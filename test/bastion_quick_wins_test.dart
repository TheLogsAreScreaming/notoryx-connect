import 'package:bastion/generated/meshtastic/mesh.pb.dart' as pb;
import 'package:bastion/services/bastion_heard_filter.dart';
import 'package:bastion/services/bastion_preferences.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('last heard filter', () {
    final now = DateTime(2026, 11, 8, 12);
    test('windows', () {
      final twoHoursAgo = now.subtract(const Duration(hours: 2));
      expect(BastionHeardWithin.any.matches(null, now), isTrue);
      expect(BastionHeardWithin.hour.matches(twoHoursAgo, now), isFalse);
      expect(BastionHeardWithin.day.matches(twoHoursAgo, now), isTrue);
      expect(BastionHeardWithin.week.matches(now.subtract(const Duration(days: 8)), now), isFalse);
    });
    test('never-heard nodes hide, your own radio always shows', () {
      expect(BastionHeardWithin.day.matches(null, now), isFalse);
      expect(BastionHeardWithin.hour.matches(null, now, always: true), isTrue);
    });
    test('the choice is saved', () async {
      await BastionPreferences().update(heard: BastionHeardWithin.day);
      final loaded = BastionPreferences();
      await loaded.load();
      expect(loaded.heardWithin, BastionHeardWithin.day);
      expect(BastionHeardWithin.fromName('nonsense'), BastionHeardWithin.any);
    });
  });

  group('no fake RF data', () {
    pb.MeshPacket packet({double snr = 6.5, int hopStart = 3, int hopLimit = 3, bool mqtt = false}) =>
        pb.MeshPacket(rxSnr: snr, hopStart: hopStart, hopLimit: hopLimit, viaMqtt: mqtt);

    test('only direct radio packets give an SNR', () {
      expect(MeshtasticNodeInfoCodec.directSnr(packet()), 6.5);
      expect(MeshtasticNodeInfoCodec.directSnr(packet(hopStart: 0, hopLimit: 0)), 6.5, reason: 'old firmware, no hop_start');
      expect(MeshtasticNodeInfoCodec.directSnr(packet(hopLimit: 1)), isNull, reason: 'relayed');
      expect(MeshtasticNodeInfoCodec.directSnr(packet(mqtt: true)), isNull, reason: 'MQTT');
      expect(MeshtasticNodeInfoCodec.directSnr(packet(snr: 0)), isNull, reason: 'no reading');
    });

    test('NodeInfo zeros become no reading, with a reason', () {
      final relayed = MeshtasticNodeInfoCodec.fromProto(pb.NodeInfo(num: 1, snr: 0, hopsAway: 2));
      expect(relayed.snr, isNull);
      expect(relayed.noRfReason, 'No RF data: heard through relays');

      final mqtt = MeshtasticNodeInfoCodec.fromProto(pb.NodeInfo(num: 2, snr: 4, viaMqtt: true));
      expect(mqtt.snr, isNull);
      expect(mqtt.noRfReason, 'No RF data: heard over MQTT');

      final direct = MeshtasticNodeInfoCodec.fromProto(pb.NodeInfo(num: 3, snr: -7.25, hopsAway: 0));
      expect(direct.snr, -7.25);
      expect(direct.noRfReason, isNull);

      expect(MeshtasticNodeInfoCodec.fromProto(pb.NodeInfo(num: 4)).noRfReason, 'No RF data yet');
    });
  });
}
