import 'dart:math' as math;

/// Pure offline geodesy helpers. No network connection or location permission needed.
abstract final class BastionGeo {
  static double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    for (final n in [lat1, lon1, lat2, lon2]) {
      if (!n.isFinite) throw ArgumentError('Coordinates must be finite');
    }
    if (lat1.abs() > 90 || lat2.abs() > 90 || lon1.abs() > 180 || lon2.abs() > 180) {
      throw ArgumentError('Invalid coordinates');
    }
    const radius = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
        math.pow(math.sin(dLon / 2), 2);
    return 2 * radius * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
  }

  /// Initial compass bearing from point 1 to point 2, in degrees 0–360.
  static double bearingDegrees(double lat1, double lon1, double lat2, double lon2) {
    final p1 = lat1 * math.pi / 180, p2 = lat2 * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(p2);
    final x = math.cos(p1) * math.sin(p2) - math.sin(p1) * math.cos(p2) * math.cos(dLon);
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  /// Eight-point compass label for [bearing] degrees (N, NE, E, …).
  static String compassPoint(double bearing) =>
      const ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'][((bearing % 360) / 45).round() % 8];
}
