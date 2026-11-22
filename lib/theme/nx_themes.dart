import 'package:flutter/material.dart';

/// The Okabe-Ito categorical palette (Okabe & Ito, 2002), whose colors stay
/// distinct under the common forms of color blindness. The Okabe-Ito theme
/// is built from it.
abstract final class OkabeIto {
  static const orange = Color(0xFFE69F00);
  static const skyBlue = Color(0xFF56B4E9);
  static const bluishGreen = Color(0xFF009E73);
  static const yellow = Color(0xFFF0E442);
  static const blue = Color(0xFF0072B2);
  static const vermillion = Color(0xFFD55E00);
  static const reddishPurple = Color(0xFFCC79A7);
  static const black = Color(0xFF000000);
}

/// Every color a theme defines; the app's single set of color tokens.
/// `NotoryxTheme.fromPalette` turns one into the Material color scheme and
/// status colors, so every screen follows the chosen theme.
///
/// BLACKOUT, the brand look, plus four themes shared with NOTORYX Core.
class BastionPalette {
  final Brightness brightness;

  // Surfaces, page first: page, raised, cards, elevated, highest.
  final Color bg, bg1, bg2, bg3, bg4;
  // Lines, faint to strong.
  final Color line, line2, line3;
  // Text, strongest to faintest.
  final Color ink, ink2, ink3, ink4;
  // Signal quality (SNR) colors.
  final Color signal, signalDim;
  final Color warn, warnDim;
  // Errors, SOS and emergencies. Always a red or vermillion.
  final Color alert;
  final Color accent, accentDim, onAccent;
  // A second and third hue, so a theme isn't one accent on grey. Used for
  // icons, chips, highlights and the background glow; never for status.
  final Color secondary, tertiary;
  final Color magenta;
  // Your own chat bubbles.
  final Color me, meBorder, meInk;
  // Filled containers for the color scheme.
  final Color primaryContainer, secondaryContainer, tertiaryContainer;

  const BastionPalette({
    required this.brightness,
    required this.bg,
    required this.bg1,
    required this.bg2,
    required this.bg3,
    required this.bg4,
    required this.line,
    required this.line2,
    required this.line3,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.signal,
    required this.signalDim,
    required this.warn,
    required this.warnDim,
    required this.alert,
    required this.accent,
    required this.accentDim,
    required this.onAccent,
    required this.secondary,
    required this.tertiary,
    required this.magenta,
    required this.me,
    required this.meBorder,
    required this.meInk,
    required this.primaryContainer,
    required this.secondaryContainer,
    required this.tertiaryContainer,
  });

  /// A full palette from a theme's few defining colors.
  ///
  /// Surfaces and lines step from [bg] toward [surface]; secondary text
  /// sits between [ink] and [muted]. Each theme still picks its own status
  /// colors and containers, since those carry meaning.
  factory BastionPalette.derive({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color ink,
    required Color muted,
    required Color accent,
    required Color onAccent,
    required Color secondary,
    required Color tertiary,
    required Color signal,
    required Color warn,
    required Color alert,
    required Color me,
    required Color meInk,
    required Color primaryContainer,
    required Color secondaryContainer,
    required Color tertiaryContainer,
    Color? accentDim,
    Color? magenta,
    Color? meBorder,
    Color? faint,
  }) {
    Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
    return BastionPalette(
      brightness: brightness,
      bg: bg,
      bg1: mix(bg, surface, 0.25),
      bg2: mix(bg, surface, 0.5),
      bg3: surface,
      bg4: mix(surface, ink, 0.08),
      line: mix(bg, surface, 0.9),
      line2: mix(surface, ink, 0.16),
      line3: mix(surface, ink, 0.32),
      ink: ink,
      ink2: mix(ink, muted, 0.45),
      ink3: muted,
      ink4: faint ?? mix(muted, bg, 0.12),
      signal: signal,
      signalDim: mix(signal, bg, 0.3),
      warn: warn,
      warnDim: mix(warn, bg, 0.3),
      alert: alert,
      accent: accent,
      accentDim: accentDim ?? mix(accent, bg, 0.3),
      onAccent: onAccent,
      secondary: secondary,
      tertiary: tertiary,
      magenta: magenta ?? tertiary,
      me: me,
      meBorder: meBorder ?? accent,
      meInk: meInk,
      primaryContainer: primaryContainer,
      secondaryContainer: secondaryContainer,
      tertiaryContainer: tertiaryContainer,
    );
  }

