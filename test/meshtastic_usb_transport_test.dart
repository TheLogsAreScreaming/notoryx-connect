import 'dart:async';
import 'dart:typed_data';

import 'package:bastion/main.dart';
import 'package:bastion/services/meshtastic_ble_discovery.dart';
import 'package:bastion/services/meshtastic_stream_transport.dart';
import 'package:bastion/services/meshtastic_usb_transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakePort implements UsbSerialPortHandle {
  final input$ = StreamController<Uint8List>();
  final written = <int>[];
  bool closed = false;
  @override
  Stream<Uint8List> get input => input$.stream;
  @override
  Future<void> write(Uint8List data) async => written.addAll(data);
  @override
  Future<void> close() async => closed = true;
}

class _FakeUsb implements UsbSerialGateway {
  _FakeUsb(this.devices);
  final List<UsbRadioInfo> devices;
  final port = _FakePort();
  final detach$ = StreamController<int>.broadcast();
  Object? openError;
  @override
  Future<List<UsbRadioInfo>> list() async => devices;
  @override
  Future<UsbSerialPortHandle> open(int deviceId) async {
    if (openError != null) throw openError!;
    return port;
  }

  @override
  Stream<int> get detached => detach$.stream;
}

void main() {
  test('USB radios carry their device id and skip the Bluetooth check', () {
    final d = MeshtasticBleDevice.usb(1003, 'Heltec V3');
    expect(d.isUsb, isTrue);
    expect(d.usbDeviceId, 1003);
    expect(d.usesBluetooth, isFalse);
    expect(MeshtasticBleDevice.network('10.0.0.2').usesBluetooth, isFalse);
    const ble = MeshtasticBleDevice(id: 'AA:BB', name: 'x', rssi: -50, advertisedServices: []);
    expect(ble.usesBluetooth, isTrue);
    expect(ble.usbDeviceId, isNull);
  });

  test('common radio USB chips are recognised', () {
    expect(const UsbRadioInfo(deviceId: 1, name: 'a', vendorId: 0x10C4).likelyRadio, isTrue);
    expect(const UsbRadioInfo(deviceId: 1, name: 'a', vendorId: 0x303A).chip, 'Espressif');
    expect(const UsbRadioInfo(deviceId: 1, name: 'mouse', vendorId: 0x046D).likelyRadio, isFalse);
  });

  test('the USB transport wakes the radio, frames packets and reports unplugging', () async {
    final usb = _FakeUsb(const []);
    final t = MeshtasticUsbTransport(deviceId: 7, gateway: usb, wakeDelay: Duration.zero);
    final received = <Uint8List>[];
    t.fromRadio.listen(received.add);
    final lost = Completer<void>();
    t.linkLost.listen((_) => lost.complete());
    await t.connect();
    expect(usb.port.written, List.filled(32, 0xC3), reason: 'wake-up bytes first');

    usb.port.written.clear();
    await t.sendToRadio(Uint8List.fromList([9, 8]));
    expect(usb.port.written, [0x94, 0xC3, 0, 2, 9, 8]);

    usb.port.input$.add(Uint8List.fromList([...'boot log\n'.codeUnits, ...MeshtasticStreamFramer.frame([1, 2])]));
    await Future<void>.delayed(Duration.zero);
    expect(received, [Uint8List.fromList([1, 2])]);

    usb.detach$.add(99);
    await Future<void>.delayed(Duration.zero);
    expect(t.isConnected, isTrue, reason: 'another device was unplugged');
    usb.detach$.add(7);
    await lost.future.timeout(const Duration(seconds: 1));
    expect(t.isConnected, isFalse);
    expect(usb.port.closed, isTrue);
  });

  test('a local disconnect is not a lost link, and open errors surface', () async {
    final usb = _FakeUsb(const []);
    final t = MeshtasticUsbTransport(deviceId: 7, gateway: usb, wakeDelay: Duration.zero);
    var lost = false;
    t.linkLost.listen((_) => lost = true);
    await t.connect();
    await t.disconnect();
    await usb.port.input$.close();
    await Future<void>.delayed(Duration.zero);
    expect(lost, isFalse);

    usb.openError = StateError('USB permission was not granted');
    final t2 = MeshtasticUsbTransport(deviceId: 8, gateway: usb, wakeDelay: Duration.zero);
    await expectLater(t2.connect(), throwsA(isA<StateError>()));
    expect(t2.isConnected, isFalse);
  });

  testWidgets('Nodes lists USB devices with likely radios first', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    BastionUsb.gateway = _FakeUsb(const [
      UsbRadioInfo(deviceId: 1, name: 'Logitech Receiver', vendorId: 0x046D),
      UsbRadioInfo(deviceId: 2, name: 'Silicon Labs CP2102', vendorId: 0x10C4),
    ]);
    addTearDown(() => BastionUsb.gateway = null);
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.hub_outlined).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect over USB'));
    await tester.pumpAndSettle();
    final radioY = tester.getTopLeft(find.text('Silicon Labs CP2102')).dy;
    final otherY = tester.getTopLeft(find.text('Logitech Receiver')).dy;
    expect(radioY, lessThan(otherY));
    expect(find.textContaining('Likely a radio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
