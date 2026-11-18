// Renders the live Traffic map with the demo radio, mid-animation.
// Skipped unless PREVIEW_OUT is set:
//   PREVIEW_OUT=docs/screenshots flutter test test/preview/traffic_preview_test.dart
// Map tiles need the internet, so the base map is blank here.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/main.dart';
import 'package:bastion/map_page.dart';
import 'package:bastion/services/bastion_demo_radio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
  await load('Roboto', [for (final w in ['Regular', 'Medium', 'Bold']) '$fonts/Roboto-$w.ttf']);
  await load('MaterialIcons', ['$fonts/MaterialIcons-Regular.otf']);
  await load('Inter', [for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) 'assets/fonts/Inter-$w.ttf']);
}

void main() {
  final out = Platform.environment['PREVIEW_OUT'];

  testWidgets('traffic map', (tester) async {
    await _loadFonts();
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final tmp = Directory.systemTemp.createTempSync('preview').path;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (call) async => tmp);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(860, 1800);
    addTearDown(tester.view.reset);
    final radio = BastionDemoRadio();
    addTearDown(radio.dispose);
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: BastionApp.appearance(Brightness.dark),
      home: Scaffold(body: MapPage(radio: radio)),
    )));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const ValueKey('map-traffic')));
    await tester.pump();
    // The first demo packet: Sam → relay → us, dot on the second leg.
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.runAsync(() async {
      final ro = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await ro.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$out/traffic_map.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
    await tester.tap(find.byKey(const ValueKey('map-traffic')));
    await tester.pump(const Duration(seconds: 5));
  }, skip: out == null);
}
