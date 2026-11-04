import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/local_mesh_discovery_observation.dart';

void main() {
  final now = DateTime.utc(2026, 11, 3);

  test('latest observations are sorted and cannot be modified', () {
    final result = latestDiscoveryObservations([
      DiscoveryObservation(nodeNumber: 3, lastHeard: now),
      DiscoveryObservation(nodeNumber: 1, lastHeard: now),
    ]);
    expect(result.map((node) => node.nodeNumber).toList(), [1, 3]);
    expect(
      () => result.add(DiscoveryObservation(nodeNumber: 5, lastHeard: now)),
      throwsUnsupportedError,
    );
    expect(() => result.clear(), throwsUnsupportedError);
  });

  test('recent observations are immutable and reject future timestamps', () {
    final result = recentDiscoveryObservations([
      DiscoveryObservation(nodeNumber: 1, lastHeard: now),
      DiscoveryObservation(nodeNumber: 2, lastHeard: now.add(const Duration(seconds: 1))),
    ], now: now, maxAge: const Duration(minutes: 5));
    expect(result.map((node) => node.nodeNumber).toList(), [1]);
    expect(() => result.clear(), throwsUnsupportedError);
  });
}
