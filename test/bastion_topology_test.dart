import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/map_page.dart';
import 'package:bastion/network_diagram_page.dart';
import 'package:bastion/services/bastion_demo_radio.dart';
import 'package:bastion/services/bastion_topology.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

MeshtasticNode node(int num, {int? hops}) => MeshtasticNode(num: num, longName: 'N$num', hopsAway: hops);

MeshNeighborReport report(int from, List<(int, double)> heard) => MeshNeighborReport(
      nodeNum: from,
      receivedAt: DateTime(2026),
      neighbors: [for (final (n, snr) in heard) (nodeNum: n, snr: snr)],
    );

void main() {
  test('rings follow links from your radio, else reported hops', () {
    // 1 = you. 2 heard directly. 3 reports hearing 2 and 4. 5 only has hops.
    final t = BastionTopology.build(
      local: 1,
      nodes: [node(1), node(2, hops: 0), node(3, hops: 5), node(4), node(5, hops: 2), node(6)],
      reports: {3: report(3, [(2, 4.5), (4, -7)])},
    );
    expect(t.dots[1]!.ring, 0);
    expect(t.dots[2]!.ring, 1);
    expect(t.dots[3]!.ring, 2, reason: 'links beat the reported hop count');
    expect(t.dots[4]!.ring, 3);
    expect(t.dots[5]!.ring, 3);
    expect(t.dots.containsKey(6), isFalse, reason: 'no hops and no links');
    expect(t.links[(1, 2)], isNull, reason: 'known only from hearing it');
    expect(t.links.containsKey((1, 2)), isTrue);
    expect(t.links[(2, 3)], 4.5);
    expect(t.links[(3, 4)], -7);
    expect(t.dots[3]!.links, 2);
    expect(t.rings, 3);
  });

  test('the best SNR is kept when both ends report a link', () {
    final t = BastionTopology.build(
      local: 1,
      nodes: [node(1), node(2, hops: 0)],
      reports: {1: report(1, [(2, -3)]), 2: report(2, [(1, 6)])},
    );
    expect(t.links[(1, 2)], 6);
  });

  test('capped to the most linked nodes, and empty without data', () {
    final t = BastionTopology.build(
      local: 1,
      nodes: [node(1), for (var i = 2; i < 80; i++) node(i, hops: 1)],
      reports: const {},
      maxNodes: 10,
    );
    expect(t.dots, hasLength(11));
    expect(BastionTopology.build(local: null, nodes: const [], reports: const {}).dots, isEmpty);
  });

  test('layout: your radio centred, rings at even steps, tappable', () {
    final t = BastionTopology.build(
      local: 1,
      nodes: [node(1), node(2, hops: 0), node(3, hops: 1)],
      reports: {3: report(3, [(2, 1)])},
    );
    final layout = layoutTopology(t, const Size(300, 300));
    expect(layout.centers[1], const Offset(150, 150));
    for (final d in t.dots.values) {
      expect((layout.centers[d.num]! - layout.center).distance, closeTo(layout.gap * d.ring, .001));
    }
    expect(layout.hit(layout.centers[3]!), 3);
    expect(layout.hit(const Offset(-40, -40)), isNull);
  });

  testWidgets('the map opens the network diagram of the demo mesh', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final radio = BastionDemoRadio();
    addTearDown(radio.dispose);
    await tester.binding.setSurfaceSize(const Size(1000, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MapPage(radio: radio)),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-network-diagram')));
    await tester.pumpAndSettle();
    expect(find.text('Network diagram'), findsOneWidget);
    expect(find.byKey(const ValueKey('network-diagram')), findsOneWidget);
    expect(find.text('Heard directly'), findsOneWidget);
  });
}
