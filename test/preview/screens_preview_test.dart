// Renders README screenshots of each main tab and the main sub-screens
// with real fonts.
// Skipped unless PREVIEW_OUT is set:
//   PREVIEW_OUT=docs/screenshots flutter test test/preview
// Screens use the built-in demo radio (BastionDemoRadio), so they show a
// pretend mesh instead of the not-yet-connected state.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bastion/beacon_page.dart';
import 'package:bastion/field_tools_page.dart';
import 'package:bastion/local_mesh_discovery_page.dart';
import 'package:bastion/main.dart';
import 'package:bastion/phone_backup_page.dart';
import 'package:bastion/privacy_page.dart';
import 'package:bastion/radio_backup_page.dart';
import 'package:bastion/sarneg/sarneg.dart';
import 'package:bastion/sarneg/sarneg_ui.dart';
import 'package:bastion/services/bastion_demo_radio.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/trip_page.dart';
import 'package:bastion/services/bastion_preferences.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final p in paths) {
      final bytes = File(p).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  final fonts = '${Platform.environment['FLUTTER_ROOT']!}/bin/cache/artifacts/material_fonts';
  await load('Roboto', [
    for (final w in ['Light', 'Regular', 'Medium', 'Bold', 'Black']) '$fonts/Roboto-$w.ttf',
  ]);
  await load('MaterialIcons', ['$fonts/MaterialIcons-Regular.otf']);
  // The app's own bundled fonts (NxFonts).
  await load('Inter', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) 'assets/fonts/Inter-$w.ttf',
  ]);
  await load('JetBrains Mono', [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) 'assets/fonts/JetBrainsMono-$w.ttf',
  ]);
  // On a phone 'monospace' is the system mono font; here the bundled one
  // stands in, so the SARNEG screen doesn't render empty boxes.
  await load('monospace', [
    for (final w in ['Regular', 'Bold']) 'assets/fonts/JetBrainsMono-$w.ttf',
  ]);
}

void main() {
  final out = Platform.environment['PREVIEW_OUT'];
  // Icons to tap in turn, and the file name for that screen. Tools and
  // Settings are the two sides of the More tab.
  final tabs = {
    'home': [Icons.shield_outlined],
    'nodes': [Icons.hub_outlined],
    'chats': [Icons.chat_bubble_outline],
    // Map tiles need the internet, so the base map is blank here.
    'map': [Icons.map_outlined],
    'tools': [Icons.more_horiz, Icons.build_outlined],
    'settings': [Icons.more_horiz, Icons.settings_outlined],
  };

  setUpAll(() async {
    if (out != null) await _loadFonts();
  });

  // The map tab is built off-screen and asks for a tile cache directory;
  // the message archive needs a working store.
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final tmp = Directory.systemTemp.createTempSync('preview').path;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), (call) async => tmp);
  });

  // A made-up code word for the SARNEG screen; it stays hidden on screen.
  SarnegKeys.instance = SarnegKeys(storage: MemorySarnegStorage(jsonEncode(SarnegKeySet(word: 'FLYINGDUCK').toJson())));

  // Sub-screens opened from the tabs, rendered in the default dark theme
  // (BLACKOUT).
  final pages = <String, Widget Function(MeshtasticRadioCoordinator)>{
    'field_records': (radio) => FieldToolsPage(radio: radio),
    'privacy': (radio) => PrivacyPage(radio: radio),
    'radio_backup': (radio) => RadioBackupPage(radio: radio),
    'phone_backup': (radio) => PhoneBackupPage(radio: radio),
    'beacons': (radio) => BeaconPage(radio: radio),
    'trip': (radio) => TripPage(radio: radio),
    'discovery': (radio) => LocalMeshDiscoveryPage(radio: radio),
    'sarneg': (radio) => const SarnegScreen(),
  };
  for (final page in pages.entries) {
    testWidgets('page ${page.key}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(780, 1688);
      addTearDown(tester.view.reset);
      final radio = BastionDemoRadio();
      addTearDown(radio.dispose);
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: boundary, child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, 
        debugShowCheckedModeBanner: false,
        theme: BastionApp.appearance(Brightness.dark),
        home: page.value(radio),
      )));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final ro = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await ro.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$out/${page.key}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      });
    }, skip: out == null);
  }

  // PREVIEW_THEME=night_ops renders one theme; otherwise BLACKOUT (the
  // default) and Bare Beauty (the light theme).
  final themes = Platform.environment['PREVIEW_THEME']?.split(',') ?? ['blackout', 'bare_beauty'];
  for (final theme in themes) {
    testWidgets('main tabs $theme', (tester) async {
      SharedPreferences.setMockInitialValues({});
      BastionPreferences.instance.appTheme = theme;
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(780, 1688);
      addTearDown(tester.view.reset);
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(key: boundary, child: const BastionApp()));
      await tester.pumpAndSettle();
      // Switch to the demo radio from the Home tab's "Try the demo".
      await tester.tap(find.byIcon(Icons.play_circle_outline).first);
      await tester.pumpAndSettle();
      for (final tab in tabs.entries) {
        for (final icon in tab.value) {
          await tester.tap(find.byIcon(icon).last);
          await tester.pumpAndSettle();
        }
        if (tab.key == 'nodes') {
          // Bring the demo mesh's node list to the top of the screen.
          await tester.dragFrom(const Offset(195, 600), const Offset(0, -520));
          await tester.pumpAndSettle();
        }
        await tester.runAsync(() async {
          final ro = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await ro.toImage(pixelRatio: 2);
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final suffix = switch (theme) { 'blackout' => '', 'bare_beauty' => '_light', _ => '_$theme' };
          File('$out/${tab.key}$suffix.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(png!.buffer.asUint8List());
        });
      }
    }, skip: out == null);
  }
}
