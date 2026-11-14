import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import 'package:file_selector/file_selector.dart';
import 'l10n/generated/app_localizations.dart';
import 'link_planner_page.dart';
import 'node_detail_page.dart';
import 'place_search_page.dart';
import 'map_list_page.dart';
import 'network_diagram_page.dart';
import 'services/bastion_coverage_grid.dart';
import 'services/bastion_field_log.dart';
import 'services/bastion_geo.dart';
import 'services/bastion_geofences.dart';
import 'services/bastion_gpx.dart';
import 'services/bastion_map_layers.dart';
import 'services/bastion_offline_map.dart';
import 'services/bastion_heard_filter.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_routes.dart';
import 'services/bastion_tak_bridge.dart';
import 'services/bastion_units.dart';
import 'services/bastion_team.dart';
import 'services/bastion_waypoints.dart';
import 'services/meshtastic_node_database.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'services/bastion_node_vault.dart';
import 'services/bastion_place_search.dart';
import 'theme/notoryx_theme.dart';

/// Mesh nodes with a reported position on an OpenStreetMap base map.
///
/// Tiles load from tile.openstreetmap.org and need internet access; node
/// positions come only from the radio.
class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.radio, this.shareFile = _shareFile, this.tak, this.mapLayers, this.offlineMap});

  final MeshtasticRadioCoordinator radio;

  /// Markers from ATAK; the app-wide bridge when null.
  final BastionTakBridge? tak;

  /// Imported map files; the app-wide store when null.
  final BastionMapLayers? mapLayers;

  /// The imported offline map file; the app-wide one when null.
  final BastionOfflineMap? offlineMap;

  /// Hands an exported file to the system share sheet; replaced in tests.
  final Future<void> Function(String fileName, String text) shareFile;

  static Future<void> _shareFile(String fileName, String text) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(Uint8List.fromList(utf8.encode(text)), mimeType: 'application/gpx+xml')],
      fileNameOverrides: [fileName],
      subject: 'NOTORYX Connect GPX export',
    ));
  }

  /// NOTORYX orange; markers sit on light map tiles in both themes.
  static const accent = Color(0xFFFC7202);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  AppLocalizations get l => AppLocalizations.of(context);
  BastionTakBridge get _tak => widget.tak ?? BastionTakBridge.instance;

  final MapController _map = MapController();
  bool _fitted = false;
  bool _showLinks = true;
  bool _showTrails = true;
  bool _showHeatmap = false;
  bool _showRemembered = false;

  /// The last place chosen in Find a place, shown with a pin until cleared.
  PlaceResult? _found;

  /// Shows OpenTopoMap contour tiles instead of the street map.
  bool _topo = false;

  /// Stops of a route being planned, or null when not planning.
  List<LatLng>? _planning;
  bool _sharingRoute = false;

  Set<int> get _team => widget.radio.trip.plan.members.toSet();

  /// Movement trails: solid for trip contacts, dotted for this radio.
  List<Polyline> _trailLines(Set<int> team, int? local) => [
        for (final num in {...team, ?local})
          if (widget.radio.trailOf(num) case final trail when trail.length >= 2)
            Polyline(
              points: [for (final p in trail) LatLng(p.latitude, p.longitude)],
              strokeWidth: 3,
              color: MapPage.accent.withValues(alpha: num == local ? 0.6 : 0.9),
              pattern: num == local ? const StrokePattern.dotted() : const StrokePattern.solid(),
            ),
      ];

  List<TeamMemberStatus> _teamStatus() {
    final now = DateTime.now();
    final byNum = {for (final n in widget.radio.nodes) n.num: n};
    final me = byNum[widget.radio.localNodeNum];
    return [
      for (final num in widget.radio.trip.plan.members)
        TeamMemberStatus.of(num, byNum[num], me: me, now: now,
            battery: widget.radio.deviceTelemetry[num]?.batteryLevel),
    ];
  }

  /// One line per pair of placed nodes that a Neighbor Info report links.
  List<Polyline> _links(List<MeshtasticNode> placed) {
    final byNum = {for (final n in placed) n.num: n};
    final seen = <(int, int)>{};
    final lines = <Polyline>[];
    for (final report in widget.radio.neighborReports.values) {
      final a = byNum[report.nodeNum];
      if (a == null) continue;
      for (final neighbor in report.neighbors) {
        final b = byNum[neighbor.nodeNum];
        if (b == null) continue;
        final key = a.num < b.num ? (a.num, b.num) : (b.num, a.num);
        if (!seen.add(key)) continue;
        lines.add(Polyline(
          points: [LatLng(a.latitude!, a.longitude!), LatLng(b.latitude!, b.longitude!)],
          strokeWidth: 2.5,
          color: MapPage.accent.withValues(alpha: neighbor.snr >= 0 ? 0.9 : 0.45),
        ));
      }
    }
    return lines;
  }

  Future<void> _findPlace(BuildContext context) async {
    final result = await Navigator.of(context).push(MaterialPageRoute<PlaceResult>(
      builder: (_) => PlaceSearchPage(nodes: widget.radio.nodes, waypoints: widget.radio.waypoints),
    ));
    if (result == null || !mounted) return;
    setState(() => _found = result);
    _map.move(LatLng(result.latitude, result.longitude), 14);
  }

  void _showTak(BuildContext context, TakMarker m) {
    final kind = _TakPin.kind(AppLocalizations.of(context), m);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(child: ListTile(
        leading: Icon(_TakPin.icon(m), semanticLabel: kind),
        title: Text(m.callsign),
        subtitle: Text('$kind · ${m.type}\n'
            '${m.latitude.toStringAsFixed(5)}, ${m.longitude.toStringAsFixed(5)}\n'
            '${l.mapTakUpdated(TimeOfDay.fromDateTime(m.received).format(context), TimeOfDay.fromDateTime(m.stale).format(context))}'),
      )),
    );
  }

  BastionMapLayers get _layers => widget.mapLayers ?? BastionMapLayers.instance;

  void _onLayers() {
    if (mounted) setState(() {});
  }

  BastionOfflineMap get _offline => widget.offlineMap ?? BastionOfflineMap.instance;

  @override
  void initState() {
    super.initState();
    _layers.addListener(_onLayers);
    unawaited(_layers.load());
    _offline.addListener(_onLayers);
    unawaited(_offline.load());
  }

  @override
  void dispose() {
    _layers.removeListener(_onLayers);
    _offline.removeListener(_onLayers);
    _map.dispose();
    super.dispose();
  }

  /// Offline map: import a raster MBTiles file, switch it on or off, or remove it.
  void _showOfflineMap(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => ListenableBuilder(
        listenable: _offline,
        builder: (sheet, _) {
          final info = _offline.info;
          return SafeArea(child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
            Text(l.omTitle, style: Theme.of(sheet).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l.omHelp, style: Theme.of(sheet).textTheme.bodySmall),
            const SizedBox(height: 8),
            if (info == null)
              Text(l.omNone)
            else
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _offline.active,
                onChanged: _offline.setActive,
                title: Text(info.name),
                subtitle: Text([
                  l.omZooms(info.minZoom, info.maxZoom),
                  if (info.bounds case final b?)
                    l.omArea('${b.$2.toStringAsFixed(3)}, ${b.$1.toStringAsFixed(3)} → '
                        '${b.$4.toStringAsFixed(3)}, ${b.$3.toStringAsFixed(3)}'),
                  if (info.damagedTiles > 0) l.omDamaged(info.damagedTiles),
                ].join('\n')),
                secondary: IconButton(
                  tooltip: l.omRemove,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _offline.remove,
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _importOfflineMap(sheet),
              icon: const Icon(Icons.file_open_outlined),
              label: Text(info == null ? l.omImport : l.omReplace),
            ),
          ]));
        },
      ),
    );
  }

  Future<void> _importOfflineMap(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await openFile(acceptedTypeGroups: const [
        XTypeGroup(label: 'MBTiles', extensions: ['mbtiles'], uniformTypeIdentifiers: ['public.data']),
      ]);
      if (file == null) return;
      final info = await _offline.import(file);
      messenger.showSnackBar(SnackBar(content: Text(l.omAdded(info.name, info.minZoom, info.maxZoom))));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.omUnreadable(e.message))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.omUnreadable('$e'))));
    }
  }

  /// Lines and outlines from imported map files that are switched on.
  List<Polyline> _layerLines(Color color) => [
        for (final layer in _layers.layers)
          if (layer.visible)
            for (final line in layer.lines)
              Polyline(
                points: [for (final (a, o) in line.points) LatLng(a, o)],
                strokeWidth: 3,
                color: color,
                pattern: StrokePattern.dashed(segments: const [8, 5]),
              ),
      ];

  List<Marker> _layerMarkers(BuildContext context, Color color) => [
        for (final layer in _layers.layers)
          if (layer.visible)
            for (final p in layer.points)
              Marker(
                point: LatLng(p.latitude, p.longitude),
                width: 44,
                height: 44,
                child: IconButton(
                  tooltip: p.name,
                  icon: Icon(Icons.place_outlined, color: color),
                  onPressed: () => _showLayerPoint(context, layer, p),
                ),
              ),
      ];

  void _showLayerPoint(BuildContext context, MapLayer layer, LayerPoint p) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.place_outlined),
          title: Text(p.name),
          subtitle: Text([
            if (p.note.isNotEmpty) p.note,
            '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
            l.mapLayerFrom(layer.name),
          ].join('\n')),
        ),
      ),
    );
  }

  /// Lists imported map files, with switches to show or hide each.
  void _showLayers(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => ListenableBuilder(
        listenable: _layers,
        builder: (sheet, _) {
          final layers = _layers.layers;
          return SafeArea(
            child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
              Text(l.mapLayers, style: Theme.of(sheet).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l.mapLayersHelp, style: Theme.of(sheet).textTheme.bodySmall),
              const SizedBox(height: 8),
              if (layers.isEmpty) Text(l.mapLayersEmpty),
              for (final layer in layers)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: layer.visible,
                  onChanged: (v) => _layers.setVisible(layer.id, v),
                  title: Text(layer.name),
                  subtitle: Text(l.mapLayerCounts(layer.points.length, layer.lines.length)),
                  secondary: IconButton(
                    tooltip: l.mapLayerRemove(layer.name),
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _layers.remove(layer.id),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => _importLayer(sheet),
                icon: const Icon(Icons.file_open_outlined),
                label: Text(l.mapLayerImport),
              ),
            ]),
          );
        },
      ),
    );
  }

  Future<void> _importLayer(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await openFile(acceptedTypeGroups: const [
        XTypeGroup(
          label: 'GPX, KML, GeoJSON',
          extensions: ['gpx', 'kml', 'geojson', 'json'],
          uniformTypeIdentifiers: ['com.topografix.gpx', 'com.google.earth.kml', 'public.geojson', 'public.json', 'public.xml'],
        ),
      ]);
      if (file == null) return;
      final text = await file.readAsString();
      final name = file.name.replaceFirst(RegExp(r'\.(gpx|kml|geojson|json)$', caseSensitive: false), '');
      final layer = await _layers.import(name.isEmpty ? file.name : name, text);
      messenger.showSnackBar(SnackBar(content: Text(l.mapLayerAdded(layer.name, layer.points.length, layer.lines.length))));
    } on StateError {
      messenger.showSnackBar(SnackBar(content: Text(l.mapLayerTooMany(BastionMapLayers.maxLayers))));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.mapLayerUnreadable)));
    }
  }

  List<MeshtasticNode> get _placed {
    final heard = BastionPreferences.instance.heardWithin;
    final favoritesOnly = BastionPreferences.instance.favoritesOnly;
    final favorites = widget.radio.favoriteNums;
    final now = DateTime.now();
    final local = widget.radio.localNode?.num;
    return widget.radio.nodes
        .where((n) =>
            n.hasPosition &&
            heard.matches(n.lastHeard, now, always: n.num == local) &&
            (!favoritesOnly || n.num == local || favorites.contains(n.num)))
        .toList();
  }

  void _fit(List<MeshtasticNode> nodes) {
    if (nodes.isEmpty) return;
    final points = [for (final n in nodes) LatLng(n.latitude!, n.longitude!)];
    if (points.length == 1) {
      _map.move(points.single, 13);
    } else {
      _map.fitCamera(CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(48),
        maxZoom: 15,
      ));
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([widget.radio, _tak]),
        builder: (context, _) {
          final placed = _placed;
          final takMarkers = _tak.receive ? _tak.markers : const <TakMarker>[];
          final local = widget.radio.localNodeNum;
          final team = _team;
          final trails = _trailLines(team, local);
          if (!_fitted && placed.isNotEmpty) {
            _fitted = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _fit(placed);
            });
          }
          return Stack(
            children: [
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: const LatLng(39.5, -98.35),
                  initialZoom: 3,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onLongPress: (_, point) => _planning == null ? _createWaypoint(context, point) : null,
                  onTap: (_, point) {
                    final plan = _planning;
                    if (plan == null || plan.length >= BastionRoutes.maxStops) return;
                    setState(() => plan.add(point));
                  },
                ),
                children: [
                  TileLayer(
                    key: ValueKey(_topo),
                    urlTemplate: _topo
                        ? 'https://tile.opentopomap.org/{z}/{x}/{y}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.bastionmesh.connect',
                    maxNativeZoom: _topo ? 17 : 19,
                  ),
                  if (_offline.info case final info? when _offline.active)
                    TileLayer(
                      key: const ValueKey('offline-map'),
                      tileProvider: _offline.tileProvider,
                      minNativeZoom: info.minZoom,
                      maxNativeZoom: info.maxZoom,
                      // Without these the layer asks the file for every tile
                      // of the visible world at its lowest zoom (hundreds of
                      // thousands of lookups on a zoomed-out map), which
                      // froze the app.
                      minZoom: offlineLayerMinZoom(info),
                      tileBounds: offlineLayerBounds(info),
                    ),
                  // Outside this outline the offline file has no tiles.
                  if (_offline.info?.bounds case final b? when _offline.active)
                    PolylineLayer(polylines: [
                      Polyline(
                        points: [
                          LatLng(b.$4, b.$1),
                          LatLng(b.$4, b.$3),
                          LatLng(b.$2, b.$3),
                          LatLng(b.$2, b.$1),
                          LatLng(b.$4, b.$1),
                        ],
                        strokeWidth: 2,
                        color: MapPage.accent,
                        pattern: StrokePattern.dashed(segments: const [8, 6]),
                      ),
                    ]),
                  if (_showHeatmap) _heatmapLayer(context),
                  if (widget.radio.geofences.isNotEmpty)
                    CircleLayer(circles: [
                      for (final zone in widget.radio.geofences)
                        CircleMarker(
                          point: LatLng(zone.latitude, zone.longitude),
                          radius: zone.radiusMeters,
                          useRadiusInMeter: true,
                          color: MapPage.accent.withValues(alpha: 0.1),
                          borderColor: MapPage.accent,
                          borderStrokeWidth: 2,
                        ),
                    ]),
                  if (_showLinks) PolylineLayer(polylines: _links(placed)),
                  if (_showTrails && trails.isNotEmpty) PolylineLayer(polylines: trails),
                  if (BastionRoutes.group(widget.radio.waypoints) case final routes when routes.isNotEmpty)
                    PolylineLayer(polylines: [
                      for (final r in routes)
                        if (r.stops.length >= 2)
                          Polyline(
                            points: [for (final p in r.points) LatLng(p.latitude, p.longitude)],
                            strokeWidth: 4,
                            color: Theme.of(context).colorScheme.tertiary,
                            pattern: StrokePattern.dashed(segments: const [12, 6]),
                          ),
                    ]),
                  if (_layerLines(Theme.of(context).colorScheme.secondary) case final lines when lines.isNotEmpty)
                    PolylineLayer(polylines: lines),
                  if (_layerMarkers(context, Theme.of(context).colorScheme.secondary) case final marks when marks.isNotEmpty)
                    MarkerLayer(markers: marks),
                  if (_planning case final plan? when plan.isNotEmpty) ...[
                    PolylineLayer(polylines: [
                      if (plan.length >= 2)
                        Polyline(points: plan, strokeWidth: 4, color: MapPage.accent),
                    ]),
                    MarkerLayer(markers: [
                      for (final (i, p) in plan.indexed)
                        Marker(point: p, width: 28, height: 28, child: Container(
                          decoration: BoxDecoration(color: MapPage.accent, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2)),
                          alignment: Alignment.center,
                          child: Text('${i + 1}', style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w700, fontSize: 12)),
                        )),
                    ]),
                  ],
                  if (_showRemembered) MarkerLayer(markers: [
                    for (final r in _remembered)
                      Marker(point: LatLng(r.latitude!, r.longitude!), width: 48, height: 48,
                        child: Semantics(button: true, label: l.mapRememberedPin(r.displayName, _when(r.lastSeen)),
                          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _showRememberedNode(context, r),
                            child: ExcludeSemantics(child: Icon(Icons.history, size: 28, color: Theme.of(context).colorScheme.onSurfaceVariant))))),
                  ]),
                  if (_found case final found?)
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(found.latitude, found.longitude),
                        width: 48,
                        height: 48,
                        alignment: Alignment.topCenter,
                        child: Semantics(
                          button: true,
                          label: l.mapFoundPin(found.name),
                          child: GestureDetector(
                            key: const ValueKey('found-pin'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _found = null),
                            child: const ExcludeSemantics(
                                child: Icon(Icons.location_on, size: 44, color: MapPage.accent)),
                          ),
                        ),
                      ),
                    ]),
                  if (takMarkers.isNotEmpty)
                    MarkerLayer(markers: [
                      for (final m in takMarkers)
                        Marker(
                          point: LatLng(m.latitude, m.longitude),
                          width: 96,
                          height: MediaQuery.textScalerOf(context).scale(56),
                          child: _TakPin(marker: m, onTap: () => _showTak(context, m)),
                        ),
                    ]),
                  MarkerLayer(
                    markers: [
                      for (final waypoint in widget.radio.waypoints)
                        Marker(
                          point: LatLng(waypoint.latitude, waypoint.longitude),
                          width: 120,
                          height: MediaQuery.textScalerOf(context).scale(56),
                          child: _WaypointPin(
                            waypoint: waypoint,
                            onTap: () => _showWaypoint(context, waypoint),
                          ),
                        ),
                      for (final node in placed)
                        Marker(
                          point: LatLng(node.latitude!, node.longitude!),
                          width: 72,
                          height: MediaQuery.textScalerOf(context).scale(team.contains(node.num) ? 80 : 64),
                          child: _NodePin(
                            node: node,
                            isLocal: node.num == local,
                            team: team.contains(node.num)
                                ? TeamMemberStatus.of(node.num, node, now: DateTime.now())
                                : null,
                            onTap: () => _showNode(context, node),
                          ),
                        ),
                    ],
                  ),
                  _MapAttribution(topo: _topo),
                ],
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        const Icon(Icons.map_outlined, color: MapPage.accent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            placed.isEmpty
                                ? (widget.radio.isReady
                                    ? l.mapNoPositions
                                    : l.mapConnectForPositions)
                                : '${l.mapPlaced(placed.length, widget.radio.nodes.length)}'
                                    '${widget.radio.waypoints.isEmpty ? '' : ' • ${l.mapWaypointCount(widget.radio.waypoints.length)}'}'
                                    '\n${l.mapLongPressHint}',
                          ),
                        ),
                      ]),
                      // The squares are only colour and numbers on the map,
                      // so say the same in words for screen readers and everyone else.
                      if (_showHeatmap)
                        if (_coverage case final cells when cells.isNotEmpty)
                          Semantics(liveRegion: true, child: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(l.mapHeatSummary(
                              cells.where((c) => c.band == CoverageBand.strong).length,
                              cells.where((c) => c.band == CoverageBand.fair).length,
                              cells.where((c) => c.band == CoverageBand.weak).length,
                              cells.fold<int>(0, (sum, c) => sum + c.readings),
                            ), key: const ValueKey('heatmap-summary')),
                          )),
                      Wrap(alignment: WrapAlignment.end, children: [
                        IconButton(
                          key: const ValueKey('map-find-place'),
                          tooltip: l.mapFindPlace,
                          icon: const Icon(Icons.search),
                          onPressed: () => _findPlace(context),
                        ),
                        IconButton(
                          key: const ValueKey('map-favorites-only'),
                          tooltip: BastionPreferences.instance.favoritesOnly
                              ? l.mapShowAllNodes
                              : l.nodesFavoritesOnly,
                          isSelected: BastionPreferences.instance.favoritesOnly,
                          icon: const Icon(Icons.star_border),
                          selectedIcon: const Icon(Icons.star),
                          onPressed: () async {
                            await BastionPreferences.instance
                                .update(favorites: !BastionPreferences.instance.favoritesOnly);
                            if (mounted) setState(() {});
                          },
                        ),
                        PopupMenuButton<BastionHeardWithin>(
                          key: const ValueKey('map-heard-filter'),
                          tooltip: l.mapHeardWithin,
                          icon: Badge(
                            isLabelVisible: BastionPreferences.instance.heardWithin != BastionHeardWithin.any,
                            smallSize: 8,
                            child: const Icon(Icons.filter_alt_outlined),
                          ),
                          initialValue: BastionPreferences.instance.heardWithin,
                          onSelected: (v) async {
                            await BastionPreferences.instance.update(heard: v);
                            if (mounted) setState(() {});
                          },
                          itemBuilder: (_) => [
                            for (final v in BastionHeardWithin.values)
                              CheckedPopupMenuItem(
                                value: v,
                                checked: v == BastionPreferences.instance.heardWithin,
                                child: Text(switch (v) {
                                  BastionHeardWithin.any => l.mapHeardAny,
                                  BastionHeardWithin.hour => l.mapHeardHour,
                                  BastionHeardWithin.day => l.mapHeardDay,
                                  BastionHeardWithin.week => l.mapHeardWeek,
                                }),
                              ),
                          ],
                        ),
                        IconButton(
                          tooltip: _topo ? l.mapShowStreet : l.mapShowTopo,
                          icon: Icon(_topo ? Icons.map_outlined : Icons.terrain),
                          onPressed: () => setState(() => _topo = !_topo),
                        ),
                        IconButton(
                          tooltip: l.mapLinkPlanner,
                          icon: const Icon(Icons.settings_input_antenna),
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => LinkPlannerPage(radio: widget.radio))),
                        ),
                        IconButton(
                          tooltip: l.mapRallyRoutes,
                          icon: Badge(
                            isLabelVisible: widget.radio.waypoints.any(BastionRoutes.isRally),
                            label: Text('${widget.radio.waypoints.where(BastionRoutes.isRally).length}'),
                            child: const Icon(Icons.flag_outlined),
                          ),
                          onPressed: () => _showRally(context),
                        ),
                        IconButton(
                          tooltip: l.mapTeam,
                          icon: Badge(
                            isLabelVisible: team.isNotEmpty,
                            label: Text('${team.length}'),
                            child: const Icon(Icons.groups_outlined),
                          ),
                          onPressed: () => _showTeam(context),
                        ),
                        IconButton(
                          tooltip: l.mapLayers,
                          icon: Badge(
                            isLabelVisible: _layers.layers.isNotEmpty,
                            label: Text('${_layers.layers.length}'),
                            child: const Icon(Icons.layers_outlined),
                          ),
                          onPressed: () => _showLayers(context),
                        ),
                        IconButton(
                          tooltip: l.omTitle,
                          icon: Icon(_offline.active ? Icons.map : Icons.map_outlined),
                          onPressed: () => _showOfflineMap(context),
                        ),
                        IconButton(
                          tooltip: l.mapZones,
                          icon: Badge(
                            isLabelVisible: widget.radio.geofences.isNotEmpty,
                            label: Text('${widget.radio.geofences.length}'),
                            child: const Icon(Icons.fence),
                          ),
                          onPressed: () => _showZones(context),
                        ),
                        if (trails.isNotEmpty || widget.radio.waypoints.isNotEmpty)
                          IconButton(
                            tooltip: l.mapExportGpx,
                            icon: const Icon(Icons.ios_share),
                            onPressed: () => _exportGpx(context, team, local),
                          ),
                        if (trails.isNotEmpty)
                          IconButton(
                            tooltip: _showTrails ? l.mapHideTrails : l.mapShowTrails,
                            icon: Icon(_showTrails ? Icons.timeline : Icons.timeline_outlined),
                            onPressed: () => setState(() => _showTrails = !_showTrails),
                          ),
                        IconButton(
                          key: const ValueKey('map-network-diagram'),
                          tooltip: l.topologyTitle,
                          icon: const Icon(Icons.account_tree_outlined),
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => NetworkDiagramPage(radio: widget.radio))),
                        ),
                        if (widget.radio.neighborReports.isNotEmpty)
                          IconButton(
                            tooltip: _showLinks ? l.mapHideLinks : l.mapShowLinks,
                            icon: Icon(_showLinks ? Icons.hub : Icons.hub_outlined),
                            onPressed: () => setState(() => _showLinks = !_showLinks),
                          ),
                        IconButton(
                          key: const ValueKey('map-as-list'),
                          tooltip: l.mlTitle,
                          icon: const Icon(Icons.format_list_bulleted),
                          onPressed: () {
                            final me = widget.radio.localNode;
                            Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MapListPage(
                              me: me != null && me.hasPosition ? (me.latitude!, me.longitude!) : null,
                              selfNum: widget.radio.localNodeNum,
                              nodes: widget.radio.nodes,
                              waypoints: widget.radio.waypoints,
                              cells: _coverage,
                            )));
                          },
                        ),
                        IconButton(
                          key: const ValueKey('map-heatmap'),
                          tooltip: _showHeatmap ? l.mapHideHeatmap : l.mapShowHeatmap,
                          icon: Icon(_showHeatmap ? Icons.grid_on : Icons.grid_off),
                          onPressed: () => _toggleHeatmap(context),
                        ),
                        IconButton(
                          key: const ValueKey('map-remembered'),
                          tooltip: _showRemembered ? l.mapHideRemembered : l.mapShowRemembered,
                          icon: Icon(_showRemembered ? Icons.history : Icons.history_toggle_off),
                          onPressed: () => _toggleRemembered(context),
                        ),
                        if (placed.isNotEmpty)
                          IconButton(
                            tooltip: l.mapShowAll,
                            icon: const Icon(Icons.fit_screen),
                            onPressed: () => _fit(placed),
                          ),
                      ]),
                    ]),
                  ),
                ),
              ),
              if (_planning case final plan?)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 36,
                  child: Card(child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Semantics(liveRegion: true, child: Text(
                        plan.isEmpty
                            ? l.mapPlanHint(BastionRoutes.maxStops)
                            : l.mapPlanProgress(plan.length, BastionRoutes.maxStops,
                                BastionUnitFormat.distance(BastionRoutes.lengthOf([for (final p in plan) (latitude: p.latitude, longitude: p.longitude)]), BastionPreferences.instance.units)),
                        style: Theme.of(context).textTheme.titleSmall,
                      )),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
                        TextButton(onPressed: _sharingRoute ? null : () => setState(() => _planning = null),
                          child: Text(AppLocalizations.of(context).commonCancel)),
                        OutlinedButton.icon(
                          onPressed: plan.isEmpty || _sharingRoute ? null : () => setState(plan.removeLast),
                          icon: const Icon(Icons.undo), label: Text(l.mapUndo)),
                        FilledButton.icon(
                          onPressed: plan.length < 2 || _sharingRoute ? null : () => _shareRoute(context, plan),
                          icon: _sharingRoute
                              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.share_location),
                          label: Text(l.mapShareRoute)),
                      ]),
                    ]),
                  )),
                ),
            ],
          );
        },
      );

  ({double distance, double bearing})? _fromMe(double lat, double lon) {
    final me = widget.radio.localNode;
    if (me == null || !me.hasPosition) return null;
    return (
      distance: BastionGeo.distanceMeters(me.latitude!, me.longitude!, lat, lon),
      bearing: BastionGeo.bearingDegrees(me.latitude!, me.longitude!, lat, lon),
    );
  }

  /// Rally points with distance and direction, shared routes, and route planning.
  List<CoverageCell> get _coverage =>
      BastionCoverageGrid.build(BastionFieldLog.instance.records, radio: widget.radio.localNodeNum);

  void _toggleHeatmap(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final turningOn = !_showHeatmap;
    setState(() => _showHeatmap = turningOn);
    if (!turningOn) return;
    final cells = _coverage;
    final readings = cells.fold<int>(0, (sum, c) => sum + c.readings);
    messenger.showSnackBar(SnackBar(content: Text(cells.isEmpty
        ? l.mapHeatmapEmpty
        : '${l.mapHeatmapSummary(readings)} ${l.mapHeatStrong} ≥ ${BastionCoverageGrid.strongSnr.round()}, '
            '${l.mapHeatFair} ≥ ${BastionCoverageGrid.fairSnr.round()}, ${l.mapHeatWeak} < ${BastionCoverageGrid.fairSnr.round()}.')));
  }

  /// Colour is backed by the SNR number printed in each square.
  Widget _heatmapLayer(BuildContext context) {
    final theme = Theme.of(context);
    final status = theme.extension<NxStatusColors>()!;
    Color colour(CoverageBand band) => status.strong(switch (band) {
          CoverageBand.strong => NxTone.success,
          CoverageBand.fair => NxTone.warning,
          CoverageBand.weak => NxTone.danger,
        }, theme.colorScheme);
    return PolygonLayer(polygons: [
      for (final c in _coverage)
        Polygon(
          points: [
            LatLng(c.south, c.west),
            LatLng(c.south + BastionCoverageGrid.cellDegrees, c.west),
            LatLng(c.south + BastionCoverageGrid.cellDegrees, c.west + BastionCoverageGrid.cellDegrees),
            LatLng(c.south, c.west + BastionCoverageGrid.cellDegrees),
          ],
          color: colour(c.band).withValues(alpha: 0.2 + 0.4 * c.density),
          borderColor: colour(c.band),
          borderStrokeWidth: 1,
          label: c.meanSnr.toStringAsFixed(0),
          labelStyle: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w700, fontSize: 12),
        ),
    ]);
  }

  /// Nodes with a saved position that the radio no longer places.
  List<BastionNodeRecord> get _remembered {
    final current = {for (final n in widget.radio.nodes) if (n.hasPosition) n.num};
    return [for (final r in widget.radio.nodeVault) if (r.hasPosition && !current.contains(r.num)) r];
  }

  void _toggleRemembered(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final turningOn = !_showRemembered;
    setState(() => _showRemembered = turningOn);
    if (turningOn && _remembered.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l.mapRememberedNone)));
    }
  }

  String _when(DateTime time) {
    final d = DateTime.now().difference(time);
    if (d.inMinutes < 1) return l.agoNow;
    if (d.inHours < 1) return l.agoMin(d.inMinutes);
    if (d.inDays < 1) return l.agoHours(d.inHours);
    return l.agoDays(d.inDays);
  }

  void _showRememberedNode(BuildContext context, BastionNodeRecord r) {
    showModalBottomSheet<void>(context: context, builder: (sheet) => SafeArea(child: ListTile(
      leading: const Icon(Icons.history),
      title: Text(r.displayName),
      subtitle: Text('${l.mapLastSeen(_when(r.lastSeen))}\n${r.latitude!.toStringAsFixed(5)}, ${r.longitude!.toStringAsFixed(5)}\n${l.mapRememberedNote}'),
    )));
  }

  void _showRally(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(child: AnimatedBuilder(
        animation: widget.radio,
        builder: (sheetContext, _) {
          final units = BastionPreferences.instance.units;
          final rallies = widget.radio.waypoints.where(BastionRoutes.isRally).toList();
          final routes = BastionRoutes.group(widget.radio.waypoints);
          final type = Theme.of(sheetContext).textTheme;
          return ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
            Text(l.mapRallyRoutes, style: type.titleLarge),
            const SizedBox(height: 4),
            Text(l.mapRallyIntro),
            const SizedBox(height: 12),
            Text(l.mapRallyPoints, style: type.titleSmall),
            if (rallies.isEmpty)
              ListTile(contentPadding: EdgeInsets.zero, title: Text(l.mapNoneYet)),
            for (final w in rallies)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Text('🚩', style: TextStyle(fontSize: 24)),
                title: Text(w.name),
                subtitle: Text(switch (_fromMe(w.latitude, w.longitude)) {
                  final d? => l.mapDistanceOfYou(BastionUnitFormat.distance(d.distance, units), BastionGeo.compassPoint(d.bearing)),
                  null => l.mapNoOwnPosition,
                }),
                trailing: IconButton(
                  tooltip: l.mapShowOnMap,
                  icon: const Icon(Icons.center_focus_strong),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _map.move(LatLng(w.latitude, w.longitude), 15);
                  },
                ),
              ),
            const SizedBox(height: 8),
            Text(l.mapRoutes, style: type.titleSmall),
            if (widget.radio.routeWatch case final watching?)
              ListTile(
                key: const ValueKey('route-watching'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(l.mapRouteWatching(watching.name,
                    BastionUnitFormat.distance(watching.limitMeters, units))),
                subtitle: Text(_watchLabel(l, watching.watch)),
                trailing: TextButton(
                  key: const ValueKey('route-watch-stop'),
                  onPressed: () => widget.radio.setRouteWatch(null),
                  child: Text(l.mapRouteWatchStop),
                ),
              ),
            if (routes.isEmpty)
              ListTile(contentPadding: EdgeInsets.zero, title: Text(l.mapNoneYet)),
            for (final r in routes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.route),
                title: Text(r.name),
                subtitle: Text([
                  r.complete ? l.mapStops(r.count) : l.mapStopsHeard(r.stops.length, r.count),
                  if (r.stops.length >= 2) BastionUnitFormat.distance(r.lengthMeters, units),
                  r.from == null ? l.mapFromYou : l.mapFromNode(widget.radio.nodeName(r.from!)),
                ].join(' • ')),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (r.stops.length >= 2)
                    IconButton(
                      key: ValueKey('route-watch-${r.name}'),
                      tooltip: l.mapRouteWatchTitle,
                      icon: const Icon(Icons.notification_add_outlined),
                      onPressed: () => _watchRoute(sheetContext, r),
                    ),
                  IconButton(
                  tooltip: l.mapShowOnMap,
                  icon: const Icon(Icons.center_focus_strong),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    final pts = [for (final p in r.points) LatLng(p.latitude, p.longitude)];
                    if (pts.length == 1) {
                      _map.move(pts.single, 15);
                    } else {
                      _map.fitCamera(CameraFit.coordinates(coordinates: pts, padding: const EdgeInsets.all(48)));
                    }
                  },
                ),
                ]),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: widget.radio.isReady
                  ? () {
                      Navigator.pop(sheetContext);
                      setState(() => _planning = []);
                    }
                  : null,
              icon: const Icon(Icons.add_road),
              label: Text(widget.radio.isReady ? l.mapPlanRoute : l.mapConnectForRoutes),
            ),
          ]);
        },
      )),
    );
  }

  /// Asks for a name and shares [plan] as numbered waypoints, a few seconds
  /// apart so the stops don't flood the channel.
  Future<void> _shareRoute(BuildContext context, List<LatLng> plan) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final routeName = await showDialog<String>(
      context: context,
      builder: (_) => _RouteNameDialog(stops: plan.length),
    );
    if (routeName == null || !mounted) return;
    final stops = BastionRoutes.build(
      name: routeName,
      points: [for (final p in plan) (latitude: p.latitude, longitude: p.longitude)],
      newId: BastionWaypointStore.newId,
      expires: DateTime.now().toUtc().add(const Duration(days: 1)),
    );
    setState(() => _sharingRoute = true);
    var sent = 0;
    try {
      for (final stop in stops) {
        if (sent > 0) await Future<void>.delayed(routeStopSpacing);
        await widget.radio.sendWaypoint(stop);
        sent++;
      }
      messenger.showSnackBar(SnackBar(content: Text(l.mapRouteShared(stops.length))));
      if (mounted) setState(() => _planning = null);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(
          l.mapRouteStopped(sent, stops.length, '$error'))));
    } finally {
      if (mounted) setState(() => _sharingRoute = false);
    }
  }

  /// Exports all waypoints and the trails of trip contacts and this radio.
  Future<void> _exportGpx(BuildContext context, Set<int> team, int? local) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final names = {for (final n in widget.radio.nodes) n.num: n.displayName};
    final tracks = [
      for (final num in {?local, ...team})
        if (widget.radio.trailOf(num) case final points when points.isNotEmpty)
          (name: num == local ? 'This radio (${names[num] ?? 'me'})' : names[num] ?? '!${num.toRadixString(16)}',
            points: points),
    ];
    final now = DateTime.now();
    final gpx = BastionGpx.build(waypoints: widget.radio.waypoints, tracks: tracks, createdAt: now);
    try {
      await widget.shareFile('notoryx-${now.toIso8601String().substring(0, 10)}.gpx', gpx);
      messenger.showSnackBar(SnackBar(content: Text(
          l.mapGpxExported(widget.radio.waypoints.length, tracks.length))));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l.mapGpxFailed('$error'))));
    }
  }

  /// Asks how far off [route] is too far and whom to watch, then watches it.
  Future<void> _watchRoute(BuildContext context, SharedRoute route) async {
    final l = AppLocalizations.of(context);
    final units = BastionPreferences.instance.units;
    var limit = 100.0;
    var watch = GeofenceWatch.tripContacts;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, setDialog) => AlertDialog(
          title: Text(l.mapRouteWatchTitle),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(route.name, style: Theme.of(dialog).textTheme.titleSmall),
              const SizedBox(height: 8),
              Text(l.mapRouteWatchLimit),
              Wrap(spacing: 6, children: [
                for (final m in BastionRouteWatch.limits)
                  ChoiceChip(
                    key: ValueKey('route-limit-${m.round()}'),
                    label: Text(BastionUnitFormat.distance(m, units)),
                    selected: m == limit,
                    onSelected: (_) => setDialog(() => limit = m),
                  ),
              ]),
              const SizedBox(height: 8),
              Text(l.mapRouteWatchWho),
              Wrap(spacing: 6, children: [
                for (final w in GeofenceWatch.values)
                  ChoiceChip(
                    label: Text(_watchLabel(l, w)),
                    selected: w == watch,
                    onSelected: (_) => setDialog(() => watch = w),
                  ),
              ]),
              const SizedBox(height: 8),
              Text(l.mapRouteWatchHint, style: Theme.of(dialog).textTheme.bodySmall),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(l.commonCancel)),
            FilledButton(
              key: const ValueKey('route-watch-save'),
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(l.mapRouteWatchStart),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final problem = await widget.radio.setRouteWatch(BastionRouteWatch(
      name: route.name,
      points: [for (final p in route.points) (latitude: p.latitude, longitude: p.longitude)],
      limitMeters: limit,
      watch: watch,
    ));
    if (problem != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
    }
  }

  static String _watchLabel(AppLocalizations l, GeofenceWatch watch) => switch (watch) {
        GeofenceWatch.tripContacts => l.mapWatchTrip,
        GeofenceWatch.favorites => l.mapWatchFavorites,
        GeofenceWatch.allNodes => l.mapWatchAll,
      };

  static String _alertLabel(AppLocalizations l, GeofenceAlertOn on) => switch (on) {
        GeofenceAlertOn.arrive => l.mapAlertArrive,
        GeofenceAlertOn.leave => l.mapAlertLeave,
        GeofenceAlertOn.both => l.mapAlertBoth,
      };

  /// Zones that alert on the phone when watched nodes arrive or leave.
  void _showZones(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: AnimatedBuilder(
          animation: widget.radio,
          builder: (sheetContext, _) {
            final zones = widget.radio.geofences;
            final units = BastionPreferences.instance.units;
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              children: [
                Text(l.mapZones, style: Theme.of(sheetContext).textTheme.titleLarge),
                Text(l.mapZonesIntro),
                const SizedBox(height: 8),
                if (zones.isEmpty) ListTile(contentPadding: EdgeInsets.zero, title: Text(l.mapNoZones)),
                for (final zone in zones)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.fence),
                    title: Text(zone.name),
                    subtitle: Text(l.mapZoneSummary(BastionUnitFormat.distance(zone.radiusMeters, units),
                        _watchLabel(l, zone.watch), _alertLabel(l, zone.alertOn))),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _map.move(LatLng(zone.latitude, zone.longitude), 14);
                    },
                    trailing: IconButton(
                      tooltip: l.mapDeleteZone(zone.name),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final problem = await widget.radio.removeGeofence(zone.id);
                        if (problem != null) messenger.showSnackBar(SnackBar(content: Text(problem)));
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: Text(l.mapAddZone),
                  onPressed: zones.length >= BastionGeofenceStore.maxZones
                      ? null
                      : () async {
                          final zone = await showDialog<BastionGeofence>(
                            context: sheetContext,
                            builder: (_) => _ZoneDialog(center: _map.camera.center),
                          );
                          if (zone == null) return;
                          final problem = await widget.radio.saveGeofence(zone);
                          if (problem != null) messenger.showSnackBar(SnackBar(content: Text(problem)));
                        },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showTeam(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: AnimatedBuilder(
          animation: widget.radio,
          builder: (sheetContext, _) {
            final members = _teamStatus();
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                ListTile(
                  title: Text(l.mapTeam, style: Theme.of(sheetContext).textTheme.titleLarge),
                  subtitle: Text(l.mapTeamIntro),
                ),
                if (members.isEmpty)
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l.mapNoTeam),
                    subtitle: Text(l.mapNoTeamHint),
                  ),
                for (final m in members)
                  ListTile(
                    leading: Icon(switch (m.freshness) {
                      TeamFreshness.fresh => Icons.check_circle_outline,
                      TeamFreshness.stale => Icons.schedule,
                      TeamFreshness.lost => Icons.warning_amber_outlined,
                      TeamFreshness.unknown => Icons.help_outline,
                    }),
                    title: Text(m.name),
                    subtitle: Text(m.summaryIn(BastionPreferences.instance.units)),
                    trailing: Text(switch (m.freshness) {
                      TeamFreshness.fresh => l.mapFreshOk,
                      TeamFreshness.stale => l.mapFreshQuiet,
                      TeamFreshness.lost => l.mapFreshLost,
                      TeamFreshness.unknown => '—',
                    }, style: const TextStyle(fontWeight: FontWeight.bold)),
                    enabled: m.hasPosition,
                    onTap: !m.hasPosition
                        ? null
                        : () {
                            final node = widget.radio.nodes.firstWhere((n) => n.num == m.num);
                            Navigator.of(sheetContext).pop();
                            _map.move(LatLng(node.latitude!, node.longitude!), 15);
                          },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _createWaypoint(BuildContext context, LatLng point) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!widget.radio.isReady) {
      messenger.showSnackBar(SnackBar(content: Text(l.mapConnectForWaypoints)));
      return;
    }
    final waypoint = await showDialog<MeshWaypoint>(
      context: context,
      builder: (_) => _WaypointDialog(point: point, localNodeNum: widget.radio.localNodeNum),
    );
    if (waypoint == null) return;
    try {
      await widget.radio.sendWaypoint(waypoint);
      messenger.showSnackBar(SnackBar(content: Text(l.mapWaypointShared(waypoint.name))));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l.mapWaypointFailed('$error'))));
    }
  }

  void _showWaypoint(BuildContext context, MeshWaypoint waypoint) {
    final l = AppLocalizations.of(context);
    String? sender;
    if (waypoint.from != null) {
      sender = '!${waypoint.from!.toRadixString(16).padLeft(8, '0')}';
      for (final node in widget.radio.nodes) {
        if (node.num == waypoint.from) sender = node.displayName;
      }
    }
    final canDelete = widget.radio.isReady && widget.radio.canEditWaypoint(waypoint);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${waypoint.iconText} ${waypoint.name}',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              if (waypoint.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(waypoint.description),
              ],
              const SizedBox(height: 12),
              Text('${waypoint.latitude.toStringAsFixed(5)}, ${waypoint.longitude.toStringAsFixed(5)}'),
              Text(waypoint.expires == null
                  ? l.mapNeverExpires
                  : l.mapExpires(waypoint.expires!.toLocal().toString().substring(0, 16))),
              if (sender != null) Text(l.mapSharedBy(sender)),
              if (waypoint.lockedTo != 0) Text(l.mapLocked),
              const SizedBox(height: 12),
              if (canDelete)
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.mapDeleteEveryone),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(sheetContext).pop();
                    try {
                      await widget.radio.deleteWaypoint(waypoint);
                      messenger.showSnackBar(SnackBar(content: Text(l.mapDeleted(waypoint.name))));
                    } catch (error) {
                      messenger.showSnackBar(SnackBar(content: Text(l.mapDeleteFailed('$error'))));
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNode(BuildContext context, MeshtasticNode node) {
    final localNode = widget.radio.localNode;
    final distance = localNode != null && localNode.hasPosition && localNode.num != node.num
        ? BastionGeo.distanceMeters(
            localNode.latitude!, localNode.longitude!, node.latitude!, node.longitude!)
        : null;
    String ago(DateTime? time) {
      if (time == null) return l.mapUnknown;
      final d = DateTime.now().difference(time);
      if (d.inMinutes < 1) return l.agoNow;
      if (d.inHours < 1) return l.agoMin(d.inMinutes);
      if (d.inDays < 1) return l.agoHours(d.inHours);
      return l.agoDays(d.inDays);
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(node.displayName, style: Theme.of(context).textTheme.titleLarge),
              if (node.shortName != null) Text(node.shortName!),
              const SizedBox(height: 12),
              Text('${node.latitude!.toStringAsFixed(5)}, ${node.longitude!.toStringAsFixed(5)}'
                  '${node.altitudeMeters == null ? '' : ' • ${BastionUnitFormat.altitude(node.altitudeMeters!, BastionPreferences.instance.units)}'}'),
              if (distance != null)
                Text(l.mapFromThisRadio(BastionUnitFormat.distance(distance, BastionPreferences.instance.units))),
              Text(l.mapPositionHeard(ago(node.positionTime), ago(node.lastHeard))),
              if (node.snr != null || node.hopsAway != null || node.noRfReason != null)
                Text([
                  if (node.snr != null) 'SNR ${node.snr!.toStringAsFixed(1)} dB' else node.noRfReason!,
                  if (node.hopsAway != null)
                    node.hopsAway == 0 ? l.mapDirect : l.hopsCount(node.hopsAway!),
                ].join(' • ')),
              if (node.batteryLevel != null)
                Text(node.batteryLevel! > 100
                    ? l.mapBatteryExternal
                    : l.mapBattery(node.batteryLevel!)),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.info_outline),
                label: Text(l.mapOpenDetails),
                onPressed: () {
                  Navigator.of(context)
                    ..pop()
                    ..push(MaterialPageRoute<void>(
                      builder: (_) => NodeDetailPage(radio: widget.radio, nodeNum: node.num),
                    ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodePin extends StatelessWidget {
  const _NodePin({required this.node, required this.isLocal, required this.onTap, this.team});

  final MeshtasticNode node;
  final bool isLocal;
  final VoidCallback onTap;

  /// Set for trip contacts: the pin shows how old their position is.
  final TeamMemberStatus? team;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final label = node.shortName ?? node.displayName.characters.take(4).toString();
    return Semantics(
      button: true,
      label: '${node.displayName}${isLocal ? l.mapThisRadioSuffix : ''}'
          '${team == null ? '' : l.mapTripContactSuffix(team!.summaryIn(BastionPreferences.instance.units))}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isLocal ? MapPage.accent : const Color(0xFF151713),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MapPage.accent, width: 2),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isLocal ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            if (team?.positionAgo case final age?)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                color: Colors.black.withValues(alpha: 0.7),
                child: Text(TeamMemberStatus.ageLabel(age),
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            Icon(isLocal ? Icons.my_location : team != null ? Icons.person_pin_circle : Icons.location_on,
                color: MapPage.accent, size: 26),
          ],
        ),
      ),
    );
  }
}

/// A marker shared by ATAK. The side is shown by shape and in words, not only colour.
class _TakPin extends StatelessWidget {
  const _TakPin({required this.marker, required this.onTap});

  final TakMarker marker;
  final VoidCallback onTap;

  static IconData icon(TakMarker m) => m.isPoint
      ? Icons.push_pin_outlined
      : switch (m.affiliation) {
          TakAffiliation.friendly => Icons.shield_outlined,
          TakAffiliation.hostile => Icons.warning_amber_rounded,
          TakAffiliation.neutral => Icons.crop_square,
          TakAffiliation.unknown => Icons.help_outline,
        };

  static String kind(AppLocalizations l, TakMarker m) => m.isPoint
      ? l.takPoint
      : switch (m.affiliation) {
          TakAffiliation.friendly => l.takFriendly,
          TakAffiliation.hostile => l.takHostile,
          TakAffiliation.neutral => l.takNeutral,
          TakAffiliation.unknown => l.takUnknown,
        };

  static Color _color(TakMarker m) => m.isPoint
      ? Colors.black87
      : switch (m.affiliation) {
          TakAffiliation.friendly => const Color(0xFF0B5CAD),
          TakAffiliation.hostile => const Color(0xFFB3261E),
          TakAffiliation.neutral => const Color(0xFF1C7442),
          TakAffiliation.unknown => const Color(0xFF835500),
        };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l.mapTakPin(kind(l, marker), marker.callsign),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _color(marker), width: 2)),
              padding: const EdgeInsets.all(3),
              child: Icon(icon(marker), size: 22, color: _color(marker)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: Colors.black54,
              child: Text(marker.callsign,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _WaypointPin extends StatelessWidget {
  const _WaypointPin({required this.waypoint, required this.onTap});

  final MeshWaypoint waypoint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${BastionRoutes.isRally(waypoint) ? AppLocalizations.of(context).mapRallyPoint : AppLocalizations.of(context).mapWaypoint} ${waypoint.name}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(waypoint.iconText, style: const TextStyle(fontSize: 26)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                color: BastionRoutes.isRally(waypoint) ? MapPage.accent : Colors.black54,
                child: Text(
                  waypoint.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: BastionRoutes.isRally(waypoint) ? Colors.black : Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
}

class _WaypointDialog extends StatefulWidget {
  const _WaypointDialog({required this.point, required this.localNodeNum});

  final LatLng point;
  final int? localNodeNum;

  @override
  State<_WaypointDialog> createState() => _WaypointDialogState();
}

class _WaypointDialogState extends State<_WaypointDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _icon = '📍';
  Duration? _lifetime = const Duration(days: 1);
  bool _locked = false;

  static const _icons = ['📍', '⛺', '🚩', '⚠️', '💧', '🚗', '🏠', '📡'];
  List<(String, Duration?)> _lifetimes(AppLocalizations l) => [
        (l.mapExpireHour, const Duration(hours: 1)),
        (l.mapExpireDay, const Duration(days: 1)),
        (l.mapExpireWeek, const Duration(days: 7)),
        (l.mapExpireNever, null),
      ];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = _name.text.trim();
    return AlertDialog(
      title: Text(l.mapNewWaypoint),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.point.latitude.toStringAsFixed(5)}, ${widget.point.longitude.toStringAsFixed(5)}'),
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: BastionWaypointStore.maxNameLength,
              decoration: InputDecoration(labelText: l.mapName),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _description,
              maxLength: BastionWaypointStore.maxDescriptionLength,
              decoration: InputDecoration(labelText: l.mapDescription),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Text('🚩', style: TextStyle(fontSize: 22)),
              title: Text(l.mapRallyPoint),
              subtitle: Text(l.mapRallySub),
              value: _icon == '🚩',
              onChanged: (v) => setState(() {
                _icon = v ? '🚩' : '📍';
                if (v && _name.text.trim().isEmpty) _name.text = 'Rally point';
              }),
            ),
            Wrap(
              spacing: 4,
              children: [
                for (final icon in _icons)
                  ChoiceChip(
                    label: Text(icon, style: const TextStyle(fontSize: 18)),
                    selected: _icon == icon,
                    onSelected: (_) => setState(() => _icon = icon),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Duration?>(
              initialValue: _lifetime,
              decoration: InputDecoration(labelText: l.mapExpiresAfter),
              items: [
                for (final (label, value) in _lifetimes(l))
                  DropdownMenuItem(value: value, child: Text(label)),
              ],
              onChanged: (v) => setState(() => _lifetime = v),
            ),
            if (widget.localNodeNum != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.mapOnlyMe),
                value: _locked,
                onChanged: (v) => setState(() => _locked = v),
              ),
            Text(l.mapSharedChannel0, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).commonCancel)),
        FilledButton(
          onPressed: name.isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    MeshWaypoint(
                      id: BastionWaypointStore.newId(),
                      latitude: widget.point.latitude,
                      longitude: widget.point.longitude,
                      name: name,
                      description: _description.text.trim(),
                      icon: _icon.runes.first,
                      expires: _lifetime == null ? null : DateTime.now().toUtc().add(_lifetime!),
                      lockedTo: _locked ? widget.localNodeNum! : 0,
                    ),
                  ),
          child: Text(AppLocalizations.of(context).mapShare),
        ),
      ],
    );
  }
}

