import 'dart:io';

import 'package:bastion/services/bastion_chat_store.dart';
import 'package:bastion/services/bastion_sqlite_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory dir;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    dir = Directory.systemTemp.createTempSync('notoryx-db-');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('a sound database opens as is', () async {
    final path = '${dir.path}/chats.db';
    final first = await SqliteChatArchiveStore.open(databaseFactoryFfi, path);
    await first.write('k', '{"messages":[],"pending":[]}');
    await first.close();

    final checked = await openCheckedDatabase(
      factory: databaseFactoryFfi,
      path: path,
      open: SqliteChatArchiveStore.open,
      databaseOf: (s) => s.database,
    );
    expect(checked.setAsidePath, isNull);
    expect(await checked.value.keys(), {'k'});
    await checked.value.close();
  });

  test('a damaged file is moved aside, kept, and a fresh one starts', () async {
    final path = '${dir.path}/chats.db';
    File(path).writeAsBytesSync(List.generate(4096, (i) => (i * 37) & 0xFF));

    final checked = await openCheckedDatabase(
      factory: databaseFactoryFfi,
      path: path,
      open: SqliteChatArchiveStore.open,
      databaseOf: (s) => s.database,
      clock: () => DateTime.fromMillisecondsSinceEpoch(1234),
    );
    expect(checked.setAsidePath, '$path.damaged-1234');
    expect(File('$path.damaged-1234').existsSync(), isTrue);
    expect(await checked.value.keys(), isEmpty);
    await checked.value.write('k', 'v');
    expect(await checked.value.read('k'), 'v');
    await checked.value.close();
  });

  test('chat storage says so when it had to start over', () async {
    final path = '${dir.path}/chats.db';
    File(path).writeAsStringSync('not a database at all' * 200);
    await BastionChatStorage.useSqlite(factory: databaseFactoryFfi, path: path);
    expect(BastionChatStorage.migrationProblem, contains('damaged'));
    expect(
      dir.listSync().whereType<File>().any((f) => f.path.contains('.damaged-')),
      isTrue,
    );
  });
}
