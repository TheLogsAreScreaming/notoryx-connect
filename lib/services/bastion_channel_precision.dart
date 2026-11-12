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
}
