import 'dart:math' as math;

/// Spots node names made to look like a trusted node's name: the same name
/// on a different radio, look-alike letters (Cyrillic "а" for "a", "0" for
/// "o"), or one character changed. Anyone can set any name, so this is a
/// hint to check, never proof.
abstract final class BastionLookalike {
  static const _homoglyphs = {
    'а': 'a', 'е': 'e', 'о': 'o', 'р': 'p', 'с': 'c', 'у': 'y', 'х': 'x',
    'і': 'i', 'в': 'b', 'м': 'm', 'н': 'h', 'т': 't', 'к': 'k', 'ј': 'j', 'ѕ': 's', 'ԁ': 'd', 'ɡ': 'g', 'һ': 'h', 'κ': 'k',
    'ο': 'o', 'ν': 'v', 'α': 'a', 'ρ': 'p', 'τ': 't', 'ι': 'i',
    '0': 'o', '1': 'l', 'i': 'l', '|': 'l', '3': 'e', '4': 'a', '5': 's',
    '7': 't', '8': 'b', '\$': 's', '@': 'a',
  };

  /// [name] lower-cased, look-alike characters folded together, and
  /// spaces, punctuation and symbols removed.
  static String fold(String name) {
    final b = StringBuffer();
    for (final rune in name.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      final mapped = _homoglyphs[ch] ?? ch;
      if (RegExp(r'[a-z0-9]', unicode: true).hasMatch(mapped) ||
          (rune > 0x7f && RegExp(r'\p{L}', unicode: true).hasMatch(mapped))) {
        b.write(mapped);
      }
    }
    return b.toString().replaceAll('rn', 'm').replaceAll('vv', 'w');
  }

  /// Whether [candidate] looks like [trusted] without being the same text
  /// on purpose-built radios. Identical names count: two radios with one
  /// name is how impersonation usually starts.
  static bool looksLike(String candidate, String trusted) {
    final a = fold(candidate), b = fold(trusted);
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    // "Relay 2" next to "Relay 1": numbered units of one group are normal.
    if (_unitNumbersOnly(candidate, trusted)) return false;
    if (math.min(a.length, b.length) < 5) return false;
    return _withinOneEdit(a, b);
  }

  /// The trusted node that [num] imitates, or null. [trusted] are
  /// favourites and trip contacts; a node never imitates itself.
  static int? imitates(int num, String name, Map<int, String> trusted) {
    if (trusted.containsKey(num)) return null;
    for (final e in trusted.entries) {
      if (looksLike(name, e.value)) return e.key;
    }
    return null;
  }

  static bool _unitNumbersOnly(String a, String b) {
    String plain(String s) => s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
    final pa = plain(a), pb = plain(b);
    final base = RegExp(r'^(.*?)(\d*)$');
    final ma = base.firstMatch(pa)!, mb = base.firstMatch(pb)!;
    return ma.group(1) == mb.group(1) && ma.group(1)!.isNotEmpty && ma.group(2) != mb.group(2);
  }

  static bool _withinOneEdit(String a, String b) {
    if ((a.length - b.length).abs() > 1) return false;
    var i = 0, j = 0, edits = 0;
    while (i < a.length && j < b.length) {
      if (a[i] == b[j]) {
        i++;
        j++;
        continue;
      }
      if (++edits > 1) return false;
      if (a.length > b.length) {
        i++;
      } else if (b.length > a.length) {
        j++;
      } else {
        i++;
        j++;
      }
    }
    return edits + (a.length - i) + (b.length - j) <= 1;
  }
}
