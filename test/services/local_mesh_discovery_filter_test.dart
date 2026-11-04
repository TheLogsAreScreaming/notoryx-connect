import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/local_mesh_discovery_observation.dart';

void main() {
  test('filters stale and future observations, retaining boundary', () {
    final now = DateTime.utc(2026, 11, 3, 12);
    final results = recentDiscoveryObservations([
      DiscoveryObservation(nodeNumber: 1, lastHeard: now.subtract(const Duration(minutes: 11))),
      DiscoveryObservation(nodeNumber: 2, lastHeard: now.subtract(const Duration(minutes: 10))),
      DiscoveryObservation(nodeNumber: 3, lastHeard: now.add(const Duration(seconds: 1))),
    ], now: now, maxAge: const Duration(minutes: 10));
    expect(results.map((node) => node.nodeNumber).toList(), [2]);
  });

  test('rejects negative window', () {
    expect(() => recentDiscoveryObservations([], now: DateTime.utc(2026), maxAge: const Duration(seconds: -1)), throwsArgumentError);
  });
}
