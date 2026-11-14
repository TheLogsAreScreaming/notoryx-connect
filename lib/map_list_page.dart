import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_coverage_grid.dart';
import 'services/bastion_map_list.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_units.dart';
import 'services/bastion_waypoints.dart';
import 'services/meshtastic_node_database.dart';

/// The map in words: every node, waypoint and weak-coverage square with how
/// far, which way and how fresh, nearest first. For screen readers, large
/// text and anyone who'd rather read than pan a map.
class MapListPage extends StatelessWidget {
  const MapListPage({
    super.key,
    required this.me,
    required this.selfNum,
    required this.nodes,
    required this.waypoints,
    required this.cells,
    this.now,
  });

  final (double, double)? me;
  final int? selfNum;
  final List<MeshtasticNode> nodes;
  final List<MeshWaypoint> waypoints;
  final List<CoverageCell> cells;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final rows = buildMapList(me: me, selfNum: selfNum, nodes: nodes, waypoints: waypoints, cells: cells);
    final units = BastionPreferences.instance.units;
    final clock = now ?? DateTime.now();

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
              ),
        ]);

    return Scaffold(
      appBar: AppBar(title: Text(l.mlTitle)),
      body: ListView(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Text(l.mlIntro)),
        section(l.mlNodes, rows.nodes,
            (r) => [where(r), l.mlHeard(ago(r.heard)), l.mlPositionAge(ago(r.positionAt))].join(' • '),
            (r) => r.name),
        section(l.mlWaypoints, rows.waypoints, where, (r) => r.name),
        section(l.mlWeakAreas, rows.weakAreas,
            (r) => [where(r), l.mlReadings(r.readings ?? 0, (r.snr ?? 0).toStringAsFixed(0))].join(' • '),
            (r) => l.mlWeakArea),
      ]),
    );
  }
}
