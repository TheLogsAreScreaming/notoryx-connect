import 'package:bastion/map_page.dart';
import 'package:bastion/services/bastion_geo.dart';
import 'package:bastion/services/bastion_team.dart';
import 'package:bastion/services/bastion_trails.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class FlakyStore extends InMemorySharedPreferencesAsync {
  FlakyStore() : super.empty();
  bool failReads = false;
  int writes = 0;
  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) async {
    if (failReads) throw StateError('read failed');
    return super.getString(key, options);
  }
  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) async {
    writes++;
    return super.setString(key, value, options);
  }
}

MeshtasticNode at(int num, double lat, double lon, {DateTime? heard, int? battery}) => MeshtasticNode(
    num: num, longName: 'Node $num', latitude: lat, longitude: lon,
    positionTime: heard, lastHeard: heard, batteryLevel: battery);

void main() {
  late FlakyStore store;
  setUp(() {
    store = FlakyStore();
    SharedPreferencesAsyncPlatform.instance = store;
  });

  group('geo', () {
    test('bearing and compass point', () {
      expect(BastionGeo.bearingDegrees(0, 0, 1, 0), closeTo(0, 0.01));
      expect(BastionGeo.bearingDegrees(0, 0, 0, 1), closeTo(90, 0.01));
      expect(BastionGeo.bearingDegrees(0, 0, -1, 0), closeTo(180, 0.01));
      expect(BastionGeo.compassPoint(44), 'NE');
      expect(BastionGeo.compassPoint(359), 'N');
      expect(BastionGeo.compassPoint(225), 'SW');
    });
  });

  group('team status', () {
    final now = DateTime.utc(2026, 10, 28, 12);
    final me = at(1, 35.0, -83.0, heard: now);

    test('freshness follows how recently a contact was heard', () {
      TeamFreshness f(Duration ago) => TeamMemberStatus.of(2, at(2, 35, -83, heard: now.subtract(ago)), now: now).freshness;
      expect(f(const Duration(minutes: 15)), TeamFreshness.fresh);
      expect(f(const Duration(minutes: 16)), TeamFreshness.stale);
      expect(f(const Duration(minutes: 61)), TeamFreshness.lost);
      expect(TeamMemberStatus.of(2, null, now: now).freshness, TeamFreshness.unknown);
    });

    test('summary gives age, distance, bearing and battery in plain words', () {
      final s = TeamMemberStatus.of(2, at(2, 35.01, -83.0, heard: now.subtract(const Duration(minutes: 4)), battery: 80),
          me: me, battery: 63, now: now);
      expect(s.summary, 'Heard 4 min ago • position 4 min old • 1.1 km N • battery 63%');
      expect(TeamMemberStatus.of(3, const MeshtasticNode(num: 3, batteryLevel: 101), now: now).summary,
          'Not heard yet • no position', reason: 'external power (101) is not a battery level');
    });

    test('labels', () {
      expect(TeamMemberStatus.ageLabel(const Duration(seconds: 30)), 'just now');
      expect(TeamMemberStatus.ageLabel(const Duration(hours: 3)), '3 h');
      expect(TeamMemberStatus.distanceLabel(850.4), '850 m');
      expect(TeamMemberStatus.distanceLabel(2440), '2.4 km');
    });
  });

  group('trails', () {
    late DateTime now;
    late BastionTrails trails;
    setUp(() async {
      now = DateTime.utc(2026, 10, 28, 12);
      trails = BastionTrails(clock: () => now);
      await trails.useRadio(0xA1);
    });

    test('records only tracked nodes that moved at least 15 m', () {
      expect(trails.record([at(2, 35, -83), at(9, 35, -83)], {2}), isTrue);
      expect(trails.record([at(2, 35.00005, -83)], {2}), isFalse, reason: 'about 6 m');
      expect(trails.record([at(2, 35.0002, -83)], {2}), isTrue, reason: 'about 22 m');
      expect(trails.trailOf(2), hasLength(2));
      expect(trails.trailOf(9), isEmpty);
    });

    test('keeps 24 hours and at most 300 points', () {
      for (var i = 0; i < 310; i++) {
        trails.record([at(2, 35 + i * 0.001, -83)], {2});
      }
      expect(trails.trailOf(2), hasLength(BastionTrails.maxPoints));
      now = now.add(const Duration(hours: 25));
      trails.record([at(2, 40, -83)], {2});
      expect(trails.trailOf(2), hasLength(1));
    });

    test('saves at most every 30 s, flushes the rest, and keeps radios apart', () async {
      trails.record([at(2, 35, -83)], {2});
      await pumpEventQueue();
      trails.record([at(2, 35.001, -83)], {2});
      await pumpEventQueue();
      expect(store.writes, 1, reason: 'second point within 30 s is not written yet');
      await trails.useRadio(0xB2);
      expect(store.writes, 2, reason: 'switching radios flushes the pending point');
      expect(trails.trailOf(2), isEmpty);
      final reloaded = BastionTrails(clock: () => now);
      await reloaded.useRadio(0xA1);
      expect(reloaded.trailOf(2), hasLength(2));
    });

    test('unreadable storage is never overwritten', () async {
      store.failReads = true;
      final t = BastionTrails(clock: () => now);
      await t.useRadio(0xC3);
      t.record([at(2, 35, -83)], {2});
      await t.flush();
      expect(store.writes, 0);
    });
  });

  testWidgets('the Team sheet explains how to add trip contacts', (tester) async {
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MapPage(radio: radio))));
    await tester.pump();
    await tester.tap(find.byTooltip('Team'));
    await tester.pumpAndSettle();
    expect(find.text('No trip contacts yet'), findsOneWidget);
  });
}
