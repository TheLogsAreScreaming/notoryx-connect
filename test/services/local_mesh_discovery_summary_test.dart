import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/local_mesh_discovery_observation.dart';
import 'package:bastion/services/local_mesh_discovery_summary.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 12);

  test('empty observation set produces zero counts', () {
    final summary = LocalMeshDiscoverySummary.fromObservations(const []);
    expect(summary.totalNodes, 0);
    expect(summary.withSignal, 0);
    expect(summary.withName, 0);
  });

  test('latest node observation determines signal and name counts', () {
    final summary = LocalMeshDiscoverySummary.fromObservations([
      DiscoveryObservation(nodeNumber: 7, lastHeard: now.subtract(const Duration(minutes: 5)), name: 'Old', snr: 3),
      DiscoveryObservation(nodeNumber: 7, lastHeard: now, name: '  '),
      DiscoveryObservation(nodeNumber: 8, lastHeard: now, name: 'Relay', rssi: -90),
      DiscoveryObservation(nodeNumber: 9, lastHeard: now, snr: 0),
    ]);
    expect(summary.totalNodes, 3);
    expect(summary.withSignal, 2);
    expect(summary.withName, 1);
  });
}
