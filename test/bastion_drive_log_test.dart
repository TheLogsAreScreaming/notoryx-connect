import 'dart:convert';
import 'dart:io';

import 'package:bastion/generated/meshtastic/mesh.pb.dart' as pb;
import 'package:bastion/services/bastion_drive_log.dart';
import 'package:bastion/services/bastion_phone_position.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final now = DateTime.utc(2026, 11, 22, 15);

PhoneFix fix({double lat = 35.2, double lon = -80.8, double accuracy = 8, Duration age = Duration.zero}) =>
    PhoneFix(latitude: lat, longitude: lon, time: now.subtract(age), accuracyMeters: accuracy);

pb.MeshPacket packet({
  int from = 0x1234abcd,
  int id = 1,
  double snr = -4.5,
  int rssi = -101,
  int hopStart = 3,
  int hopLimit = 3,
  int relay = 0,
  bool mqtt = false,
  Duration age = Duration.zero,
}) =>
    pb.MeshPacket(
      from: from,
      id: id,
      rxTime: now.subtract(age).millisecondsSinceEpoch ~/ 1000,
      rxSnr: snr,
      rxRssi: rssi,
      hopStart: hopStart,
      hopLimit: hopLimit,
      relayNode: relay,
      viaMqtt: mqtt,
    );

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  Future<BastionDriveLog> started() async {
    final log = BastionDriveLog();
    await log.load(useDatabase: false);
    await log.start(42, now: now);
    return log;
  }

  group('hop classes', () {
    test('equal start and limit is direct, fewer left is relayed', () {
      expect(classifyHops(3, 3), HopClass.direct);
      expect(classifyHops(7, 7), HopClass.direct);
      expect(classifyHops(3, 1), HopClass.relayed);
      expect(classifyHops(3, 0), HopClass.relayed);
    });

    test('firmware that leaves hop_start at 0 is unknown, not direct', () {
      expect(classifyHops(0, 0), HopClass.unknown);
      expect(classifyHops(0, 3), HopClass.unknown);
    });

    test('impossible values are unknown', () {
      expect(classifyHops(2, 5), HopClass.unknown);
      expect(classifyHops(3, -1), HopClass.unknown);
    });
  });

  group('recording', () {
    test('saves the phone position, signal, hops and relay byte', () async {
      final log = await started();
      expect(await log.observe(packet(hopStart: 3, hopLimit: 2, relay: 0xab), fix(), now), isTrue);
      final s = log.samples.single;
      expect((s.latitude, s.longitude, s.snr, s.rssi), (35.2, -80.8, -4.5, -101));
      expect((s.hops, s.hopStart, s.hopLimit, s.relayByte), (HopClass.relayed, 3, 2, 0xab));
      expect(s.trip, log.current!.id);
    });

    test('ignores MQTT, own, stale and poorly placed packets', () async {
      final log = await started();
      expect(await log.observe(packet(mqtt: true), fix(), now), isFalse);
      expect(await log.observe(packet(from: 42), fix(), now), isFalse);
      expect(await log.observe(packet(age: const Duration(minutes: 3)), fix(), now), isFalse);
      expect(await log.observe(packet(), fix(age: const Duration(seconds: 31)), now), isFalse);
      expect(await log.observe(packet(), fix(accuracy: 60), now), isFalse);
      expect(await log.observe(packet(), null, now), isFalse);
      expect(log.samples, isEmpty);
    });

    test('nothing is saved without a running drive', () async {
      final log = BastionDriveLog();
      await log.load(useDatabase: false);
      expect(await log.observe(packet(), fix(), now), isFalse);
    });

    test('one reading per node per 100 m square per minute, but every new square counts', () async {
      final log = await started();
      expect(await log.observe(packet(id: 1), fix(), now), isTrue);
      expect(await log.observe(packet(id: 2), fix(), now.add(const Duration(seconds: 10))), isFalse);
      // Another node in the same square is still logged.
      expect(await log.observe(packet(id: 3, from: 0x99), fix(), now.add(const Duration(seconds: 10))), isTrue);
      // Driving 300 m on logs the first node again straight away.
      expect(await log.observe(packet(id: 4), fix(lat: 35.2027), now.add(const Duration(seconds: 20))), isTrue);
      // Back in the first square after a minute.
      expect(await log.observe(packet(id: 5), fix(age: const Duration(seconds: -61)), now.add(const Duration(seconds: 61))), isTrue);
      expect(log.samples, hasLength(4));
    });

    test('stop ends the trip and later packets are not saved', () async {
      final log = await started();
      await log.stop(now: now.add(const Duration(minutes: 5)));
      expect(log.recording, isFalse);
      expect(log.trips.single.ended, now.add(const Duration(minutes: 5)));
      expect(await log.observe(packet(), fix(), now), isFalse);
    });

    test('a drive cannot be deleted while it runs', () async {
      final log = await started();
      expect(() => log.deleteTrip(log.current!.id), throwsStateError);
      await log.stop(now: now);
      await log.deleteTrip(log.trips.single.id);
      expect(log.trips, isEmpty);
    });
  });

  group('limits', () {
    test('the oldest finished trips go first, never the running one', () async {
      final log = BastionDriveLog();
      await log.load(useDatabase: false);
      for (var i = 0; i < BastionDriveLog.maxTrips + 3; i++) {
        await log.start(42, name: 'Drive $i', now: now.add(Duration(minutes: i)));
        await log.stop(now: now.add(Duration(minutes: i, seconds: 30)));
      }
      await log.start(42, name: 'Running', now: now.add(const Duration(days: 1)));
      expect(log.trips, hasLength(BastionDriveLog.maxTrips));
      expect(log.trips.first.name, 'Drive 4');
      expect(log.trips.last.name, 'Running');
    });
  });

  group('moving old readings over', () {
    Map<String, Object?> old(String time, {double lat = 35.2, Object? snr = -3}) =>
        {'kind': 'coverage', 'time': time, 'radio': 42, 'from': 7, 'packet': 1, 'lat': lat, 'lon': -80.8,
          'accuracy': 5.0, 'snr': snr, 'rssi': -99};

    test('coverage readings become one finished trip, once; notes stay put', () async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
        'bastion.field_log.v1': jsonEncode([
          old('2026-11-20T10:05:00Z'),
          old('2026-11-20T10:00:00Z'),
          {'kind': 'incident', 'time': '2026-11-20T10:01:00Z', 'note': 'Gate locked'},
        ]),
      });
      final store = MemoryDriveLogStore();
      final log = BastionDriveLog(store: store);
      await log.load(useDatabase: false);
      final trip = log.trips.single;
      expect((trip.name, trip.radio, trip.running), (BastionDriveLog.earlierTripName, 42, false));
      expect(trip.started, DateTime.utc(2026, 11, 20, 10));
      expect(trip.ended, DateTime.utc(2026, 11, 20, 10, 5));
      expect(log.samples.map((s) => s.hops).toSet(), {HopClass.unknown});
      expect(log.samples, hasLength(2));

      final again = BastionDriveLog(store: store);
      await again.load(useDatabase: false);
      expect(again.trips, hasLength(1));
      expect(again.samples, hasLength(2));
      expect(await SharedPreferencesAsync().getString('bastion.field_log.v1'), contains('Gate locked'));
    });

    test('unreadable old data is left alone', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({'bastion.field_log.v1': 'not json'});
      final log = BastionDriveLog();
      await log.load(useDatabase: false);
      expect(log.trips, isEmpty);
      expect(log.error, isNull);
    });
  });

  group('database', () {
    late Directory dir;
    setUpAll(sqfliteFfiInit);
    setUp(() async => dir = await Directory.systemTemp.createTemp('drives'));
    tearDown(() => dir.delete(recursive: true));

    test('trips and samples survive a restart; a drive left running is closed', () async {
      final path = '${dir.path}/drives.db';
      final log = BastionDriveLog();
      await log.load(factory: databaseFactoryFfi, path: path);
      await log.start(42, name: 'Ridge road', now: now);
      await log.observe(packet(hopStart: 3, hopLimit: 3), fix(), now);
      await log.observe(packet(from: 0x55, hopStart: 0, hopLimit: 0), fix(), now.add(const Duration(seconds: 5)));
      // No stop: the app was killed mid-drive.

      final reopened = BastionDriveLog();
      await reopened.load(factory: databaseFactoryFfi, path: path);
      expect(reopened.recording, isFalse);
      expect(reopened.trips.single.name, 'Ridge road');
      expect(reopened.trips.single.ended, now.add(const Duration(seconds: 5)));
      expect(reopened.samples.map((s) => s.hops), [HopClass.direct, HopClass.unknown]);

      await reopened.deleteTrip(reopened.trips.single.id);
      final emptied = BastionDriveLog();
      await emptied.load(factory: databaseFactoryFfi, path: path);
      expect(emptied.trips, isEmpty);
      expect(emptied.samples, isEmpty);
    });
  });

  test('CSV has one row per sample with the hop class', () async {
    final log = await started();
    await log.observe(packet(hopStart: 3, hopLimit: 1), fix(), now);
    final lines = log.exportCsv().trim().split('\r\n');
    expect(lines.first, startsWith('"trip"'.replaceAll('"', '')));
    expect(lines, hasLength(2));
    expect(lines.last, contains('"relayed"'));
  });
}
