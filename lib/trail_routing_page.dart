import 'dart:async';

import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_map_layers.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_trail_graph.dart';
import 'services/bastion_trail_store.dart';
import 'services/bastion_units.dart';
import 'services/bastion_phone_position.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// Where you are, from the radio's GPS or the phone; null when unknown.
typedef WhereAmI = Future<(double, double)?> Function();

/// Plans walking routes with no signal, over trails downloaded beforehand
/// from OpenStreetMap by area. As on NOTORYX Core.
class TrailRoutingPage extends StatefulWidget {
  const TrailRoutingPage({
    super.key,
    required this.store,
    required this.whereAmI,
    required this.share,
    this.savedPlaces = const [],
    this.layers,
  });

  final BastionTrailStore store;
  final WhereAmI whereAmI;
  final Future<void> Function(String fileName, String text) share;

  /// Your saved waypoints, offered as destinations alongside the area's
  /// named places.
  final List<TrailPlace> savedPlaces;

  /// Defaults to [BastionMapLayers.instance].
  final BastionMapLayers? layers;

  /// Download sizes offered, as the distance from you to each edge.
  static const radii = [5.0, 10.0, 20.0];

  /// Walking pace for the time estimate, on the flat.
  static const walkingKmh = 4.0;

  @override
  State<TrailRoutingPage> createState() => _TrailRoutingPageState();
}

