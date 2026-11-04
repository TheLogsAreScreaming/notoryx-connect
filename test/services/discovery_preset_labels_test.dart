import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/local_mesh_discovery_plan.dart';

void main() {
  test('all eight discovery presets have unique user-facing labels', () {
    expect(DiscoveryPreset.values, hasLength(8));
    final labels = DiscoveryPreset.values.map((preset) => preset.label).toList();
    expect(labels.toSet(), hasLength(8));
    for (final label in labels) {
      expect(label.trim(), isNotEmpty);
    }
  });

  test('recommended presets are distinct supported choices', () {
    expect(LocalMeshDiscoveryPlan.recommended, hasLength(2));
    expect(LocalMeshDiscoveryPlan.recommended.toSet(), hasLength(2));
    for (final preset in LocalMeshDiscoveryPlan.recommended) {
      expect(DiscoveryPreset.values, contains(preset));
    }
  });
}
