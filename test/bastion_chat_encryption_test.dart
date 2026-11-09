import 'dart:convert';
import 'dart:io';

import 'package:bastion/services/bastion_chat_encryption.dart';
import 'package:bastion/services/bastion_chat_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakeVault implements BastionKeyVault {
  List<int>? key;
  bool broken = false;
  @override
  Future<List<int>?> read() async {
    if (broken) throw StateError('locked');
    return key;
  }
  @override
  Future<void> write(List<int> value) async => key = value;
  @override
  Future<void> delete() async => key = null;
}

const a = '${BastionChatStorage.prefix}one';
const b = '${BastionChatStorage.prefix}two';
final archive = jsonEncode({
  'messages': [{'packetId': 1, 'from': 2, 'timestamp': '2026-11-08', 'text': 'meet at the secret ridge'}],
  'pending': [],
});

void main() {
  sqfliteFfiInit();
  late SqliteChatArchiveStore plain;
  late FakeVault vault;
  late File file;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    vault = FakeVault();
    file = File('${Directory.systemTemp.createTempSync('nx-enc-').path}/chats.db');
    plain = await SqliteChatArchiveStore.open(databaseFactoryFfi, file.path);
    await plain.write(a, archive);
    await plain.write(b, 'not json');
    BastionChatStorage.active = plain;
  });
  tearDown(() async {
    BastionChatStorage.active = null;
    await plain.close();
  });

  test('turning on keeps every archive and removes the text from the file', () async {
    expect(utf8.decode(file.readAsBytesSync(), allowMalformed: true), contains('secret ridge'));
    expect(await BastionChatStorage.setEncrypted(true, vault: vault), isNull);
    expect(BastionChatStorage.encrypted, isTrue);
    final store = BastionChatStorage.of(throw_());
    expect(jsonDecode((await store.read(a))!), jsonDecode(archive));
    expect(await store.read(b), 'not json');
    expect(EncryptedChatArchiveStore.isEncrypted((await plain.read(a))!), isTrue);
    expect(utf8.decode(file.readAsBytesSync(), allowMalformed: true), isNot(contains('secret ridge')));
  });

  test('turning off restores plain archives and drops the key', () async {
    await BastionChatStorage.setEncrypted(true, vault: vault);
    expect(await BastionChatStorage.setEncrypted(false, vault: vault), isNull);
    expect(BastionChatStorage.encrypted, isFalse);
    expect(vault.key, isNull);
    expect(jsonDecode((await plain.read(a))!), jsonDecode(archive));
  });

  test('a restart reopens with the saved key and finishes an interrupted change', () async {
    await BastionChatStorage.setEncrypted(true, vault: vault);
    await plain.write(b, 'left plain by an interrupted run');
    BastionChatStorage.active = plain;
    expect(await BastionChatStorage.applySavedEncryption(vault: vault), isNull);
    expect(EncryptedChatArchiveStore.isEncrypted((await plain.read(b))!), isTrue);
    expect(await BastionChatStorage.of(throw_()).read(b), 'left plain by an interrupted run');
  });

  for (final broken in [false, true]) {
    test('an unreadable key (broken: $broken) fails loudly and changes nothing', () async {
      await BastionChatStorage.setEncrypted(true, vault: vault);
      final before = await plain.read(a);
      BastionChatStorage.active = plain;
      vault.key = null;
      vault.broken = broken;
      expect(await BastionChatStorage.applySavedEncryption(vault: vault), contains('could not be read'));
      final store = BastionChatStorage.of(throw_());
      await expectLater(store.read(a), throwsStateError);
      await expectLater(store.write(a, '{}'), throwsStateError);
      expect(await plain.read(a), before);
    });
  }

  test('a wrong key cannot read, and archives cannot be swapped', () async {
    final one = EncryptedChatArchiveStore(plain, List.filled(32, 1));
    await one.write(a, 'hello');
    await expectLater(EncryptedChatArchiveStore(plain, List.filled(32, 2)).read(a), throwsA(anything));
    await plain.write(b, (await plain.read(a))!);
    await expectLater(one.read(b), throwsA(anything));
  });

  test('a phone that cannot store the key stays unencrypted', () async {
    final bad = _DroppingVault();
    expect(await BastionChatStorage.setEncrypted(true, vault: bad), contains('could not store'));
    expect(BastionChatStorage.encrypted, isFalse);
    expect(jsonDecode((await plain.read(a))!), jsonDecode(archive));
  });
}

class _DroppingVault extends FakeVault {
  @override
  Future<void> write(List<int> value) async {}
}

// The active store ignores the fallback preferences it is given.
Never _unused() => throw StateError('unused');
dynamic throw_() => _Unused();
class _Unused implements SharedPreferencesAsync {
  @override
  dynamic noSuchMethod(Invocation invocation) => _unused();
}
