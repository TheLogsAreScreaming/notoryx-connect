import 'package:flutter/material.dart';

import '../services/bastion_preferences.dart';
import 'notoryx_tokens.dart';
import 'nx_themes.dart';

/// The short description of [theme].
String themeDescription(BastionTheme theme) => switch (theme) {
      BastionTheme.blaze => 'Charcoal and slate with high-visibility orange',
      BastionTheme.neonAnarchy => 'Toxic green and electric purple on black',
      BastionTheme.tactical => 'Olive, gunmetal and earth tones',
      BastionTheme.pinkOverload => 'Hot pink, bubblegum and lavender',
      BastionTheme.bareBeauty => 'Warm nude, dusty rose, cocoa and sage',
      BastionTheme.okabeIto => 'Color-blind safe, high clarity',
      BastionTheme.nightOps => 'Dim reds on near-black for low light',
      BastionTheme.seasonal => 'Changes with the seasons and holidays',
    };

/// The name of [season].
String seasonName(Season season) => switch (season) {
      Season.spring => 'Spring',
      Season.summer => 'Summer',
      Season.autumn => 'Autumn',
      Season.winter => 'Winter',
      Season.halloween => 'Halloween',
      Season.christmas => 'Christmas',
      Season.valentine => "Valentine's Day",
    };

/// Black or white, whichever reads better on [fill].
Color onColor(Color fill) {
  final l = fill.computeLuminance();
  return 1.05 / (l + .05) >= (l + .05) / .05 ? Colors.white : Colors.black;
}

/// The eight themes as cards with a small preview of each. A tap applies the
/// theme at once and saves it. Seasonal's options and the optional dark-mode
/// theme sit below the cards.
class NxThemePicker extends StatelessWidget {
  const NxThemePicker({super.key, required this.prefs});

