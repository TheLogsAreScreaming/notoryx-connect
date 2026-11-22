import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_coverage_grid.dart';
import 'services/bastion_drive_check.dart';
import 'services/bastion_drive_export.dart';
import 'services/bastion_drive_log.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_units.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';
import 'track_log_page.dart';

/// Hands a file to the share sheet: name, text, MIME type.
typedef DriveShare =
    Future<void> Function(String fileName, String text, String mimeType);

/// Asks for a drive file and returns its text, or null if none was picked.
typedef DrivePick = Future<String?> Function();

/// Start and stop drives, watch coverage build up on a map, and look back
/// at saved drives. Listening only: nothing is sent unless the optional
/// check is turned on.
class DrivePage extends StatefulWidget {
  const DrivePage({
    super.key,
    required this.radio,
    this.log,
    this.tiles = true,
    this.share = shareDriveFile,
    this.pick = pickDriveFile,
  });

  /// Opens the share sheet with one file.
  static Future<void> shareDriveFile(
    String fileName,
    String text,
    String mimeType,
  ) => SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(utf8.encode(text)),
          mimeType: mimeType,
        ),
      ],
      fileNameOverrides: [fileName],
      subject: fileName,
    ),
  );

  /// Opens the file picker for a drive file.
  static Future<String?> pickDriveFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Drive file',
          extensions: ['json'],
          uniformTypeIdentifiers: ['public.json'],
        ),
      ],
    );
    return file?.readAsString();
  }

  final MeshtasticRadioCoordinator radio;

  /// Defaults to [BastionDriveLog.instance].
  final BastionDriveLog? log;

  /// Draws map tiles from the network. Off in tests.
  final bool tiles;

  final DriveShare share;
  final DrivePick pick;

  @override
  State<DrivePage> createState() => _DrivePageState();
}

class _DrivePageState extends State<DrivePage> {
  final _name = TextEditingController();
  final _map = MapController();
  StreamSubscription<NewNodeHeard>? _alerts;
  CoverageSquare _size = CoverageSquare.m300;
  bool _relayed = false;
  bool _follow = true;
  bool _busy = false;
  bool _mapReady = false;
  bool _trim = true;
  int? _shown;
  DrivePoint? _followed;

