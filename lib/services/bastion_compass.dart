import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// One compass reading: degrees clockwise from magnetic north, and the
/// sensor's accuracy from 0 (unreliable) to 3 (high).
typedef HeadingReading = ({double heading, int accuracy});

/// Where compass headings come from. Tests replace it.
abstract interface class CompassSource {
  /// Whether this device has a compass the app can read.
  Future<bool> available();

  /// Headings, about 20 a second, while listened to.
  Stream<HeadingReading> headings();

  /// Degrees east of true north that magnetic north lies at a point, or
  /// null when it can't be worked out.
  Future<double?> declination(double latitude, double longitude);
}

/// The Android rotation-vector compass (HeadingStream.kt). Other platforms
/// report none, and the page falls back to a north-up arrow.
class DeviceCompass implements CompassSource {
  const DeviceCompass();

  static const _events = EventChannel('notoryx/heading');
  static const _methods = MethodChannel('notoryx/compass');

  @override
  Future<bool> available() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _methods.invokeMethod<bool>('available') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Stream<HeadingReading> headings() => _events.receiveBroadcastStream().map((event) {
        final map = event as Map<Object?, Object?>;
        return (
          heading: (map['heading']! as num).toDouble(),
          accuracy: (map['accuracy'] as num?)?.toInt() ?? 2,
        );
      });

  @override
  Future<double?> declination(double latitude, double longitude) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _methods.invokeMethod<double>('declination', {'lat': latitude, 'lon': longitude});
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

/// The sums for pointing the phone at a node.
abstract final class BastionCompass {
  /// Turns within this many degrees either side count as on target.
  static const onTargetDegrees = 10.0;

  /// [degrees] brought into 0 (inclusive) to 360 (exclusive).
  static double normalise(double degrees) {
    final d = degrees % 360;
    return d < 0 ? d + 360 : d;
  }

  /// How far to turn from facing [heading] to face [bearing]: negative is
  /// left, positive is right, never more than 180 either way.
  static double turn(double heading, double bearing) {
    final d = normalise(bearing - heading);
    return d > 180 ? d - 360 : d;
  }

  /// Moves [previous] a [factor] of the way towards [next], the short way
  /// round, so 359° to 1° passes through 0° rather than 180°.
  static double smooth(double? previous, double next, {double factor = 0.25}) {
    if (previous == null) return normalise(next);
    return normalise(previous + turn(previous, next) * factor);
  }

  /// Whether facing [heading] counts as pointing at [bearing].
  static bool onTarget(double heading, double bearing) => turn(heading, bearing).abs() <= onTargetDegrees;
}
