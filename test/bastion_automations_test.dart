import 'package:bastion/automations_page.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/bastion_automations.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/bastion_geofences.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeSource extends ChangeNotifier implements AutomationSource {
  @override
  int? localNodeNum = 1;
  @override
  bool isReady = false;
  @override
  List<MeshtasticNode> nodes = [];
  @override
  List<BastionChatMessage> messages = [];
  @override
  List<BastionGeofence> geofences = [];
  final Map<int, int> battery = {};

  @override
  int? batteryOf(int node) => battery[node];
  @override
  String nodeName(int node) => 'N$node';

  void update() => notifyListeners();
}

class Calls {
  final sent = <(int, int, String)>[];
  final alerts = <(int, String, String)>[];
  final posts = <(Uri, String)>[];
  final joined = <String>[];
  var sounds = 0;
  bool ready = true;
  int status = 200;

  AutomationHooks get hooks => AutomationHooks(
        send: (to, ch, text) async {
          if (!ready) return false;
          sent.add((to, ch, text));
          return true;
        },
        alert: (id, title, body) async => alerts.add((id, title, body)),
        playSound: () async => sounds++,
        joinChannel: (link) async {
          joined.add(link);
          return ready;
        },
        post: (url, json) async {
          posts.add((url, json));
          return status;
        },
      );
}

var now = DateTime(2026, 11, 13, 12);

BastionChatMessage incoming(int id, String text, {int from = 9, int to = automationBroadcast, int channel = 0}) =>
    BastionChatMessage(packetId: id, from: from, to: to, channel: channel, text: text, timestamp: now,
        direction: BastionMessageDirection.incoming, deliveryState: BastionDeliveryState.received);

