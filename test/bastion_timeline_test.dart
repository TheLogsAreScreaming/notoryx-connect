import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/bastion_timeline.dart';
import 'package:bastion/services/bastion_waypoints.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/timeline_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeSource extends ChangeNotifier implements TimelineSource {
  @override
  int? localNodeNum;
  @override
  bool isReady = false;
  @override
  List<MeshtasticNode> nodes = [];
  @override
  List<MeshWaypoint> waypoints = [];
  @override
  List<BastionChatMessage> messages = [];

  @override
  String nodeName(int num) => 'Node $num';

  void update() => notifyListeners();
}

final t0 = DateTime(2026, 11, 13, 9);

MeshtasticNode node(int num, {int minute = 0, double? snr, int hops = 0}) => MeshtasticNode(
    num: num, longName: 'N$num', lastHeard: t0.add(Duration(minutes: minute)), snr: snr, hopsAway: hops);

Future<(BastionTimeline, FakeSource)> connected(SharedPreferencesAsync prefs, List<MeshtasticNode> nodes) async {
  final timeline = BastionTimeline(preferences: prefs, clock: () => t0);
  final source = FakeSource()
    ..localNodeNum = 1
    ..nodes = nodes;
  timeline.attach(source);
  await timeline.settled();
  source
    ..isReady = true
    ..update();
  return (timeline, source);
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('nodes already known when the link is ready are the starting point, later ones are news', () async {
    final prefs = SharedPreferencesAsync();
    final (timeline, source) = await connected(prefs, [node(2), node(3)]);
    expect(timeline.events, isEmpty);

    source
      ..nodes = [node(2), node(3), node(4, minute: 5)]
      ..update();
    final joined = timeline.events.single;
    expect(joined.kind, TimelineKind.nodeJoined);
    expect(joined.subject, 'N4');
    expect(joined.nodeNum, 4);
    expect(joined.at, t0.add(const Duration(minutes: 5)));
    await timeline.flush();
    timeline.dispose();

    // Next session: node 5 turned up while the app was closed.
    final (again, _) = await connected(prefs, [node(2), node(3), node(4), node(5, minute: 9)]);
    expect(again.events.map((e) => e.subject), ['N5', 'N4']);
    again.dispose();
  });

  test('a direct link moving 6 dB is a signal change; jitter and relayed nodes are not', () async {
    final (timeline, source) = await connected(SharedPreferencesAsync(), [node(2, snr: 8), node(3, snr: 8, hops: 2)]);
    source
      ..nodes = [node(2, minute: 1, snr: 6), node(3, minute: 1, snr: -10, hops: 2)]
      ..update();
    expect(timeline.events, isEmpty);
    source
      ..nodes = [node(2, minute: 2, snr: -1.5), node(3, minute: 2, snr: 9, hops: 2)]
      ..update();
    final change = timeline.events.single;
    expect(change.kind, TimelineKind.signalChange);
    expect(change.subject, 'N2');
    expect(change.toSnr, -1.5);
    expect(change.fromSnr, closeTo(7.6, 0.01));
    // The same packet seen again (no new lastHeard) adds nothing.
    source.update();
    expect(timeline.events, hasLength(1));
    timeline.dispose();
  });

  test('new waypoints get a line, ones already there do not', () async {
    final (timeline, source) = await connected(SharedPreferencesAsync(), []);
    source
      ..waypoints = [const MeshWaypoint(id: 1, latitude: 1, longitude: 1, name: 'Old')]
      ..update();
    expect(timeline.events.single.subject, 'Old', reason: 'new since the link was ready');
    source
      ..waypoints = [
        const MeshWaypoint(id: 1, latitude: 1, longitude: 1, name: 'Old'),
        const MeshWaypoint(id: 2, latitude: 1, longitude: 1, name: 'Camp', description: 'Water here', from: 7),
      ]
      ..update();
    final w = timeline.events.first;
    expect((w.kind, w.subject, w.detail, w.nodeNum), (TimelineKind.waypoint, 'Camp', 'Water here', 7));
    timeline.dispose();
  });

  test('messages come from chat history, without reactions', () async {
    final (timeline, source) = await connected(SharedPreferencesAsync(), []);
    source.messages = [
      BastionChatMessage(packetId: 1, from: 9, to: 1, channel: 0, text: 'On the ridge', timestamp: t0,
          direction: BastionMessageDirection.incoming, deliveryState: BastionDeliveryState.received),
      BastionChatMessage(packetId: 2, from: 1, to: 9, channel: 0, text: '👍', timestamp: t0,
          direction: BastionMessageDirection.outgoing, deliveryState: BastionDeliveryState.sent, isReaction: true),
      BastionChatMessage(packetId: 3, from: 1, to: 9, channel: 0, text: 'Copy', timestamp: t0,
          direction: BastionMessageDirection.outgoing, deliveryState: BastionDeliveryState.sent),
    ];
    final messages = timeline.messageEvents();
    expect(messages.map((m) => (m.subject, m.detail, m.outgoing)),
        [('Node 9', 'On the ridge', false), ('Node 1', 'Copy', true)]);
    timeline.dispose();
  });

  test('each radio has its own timeline', () async {
    final (timeline, source) = await connected(SharedPreferencesAsync(), [node(2)]);
    source
      ..nodes = [node(2), node(3)]
      ..update();
    expect(timeline.events, hasLength(1));
    source
      ..localNodeNum = 50
      ..update();
    await timeline.settled();
    expect(timeline.radio, 50);
    expect(timeline.events, isEmpty);
    timeline.dispose();
  });

  test('filter keeps chosen kinds and every search word, newest first', () {
    final events = [
      TimelineEvent(kind: TimelineKind.message, at: t0, subject: 'Ana', detail: 'water at camp'),
      TimelineEvent(kind: TimelineKind.waypoint, at: t0.add(const Duration(hours: 1)), subject: 'Camp'),
      TimelineEvent(kind: TimelineKind.nodeJoined, at: t0.add(const Duration(hours: 2)), subject: 'Ridge'),
    ];
    expect(filterTimeline(events, kinds: {...TimelineKind.values}).map((e) => e.subject), ['Ridge', 'Camp', 'Ana']);
    expect(filterTimeline(events, kinds: {...TimelineKind.values}, query: 'CAMP').map((e) => e.subject),
        ['Camp', 'Ana']);
    expect(filterTimeline(events, kinds: {TimelineKind.message}, query: 'camp water').single.subject, 'Ana');
    expect(filterTimeline(events, kinds: {}), isEmpty);
  });

  test('events survive a round trip through JSON', () {
    final e = TimelineEvent(kind: TimelineKind.signalChange, at: t0, subject: 'N2', nodeNum: 2, fromSnr: 8,
        toSnr: -1.5);
    final back = TimelineEvent.fromJson(e.toJson())!;
    expect((back.kind, back.at, back.subject, back.nodeNum, back.fromSnr, back.toSnr),
        (e.kind, e.at, e.subject, e.nodeNum, e.fromSnr, e.toSnr));
    expect(TimelineEvent.fromJson({'k': 'nope', 'at': 1, 's': 'x'}), isNull);
  });

  testWidgets('the page is translated and the kind filters work', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    late BastionTimeline timeline;
    late FakeSource source;
    await tester.runAsync(() async {
      (timeline, source) = await connected(SharedPreferencesAsync(), [node(2)]);
      source
        ..nodes = [node(2), node(3)]
        ..waypoints = []
        ..update();
      source
        ..waypoints = [const MeshWaypoint(id: 4, latitude: 1, longitude: 1, name: 'Camp')]
        ..update();
    });
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TimelinePage(radio: radio, timeline: timeline),
    ));
    await tester.pump();
    expect(find.text('Neuer Knoten: N3'), findsOneWidget);
    expect(find.text('Wegpunkt: Camp'), findsOneWidget);
    expect(find.text('2 Einträge'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('timeline-filter-waypoint')));
    await tester.pump();
    expect(find.text('Wegpunkt: Camp'), findsNothing);
    expect(find.text('1 Eintrag'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('timeline-search')), 'zzz');
    await tester.pump();
    expect(find.text('Nichts passt zu diesen Filtern.'), findsOneWidget);
    expect(find.byTooltip('Suche löschen'), findsOneWidget);
    timeline.detach();
  });
}
