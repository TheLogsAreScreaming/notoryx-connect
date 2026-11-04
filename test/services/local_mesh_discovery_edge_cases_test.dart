import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/local_mesh_discovery_observation.dart';

void main() {
  test('equal timestamps sort by node number', () {
    final now = DateTime.utc(2026, 11, 3);
    final result = latestDiscoveryObservations([
      DiscoveryObservation(nodeNumber: 12, lastHeard: now),
      DiscoveryObservation(nodeNumber: 3, lastHeard: now),
    ]);
    expect(result.map((e) => e.nodeNumber).toList(), [3, 12]);
  });

  test('zero age includes now but excludes older reports', () {
    final now = DateTime.utc(2026, 11, 3);
    final result = recentDiscoveryObservations([
      DiscoveryObservation(nodeNumber: 1, lastHeard: now),
      DiscoveryObservation(nodeNumber: 2, lastHeard: now.subtract(const Duration(microseconds: 1))),
    ], now: now, maxAge: Duration.zero);
    expect(result.map((e) => e.nodeNumber).toList(), [1]);
  });
}
