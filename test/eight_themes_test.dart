import 'package:bastion/services/bastion_preferences.dart';
import 'package:bastion/theme/notoryx_theme.dart';
import 'package:bastion/theme/nx_theme_picker.dart';
import 'package:bastion/theme/nx_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (la > lb ? la + .05 : lb + .05) / (la > lb ? lb + .05 : la + .05);
}

Map<String, BastionPalette> allPalettes() => {
  for (final t in BastionTheme.values)
    if (t != BastionTheme.seasonal) t.id: t.palette,
  for (final s in Season.values) 'seasonal/${s.id}': s.palette,
};

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('exactly eight themes, in order, Blaze first', () {
    expect(BastionTheme.values.map((t) => t.label), [
      'Blaze',
      'Neon Anarchy',
      'Tactical',
      'Pink Overload',
      'Bare Beauty',
      'Okabe-Ito',
      'Night Ops',
      'Seasonal',
    ]);
    expect(BastionPreferences().appTheme, BastionTheme.blaze.id);
  });

  test('every theme keeps text, buttons, status and SOS readable (WCAG AA)', () {
    final failures = <String>[];
    for (final e in allPalettes().entries) {
      final theme = NotoryxTheme.fromPalette(e.value);
      final c = theme.colorScheme;
      final s = theme.extension<NxStatusColors>()!;
      final card = theme.cardTheme.color!;
      final text = {
        'text on page': contrast(c.onSurface, c.surface),
        'text on cards': contrast(c.onSurface, card),
        'secondary text on page': contrast(c.onSurfaceVariant, c.surface),
        'secondary text on cards': contrast(c.onSurfaceVariant, card),
        'secondary text in fields': contrast(c.onSurfaceVariant, c.surfaceContainer),
        'text in dialogs': contrast(c.onSurface, c.surfaceContainerHigh),
        'accent on page': contrast(c.primary, c.surface),
        'accent on cards': contrast(c.primary, card),
        'button text': contrast(c.onPrimary, c.primary),
        'text on accent container': contrast(c.onPrimaryContainer, c.primaryContainer),
        'SOS / error on page': contrast(c.error, c.surface),
        'SOS / error on cards': contrast(c.error, card),
        'text on error container': contrast(c.onErrorContainer, c.errorContainer),
        'snack bar text': contrast(c.onInverseSurface, c.inverseSurface),
        for (final tone in NxTone.values) ...{
          '${tone.name} on cards': contrast(s.strong(tone, c), card),
          '${tone.name} container text': contrast(s.container(tone, c).$2, s.container(tone, c).$1),
        },
      };
      for (final t in text.entries) {
        if (t.value < 4.5) failures.add('${e.key}: ${t.key} ${t.value.toStringAsFixed(2)}');
      }
      // Field borders and switch tracks: 3:1 for controls.
      if (contrast(c.outline, c.surface) < 3) {
        failures.add('${e.key}: control outline ${contrast(c.outline, c.surface).toStringAsFixed(2)}');
      }
      expect(c.brightness, e.value.brightness);
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('good, warning and SOS stay three different colors', () {
    for (final e in allPalettes().entries) {
      final p = e.value;
      expect({p.signal, p.warn, p.alert}, hasLength(3), reason: e.key);
    }
  });

  group('saved choices from before the eight themes', () {
    Future<BastionPreferences> loadWith(Map<String, Object> values) async {
      final store = InMemorySharedPreferencesAsync.withData(values);
      SharedPreferencesAsyncPlatform.instance = store;
      final prefs = BastionPreferences();
      await prefs.load();
      return prefs;
    }

    test('dark opens as Blaze', () async {
      final p = await loadWith({'bastion.theme': 'dark'});
      expect((p.appTheme, p.darkModeTheme), ('blaze', ''));
    });

    test('light opens as Bare Beauty', () async {
      final p = await loadWith({'bastion.theme': 'light'});
      expect((p.appTheme, p.darkModeTheme), ('bare_beauty', ''));
    });

    test('system keeps following the device: Bare Beauty, Blaze in dark mode', () async {
      final p = await loadWith({'bastion.theme': 'system'});
      expect((p.appTheme, p.darkModeTheme), ('bare_beauty', 'blaze'));
      expect(p.activeTheme(Brightness.light), 'bare_beauty');
      expect(p.activeTheme(Brightness.dark), 'blaze');
    });

    test('a fresh install is Blaze', () async {
      final p = await loadWith({});
      expect((p.appTheme, p.darkModeTheme), ('blaze', ''));
    });

    test('a saved theme wins over the old setting, unknown ids fall back', () async {
      expect((await loadWith({'bastion.theme': 'light', 'bastion.app_theme': 'tactical'})).appTheme, 'tactical');
      expect((await loadWith({'bastion.app_theme': 'not_a_theme'})).appTheme, 'blaze');
    });
  });

  test('only Seasonal changes with the date', () {
    final july = DateTime(2026, 7, 4);
    final p = BastionPreferences()..appTheme = 'seasonal';
    expect(identical(p.palette(Brightness.light, now: july), Season.summer.palette), isTrue);
    expect(identical(p.palette(Brightness.light, now: DateTime(2026, 10, 30)), Season.halloween.palette), isTrue);
    p.seasonalHolidays = false;
    expect(identical(p.palette(Brightness.light, now: DateTime(2026, 10, 30)), Season.autumn.palette), isTrue);
    p.seasonalOverride = 'winter';
    expect(identical(p.palette(Brightness.light, now: july), Season.winter.palette), isTrue);
    for (final t in BastionTheme.values.where((t) => t != BastionTheme.seasonal)) {
      p.appTheme = t.id;
      expect(identical(p.palette(Brightness.light, now: july), t.palette), isTrue, reason: t.id);
    }
  });

  group('picker', () {
    Widget app(BastionPreferences prefs, {double width = 400, double textScale = 1}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 2400), textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(child: NxThemePicker(prefs: prefs)),
        ),
      ),
    );

    for (final width in [320.0, 720.0]) {
      testWidgets('eight cards at width $width and 2x text; a tap applies and saves', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 3200));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final prefs = BastionPreferences();
        await tester.pumpWidget(app(prefs, width: width, textScale: 2));
        expect(tester.takeException(), isNull);
        for (final t in BastionTheme.values) {
          expect(find.byKey(ValueKey('theme-${t.id}')), findsOneWidget);
        }
        expect(find.text('Selected'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('theme-pink_overload')));
        await tester.pumpAndSettle();
        expect(prefs.appTheme, 'pink_overload');
        final restored = BastionPreferences();
        await restored.load();
        expect(restored.appTheme, 'pink_overload');
      });
    }

    testWidgets('screen readers hear the name and Selected, and can choose', (tester) async {
      final handle = tester.ensureSemantics();
      final prefs = BastionPreferences();
      await tester.pumpWidget(app(prefs));
      final card = find.byKey(const ValueKey('theme-blaze'));
      expect(
        tester.getSemantics(find.ancestor(of: card, matching: find.byType(Semantics)).first),
        isSemantics(
          isButton: true,
          isSelected: true,
          hasTapAction: true,
          label: 'Blaze. ${themeDescription(BastionTheme.blaze)}',
        ),
      );
      await tester.tap(find.byKey(const ValueKey('theme-tactical')));
      await tester.pumpAndSettle();
      expect(prefs.appTheme, 'tactical');
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('Seasonal options appear only for Seasonal and save', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 3200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final prefs = BastionPreferences();
      await tester.pumpWidget(app(prefs));
      expect(find.byKey(const ValueKey('seasonal-season')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('theme-seasonal')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('seasonal-season')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('seasonal-holidays')));
      await tester.pumpAndSettle();
      expect(prefs.seasonalHolidays, isFalse);
    });

    testWidgets('dark-mode theme: off by default, switch on, pick, switch off', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 3200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final prefs = BastionPreferences();
      await tester.pumpWidget(app(prefs));
      expect(prefs.darkModeTheme, '');
      expect(find.byKey(const ValueKey('dark-mode-theme')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('dark-mode-switch')));
      await tester.pumpAndSettle();
      expect(prefs.darkModeTheme, 'night_ops');
      expect(prefs.activeTheme(Brightness.dark), 'night_ops');
      expect(prefs.activeTheme(Brightness.light), 'blaze');
      await tester.tap(find.byKey(const ValueKey('dark-mode-theme')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tactical').last);
      await tester.pumpAndSettle();
      expect(prefs.darkModeTheme, 'tactical');
      await tester.tap(find.byKey(const ValueKey('dark-mode-switch')));
      await tester.pumpAndSettle();
      expect(prefs.darkModeTheme, '');
    });
  });
}
