import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'bastion_message_archive.dart';
import 'bastion_nodedex.dart';
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

  /// The radio's long name when one of the NodeDex lists knows it.
  final String? name;

  /// Saved messages, NodeDex nodes and nodes with a trail.
  final int messages;
  final int nodes;
  final int trails;

  String get id => '!${radio.toRadixString(16).padLeft(8, '0')}';
  String get label => name == null ? id : '$name ($id)';
}

/// Messages, NodeDex history and trails are stored per radio. This lists
/// them and helps hand a lost or replaced radio's data to the new one.
class BastionRadioData {
  BastionRadioData({SharedPreferencesAsync? preferences})
      : _preferences = preferences;

  /// Where the receiving radio's own data is copied before a move.
  static const beforeMoveSuffix = '.before-move';

  static final _radioKey = RegExp(
      r'^bastion\.(?:comms\.archive\.v2|nodedex\.v2|trails\.v1)\.radio\.([0-9a-f]{8})$');

  /// Every key holding [radio]'s data.
  static List<String> keysOf(int radio) => [
        BastionMessageArchive.radioKey(radio),
        BastionNodeDex.radioKey(radio),
        BastionTrails.key(radio),
      ];

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();

  /// Radios with data on this phone, by node number.
  Future<List<StoredRadio>> list() async {
    final radios = <int>{
      for (final key in await _store.getKeys())
        if (_radioKey.firstMatch(key) case final match?)
          int.parse(match[1]!, radix: 16),
    };
    final dex = {for (final r in radios) r: _decodeList(await _read(BastionNodeDex.radioKey(r)))};
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
    for (final key in keysOf(radio)) {
      final raw = await _store.getString(key);
      if (raw != null) await _store.setString('$key$beforeMoveSuffix', raw);
    }
  }

  /// Deletes [radio]'s data once it has been moved.
  Future<void> remove(int radio) async {
    for (final key in keysOf(radio)) {
      await _store.remove(key);
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _store.getString(key);
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