  BastionDriveLog get log => widget.log ?? BastionDriveLog.instance;
  AppLocalizations get l => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _alerts = log.newNodes.listen(_announce);
    log.addListener(_followMe);
  }

  @override
  void dispose() {
    unawaited(_alerts?.cancel());
    log.removeListener(_followMe);
    _name.dispose();
    _map.dispose();
    super.dispose();
  }

  void _announce(NewNodeHeard heard) {
    if (!mounted) return;
    final name = widget.radio.nodeName(heard.node);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          heard.firstEver ? l.drvNewNodeEver(name) : l.drvNewNode(name),
        ),
      ),
    );
  }

  /// Keeps the running drive's latest position in view.
  void _followMe() {
    final trip = log.current;
    if (!_follow ||
        !_mapReady ||
        trip == null ||
        (_shown != null && _shown != trip.id))
      return;
    final last = log.pointsOf(trip.id).lastOrNull;
    if (last == null || identical(last, _followed)) return;
    _followed = last;
    _map.move(LatLng(last.latitude, last.longitude), _map.camera.zoom);
  }

  Future<void> _run(Future<void> Function() operation) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await operation();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start() => _run(() async {
    await widget.radio.setCoverageRecording(true, tripName: _name.text);
    _name.clear();
    if (mounted) setState(() => _shown = null);
  });

  Future<void> _stop() => _run(() => widget.radio.setCoverageRecording(false));

  Future<void> _rename(DriveTrip trip) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(name: trip.name),
    );
    if (name != null) await _run(() => log.renameTrip(trip.id, name));
  }

  Future<void> _delete(DriveTrip trip) async {
    final messenger = ScaffoldMessenger.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.drvDeleteQ(trip.name)),
        content: Text(l.drvDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            key: const ValueKey('drive-delete-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.drvDelete),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final deleted = l.drvDeleted;
    await _run(() async {
      await log.deleteTrip(trip.id);
      if (_shown == trip.id) setState(() => _shown = null);
      messenger.showSnackBar(SnackBar(content: Text(deleted)));
    });
  }

  /// The drive on the map: the one picked, else the running one, else the
  /// latest.
  DriveTrip? get _trip {
    final trips = log.trips;
    return trips.where((t) => t.id == _shown).firstOrNull ??
        log.current ??
        trips.lastOrNull;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l.drvTitle)),
    body: SafeArea(
      top: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          widget.radio,
          log,
          widget.radio.driveCheck,
          BastionPreferences.instance,
        ]),
        builder: (context, _) {
          final units = BastionPreferences.instance.units;
          final running = log.current;
          final shown = _trip;
          final saved = [
            for (final t in log.trips.reversed)
              if (!t.running) t,
          ];
          return ListView(
            padding: NxSpace.page,
            children: [
              _controls(context, running, units),
              if (shown != null) ...[
                const SizedBox(height: NxSpace.sm),
                _mapCard(context, shown),
                const SizedBox(height: NxSpace.sm),
                _counters(context, shown, units),
                if (shown.running) ...[
                  const SizedBox(height: NxSpace.sm),
                  _checkCard(context),
                ],
                if (!shown.running) ...[
                  const SizedBox(height: NxSpace.sm),
                  _exportCard(context, shown),
                ],
              ],
              const SizedBox(height: NxSpace.sm),
              _alertSetting(context),
              NxSectionLabel(
                l.drvSaved,
                trailing: TextButton.icon(
                  key: const ValueKey('drive-import'),
                  onPressed: _busy ? null : _import,
                  icon: const Icon(Icons.file_open_outlined),
                  label: Text(l.drvImport),
                ),
              ),
              if (saved.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(NxSpace.sm),
                  child: Text(l.drvEmpty),
                )
              else
                for (final t in saved) _tripTile(context, t, units),
              const SizedBox(height: NxSpace.sm),
              _guide(context),
            ],
          );
        },
      ),
    ),
  );

  Widget _controls(
    BuildContext context,
    DriveTrip? running,
    BastionUnits units,
  ) {
    final radio = widget.radio;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(NxSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (running != null) ...[
              Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: NxSpace.xs),
                    Expanded(
                      child: Text(
                        '${l.drvRecording}: ${running.name}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: NxSpace.xs),
              Text(l.drvScreenOff),
              const SizedBox(height: NxSpace.sm),
              FilledButton.icon(
                key: const ValueKey('drive-stop'),
                onPressed: _busy ? null : _stop,
                icon: const Icon(Icons.stop),
                label: Text(l.drvStop),
              ),
            ] else ...[
              TextField(
                key: const ValueKey('drive-name'),
                controller: _name,
                maxLength: 60,
                decoration: InputDecoration(labelText: l.drvName),
              ),
              if (!radio.isReady)
                Padding(
                  padding: const EdgeInsets.only(bottom: NxSpace.xs),
                  child: Text(l.drvNotConnected),
                ),
              FilledButton.icon(
                key: const ValueKey('drive-start'),
                onPressed: _busy || !radio.isReady ? null : _start,
                icon: const Icon(Icons.play_arrow),
                label: Text(l.drvStart),
              ),
            ],
            if (radio.coverageProblem case final problem?)
              Padding(
                padding: const EdgeInsets.only(top: NxSpace.xs),
                child: Text(problem),
              ),
            if (log.error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: NxSpace.xs),
                child: Text(error),
              ),
          ],
        ),
      ),
    );
  }

  Widget _mapCard(BuildContext context, DriveTrip trip) {
    final theme = Theme.of(context);
    final status = theme.extension<NxStatusColors>()!;
    Color colour(CoverageBand band) => status.strong(switch (band) {
      CoverageBand.strong => NxTone.success,
      CoverageBand.fair => NxTone.warning,
      CoverageBand.weak => NxTone.danger,
    }, theme.colorScheme);
    final cells = BastionCoverageGrid.build(
      log.samplesOf(trip: trip.id),
      size: _size,
      classes: {
        ...BastionCoverageGrid.defaultClasses,
        if (_relayed) HopClass.relayed,
      },
    );
    final trail = [
      for (final p in log.pointsOf(trip.id)) LatLng(p.latitude, p.longitude),
    ];
    final spots = trail.isNotEmpty
        ? trail
        : [
            for (final s in log.samplesOf(trip: trip.id))
              LatLng(s.latitude, s.longitude),
          ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NxSpace.md,
              NxSpace.sm,
              NxSpace.md,
              0,
            ),
            child: Text(
              l.drvShowing(trip.name),
              style: theme.textTheme.titleSmall,
            ),
          ),
          if (spots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(NxSpace.md),
              child: Text(l.drvMapEmpty),
            )
          else
            SizedBox(
              height: 300,
              child: FlutterMap(
                key: ValueKey('drive-map-${trip.id}'),
                mapController: _map,
                options: MapOptions(
                  initialCenter: spots.last,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onMapReady: () => _mapReady = true,
                ),
                children: [
                  if (widget.tiles)
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.bastionmesh.connect',
                      tileBuilder: theme.brightness == Brightness.dark
                          ? darkModeTileBuilder
                          : null,
                    ),
                  PolygonLayer(
                    polygons: [
                      for (final c in cells)
                        Polygon(
                          points: [
                            LatLng(c.south, c.west),
                            LatLng(c.north, c.west),
                            LatLng(c.north, c.east),
                            LatLng(c.south, c.east),
                          ],
                          color: colour(
                            c.band,
                          ).withValues(alpha: 0.2 + 0.4 * c.density),
                          borderColor: colour(c.band),
                          borderStrokeWidth: 1,
                          label: c.meanSnr.toStringAsFixed(0),
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  if (trail.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: trail,
                          color: theme.colorScheme.primary,
                          strokeWidth: 3,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (trip.running)
                        for (final r in widget.radio.driveCheck.results)
                          Marker(
                            point: LatLng(r.latitude, r.longitude),
                            width: 20,
                            height: 20,
                            child: Icon(
                              _checkIcon(r.outcome),
                              size: 20,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                      Marker(
                        point: spots.last,
                        width: 18,
                        height: 18,
                        child: Icon(
                          Icons.navigation,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // The squares are colour and numbers, so say the same in words.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NxSpace.md,
              vertical: NxSpace.xs,
            ),
            child: Semantics(
              liveRegion: true,
              child: Text(
                cells.isEmpty
                    ? l.drvMapEmpty
                    : l.drvBands(
                        cells
                            .where((c) => c.band == CoverageBand.strong)
                            .length,
                        cells.where((c) => c.band == CoverageBand.fair).length,
                        cells.where((c) => c.band == CoverageBand.weak).length,
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NxSpace.md),
            child: Wrap(
              spacing: NxSpace.xs,
              runSpacing: NxSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l.drvSquareSize),
                SegmentedButton<CoverageSquare>(
                  key: const ValueKey('drive-square-size'),
                  segments: [
                    for (final s in CoverageSquare.values)
                      ButtonSegment(
                        value: s,
                        label: Text('${s.meters.round()} m'),
                      ),
                  ],
                  selected: {_size},
                  onSelectionChanged: (v) => setState(() => _size = v.first),
                ),
              ],
            ),
          ),
          SwitchListTile(
            key: const ValueKey('drive-show-relayed'),
            title: Text(l.drvShowRelayed),
            subtitle: Text(l.drvShowRelayedSub),
            value: _relayed,
            onChanged: (v) => setState(() => _relayed = v),
          ),
          if (trip.running)
            SwitchListTile(
              key: const ValueKey('drive-follow'),
              title: Text(l.drvFollow),
              value: _follow,
              onChanged: (v) => setState(() {
                _follow = v;
                _followed = null;
                _followMe();
              }),
            ),
        ],
      ),
    );
  }

  Widget _counters(BuildContext context, DriveTrip trip, BastionUnits units) {
    final s = log.summary(trip.id);
    return Card(
      key: const ValueKey('drive-counters'),
      child: Padding(
        padding: const EdgeInsets.all(NxSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.drvStats(
                BastionUnitFormat.distance(s.meters, units),
                TrackLogPage.duration(s.duration),
                s.readings,
              ),
            ),
            Text(l.drvNodes(s.nodes, s.directNodes, s.newNodes)),
            Text(l.drvSquares(s.squares, s.bestSnr?.toStringAsFixed(1) ?? '—')),
          ],
        ),
      ),
    );
  }

  Widget _alertSetting(BuildContext context) =>
      DropdownButtonFormField<NewNodeAlert>(
        key: const ValueKey('drive-alert'),
        initialValue: log.newNodeAlert,
        decoration: InputDecoration(labelText: l.drvAlert),
        items: [
          for (final a in NewNodeAlert.values)
            DropdownMenuItem(
              value: a,
              child: Text(switch (a) {
                NewNodeAlert.off => l.drvAlertOff,
                NewNodeAlert.trip => l.drvAlertTrip,
                NewNodeAlert.ever => l.drvAlertEver,
              }),
            ),
        ],
        onChanged: (v) {
          if (v != null) unawaited(log.setNewNodeAlert(v));
        },
      );

  Widget _tripTile(BuildContext context, DriveTrip t, BastionUnits units) {
    final s = log.summary(t.id);
    return Card(
      child: ListTile(
        key: ValueKey('drive-${t.id}'),
        selected: _trip?.id == t.id,
        leading: const Icon(Icons.directions_car_outlined),
        title: Text(t.name),
        subtitle: Text(
          '${l.drvStats(BastionUnitFormat.distance(s.meters, units), TrackLogPage.duration(s.duration), s.readings)}\n'
          '${l.drvNodes(s.nodes, s.directNodes, s.newNodes)}',
        ),
        isThreeLine: true,
        onTap: () => setState(() {
          _shown = t.id;
          _mapReady = false;
        }),
        trailing: PopupMenuButton<String>(
          key: ValueKey('drive-menu-${t.id}'),
          onSelected: (v) => switch (v) {
            'show' => setState(() {
              _shown = t.id;
              _mapReady = false;
            }),
            'rename' => unawaited(_rename(t)),
            _ => unawaited(_delete(t)),
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'show', child: Text(l.drvShowOnMap)),
            PopupMenuItem(value: 'rename', child: Text(l.drvRename)),
            PopupMenuItem(value: 'delete', child: Text(l.drvDelete)),
          ],
        ),
      ),
    );
  }

  static IconData _checkIcon(DriveCheckOutcome o) => switch (o) {
    DriveCheckOutcome.twoWay => Icons.check_circle,
    DriveCheckOutcome.answeredRelayed => Icons.alt_route,
    DriveCheckOutcome.noAnswer => Icons.cancel_outlined,
  };

  /// The optional check: off by default, explained before it's turned on.
  Widget _checkCard(BuildContext context) {
    final check = widget.radio.driveCheck;
    final candidates = check.candidates;
    final results = check.results;
    int count(DriveCheckOutcome o) =>
        results.where((r) => r.outcome == o).length;
    return Card(
      key: const ValueKey('drive-check'),
      child: Padding(
        padding: const EdgeInsets.all(NxSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              key: const ValueKey('drive-check-switch'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.drvCheck),
              subtitle: Text(l.drvCheckSub),
              value: check.enabled,
              onChanged: (v) => check.setEnabled(v),
            ),
            if (check.enabled) ...[
              if (candidates.isEmpty)
                Text(l.drvCheckNoCandidates)
              else
                DropdownButtonFormField<int>(
                  key: const ValueKey('drive-check-target'),
                  initialValue: candidates.contains(check.target)
                      ? check.target
                      : null,
                  decoration: InputDecoration(labelText: l.drvCheckTarget),
                  items: [
                    for (final n in candidates)
                      DropdownMenuItem(
                        value: n,
                        child: Text(widget.radio.nodeName(n)),
                      ),
                  ],
                  onChanged: check.setTarget,
                ),
              const SizedBox(height: NxSpace.xs),
              Semantics(
                liveRegion: true,
                child: Text(switch (check.pause) {
                  _ when check.waiting => l.drvCheckWaiting,
                  _ when check.target == null => l.drvCheckPickTarget,
                  DriveCheckPause.busyChannel => l.drvCheckBusy(
                    BastionDriveCheck.maxChannelUtilization.round(),
                  ),
                  DriveCheckPause.noTarget => l.drvCheckPickTarget,
                  DriveCheckPause.noDrive => l.drvCheckPickTarget,
                  null => l.drvCheckReady,
                }),
              ),
            ],
            if (results.isNotEmpty)
              Text(
                l.drvCheckResults(
                  count(DriveCheckOutcome.twoWay),
                  count(DriveCheckOutcome.answeredRelayed),
                  count(DriveCheckOutcome.noAnswer),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _exportCard(BuildContext context, DriveTrip trip) => Card(
    key: const ValueKey('drive-export'),
    child: Padding(
      padding: const EdgeInsets.all(NxSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.drvExport, style: Theme.of(context).textTheme.titleSmall),
          SwitchListTile(
            key: const ValueKey('drive-trim'),
            contentPadding: EdgeInsets.zero,
            title: Text(l.drvTrim),
            subtitle: Text(l.drvTrimSub),
            value: _trim,
            onChanged: (v) => setState(() => _trim = v),
          ),
          Wrap(
            spacing: NxSpace.xs,
            runSpacing: NxSpace.xs,
            children: [
              for (final (format, label) in [
                (DriveExportFormat.gpx, 'GPX'),
                (DriveExportFormat.kml, 'KML'),
                (DriveExportFormat.csv, 'CSV'),
                (DriveExportFormat.geojson, 'GeoJSON'),
                (DriveExportFormat.drive, l.drvDriveFile),
              ])
                OutlinedButton(
                  key: ValueKey('drive-export-${format.name}'),
                  onPressed: _busy ? null : () => _export(trip, format),
                  child: Text(label),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _export(DriveTrip trip, DriveExportFormat format) async {
    final messenger = ScaffoldMessenger.of(context);
    final export = DriveExport.of(
      log,
      trip,
      trimMeters: _trim ? DriveExport.defaultTrimMeters : 0,
    );
    if (export.samples.isEmpty && export.points.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.drvExportEmpty)));
      return;
    }
    await _run(
      () => widget.share(
        export.fileName(format),
        export.write(format),
        format.mimeType,
      ),
    );
  }

  Future<void> _import() async {
    final messenger = ScaffoldMessenger.of(context);
    final l = this.l;
    String? text;
    try {
      text = await widget.pick();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.drvImportUnreadable)));
      return;
    }
    if (text == null) return;
    final DriveFile file;
    try {
      file = DriveFile.parse(text);
    } on FormatException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.drvImportBad(e.message))),
      );
      return;
    }
    await _run(() async {
      final trip = await log.importTrip(
        name: l.drvImportedName(file.name),
        started: file.started,
        ended: file.ended,
        points: file.points,
        samples: file.samples,
      );
      if (mounted) setState(() => _shown = trip.id);
      messenger.showSnackBar(
        SnackBar(content: Text(l.drvImported(file.samples.length))),
      );
    });
  }

  Widget _guide(BuildContext context) => Card(
    child: ExpansionTile(
      key: const ValueKey('drive-guide'),
      title: Text(l.drvGuide),
      childrenPadding: const EdgeInsets.fromLTRB(
        NxSpace.md,
        0,
        NxSpace.md,
        NxSpace.md,
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (title, body) in [
          (l.drvGuideDirectTitle, l.drvGuideDirect),
          (l.drvGuideListenTitle, l.drvGuideListen),
          (l.drvGuideAntennaTitle, l.drvGuideAntenna),
          (l.drvGuidePrivacyTitle, l.drvGuidePrivacy),
        ]) ...[
          const SizedBox(height: NxSpace.xs),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          Text(body),
        ],
      ],
    ),
  );
}

/// Owns its text box, so the box outlives the closing animation.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.name});
  final String name;
  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.name);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.drvRename),
      content: TextField(
        key: const ValueKey('drive-rename-field'),
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        decoration: InputDecoration(labelText: l.drvName),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l.drvSave),
        ),
      ],
    );
  }
}
