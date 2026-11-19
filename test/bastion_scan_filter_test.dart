import 'package:bastion/services/meshtastic_ble_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

MeshtasticBleDevice device(String name, [List<String> services = const []]) =>
    MeshtasticBleDevice(id: name, name: name, rssi: -60, advertisedServices: services);

void main() {
  test('Meshtastic radios are recognised by their service or their name', () {
    expect(device('Headphones', ['6BA1B218-15A8-461F-9FA8-5DCAE273EAFD']).looksLikeMeshtastic, isTrue);
    expect(device('SQCH_49cb').looksLikeMeshtastic, isTrue);
    expect(device('Meshtastic_1A2B').looksLikeMeshtastic, isTrue);
    // Short names can be lower case, one character or an emoji.
    for (final name in ['ab_00ff', 'X_1234', '🐻_c0de', 'N1_beef']) {
      expect(device(name).looksLikeMeshtastic, isTrue, reason: name);
    }
  });

  test('other Bluetooth devices are not offered as radios', () {
    for (final name in [
      'Unnamed BLE device',
      'Galaxy Buds2 Pro',
      'TV_Living',
      'Watch_12345',
      'Car_ab',
      // Smart lights whose names happen to end in "_" and four hex digits.
      'Govee_H6169_3A66',
      'Govee_H6167_3338',
      'ihoment_H6199_BEEF',
      'My Lamp_ABCD',
    ]) {
      expect(device(name, ['0000180f-0000-1000-8000-00805f9b34fb']).looksLikeMeshtastic, isFalse, reason: name);
    }
  });

  test('the list hides other devices until Show all is on', () {
    final discovery = MeshtasticBleDiscovery();
    addTearDown(discovery.dispose);
    expect(discovery.showAll, isFalse);
    expect(discovery.hiddenCount, 0);
    discovery.showAll = true;
    expect(discovery.showAll, isTrue);
  });
}