class _ZoneDialog extends StatefulWidget {
  const _ZoneDialog({required this.center});

  final LatLng center;

  @override
  State<_ZoneDialog> createState() => _ZoneDialogState();
}

class _ZoneDialogState extends State<_ZoneDialog> {
  final _name = TextEditingController();
  double _radius = 500;
  GeofenceWatch _watch = GeofenceWatch.tripContacts;
  GeofenceAlertOn _alertOn = GeofenceAlertOn.both;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = _name.text.trim();
    final units = BastionPreferences.instance.units;
    return AlertDialog(
      title: Text(l.mapNewZone),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.mapCenteredOn(widget.center.latitude.toStringAsFixed(5), widget.center.longitude.toStringAsFixed(5))),
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: 30,
              decoration: InputDecoration(labelText: l.mapZoneName),
              onChanged: (_) => setState(() {}),
            ),
            DropdownButtonFormField<double>(
              initialValue: _radius,
              decoration: InputDecoration(labelText: l.mapRadius),
              items: [
                for (final r in BastionGeofence.radiusChoices)
                  DropdownMenuItem(value: r, child: Text(BastionUnitFormat.distance(r, units))),
              ],
              onChanged: (v) => setState(() => _radius = v ?? _radius),
            ),
            DropdownButtonFormField<GeofenceWatch>(
              initialValue: _watch,
              decoration: InputDecoration(labelText: l.mapWatch),
              items: [
                for (final w in GeofenceWatch.values)
                  DropdownMenuItem(value: w, child: Text(_MapPageState._watchLabel(l, w))),
              ],
              onChanged: (v) => setState(() => _watch = v ?? _watch),
            ),
            DropdownButtonFormField<GeofenceAlertOn>(
              initialValue: _alertOn,
              decoration: InputDecoration(labelText: l.mapAlertWhen),
              items: [
                for (final a in GeofenceAlertOn.values)
                  DropdownMenuItem(value: a, child: Text(_MapPageState._alertLabel(l, a))),
              ],
              onChanged: (v) => setState(() => _alertOn = v ?? _alertOn),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).commonCancel)),
        FilledButton(
          onPressed: name.isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    BastionGeofence(
                      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
                      name: name,
                      latitude: widget.center.latitude,
                      longitude: widget.center.longitude,
                      radiusMeters: _radius,
                      watch: _watch,
                      alertOn: _alertOn,
                    ),
                  ),
          child: Text(l.mapAdd),
        ),
      ],
    );
  }
}

