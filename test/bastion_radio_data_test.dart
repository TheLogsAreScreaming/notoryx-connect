import 'dart:convert';
import 'dart:typed_data';

import 'package:bastion/services/bastion_message_archive.dart';
import 'package:bastion/services/bastion_nodedex.dart';
import 'package:bastion/services/bastion_radio_data.dart';
import 'package:bastion/services/bastion_trails.dart';
import 'package:bastion/services/meshtastic_connection_controller.dart';
import 'package:bastion/services/meshtastic_messaging_service.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/services/meshtastic_radio_session.dart';
import 'package:bastion/services/meshtastic_radio_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const oldRadio = 0xA1A1A1A1;
const newRadio = 0xB2B2B2B2;
const broadcast = 0xffffffff;

class _Transport implements MeshtasticRadioTransport {
  @override Stream<Uint8List> get fromRadio => const Stream.empty();
  @override bool get isConnected => true;
  @override Future<void> connect() async {}
  @override Future<void> disconnect() async {}
  @override Future<void> sendToRadio(Uint8List envelope) async {}
}

BastionChatMessage msg(int id, int from, String text) => BastionChatMessage(
  packetId: id, from: from, to: broadcast, channel: 0, text: text,
  timestamp: DateTime.utc(2026, 11, 1, 0, id), direction: BastionMessageDirection.outgoing,
  deliveryState: BastionDeliveryState.sent);

BastionNodeRecord rec(int num, {String? name, int encounters = 1, int day = 1}) => BastionNodeRecord(
  num: num, longName: name, firstSeen: DateTime.utc(2026, 11, day), lastSeen: DateTime.utc(2026, 11, day),
  encounters: encounters);

void main() {
  late SharedPreferencesAsync prefs;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
  });

  Future<void> seedDex(int radio, List<BastionNodeRecord> records) => prefs.setString(
      BastionNodeDex.radioKey(radio), jsonEncode([for (final r in records) r.toJson()]));

  test('lists each radio with its name and what is stored', () async {
    await BastionMessageArchive(radio: oldRadio).save(messages: [msg(1, oldRadio, 'a'), msg(2, oldRadio, 'b')], pending: []);
    await seedDex(oldRadio, [rec(oldRadio, name: 'Old Echo'), rec(0x77)]);
    await seedDex(newRadio, [rec(0x77)]);
    await prefs.setString(BastionTrails.key(oldRadio), jsonEncode({'119': [[1.0, 2.0, 1762000000]]}));
    await prefs.setString('${BastionNodeDex.radioKey(newRadio)}.unreadable', 'x');

    final radios = await BastionRadioData().list();
    expect([for (final r in radios) r.radio], [oldRadio, newRadio]);
    expect(radios.first.label, 'Old Echo (!a1a1a1a1)');
    expect([radios.first.messages, radios.first.nodes, radios.first.trails], [2, 2, 1]);
    expect(radios.last.label, '!b2b2b2b2');
    expect([radios.last.messages, radios.last.nodes, radios.last.trails], [0, 1, 0]);
  });

  test('keeps a copy of the receiving radio and removes the moved one', () async {
    await seedDex(newRadio, [rec(0x77)]);
    await seedDex(oldRadio, [rec(0x88)]);
    final data = BastionRadioData();
    await data.keepBeforeMove(newRadio);
    expect(await prefs.getString('${BastionNodeDex.radioKey(newRadio)}${BastionRadioData.beforeMoveSuffix}'),
        await prefs.getString(BastionNodeDex.radioKey(newRadio)));
    await data.remove(oldRadio);
    expect(await prefs.getString(BastionNodeDex.radioKey(oldRadio)), isNull);
    expect([for (final r in await data.list()) r.radio], [newRadio]);
  });

  test('NodeDex merges the old radio into the new one without losing either', () async {
    await seedDex(newRadio, [rec(0x77, encounters: 2, day: 3), rec(0x99)]);
    await seedDex(oldRadio, [rec(0x77, name: 'Hiker', encounters: 5, day: 1), rec(0x88)]);
    final dex = BastionNodeDex();
    await dex.useRadio(newRadio);
    expect(await dex.importRadio(oldRadio), isTrue);
    final byNum = {for (final r in dex.records) r.num: r};
    expect(byNum.keys.toSet(), {0x77, 0x88, 0x99});
    expect(byNum[0x77]!.encounters, 7);
    expect(byNum[0x77]!.longName, 'Hiker');
    expect(byNum[0x77]!.firstSeen, DateTime.utc(2026, 11, 1).toLocal());

    final reloaded = BastionNodeDex();
    await reloaded.useRadio(newRadio);
    expect(reloaded.records, hasLength(3));
  });

  test('trails merge in time order without duplicate points', () async {
    final now = DateTime.utc(2026, 11, 5, 12);
    int t(int minutes) => now.subtract(Duration(minutes: minutes)).millisecondsSinceEpoch ~/ 1000;
    await prefs.setString(BastionTrails.key(newRadio), jsonEncode({'119': [[1.0, 1.0, t(10)]]}));
    await prefs.setString(BastionTrails.key(oldRadio), jsonEncode({
      '119': [[0.0, 0.0, t(30)], [1.0, 1.0, t(10)]],
      '136': [[5.0, 5.0, t(5)]],
    }));
    final trails = BastionTrails(clock: () => now);
    await trails.useRadio(newRadio);
    expect(await trails.importRadio(oldRadio), isTrue);
    expect([for (final p in trails.trailOf(119)) p.latitude], [0.0, 1.0]);
    expect(trails.trailOf(136), hasLength(1));

    final reloaded = BastionTrails(clock: () => now);
    await reloaded.useRadio(newRadio);
    expect(reloaded.trailOf(119), hasLength(2));
  });

  test('messages and the queue merge into the attached radio and are saved', () async {
    await BastionMessageArchive(radio: newRadio).save(messages: [msg(2, newRadio, 'new')], pending: []);
    final connection = MeshtasticConnectionController();
    final session = MeshtasticRadioSession(transport: _Transport(), connection: connection);
    final messaging = MeshtasticMessagingService(session: session, connection: connection);
    await messaging.start();
    await messaging.attachArchive(BastionMessageArchive(radio: newRadio));

    final saved = await messaging.importHistory(BastionArchiveSnapshot(
      messages: [msg(1, oldRadio, 'old'), msg(2, newRadio, 'new')],
      pending: [const PendingTextMessage(text: 'queued', destination: broadcast, channel: 0, packetId: 9)],
    ));
    expect(saved, isTrue);
    expect([for (final m in messaging.messages) m.text], ['old', 'new']);
    expect([for (final p in messaging.pending) p.packetId], [9]);
    final stored = await BastionMessageArchive(radio: newRadio).load();
    expect([for (final m in stored.messages) m.text], ['old', 'new']);
    await messaging.dispose();
  });

  test('moving needs the new radio connected', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    expect(await radio.moveRadioData(oldRadio), 'Connect to the new radio first.');
  });
}
