import 'dart:convert';

import 'package:bastion/generated/meshtastic/mesh.pbenum.dart' as pb;
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/nodedb_import_page.dart';
import 'package:bastion/services/bastion_node_keys.dart';
import 'package:bastion/services/bastion_radio_history.dart';
import 'package:bastion/services/bastion_node_vault.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_nodedb_import.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/traceroute_page.dart';
import 'package:bastion/main.dart' show pickConversation, conversationTitle;
import 'package:bastion/services/bastion_conversations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _me = 0x11111111;
const _radio = 0x0a0a0a0a;
final _keyA = base64Encode(List.generate(32, (i) => i));
final _keyB = base64Encode(List.generate(32, (i) => 255 - i));

/// Seconds since 1970 for [daysAgo] days before 2026-11-01.
int _t(int daysAgo) =>
    DateTime.utc(2026, 11, 1).subtract(Duration(days: daysAgo)).millisecondsSinceEpoch ~/ 1000;

Map<String, Object?> _n(int num, String name, {
  String transport = 'TRANSPORT_LORA',
  int daysAgo = 1,
  bool favorite = false,
  Map<String, Object?>? position,
  String? key,
  String? hw = 'HELTEC_V3',
}) => {
  'num': num,
  'id': '!${num.toRadixString(16).padLeft(8, '0')}',
  'longName': name,
  'shortName': name.substring(0, 4),
  'hwModel': ?hw,
  'role': 'CLIENT',
  'lastHeard': _t(daysAgo),
  'viaMqtt': true,
  'lastTransport': transport,
  if (favorite) 'isFavorite': true,
  'position': ?position,
  'publicKey': ?key,
};

