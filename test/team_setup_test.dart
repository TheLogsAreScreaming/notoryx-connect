import 'package:bastion/generated/meshtastic/apponly.pb.dart';
import 'package:bastion/generated/meshtastic/channel.pb.dart';
import 'package:bastion/generated/meshtastic/config.pb.dart';
import 'package:bastion/services/bastion_team_setup.dart';
import 'package:bastion/services/bastion_trip.dart';
import 'package:flutter_test/flutter_test.dart';

ChannelSet _channels() => ChannelSet(
      settings: [
        ChannelSettings(name: 'Ridge', psk: List.generate(32, (i) => i)),
        ChannelSettings(name: 'Base', psk: List.generate(16, (i) => 100 + i)),
      ],
      loraConfig: Config_LoRaConfig(
        region: Config_LoRaConfig_RegionCode.US,
        usePreset: true,
        modemPreset: Config_LoRaConfig_ModemPreset.LONG_FAST,
      ),
    );

void main() {
  const plan = TripPlan(name: 'Ridge trip', members: [0x22, 0x33], overdueMinutes: 90, sosChannel: 1);
  String name(int n) => {0x10: 'Me', 0x22: 'Ridge Relay', 0x33: 'Camp'}[n] ?? '?';

  test('round-trips channels, LoRa settings, contacts and trip settings', () {
    final team = TeamSetup.from(channels: _channels(), plan: plan, nameOf: name, self: 0x10);
    final code = team.encode();
    expect(code, startsWith(TeamSetup.prefix));
    expect(code.length, lessThanOrEqualTo(TeamSetup.maxLength));
    final back = TeamSetup.decode(code);
    expect(back.channels.settings.map((s) => s.name), ['Ridge', 'Base']);
    expect(back.channels.settings.first.psk, List.generate(32, (i) => i));
    expect(back.channels.loraConfig.region, Config_LoRaConfig_RegionCode.US);
    expect(back.members.map((m) => m.num), [0x10, 0x22, 0x33], reason: 'you are included so they can reach you');
    expect(back.members.first.name, 'Me');
    expect(back.tripName, 'Ridge trip');
    expect(back.overdueMinutes, 90);
    expect(back.sosChannel, 1);
  });

  test('long names are shortened so the code fits one QR', () {
    final long = TeamSetup(
      channelLink: TeamSetup.from(channels: _channels(), plan: const TripPlan(), nameOf: name).channelLink,
      members: [for (var i = 1; i <= TripPlan.maxMembers; i++) (num: i, name: 'x' * 400)],
    );
    final code = long.encode();
    expect(code.length, lessThanOrEqualTo(TeamSetup.maxLength));
    expect(TeamSetup.decode(code).members.every((m) => m.name.length == TeamSetup.maxName), isTrue);
    expect(TeamSetup.decode(code).members, hasLength(TripPlan.maxMembers));
  });

  test('damaged or foreign codes are refused', () {
    expect(() => TeamSetup.decode('https://meshtastic.org/e/#abc'), throwsFormatException);
    expect(() => TeamSetup.decode('${TeamSetup.prefix}!!!'), throwsFormatException);
    expect(() => TeamSetup.decode('${TeamSetup.prefix}eyJ4IjoxfQ'), throwsFormatException, reason: 'no channels');
    expect(TeamSetup.looksLike('  ${TeamSetup.prefix}abc'), isTrue);
  });

  test('bad member numbers and settings are ignored, not trusted', () {
    final link = TeamSetup.from(channels: _channels(), plan: const TripPlan(), nameOf: name).channelLink;
    final odd = TeamSetup(channelLink: link, members: const [(num: 5, name: 'ok')], overdueMinutes: 99999, sosChannel: 42);
    final back = TeamSetup.decode(odd.encode());
    expect(back.overdueMinutes, 0);
    expect(back.sosChannel, -1);
  });

  test('merging adds new contacts only, never yourself, up to the limit', () {
    final team = TeamSetup.decode(TeamSetup.from(channels: _channels(), plan: plan, nameOf: name, self: 0x10).encode());
    // On the other phone, which is 0x22 and already has 0x33.
    const theirs = TripPlan(members: [0x33], overdueMinutes: 30, sosChannel: -1);
    final merged = team.mergeInto(theirs, self: 0x22);
    expect(merged.members, [0x33, 0x10]);
    expect(team.newMembers(theirs, self: 0x22), 1);
    expect(merged.overdueMinutes, 30, reason: 'your own settings are kept once you have contacts');

    final fresh = team.mergeInto(const TripPlan(), self: 0x44);
    expect(fresh.members, [0x10, 0x22, 0x33]);
    expect(fresh.overdueMinutes, 90, reason: 'a new trip takes the team settings');
    expect(fresh.sosChannel, 1);

    const full = TripPlan(members: [1, 2, 3, 4, 5]);
    expect(team.mergeInto(full).members, hasLength(TripPlan.maxMembers));
  });
}
