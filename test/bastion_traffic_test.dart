import 'package:bastion/generated/meshtastic/mesh.pb.dart' as pb;
import 'package:bastion/generated/meshtastic/portnums.pbenum.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/map_page.dart';
import 'package:bastion/services/bastion_demo_radio.dart';
import 'package:bastion/services/bastion_traffic.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/traffic_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const me = 0xA0000001;
const origin = 0xB00000C1;
const relay = 0xC00000D2;
const hidden = 0xD00000E3;
final heard = DateTime.utc(2026, 11, 18, 12);

MeshtasticNode node(int num, {String? long, String? short, double? lat, double? lon}) =>
    MeshtasticNode(num: num, id: '!${num.toRadixString(16)}', longName: long, shortName: short, latitude: lat, longitude: lon);

pb.MeshPacket packet({
  int from = origin,
  int to = TrafficPacket.broadcast,
  PortNum port = PortNum.TEXT_MESSAGE_APP,
  int hopStart = 3,
  int hopLimit = 3,
  int relayNode = 0,
  List<int>? payload,
  int requestId = 0,
}) =>
    pb.MeshPacket(
      from: from,
      to: to,
      id: 77,
      hopStart: hopStart,
      hopLimit: hopLimit,
      relayNode: relayNode,
      rxSnr: 6.5,
      rxRssi: -97,
      decoded: pb.Data(portnum: port, payload: payload ?? const [], requestId: requestId),
    );

