import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_coverage_grid.dart';
import 'services/bastion_map_list.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_units.dart';
import 'services/bastion_waypoints.dart';
import 'services/meshtastic_node_database.dart';

/// The map in words: trip contacts, every node, waypoint and weak-coverage
/// square with how far, which way and how fresh, nearest first. For screen
/// readers, large text and anyone who'd rather read than pan a map.
class MapListPage extends StatefulWidget {
  const MapListPage({
    super.key,
    required this.me,
    required this.selfNum,
    required this.nodes,
    required this.waypoints,
    required this.cells,
    this.team = const {},
    this.onOpenNode,
    this.now,
  });

  final (double, double)? me;
  final int? selfNum;
  final List<MeshtasticNode> nodes;
  final List<MeshWaypoint> waypoints;
  final List<CoverageCell> cells;

  /// Node numbers of this trip's contacts; listed in their own section.
  final Set<int> team;

  /// Opens a node's details; when null, node rows are not tappable.
  final void Function(int num)? onOpenNode;
  final DateTime? now;

  @override
  State<MapListPage> createState() => _MapListPageState();
}

class _MapListPageState extends State<MapListPage> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rows = buildMapList(
      me: widget.me,
      selfNum: widget.selfNum,
      team: widget.team,
      nodes: widget.nodes,
      waypoints: widget.waypoints,
      cells: widget.cells,
    );
    final units = BastionPreferences.instance.units;
    final clock = widget.now ?? DateTime.now();
    final searching = _query.trim().isNotEmpty;
    List<MapListRow> matching(List<MapListRow> list) =>
        searching ? [for (final r in list) if (mapListMatches(r, _query)) r] : list;
    final team = matching(rows.team);
    final nodes = matching(rows.nodes);
    final waypoints = matching(rows.waypoints);

    String ago(DateTime? t) {
      if (t == null) return l.mapUnknown;
      final d = clock.difference(t);
      if (d.inMinutes < 1) return l.agoNow;
      if (d.inHours < 1) return l.agoMin(d.inMinutes);
      if (d.inDays < 1) return l.agoHours(d.inHours);
      return l.agoDays(d.inDays);
    }

    String where(MapListRow r) => r.meters == null
        ? l.mlNoOwnPosition
        : l.mlDistanceDir(BastionUnitFormat.distance(r.meters!, units), compassOf(r.bearing!).name);

    String nodeLine(MapListRow r) => [where(r), l.mlHeard(ago(r.heard)), l.mlPositionAge(ago(r.positionAt))].join(' • ');

    Widget section(String title, List<MapListRow> list, String Function(MapListRow) describe,
            String Function(MapListRow) name) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: Semantics(header: true, child: Text('$title (${list.length})',
                style: Theme.of(context).textTheme.titleMedium)),
          ),
          if (list.isEmpty)
            ListTile(title: Text(l.mlNone))
          else
            for (final r in list)
              ListTile(
                title: Text(name(r)),
                subtitle: Text(describe(r)),
                onTap: r.num != null && widget.onOpenNode != null ? () => widget.onOpenNode!(r.num!) : null,
              ),
        ]);

    final nothing = searching && team.isEmpty && nodes.isEmpty && waypoints.isEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(l.mlTitle)),
      body: ListView(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Text(l.mlIntro)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            key: const ValueKey('map-list-search'),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.mlSearch),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        if (nothing)
          ListTile(title: Text(l.mlNoMatch(_query.trim())))
        else ...[
          if (rows.team.isNotEmpty) section(l.mlTeam, team, nodeLine, (r) => r.name),
          section(l.mlNodes, nodes, nodeLine, (r) => r.name),
          section(l.mlWaypoints, waypoints, where, (r) => r.name),
          // Weak areas have no names, so they are left out while searching.
          if (!searching)
            section(l.mlWeakAreas, rows.weakAreas,
                (r) => [
                      where(r),
                      l.mlReadings(r.readings ?? 0, (r.snr ?? 0).toStringAsFixed(0)),
                      l.mlLastReading(ago(r.heard)),
                    ].join(' • '),
                (r) => l.mlWeakArea),
        ],
      ]),
    );
  }
}
