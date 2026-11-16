import 'package:bastion/services/meshtastic_ble_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

MeshtasticBleDevice device(String name, [List<String> services = const []]) =>
    MeshtasticBleDevice(id: name, name: name, rssi: -60, advertisedServices: services);

void main() {
  test('Meshtastic radios are recognised by their service or their name', () {
    expect(device('Headphones', ['6BA1B218-15A8-461F-9FA8-5DCAE273EAFD']).looksLikeMeshtastic, isTrue);
    expect(device('SQCH_49cb').looksLikeMeshtastic, isTrue);
    expect(device('Meshtastic_1A2B').looksLikeMeshtastic, isTrue);
  });

  test('other Bluetooth devices are not offered as radios', () {
    for (final name in ['Unnamed BLE device', 'Galaxy Buds2 Pro', 'TV_Living', 'Watch_12345', 'Car_ab']) {
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