class _TrailRoutingPageState extends State<TrailRoutingPage> {
  final _search = TextEditingController();
  double _radius = 10;
  bool _downloading = false;
  bool _routing = false;
  String? _message;
  List<TrailPlace> _places = const [];
  TrailPlace? _to;
  TrailRouteResult? _route;
  TrailPlace? _routeTo;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPlaces());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    await widget.store.ensureLoaded();
    final places = await widget.store.allPlaces();
    if (mounted) setState(() => _places = [...widget.savedPlaces, ...places]);
  }

  String _problem(AppLocalizations l, TrailDownloadProblem p) => switch (p) {
        TrailDownloadProblem.tooLarge => l.trlTooLarge,
        TrailDownloadProblem.storageFull => l.trlFull,
        TrailDownloadProblem.noTrails => l.trlNoTrails,
        TrailDownloadProblem.failed => l.trlFailed,
      };

  Future<void> _download() async {
    final l = AppLocalizations.of(context);
    setState(() {
      _downloading = true;
      _message = null;
    });
    final here = await widget.whereAmI();
    if (!mounted) return;
    if (here == null) {
      setState(() {
        _downloading = false;
        _message = l.trlNoPosition;
      });
      return;
    }
    final name = l.trlAreaName(MaterialLocalizations.of(context).formatMediumDate(DateTime.now()));
    try {
      await widget.store.download(name, BastionTrailStore.around(here.$1, here.$2, _radius));
      await _loadPlaces();
      if (mounted) setState(() => _message = l.trlSaved);
    } on TrailDownloadException catch (e) {
      if (mounted) setState(() => _message = _problem(l, e.problem));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _plan(TrailPlace to) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _routing = true;
      _route = null;
      _message = null;
    });
    final here = await widget.whereAmI();
    if (!mounted) return;
    if (here == null) {
      setState(() {
        _routing = false;
        _message = l.trlNoPosition;
      });
      return;
    }
    final area = widget.store.areaFor(here.$1, here.$2, to.lat, to.lon);
    if (area == null) {
      setState(() {
        _routing = false;
        _message = l.trlNoArea;
      });
      return;
    }
    try {
      final graph = await widget.store.graphFor(area);
      final route = graph.route(here.$1, here.$2, to.lat, to.lon);
      if (!mounted) return;
      setState(() {
        _route = route;
        _routeTo = to;
        _message = switch (route.problem) {
          null => null,
          TrailRouteProblem.startTooFar => l.trlStartFar,
          TrailRouteProblem.endTooFar => l.trlEndFar,
          TrailRouteProblem.notConnected => l.trlNotConnected,
        };
      });
    } on FormatException {
      if (mounted) setState(() => _message = l.trlDamaged);
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  String _gpx(String name, TrailRouteResult r) {
    final b = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<gpx version="1.1" creator="NOTORYX Connect" xmlns="http://www.topografix.com/GPX/1/1">')
      ..writeln('  <rte><name>${_escape(name)}</name>');
    for (final (lat, lon) in r.points) {
      b.writeln('    <rtept lat="${lat.toStringAsFixed(7)}" lon="${lon.toStringAsFixed(7)}"/>');
    }
    b
      ..writeln('  </rte>')
      ..writeln('</gpx>');
    return b.toString();
  }

  static String _escape(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

  String _kind(AppLocalizations l, TrailPlaceKind k) => switch (k) {
        TrailPlaceKind.peak => l.trlKindPeak,
        TrailPlaceKind.saddle => l.trlKindPass,
        TrailPlaceKind.spring => l.trlKindSpring,
        TrailPlaceKind.hut => l.trlKindHut,
        TrailPlaceKind.campsite => l.trlKindCampsite,
        TrailPlaceKind.viewpoint => l.trlKindViewpoint,
        TrailPlaceKind.shelter => l.trlKindShelter,
        TrailPlaceKind.trailhead => l.trlKindTrailhead,
        TrailPlaceKind.town => l.trlKindTown,
        TrailPlaceKind.locality => l.trlKindLocality,
        TrailPlaceKind.waypoint => l.trlKindWaypoint,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final units = BastionPreferences.instance.units;
    return Scaffold(
      appBar: AppBar(title: Text(l.trlTitle)),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final areas = widget.store.areas;
          final hits = searchPlaces(_places, _search.text, limit: 20);
          final route = _route;
          return ListView(padding: NxSpace.page, children: [
            Text(l.trlIntro),
            if (_message case final m?) ...[
              const SizedBox(height: NxSpace.sm),
              NxBanner(key: const ValueKey('trail-message'), message: m),
            ],
            NxSectionLabel(l.trlPlanSection),
            if (areas.isEmpty)
              Text(l.trlNoAreas)
            else ...[
              TextField(
                key: const ValueKey('trail-search'),
                controller: _search,
                decoration: InputDecoration(labelText: l.trlTo, prefixIcon: const Icon(Icons.search)),
                onChanged: (_) => setState(() {}),
              ),
              for (final p in hits)
                ListTile(
                  key: ValueKey('trail-place-${p.name}'),
                  leading: Icon(p.kind == TrailPlaceKind.waypoint ? Icons.place : Icons.terrain),
                  title: Text(p.name),
                  subtitle: Text(_kind(l, p.kind)),
                  selected: _to == p,
                  onTap: _routing
                      ? null
                      : () {
                          setState(() => _to = p);
                          unawaited(_plan(p));
                        },
                ),
              if (_routing) const Padding(padding: EdgeInsets.all(NxSpace.md), child: LinearProgressIndicator()),
            ],
            if (route != null && route.problem == null && _routeTo != null)
              Card(
                key: const ValueKey('trail-route'),
                child: Padding(
                  padding: const EdgeInsets.all(NxSpace.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.trlRouteTo(_routeTo!.name), style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: NxSpace.xs),
                    Text(l.trlRouteStats(
                      BastionUnitFormat.distance(route.meters, units),
                      _walkTime(route.meters),
                    )),
                    Text(l.trlNoClimb, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: NxSpace.sm),
                    Wrap(spacing: NxSpace.sm, runSpacing: NxSpace.sm, children: [
                      FilledButton.tonalIcon(
                        key: const ValueKey('trail-map'),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await (widget.layers ?? BastionMapLayers.instance)
                                .import(l.trlRouteTo(_routeTo!.name), _gpx(_routeTo!.name, route));
                            messenger.showSnackBar(SnackBar(content: Text(l.tlgOnMap)));
                          } on Object {
                            messenger.showSnackBar(SnackBar(content: Text(l.tlgMapFailed)));
                          }
                        },
                        icon: const Icon(Icons.map_outlined),
                        label: Text(l.tlgShowMap),
                      ),
                      OutlinedButton.icon(
                        key: const ValueKey('trail-gpx'),
                        onPressed: () => widget.share('route.gpx', _gpx(_routeTo!.name, route)),
                        icon: const Icon(Icons.ios_share),
                        label: Text(l.tlgExport),
                      ),
                    ]),
                  ]),
                ),
              ),
            NxSectionLabel(l.trlAreasSection),
            Text(l.trlDownloadHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: NxSpace.sm),
            Wrap(spacing: NxSpace.sm, children: [
              for (final r in TrailRoutingPage.radii)
                ChoiceChip(
                  label: Text(l.trlWithin(BastionUnitFormat.distance(r * 1000, units))),
                  selected: _radius == r,
                  onSelected: _downloading ? null : (_) => setState(() => _radius = r),
                ),
            ]),
            const SizedBox(height: NxSpace.sm),
            FilledButton.icon(
              key: const ValueKey('trail-download'),
              onPressed: _downloading ? null : () => unawaited(_download()),
              icon: _downloading
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download),
              label: Text(l.trlDownload),
            ),
            for (final a in areas)
              ListTile(
                key: ValueKey('trail-area-${a.id}'),
                leading: const Icon(Icons.layers_outlined),
                title: Text(a.name),
                subtitle: Text('${(a.bytes / 1024 / 1024).toStringAsFixed(1)} MB'),
                trailing: IconButton(
                  tooltip: l.tlgDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await widget.store.delete(a.id);
                    await _loadPlaces();
                  },
                ),
              ),
          ]);
        },
      ),
    );
  }

  static String _walkTime(double meters) {
    final minutes = (meters / 1000 / TrailRoutingPage.walkingKmh * 60).round();
    final h = minutes ~/ 60, m = minutes % 60;
    return h > 0 ? '$h h ${m.toString().padLeft(2, '0')} min' : '$m min';
  }
}

/// Where you are: the radio's own GPS when it has a fix, else one fix from
/// the phone (asking for permission if needed).
WhereAmI radioOrPhonePosition(MeshtasticRadioCoordinator radio, {PhoneLocationSource? phone}) => () async {
      final me = radio.localNode;
      if (me != null && me.hasPosition) return (me.latitude!, me.longitude!);
      final source = phone ?? GeolocatorLocationSource();
      if (await source.ensureAccess() != null) return null;
      try {
        final fix = await source.watch().first.timeout(const Duration(seconds: 20));
        return (fix.latitude, fix.longitude);
      } on Object {
        return null;
      }
    };

/// The radio's saved waypoints as destinations.
List<TrailPlace> waypointPlaces(MeshtasticRadioCoordinator radio) => [
      for (final w in radio.waypoints)
        if (w.name.trim().isNotEmpty) TrailPlace(w.name.trim(), TrailPlaceKind.waypoint, w.latitude, w.longitude),
    ];
