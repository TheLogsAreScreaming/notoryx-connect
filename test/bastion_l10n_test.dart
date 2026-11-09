import 'dart:convert';
import 'dart:io';

import 'package:bastion/main.dart';
import 'package:bastion/trip_page.dart';
import 'package:bastion/beacon_page.dart';
import 'package:bastion/channel_share_page.dart';
import 'package:bastion/radio_settings_page.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/field_tools_page.dart';
import 'package:bastion/node_detail_page.dart';
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

  testWidgets('Node detail is translated', (tester) async {
    tester.view.physicalSize = const Size(390, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NodeDetailPage(radio: radio, nodeNum: 0x1234),
    ));
    await tester.pump();
    expect(find.text('Silenciar notificaciones'), findsOneWidget);
    expect(find.text('Clave de seguridad'), findsOneWidget);
    expect(find.text('MENSAJES DIRECTOS'), findsOneWidget);
  });

  testWidgets('Home is translated, but check-in words stay as sent on air', (tester) async {
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
    expect(find.text('Ninguna radio conectada'), findsOneWidget);
    expect(find.text('Mantén para SOS'), findsOneWidget);
    expect(find.text('Conectar radio'), findsOneWidget);
    expect(find.textContaining('Reportarse: '), findsOneWidget);
  });

  testWidgets('Field records is translated, but templates stay as sent on air', (tester) async {
    tester.view.physicalSize = const Size(390, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: FieldToolsPage(radio: radio),
    ));
    await tester.pump();
    expect(find.text('Registros de campo'), findsOneWidget);
    expect(find.text('Registro de incidentes'), findsOneWidget);
    await tester.tap(find.text('Plantillas de emergencia y reporte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Todo en orden'));
    await tester.pump();
    expect(find.textContaining('ALL CLEAR | Name:'), findsOneWidget);
  });

  testWidgets('Radio settings is translated', (tester) async {
    tester.view.physicalSize = const Size(390, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RadioSettingsPage(radio: radio),
    ));
    await tester.pump();
    expect(find.text('Ajustes de la radio'), findsOneWidget);
    expect(find.text('Radio no preparada'), findsOneWidget);
    expect(find.text('Propietario'), findsOneWidget);
  });

  testWidgets('Beacons is translated', (tester) async {
    tester.view.physicalSize = const Size(390, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BeaconPage(radio: radio),
    ));
    await tester.pump();
    expect(find.text('Balizas de la malla'), findsOneWidget);
    expect(find.text('Aún no se han oído balizas'), findsOneWidget);
    expect(find.text('Conéctate a una radio para enviar una baliza.'), findsOneWidget);
  });

  testWidgets('Channel import is translated', (tester) async {
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChannelImportPage(radio: radio),
    ));
    await tester.pump();
    expect(find.text('Importar canales'), findsOneWidget);
    expect(find.text('Enlace de canal de Meshtastic'), findsOneWidget);
  });

  testWidgets('Trip is translated', (tester) async {
    tester.view.physicalSize = const Size(390, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TripPage(radio: radio),
    ));
    await tester.pump();
    expect(find.text('Planifica tu viaje'), findsOneWidget);
    expect(find.text('Empezar viaje'), findsOneWidget);
    expect(find.text('Aún no hay nodos'), findsOneWidget);
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