  /// The theme's hues in order, for giving neighbouring icons or groups
  /// their own color. Pick by index with [hue].
  List<Color> get spectrum => [accent, secondary, tertiary, magenta, signal];

  /// The [spectrum] color for item [index], repeating.
  Color hue(int index) => spectrum[index % spectrum.length];

  Color get warnBg => warn.withAlpha(0x1F);
  Color get warnLine => warn.withAlpha(0x66);
  Color get alertBg => alert.withAlpha(0x1F);
  Color get alertLine => alert.withAlpha(0x66);
  Color get accentBg => accent.withAlpha(0x29);
  Color get accentLine => accent.withAlpha(0x80);
  Color get magentaBg => magenta.withAlpha(0x1C);
  Color get magentaLine => magenta.withAlpha(0x47);
}

/// The themes offered in Settings, in display order.
enum BastionTheme {
  blackout('blackout', 'BLACKOUT'),
  blaze('blaze', 'Blaze'),
  bareBeauty('bare_beauty', 'Bare Beauty'),
  okabeIto('okabe_ito', 'Okabe-Ito'),
  nightOps('night_ops', 'Night Ops');

  const BastionTheme(this.id, this.label);

  /// The stored settings value.
  final String id;

  /// The theme's name, the same in every language.
  final String label;

  /// The default, and what any unknown or removed theme id opens as.
  static const fallback = BastionTheme.blackout;

  /// This theme's palette.
  BastionPalette get palette => switch (this) {
    blackout => _blackout,
    blaze => _blaze,
    bareBeauty => _bareBeauty,
    okabeIto => _okabeIto,
    nightOps => _nightOps,
  };

  /// Connect's earlier light/dark choices and the theme each now opens as.
  /// 'system' becomes Bare Beauty with Blaze in dark mode; see
  /// BastionPreferences.load.
  static const Map<String, BastionTheme> legacyIds = {'dark': blaze, 'light': bareBeauty, 'system': bareBeauty};

  /// Themes that were removed. Each opens as [fallback]; listed so the
  /// fallback is deliberate, not an accident of an unknown id.
  static const removedIds = {'neon_anarchy', 'tactical', 'pink_overload', 'seasonal'};

  static BastionTheme fromId(String? id) {
    final legacy = legacyIds[id];
    if (legacy != null) return legacy;
    for (final t in values) {
      if (t.id == id) return t;
    }
    return fallback;
  }
}

/// The theme id to show: [darkModeTheme] while the device is in dark mode
/// and one is set, otherwise [appTheme].
String activeThemeId({
  required String appTheme,
  required String darkModeTheme,
  required Brightness platformBrightness,
}) => darkModeTheme.isNotEmpty && platformBrightness == Brightness.dark ? darkModeTheme : appTheme;

/// The palette for the saved theme [themeId].
BastionPalette resolveThemePalette(String? themeId) => BastionTheme.fromId(themeId).palette;

const _dark = Brightness.dark;
const _light = Brightness.light;

// BLACKOUT: the NOTORYX brand look. Matte, charcoal, gunmetal, steel and
// frost; no brand hue. Only colors that carry meaning (good signal, warning,
// SOS) keep their color. The default.
const _matte = Color(0xFF080808);
const _charcoal = Color(0xFF242424);
const _gunmetal = Color(0xFF484848);
const _steel = Color(0xFF888888);
const _frost = Color(0xFFE8E8E8);

final _blackout = BastionPalette.derive(
  brightness: _dark,
  bg: _matte,
  surface: _charcoal,
  ink: _frost,
  // Steel, lifted a touch so secondary text stays 4.5:1 on glass cards.
  muted: const Color(0xFF9A9A9A),
  accent: _frost,
  accentDim: _steel,
  onAccent: _matte,
  secondary: const Color(0xFFBDBDBD),
  tertiary: const Color(0xFFA8A8A8),
  magenta: const Color(0xFFD0D0D0),
  signal: const Color(0xFF5FD98A),
  warn: const Color(0xFFFFC83D),
  alert: const Color(0xFFFF5A4E),
  me: const Color(0xFF2E2E2E),
  meInk: _frost,
  meBorder: _gunmetal,
  primaryContainer: const Color(0xFF3A3A3A),
  secondaryContainer: _gunmetal,
  tertiaryContainer: const Color(0xFF303030),
);

