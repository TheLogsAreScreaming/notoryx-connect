import 'package:flutter/material.dart';

import 'notoryx_tokens.dart';
import 'nx_themes.dart';

/// The tone of a status: what it means, shown with colour AND an icon or
/// words, never colour alone.
enum NxTone { neutral, info, success, warning, danger }

/// Status colours for each tone, tuned per theme for 4.5:1 text contrast.
@immutable
class NxStatusColors extends ThemeExtension<NxStatusColors> {
  const NxStatusColors({
    required this.success,
    required this.onSuccessContainer,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;

  static NxStatusColors of(BuildContext context) =>
      Theme.of(context).extension<NxStatusColors>() ?? _dark;

  /// The strong colour for [tone]: icons, dots and short labels.
  Color strong(NxTone tone, ColorScheme scheme) => switch (tone) {
        NxTone.neutral => scheme.onSurfaceVariant,
        NxTone.info => info,
        NxTone.success => success,
        NxTone.warning => warning,
        NxTone.danger => scheme.error,
      };

  /// A tinted background for [tone] and the text colour that sits on it.
  (Color background, Color foreground) container(NxTone tone, ColorScheme scheme) => switch (tone) {
        NxTone.neutral => (scheme.surfaceContainerHigh, scheme.onSurface),
        NxTone.info => (infoContainer, onInfoContainer),
        NxTone.success => (successContainer, onSuccessContainer),
        NxTone.warning => (warningContainer, onWarningContainer),
        NxTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
      };

  /// Status colors from a theme [p]: its own good, warning and second hue,
  /// on light tints of each with the theme's text color.
  factory NxStatusColors.fromPalette(BastionPalette p) {
    Color tint(Color c) => Color.alphaBlend(c.withAlpha(0x38), p.bg2);
    return NxStatusColors(
      success: p.signal,
      successContainer: tint(p.signal),
      onSuccessContainer: p.ink,
      warning: p.warn,
      warningContainer: tint(p.warn),
      onWarningContainer: p.ink,
      info: p.secondary,
      infoContainer: tint(p.secondary),
      onInfoContainer: p.ink,
    );
  }

  static const _dark = NxStatusColors(
    success: NxPalette.greenBright,
    successContainer: Color(0xFF14301F),
    onSuccessContainer: Color(0xFFB9F0CD),
    warning: NxPalette.amberBright,
    warningContainer: Color(0xFF3A2C08),
    onWarningContainer: Color(0xFFFBE2A6),
    info: NxPalette.blueBright,
    infoContainer: Color(0xFF152A45),
    onInfoContainer: Color(0xFFCFE2FF),
  );

  @override
  NxStatusColors copyWith() => this;

  @override
  NxStatusColors lerp(NxStatusColors? other, double t) => t < .5 || other == null ? this : other;
}

/// Builds the app theme from one of the eight theme palettes; every colour
/// role is taken from the palette, so screens follow the chosen theme.
abstract final class NotoryxTheme {
  /// One type scale for the whole app: sentence case, weight for hierarchy.
  static TextTheme _type(ColorScheme c) {
    // Start from Material's full type geometry (sizes, baselines, spacing).
    final base = ThemeData(useMaterial3: true, brightness: c.brightness).textTheme
        .apply(bodyColor: c.onSurface, displayColor: c.onSurface);
    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
      titleLarge: base.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, height: 1.3),
      titleMedium: base.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.35),
      titleSmall: base.titleSmall?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12.5, height: 1.4, color: c.onSurfaceVariant),
      labelLarge: base.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: .1),
      labelMedium: base.labelMedium?.copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
      labelSmall: base.labelSmall?.copyWith(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: .9,
          color: c.onSurfaceVariant),
    );
  }

  /// The built-in look for [brightness]: Blaze when dark, Bare Beauty when
  /// light. The app itself uses [fromPalette] with the chosen theme.
  static ThemeData build(Brightness brightness) => fromPalette(
      brightness == Brightness.dark ? BastionTheme.blaze.palette : BastionTheme.bareBeauty.palette);

  /// The color scheme for theme [p]; every role is taken from the palette.
  static ColorScheme schemeFor(BastionPalette p) {
    final isDark = p.brightness == Brightness.dark;
    return ColorScheme(
      brightness: p.brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: p.ink,
      secondary: p.secondary,
      onSecondary: isDark ? p.bg : Colors.white,
      secondaryContainer: p.secondaryContainer,
      onSecondaryContainer: p.ink,
      tertiary: p.tertiary,
      onTertiary: isDark ? p.bg : Colors.white,
      tertiaryContainer: p.tertiaryContainer,
      onTertiaryContainer: p.ink,
      error: p.alert,
      onError: isDark ? p.bg : Colors.white,
      errorContainer: Color.alphaBlend(p.alert.withAlpha(0x40), p.bg2),
      onErrorContainer: p.ink,
      surface: p.bg,
      onSurface: p.ink,
      surfaceContainerLowest: p.bg,
      surfaceContainerLow: p.bg1,
      surfaceContainer: p.bg2,
      surfaceContainerHigh: p.bg3,
      surfaceContainerHighest: p.bg4,
      onSurfaceVariant: p.ink2,
      outline: p.line3,
      outlineVariant: p.line2,
      inverseSurface: p.ink,
      onInverseSurface: p.bg,
      inversePrimary: p.accentDim,
      shadow: Colors.black,
      scrim: Colors.black,
    );
  }

  /// The whole app theme for palette [p].
  static ThemeData fromPalette(BastionPalette p) =>
      _compose(schemeFor(p), NxStatusColors.fromPalette(p));

  static ThemeData _compose(ColorScheme c, NxStatusColors status) {
    final brightness = c.brightness;
    final dark = brightness == Brightness.dark;
    final type = _type(c);
    final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(NxRadius.md));
    const buttonSize = Size(64, NxTouch.min);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    Color? disabledFg(Set<WidgetState> s) => s.contains(WidgetState.disabled) ? c.onSurfaceVariant : null;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: c,
      textTheme: type,
      extensions: [status],
      scaffoldBackgroundColor: c.surface,
      canvasColor: c.surface,
      disabledColor: c.onSurfaceVariant,
      dividerTheme: DividerThemeData(color: c.outlineVariant, thickness: 1, space: 1),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: type.titleLarge,
        foregroundColor: c.onSurface,
      ),
      cardTheme: CardThemeData(
        color: c.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: NxSpace.xxs + 2),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NxRadius.lg),
          side: BorderSide(color: c.outlineVariant.withValues(alpha: dark ? .7 : 1)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: c.onSurface,
        iconColor: c.onSurfaceVariant,
        titleTextStyle: type.titleSmall?.copyWith(fontSize: 15),
        subtitleTextStyle: type.bodyMedium?.copyWith(color: c.onSurfaceVariant),
        minVerticalPadding: NxSpace.sm,
        contentPadding: const EdgeInsets.symmetric(horizontal: NxSpace.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NxRadius.lg)),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: c.primary,
        collapsedIconColor: c.onSurfaceVariant,
        textColor: c.onSurface,
        collapsedTextColor: c.onSurface,
      ),
      filledButtonTheme: FilledButtonThemeData(style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(buttonSize),
        padding: const WidgetStatePropertyAll(buttonPadding),
        shape: WidgetStatePropertyAll(rounded),
        textStyle: WidgetStatePropertyAll(type.labelLarge),
        foregroundColor: WidgetStateProperty.resolveWith(disabledFg),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(buttonSize),
        padding: const WidgetStatePropertyAll(buttonPadding),
        shape: WidgetStatePropertyAll(rounded),
        elevation: const WidgetStatePropertyAll(0),
        textStyle: WidgetStatePropertyAll(type.labelLarge),
      )),
      outlinedButtonTheme: OutlinedButtonThemeData(style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(buttonSize),
        padding: const WidgetStatePropertyAll(buttonPadding),
        shape: WidgetStatePropertyAll(rounded),
        textStyle: WidgetStatePropertyAll(type.labelLarge),
        foregroundColor: WidgetStateProperty.resolveWith((s) => disabledFg(s) ?? c.onSurface),
        side: WidgetStateProperty.resolveWith((s) => BorderSide(
            color: s.contains(WidgetState.disabled) ? c.outlineVariant : c.outline)),
      )),
      textButtonTheme: TextButtonThemeData(style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, NxTouch.min)),
        shape: WidgetStatePropertyAll(rounded),
        textStyle: WidgetStatePropertyAll(type.labelLarge),
      )),
      iconButtonTheme: IconButtonThemeData(style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(NxTouch.min, NxTouch.min)),
      )),
      segmentedButtonTheme: SegmentedButtonThemeData(style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(48, NxTouch.min)),
        textStyle: WidgetStatePropertyAll(type.labelLarge),
      )),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: NxSpace.md, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NxRadius.md),
          borderSide: BorderSide(color: c.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NxRadius.md),
          borderSide: BorderSide(color: c.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NxRadius.md),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(NxRadius.md),
          borderSide: BorderSide(color: c.error),
        ),
        labelStyle: TextStyle(color: c.onSurfaceVariant),
        helperStyle: type.bodySmall,
        prefixIconColor: c.onSurfaceVariant,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceContainer,
        selectedColor: c.primaryContainer,
        side: BorderSide(color: c.outlineVariant),
        labelStyle: type.labelMedium?.copyWith(color: c.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NxRadius.sm)),
        padding: const EdgeInsets.symmetric(horizontal: NxSpace.xxs, vertical: NxSpace.xxs),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onPrimary : c.outline),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : c.surfaceContainerHighest),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : c.outline),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primaryContainer,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? c.onPrimaryContainer : c.onSurfaceVariant)),
        labelTextStyle: WidgetStateProperty.resolveWith((s) => type.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected) ? c.onSurface : c.onSurfaceVariant,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surfaceContainerLow,
        indicatorColor: c.primaryContainer,
        selectedIconTheme: IconThemeData(color: c.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: c.onSurfaceVariant),
        selectedLabelTextStyle: type.labelMedium?.copyWith(color: c.onSurface, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: type.labelMedium?.copyWith(color: c.onSurfaceVariant),
        labelType: NavigationRailLabelType.all,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.primary,
        unselectedLabelColor: c.onSurfaceVariant,
        indicatorColor: c.primary,
        dividerColor: c.outlineVariant,
        labelStyle: type.labelLarge,
        unselectedLabelStyle: type.labelLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.inverseSurface,
        contentTextStyle: type.bodyMedium?.copyWith(color: c.onInverseSurface),
        actionTextColor: c.inversePrimary,
        shape: rounded,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NxRadius.xl)),
        titleTextStyle: type.titleLarge,
        contentTextStyle: type.bodyMedium?.copyWith(color: c.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(NxRadius.xl))),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary, linearTrackColor: c.surfaceContainerHighest),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: c.inverseSurface, borderRadius: BorderRadius.circular(NxRadius.sm)),
        textStyle: type.bodySmall?.copyWith(color: c.onInverseSurface),
      ),
      // Wide enough to grab with a finger; wider still while dragged.
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.dragged) ? 12 : 8),
        radius: const Radius.circular(6),
        minThumbLength: 48,
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.dragged)
            ? c.primary : c.onSurfaceVariant.withValues(alpha: 0.6)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      }),
    );
  }
}
