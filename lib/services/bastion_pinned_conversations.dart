import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the set of pinned conversation keys across sessions.
class BastionPinnedConversations extends ChangeNotifier {
  static final instance = BastionPinnedConversations();

  static const _key = 'pinnedConversations';

  Set<String> _pinned = {};

  bool isPinned(String conversationKey) => _pinned.contains(conversationKey);

  Future<void> load() async {
    final p = SharedPreferencesAsync();
    final list = await p.getStringList(_key);
    _pinned = list?.toSet() ?? {};
    notifyListeners();
  }

  Future<void> pin(String conversationKey) async {
    if (_pinned.add(conversationKey)) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> unpin(String conversationKey) async {
    if (_pinned.remove(conversationKey)) {
      await _save();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final p = SharedPreferencesAsync();
    await p.setStringList(_key, _pinned.toList());
  }
}
