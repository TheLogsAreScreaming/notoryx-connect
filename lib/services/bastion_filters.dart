import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ignored and muted nodes and word filters, shared across radios.
///
/// Ignored nodes are hidden from node lists, the map and chats, and never
/// notify or get bot replies. Muted nodes still show but never notify.
/// Messages with a filtered word are kept, only hidden, unless
/// [showFiltered] is on. Nothing is deleted, so every choice is reversible.
class BastionFilters extends ChangeNotifier {
  BastionFilters({SharedPreferencesAsync? preferences}) : _preferences = preferences;

  static const key = 'bastion.filters.v1';
  static const maxWords = 50;

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();
  final Set<int> _ignored = {};
  final Set<int> _muted = {};
  final List<String> _words = [];
  List<RegExp> _patterns = const [];
  bool _showFiltered = false;
  bool _loadFailed = false;

  /// Set when a change could not be saved; it still applies until restart.
  String? problem;

  Set<int> get ignored => Set.unmodifiable(_ignored);
  Set<int> get muted => Set.unmodifiable(_muted);
  List<String> get words => List.unmodifiable(_words);
  bool get showFiltered => _showFiltered;

  bool isIgnored(int node) => _ignored.contains(node);

  /// Whether messages from [node] should never notify or be read aloud.
  bool isSilenced(int node) => _ignored.contains(node) || _muted.contains(node);

  /// Whether [text] contains a filtered word (whole word, any case).
  bool matchesWord(String text) => _patterns.any((p) => p.hasMatch(text));

  Future<void> load() async {
    try {
      final raw = await _store.getString(key);
      if (raw != null) {
        final json = jsonDecode(raw) as Map<String, Object?>;
        _ignored.addAll([for (final n in json['ignored'] as List? ?? const []) n as int]);
        _muted.addAll([for (final n in json['muted'] as List? ?? const []) n as int]);
        _words.addAll([for (final w in json['words'] as List? ?? const []) w as String]);
        _showFiltered = json['showFiltered'] == true;
        _compile();
      }
    } on FormatException {
      // Damaged filters are replaced by the next change.
    } on TypeError {
      // Same: keep what parsed, replace on the next change.
    } catch (_) {
      _loadFailed = true;
      problem = 'Filters could not be read from phone storage; changes apply until the app restarts.';
    }
    notifyListeners();
  }

  void _compile() {
    _patterns = [
      for (final w in _words)
        RegExp('(^|[^\\p{L}\\p{N}])${RegExp.escape(w)}(\$|[^\\p{L}\\p{N}])',
            caseSensitive: false, unicode: true),
    ];
  }

  Future<void> setIgnored(int node, bool value) =>
      _change(() => value ? _ignored.add(node) : _ignored.remove(node));

  Future<void> setMuted(int node, bool value) =>
      _change(() => value ? _muted.add(node) : _muted.remove(node));

  Future<void> setShowFiltered(bool value) => _change(() => _showFiltered = value);

  /// Adds [word]; returns why not when it can't be added.
  Future<String?> addWord(String word) async {
    final w = word.trim();
    if (w.isEmpty) return 'Enter a word or phrase.';
    if (_words.any((x) => x.toLowerCase() == w.toLowerCase())) return 'That word is already filtered.';
    if (_words.length >= maxWords) return 'You can filter up to $maxWords words.';
    await _change(() {
      _words.add(w);
      _compile();
    });
    return null;
  }

  Future<void> removeWord(String word) => _change(() {
        _words.remove(word);
        _compile();
      });

  Future<void> _change(void Function() apply) async {
    apply();
    notifyListeners();
    if (_loadFailed) return;
    try {
      await _store.setString(key, jsonEncode({
        'ignored': _ignored.toList()..sort(),
        'muted': _muted.toList()..sort(),
        'words': _words,
        'showFiltered': _showFiltered,
      }));
      if (problem != null) {
        problem = null;
        notifyListeners();
      }
    } catch (_) {
      problem = 'Filter changes apply now, but could not be saved.';
      notifyListeners();
    }
  }
}
