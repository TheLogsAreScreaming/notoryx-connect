import 'dart:io';

import 'package:bastion/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// German and French run longer than English. Every main tab must fit a
/// small phone without overflow stripes, with normal and large text.
void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final cache = Directory.systemTemp.createTempSync('bastion-layout-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => cache.path,
    );
  });

  for (final code in ['de', 'fr']) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('every tab fits a small phone in $code at text x$scale', (tester) async {
        final locale = Locale(code);
        tester.platformDispatcher.localeTestValue = locale;
        tester.platformDispatcher.localesTestValue = [locale];
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(const BastionApp());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'Home');
        final tabs = find.byType(NavigationDestination);
        expect(tabs, findsWidgets);
        final seen = <String>{};
        for (var i = 0; i < tabs.evaluate().length; i++) {
          await tester.tap(tabs.at(i));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: 'tab $i in $code');
          if (find
              .textContaining(code == 'de' ? 'Hilfsmittel zum Planen' : 'Utilitaires pour planifier')
              .evaluate()
              .isNotEmpty)
            seen.add('tools');
          if (find.textContaining(code == 'de' ? 'das Verhalten der App' : 'comportement de l').evaluate().isNotEmpty)
            seen.add('settings');
        }
        expect(seen, {'tools', 'settings'}, reason: 'the taps really opened the Tools and Settings tabs');
      });
    }
  }
}
