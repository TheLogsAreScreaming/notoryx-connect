import 'dart:math' as math;

/// Per-channel position precision, the radio's own setting.
///
/// Meshtastic keeps this many leading bits of each coordinate before sending
/// a position on the channel. 0 sends no position; 32 sends it exactly.
abstract final class BastionChannelPrecision {
  static const none = 0;
  static const exact = 32;

  /// Choices offered, with the approximate area a position is rounded to, in
  /// metres, from the Meshtastic documentation.
  static const choices = <int, int>{
    none: 0,
    10: 23300,
    11: 11700,
    12: 5800,
    13: 2900,
    14: 1500,
    15: 729,
    16: 364,
    17: 182,
    18: 91,
    19: 45,
    exact: 0,
  };

  /// Roughly how far a position sent with [bits] of precision may be from
  /// the real spot, in metres, or null when it is exact enough not to
  /// matter (under 30 m) or the precision is unknown (null, 0 or 32+).
  /// Each bit fewer doubles the box the position is rounded into; 10 bits
  /// is about 23 km.
  static double? uncertaintyMeters(int? bits) {
    if (bits == null || bits <= none || bits >= exact) return null;
    final meters = 23300.0 * math.pow(2, 10 - bits);
    return meters < 30 ? null : meters;
  }
}
