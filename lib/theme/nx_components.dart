import 'package:flutter/material.dart';

import 'notoryx_theme.dart';
import 'notoryx_tokens.dart';

/// The title block at the top of a tab: a clear heading and one line on
/// what the screen is for. No box, so content starts higher up.
class NxPageHeader extends StatelessWidget {
  const NxPageHeader({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: NxSpace.xxs, bottom: NxSpace.sm),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(header: true, child: Text(title, style: type.headlineSmall)),
          if (subtitle != null) ...[
            const SizedBox(height: NxSpace.xxs),
            Text(subtitle!, style: type.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ])),
        if (trailing != null) ...[const SizedBox(width: NxSpace.sm), trailing!],
      ]),
    );
  }
}

/// A small label that starts a group of related controls.
class NxSectionLabel extends StatelessWidget {
  const NxSectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(NxSpace.xxs, NxSpace.md, NxSpace.xxs, NxSpace.xs),
        child: Row(children: [
          Expanded(child: Semantics(header: true,
              child: Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall))),
          ?trailing,
        ]),
      );
}

/// One number or word with a caption, for a row of at-a-glance stats.
class NxStatTile extends StatelessWidget {
  const NxStatTile({super.key, required this.label, required this.value, this.tone = NxTone.neutral, this.icon});
  final String label;
  final String value;
  final NxTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final color = tone == NxTone.neutral ? scheme.onSurface : NxStatusColors.of(context).strong(tone, scheme);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: NxSpace.sm, horizontal: NxSpace.sm),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(NxRadius.md),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: .7)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            if (icon != null) ...[Icon(icon, size: 18, color: color), const SizedBox(width: NxSpace.xxs)],
            Flexible(child: Text(value, style: type.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 2),
          Text(label, style: type.bodySmall),
        ]),
      ),
    );
  }
}

/// A row of [NxStatTile]s, all the same height and evenly spaced.
class NxStatRow extends StatelessWidget {
  const NxStatRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(width: NxSpace.xs),
            Expanded(child: child),
          ],
        ]),
      );
}

/// An inline message about state: a tip, a warning, an error or success.
/// The tone is shown by colour and by its icon.
class NxBanner extends StatelessWidget {
  const NxBanner({
    super.key,
    required this.message,
    this.title,
    this.tone = NxTone.neutral,
    this.icon,
    this.action,
  });
  final String message;
  final String? title;
  final NxTone tone;
  final IconData? icon;
  final Widget? action;

  static IconData iconFor(NxTone tone) => switch (tone) {
        NxTone.neutral => Icons.info_outline,
        NxTone.info => Icons.info_outline,
        NxTone.success => Icons.check_circle_outline,
        NxTone.warning => Icons.warning_amber_rounded,
        NxTone.danger => Icons.error_outline,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final (bg, fg) = NxStatusColors.of(context).container(tone, scheme);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: NxSpace.xxs + 2),
      padding: const EdgeInsets.all(NxSpace.sm + 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(NxRadius.md)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon ?? iconFor(tone), size: 20, color: fg),
        const SizedBox(width: NxSpace.sm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (title != null) ...[
            Text(title!, style: type.titleSmall?.copyWith(color: fg)),
            const SizedBox(height: 2),
          ],
          Text(message, style: type.bodyMedium?.copyWith(color: fg)),
          if (action != null) ...[const SizedBox(height: NxSpace.xs), action!],
        ])),
      ]),
    );
  }
}

/// What to show when a list has nothing in it yet, and what to do next.
class NxEmptyState extends StatelessWidget {
  const NxEmptyState({super.key, required this.icon, required this.title, required this.detail, this.action});
  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NxSpace.lg, horizontal: NxSpace.md),
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: scheme.surfaceContainerHigh, shape: BoxShape.circle),
          child: Icon(icon, size: 28, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: NxSpace.sm),
        Text(title, textAlign: TextAlign.center, style: type.titleMedium),
        const SizedBox(height: NxSpace.xxs),
        Text(detail, textAlign: TextAlign.center, style: type.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        if (action != null) ...[const SizedBox(height: NxSpace.md), action!],
      ]),
    );
  }
}

/// A rounded status chip with a coloured dot and words, e.g. "Connected".
class NxStatusPill extends StatelessWidget {
  const NxStatusPill({super.key, required this.label, required this.tone, this.icon, this.busy = false});
  final String label;
  final NxTone tone;
  final IconData? icon;

  /// Shows a small spinner in place of the dot while something is underway.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = NxStatusColors.of(context).strong(tone, scheme);
    return Semantics(
      label: 'Radio status: $label',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: NxSpace.sm, vertical: NxSpace.xxs),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(NxRadius.pill),
          border: Border.all(color: color.withValues(alpha: .45)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (busy)
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: color))
          else if (icon != null)
            Icon(icon, size: 16, color: color)
          else
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: NxSpace.xs),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurface)),
        ]),
      ),
    );
  }
}

/// A card holding a titled group of rows, the standard settings block.
class NxGroupCard extends StatelessWidget {
  const NxGroupCard({super.key, required this.children, this.padding = EdgeInsets.zero});
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(padding: padding, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children)),
      );
}
