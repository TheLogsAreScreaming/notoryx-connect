import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// What happened when a node's key was checked against the remembered one.
enum KeyCheck { firstSeen, same, changed }

/// Remembers each node's public key the first time it is seen, and flags
/// when a node later shows a different one, which can mean the radio was
/// reset or replaced, or that someone is impersonating it.
///
/// Keys are public, so storing them is not sensitive. Unreadable storage is
/// never overwritten.
class BastionNodeKeys {
  BastionNodeKeys({SharedPreferencesAsync? preferences}) : _preferences = preferences;

  static const key = 'bastion.node_keys.v1';

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();
  final Map<int, String> _known = {};
  final Map<int, String> _changed = {};
  bool _loadFailed = false;

  /// The remembered key of [num], base64.
  String? knownKey(int num) => _known[num];

  /// The new key [num] is showing, when it differs from the remembered one.
  String? changedKey(int num) => _changed[num];

  bool hasChanged(int num) => _changed.containsKey(num);

  /// Nodes whose key changed and hasn't been accepted.
  Set<int> get changedNodes => _changed.keys.toSet();

  Future<void> load() async {
    _known.clear();
    _changed.clear();
    try {
      final raw = await _store.getString(key);
      if (raw == null) return;
      final json = jsonDecode(raw);
      if (json is! Map) return;
      for (final MapEntry(:key, :value) in ((json['known'] as Map?) ?? const {}).entries) {
        if (int.tryParse('$key') case final n? when value is String) _known[n] = value;
      }
      for (final MapEntry(:key, :value) in ((json['changed'] as Map?) ?? const {}).entries) {
        if (int.tryParse('$key') case final n? when value is String) _changed[n] = value;
      }
    } on FormatException {
      // Damaged records are rebuilt as nodes are heard again.
    } catch (_) {
      _loadFailed = true;
    }
  }

  /// Compares [publicKey] with what is remembered for [num].
  Future<KeyCheck> check(int num, Uint8List publicKey) async {
    final shown = base64Encode(publicKey);
    final known = _known[num];
    if (known == null) {
      _known[num] = shown;
      await _save();
      return KeyCheck.firstSeen;
    }
    if (known == shown) {
      // Back to the remembered key: nothing to warn about any more.
      if (_changed.remove(num) != null) await _save();
      return KeyCheck.same;
    }
    final already = _changed[num] == shown;
    _changed[num] = shown;
    if (!already) await _save();
    return KeyCheck.changed;
  }

  /// Accepts the new key of [num] as its key from now on.
  Future<void> trust(int num) async {
    final next = _changed.remove(num);
    if (next == null) return;
    _known[num] = next;
    await _save();
  }

  Future<void> _save() async {
    if (_loadFailed) return;
    try {
      await _store.setString(key, jsonEncode({
        'known': {for (final e in _known.entries) '${e.key}': e.value},
        'changed': {for (final e in _changed.entries) '${e.key}': e.value},
      }));
    } catch (_) {
      // Warnings still show this session.
    }
  }

  /// A short code people can read aloud to compare keys, e.g. "3F9A 0C21 77B4 E812".
  static String safetyCode(String base64Key) {
    final bytes = base64Decode(base64Key);
    final hex = [for (final b in bytes.take(8)) b.toRadixString(16).padLeft(2, '0').toUpperCase()].join();
    return [for (var i = 0; i < hex.length; i += 4) hex.substring(i, i + 4)].join(' ');
  }
}