  final BastionPreferences prefs;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: prefs,
        builder: (context, _) {
          final selected = BastionTheme.fromId(prefs.appTheme);
          final season = activeSeason(override: prefs.seasonalOverride, holidays: prefs.seasonalHolidays);
          final seasonalInUse = selected == BastionTheme.seasonal ||
              prefs.darkModeTheme == BastionTheme.seasonal.id;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth >= 300 ? 2 : 1;
                const gap = NxSpace.sm;
                final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(spacing: gap, runSpacing: gap, children: [
                  for (final t in BastionTheme.values)
                    SizedBox(
                      width: width,
                      child: _ThemeCard(
                        theme: t,
                        palette: t == BastionTheme.seasonal ? season.palette : t.palette,
                        selected: t == selected,
                        onTap: () => prefs.update(theme: t.id),
                      ),
                    ),
                ]);
              }),
              if (seasonalInUse) ...[
                const SizedBox(height: NxSpace.sm),
                _SeasonalControls(prefs: prefs, active: season),
              ],
              const SizedBox(height: NxSpace.sm),
              _DarkModeControls(prefs: prefs),
            ],
          );
        },
      );
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.theme, required this.palette, required this.selected, required this.onTap});

  final BastionTheme theme;
  final BastionPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final ring = Theme.of(context).colorScheme.primary;
    final description = themeDescription(theme);
    final radius = BorderRadius.circular(NxRadius.lg);
    return Semantics(
      button: true,
      selected: selected,
      label: '${theme.label}. $description',
      // Excluding the children drops the InkWell's tap, so add it back or
      // screen-reader users couldn't choose a theme.
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('theme-${theme.id}'),
          onTap: onTap,
          borderRadius: radius,
          child: AnimatedContainer(
            duration: NxMotion.of(context, NxMotion.fast),
            padding: const EdgeInsets.all(NxSpace.xs),
            decoration: BoxDecoration(
              color: p.bg,
              borderRadius: radius,
              border: Border.all(color: selected ? ring : p.line2, width: selected ? 3 : 1),
              boxShadow: selected ? [BoxShadow(color: ring.withValues(alpha: 0.35), blurRadius: 12)] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniApp(palette: p),
                const SizedBox(height: NxSpace.xs),
                Row(children: [
                  Expanded(
                    child: Text(theme.label,
                        style: TextStyle(color: p.ink, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  if (selected) Icon(Icons.check_circle, size: 20, color: p.accent),
                ]),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: p.ink3, fontSize: 12, height: 1.25)),
                if (selected) ...[
                  const SizedBox(height: 4),
                  Text('Selected',
                      style: TextStyle(color: p.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A miniature of the app: app bar, a received and a sent message, a
/// button, an SOS chip and the navigation bar, all in [palette].
class _MiniApp extends StatelessWidget {
  const _MiniApp({required this.palette});

  final BastionPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    Widget bar(double width, Color color, {double height = 5}) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(NxRadius.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.bg1, Color.lerp(p.bg1, p.secondary, 0.10)!],
          ),
          border: Border.all(color: p.line),
          borderRadius: BorderRadius.circular(NxRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: p.bg2,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: p.signal, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                bar(36, p.ink),
                const Spacer(),
                bar(14, p.ink3),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: p.bg3, borderRadius: BorderRadius.circular(8)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        bar(20, p.tertiary, height: 4),
                        const SizedBox(height: 3),
                        bar(44, p.ink2, height: 4),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: p.me,
                        border: Border.all(color: p.meBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: bar(38, p.meInk, height: 4),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(children: [
                    Expanded(
                      child: Container(
                        height: 16,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(NxRadius.pill)),
                        child: bar(22, p.onAccent, height: 4),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: p.alert, borderRadius: BorderRadius.circular(NxRadius.pill)),
                      child: Text('SOS',
                          style: TextStyle(color: onColor(p.alert), fontSize: 8, fontWeight: FontWeight.w900)),
                    ),
                  ]),
                ],
              ),
            ),
            Container(
              color: p.bg2,
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final c in [p.accent, p.ink4, p.ink4, p.ink4])
                    Container(
                      width: c == p.accent ? 16 : 7,
                      height: 7,
                      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(NxRadius.md),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Column(children: children),
      );
}

class _SeasonalControls extends StatelessWidget {
  const _SeasonalControls({required this.prefs, required this.active});

  final BastionPreferences prefs;
  final Season active;

  @override
  Widget build(BuildContext context) {
    final auto = seasonFor(DateTime.now(), holidays: prefs.seasonalHolidays);
    final value = Season.fromId(prefs.seasonalOverride)?.id ?? 'auto';
    return _Box(children: [
      ListTile(
        key: const ValueKey('seasonal-season'),
        leading: const Icon(Icons.eco_outlined),
        title: const Text('Season'),
        subtitle: Text(value == 'auto'
            ? "Follows your device's date, with northern-hemisphere seasons"
            : seasonName(active)),
        trailing: DropdownButton<String>(
          value: value,
          underline: const SizedBox.shrink(),
          onChanged: (v) {
            if (v != null) prefs.update(season: v);
          },
          items: [
            DropdownMenuItem(value: 'auto', child: Text('Automatic (${seasonName(auto)} now)')),
            for (final s in Season.values) DropdownMenuItem(value: s.id, child: Text(seasonName(s))),
          ],
        ),
      ),
      const Divider(height: 1),
      SwitchListTile(
        key: const ValueKey('seasonal-holidays'),
        secondary: const Icon(Icons.celebration_outlined),
        title: const Text('Holiday colors'),
        subtitle: const Text("Halloween, Christmas and Valentine's Day on their dates"),
        value: prefs.seasonalHolidays,
        onChanged: (v) => prefs.update(holidays: v),
      ),
    ]);
  }
}

/// An optional second theme for when the device is in dark mode.
class _DarkModeControls extends StatelessWidget {
  const _DarkModeControls({required this.prefs});

  final BastionPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final on = prefs.darkModeTheme.isNotEmpty;
    final current = BastionTheme.fromId(prefs.darkModeTheme);
    return _Box(children: [
      SwitchListTile(
        key: const ValueKey('dark-mode-switch'),
        secondary: const Icon(Icons.dark_mode_outlined),
        title: const Text('Different theme in dark mode'),
        subtitle: const Text('Use another theme while your device is set to dark mode'),
        value: on,
        onChanged: (value) => prefs.update(
          darkTheme: !value
              ? ''
              // Start with a dark theme other than the day one.
              : prefs.appTheme == BastionTheme.nightOps.id
                  ? BastionTheme.blaze.id
                  : BastionTheme.nightOps.id,
        ),
      ),
      if (on) ...[
        const Divider(height: 1),
        ListTile(
          key: const ValueKey('dark-mode-theme'),
          leading: const Icon(Icons.nights_stay_outlined),
          title: const Text('Dark mode theme'),
          trailing: DropdownButton<String>(
            value: current.id,
            underline: const SizedBox.shrink(),
            onChanged: (v) {
              if (v != null) prefs.update(darkTheme: v);
            },
            items: [
              for (final t in BastionTheme.values) DropdownMenuItem(value: t.id, child: Text(t.label)),
            ],
          ),
        ),
      ],
    ]);
  }
}
