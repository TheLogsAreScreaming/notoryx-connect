import 'dart:async';

import 'package:bastion/services/bastion_background_service.dart';
import 'package:bastion/services/bastion_bluetooth_state.dart';
import 'package:bastion/services/bastion_last_link.dart';
import 'package:bastion/services/meshtastic_ble_discovery.dart';
import 'package:bastion/services/meshtastic_connection_controller.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _OffBluetooth implements BluetoothAvailability {
  @override
  Future<bool> isOn() async => false;
  @override
  Stream<bool> get changes => const Stream.empty();
}

class _NoKeeper implements BastionBackgroundKeeper {
  @override
  Future<void> keepAlive({
    required String radioName,
    required bool reconnecting,
  }) async {}
  @override
  Future<void> release() async {}
}

const ble = MeshtasticBleDevice(
  id: 'AA:BB',
  name: 'Trail Radio',
  rssi: -60,
  advertisedServices: [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BastionLastLink link;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    link = BastionLastLink();
  });

  group('the saved radio', () {
    test('round-trips Bluetooth and network radios', () async {
      expect(await link.load(), isNull);
      await link.save(ble);
      final got = (await link.load())!;
      expect((got.id, got.name), ('AA:BB', 'Trail Radio'));
      await link.save(MeshtasticBleDevice.network('10.0.0.5'));
      expect((await link.load())!.networkAddress, (
        host: '10.0.0.5',
        port: 4403,
      ));
    });

    test(
      'never keeps a USB radio, whose id changes on every plug-in',
      () async {
        await link.save(ble);
        await link.save(MeshtasticBleDevice.usb(1002, 'USB radio'));
        expect((await link.load())!.id, 'AA:BB');
        await SharedPreferencesAsync().setString(
          BastionLastLink.key,
          '{"id":"usb:7","name":"x"}',
        );
        expect(await link.load(), isNull);
      },
    );

    test('is forgotten on clear and survives junk', () async {
      await link.save(ble);
      await link.clear();
      expect(await link.load(), isNull);
      await SharedPreferencesAsync().setString(BastionLastLink.key, 'not json');
      expect(await link.load(), isNull);
      await SharedPreferencesAsync().setString(
        BastionLastLink.key,
        '{"id":"","name":"x"}',
      );
      expect(await link.load(), isNull);
    });
  });

  group('reconnecting at launch', () {
    late MeshtasticRadioCoordinator radio;

    setUp(() {
      radio = MeshtasticRadioCoordinator(
        background: _NoKeeper(),
        bluetooth: _OffBluetooth(),
        lastLink: link,
      );
    });

    tearDown(() async {
      await radio.disconnect();
      radio.dispose();
    });

    test('does nothing when no radio was saved', () async {
      expect(await radio.reconnectAtLaunch(), isFalse);
      expect(radio.hasLastRadio, isFalse);
      expect(radio.connection.state, MeshtasticConnectionState.disconnected);
    });

    test('picks the saved radio up again and waits for Bluetooth', () async {
      await link.save(ble);
      expect(await radio.reconnectAtLaunch(), isTrue);
      await pumpEventQueue();
      expect(radio.hasLastRadio, isTrue);
      expect(radio.isReconnecting, isTrue);
      expect(radio.connection.error, contains('Trail Radio'));
      // Only once per launch.
      expect(await radio.reconnectAtLaunch(), isFalse);
    });

    test('a user disconnect forgets the radio for next launch', () async {
      await link.save(ble);
      await radio.reconnectAtLaunch();
      await radio.disconnect();
      await pumpEventQueue();
      expect(await link.load(), isNull);
    });
  });
}
