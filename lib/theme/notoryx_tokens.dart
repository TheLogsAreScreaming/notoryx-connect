import 'package:flutter/material.dart';

/// Spacing steps on a 4 px grid. Layouts use these, never raw numbers.
abstract final class NxSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Side padding for every scrolling page.
  static const page = EdgeInsets.fromLTRB(md, sm, md, lg);
}

/// Corner radii, the same steps NOTORYX Core uses. Cards, buttons and
/// chips take [xs]: squared-off, like a field instrument.
abstract final class NxRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

/// Bundled font families (see pubspec.yaml), shared with NOTORYX Core.
abstract final class NxFonts {
  static const sans = 'Inter';
  static const mono = 'JetBrains Mono';
  static const sansFallback = ['system-ui', '-apple-system', 'Roboto', 'Noto Sans', 'sans-serif'];
  static const monoFallback = ['SF Mono', 'Menlo', 'Consolas', 'Roboto Mono', 'monospace'];

  /// Numbers and readings (SNR, battery, IDs): monospace with even-width
  /// digits so columns line up and values don't jitter as they change.
  static TextStyle monoStyle({double? fontSize, FontWeight? fontWeight, Color? color}) => TextStyle(
        fontFamily: mono,
        fontFamilyFallback: monoFallback,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: .2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

/// The smallest comfortable touch target, in logical pixels.
abstract final class NxTouch {
  static const double min = 48;
  static const double large = 64;
}

/// Raw palette, named by what it is. Screens use [ColorScheme] roles and
/// [NxStatusColors], never these directly.
abstract final class NxPalette {
  /// NOTORYX orange from the app icon (the dark theme's accent).
  static const signal = Color(0xFFFC7202);

  /// The same hue darkened to keep 4.5:1 contrast on light surfaces.
  static const signalDeep = Color(0xFFAC4E01);

  // Dark neutrals, a faint olive cast that suits the field theme.
  static const ink0 = Color(0xFF0D0F0C);
  static const ink1 = Color(0xFF151713);
  static const ink2 = Color(0xFF1B1E19);
  static const ink3 = Color(0xFF232620);
  static const ink4 = Color(0xFF2C3029);
  static const ink5 = Color(0xFF3A3E36);
  static const fog = Color(0xFFECEDE7);
  static const fogDim = Color(0xFFB7BAB0);

  // Light neutrals.
  static const paper0 = Color(0xFFF6F5F1);
  static const paper1 = Color(0xFFFFFFFF);
  static const paper2 = Color(0xFFF0EEE8);
  static const paper3 = Color(0xFFE8E5DE);
  static const paper4 = Color(0xFFDFDCD3);
  static const paper5 = Color(0xFFC9C5BB);
  static const graphite = Color(0xFF1B1C18);
  static const graphiteDim = Color(0xFF52544C);

  // Status hues, dark-theme and light-theme variants.
  static const greenBright = Color(0xFF6ED49A);
  static const greenDeep = Color(0xFF1C7442);
  static const amberBright = Color(0xFFF4C152);
  static const amberDeep = Color(0xFF835500);
  static const redBright = Color(0xFFFF8E80);
  static const redDeep = Color(0xFFB3261E);
  static const blueBright = Color(0xFF8DBDFF);
  static const blueDeep = Color(0xFF1D5DAD);
}

/// Durations. [NxMotion.of] returns zero when the system asks for reduced
/// motion, so every animation honours it in one place.
abstract final class NxMotion {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const curve = Curves.easeOutCubic;

  static Duration of(BuildContext context, [Duration base = normal]) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : base;
}
