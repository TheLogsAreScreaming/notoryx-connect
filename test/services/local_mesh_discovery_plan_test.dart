import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/local_mesh_discovery_plan.dart';

void main() {
  test('recommended presets match common public mesh choices', () {
    expect(LocalMeshDiscoveryPlan.recommended, [
      DiscoveryPreset.longFast,
      DiscoveryPreset.mediumFast,
    ]);
  });

  test('deduplicates presets and calculates listening duration', () {
    final plan = LocalMeshDiscoveryPlan(
      presets: [
        DiscoveryPreset.longFast,
        DiscoveryPreset.longFast,
        DiscoveryPreset.mediumFast,
      ],
      dwell: const Duration(minutes: 15),
    );
    expect(plan.presets.length, 2);
    expect(plan.estimatedListeningTime, const Duration(minutes: 30));
  });

  test('rejects empty selections and invalid dwell times', () {
    expect(
      () => LocalMeshDiscoveryPlan(
        presets: [],
        dwell: const Duration(minutes: 5),
      ),
      throwsArgumentError,
    );
    expect(
      () => LocalMeshDiscoveryPlan(
        presets: [DiscoveryPreset.longFast],
        dwell: Duration.zero,
      ),
      throwsArgumentError,
    );
    expect(
      () => LocalMeshDiscoveryPlan(
        presets: [DiscoveryPreset.longFast],
        dwell: const Duration(minutes: 31),
      ),
      throwsArgumentError,
    );
  });
}
