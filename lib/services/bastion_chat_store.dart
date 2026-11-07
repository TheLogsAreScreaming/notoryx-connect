import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Where chat archives (message history and offline queues) are kept.
///
/// Archives are addressed by the same keys they always had
/// (`bastion.comms.archive.…`), and read and written as the same JSON, so
/// backups, Radio data and history migration work unchanged whichever
/// store is in use.
abstract interface class ChatArchiveStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
  Future<Set<String>> keys();
}

/// Chooses the chat store. The app switches to SQLite at startup; until
/// then (and in tests) archives stay in phone preferences.
abstract final class BastionChatStorage {
  /// Every chat archive key starts with this.
  static const prefix = 'bastion.comms.archive.';

  static ChatArchiveStore? _active;

  /// A problem from moving archives into the database, for the person.
  static String? migrationProblem;

  /// The store to use, given the preferences a caller would otherwise use.
  static ChatArchiveStore of(SharedPreferencesAsync preferences) =>
      _active ?? PrefsChatArchiveStore(preferences);

  static bool isChatKey(String key) => key.startsWith(prefix);

  @visibleForTesting
  static set active(ChatArchiveStore? store) => _active = store;

  /// Opens the SQLite store, moves archives out of preferences into it and
  /// makes it the active store. On failure archives stay in preferences.
  /// Returns a problem to show the person, or null.
  static Future<String?> useSqlite({DatabaseFactory? factory, String? path}) async {
    try {
      final db = factory ?? databaseFactory;
      final file = path ?? '${await db.getDatabasesPath()}/notoryx_chats.db';
      final store = await SqliteChatArchiveStore.open(db, file);
      final problem = await store.migrateFrom(SharedPreferencesAsync());
      _active = store;
      return migrationProblem = problem;
    } catch (error) {
      debugPrint('Chat database unavailable, using preferences: $error');
      return null;
    }
  }
}

/// Archives as single JSON strings in phone preferences (the old layout).
class PrefsChatArchiveStore implements ChatArchiveStore {
  PrefsChatArchiveStore(this._prefs);
  final SharedPreferencesAsync _prefs;

  @override
  Future<String?> read(String key) => _prefs.getString(key);
  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);
  @override
  Future<void> remove(String key) => _prefs.remove(key);
  @override
  Future<Set<String>> keys() async =>
      {for (final k in await _prefs.getKeys()) if (BastionChatStorage.isChatKey(k)) k};
}

/// Archives in an SQLite database: one row per message and per queued
/// message, so large histories don't sit in one preferences string.
///
/// An archive that isn't the usual `{messages, pending}` shape (for
/// example a copy of unreadable data) is kept verbatim as text.
class SqliteChatArchiveStore implements ChatArchiveStore {
  SqliteChatArchiveStore._(this._db);
  final Database _db;

  static const schemaVersion = 1;

