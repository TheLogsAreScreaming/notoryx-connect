import 'dart:io';

import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// German and French run longer than English. Every main tab must fit a
/// small phone without overflow stripes, with normal and large text.
void main() {
  // Measure with the app's real font; the default test font is far wider.
  setUpAll(() async {
    final loader = FontLoader('Inter');
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Inter-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
  });

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final cache = Directory.systemTemp.createTempSync('bastion-layout-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => cache.path,
    );
  });

  for (final code in ['en', 'de', 'fr', 'es']) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('every tab fits a small phone in $code at text x$scale', (tester) async {
        final locale = Locale(code);
        final l = lookupAppLocalizations(locale);
        tester.platformDispatcher.localeTestValue = locale;
        tester.platformDispatcher.localesTestValue = [locale];
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        tester.view.physicalSize = const Size(384, 832); // a Galaxy A15
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const BastionApp());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Home');
        final tabs = find.byType(NavigationDestination);
        expect(tabs, findsWidgets);
        // A tab label that wraps breaks in the middle of the word ("Einstellun / gen").
        final wrapped = <String>[];
        for (final label in tester.renderObjectList<RenderParagraph>(
          find.descendant(of: find.byType(NavigationBar), matching: find.byType(RichText)),
        )) {
          final text = label.text.toPlainText();
          final lines = label
              .getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: text.length))
              .map((b) => b.top.round())
              .toSet();
          if (lines.length > 1) wrapped.add(text);
        }
        // Large text can still wrap a label; the phone's normal size must not.
        if (scale == 1.0) expect(wrapped, isEmpty, reason: 'tab labels wrap in $code');
        final seen = <String>{};
        for (var i = 0; i < tabs.evaluate().length; i++) {
          await tester.tap(tabs.at(i));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'tab $i in $code');
          if (find.text(l.toolsDoctor).evaluate().isNotEmpty) seen.add('tools');
          if (find.text(l.setSubtitle).evaluate().isNotEmpty) seen.add('settings');
        }
        expect(seen, {'tools', 'settings'}, reason: 'the taps really opened the Tools and Settings tabs');
      });
    }
  }
}