String _file({List<Object?>? nodes, int version = 1}) => jsonEncode({
  'schemaVersion': version,
  'exportedAt': '2026-11-01T00:00:00.000Z',
  'myNodeNum': _me,
  'nodes': nodes ??
      [
        _n(_me, 'Own Radio'),
        _n(0x22, 'Ridge Relay', position: {'latitude': 35.1, 'longitude': -80.5, 'time': _t(2)}, key: _keyA),
        _n(0x33, 'Camp Base', favorite: true, transport: 'TRANSPORT_MQTT', daysAgo: 40),
        _n(0x44, 'Far Away One', transport: 'TRANSPORT_MQTT', daysAgo: 3),
        _n(0x55, 'Far Away Two', transport: 'TRANSPORT_MQTT', daysAgo: 1),
        _n(0x66, 'No Fix Node', position: {'latitude': 0.0, 'longitude': 0.0}, hw: 'NOT_A_MODEL'),
        {'num': 0, 'longName': 'broken'},
        'junk',
      ],
});

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('parse', () {
    test('reads nodes, skips the exporting radio and junk', () {
      final export = MeshtasticNodeDbExport.parse(_file());
      expect(export.myNodeNum, _me);
      expect(export.exportedFromName, 'Own Radio');
      expect(export.nodes.map((n) => n.num), unorderedEquals([0x22, 0x33, 0x44, 0x55, 0x66]));

      final relay = export.nodes.firstWhere((n) => n.num == 0x22);
      expect(relay.hardwareModel, pb.HardwareModel.HELTEC_V3.value);
      expect(relay.latitude, 35.1);
      expect(relay.publicKey, _keyA);
      expect(relay.internetOnly, isFalse);
      expect(relay.lastHeard, DateTime.utc(2026, 10, 31));

      final noFix = export.nodes.firstWhere((n) => n.num == 0x66);
      expect(noFix.hasPosition, isFalse, reason: '0,0 means no fix');
      expect(noFix.hardwareModel, isNull);
    });

    test('sorts radio and internet nodes by last transport', () {
      final export = MeshtasticNodeDbExport.parse(_file());
      expect(export.heardByRadio.map((n) => n.num), unorderedEquals([0x22, 0x66]));
      expect(export.internetOnly.map((n) => n.num), unorderedEquals([0x33, 0x44, 0x55]));
      expect(export.favoriteCount, 1);
    });

    test('picks radio nodes and favorites, internet nodes only when asked, newest first', () {
      final export = MeshtasticNodeDbExport.parse(_file());
      expect(export.pick(includeInternet: false).map((n) => n.num),
          unorderedEquals([0x22, 0x33, 0x66]));
      final all = export.pick(includeInternet: true).map((n) => n.num).toList();
      expect(all, hasLength(5));
      expect(all.indexOf(0x55), lessThan(all.indexOf(0x44)));
    });

    test('internet nodes are capped', () {
      final export = MeshtasticNodeDbExport.parse(_file(nodes: [
        for (var i = 1; i <= MeshtasticNodeDbExport.internetLimit + 5; i++)
          _n(0x1000 + i, 'Mqtt node $i', transport: 'TRANSPORT_MQTT'),
      ]));
      expect(export.pick(includeInternet: true), hasLength(MeshtasticNodeDbExport.internetLimit));
    });

    test('refuses files that are not a node database or are newer', () {
      expect(() => MeshtasticNodeDbExport.parse('nope'),
          throwsA(isA<FormatException>().having((e) => e.message, 'message', 'notJson')));
      expect(() => MeshtasticNodeDbExport.parse('{"radios": []}'),
          throwsA(isA<FormatException>().having((e) => e.message, 'message', 'notNodeDb')));
      expect(() => MeshtasticNodeDbExport.parse(_file(version: 2)),
          throwsA(isA<FormatException>().having((e) => e.message, 'message', 'newerVersion')));
    });

    test('drops keys that are not 32 bytes', () {
      final export = MeshtasticNodeDbExport.parse(_file(nodes: [
        _n(0x22, 'Short Key', key: base64Encode([1, 2, 3])),
        _n(0x23, 'Bad Key', key: 'not base64!'),
      ]));
      expect(export.nodes.every((n) => n.publicKey == null), isTrue);
    });
  });

  group('vault', () {
    BastionNodeRecord rec(int num, String name, DateTime seen, {int encounters = 0, double? lat}) =>
        BastionNodeRecord(num: num, longName: name, firstSeen: seen, lastSeen: seen,
            encounters: encounters, latitude: lat, longitude: lat == null ? null : -80.0, positionTime: lat == null ? null : seen);

    test('imports into the shown radio, keeping what this phone already saw', () async {
      final vault = BastionNodeVault();
      await vault.useRadio(_radio);
      await vault.observe(const MeshtasticNode(num: 0x22, longName: 'Ridge Relay'));
      await vault.observe(const MeshtasticNode(num: 0x22, longName: 'Ridge Relay'));
      final older = DateTime(2026, 10, 1);
      final added = await vault.importNodes(_radio, [
        rec(0x22, 'Old Name', older, lat: 35.0),
        rec(0x33, 'Camp Base', older),
      ], favorites: {0x33});
      expect(added, 1);
      final relay = vault.records.firstWhere((r) => r.num == 0x22);
      expect(relay.longName, 'Ridge Relay', reason: 'the newer name wins');
      expect(relay.encounters, 2, reason: 'imports do not count as encounters');
      expect(relay.latitude, 35.0, reason: 'a missing position is filled in');
      expect(relay.firstSeen, older);
      expect(vault.records.first.num, 0x33, reason: 'favorites sort first');

      final reloaded = BastionNodeVault();
      await reloaded.useRadio(_radio);
      expect(reloaded.records.map((r) => r.num), containsAll([0x22, 0x33]));
      expect(reloaded.records.firstWhere((r) => r.num == 0x33).favorite, isTrue);
    });

    test('imports into another radio without changing the shown list', () async {
      final vault = BastionNodeVault();
      await vault.useRadio(_radio);
      expect(await vault.importNodes(_me, [rec(0x44, 'Elsewhere', DateTime(2026, 10, 2))]), 1);
      expect(vault.records, isEmpty);
      await vault.useRadio(_me);
      expect(vault.records.single.longName, 'Elsewhere');
    });

    test('an import never clears a star or note already set', () async {
      final vault = BastionNodeVault();
      await vault.useRadio(_radio);
      await vault.observe(const MeshtasticNode(num: 0x22, longName: 'Ridge Relay'));
      await vault.setNote(0x22, 'on the ridge');
      await vault.importNodes(_radio, [rec(0x22, 'Ridge Relay', DateTime(2026, 10, 1))], favorites: {0x22});
      final relay = vault.records.single;
      expect(relay.note, 'on the ridge');
      expect(relay.favorite, isFalse);
    });

    test('the sorted list refreshes after changes', () async {
      final vault = BastionNodeVault();
      await vault.useRadio(_radio);
      expect(vault.records, isEmpty);
      await vault.observe(const MeshtasticNode(num: 0x22, longName: 'Ridge Relay'));
      expect(vault.records, hasLength(1));
      await vault.setFavorite(0x22, true);
      expect(vault.records.single.favorite, isTrue);
    });
  });

  test('imported keys never replace a key already remembered', () async {
    final keys = BastionNodeKeys();
    await keys.load();
    await keys.check(0x22, base64Decode(_keyA));
    expect(await keys.rememberImported({0x22: _keyB, 0x33: _keyB}), 1);
    expect(keys.knownKey(0x22), _keyA);
    expect(keys.knownKey(0x33), _keyB);
    expect(keys.hasChanged(0x22), isFalse);
  });

  test('the coordinator adds picked nodes and their keys', () async {
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await radio.nodeKeys.load();
    final result = await radio.importNodeDatabase(
        MeshtasticNodeDbExport.parse(_file()), includeInternet: false);
    expect(result, isNotNull);
    expect(result!.radio, _me, reason: 'no radio yet: saved for the radio the file came from');
    expect(result.added, 3);
    expect(result.keys, 1);
    expect(radio.nodeKeys.knownKey(0x22), _keyA);
  });

  test('imported nodes the radio does not list show in the known nodes', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
      BastionRadioHistory.lastRadioKey: _me,
    });
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    // Let the last radio's saved nodes load.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final result = await radio.importNodeDatabase(
        MeshtasticNodeDbExport.parse(_file()), includeInternet: false);
    expect(result?.radio, _me);
    expect(radio.nodes, isEmpty, reason: 'no radio is connected');
    final known = {for (final n in radio.knownNodes) n.num: n};
    expect(known.keys, containsAll([0x22, 0x33, 0x66]));
    expect(known[0x22]!.longName, 'Ridge Relay');
    expect(known[0x22]!.latitude, 35.1);
    expect(known[0x22]!.lastHeard, isNotNull);
    expect(radio.knownNodeCount, radio.knownNodes.length);

    await radio.filters.setIgnored(0x22, true);
    expect(radio.knownNodes.map((n) => n.num), isNot(contains(0x22)),
        reason: 'ignored nodes stay hidden');
    expect(radio.knownNodeCount, radio.knownNodes.length);
  });

  testWidgets('traceroute opened from an imported node keeps it as the destination',
      (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
      BastionRadioHistory.lastRadioKey: _me,
    });
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await radio.importNodeDatabase(MeshtasticNodeDbExport.parse(_file()), includeInternet: false);
    });
    expect(radio.nodes.map((n) => n.num), isNot(contains(0x22)), reason: 'only restored, not live');

    Future<void> open(int target) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TraceroutePage(key: ValueKey(target), radio: radio, initialTarget: target),
      ));
      await tester.pumpAndSettle();
    }

    await open(0x22);
    expect(find.text('Ridge Relay'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // A node the phone knows nothing about still shows by its ID.
    await open(0xabc);
    expect(find.text('!00000abc'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new chat finds an imported node by search and names it', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
      BastionRadioHistory.lastRadioKey: _me,
    });
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await radio.importNodeDatabase(MeshtasticNodeDbExport.parse(_file()), includeInternet: false);
    });
    BastionConversation? picked;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async => picked = await pickConversation(context, radio,
              title: 'New chat', everyNode: true),
          child: const Text('open'),
        ),
      )),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    // Not heard by the radio, so not listed until searched for.
    expect(find.text('Ridge Relay'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('pick-node-search')), 'ridge');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ridge Relay'));
    await tester.pumpAndSettle();
    expect(picked, BastionConversation.direct(0x22));

    final l = await AppLocalizations.delegate.load(const Locale('en'));
    expect(conversationTitle(l, radio, BastionConversation.direct(0x22)), 'Ridge Relay');
    expect(conversationTitle(l, radio, BastionConversation.direct(0xabc)), '!00000abc');
  });

  testWidgets('the page shows what is in the file and imports it', (tester) async {
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NodeDbImportPage(radio: radio, files: _FakeFiles(_file())),
    ));
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('ndb-choose')));
      for (var i = 0; i < 50 && find.byKey(const ValueKey('ndb-import')).evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('Saved from Own Radio'), findsOneWidget);
    expect(find.text('2 nodes heard by radio'), findsOneWidget);
    expect(find.text('3 nodes heard only over the internet (MQTT)'), findsOneWidget);
    expect(find.text('Import 3 nodes'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ndb-internet')));
    await tester.pump();
    expect(find.text('Import 5 nodes'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('ndb-import')));
      for (var i = 0; i < 50 && find.textContaining('Done for').evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    expect(find.textContaining('5 new, 0 already known'), findsOneWidget);
  });

  testWidgets('a file that is not a node database says so', (tester) async {
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NodeDbImportPage(radio: radio, files: _FakeFiles('{"hello": 1}')),
    ));
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('ndb-choose')));
      for (var i = 0; i < 50 && find.textContaining("isn't").evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    expect(find.text("That isn't a Meshtastic node database file."), findsOneWidget);
  });
}

class _FakeFiles implements NodeDbFiles {
  _FakeFiles(this.text);
  final String text;
  @override
  Future<String?> open() async => text;
}
