import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Names you give nodes on this phone only. A local name replaces the
/// node's own name everywhere it's shown (lists, chats, map, alerts) and
/// is never sent to the node or the mesh. The node's own name stays
/// visible on its detail page.
///
/// Saved under the `bastion.` prefix, so phone backups include it.
class BastionLocalNames extends ChangeNotifier {
  BastionLocalNames._();

  /// The app-wide store. Display names read it synchronously.
  static final BastionLocalNames instance = BastionLocalNames._();

  static const prefsKey = 'bastion.local_names_v1';

  /// Longest local name kept.
  static const maxLength = 40;

  final Map<int, String> _names = {};
  SharedPreferencesAsync? _prefs;

  /// The local name for node [num], or null when it has none.
  String? nameFor(int num) => _names[num];

  bool get isEmpty => _names.isEmpty;

  Future<void> load({SharedPreferencesAsync? prefs}) async {
    try {
      _prefs = prefs ?? SharedPreferencesAsync();
      final raw = await _prefs!.getString(prefsKey);
      _names.clear();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((k, v) {
            final num = int.tryParse('$k');
            if (num != null && v is String && v.trim().isNotEmpty) {
              _names[num] = v.trim();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Local names: could not load ($e)');
    }
    notifyListeners();
  }

  /// Sets node [num]'s local name; an empty [name] removes it.
  Future<void> set(int num, String name) async {
    var clean = name.replaceAll(RegExp(r'[\r\n\t]'), ' ').trim();
    if (clean.length > maxLength) clean = clean.substring(0, maxLength);
    if (clean.isEmpty) {
      if (_names.remove(num) == null) return;
    } else {
      if (_names[num] == clean) return;
      _names[num] = clean;
    }
    notifyListeners();
    try {
      await (_prefs ?? SharedPreferencesAsync()).setString(
        prefsKey,
        jsonEncode({for (final e in _names.entries) '${e.key}': e.value}),
      );
    } catch (e) {
      debugPrint('Local names: could not save ($e)');
    }
  }

  @visibleForTesting
  void debugReset() => _names.clear();
}
