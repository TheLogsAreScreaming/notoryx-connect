import 'dart:convert';
import 'dart:io';

import 'package:bastion/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Set<String> keysOf(String path) => (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>)
    .keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final cache = Directory.systemTemp.createTempSync('bastion-l10n-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (_) async => cache.path);
  });

  test('every language has every string', () {
    final english = keysOf('lib/l10n/app_en.arb');
    for (final file in Directory('lib/l10n').listSync().whereType<File>().where((f) => f.path.endsWith('.arb'))) {
      expect(keysOf(file.path), english, reason: file.path);
    }
  });

  testWidgets('the Tools page is translated', (tester) async {
    const locale = Locale('es');
    tester.platformDispatcher.localeTestValue = locale;
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Herramientas')));
    await tester.pumpAndSettle();
    expect(find.text('Doctor de conexión'), findsOneWidget);
    expect(find.text('Radio cargada'), findsOneWidget);
    expect(find.text('Connection doctor'), findsNothing);
  });

  testWidgets('Chats is translated, but quick replies stay as sent on air', (tester) async {
    const locale = Locale('es');
    tester.platformDispatcher.localeTestValue = locale;
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Chats')));
    await tester.pumpAndSettle();
    expect(find.text('Enviar'), findsOneWidget);
    expect(find.text('Send'), findsNothing);
    expect(find.text('On my way'), findsOneWidget);
  });

  testWidgets('the Nodes page is translated', (tester) async {
    const locale = Locale('es');
    tester.platformDispatcher.localeTestValue = locale;
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Nodos')));
    await tester.pumpAndSettle();
    expect(find.text('RADIOS CERCANAS'), findsOneWidget);
    expect(find.text('Conectar por Wi-Fi'), findsOneWidget);
    expect(find.text('RADIOS NEARBY'), findsNothing);
  });

  testWidgets('Settings is translated, but the legal notice stays English', (tester) async {
    const locale = Locale('es');
    tester.platformDispatcher.localeTestValue = locale;
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(390, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Ajustes')));
    await tester.pumpAndSettle();
    expect(find.text('Configuración de la radio'), findsOneWidget);
    expect(find.text('Radio configuration'), findsNothing);
    expect(find.textContaining('registered trademark of Meshtastic LLC'), findsOneWidget);
  });

  for (final (locale, settings, offline) in [
    (const Locale('en'), 'Settings', 'Radio: Offline'),
    (const Locale('es'), 'Ajustes', 'Radio: Sin conexión'),
  ]) {
    testWidgets('tabs and radio status follow the phone language: ${locale.languageCode}', (tester) async {
      tester.platformDispatcher.localeTestValue = locale;
      tester.platformDispatcher.localesTestValue = [locale];
      addTearDown(tester.platformDispatcher.clearLocaleTestValue);
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      // Phone width, so the shell shows the bottom tab bar rather than the side rail.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(const BastionApp());
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(NavigationBar), matching: find.text(settings)), findsOneWidget);
      expect(find.bySemanticsLabel(offline), findsOneWidget);
      handle.dispose();
    });
  }
}