  static Future<SqliteChatArchiveStore> open(DatabaseFactory factory, String path) async {
    final db = await factory.openDatabase(path, options: OpenDatabaseOptions(
      version: schemaVersion,
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE archives (key TEXT PRIMARY KEY, raw TEXT)');
        await db.execute('CREATE TABLE messages (archive TEXT NOT NULL, seq INTEGER NOT NULL, '
            'packet_id INTEGER, from_node INTEGER, ts TEXT, body TEXT NOT NULL, PRIMARY KEY (archive, seq))');
        await db.execute('CREATE INDEX messages_ts ON messages (archive, ts)');
        await db.execute('CREATE TABLE pending (archive TEXT NOT NULL, seq INTEGER NOT NULL, '
            'body TEXT NOT NULL, PRIMARY KEY (archive, seq))');
      },
    ));
    return SqliteChatArchiveStore._(db);
  }

  Future<void> close() => _db.close();

  @override
  Future<Set<String>> keys() async =>
      {for (final row in await _db.query('archives', columns: ['key'])) row['key']! as String};

  @override
  Future<String?> read(String key) async {
    final rows = await _db.query('archives', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    final raw = rows.single['raw'] as String?;
    if (raw != null) return raw;
    final messages = await _db.query('messages', columns: ['body'], where: 'archive = ?',
        whereArgs: [key], orderBy: 'seq');
    final pending = await _db.query('pending', columns: ['body'], where: 'archive = ?',
        whereArgs: [key], orderBy: 'seq');
    // Bodies are stored JSON, so they are joined without re-encoding.
    return '{"messages":[${messages.map((r) => r['body']).join(',')}],'
        '"pending":[${pending.map((r) => r['body']).join(',')}]}';
  }

  @override
  Future<void> write(String key, String value) async {
    Object? root;
    try {
      root = jsonDecode(value);
    } on FormatException {
      root = null;
    }
    final messages = root is Map ? root['messages'] : null;
    final pending = root is Map ? root['pending'] : null;
    // Only the exact usual shape is split into rows, so reading it back
    // gives the same data; anything else is kept verbatim.
    final structured = root is Map && root.length == 2 && messages is List && pending is List;
    await _db.transaction((txn) async {
      await txn.delete('messages', where: 'archive = ?', whereArgs: [key]);
      await txn.delete('pending', where: 'archive = ?', whereArgs: [key]);
      await txn.insert('archives', {'key': key, 'raw': structured ? null : value},
          conflictAlgorithm: ConflictAlgorithm.replace);
      if (!structured) return;
      final batch = txn.batch();
      for (final (i, m) in messages.indexed) {
        batch.insert('messages', {
          'archive': key,
          'seq': i,
          'packet_id': m is Map ? m['packetId'] : null,
          'from_node': m is Map ? m['from'] : null,
          'ts': m is Map ? m['timestamp'] : null,
          'body': jsonEncode(m),
        });
      }
      for (final (i, p) in pending.indexed) {
        batch.insert('pending', {'archive': key, 'seq': i, 'body': jsonEncode(p)});
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> remove(String key) => _db.transaction((txn) async {
        await txn.delete('messages', where: 'archive = ?', whereArgs: [key]);
        await txn.delete('pending', where: 'archive = ?', whereArgs: [key]);
        await txn.delete('archives', where: 'key = ?', whereArgs: [key]);
      });

  /// Moves every chat archive out of [prefs]. Each one is written here,
  /// read back and compared before the preferences copy is removed; any
  /// archive that doesn't match stays in preferences untouched (and the
  /// copy here is dropped). Returns a problem to report, or null.
  Future<String?> migrateFrom(SharedPreferencesAsync prefs) async {
    final Set<String> keys;
    try {
      keys = {for (final k in await prefs.getKeys()) if (BastionChatStorage.isChatKey(k)) k};
    } catch (error) {
      return 'Saved messages could not be checked for moving to the new message database ($error).';
    }
    var failed = 0;
    for (final key in keys) {
      try {
        final raw = await prefs.getString(key);
        if (raw == null) continue;
        if (await read(key) != null) {
          // Already moved on an earlier launch that stopped before cleanup.
          if (_same(await read(key), raw)) await prefs.remove(key);
          continue;
        }
        await write(key, raw);
        if (_same(await read(key), raw)) {
          await prefs.remove(key);
        } else {
          await remove(key);
          failed++;
        }
      } catch (_) {
        failed++;
      }
    }
    return failed == 0
        ? null
        : '$failed saved message archive${failed == 1 ? '' : 's'} could not be moved to the new message '
            'database and ${failed == 1 ? 'was' : 'were'} left where ${failed == 1 ? 'it was' : 'they were'}.';
  }

  /// Whether two archive strings hold the same data.
  static bool _same(String? a, String b) {
    if (a == null) return false;
    if (a == b) return true;
    try {
      return _canonical(jsonDecode(a)) == _canonical(jsonDecode(b));
    } on FormatException {
      return false;
    }
  }

  static String _canonical(Object? v) => switch (v) {
        Map() => '{${(v.keys.map((k) => '$k').toList()..sort()).map((k) => '${jsonEncode(k)}:${_canonical(v[k])}').join(',')}}',
        List() => '[${v.map(_canonical).join(',')}]',
        _ => jsonEncode(v),
      };
}
