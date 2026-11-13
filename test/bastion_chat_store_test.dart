import 'dart:convert';

import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/bastion_chat_store.dart';
import 'package:bastion/services/bastion_message_archive.dart';
import 'package:bastion/services/bastion_phone_backup.dart';
import 'package:bastion/services/bastion_radio_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

BastionChatMessage _msg(int id, {double? snr}) => BastionChatMessage(
      packetId: id, from: 2, to: 0xffffffff, channel: 0, text: 'message $id "quoted"',
      timestamp: DateTime.utc(2026, 11, 7, 10, id), direction: BastionMessageDirection.incoming,
      deliveryState: BastionDeliveryState.received, rxSnr: snr, hops: 1,
    );

String _archive(List<int> ids) => jsonEncode({
      'messages': [for (final i in ids) _msg(i, snr: 7.0).toJson()],
      'pending': [const PendingTextMessage(text: 'queued', destination: 5, channel: 0, packetId: 99).toJson()],
    });

void main() {
  sqfliteFfiInit();
  late SqliteChatArchiveStore store;
  var n = 0;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    store = await SqliteChatArchiveStore.open(databaseFactoryFfi, 'file:chat${n++}?mode=memory&cache=shared');
  });
  tearDown(() async {
    BastionChatStorage.active = null;
    await store.close();
  });

  test('archives round-trip through rows, and odd data is kept verbatim', () async {
    const key = 'bastion.comms.archive.v2.radio.0000abcd';
    final raw = _archive([1, 2, 3]);
    await store.write(key, raw);
    expect(jsonDecode((await store.read(key))!), jsonDecode(raw));
    await store.write(key, _archive([4]));
    expect((jsonDecode((await store.read(key))!) as Map)['messages'], hasLength(1), reason: 'a save replaces the archive');

    const odd = 'bastion.comms.archive.v1.unreadable';
    await store.write(odd, 'not json {');
    expect(await store.read(odd), 'not json {');
    await store.write('$key.extra', '{"messages":[],"pending":[],"other":1}');
    expect(await store.read('$key.extra'), '{"messages":[],"pending":[],"other":1}');

    expect(await store.keys(), {key, odd, '$key.extra'});
    await store.remove(key);
    expect(await store.read(key), isNull);
  });

  test('migration moves chat archives out of preferences after checking them', () async {
    final prefs = SharedPreferencesAsync();
    const a = 'bastion.comms.archive.v2.radio.00000001';
    const legacy = 'bastion.comms.archive.v1';
    await prefs.setString(a, _archive([1, 2]));
    await prefs.setString(legacy, _archive([3]));
    await prefs.setString('bastion.comms.last_radio_name', 'kept');
    await prefs.setString('bastion.nodevault.v2.radio.00000001', '[]');

    expect(await store.migrateFrom(prefs), isNull);
    expect(await prefs.getString(a), isNull);
    expect(await prefs.getString(legacy), isNull);
    expect(await prefs.getString('bastion.comms.last_radio_name'), 'kept', reason: 'only archives move');
    expect(await prefs.getString('bastion.nodevault.v2.radio.00000001'), '[]');
    expect(jsonDecode((await store.read(a))!), jsonDecode(_archive([1, 2])));

    // A second launch finds nothing left to move.
    expect(await store.migrateFrom(prefs), isNull);
  });

  test('a migration that cannot read preferences leaves everything in place', () async {
    SharedPreferencesAsyncPlatform.instance = _Unreadable();
    final prefs = SharedPreferencesAsync();
    await prefs.setString('bastion.comms.archive.v2.radio.00000001', _archive([1]));
    final problem = await store.migrateFrom(prefs);
    expect(problem, contains('could not be moved'));
    expect(await store.keys(), isEmpty);
    expect((SharedPreferencesAsyncPlatform.instance! as _Unreadable).removed, isFalse);
  });

  test('the message archive, Radio data and phone backups use the database', () async {
    BastionChatStorage.active = store;
    final prefs = SharedPreferencesAsync();
    final archive = BastionMessageArchive(preferences: prefs, radio: 0x1234abcd, historyLimit: () => 500);
    await archive.load();
    expect(await archive.save(messages: [_msg(1), _msg(2)], pending: const []), isTrue);
    expect(await prefs.getKeys(), isNot(contains(BastionMessageArchive.radioKey(0x1234abcd))));
    final reloaded = await BastionMessageArchive(preferences: prefs, radio: 0x1234abcd).load();
    expect([for (final m in reloaded.messages) m.packetId], [1, 2]);
    expect(reloaded.messages.first.hops, 1);

    final radios = await BastionRadioData(preferences: prefs).list();
    expect(radios.single.radio, 0x1234abcd);
    expect(radios.single.messages, 2);

    final backup = BastionPhoneBackup(preferences: prefs);
    final exported = await backup.export();
    final (summary, values) = BastionPhoneBackup.parse(exported);
    expect(summary.messages, 2);
    expect(await backup.erase(everything: false), 1);
    expect(await store.keys(), isEmpty);
    await backup.restore(values);
    expect(await store.keys(), {BastionMessageArchive.radioKey(0x1234abcd)});
    expect(await prefs.getKeys(), isNot(contains(BastionMessageArchive.radioKey(0x1234abcd))));
  });
}

final class _Unreadable extends InMemorySharedPreferencesAsync {
  _Unreadable() : super.empty();
  bool removed = false;
  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) async {
    if (key.startsWith('bastion.comms.archive.')) throw StateError('read failed');
    return super.getString(key, options);
  }

  @override
  Future<bool> clear(ClearPreferencesParameters parameters, SharedPreferencesOptions options) async {
    removed = true;
    return super.clear(parameters, options);
  }
}
