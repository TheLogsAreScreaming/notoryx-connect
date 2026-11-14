import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/map_list_page.dart';
import 'package:bastion/services/bastion_coverage_grid.dart';
import 'package:bastion/services/bastion_map_list.dart';
import 'package:bastion/services/bastion_waypoints.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 11, 14, 12);
const me = (35.0, -80.0);

final nodes = [
  MeshtasticNode(num: 1, longName: 'Self', latitude: 35.0, longitude: -80.0),
  MeshtasticNode(num: 2, longName: 'Far ridge', latitude: 35.1, longitude: -80.0,
      lastHeard: now.subtract(const Duration(minutes: 5)), positionTime: now.subtract(const Duration(hours: 2))),
  MeshtasticNode(num: 3, longName: 'Camp', latitude: 35.01, longitude: -79.99, lastHeard: now),
  const MeshtasticNode(num: 4, longName: 'No position'),
];
final waypoints = [const MeshWaypoint(id: 1, latitude: 34.99, longitude: -80.0, name: 'Trailhead')];
final cells = [
  const CoverageCell(south: 35.02, west: -80.002, readings: 4, meanSnr: -14),
  const CoverageCell(south: 35.05, west: -80.0, readings: 9, meanSnr: 3),
];

void main() {
  test('nodes nearest first, without this radio or positionless nodes', () {
    final rows = buildMapList(me: me, selfNum: 1, nodes: nodes, waypoints: waypoints, cells: cells);
    expect(rows.nodes.map((r) => r.name), ['Camp', 'Far ridge']);
    expect(compassOf(rows.nodes.first.bearing!), CompassPoint.ne);
    expect(compassOf(rows.nodes.last.bearing!), CompassPoint.n);
    expect(rows.nodes.last.meters, closeTo(11120, 50));
    expect(compassOf(rows.waypoints.single.bearing!), CompassPoint.s);
  });

  test('only weak squares are listed as weak areas', () {
    final rows = buildMapList(me: me, nodes: const [], waypoints: const [], cells: cells);
    expect(rows.weakAreas, hasLength(1));
    expect(rows.weakAreas.single.readings, 4);
    expect(rows.weakAreas.single.snr, -14);
  });

  test('without this radio\'s position, rows still list, by name', () {
    final rows = buildMapList(nodes: nodes, waypoints: waypoints, cells: cells, selfNum: 1);
    expect(rows.nodes.map((r) => r.name), ['Camp', 'Far ridge']);
    expect(rows.nodes.first.meters, isNull);
  });

  testWidgets('reads as words: distance, direction, freshness', (tester) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MapListPage(me: me, selfNum: 1, nodes: nodes, waypoints: waypoints, cells: cells, now: now),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('north-east'), findsOneWidget);
    expect(find.textContaining('heard 5 min ago'), findsOneWidget);
    expect(find.textContaining('4 readings, average SNR -14 dB'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Nodes \\(2\\)')), findsOneWidget);
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('says when the distance is unknown', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MapListPage(me: null, selfNum: 1, nodes: nodes, waypoints: const [], cells: const [], now: now),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('your radio has no position'), findsWidgets);
  });
}