void main() {
  group('packet types map onto the six colours', () {
    test('position and node info are adverts, routing is an ack, traceroute is a trace', () {
      expect(TrafficPacket.kindOf(PortNum.POSITION_APP, to: me), TrafficKind.advert);
      expect(TrafficPacket.kindOf(PortNum.NODEINFO_APP, to: TrafficPacket.broadcast), TrafficKind.advert);
      expect(TrafficPacket.kindOf(PortNum.ROUTING_APP, to: me), TrafficKind.ack);
      expect(TrafficPacket.kindOf(PortNum.TRACEROUTE_APP, to: me), TrafficKind.trace);
      expect(TrafficPacket.kindOf(PortNum.TELEMETRY_APP, to: TrafficPacket.broadcast), TrafficKind.other);
    });

    test('text to everyone is a channel message, text to us is a direct message', () {
      expect(TrafficPacket.kindOf(PortNum.TEXT_MESSAGE_APP, to: TrafficPacket.broadcast), TrafficKind.channel);
      expect(TrafficPacket.kindOf(PortNum.TEXT_MESSAGE_APP, to: me), TrafficKind.direct);
    });

    test('every type has its own colour and a name', () {
      expect(TrafficKind.values.map(TrafficStyle.color).toSet(), hasLength(6));
    });
  });

  group('inferred paths from hop count and relay byte', () {
    test('zero hops goes straight from the sender to us', () {
      final p = TrafficPacket.fromMeshPacket(packet(), local: me, heard: heard)!;
      expect(p.hopsAway, 0);
      expect(p.path, const [TrafficNodeStop(origin), TrafficNodeStop(me)]);
      expect(p.kind, TrafficKind.channel);
      expect(p.snr, 6.5);
      expect(p.rssi, -97);
    });

    test('three hops with a relay byte: two unnamed relays, then the relay', () {
      final p = TrafficPacket.fromMeshPacket(packet(hopStart: 5, hopLimit: 2, relayNode: 0xD2), local: me, heard: heard)!;
      expect(p.hopsAway, 3);
      expect(p.path, const [TrafficNodeStop(origin), TrafficUnknownStop(2), TrafficRelayStop(0xD2), TrafficNodeStop(me)]);
    });

    test('hops without a relay byte are all unnamed', () {
      expect(TrafficPacket.inferredPath(from: origin, local: me, hopsAway: 2),
          const [TrafficNodeStop(origin), TrafficUnknownStop(2), TrafficNodeStop(me)]);
    });

    test('old firmware without hop_start gives a straight line', () {
      final p = TrafficPacket.fromMeshPacket(packet(hopStart: 0, hopLimit: 3), local: me, heard: heard)!;
      expect(p.hopsAway, isNull);
      expect(p.path, const [TrafficNodeStop(origin), TrafficNodeStop(me)]);
    });

    test('our own packets and undecoded ones are not drawn', () {
      expect(TrafficPacket.fromMeshPacket(packet(from: me), local: me, heard: heard), isNull);
      expect(TrafficPacket.fromMeshPacket(pb.MeshPacket(from: origin, to: me), local: me, heard: heard), isNull);
    });
  });

  group('traceroutes carry the full path', () {
    test('a reply uses route_back', () {
      final route = pb.RouteDiscovery(route: [hidden], routeBack: [relay, hidden]);
      final p = TrafficPacket.fromMeshPacket(
          packet(to: me, port: PortNum.TRACEROUTE_APP, payload: route.writeToBuffer(), requestId: 9),
          local: me, heard: heard)!;
      expect(p.kind, TrafficKind.trace);
      expect(p.fullPath, isTrue);
      expect(p.path, const [TrafficNodeStop(origin), TrafficNodeStop(relay), TrafficNodeStop(hidden), TrafficNodeStop(me)]);
    });

    test('a reply from older firmware reverses the way out', () {
      final route = pb.RouteDiscovery(route: [hidden, relay]);
      expect(TrafficPacket.tracePath(from: origin, local: me, route: route, isReply: true),
          const [TrafficNodeStop(origin), TrafficNodeStop(relay), TrafficNodeStop(hidden), TrafficNodeStop(me)]);
    });

    test('a request to us lists its relays so far; unknown relays are grouped', () {
      final route = pb.RouteDiscovery(route: [relay, TrafficPacket.unknownRelay, TrafficPacket.unknownRelay]);
      expect(TrafficPacket.tracePath(from: origin, local: me, route: route, isReply: false),
          const [TrafficNodeStop(origin), TrafficNodeStop(relay), TrafficUnknownStop(2), TrafficNodeStop(me)]);
    });
  });

  group('routes resolve against the node list', () {
    final nodes = {
      me: node(me, long: 'Base', lat: 40, lon: -105),
      origin: node(origin, long: 'Ridge', short: 'RDG', lat: 40.1, lon: -105.1),
      relay: node(relay, short: 'RLY', lat: 40.05, lon: -105.05),
      hidden: node(hidden, long: 'Cabin'),
    };

    test('path to map points skips nodes without a position', () {
      const p = [TrafficNodeStop(origin), TrafficNodeStop(hidden), TrafficNodeStop(relay), TrafficNodeStop(me)];
      final route = TrafficRoute.build(
          TrafficPacket(id: 1, from: origin, to: me, kind: TrafficKind.trace, path: p, heard: heard, fullPath: true), nodes);
      expect(route.summary, 'Ridge → Cabin → RLY → Base');
      expect([for (final s in route.placed) s.label], ['Ridge', 'RLY', 'Base']);
      expect(route.legs, 2);
      expect([for (final s in route.notOnMap) s.label], ['Cabin']);
      expect(route.lastHop!.label, 'RLY');
      expect((route.placed.first.latitude, route.placed.first.longitude), (40.1, -105.1));
    });

    test('a relay byte names the relay when exactly one node ends in it', () {
      final route = TrafficRoute.build(
          TrafficPacket(id: 1, from: origin, to: me, kind: TrafficKind.channel, heard: heard, hopsAway: 3,
              path: TrafficPacket.inferredPath(from: origin, local: me, hopsAway: 3, relayByte: 0xD2)),
          nodes);
      expect(route.summary, 'Ridge → +2 → RLY → Base');
      expect(route.unknownRelays, 2);
      expect(route.notOnMap, isEmpty);
      expect(route.legs, 2);
    });

    test('an ambiguous or unknown relay byte stays a byte and is not drawn', () {
      final twins = {...nodes, 0xE00000D2: node(0xE00000D2, short: 'TWN', lat: 41, lon: -104)};
      final route = TrafficRoute.build(
          TrafficPacket(id: 1, from: origin, to: me, kind: TrafficKind.ack, heard: heard, hopsAway: 1,
              path: TrafficPacket.inferredPath(from: origin, local: me, hopsAway: 1, relayByte: 0xD2)),
          twins);
      expect(route.summary, 'Ridge → ··D2 → Base');
      expect(route.placed, hasLength(2));
    });

    test('unknown nodes show a short hex ID', () {
      final route = TrafficRoute.build(
          TrafficPacket(id: 1, from: 0x1234ABCD, to: me, kind: TrafficKind.other, heard: heard,
              path: const [TrafficNodeStop(0x1234ABCD), TrafficNodeStop(me)]),
          nodes);
      expect(route.stops.first.label, 'ABCD');
      expect(route.legs, 0, reason: 'only our end has a position');
    });
  });

  group('toolbar fits the space it has', () {
    const one = TextScaler.noScaling;
    test('labels when there is room', () {
      expect(TrafficToolbar.layoutFor(6, 500, one), TrafficToolbarLayout.labelled);
    });
    test('icons only when labels would not fit', () {
      expect(TrafficToolbar.layoutFor(6, 320, one), TrafficToolbarLayout.icons);
    });
    test('two columns in a very short space', () {
      expect(TrafficToolbar.layoutFor(6, 200, one), TrafficToolbarLayout.twoColumns);
    });
    test('large text drops the labels sooner', () {
      expect(TrafficToolbar.layoutFor(6, 400, one), TrafficToolbarLayout.labelled);
      expect(TrafficToolbar.layoutFor(6, 400, const TextScaler.linear(2)), TrafficToolbarLayout.icons);
    });
  });

  testWidgets('every toolbar button stays on screen on a short phone with the card open', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final radio = BastionDemoRadio(replyDelay: Duration.zero);
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MapPage(radio: radio)),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-traffic')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TrafficRouteCard), findsOneWidget);
    final card = tester.getRect(find.byType(TrafficRouteCard));
    for (final key in ['map-locate', 'map-traffic-filter', 'map-traffic', 'map-find-place', 'map-fit-all', 'map-traffic-options']) {
      final r = tester.getRect(find.byKey(ValueKey(key)));
      expect(r.bottom, lessThanOrEqualTo(card.top), reason: '$key is above the route card');
      expect(r.top, greaterThanOrEqualTo(0), reason: '$key is on screen');
    }
    await tester.tap(find.byKey(const ValueKey('map-traffic')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
  });

    group('animation timing', () {
    test('the dot crosses each leg in turn, then the route fades', () {
      expect(TrafficTiming.frame(Duration.zero, 2).leg, 0);
      final mid = TrafficTiming.frame(TrafficTiming.leg + TrafficTiming.leg ~/ 2, 2);
      expect(mid.leg, 1);
      expect(mid.t, closeTo(0.5, 0.01));
      expect(mid.opacity, 1);
      final fading = TrafficTiming.frame(TrafficTiming.leg * 2 + TrafficTiming.fade ~/ 2, 2);
      expect(fading.leg, 2);
      expect(fading.opacity, closeTo(0.5, 0.01));
      expect(TrafficTiming.frame(TrafficTiming.total(2), 2).done, isTrue);
    });

    test('reduce motion draws the whole route at once and only fades', () {
      final f = TrafficTiming.frame(Duration.zero, 4, reduceMotion: true);
      expect(f.leg, 4);
      expect(f.opacity, 1);
      expect(TrafficTiming.frame(TrafficTiming.still, 4, reduceMotion: true).done, isTrue);
    });

    test('at most three routes animate; the rest wait their turn', () {
      final q = TrafficQueue(maxWaiting: 2);
      final r = TrafficRoute.build(
          TrafficPacket(id: 1, from: origin, to: me, kind: TrafficKind.advert, heard: heard,
              path: const [TrafficNodeStop(origin), TrafficNodeStop(me)]),
          const {});
      for (var i = 0; i < 6; i++) {
        q.add(r, heard);
      }
      expect(q.active, hasLength(3));
      expect(q.waiting, hasLength(2), reason: 'oldest waiting routes are dropped');
      expect(q.tick(heard.add(TrafficTiming.total(r.legs))), isTrue);
      expect(q.active, hasLength(2));
      expect(q.waiting, isEmpty);
      expect(q.tick(heard.add(TrafficTiming.total(r.legs) * 3)), isFalse);
    });
  });

  test('the log keeps the latest packets and streams new ones', () async {
    final log = BastionTrafficLog();
    final seen = <TrafficPacket>[];
    final sub = log.packets.listen(seen.add);
    for (var i = 0; i < BastionTrafficLog.keep + 5; i++) {
      log.add(BastionDemoRadio.demoTrafficPacket(i, heard));
    }
    await Future<void>.delayed(Duration.zero);
    expect(seen, hasLength(BastionTrafficLog.keep + 5));
    expect(log.recent, hasLength(BastionTrafficLog.keep));
    await sub.cancel();
    await log.close();
  });

  test('the demo pattern covers all six colours', () {
    expect({for (var i = 0; i < 6; i++) BastionDemoRadio.demoTrafficPacket(i, heard).kind}, TrafficKind.values.toSet());
  });

  testWidgets('Traffic mode animates demo packets and fills the route card', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await tester.binding.setSurfaceSize(const Size(430, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final radio = BastionDemoRadio(replyDelay: Duration.zero);
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MapPage(radio: radio)),
    ));
    await tester.pump();
    expect(find.byType(TrafficRouteCard), findsNothing);
    expect(find.byKey(const ValueKey('map-locate')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('map-traffic')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(TrafficRouteCard), findsOneWidget);
    expect(find.text('Sam → +1 → Ridge Relay → Demo Base'), findsOneWidget);
    expect(find.text('Channel message'), findsWidgets, reason: 'pill and legend');
    expect(find.textContaining('2 hops · -106 dBm · SNR 2.5'), findsOneWidget);
    // The SNR is only in the stats line, not repeated next to the name.
    expect(find.text('Heard from Ridge Relay'), findsOneWidget);
    expect(find.byType(PolylineLayer), findsWidgets);

    // Hide channel messages: the next channel packet is skipped.
    await tester.tap(find.byKey(const ValueKey('map-traffic-filter')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.byKey(const ValueKey('traffic-kind-direct')));
    await tester.tap(find.byKey(const ValueKey('traffic-kind-direct')));
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(find.byKey(const ValueKey('traffic-kind-direct'))).value, isFalse);
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 3));
    final shown = tester.widget<Text>(find.byKey(const ValueKey('traffic-route'))).data;
    expect(shown, 'Sam → +1 → Ridge Relay → Demo Base', reason: 'direct message was filtered out');

    await tester.tap(find.byKey(const ValueKey('map-traffic')));
    await tester.pump();
    expect(find.byType(TrafficRouteCard), findsNothing);
    await tester.pump(const Duration(seconds: 5));
  });
}
