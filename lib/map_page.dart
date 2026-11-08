import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import 'link_planner_page.dart';
import 'node_detail_page.dart';
import 'services/bastion_geo.dart';
import 'services/bastion_geofences.dart';
import 'services/bastion_gpx.dart';
import 'services/bastion_heard_filter.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_routes.dart';
import 'services/bastion_units.dart';
import 'services/bastion_team.dart';
import 'services/bastion_waypoints.dart';
import 'services/meshtastic_node_database.dart';
import 'services/meshtastic_radio_coordinator.dart';

/// Mesh nodes with a reported position on an OpenStreetMap base map.
///
/// Tiles load from tile.openstreetmap.org and need internet access; node
/// positions come only from the radio.
class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.radio, this.shareFile = _shareFile});

  final MeshtasticRadioCoordinator radio;

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
  final MapController _map = MapController();
  bool _fitted = false;
  bool _showLinks = true;
  bool _showTrails = true;

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

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  List<MeshtasticNode> get _placed {
    final heard = BastionPreferences.instance.heardWithin;
    final now = DateTime.now();
    final local = widget.radio.localNode?.num;
    return widget.radio.nodes
        .where((n) => n.hasPosition && heard.matches(n.lastHeard, now, always: n.num == local))
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
        animation: widget.radio,
        builder: (context, _) {
          final placed = _placed;
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
                  MarkerLayer(
                    markers: [
                      for (final waypoint in widget.radio.waypoints)
                        Marker(
                          point: LatLng(waypoint.latitude, waypoint.longitude),
                          width: 120,
                          height: 56,
                          child: _WaypointPin(
                            waypoint: waypoint,
                            onTap: () => _showWaypoint(context, waypoint),
                          ),
                        ),
                      for (final node in placed)
                        Marker(
                          point: LatLng(node.latitude!, node.longitude!),
                          width: 72,
                          height: team.contains(node.num) ? 80 : 64,
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
                                    ? 'No node has reported a position yet'
                                    : 'Connect a radio to show node positions')
                                : '${placed.length} of ${widget.radio.nodes.length} nodes placed'
                                    '${widget.radio.waypoints.isEmpty ? '' : ' • ${widget.radio.waypoints.length} waypoints'}'
                                    '\nLong-press the map to drop a waypoint',
                          ),
                        ),
                      ]),
                      Wrap(alignment: WrapAlignment.end, children: [
                        PopupMenuButton<BastionHeardWithin>(
                          key: const ValueKey('map-heard-filter'),
                          tooltip: 'Show nodes heard within',
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
                                child: Text(v == BastionHeardWithin.any ? 'Heard any time' : 'Heard in last ${v.label}'),
                              ),
                          ],
                        ),
                        IconButton(
                          tooltip: _topo ? 'Show street map' : 'Show topographic map',
                          icon: Icon(_topo ? Icons.map_outlined : Icons.terrain),
                          onPressed: () => setState(() => _topo = !_topo),
                        ),
                        IconButton(
                          tooltip: 'Link planner',
                          icon: const Icon(Icons.settings_input_antenna),
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => LinkPlannerPage(radio: widget.radio))),
                        ),
                        IconButton(
                          tooltip: 'Rally points & routes',
                          icon: Badge(
                            isLabelVisible: widget.radio.waypoints.any(BastionRoutes.isRally),
                            label: Text('${widget.radio.waypoints.where(BastionRoutes.isRally).length}'),
                            child: const Icon(Icons.flag_outlined),
                          ),
                          onPressed: () => _showRally(context),
                        ),
                        IconButton(
                          tooltip: 'Team',
                          icon: Badge(
                            isLabelVisible: team.isNotEmpty,
                            label: Text('${team.length}'),
                            child: const Icon(Icons.groups_outlined),
                          ),
                          onPressed: () => _showTeam(context),
                        ),
                        IconButton(
                          tooltip: 'Zones',
                          icon: Badge(
                            isLabelVisible: widget.radio.geofences.isNotEmpty,
                            label: Text('${widget.radio.geofences.length}'),
                            child: const Icon(Icons.fence),
                          ),
                          onPressed: () => _showZones(context),
                        ),
                        if (trails.isNotEmpty || widget.radio.waypoints.isNotEmpty)
                          IconButton(
                            tooltip: 'Export GPX',
                            icon: const Icon(Icons.ios_share),
                            onPressed: () => _exportGpx(context, team, local),
                          ),
                        if (trails.isNotEmpty)
                          IconButton(
                            tooltip: _showTrails ? 'Hide trails' : 'Show trails',
                            icon: Icon(_showTrails ? Icons.timeline : Icons.timeline_outlined),
                            onPressed: () => setState(() => _showTrails = !_showTrails),
                          ),
                        if (widget.radio.neighborReports.isNotEmpty)
                          IconButton(
                            tooltip: _showLinks ? 'Hide radio links' : 'Show radio links',
                            icon: Icon(_showLinks ? Icons.hub : Icons.hub_outlined),
                            onPressed: () => setState(() => _showLinks = !_showLinks),
                          ),
                        if (placed.isNotEmpty)
                          IconButton(
                            tooltip: 'Show all nodes',
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
                            ? 'Tap the map to add stops, in order. Up to ${BastionRoutes.maxStops}.'
                            : '${plan.length} of ${BastionRoutes.maxStops} stops • '
                              '${BastionUnitFormat.distance(BastionRoutes.lengthOf([for (final p in plan) (latitude: p.latitude, longitude: p.longitude)]), BastionPreferences.instance.units)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      )),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: [
                        TextButton(onPressed: _sharingRoute ? null : () => setState(() => _planning = null),
                          child: const Text('Cancel')),
                        OutlinedButton.icon(
                          onPressed: plan.isEmpty || _sharingRoute ? null : () => setState(plan.removeLast),
                          icon: const Icon(Icons.undo), label: const Text('Undo')),
                        FilledButton.icon(
                          onPressed: plan.length < 2 || _sharingRoute ? null : () => _shareRoute(context, plan),
                          icon: _sharingRoute
                              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.share_location),
                          label: const Text('Share route')),
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
            Text('Rally points & routes', style: type.titleLarge),
            const SizedBox(height: 4),
            const Text('Rally points are where everyone should meet. Drop one with a long-press and '
                'choose "Rally point". Routes are shared as numbered waypoints, so other Meshtastic apps see the stops too.'),
            const SizedBox(height: 12),
            Text('Rally points', style: type.titleSmall),
            if (rallies.isEmpty)
              const ListTile(contentPadding: EdgeInsets.zero, title: Text('None yet.')),
            for (final w in rallies)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Text('🚩', style: TextStyle(fontSize: 24)),
                title: Text(w.name),
                subtitle: Text(switch (_fromMe(w.latitude, w.longitude)) {
                  final d? => '${BastionUnitFormat.distance(d.distance, units)} ${BastionGeo.compassPoint(d.bearing)} of you',
                  null => 'Your radio has no position yet',
                }),
                trailing: IconButton(
                  tooltip: 'Show on map',
                  icon: const Icon(Icons.center_focus_strong),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _map.move(LatLng(w.latitude, w.longitude), 15);
                  },
                ),
              ),
            const SizedBox(height: 8),
            Text('Routes', style: type.titleSmall),
            if (routes.isEmpty)
              const ListTile(contentPadding: EdgeInsets.zero, title: Text('None yet.')),
            for (final r in routes)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.route),
                title: Text(r.name),
                subtitle: Text([
                  r.complete ? '${r.count} stops' : '${r.stops.length} of ${r.count} stops heard',
                  if (r.stops.length >= 2) BastionUnitFormat.distance(r.lengthMeters, units),
                  r.from == null ? 'from you' : 'from ${widget.radio.nodeName(r.from!)}',
                ].join(' • ')),
                trailing: IconButton(
                  tooltip: 'Show on map',
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
              label: Text(widget.radio.isReady ? 'Plan a route' : 'Connect a radio to share routes'),
            ),
          ]);
        },
      )),
    );
  }

  /// Asks for a name and shares [plan] as numbered waypoints, a few seconds
  /// apart so the stops don't flood the channel.
  Future<void> _shareRoute(BuildContext context, List<LatLng> plan) async {
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
      messenger.showSnackBar(SnackBar(content: Text('Route shared: ${stops.length} stops on channel 0.')));
      if (mounted) setState(() => _planning = null);
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(
          'Route stopped after $sent of ${stops.length} stops: $error')));
    } finally {
      if (mounted) setState(() => _sharingRoute = false);
    }
  }

  /// Exports all waypoints and the trails of trip contacts and this radio.
  Future<void> _exportGpx(BuildContext context, Set<int> team, int? local) async {
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
          'Exported ${widget.radio.waypoints.length} waypoints and ${tracks.length} trails as GPX.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Could not export GPX: $error')));
    }
  }

  static String _watchLabel(GeofenceWatch watch) => switch (watch) {
        GeofenceWatch.tripContacts => 'Trip contacts',
        GeofenceWatch.favorites => 'Favorites',
        GeofenceWatch.allNodes => 'All nodes',
      };

  static String _alertLabel(GeofenceAlertOn on) => switch (on) {
        GeofenceAlertOn.arrive => 'arrive',
        GeofenceAlertOn.leave => 'leave',
        GeofenceAlertOn.both => 'arrive or leave',
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
                Text('Zones', style: Theme.of(sheetContext).textTheme.titleLarge),
                const Text('Get a phone alert when someone arrives at or leaves a place, '
                    'like camp or the trailhead. Alerts need the radio connected; nothing is sent over the mesh.'),
                const SizedBox(height: 8),
                if (zones.isEmpty) const ListTile(contentPadding: EdgeInsets.zero, title: Text('No zones yet.')),
                for (final zone in zones)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.fence),
                    title: Text(zone.name),
                    subtitle: Text('${BastionUnitFormat.distance(zone.radiusMeters, units)} radius • '
                        '${_watchLabel(zone.watch)} • alert when they ${_alertLabel(zone.alertOn)}'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _map.move(LatLng(zone.latitude, zone.longitude), 14);
                    },
                    trailing: IconButton(
                      tooltip: 'Delete ${zone.name}',
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
                  label: const Text('Add zone at map center'),
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
                  title: Text('Team', style: Theme.of(sheetContext).textTheme.titleLarge),
                  subtitle: const Text('Your trip contacts. Tap one to find them on the map.'),
                ),
                if (members.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('No trip contacts yet'),
                    subtitle: Text('Add up to 6 people on HOME → Trip. They show here and stand out on the map.'),
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
                      TeamFreshness.fresh => 'OK',
                      TeamFreshness.stale => 'QUIET',
                      TeamFreshness.lost => 'LOST',
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
    final messenger = ScaffoldMessenger.of(context);
    if (!widget.radio.isReady) {
      messenger.showSnackBar(const SnackBar(content: Text('Connect a radio to share waypoints.')));
      return;
    }
    final waypoint = await showDialog<MeshWaypoint>(
      context: context,
      builder: (_) => _WaypointDialog(point: point, localNodeNum: widget.radio.localNodeNum),
    );
    if (waypoint == null) return;
    try {
      await widget.radio.sendWaypoint(waypoint);
      messenger.showSnackBar(SnackBar(content: Text('Waypoint "${waypoint.name}" shared on channel 0.')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Could not share waypoint: $error')));
    }
  }

  void _showWaypoint(BuildContext context, MeshWaypoint waypoint) {
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
                  ? 'Never expires'
                  : 'Expires ${waypoint.expires!.toLocal().toString().substring(0, 16)}'),
              if (sender != null) Text('Shared by $sender'),
              if (waypoint.lockedTo != 0) const Text('Locked to its creator'),
              const SizedBox(height: 12),
              if (canDelete)
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete for everyone'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(sheetContext).pop();
                    try {
                      await widget.radio.deleteWaypoint(waypoint);
                      messenger.showSnackBar(SnackBar(content: Text('Deleted "${waypoint.name}".')));
                    } catch (error) {
                      messenger.showSnackBar(SnackBar(content: Text('Could not delete: $error')));
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
      if (time == null) return 'unknown';
      final d = DateTime.now().difference(time);
      if (d.inMinutes < 1) return 'just now';
      if (d.inHours < 1) return '${d.inMinutes} min ago';
      if (d.inDays < 1) return '${d.inHours} h ago';
      return '${d.inDays} d ago';
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
                Text('${BastionUnitFormat.distance(distance, BastionPreferences.instance.units)} from this radio'),
              Text('Position: ${ago(node.positionTime)} • Heard: ${ago(node.lastHeard)}'),
              if (node.snr != null || node.hopsAway != null || node.noRfReason != null)
                Text([
                  if (node.snr != null) 'SNR ${node.snr!.toStringAsFixed(1)} dB' else node.noRfReason!,
                  if (node.hopsAway != null)
                    node.hopsAway == 0 ? 'direct' : '${node.hopsAway} hops',
                ].join(' • ')),
              if (node.batteryLevel != null)
                Text(node.batteryLevel! > 100
                    ? 'Battery: external power'
                    : 'Battery: ${node.batteryLevel}%'),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.info_outline),
                label: const Text('Open details'),
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
    final label = node.shortName ?? node.displayName.characters.take(4).toString();
    return Semantics(
      button: true,
      label: '${node.displayName}${isLocal ? ', this radio' : ''}'
          '${team == null ? '' : ', trip contact, ${team!.summaryIn(BastionPreferences.instance.units)}'}',
      child: GestureDetector(
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
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
              ),
            Icon(isLocal ? Icons.my_location : team != null ? Icons.person_pin_circle : Icons.location_on,
                color: MapPage.accent, size: 26),
          ],
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
        label: '${BastionRoutes.isRally(waypoint) ? 'Rally point' : 'Waypoint'} ${waypoint.name}',
        child: GestureDetector(
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
                  style: const TextStyle(color: Colors.white, fontSize: 11),
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
  static const _lifetimes = <(String, Duration?)>[
    ('1 hour', Duration(hours: 1)),
    ('1 day', Duration(days: 1)),
    ('1 week', Duration(days: 7)),
    ('Never', null),
  ];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.text.trim();
    return AlertDialog(
      title: const Text('New waypoint'),
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
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => setState(() {}),
            ),
            TextField(
              controller: _description,
              maxLength: BastionWaypointStore.maxDescriptionLength,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Text('🚩', style: TextStyle(fontSize: 22)),
              title: const Text('Rally point'),
              subtitle: const Text('Where everyone should meet'),
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
              decoration: const InputDecoration(labelText: 'Expires after'),
              items: [
                for (final (label, value) in _lifetimes)
                  DropdownMenuItem(value: value, child: Text(label)),
              ],
              onChanged: (v) => setState(() => _lifetime = v),
            ),
            if (widget.localNodeNum != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Only I can edit or delete'),
                value: _locked,
                onChanged: (v) => setState(() => _locked = v),
              ),
            Text('Shared with everyone on channel 0.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
          child: const Text('Share'),
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
    final name = _name.text.trim();
    final units = BastionPreferences.instance.units;
    return AlertDialog(
      title: const Text('New zone'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Centered on ${widget.center.latitude.toStringAsFixed(5)}, '
                '${widget.center.longitude.toStringAsFixed(5)}'),
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: 30,
              decoration: const InputDecoration(labelText: 'Name, e.g. Camp'),
              onChanged: (_) => setState(() {}),
            ),
            DropdownButtonFormField<double>(
              initialValue: _radius,
              decoration: const InputDecoration(labelText: 'Radius'),
              items: [
                for (final r in BastionGeofence.radiusChoices)
                  DropdownMenuItem(value: r, child: Text(BastionUnitFormat.distance(r, units))),
              ],
              onChanged: (v) => setState(() => _radius = v ?? _radius),
            ),
            DropdownButtonFormField<GeofenceWatch>(
              initialValue: _watch,
              decoration: const InputDecoration(labelText: 'Watch'),
              items: [
                for (final w in GeofenceWatch.values)
                  DropdownMenuItem(value: w, child: Text(_MapPageState._watchLabel(w))),
              ],
              onChanged: (v) => setState(() => _watch = v ?? _watch),
            ),
            DropdownButtonFormField<GeofenceAlertOn>(
              initialValue: _alertOn,
              decoration: const InputDecoration(labelText: 'Alert when they'),
              items: [
                for (final a in GeofenceAlertOn.values)
                  DropdownMenuItem(value: a, child: Text(_MapPageState._alertLabel(a))),
              ],
              onChanged: (v) => setState(() => _alertOn = v ?? _alertOn),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
          child: const Text('Add'),
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
        title: const Text('Share route'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(controller: _name, autofocus: true, maxLength: 22,
            decoration: const InputDecoration(labelText: 'Route name')),
          Text('Sends ${widget.stops} waypoints on channel 0, about 3 seconds apart. '
              'They expire after a day.'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, _name.text), child: const Text('Share')),
        ],
      );
}
