import 'dart:async';

import 'package:bastion/generated/meshtastic/mesh.pb.dart';
import 'package:bastion/generated/meshtastic/portnums.pbenum.dart';
import 'package:bastion/services/bastion_phone_position.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' hide Position;

class _FakeSource implements PhoneLocationSource {
  _FakeSource({this.problem});

  final String? problem;
  final fixes = StreamController<PhoneFix>.broadcast();
  final watchedLowPower = <bool>[];

  @override
  Future<String?> ensureAccess() async => problem;

  @override
  Stream<PhoneFix> watch({bool lowPower = false, bool background = false}) {
    watchedLowPower.add(lowPower);
    return fixes.stream;
  }
}

PhoneFix fix(double lat, double lon, int minute, {int second = 0}) => PhoneFix(
      latitude: lat,
      longitude: lon,
      altitudeMeters: 412.6,
      time: DateTime.utc(2026, 10, 9, 12, minute, second),
    );

void main() {
  late List<Uint8List> sent;
  late BastionPhonePositionSharer sharer;

  setUp(() {
    sent = [];
    sharer = BastionPhonePositionSharer(
      source: _FakeSource(),
      send: (bytes) async => sent.add(bytes),
      localNodeNum: 0x1234,
    );
  });

  test('encodes a local POSITION_APP packet from the phone', () async {
    await sharer.handleFix(fix(35.5, -83.25, 0));
    final packet = ToRadio.fromBuffer(sent.single).packet;
    expect(packet.to, 0x1234);
    expect(packet.decoded.portnum, PortNum.POSITION_APP);
    final position = Position.fromBuffer(packet.decoded.payload);
    expect(position.latitudeI, 355000000);
    expect(position.longitudeI, -832500000);
    expect(position.altitude, 413);
    expect(position.locationSource, Position_LocSource.LOC_EXTERNAL);
  });

  test('throttles stationary fixes to one per 5 minutes', () async {
    await sharer.handleFix(fix(35.5, -83.25, 0));
    await sharer.handleFix(fix(35.5, -83.25, 2));
    await sharer.handleFix(fix(35.50001, -83.25, 4));
    expect(sent, hasLength(1));
    await sharer.handleFix(fix(35.5, -83.25, 5));
    expect(sent, hasLength(2));
  });

  test('sends sooner after moving more than 50 m', () async {
    await sharer.handleFix(fix(35.5, -83.25, 0));
    await sharer.handleFix(fix(35.501, -83.25, 0, second: 10));
    expect(sent, hasLength(1), reason: 'too soon even though moved');
    await sharer.handleFix(fix(35.501, -83.25, 0, second: 40));
    expect(sent, hasLength(2));
  });

  test('reports why location cannot be used and does not start', () async {
    final blocked = BastionPhonePositionSharer(
      source: _FakeSource(problem: 'Location permission was not granted.'),
      send: (_) async {},
      localNodeNum: 1,
    );
    expect(await blocked.start(), 'Location permission was not granted.');
    expect(blocked.isRunning, isFalse);
  });

  group('low-power field mode', () {
    late BastionPhonePositionSharer lowPower;
    late _FakeSource source;

    setUp(() {
      source = _FakeSource();
      lowPower = BastionPhonePositionSharer(
        source: source,
        send: (bytes) async => sent.add(bytes),
        localNodeNum: 0x1234,
        lowPower: true,
      );
    });

    test('asks the location source for low-power fixes', () async {
      await lowPower.start();
      expect(source.watchedLowPower, [true]);
      await lowPower.stop();
      await sharer.start();
      await sharer.stop();
    });

    test('throttles stationary fixes to one per 15 minutes', () async {
      await lowPower.handleFix(fix(35.5, -83.25, 0));
      await lowPower.handleFix(fix(35.5, -83.25, 5));
      await lowPower.handleFix(fix(35.5, -83.25, 14));
      expect(sent, hasLength(1));
      await lowPower.handleFix(fix(35.5, -83.25, 15));
      expect(sent, hasLength(2));
    });

    test('needs 200 m and 2 minutes before sending early', () async {
      await lowPower.handleFix(fix(35.5, -83.25, 0));
      await lowPower.handleFix(fix(35.501, -83.25, 3));
      expect(sent, hasLength(1), reason: '~111 m is under 200 m');
      await lowPower.handleFix(fix(35.503, -83.25, 4));
      expect(sent, hasLength(2), reason: '~333 m after 4 minutes');
      await lowPower.handleFix(fix(35.506, -83.25, 5));
      expect(sent, hasLength(2), reason: '~333 m but only 1 minute later');
    });
  });

  group('location precision', () {
    test('precise keeps the exact fix and altitude', () {
      final p = Position.fromBuffer(ToRadio.fromBuffer(
          BastionPhonePositionSharer.encode(fix(35.123456, -83.654321, 0), 1)).packet.decoded.payload);
      expect(p.latitudeI, 351234560);
      expect(p.altitude, 413);
      expect(p.hasPrecisionBits(), isFalse);
    });

    test('approximate rounds before sending, drops altitude and sets precision', () {
      for (final bits in [16, 14, 12]) {
        final p = Position.fromBuffer(ToRadio.fromBuffer(BastionPhonePositionSharer.encode(
            fix(35.123456, -83.654321, 0), 1, precisionBits: bits)).packet.decoded.payload);
        final step = 1 << (32 - bits);
        expect(p.precisionBits, bits);
        expect(p.hasAltitude(), isFalse);
        expect((p.latitudeI - 351234560).abs(), lessThanOrEqualTo(step ~/ 2), reason: '$bits bits');
        expect((p.longitudeI + 836543210).abs(), lessThanOrEqualTo(step ~/ 2), reason: '$bits bits');
        expect(p.latitudeI, isNot(351234560));
      }
    });

    test('coarsening matches Meshtastic: keep leading bits, centre the cell', () {
      expect(BastionPhonePositionSharer.coarsen(351234560, 32), 351234560);
      expect(BastionPhonePositionSharer.coarsen(351234560, 16), ((351234560 & 0xffff0000) + 0x8000));
      final negative = BastionPhonePositionSharer.coarsen(-836543210, 16);
      expect(negative, ((-836543210).toUnsigned(32) & 0xffff0000) + 0x8000 - (1 << 32));
      expect(BastionPhonePositionSharer.coarsen(BastionPhonePositionSharer.coarsen(-836543210, 14), 14),
          BastionPhonePositionSharer.coarsen(-836543210, 14), reason: 'stable once rounded');
    });

    test('the sharer sends at its configured precision', () async {
      final coarse = BastionPhonePositionSharer(
          source: _FakeSource(), send: (b) async => sent.add(b), localNodeNum: 1, precisionBits: 14);
      await coarse.handleFix(fix(35.5, -83.25, 0));
      expect(Position.fromBuffer(ToRadio.fromBuffer(sent.single).packet.decoded.payload).precisionBits, 14);
    });
  });

  group('screen-off GPS for drives', () {
    LocationSettings settings(TargetPlatform platform, {bool background = true}) =>
        GeolocatorLocationSource.settingsFor(lowPower: false, background: background, platform: platform);

    test('Android runs a location service with an ongoing notification', () {
      final s = settings(TargetPlatform.android);
      expect(s, isA<AndroidSettings>());
      final config = (s as AndroidSettings).foregroundNotificationConfig!;
      expect(config.notificationTitle, GeolocatorLocationSource.driveNotificationTitle);
      expect((config.setOngoing, config.enableWakeLock), (true, true));
      expect((s.accuracy, s.distanceFilter), (LocationAccuracy.high, 0));
      expect(s.intervalDuration, GeolocatorLocationSource.driveInterval);
    });

    test('iOS keeps updating in the background with the indicator showing', () {
      final s = settings(TargetPlatform.iOS) as AppleSettings;
      expect(s.allowBackgroundLocationUpdates, isTrue);
      expect(s.showBackgroundLocationIndicator, isTrue);
      expect(s.pauseLocationUpdatesAutomatically, isFalse);
    });

    test('nothing runs in the background unless a drive asks for it', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        final s = settings(platform, background: false);
        expect(s, isNot(isA<AndroidSettings>()));
        expect(s, isNot(isA<AppleSettings>()));
        expect(s.distanceFilter, 25);
      }
      // macOS has no location background mode, so it never asks for one.
      expect(settings(TargetPlatform.macOS), isNot(isA<AppleSettings>()));
    });

    test('the Android and iOS builds declare what the service needs', () {
      final android = File('scripts/prepare_android.py').readAsStringSync();
      expect(android, contains('android.permission.FOREGROUND_SERVICE_LOCATION'));
      expect(android, isNot(contains('ACCESS_BACKGROUND_LOCATION')));
      final ios = File('scripts/prepare_ios.py').readAsStringSync();
      expect(ios, contains("'UIBackgroundModes': ['bluetooth-central', 'location']"));
    });
  });
}
