import 'dart:io';

import 'package:bastion/main.dart';
import 'package:bastion/theme/notoryx_theme.dart';
import 'package:bastion/theme/nx_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final cache = Directory.systemTemp.createTempSync('bastion-a11y-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (_) async => cache.path);
  });

  const tabs = ['Nodes', 'Tools', 'Settings'];

  testWidgets('every tap target on the main tabs is big enough and named', (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    for (final label in tabs) {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline), reason: label);
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline), reason: label);
    }
    handle.dispose();
  });

  testWidgets('the radio status is a button that is announced when it changes', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    final pill = find.bySemanticsLabel(RegExp(r'^Radio: '));
    expect(pill, findsOneWidget);
    expect(tester.getSemantics(pill), isSemantics(isButton: true, isLiveRegion: true, hasTapAction: true));
    handle.dispose();
  });

  for (final (tone, spoken) in [(NxTone.danger, true), (NxTone.warning, true), (NxTone.info, false)]) {
    testWidgets('a ${tone.name} banner ${spoken ? 'is' : 'is not'} announced', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: NxBanner(message: 'Hello', tone: tone))));
      expect(tester.getSemantics(find.bySemanticsLabel('Hello')), isSemantics(isLiveRegion: spoken));
      handle.dispose();
    });
  }

  test('nothing in the app overrides the text size setting', () {
    final dart = Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
    for (final file in dart) {
      expect(file.readAsStringSync(), isNot(matches(RegExp(r'withClampedTextScaling|textScaleFactor'))), reason: file.path);
    }
  });
}
