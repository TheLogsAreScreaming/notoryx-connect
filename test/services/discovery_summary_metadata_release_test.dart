import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/local_mesh_discovery_observation.dart';
import 'package:bastion/services/local_mesh_discovery_summary.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3);

  test('whitespace-only names are not counted', () {
    final summary = LocalMeshDiscoverySummary.fromObservations([
      DiscoveryObservation(nodeNumber: 1, lastHeard: now, name: '   '),
      DiscoveryObservation(nodeNumber: 2, lastHeard: now, name: ' Node '),
    ]);
    expect(summary.totalNodes, 2);
    expect(summary.withName, 1);
  });

  test('zero signal readings count as available telemetry', () {
    final summary = LocalMeshDiscoverySummary.fromObservations([
      DiscoveryObservation(nodeNumber: 1, lastHeard: now, snr: 0),
      DiscoveryObservation(nodeNumber: 2, lastHeard: now, rssi: 0),
      DiscoveryObservation(nodeNumber: 3, lastHeard: now),
    ]);
    expect(summary.withSignal, 2);
    expect(summary.totalNodes, 3);
  });
}
