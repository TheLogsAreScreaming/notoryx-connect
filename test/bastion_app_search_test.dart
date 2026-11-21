import 'package:bastion/main.dart';
import 'package:bastion/services/bastion_app_search.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/bastion_node_vault.dart';
import 'package:bastion/services/bastion_waypoints.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_text_codec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _me = 0x0a0a0a0a;
final _t0 = DateTime(2026, 11, 1, 12);

BastionChatMessage _msg(int id, String text, {int from = 0x22, int to = MeshtasticTextCodec.broadcastNode, int minutes = 0, bool reaction = false}) =>
    BastionChatMessage(
      packetId: id,
      from: from,
      to: to,
      channel: 0,
      text: text,
      timestamp: _t0.add(Duration(minutes: minutes)),
      direction: from == _me ? BastionMessageDirection.outgoing : BastionMessageDirection.incoming,
      deliveryState: from == _me ? BastionDeliveryState.sent : BastionDeliveryState.received,
      isReaction: reaction,
    );

void main() {
  group('BastionAppSearch', () {
    final nodes = [
      MeshtasticNode(num: 0x22, longName: 'Ridge Relay', shortName: 'RDG', lastHeard: _t0),
      MeshtasticNode(num: 0xb2c649cb, longName: 'Camp Base', shortName: 'CAMP', lastHeard: _t0.subtract(const Duration(hours: 1))),
      MeshtasticNode(num: 0x33, longName: 'Old Ridge Tower', lastHeard: _t0.add(const Duration(hours: 1))),
    ];

    test('an empty query finds nothing', () {
      expect(BastionAppSearch.run('  ', nodes: nodes).isEmpty, isTrue);
    });

    test('finds nodes by name, short name and ID, names starting with the query first', () {
      final byName = BastionAppSearch.run('ridge', nodes: nodes).nodes.map((n) => n.name);
      expect(byName, ['Ridge Relay', 'Old Ridge Tower']);
      expect(BastionAppSearch.run('camp', nodes: nodes).nodes.single.num, 0xb2c649cb);
      expect(BastionAppSearch.run('!b2c6', nodes: nodes).nodes.single.name, 'Camp Base');
      expect(BastionAppSearch.run('B2C649', nodes: nodes).nodes.single.name, 'Camp Base');
    });

    test('adds remembered nodes the radio no longer lists, once', () {
      final remembered = [
        BastionNodeRecord(num: 0x22, longName: 'Ridge Relay', firstSeen: _t0, lastSeen: _t0, encounters: 1),
        BastionNodeRecord(num: 0x44, longName: 'Ridge Camp Two', firstSeen: _t0, lastSeen: _t0, encounters: 0),
      ];
      final found = BastionAppSearch.run('ridge', nodes: nodes, remembered: remembered).nodes;
      expect(found.map((n) => n.num), unorderedEquals([0x22, 0x33, 0x44]));
      expect(found.firstWhere((n) => n.num == 0x44).remembered, isTrue);
      expect(found.firstWhere((n) => n.num == 0x22).remembered, isFalse);
    });

    test('finds messages newest first, ignoring reactions and accents', () {
      final found = BastionAppSearch.run('cafe', messages: [
        _msg(1, 'Meet at the café', minutes: 1),
        _msg(2, 'cafe is closed', minutes: 5),
        _msg(3, 'cafe', reaction: true, minutes: 9),
        _msg(4, 'nothing here'),
      ]).messages;
      expect(found.map((m) => m.message.packetId), [2, 1]);
      expect(found.first.conversation.key, 'ch0');
    });

    test('direct messages point at the other node', () {
      final found = BastionAppSearch.run('hello', messages: [_msg(5, 'hello there', to: _me)]).messages.single;
      expect(found.conversation.key, 'dm${0x22}');
    });

    test('finds channels, places and features', () {
      final r = BastionAppSearch.run(
        'bridge',
        channels: const [SearchChannel(1, 'Bridge'), SearchChannel(0, 'Primary channel')],
        places: const [
          MeshWaypoint(id: 1, latitude: 35, longitude: -80, name: 'Trailhead', description: 'by the bridge'),
          MeshWaypoint(id: 2, latitude: 35, longitude: -80, name: 'Summit'),
        ],
        features: const [
          SearchFeature(id: 'a', title: 'Bridge mode', subtitle: 'x'),
          SearchFeature(id: 'b', title: 'Privacy', subtitle: 'y', keywords: 'bridge'),
          SearchFeature(id: 'c', title: 'Other', subtitle: 'z'),
        ],
      );
      expect(r.channels.single.index, 1);
      expect(r.places.single.name, 'Trailhead');
      expect(r.features.map((f) => f.id), ['a', 'b']);
    });

    test('caps how many messages come back', () {
      final many = [for (var i = 0; i < 100; i++) _msg(i, 'ping $i', minutes: i)];
      expect(BastionAppSearch.run('ping', messages: many).messages, hasLength(BastionAppSearch.messageLimit));
    });
  });

  group('search page', () {
    setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

    testWidgets('opens from the top bar on every tab and finds app pages', (tester) async {
      await tester.pumpWidget(const BastionApp());
      await tester.pumpAndSettle();
      for (final icon in [Icons.hub_outlined, Icons.more_horiz]) {
        await tester.tap(find.byIcon(icon).last);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('app-search')), findsOneWidget);
      }

      await tester.tap(find.byKey(const ValueKey('app-search')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Search everything on this phone'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('app-search-field')), 'backup');
      await tester.pumpAndSettle();
      expect(find.text('Settings and tools'), findsOneWidget);
      expect(find.text('Phone data backup'), findsOneWidget);
      expect(find.text('Encrypted radio backup'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('app-search-field')), 'zzqx');
      await tester.pumpAndSettle();
      expect(find.text('Nothing matches “zzqx”.'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('app-search-field')), 'import nodes');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import nodes from Meshtastic'));
      await tester.pumpAndSettle();
      expect(find.text('Choose file'), findsOneWidget);
    });

    testWidgets('a feature on a tab closes search and switches to that tab', (tester) async {
      await tester.pumpWidget(const BastionApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('app-search')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('app-search-field')), 'demo');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Demo mode'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('app-search-field')), findsNothing);
      expect(find.text('Your radio, how the app behaves, and your data.'), findsOneWidget);
    });
  });
}
