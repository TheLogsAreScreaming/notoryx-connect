import 'dart:ui';

import 'package:flutter/material.dart';

import 'notoryx_tokens.dart';

/// NOTORYX Core's frosted glass, for Connect's main screens.
///
/// A see-through surface with a bright top edge and an edge that catches
/// the theme's accent, so the backdrop glow shows through. [blur] adds a
/// backdrop blur for large panels; rows in lists leave it off, since a blur
/// per row is costly on older phones. Reduced motion turns the blur off.
class NxGlassPanel extends StatelessWidget {
  const NxGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(NxSpace.md),
    this.blur = true,
    this.radius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool blur;
  final double radius;

  /// The glass fill, top to bottom, for dark and light themes.
  static List<Color> fill(bool dark) => dark
      ? [Colors.white.withValues(alpha: .14), Colors.white.withValues(alpha: .08), Colors.white.withValues(alpha: .035)]
      : [Colors.white.withValues(alpha: .72), Colors.white.withValues(alpha: .58), Colors.white.withValues(alpha: .42)];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = BorderRadius.circular(radius);
    final panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // The first stop is the lit top edge.
          stops: const [0, .06, 1],
          colors: fill(dark),
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: dark ? .30 : .38)),
      ),
      child: Padding(padding: padding, child: child),
    );
    // No drop shadow: it would show through the glass and darken it.
    return ClipRRect(
      borderRadius: r,
      child: blur && !MediaQuery.disableAnimationsOf(context)
          ? BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: panel)
          : panel,
    );
  }
}

/// One live value in an [NxReadoutStrip].
class NxReadout {
  const NxReadout(this.value, this.label, {this.color, this.icon});
  final String value;
  final String label;
  final Color? color;

  /// Drawn in place of [value] when a word would not fit the narrow tile
  /// (for example a plug for "Plugged in"); [value] is still what a screen
  /// reader says.
  final IconData? icon;
}

/// Live numbers side by side, split by hairlines, in the mono face, like
/// the face of a handheld instrument.
class NxReadoutStrip extends StatelessWidget {
  const NxReadoutStrip(this.readouts, {super.key});
  final List<NxReadout> readouts;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = scheme.outlineVariant.withValues(alpha: .7);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < readouts.length; i++)
            Expanded(
              child: Semantics(
                container: true,
                label: '${readouts[i].label}: ${readouts[i].value == '–' ? '–' : readouts[i].value}',
                excludeSemantics: true,
                child: Container(
                  padding: EdgeInsetsDirectional.fromSTEB(i == 0 ? NxSpace.md : NxSpace.sm, NxSpace.sm, NxSpace.xxs, NxSpace.sm),
                  decoration: i == 0
                      ? null
                      : BoxDecoration(border: BorderDirectional(start: BorderSide(color: line))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (readouts[i].icon case final icon?)
                        Icon(icon, size: 24, color: readouts[i].color ?? scheme.onSurface)
                      else
                        Text(
                          readouts[i].value,
                          style: TextStyle(
                            fontFamily: NxFonts.mono,
                            fontFamilyFallback: NxFonts.monoFallback,
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                            color: readouts[i].color ?? scheme.onSurface,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(readouts[i].label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A quiet section title for glass screens.
class NxGlassLabel extends StatelessWidget {
  const NxGlassLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(NxSpace.xxs, NxSpace.lg, NxSpace.xxs, NxSpace.xs),
        child: Semantics(
          header: true,
          child: Text(text, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
}

/// A compact glass row for an action or readout on a main screen.
class NxGlassRow extends StatelessWidget {
  const NxGlassRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: NxSpace.xs),
      child: NxGlassPanel(
        blur: false,
        radius: 18,
        padding: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: NxTouch.min + 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: NxSpace.md, vertical: 10),
                child: Row(children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: iconColor ?? scheme.onSurfaceVariant),
                    const SizedBox(width: NxSpace.md),
                  ],
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(title,
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: titleColor ?? scheme.onSurface)),
                      if (subtitle case final s? when s.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(s, style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant)),
                        ),
                    ]),
                  ),
                  if (trailing != null) ...[const SizedBox(width: NxSpace.sm), trailing!]
                  else if (onTap != null) ...[
                    const SizedBox(width: NxSpace.sm),
                    ExcludeSemantics(child: Icon(Icons.chevron_right_rounded, size: 20, color: scheme.onSurfaceVariant)),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Core's bottom bar: a frosted pill floating over the backdrop.
class NxFloatingBar extends StatelessWidget {
  const NxFloatingBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = BorderRadius.circular(30);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final pill = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, .08, 1],
          colors: dark
              ? [Colors.white.withValues(alpha: .16), Colors.white.withValues(alpha: .09), Colors.white.withValues(alpha: .05)]
              : [Colors.white.withValues(alpha: .85), Colors.white.withValues(alpha: .70), Colors.white.withValues(alpha: .55)],
        ),
        border: Border.all(color: dark ? Colors.white.withValues(alpha: .12) : Colors.black.withValues(alpha: .08)),
      ),
      child: child,
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
        child: ClipRRect(
          borderRadius: r,
          child: reduce ? pill : BackdropFilter(filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22), child: pill),
        ),
      ),
    );
  }
}
