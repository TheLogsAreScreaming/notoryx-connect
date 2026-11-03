import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/local_mesh_discovery_observation.dart';

void main() {
  test('keeps latest report per node and sorts newest first', () {
    final old = DateTime.utc(2026, 1, 1);
    final recent = old.add(const Duration(minutes: 1));
    final results = latestDiscoveryObservations([
      DiscoveryObservation(nodeNumber: 7, lastHeard: old, rssi: -90),
      DiscoveryObservation(nodeNumber: 8, lastHeard: old),
      DiscoveryObservation(nodeNumber: 7, lastHeard: recent, rssi: -70),
    ]);
    expect(results.length, 2);
    expect(results.first.nodeNumber, 7);
    expect(results.first.rssi, -70);
  });

  test('handles empty observations', () {
    expect(latestDiscoveryObservations([]), isEmpty);
  });
}
