import '../generated/meshtastic/mesh.pb.dart' as pb;
import '../generated/meshtastic/mesh.pbenum.dart' as pbe;

enum GateStatus { available, unavailable, unknown }

/// Why a feature is or isn't offered.
enum GateReason {
  /// The radio reported its device info and nothing rules this out.
  reported,

  /// The radio hasn't sent its device info yet.
  noDeviceInfo,

  /// The firmware build left this module out (DeviceMetadata.excluded_modules).
  excludedFromBuild,

  /// The radio reported it lacks the hardware (no Bluetooth, no Wi-Fi...).
  noHardware,
}

class FeatureGate {
  const FeatureGate(this.status, this.reason);
  final GateStatus status;
  final GateReason reason;
  bool get unavailable => status == GateStatus.unavailable;

  static const unknown = FeatureGate(GateStatus.unknown, GateReason.noDeviceInfo);
  static const available = FeatureGate(GateStatus.available, GateReason.reported);
}

/// Per-feature support from what the radio reported about itself, instead
/// of one firmware version number for everything.
abstract final class BastionFeatureGates {
  /// A module settings page, by its AdminMessage.ModuleConfigType name
  /// (MQTT_CONFIG, TAK_CONFIG...), which matches ExcludedModules names.
  static FeatureGate module(String name, pb.DeviceMetadata? metadata) {
    if (metadata == null) return FeatureGate.unknown;
    if (_excluded(name, metadata)) {
      return const FeatureGate(GateStatus.unavailable, GateReason.excludedFromBuild);
    }
    return FeatureGate.available;
  }

  /// A radio settings page, by its AdminMessage.ConfigType name.
  static FeatureGate config(String name, pb.DeviceMetadata? metadata) {
    if (metadata == null) return FeatureGate.unknown;
    if (_excluded(name, metadata)) {
      return const FeatureGate(GateStatus.unavailable, GateReason.excludedFromBuild);
    }
    final hasHardware = switch (name) {
      'BLUETOOTH_CONFIG' => metadata.hasBluetooth,
      'NETWORK_CONFIG' => metadata.hasWifi || metadata.hasEthernet,
      _ => true,
    };
    return hasHardware
        ? FeatureGate.available
        : const FeatureGate(GateStatus.unavailable, GateReason.noHardware);
  }

  /// Public-key (PKI) direct messages.
  static FeatureGate pki(pb.DeviceMetadata? metadata) {
    if (metadata == null) return FeatureGate.unknown;
    return metadata.hasPKC
        ? FeatureGate.available
        : const FeatureGate(GateStatus.unavailable, GateReason.noHardware);
  }

  static bool _excluded(String name, pb.DeviceMetadata metadata) {
    for (final bit in pbe.ExcludedModules.values) {
      if (bit.name == name && bit.value != 0) {
        return metadata.excludedModules & bit.value != 0;
      }
    }
    return false;
  }
}
