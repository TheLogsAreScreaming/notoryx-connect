import 'dart:io';

import 'package:bastion/connection_doctor_page.dart';
import 'package:bastion/main.dart';
import 'package:bastion/services/bastion_bluetooth_state.dart';
import 'package:bastion/services/bastion_connection_doctor.dart';
import 'package:bastion/services/bastion_connection_log.dart';
import 'package:bastion/services/meshtastic_ble_discovery.dart';
import 'package:bastion/services/meshtastic_connection_controller.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _Bluetooth implements BluetoothAvailability {
  _Bluetooth(this.on);
  final bool on;
  @override
  Future<bool> isOn() async => on;
  @override
  Stream<bool> get changes => const Stream.empty();
}

DoctorCheck? checkOf(List<DoctorCheck> checks, String id) => checks.where((c) => c.id == id).firstOrNull;

void main() {
  group('classify', () {
    final cases = {
      'Bluetooth is off. NOTORYX Connect will reconnect': FailureCause.bluetoothOff,
      'PlatformException(permission denied)': FailureCause.permission,
      'GATT 133 error': FailureCause.pairedElsewhere,
      'Device is already connected to another device': FailureCause.pairedElsewhere,
      'TimeoutException after 0:00:20': FailureCause.timeout,
      'SocketException: Connection refused (OS Error)': FailureCause.network,
      'USB device detached': FailureCause.usb,
      'Radio link lost; reconnect gave up after 5 attempts': FailureCause.gaveUp,
      'Something odd': FailureCause.unknown,
    };
    for (final c in cases.entries) {
      test(c.key, () => expect(BastionConnectionDoctor.classify(c.key), c.value));
    }
  });

  group('diagnose', () {
    test('a healthy connection has no problems', () {
      final checks = BastionConnectionDoctor.diagnose(const DoctorFacts(
        state: MeshtasticConnectionState.ready,
        link: DoctorLink.bluetooth,
        radioName: 'T1000',
        bluetoothOn: true,
        permissionsGranted: true,
        batteryOptimized: false,
        firmwareVersion: '2.7.15.abc',
      ));
      expect(checks.where((c) => c.status == DoctorStatus.problem), isEmpty);
      expect(checkOf(checks, 'link')!.detail, contains('T1000'));
    });

    test('each problem comes with its own fix', () {
      final checks = BastionConnectionDoctor.diagnose(const DoctorFacts(
        state: MeshtasticConnectionState.error,
        link: DoctorLink.bluetooth,
        error: 'GATT 133',
        bluetoothOn: false,
        permissionsGranted: false,
        batteryOptimized: true,
      ));
      expect(checkOf(checks, 'bluetooth')!.fix, DoctorFix.turnOnBluetooth);
      expect(checkOf(checks, 'permission')!.fix, DoctorFix.grantPermission);
      expect(checkOf(checks, 'link')!.detail, contains('another phone'));
      expect(checkOf(checks, 'link')!.fix, DoctorFix.reconnect);
      expect(checkOf(checks, 'background')!.fix, DoctorFix.batterySettings);
    });

    test('no radios found after a scan', () {
      final checks = BastionConnectionDoctor.diagnose(
          const DoctorFacts(state: MeshtasticConnectionState.disconnected, scanned: true, bluetoothOn: true));
      expect(checkOf(checks, 'link')!.status, DoctorStatus.problem);
      expect(checkOf(checks, 'link')!.fix, DoctorFix.scan);
    });

    test('Wi-Fi and USB links skip the Bluetooth checks', () {
      for (final link in [DoctorLink.network, DoctorLink.usb]) {
        final checks = BastionConnectionDoctor.diagnose(DoctorFacts(state: MeshtasticConnectionState.ready, link: link));
        expect(checkOf(checks, 'bluetooth'), isNull);
        expect(checkOf(checks, 'permission'), isNull);
      }
    });

    test('old firmware is flagged with how to update', () {
      final checks = BastionConnectionDoctor.diagnose(
          const DoctorFacts(state: MeshtasticConnectionState.ready, link: DoctorLink.usb, firmwareVersion: '2.3.0'));
      expect(checkOf(checks, 'firmware')!.status, DoctorStatus.problem);
      expect(checkOf(checks, 'firmware')!.fix, DoctorFix.updateFirmware);
    });
  });

  test('the report holds the checks and the log', () {
    final log = BastionConnectionLog(clock: () => DateTime.utc(2026, 11, 8, 9))..add('error (Bluetooth): GATT 133');
    const facts = DoctorFacts(state: MeshtasticConnectionState.error, error: 'GATT 133', link: DoctorLink.bluetooth);
    final text = BastionConnectionDoctor.report(
      facts: facts,
      checks: BastionConnectionDoctor.diagnose(facts),
      log: log.entries,
      appVersion: '1.0.0+10',
    );
    expect(text, contains('NOTORYX Connect 1.0.0+10'));
    expect(text, contains('[problem] Radio link'));
    expect(text, contains('2026-11-08T09:00:00.000Z  error (Bluetooth): GATT 133'));
  });

  test('the log keeps only the newest entries', () {
    final log = BastionConnectionLog(capacity: 3);
    for (var i = 0; i < 5; i++) {
      log.add('event $i');
    }
    expect(log.entries.map((e) => e.text), ['event 2', 'event 3', 'event 4']);
  });

  group('page', () {
    setUp(() {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final cache = Directory.systemTemp.createTempSync('bastion-doctor-');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'), (_) async => cache.path);
    });

    testWidgets('shows the problem, logs it and copies a report', (tester) async {
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform,
          (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      final radio = MeshtasticRadioCoordinator();
      addTearDown(radio.dispose);
      final discovery = MeshtasticBleDiscovery();
      radio.connection.beginConnect('Trail T1000');
      radio.connection.fail(StateError('TimeoutException after 0:00:20'));
      await tester.pumpWidget(MaterialApp(
        theme: BastionApp.appearance(Brightness.dark),
        home: ConnectionDoctorPage(
          radio: radio,
          discovery: discovery,
          bluetooth: _Bluetooth(true),
          permissions: () async => true,
          batteryOptimized: () async => true,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('2 problems found'), findsOneWidget);
      expect(find.textContaining('didn\'t answer in time'), findsOneWidget);
      expect(radio.connectionLog.entries.map((e) => e.text), contains(contains('TimeoutException')));
      await tester.scrollUntilVisible(find.byKey(const ValueKey('copy-report')), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byKey(const ValueKey('copy-report')));
      await tester.pumpAndSettle();
      expect(copied, contains('[problem] Radio link'));
      expect(copied, contains('connecting'));
    });
  });
}
