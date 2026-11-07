import 'package:bastion/services/bastion_route_map.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_traceroute.dart';
import 'package:bastion/traceroute_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const local = 1, relay = 2, hidden = 3, dest = 4;
  bool placed(int n) => n != hidden;

  test('the route runs from this radio to the destination and back', () {
    final path = RouteMapPath.of(
      const TracerouteResult(
        towards: [TracerouteHop(relay, 5), TracerouteHop(dest, 3)],
        back: [TracerouteHop(relay, 4)],
      ),
      local: local, destination: dest, hasPosition: placed,
    );
    expect(path.towards, [local, relay, dest]);
    expect(path.back, [dest, relay, local]);
    expect(path.unplaced, isEmpty);
    expect(path.drawable, isTrue);
  });

  test('relays without a position are skipped and reported', () {
    final path = RouteMapPath.of(
      const TracerouteResult(towards: [TracerouteHop(hidden, null), TracerouteHop(dest, 1)], back: []),
      local: local, destination: dest, hasPosition: placed,
    );
    expect(path.towards, [local, dest]);
    expect(path.back, isEmpty);
    expect(path.unplaced, {hidden});
  });

  test('a route with one placed node cannot be drawn', () {
    final path = RouteMapPath.of(
      const TracerouteResult(towards: [TracerouteHop(dest, 1)], back: []),
      local: local, destination: dest, hasPosition: (n) => n == local,
    );
    expect(path.drawable, isFalse);
  });

  testWidgets('the route map numbers each node and explains gaps', (tester) async {
    final path = RouteMapPath.of(
      const TracerouteResult(
        towards: [TracerouteHop(hidden, null), TracerouteHop(relay, 2), TracerouteHop(dest, 1)],
        back: [TracerouteHop(relay, 2)],
      ),
      local: local, destination: dest, hasPosition: placed,
    );
    const nodes = [
      MeshtasticNode(num: local, longName: 'Base', latitude: 40.0, longitude: -105.0),
      MeshtasticNode(num: relay, longName: 'Ridge', latitude: 40.02, longitude: -105.01),
      MeshtasticNode(num: hidden, longName: 'Hidden'),
      MeshtasticNode(num: dest, longName: 'Camp', latitude: 40.04, longitude: -105.03),
    ];
    String name(int n) => nodes.firstWhere((x) => x.num == n).displayName;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
        child: TracerouteMap(path: path, nodes: nodes, name: name)))));
    await tester.pump();
    expect(find.text('1. Base'), findsOneWidget);
    expect(find.text('2. Ridge'), findsOneWidget);
    expect(find.text('3. Camp'), findsOneWidget);
    expect(find.textContaining('No position for Hidden'), findsOneWidget);
    expect(find.textContaining('Route back'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