// Blaze: charcoal and slate with high-visibility orange.
final _blaze = BastionPalette.derive(
  brightness: _dark,
  bg: const Color(0xFF111820),
  surface: const Color(0xFF273443),
  ink: const Color(0xFFF4F6F8),
  muted: const Color(0xFFAAB5C3),
  accent: const Color(0xFFFF8A00),
  onAccent: const Color(0xFF2A1300),
  secondary: const Color(0xFFF07A12),
  tertiary: const Color(0xFF22D3E6),
  magenta: const Color(0xFFA985FF),
  signal: const Color(0xFF5FD98A),
  warn: const Color(0xFFFFC83D),
  alert: const Color(0xFFFF5A4E),
  me: const Color(0xFF3D2A18),
  meInk: const Color(0xFFF4F6F8),
  primaryContainer: const Color(0xFF4A2E10),
  secondaryContainer: const Color(0xFF4A2A0C),
  tertiaryContainer: const Color(0xFF12393F),
);

// Bare Beauty: warm nude, dusty rose, cocoa and hazel-sage.
final _bareBeauty = BastionPalette.derive(
  brightness: _light,
  bg: const Color(0xFFFFF0E7),
  surface: const Color(0xFFE8B69E),
  ink: const Color(0xFF38232B),
  muted: const Color(0xFF5E3D3F),
  // Dusty rose, deepened for white text.
  accent: const Color(0xFF84464F),
  onAccent: const Color(0xFFFFFFFF),
  // Cocoa and a hazel-sage.
  secondary: const Color(0xFF754B43),
  tertiary: const Color(0xFF44625A),
  magenta: const Color(0xFFC77D87),
  signal: const Color(0xFF2F6B45),
  warn: const Color(0xFF7A4E00),
  alert: const Color(0xFFA3122A),
  me: const Color(0xFF8E4F58),
  meInk: const Color(0xFFFFFFFF),
  meBorder: const Color(0xFFC77D87),
  primaryContainer: const Color(0xFFE8B69E),
  secondaryContainer: const Color(0xFFF0C9C4),
  tertiaryContainer: const Color(0xFFCFDDD5),
  faint: const Color(0xFF5E3D3F),
);

// Okabe-Ito: every accent and status color from the color-blind safe
// palette, on charcoal. Vermillion is lifted slightly so SOS reads on cards.
final _okabeIto = BastionPalette.derive(
  brightness: _dark,
  bg: const Color(0xFF161A20),
  surface: const Color(0xFF343C48),
  ink: const Color(0xFFFFFFFF),
  muted: const Color(0xFFC3CBD5),
  accent: OkabeIto.skyBlue,
  accentDim: OkabeIto.blue,
  onAccent: OkabeIto.black,
  secondary: OkabeIto.orange,
  tertiary: const Color(0xFF33B08A),
  magenta: const Color(0xFFD694B9),
  // Bluish green, lifted like vermillion so it reads on cards.
  signal: const Color(0xFF33B08A),
  warn: OkabeIto.yellow,
  alert: const Color(0xFFF07A3A),
  me: OkabeIto.blue,
  meInk: const Color(0xFFFFFFFF),
  meBorder: OkabeIto.skyBlue,
  primaryContainer: OkabeIto.blue,
  secondaryContainer: const Color(0xFF5A4110),
  tertiaryContainer: const Color(0xFF0B4F3E),
);

// Night Ops: near-black with restrained reds for low light.
final _nightOps = BastionPalette.derive(
  brightness: _dark,
  bg: const Color(0xFF080808),
  surface: const Color(0xFF251010),
  ink: const Color(0xFFF3D6D3),
  muted: const Color(0xFFC9A09B),
  accent: const Color(0xFFE0574D),
  accentDim: const Color(0xFFC23A32),
  onAccent: const Color(0xFF1A0503),
  secondary: const Color(0xFFE07A6E),
  tertiary: const Color(0xFFF3A29A),
  signal: const Color(0xFFE08A7E),
  warn: const Color(0xFFFF8A5C),
  alert: const Color(0xFFFF3B30),
  me: const Color(0xFF3A1412),
  meInk: const Color(0xFFF3D6D3),
  meBorder: const Color(0xFF852722),
  primaryContainer: const Color(0xFF5A1A16),
  secondaryContainer: const Color(0xFF852722),
  tertiaryContainer: const Color(0xFF3A1218),
);
