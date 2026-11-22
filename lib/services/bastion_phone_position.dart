import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' hide Position;

import '../generated/meshtastic/mesh.pb.dart';
import '../generated/meshtastic/portnums.pbenum.dart';
import 'bastion_geo.dart';

/// One location fix from the phone.
class PhoneFix {
  const PhoneFix({
    required this.latitude,
    required this.longitude,
    required this.time,
    this.altitudeMeters,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final DateTime time;
  final double? altitudeMeters;
  final double? accuracyMeters;
}

/// Phone location, behind an interface so sharing logic is testable.
abstract interface class PhoneLocationSource {
  /// Returns null when location can be used, otherwise why not.
  Future<String?> ensureAccess();

  /// Streams fixes; [lowPower] trades accuracy and frequency for battery.
  /// [background] keeps fixes coming with the screen off (a drive): on
  /// Android through a location service with its own notification, on iOS
  /// with the blue location indicator.
  Stream<PhoneFix> watch({bool lowPower = false, bool background = false});
}

class GeolocatorLocationSource implements PhoneLocationSource {
  /// Title of the Android notification shown while a drive records.
  static const driveNotificationTitle = 'Recording a drive';

  /// Text of that notification.
  static const driveNotificationText = 'NOTORYX Connect keeps logging what your radio hears while the screen is off.';

  /// Location settings for [watch]. Public for tests; [platform] defaults
  /// to the phone's.
  /// How often a drive asks for a fix on Android.
  static const driveInterval = Duration(seconds: 5);

  static LocationSettings settingsFor({required bool lowPower, required bool background, TargetPlatform? platform}) {
    final accuracy = lowPower ? LocationAccuracy.medium : LocationAccuracy.high;
    // A drive asks for a fix every few seconds even standing still: a
    // packet heard is only logged with a fix under 30 s old, and with a
    // distance filter a parked phone stops getting fixes at all.
    final distance = background ? 0 : (lowPower ? 100 : 25);
    if (!background || kIsWeb) return LocationSettings(accuracy: accuracy, distanceFilter: distance);
    return switch (platform ?? defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
          accuracy: accuracy,
          distanceFilter: distance,
          intervalDuration: driveInterval,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: driveNotificationTitle,
            notificationText: driveNotificationText,
            enableWakeLock: true,
            setOngoing: true,
          ),
        ),
      // Needs the "location" background mode, which only the iOS build has.
      TargetPlatform.iOS => AppleSettings(
          accuracy: accuracy,
          distanceFilter: distance,
          activityType: ActivityType.automotiveNavigation,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        ),
      _ => LocationSettings(accuracy: accuracy, distanceFilter: distance),
    };
  }

  @override
  Future<String?> ensureAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Turn on location services on this phone.';
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always || LocationPermission.whileInUse => null,
      LocationPermission.deniedForever =>
        'Location permission is blocked. Allow it for NOTORYX Connect in Android settings.',
      _ => 'Location permission was not granted.',
    };
  }

  @override
  Stream<PhoneFix> watch({bool lowPower = false, bool background = false}) => Geolocator.getPositionStream(
        locationSettings: settingsFor(lowPower: lowPower, background: background),
      ).map((p) => PhoneFix(
            latitude: p.latitude,
            longitude: p.longitude,
            altitudeMeters: p.altitude,
            accuracyMeters: p.accuracy,
            time: p.timestamp,
          ));
}

/// Sends the phone's location to the connected radio, which broadcasts it to
/// the mesh as its own position (when the radio has no GPS of its own).
///
/// Throttled: at most one update per [minInterval], plus one whenever the
/// phone moves more than [minDistanceMeters] after [movingInterval].
class BastionPhonePositionSharer {
  BastionPhonePositionSharer({
    required this.source,
    required this.send,
    required this.localNodeNum,
    this.lowPower = false,
    this.precisionBits = precise,
    Duration? minInterval,
    Duration? movingInterval,
    double? minDistanceMeters,
  }) : minInterval = minInterval ??
           (lowPower ? const Duration(minutes: 15) : const Duration(minutes: 5)),
       movingInterval = movingInterval ??
           (lowPower ? const Duration(minutes: 2) : const Duration(seconds: 30)),
       minDistanceMeters = minDistanceMeters ?? (lowPower ? 200 : 50);

  final PhoneLocationSource source;
  final Future<void> Function(Uint8List toRadio) send;
  final int localNodeNum;

  /// Low-power field mode: balanced GPS accuracy and fewer updates.
  final bool lowPower;

  /// Meshtastic position precision: how many leading bits of each
  /// coordinate are kept. [precise] (32) sends the exact fix.
  final int precisionBits;

  static const precise = 32;

  /// Choices offered to the user, with the approximate size in meters of the
  /// area the position is rounded to (Meshtastic's table); 0 is precise.
  static const precisionChoices = {32: 0, 16: 360, 14: 1500, 12: 6000};
  final Duration minInterval;
  final Duration movingInterval;
  final double minDistanceMeters;

  StreamSubscription<PhoneFix>? _subscription;
  PhoneFix? _lastSent;

  DateTime? get lastSentAt => _lastSent?.time;
  bool get isRunning => _subscription != null;

  /// Starts sharing. Returns an error message when location is unavailable.
  Future<String?> start() async {
    if (_subscription != null) return null;
    final problem = await source.ensureAccess();
    if (problem != null) return problem;
    _subscription = source.watch(lowPower: lowPower).listen(
      (fix) => unawaited(handleFix(fix)),
      onError: (Object _) {},
    );
    return null;
  }

  /// Sends [fix] if the throttle allows it. Public for tests.
  Future<void> handleFix(PhoneFix fix) async {
    final last = _lastSent;
    if (last != null) {
      final elapsed = fix.time.difference(last.time);
      final moved = BastionGeo.distanceMeters(
          last.latitude, last.longitude, fix.latitude, fix.longitude);
      final due = elapsed >= minInterval ||
          (moved >= minDistanceMeters && elapsed >= movingInterval);
      if (!due) return;
    }
    _lastSent = fix;
    await send(encode(fix, localNodeNum, precisionBits: precisionBits));
  }

  /// Encodes [fix] for the local radio. Below [precise], the coordinates are
  /// rounded here, before they leave the phone, and altitude is left out.
  static Uint8List encode(PhoneFix fix, int localNodeNum, {int precisionBits = precise}) {
    final exact = precisionBits >= precise;
    return ToRadio(
        packet: MeshPacket(
          to: localNodeNum,
          decoded: Data(
            portnum: PortNum.POSITION_APP,
            payload: Position(
              latitudeI: coarsen((fix.latitude * 1e7).round(), precisionBits),
              longitudeI: coarsen((fix.longitude * 1e7).round(), precisionBits),
              altitude: exact ? fix.altitudeMeters?.round() : null,
              time: fix.time.millisecondsSinceEpoch ~/ 1000,
              locationSource: Position_LocSource.LOC_EXTERNAL,
              precisionBits: exact ? null : precisionBits,
            ).writeToBuffer(),
          ),
        ),
      ).writeToBuffer();
  }

  /// Keeps the leading [bits] of a 32-bit coordinate and moves it to the
  /// middle of the remaining range, as Meshtastic firmware does.
  static int coarsen(int value, int bits) {
    if (bits >= precise) return value;
    final mask = (0xffffffff << (32 - bits)) & 0xffffffff;
    return ((value.toUnsigned(32) & mask) + (1 << (31 - bits))).toUnsigned(32).toSigned(32);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
