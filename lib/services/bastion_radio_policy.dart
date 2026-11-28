import '../generated/meshtastic/config.pb.dart';

abstract final class BastionRadioPolicy {
  /// Region codes introduced in firmware 2.8. Older firmware does not
  /// understand them; a radio running 2.7 or earlier silently ignores them
  /// or uses a fallback, so we hide them when the connected firmware is old.
  static const _fw28Regions = {
    27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, // ITU amateur + EU-lite/narrow
  };

  /// Regions the connected firmware supports. Unknown firmware gets the full
  /// list (the user might still want to set it for a future upgrade).
  static List<Config_LoRaConfig_RegionCode> availableRegions(
      String? firmwareVersion) {
    final all = [
      for (final r in Config_LoRaConfig_RegionCode.values)
        if (r != Config_LoRaConfig_RegionCode.UNSET) r,
    ];
    if (firmwareVersion == null || firmwareAtLeast28(firmwareVersion))
      return all;
    return [
      for (final r in all) if (!_fw28Regions.contains(r.value)) r,
    ];
  }
  static const compatibilityNotice =
      'Radios using different bandwidths cannot '
      'hear each other. Coordinate frequency, bandwidth, spreading factor and '
      'coding rate with your mesh before changing settings.';

  static const usNotice =
      'For US operation in 902–928 MHz, FCC 47 CFR '
      '15.247(a)(2) specifies a minimum measured 6 dB bandwidth of 500 kHz '
      'for systems using digital modulation. This notice does not determine '
      'whether your setup is legal. Check your radio’s certification and '
      'applicable operating rules.';

  static bool firmwareAtLeast28(String? version) {
    final match = RegExp(r'^(\d+)\.(\d+)(?:\.|$)').firstMatch(version ?? '');
    if (match == null) return false;
    final major = int.parse(match[1]!);
    final minor = int.parse(match[2]!);
    return major > 2 || (major == 2 && minor >= 8);
  }

  // Firmware ModemPreset mappings; custom bandwidth is expressed in kHz.
  static double? bandwidthKhz(Config_LoRaConfig config) {
    if (!config.usePreset) {
      if (config.bandwidth == 0) return null;
      return switch (config.bandwidth) {
        31 => 31.25,
        62 => 62.5,
        _ => config.bandwidth.toDouble(),
      };
    }
    return switch (config.modemPreset.value) {
      0 || 3 || 4 || 5 || 6 || 7 => 250,
      1 || 2 || 10 || 11 => 125,
      8 || 9 || 16 => 500,
      12 || 13 => 62.5,
      14 || 15 => 20,
      _ => null,
    };
  }

  static bool showUsNotice(Config_LoRaConfig config) =>
      config.region == Config_LoRaConfig_RegionCode.US &&
      bandwidthKhz(config) != null &&
      bandwidthKhz(config)! < 500;

  /// Apply a setup suggestion only when an unconfigured radio chooses US.
  static void chooseRegion(
    Config_LoRaConfig draft,
    Config_LoRaConfig_RegionCode region,
    String? firmware,
  ) {
    final firstSetup = draft.region == Config_LoRaConfig_RegionCode.UNSET;
    draft.region = region;
    if (firstSetup &&
        region == Config_LoRaConfig_RegionCode.US &&
        firmwareAtLeast28(firmware)) {
      draft.usePreset = true;
      draft.modemPreset = Config_LoRaConfig_ModemPreset.LONG_TURBO;
    }
  }

  static bool canControlLna(Config_LoRaConfig config) =>
      config.hasFemLnaMode() &&
      (config.femLnaMode == Config_LoRaConfig_FEM_LNA_Mode.ENABLED ||
          config.femLnaMode == Config_LoRaConfig_FEM_LNA_Mode.DISABLED);
}
