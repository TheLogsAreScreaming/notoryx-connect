import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/local_mesh_discovery_plan.dart';

void main() {
  test('one preset at minimum dwell takes one minute', () {
    final plan = LocalMeshDiscoveryPlan(
      presets: [DiscoveryPreset.longFast],
      dwell: const Duration(minutes: 1),
    );
    expect(plan.estimatedListeningTime, const Duration(minutes: 1));
  });

  test('all eight presets at maximum dwell take four hours', () {
    final plan = LocalMeshDiscoveryPlan(
      presets: DiscoveryPreset.values,
      dwell: const Duration(minutes: 30),
    );
    expect(plan.estimatedListeningTime, const Duration(hours: 4));
  });

  test('duplicate presets do not increase estimated time', () {
    final plan = LocalMeshDiscoveryPlan(
      presets: [DiscoveryPreset.longFast, DiscoveryPreset.longFast],
      dwell: const Duration(minutes: 5),
    );
    expect(plan.presets, hasLength(1));
    expect(plan.estimatedListeningTime, const Duration(minutes: 5));
  });

  test('invalid dwell boundaries are rejected', () {
    for (final dwell in [Duration.zero, const Duration(seconds: 59), const Duration(minutes: 31)]) {
      expect(
        () => LocalMeshDiscoveryPlan(
          presets: [DiscoveryPreset.longFast], dwell: dwell,
        ),
        throwsArgumentError,
      );
    }
  });
}
