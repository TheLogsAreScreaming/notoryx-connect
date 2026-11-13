import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'bastion_chat_store.dart';
import 'bastion_message_archive.dart';
import 'bastion_node_vault.dart';
import 'bastion_telemetry_history.dart';
import 'bastion_trails.dart';

/// What this phone keeps for one radio.
class StoredRadio {
  const StoredRadio({
    required this.radio,
    required this.name,
    required this.messages,
    required this.nodes,
    required this.trails,
  });

  /// The radio's node number.
  final int radio;

  /// The radio's long name when one of the NodeVault lists knows it.
  final String? name;

  /// Saved messages, NodeVault nodes and nodes with a trail.
  final int messages;
  final int nodes;
  final int trails;

  String get id => '!${radio.toRadixString(16).padLeft(8, '0')}';
  String get label => name == null ? id : '$name ($id)';
}

/// Messages, NodeVault history, trails and telemetry are stored per radio. This lists
/// them and helps hand a lost or replaced radio's data to the new one.
class BastionRadioData {
  BastionRadioData({SharedPreferencesAsync? preferences})
      : _preferences = preferences;

  /// Where the receiving radio's own data is copied before a move.
  static const beforeMoveSuffix = '.before-move';

  static final _radioKey = RegExp(
      r'^bastion\.(?:comms\.archive\.v2|nodevault\.v2|trails\.v1|telemetry\.v1)\.radio\.([0-9a-f]{8})$');

  /// Every key holding [radio]'s data.
  static List<String> keysOf(int radio) => [
        BastionMessageArchive.radioKey(radio),
        BastionNodeVault.radioKey(radio),
        BastionTrails.key(radio),
        BastionTelemetryHistory.key(radio),
      ];

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();
  ChatArchiveStore get _chats => BastionChatStorage.of(_store);

  Future<String?> _get(String key) =>
      BastionChatStorage.isChatKey(key) ? _chats.read(key) : _store.getString(key);
  Future<void> _set(String key, String value) =>
      BastionChatStorage.isChatKey(key) ? _chats.write(key, value) : _store.setString(key, value);
  Future<void> _remove(String key) =>
      BastionChatStorage.isChatKey(key) ? _chats.remove(key) : _store.remove(key);

  /// Radios with data on this phone, by node number.
  Future<List<StoredRadio>> list() async {
    await BastionNodeVault.migrateStoredKeys(_store);
    final radios = <int>{
      for (final key in {...await _store.getKeys(), ...await _chats.keys()})
        if (_radioKey.firstMatch(key) case final match?)
          int.parse(match[1]!, radix: 16),
    };
    final dex = {for (final r in radios) r: _decodeList(await _read(BastionNodeVault.radioKey(r)))};
    final names = <int, String>{};
    for (final records in dex.values) {
      for (final record in records) {
        if (record is! Map) continue;
        final num = record['num'];
        final name = record['longName'];
        if (num is int && radios.contains(num) && name is String && name.isNotEmpty) {
          names[num] = name;
        }
      }
    }
    return [
      for (final r in radios.toList()..sort())
        StoredRadio(
          radio: r,
          name: names[r],
          messages: _messageCount(await _read(BastionMessageArchive.radioKey(r))),
          nodes: dex[r]!.length,
          trails: _mapLength(await _read(BastionTrails.key(r))),
        ),
    ];
  }

  /// Copies [radio]'s data aside before another radio's is merged into it.
  Future<void> keepBeforeMove(int radio) async {
    await BastionNodeVault.migrateStoredKeys(_store);
    for (final key in keysOf(radio)) {
      final raw = await _get(key);
      if (raw != null) await _set('$key$beforeMoveSuffix', raw);
    }
  }

  /// Deletes [radio]'s data once it has been moved.
  Future<void> remove(int radio) async {
    await BastionNodeVault.migrateStoredKeys(_store);
    for (final key in keysOf(radio)) {
      await _remove(key);
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _get(key);
    } catch (_) {
      return null;
    }
  }

  static Object? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  static List<Object?> _decodeList(String? raw) =>
      _decode(raw) is List ? _decode(raw)! as List<Object?> : const [];

  static int _messageCount(String? raw) {
    final root = _decode(raw);
    return root is Map && root['messages'] is List ? (root['messages'] as List).length : 0;
  }

  static int _mapLength(String? raw) {
    final root = _decode(raw);
    return root is Map ? root.length : 0;
  }
}
