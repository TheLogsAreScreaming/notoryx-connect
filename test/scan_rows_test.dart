import 'package:bastion/main.dart';
import 'package:bastion/services/meshtastic_ble_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

const a = MeshtasticBleDevice(
  id: 'AA:BB',
  name: 'SQCH_49cb',
  rssi: -50,
  advertisedServices: [],
);
const b = MeshtasticBleDevice(
  id: 'CC:DD',
  name: 'Other',
  rssi: -70,
  advertisedServices: [],
);

void main() {
  test('the connected radio is not listed again under its card', () {
    expect(scanRowsBesideCard([a, b], connectedCard: true, linkId: 'AA:BB'), [
      b,
    ]);
  });

  test('everything is listed when no card is shown', () {
    expect(scanRowsBesideCard([a, b], connectedCard: false, linkId: 'AA:BB'), [
      a,
      b,
    ]);
    expect(scanRowsBesideCard([a, b], connectedCard: true, linkId: null), [
      a,
      b,
    ]);
  });

  test('a radio with the same name but a different id still shows', () {
    const twin = MeshtasticBleDevice(
      id: 'EE:FF',
      name: 'SQCH_49cb',
      rssi: -60,
      advertisedServices: [],
    );
    expect(
      scanRowsBesideCard([a, twin], connectedCard: true, linkId: 'AA:BB'),
      [twin],
    );
  });
}
