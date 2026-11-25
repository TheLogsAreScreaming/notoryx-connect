import 'dart:io';

import 'package:bastion/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'support/shell_nav.dart';

/// Home (with SOS) and Settings at large text on a narrow phone: nothing
/// overflows, text keeps its contrast, and SOS can be used without holding.
void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final cache = Directory.systemTemp.createTempSync('bastion-a11y-large-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (_) async => cache.path);
  });

  Future<void> pumpApp(WidgetTester tester, double scale) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('Home and SOS at text size $scale', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, scale);
      expect(tester.takeException(), isNull);
      final sos = find.bySemanticsLabel(RegExp('SOS', caseSensitive: false)).first;
      await tester.ensureVisible(sos);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('Settings at text size $scale', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, scale);
      await openSettings(tester);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  }
}
