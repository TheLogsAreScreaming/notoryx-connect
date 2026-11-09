import 'dart:io';

import 'package:bastion/beacon_page.dart';
import 'package:bastion/channel_share_page.dart';
import 'package:bastion/field_tools_page.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/local_mesh_discovery_page.dart';
import 'package:bastion/main.dart';
import 'package:bastion/mesh_health_page.dart';
import 'package:bastion/mesh_tools_page.dart';
import 'package:bastion/phone_backup_page.dart';
import 'package:bastion/privacy_page.dart';
import 'package:bastion/radio_backup_page.dart';
import 'package:bastion/radio_settings_page.dart';
import 'package:bastion/services/bastion_tak_bridge.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/tak_bridge_page.dart';
import 'package:bastion/traceroute_page.dart';
import 'package:bastion/trip_page.dart';
import 'package:bastion/trip_readiness_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final pages = <String, Widget Function(MeshtasticRadioCoordinator)>{
  'field records': (r) => FieldToolsPage(radio: r),
  'privacy': (r) => PrivacyPage(radio: r),
  'radio backup': (r) => RadioBackupPage(radio: r),
  'phone backup': (r) => PhoneBackupPage(radio: r),
  'beacons': (r) => BeaconPage(radio: r),
  'trip': (r) => TripPage(radio: r),
  'trip readiness': (r) => TripReadinessPage(radio: r),
  'discovery': (r) => LocalMeshDiscoveryPage(radio: r),
  'mesh tools': (r) => MeshToolsPage(radio: r),
  'mesh health': (r) => MeshHealthPage(radio: r),
  'traceroute': (r) => TraceroutePage(radio: r),
  'radio settings': (r) => RadioSettingsPage(radio: r),
  'channel share': (r) => ChannelSharePage(radio: r),
  'channel import': (r) => ChannelImportPage(radio: r),
  'atak feed': (r) => TakBridgePage(bridge: BastionTakBridge()),
};

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final tmp = Directory.systemTemp.createTempSync('a11y').path;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (_) async => tmp);
  });

  Future<void> check(WidgetTester tester, String name, Widget page, double scale, List<String> out) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: BastionApp.appearance(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
      home: page,
    ));
    await tester.pump(const Duration(milliseconds: 300));
    final error = tester.takeException();
    if (error != null) out.add('$name x$scale: ${'$error'.split('\n').first}');
    for (final (label, guideline) in [
      ('tap size', androidTapTargetGuideline),
      ('label', labeledTapTargetGuideline),
      ('contrast', textContrastGuideline),
    ]) {
      final result = await guideline.evaluate(tester);
      if (!result.passed) {
        out.add('$name x$scale $label: ${result.reason?.replaceAll('\n', ' | ')}');
      }
    }
    handle.dispose();
  }

  for (final page in pages.entries) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('${page.key} at text size $scale', (tester) async {
        final radio = MeshtasticRadioCoordinator();
        addTearDown(radio.dispose);
        final problems = <String>[];
        await check(tester, page.key, page.value(radio), scale, problems);
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  }
}
