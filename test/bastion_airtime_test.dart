import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/generated/meshtastic/config.pb.dart';
import 'package:bastion/services/bastion_airtime.dart';

void main() {
  test('presets match the firmware table', () {
    final longFast = BastionAirtime.presetParams('LONG_FAST');
    expect([longFast.spreadingFactor, longFast.bandwidthKHz, longFast.codingRate], [11, 250, 5]);
    final longSlow = BastionAirtime.presetParams('LONG_SLOW');
    expect([longSlow.spreadingFactor, longSlow.bandwidthKHz, longSlow.codingRate], [12, 125, 8]);
    expect(BastionAirtime.presetParams('SHORT_TURBO', wide: true).bandwidthKHz, 1625);
    expect(BastionAirtime.presetParams('SOMETHING_NEW').spreadingFactor, 11);
  });

  test('LONG_FAST airtime is in the expected range', () {
    // A 50-byte packet on LongFast takes roughly 0.4 to 0.6 seconds.
    final t = BastionAirtime.timeOnAir(50, BastionAirtime.presetParams('LONG_FAST'));
    expect(t.inMilliseconds, inInclusiveRange(350, 650));
  });

  test('longer messages and slower presets take longer', () {
    final fast = BastionAirtime.presetParams('SHORT_FAST');
    final slow = BastionAirtime.presetParams('LONG_SLOW');
    expect(BastionAirtime.textMessage(100, fast) > BastionAirtime.textMessage(10, fast), isTrue);
    expect(BastionAirtime.textMessage(50, slow) > BastionAirtime.textMessage(50, fast), isTrue);
  });

  test('reads preset and custom settings from the radio config', () {
    final preset = Config_LoRaConfig(usePreset: true, modemPreset: Config_LoRaConfig_ModemPreset.MEDIUM_FAST);
    expect(BastionAirtime.fromConfig(preset)!.spreadingFactor, 9);
    final custom = Config_LoRaConfig(usePreset: false, spreadFactor: 10, bandwidth: 62, codingRate: 6);
    final p = BastionAirtime.fromConfig(custom)!;
    expect([p.spreadingFactor, p.bandwidthKHz, p.codingRate], [10, 62.5, 6]);
    expect(BastionAirtime.fromConfig(Config_LoRaConfig(usePreset: false)), isNull);
  });
}
