import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/local_mesh_discovery_plan.dart';

void main() {
  test('accepts minimum and maximum dwell durations', () {
    final minimum = LocalMeshDiscoveryPlan(presets: [DiscoveryPreset.longFast], dwell: const Duration(minutes: 1));
    final maximum = LocalMeshDiscoveryPlan(presets: DiscoveryPreset.values, dwell: const Duration(minutes: 30));
    expect(minimum.estimatedListeningTime, const Duration(minutes: 1));
    expect(maximum.estimatedListeningTime, const Duration(minutes: 240));
  });

  test('preserves selection order and makes presets immutable', () {
    final selected = [DiscoveryPreset.shortSlow, DiscoveryPreset.longFast];
    final plan = LocalMeshDiscoveryPlan(presets: selected, dwell: const Duration(minutes: 2));
    selected.clear();
    expect(plan.presets, [DiscoveryPreset.shortSlow, DiscoveryPreset.longFast]);
    expect(() => plan.presets.clear(), throwsUnsupportedError);
  });
}
