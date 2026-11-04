import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/local_mesh_discovery_observation.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3, 12);

  test('zero window accepts only exact current timestamp', () {
    final result = recentDiscoveryObservations([
      DiscoveryObservation(nodeNumber: 1, lastHeard: now),
      DiscoveryObservation(nodeNumber: 2, lastHeard: now.subtract(const Duration(microseconds: 1))),
    ], now: now, maxAge: Duration.zero);
    expect(result.map((node) => node.nodeNumber).toList(), [1]);
  });

  test('inclusive earliest boundary excludes older observations', () {
    final result = recentDiscoveryObservations([
      DiscoveryObservation(nodeNumber: 1, lastHeard: now.subtract(const Duration(minutes: 5))),
      DiscoveryObservation(nodeNumber: 2, lastHeard: now.subtract(const Duration(minutes: 5, microseconds: 1))),
    ], now: now, maxAge: const Duration(minutes: 5));
    expect(result.map((node) => node.nodeNumber).toList(), [1]);
  });

  test('negative recency window is rejected', () {
    expect(
      () => recentDiscoveryObservations([], now: now, maxAge: const Duration(seconds: -1)),
      throwsArgumentError,
    );
  });
}
