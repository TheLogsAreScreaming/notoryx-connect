import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'bastion_chat_encryption.dart';

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

  static const _encryptedPref = 'bastion.chat_encrypted';

  /// Whether chat history is currently being encrypted.
  static bool get encrypted => _active is EncryptedChatArchiveStore;

  /// At startup, turns encryption back on if it was on, and finishes any
  /// change that was interrupted. Returns a problem to show, or null.
  static Future<String?> applySavedEncryption({BastionKeyVault? vault}) async {
    try {
      if (await SharedPreferencesAsync().getBool(_encryptedPref) != true) return null;
    } catch (_) {
      return null;
    }
    final base = _active;
    if (base == null) return null;
    List<int>? key;
    try {
      key = await (vault ?? BastionSecureKeyVault()).read();
    } catch (_) {
      key = null;
    }
    if (key == null) {
      _active = const UnavailableChatArchiveStore();
      return migrationProblem = 'The key for your encrypted chat history could not be read. '
          'Your history is still on this phone and has not been changed.';
    }
    final store = EncryptedChatArchiveStore(base, key);
    _active = store;
    return migrationProblem = await _encryptAll(store);
  }

  /// Turns encryption on or off for all history. Returns a problem, or null.
  static Future<String?> setEncrypted(bool on, {BastionKeyVault? vault}) async {
    final safe = vault ?? BastionSecureKeyVault();
    final active = _active;
    try {
      if (on) {
        if (active is! SqliteChatArchiveStore) return 'The message database is not available on this phone.';
        final key = await (await AesGcm.with256bits().newSecretKey()).extractBytes();
        await safe.write(key);
        final saved = await safe.read();
        if (saved == null || base64Encode(saved) != base64Encode(key)) return 'This phone could not store the key safely.';
        await SharedPreferencesAsync().setBool(_encryptedPref, true);
        final store = EncryptedChatArchiveStore(active, key);
        _active = store;
        return await _encryptAll(store);
      }
      if (active is! EncryptedChatArchiveStore) return null;
      // Keep the key until every archive is confirmed readable without it.
      for (final name in await active.keys()) {
        final plain = await active.read(name);
        if (plain != null) await active.inner.write(name, plain);
      }
      await SharedPreferencesAsync().setBool(_encryptedPref, false);
      _active = active.inner;
      await safe.delete();
      return null;
    } catch (error) {
      return 'Chat history encryption could not be changed ($error). Your messages were kept.';
    }
  }

  /// Encrypts what isn't yet, confirming each archive before moving on, then
  /// clears the old plain text out of the database file.
  static Future<String?> _encryptAll(EncryptedChatArchiveStore store) async {
    var failed = 0, changed = 0;
    for (final name in await store.keys()) {
      final stored = await store.inner.read(name);
      if (stored == null || EncryptedChatArchiveStore.isEncrypted(stored)) continue;
      try {
        await store.write(name, stored);
        if (await store.read(name) == stored) {
          changed++;
        } else {
          failed++;
          await store.inner.write(name, stored);
        }
      } catch (_) {
        failed++;
        await store.inner.write(name, stored);
      }
    }
    final inner = store.inner;
    if (changed > 0 && inner is SqliteChatArchiveStore) await inner.compact();
    return failed == 0 ? null : '$failed chat archive${failed == 1 ? '' : 's'} could not be encrypted and stayed as ${failed == 1 ? 'it was' : 'they were'}.';
  }

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

  /// Rebuilds the file so deleted rows no longer sit in free pages.
  Future<void> compact() => _db.execute('VACUUM');

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
