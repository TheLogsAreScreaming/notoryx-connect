import 'dart:io';

import 'package:bastion/main.dart';
import 'package:bastion/services/bastion_trip_readiness.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/trip_readiness_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final now = DateTime(2026, 11, 8, 12);
ReadinessContact contact(int n, {Duration? ago, bool? tested}) => ReadinessContact(
    num: n, name: 'Node $n', lastHeard: ago == null ? null : now.subtract(ago), testReached: tested);

ReadinessFacts good({int battery = 90, List<ReadinessContact>? contacts, DateTime? position, bool restricted = false}) =>
    ReadinessFacts(
      radioReady: true,
      now: now,
      batteryPercent: battery,
      firmwareVersion: '2.7.15.abc',
      channelCount: 2,
      contacts: contacts ?? [contact(1, ago: const Duration(minutes: 5))],
      positionTime: position ?? now.subtract(const Duration(minutes: 10)),
      backgroundRestricted: restricted,
    );

ReadinessItem item(ReadinessFacts f, String id) => BastionTripReadiness.check(f).firstWhere((i) => i.id == id);

void main() {
  test('six checks, all good means ready', () {
    final items = BastionTripReadiness.check(good());
    expect(items.map((i) => i.id), ['battery', 'firmware', 'channel', 'contacts', 'position', 'background']);
    expect(BastionTripReadiness.overall(items), ReadinessStatus.ready);
  });

  test('battery thresholds', () {
    expect(item(good(battery: 20), 'battery').status, ReadinessStatus.blocked);
    expect(item(good(battery: 45), 'battery').status, ReadinessStatus.warning);
    expect(item(good(battery: 101), 'battery').detail, 'On external power.');
  });

  test('no radio means unknown, not ready', () {
    final items = BastionTripReadiness.check(ReadinessFacts(radioReady: false, now: now, contacts: [contact(1, ago: Duration.zero)]));
    expect(items.firstWhere((i) => i.id == 'battery').status, ReadinessStatus.unknown);
    expect(items.firstWhere((i) => i.id == 'firmware').status, ReadinessStatus.unknown);
  });

  test('contacts: none, quiet, tested', () {
    expect(item(good(contacts: []), 'contacts').status, ReadinessStatus.blocked);
    final quiet = item(good(contacts: [contact(1, ago: const Duration(hours: 5))]), 'contacts');
    expect(quiet.status, ReadinessStatus.warning);
    expect(quiet.detail, contains('Node 1'));
    expect(item(good(contacts: [contact(1, ago: const Duration(hours: 5), tested: true)]), 'contacts').status, ReadinessStatus.ready);
    expect(item(good(contacts: [contact(1, ago: Duration.zero, tested: false)]), 'contacts').detail, contains('No route'));
  });

  test('missing SOS channel blocks', () {
    final f = ReadinessFacts(radioReady: true, now: now, channelCount: 1, sosChannel: 3, sosChannelExists: false);
    expect(item(f, 'channel').status, ReadinessStatus.blocked);
  });

  test('stale position and battery optimisation warn', () {
    expect(item(good(position: now.subtract(const Duration(hours: 3))), 'position').status, ReadinessStatus.warning);
    expect(item(good(restricted: true), 'background').status, ReadinessStatus.warning);
  });

  testWidgets('the page shows every check without sending anything', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final cache = Directory.systemTemp.createTempSync('bastion-ready-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (_) async => cache.path);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    var tests = 0;
    await tester.binding.setSurfaceSize(const Size(400, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      theme: BastionApp.appearance(Brightness.dark),
      home: TripReadinessPage(radio: radio, backgroundRestricted: () async => false, routeTest: (_) async => tests++),
    ));
    await tester.pumpAndSettle();
    for (final t in ['Radio battery', 'Firmware', 'Channels', 'Trip contacts', 'Position', 'Background']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(find.text('Not ready yet'), findsOneWidget, reason: 'no trip contacts chosen');
    expect(tests, 0);
  });
}