/// The OpenStreetMap credit. Unlike the stock attribution bar it wraps
/// onto a second line with large text instead of running off the screen.
class _MapAttribution extends StatelessWidget {
  const _MapAttribution({this.topo = false});

  /// Adds the SRTM and OpenTopoMap credits the topo tiles require.
  final bool topo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface);
    return SafeArea(child: Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: .85),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Wrap(alignment: WrapAlignment.end, children: [
              Text('© ', style: style),
              Text('OpenStreetMap contributors', style: style),
              if (topo) Text(', SRTM | © OpenTopoMap (CC-BY-SA)', style: style),
            ]),
          ),
        ),
      ),
    ));
  }
}

/// Gap between route stops, so sharing a route doesn't flood the channel.
@visibleForTesting
Duration routeStopSpacing = const Duration(seconds: 3);

class _RouteNameDialog extends StatefulWidget {
  const _RouteNameDialog({required this.stops});
  final int stops;

  @override
  State<_RouteNameDialog> createState() => _RouteNameDialogState();
}

class _RouteNameDialogState extends State<_RouteNameDialog> {
  final _name = TextEditingController(text: 'Route');

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context).mapShareRoute),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: _name, autofocus: true, maxLength: 22,
            decoration: InputDecoration(labelText: AppLocalizations.of(context).mapRouteName)),
          Text(AppLocalizations.of(context).mapRouteSends(widget.stops)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, _name.text), child: Text(AppLocalizations.of(context).mapShare)),
        ],
      );
}

/// The lowest map zoom at which the offline file is drawn: a few levels
/// below its own lowest zoom when its area is known (the tiles shrink but
/// stay few), one level otherwise.
@visibleForTesting
double offlineLayerMinZoom(OfflineMapInfo info) =>
    (info.minZoom - (info.bounds == null ? 1 : 3)).clamp(0, 30).toDouble();

/// The file's area, so the map only asks it for tiles it can have.
@visibleForTesting
LatLngBounds? offlineLayerBounds(OfflineMapInfo info) => switch (info.bounds) {
      (final w, final s, final e, final n) => LatLngBounds(LatLng(s, w), LatLng(n, e)),
      null => null,
    };
