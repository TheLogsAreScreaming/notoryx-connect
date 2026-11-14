import 'dart:math' as math;

import '../generated/meshtastic/config.pb.dart';

/// LoRa settings that decide how long a packet stays on air.
class LoRaParams {
  const LoRaParams({required this.spreadingFactor, required this.bandwidthKHz, required this.codingRate});

  final int spreadingFactor;
  final double bandwidthKHz;

  /// 5..8, meaning 4/5..4/8.
  final int codingRate;
}

/// Airtime estimates for text messages, using the same preset table and
/// 16-symbol preamble as the radio firmware.
abstract final class BastionAirtime {
  /// Bytes a text message adds beyond its text: packet header, data
  /// envelope and, for direct messages, the encryption tag. An estimate.
  static const messageOverheadBytes = 28;

  static const preambleSymbols = 16;

  /// The settings a preset uses. [wide] is the 2.4 GHz band, which uses
  /// wider channels. Unknown presets fall back to LONG_FAST, as the firmware does.
  static LoRaParams presetParams(String presetName, {bool wide = false}) {
    switch (presetName) {
      case 'SHORT_TURBO':
        return LoRaParams(spreadingFactor: 7, bandwidthKHz: wide ? 1625 : 500, codingRate: 5);
      case 'SHORT_FAST':
        return LoRaParams(spreadingFactor: 7, bandwidthKHz: wide ? 812.5 : 250, codingRate: 5);
      case 'SHORT_SLOW':
        return LoRaParams(spreadingFactor: 8, bandwidthKHz: wide ? 812.5 : 250, codingRate: 5);
      case 'MEDIUM_FAST':
        return LoRaParams(spreadingFactor: 9, bandwidthKHz: wide ? 812.5 : 250, codingRate: 5);
      case 'MEDIUM_SLOW':
        return LoRaParams(spreadingFactor: 10, bandwidthKHz: wide ? 812.5 : 250, codingRate: 5);
      case 'MEDIUM_TURBO':
        return LoRaParams(spreadingFactor: 9, bandwidthKHz: wide ? 1625 : 500, codingRate: 5);
      case 'LONG_TURBO':
        return LoRaParams(spreadingFactor: 11, bandwidthKHz: wide ? 1625 : 500, codingRate: 8);
      case 'LONG_MODERATE':
        return LoRaParams(spreadingFactor: 11, bandwidthKHz: wide ? 406.25 : 125, codingRate: 8);
      case 'LONG_SLOW':
        return LoRaParams(spreadingFactor: 12, bandwidthKHz: wide ? 406.25 : 125, codingRate: 8);
      case 'LITE_FAST':
        return const LoRaParams(spreadingFactor: 9, bandwidthKHz: 125, codingRate: 5);
      case 'LITE_SLOW':
        return const LoRaParams(spreadingFactor: 10, bandwidthKHz: 125, codingRate: 5);
      case 'NARROW_FAST':
        return const LoRaParams(spreadingFactor: 7, bandwidthKHz: 62.5, codingRate: 6);
      case 'NARROW_SLOW':
        return const LoRaParams(spreadingFactor: 8, bandwidthKHz: 62.5, codingRate: 6);
      case 'TINY_FAST':
        return const LoRaParams(spreadingFactor: 7, bandwidthKHz: 15.6, codingRate: 5);
      case 'TINY_SLOW':
        return const LoRaParams(spreadingFactor: 8, bandwidthKHz: 15.6, codingRate: 6);
      default:
        return LoRaParams(spreadingFactor: 11, bandwidthKHz: wide ? 812.5 : 250, codingRate: 5);
    }
  }

  /// The settings [lora] puts the radio on, or null if they make no sense.
  static LoRaParams? fromConfig(Config_LoRaConfig lora) {
    final wide = lora.region == Config_LoRaConfig_RegionCode.LORA_24;
    if (lora.usePreset) return presetParams(lora.modemPreset.name, wide: wide);
    final sf = lora.spreadFactor;
    final cr = lora.codingRate;
    final bw = switch (lora.bandwidth) { 31 => 31.25, 62 => 62.5, 200 => 203.125, 400 => 406.25, 800 => 812.5, 1600 => 1625.0, final b => b.toDouble() };
    if (sf < 5 || sf > 12 || bw <= 0 || cr < 5 || cr > 8) return null;
    return LoRaParams(spreadingFactor: sf, bandwidthKHz: bw, codingRate: cr);
  }

  /// Time on air for a LoRa packet of [payloadBytes] (Semtech formula,
  /// explicit header, CRC on).
  static Duration timeOnAir(int payloadBytes, LoRaParams p) {
    final sf = p.spreadingFactor;
    final tsymMs = (1 << sf) / p.bandwidthKHz;
    final de = tsymMs > 16.0 ? 1 : 0;
    final numerator = 8 * math.max(payloadBytes, 0) - 4 * sf + 28 + 16;
    final payloadSymbols = math.max((numerator / (4 * (sf - 2 * de))).ceil() * p.codingRate, 0);
    final ms = (preambleSymbols + 4.25) * tsymMs + (8 + payloadSymbols) * tsymMs;
    return Duration(microseconds: (ms * 1000).round());
  }

  /// Approximate airtime of a text message with [textBytes] of UTF-8 text.
  static Duration textMessage(int textBytes, LoRaParams p) =>
      timeOnAir(textBytes + messageOverheadBytes, p);
}