Future<(AutomationEngine, FakeSource, Calls)> ready(List<Automation> rules, {bool webhooks = false}) async {
  final calls = Calls();
  final engine = AutomationEngine(hooks: calls.hooks, clock: () => now);
  await engine.save(AutomationSettings(rules: rules, webhooks: webhooks));
  final source = FakeSource();
  engine.attach(source);
  source
    ..isReady = true
    ..update();
  return (engine, source, calls);
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    now = DateTime(2026, 11, 13, 12);
  });

  test('rules and the web switch survive saving; web requests start off', () async {
    expect(const AutomationSettings().webhooks, isFalse);
    final rule = Automation(
      id: 3,
      name: 'Camp',
      matchAll: true,
      cooldown: const Duration(minutes: 15),
      triggers: const [
        BatteryTrigger(node: 5, below: 20),
        TimeTrigger(hour: 7, minute: 30, weekdays: {1, 5}),
        GeofenceTrigger(zone: 'z1', enter: false, node: 6),
        MessageTrigger(contains: 'help', channel: 2),
        PresenceTrigger(node: 7, online: true, after: Duration(minutes: 60)),
      ],
      actions: const [
        SendAction(destination: automationBroadcast, channel: 1, text: '{node} low'),
        AlertAction('Check {zone}'),
        SoundAction(),
        WebhookAction('https://example.org/hook'),
      ],
    );
    final engine = AutomationEngine(hooks: Calls().hooks, preferences: SharedPreferencesAsync());
    await engine.save(AutomationSettings(rules: [rule], webhooks: true));
    final again = AutomationEngine(hooks: Calls().hooks, preferences: SharedPreferencesAsync());
    await again.load();
    expect(again.settings.webhooks, isTrue);
    expect(again.settings.rules.single.toJson(), rule.toJson());
    expect(again.settings.nextId, 4);
    expect(again.settings.rules.single.needsInternet, isTrue);
    expect(AutomationSettings.decode('not json').rules, isEmpty);
  });

  test('a matching message runs the actions with the details filled in', () async {
    final (engine, source, calls) = await ready([
      const Automation(id: 1, name: 'Help', triggers: [MessageTrigger(contains: 'HELP')], actions: [
        SendAction(destination: 9, channel: 0, text: 'Got it {node}: {text}'),
        AlertAction('{rule} from {node}'),
        SoundAction(),
      ]),
    ]);
    source
      ..messages = [incoming(1, 'need help at the ridge')]
      ..update();
    await settle();
    expect(calls.sent.single, (9, 0, '[auto] Got it N9: need help at the ridge'));
    expect(calls.alerts.single, (1, 'Help', 'Help from N9'));
    expect(calls.sounds, 1);
    expect(engine.log, hasLength(3));
    expect(engine.log.every((r) => r.ok), isTrue);
    engine.dispose();
  });

  test('messages already there, sent by automations, check-ins, old or outgoing never trigger', () async {
    now = DateTime(2026, 11, 13, 12);
    final calls = Calls();
    final engine = AutomationEngine(hooks: calls.hooks, clock: () => now);
    await engine.save(const AutomationSettings(rules: [
      Automation(id: 1, name: 'Any', cooldown: Duration(minutes: 1), triggers: [MessageTrigger()],
          actions: [AlertAction('x')]),
    ]));
    final source = FakeSource()..messages = [incoming(1, 'backlog')];
    engine.attach(source);
    source
      ..isReady = true
      ..update();
    source
      ..messages = [
        incoming(1, 'backlog'),
        incoming(2, '[auto] Got it'),
        incoming(3, '[NOTORYX Check-in] ok'),
        BastionChatMessage(packetId: 4, from: 1, to: 9, channel: 0, text: 'mine', timestamp: now,
            direction: BastionMessageDirection.outgoing, deliveryState: BastionDeliveryState.sent),
        BastionChatMessage(packetId: 5, from: 9, to: automationBroadcast, channel: 0, text: 'stale',
            timestamp: now.subtract(const Duration(hours: 1)), direction: BastionMessageDirection.incoming,
            deliveryState: BastionDeliveryState.received),
      ]
      ..update();
    await settle();
    expect(calls.alerts, isEmpty);
    engine.dispose();
  });

  test('channel and direct-only message filters', () {
    expect(const MessageTrigger(channel: 2).matches(incoming(1, 'x', channel: 2)), isTrue);
    expect(const MessageTrigger(channel: 2).matches(incoming(1, 'x', channel: 0)), isFalse);
    expect(const MessageTrigger(channel: 0).matches(incoming(1, 'x', to: 1)), isFalse);
    expect(const MessageTrigger(directOnly: true).matches(incoming(1, 'x', to: 1)), isTrue);
    expect(const MessageTrigger(directOnly: true).matches(incoming(1, 'x')), isFalse);
  });

  test('battery fires once when it crosses the line, not on the first reading', () async {
    final (engine, source, calls) = await ready([
      const Automation(id: 1, name: 'Low', cooldown: Duration(minutes: 1),
          triggers: [BatteryTrigger(node: 5, below: 20)], actions: [AlertAction('{node} at {battery}%')]),
    ]);
    source
      ..battery[5] = 10
      ..update();
    await settle();
    expect(calls.alerts, isEmpty, reason: 'the first reading is a starting point');
    source
      ..battery[5] = 50
      ..update();
    await settle();
    source
      ..battery[5] = 18
      ..update();
    await settle();
    expect(calls.alerts.single.$3, 'N5 at 18%');
    source.update();
    await settle();
    expect(calls.alerts, hasLength(1));
    engine.dispose();
  });

  test('geofence enter and leave, with slack at the edge', () async {
    final (engine, source, calls) = await ready([
      const Automation(id: 1, name: 'In', cooldown: Duration(minutes: 1),
          triggers: [GeofenceTrigger(zone: 'camp', enter: true)], actions: [AlertAction('{node} in {zone}')]),
      const Automation(id: 2, name: 'Out', cooldown: Duration(minutes: 1),
          triggers: [GeofenceTrigger(zone: 'camp', enter: false, node: 5)], actions: [AlertAction('{node} left')]),
    ]);
    source.geofences = [const BastionGeofence(id: 'camp', name: 'Camp', latitude: 45, longitude: -122,
        radiusMeters: 1000, watch: GeofenceWatch.allNodes, alertOn: GeofenceAlertOn.both)];
    void at(double lat) {
      source
        ..nodes = [MeshtasticNode(num: 5, longName: 'Ana', latitude: lat, longitude: -122)]
        ..update();
    }

    at(45.05); // ~5.5 km out: starting point
    await settle();
    at(45.005); // ~550 m: in
    await settle();
    expect(calls.alerts.map((a) => a.$3), ['Ana in Camp']);
    now = now.add(const Duration(minutes: 2));
    at(45.0095); // ~1.06 km: inside the 10% slack, still in
    await settle();
    expect(calls.alerts, hasLength(1));
    at(45.02); // ~2.2 km: out
    await settle();
    expect(calls.alerts.map((a) => a.$3), ['Ana in Camp', 'Ana left']);
    engine.dispose();
  });

  test('presence: going quiet is noticed by the clock, coming back by an update', () async {
    final (engine, source, calls) = await ready([
      const Automation(id: 1, name: 'Quiet', cooldown: Duration(minutes: 1),
          triggers: [PresenceTrigger(node: 5, online: false, after: Duration(minutes: 30))],
          actions: [AlertAction('{node} quiet')]),
      const Automation(id: 2, name: 'Back', cooldown: Duration(minutes: 1),
          triggers: [PresenceTrigger(node: 5, online: true, after: Duration(minutes: 30))],
          actions: [AlertAction('{node} back')]),
    ]);
    final heard = now;
    source
      ..nodes = [MeshtasticNode(num: 5, lastHeard: heard)]
      ..update();
    await engine.onTick();
    now = now.add(const Duration(minutes: 31));
    await engine.onTick();
    expect(calls.alerts.map((a) => a.$3), ['N5 quiet']);
    source
      ..nodes = [MeshtasticNode(num: 5, lastHeard: now)]
      ..update();
    await settle();
    expect(calls.alerts.map((a) => a.$3), ['N5 quiet', 'N5 back']);
    engine.dispose();
  });

  test('time of day fires once on chosen days', () async {
    now = DateTime(2026, 11, 13, 7, 29); // a Friday
    final (engine, _, calls) = await ready([
      const Automation(id: 1, name: 'Morning', cooldown: Duration(minutes: 1),
          triggers: [TimeTrigger(hour: 7, minute: 30, weekdays: {5})], actions: [SoundAction()]),
      const Automation(id: 2, name: 'Monday', cooldown: Duration(minutes: 1),
          triggers: [TimeTrigger(hour: 7, minute: 30, weekdays: {1})], actions: [AlertAction('x')]),
    ]);
    await engine.onTick();
    now = DateTime(2026, 11, 13, 7, 30, 5);
    await engine.onTick();
    now = DateTime(2026, 11, 13, 7, 30, 25);
    await engine.onTick();
    expect(calls.sounds, 1);
    expect(calls.alerts, isEmpty);
    engine.dispose();
  });

  test('AND needs every trigger to hold; OR needs any', () async {
    final (engine, source, calls) = await ready([
      const Automation(id: 1, name: 'Both', matchAll: true, cooldown: Duration(minutes: 1),
          triggers: [MessageTrigger(contains: 'sos'), BatteryTrigger(node: 9, below: 30)],
          actions: [AlertAction('both')]),
    ]);
    source
      ..battery[9] = 80
      ..messages = [incoming(1, 'sos')]
      ..update();
    await settle();
    expect(calls.alerts, isEmpty, reason: 'battery is fine');
    now = now.add(const Duration(minutes: 2));
    source
      ..battery[9] = 20
      ..messages = [incoming(1, 'sos'), incoming(2, 'sos again')]
      ..update();
    await settle();
    expect(calls.alerts.map((a) => a.$3), ['both']);
    engine.dispose();
  });

  test('cooldown and the hourly cap stop runaway rules', () async {
    final (engine, source, calls) = await ready([
      const Automation(id: 1, name: 'Echo', triggers: [MessageTrigger()], actions: [SoundAction()]),
    ]);
    for (var i = 1; i <= 3; i++) {
      source
        ..messages = [...source.messages, incoming(i, 'm$i')]
        ..update();
      await settle();
    }
    expect(calls.sounds, 1, reason: 'five-minute cooldown');
    engine.dispose();

    final (busy, busySource, busyCalls) = await ready([
      const Automation(id: 1, name: 'Busy', cooldown: Duration(minutes: 1), triggers: [MessageTrigger()],
          actions: [SoundAction()]),
    ]);
    for (var i = 1; i <= 40; i++) {
      now = now.add(const Duration(seconds: 61));
      busySource
        ..messages = [incoming(i, 'm$i')]
        ..update();
      await settle();
    }
    expect(busyCalls.sounds, AutomationEngine.maxPerHour);
    busy.dispose();
  });

  test('webhooks only run when web requests are allowed, and report HTTP errors', () async {
    const rule = Automation(id: 1, name: 'Hook', cooldown: Duration(minutes: 1), triggers: [MessageTrigger()],
        actions: [WebhookAction('https://example.org/x')]);
    final (off, offSource, offCalls) = await ready([rule]);
    offSource
      ..messages = [incoming(1, 'hi')]
      ..update();
    await settle();
    expect(offCalls.posts, isEmpty);
    expect(off.log.single.problem, AutoProblem.webOff);
    off.dispose();

    final (on, onSource, onCalls) = await ready([rule], webhooks: true);
    onCalls.status = 500;
    onSource
      ..messages = [incoming(1, 'hi')]
      ..update();
    await settle();
    expect(onCalls.posts.single.$1, Uri.parse('https://example.org/x'));
    expect(onCalls.posts.single.$2, contains('"rule":"Hook"'));
    expect(on.log.single.problem, AutoProblem.httpError);
    expect(on.log.single.status, 500);
    on.dispose();
  });

  test('nothing runs before the radio is ready', () async {
    final calls = Calls();
    final engine = AutomationEngine(hooks: calls.hooks, clock: () => now);
    await engine.save(const AutomationSettings(rules: [
      Automation(id: 1, name: 'T', triggers: [TimeTrigger(hour: 12, minute: 0)], actions: [SoundAction()]),
    ]));
    final source = FakeSource();
    engine.attach(source);
    await engine.onTick();
    expect(calls.sounds, 0);
    engine.dispose();
  });

  test('links and addresses are checked', () {
    expect(WebhookAction.validUrl('https://example.org/a'), isTrue);
    expect(WebhookAction.validUrl('ftp://example.org'), isFalse);
    expect(WebhookAction.validUrl('example.org'), isFalse);
    expect(JoinChannelAction.validLink('https://meshtastic.org/e/#CgMSAQESBggBQANIAQ'), isTrue);
    expect(JoinChannelAction.validLink('https://example.org'), isFalse);
    expect(AutoAction.fromJson({'a': 'webhook', 'url': 'nope'}), isNull);
  });

  testWidgets('a rule can be made in the editor, in French', (tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    final engine = AutomationEngine(hooks: Calls().hooks);
    addTearDown(engine.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: AutomationsPage(engine: engine, radio: radio),
    ));
    await tester.pump();
    expect(find.text('Autoriser les requêtes web'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.byKey(const ValueKey('automations-webhooks'))).value, isFalse);
    expect(find.text('Aucune automatisation pour l\'instant.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('automations-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('automation-name')), 'Aide');
    await tester.tap(find.byKey(const ValueKey('automation-add-trigger')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Message reçu').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('automation-dialog-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('automation-add-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jouer le son d\'alerte').last);
    await tester.pumpAndSettle();
    expect(find.text('Tout message reçu'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('automation-save')));
    await tester.pumpAndSettle();

    final rule = engine.settings.rules.single;
    expect(rule.name, 'Aide');
    expect(rule.triggers.single, isA<MessageTrigger>());
    expect(rule.actions.single, isA<SoundAction>());
    expect(find.text('Aide'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Aide activée')), findsOneWidget);
  });
}
