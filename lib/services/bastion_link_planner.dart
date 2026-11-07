import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'bastion_geo.dart';

/// One sample along a link: distance from the start and ground height.
class ProfilePoint {
  const ProfilePoint(this.distanceMeters, this.groundMeters);
  final double distanceMeters;
  final double groundMeters;
}

/// Whether a radio link can see past the ground in between.
enum LinkVerdict {
  /// The direct line and most of the Fresnel zone are clear.
  clear,

  /// The direct line is clear but terrain eats into the Fresnel zone, so
  /// the signal is weakened.
  marginal,

  /// Terrain blocks the direct line.
  blocked,
}

/// The result of checking a link between two points.
class LinkAnalysis {
  const LinkAnalysis({
    required this.distanceMeters,
    required this.pathLossDb,
    required this.verdict,
    required this.worstClearanceMeters,
    required this.worstAtMeters,
    required this.profile,
    required this.lineStart,
    required this.lineEnd,
  });

  final double distanceMeters;

  /// Free-space path loss at the chosen frequency, in dB.
  final double pathLossDb;
  final LinkVerdict verdict;

  /// Smallest gap between the line of sight and the (curvature-adjusted)
  /// ground; negative when the ground is in the way.
  final double worstClearanceMeters;

  /// Where along the link that smallest gap is.
  final double worstAtMeters;

  /// Ground heights along the link, with earth curvature added in.
  final List<ProfilePoint> profile;

  /// Antenna heights above sea level at each end.
  final double lineStart;
  final double lineEnd;
}

/// Line-of-sight and Fresnel-zone checks for a LoRa link. Pure maths: the
/// ground heights come from an [ElevationSource].
abstract final class BastionLinkPlanner {
  /// Effective earth radius for radio (4/3 of the real one), in metres.
  static const effectiveEarthRadius = 6371000.0 * 4 / 3;

  /// Samples taken along a link; the elevation service takes up to 100.
  static const samples = 64;

  /// Common LoRa bands, in MHz.
  static const bands = [(915.0, '915 MHz (Americas)'), (868.0, '868 MHz (Europe)'), (433.0, '433 MHz')];

  /// Points spaced evenly from start to end, inclusive.
  static List<({double latitude, double longitude})> samplePoints(
      double lat1, double lon1, double lat2, double lon2, [int count = samples]) => [
        for (var i = 0; i < count; i++)
          (latitude: lat1 + (lat2 - lat1) * i / (count - 1), longitude: lon1 + (lon2 - lon1) * i / (count - 1)),
      ];

  static double freeSpaceLossDb(double meters, double mhz) =>
      20 * math.log(math.max(meters, 1) / 1000) / math.ln10 + 20 * math.log(mhz) / math.ln10 + 32.44;

  /// Radius of the first Fresnel zone at [d1] and [d2] metres from each end.
  static double fresnelRadius(double d1, double d2, double mhz) {
    final lambda = 299.792458 / mhz;
    final total = d1 + d2;
    return total <= 0 ? 0 : math.sqrt(lambda * d1 * d2 / total);
  }

  /// Checks the link given ground heights at evenly spaced points between
  /// the two ends, antenna heights above ground, and a frequency.
  static LinkAnalysis analyse({
    required double distanceMeters,
    required List<double> ground,
    required double startAntennaMeters,
    required double endAntennaMeters,
    required double mhz,
  }) {
    if (ground.length < 2) throw ArgumentError('Need at least two ground heights.');
    final n = ground.length;
    final start = ground.first + startAntennaMeters;
    final end = ground.last + endAntennaMeters;
    var worst = double.infinity, worstAt = 0.0, worstFresnelShare = double.infinity;
    final profile = <ProfilePoint>[];
    for (var i = 0; i < n; i++) {
      final d1 = distanceMeters * i / (n - 1);
      final d2 = distanceMeters - d1;
      // The earth bulges up between the ends.
      final bulge = d1 * d2 / (2 * effectiveEarthRadius);
      final terrain = ground[i] + bulge;
      profile.add(ProfilePoint(d1, terrain));
      if (i == 0 || i == n - 1) continue;
      final line = start + (end - start) * i / (n - 1);
      final clearance = line - terrain;
      if (clearance < worst) {
        worst = clearance;
        worstAt = d1;
      }
      final f = fresnelRadius(d1, d2, mhz);
      if (f > 0) worstFresnelShare = math.min(worstFresnelShare, clearance / f);
    }
    if (worst == double.infinity) worst = 0;
    final verdict = worst < 0
        ? LinkVerdict.blocked
        : worstFresnelShare < 0.6
            ? LinkVerdict.marginal
            : LinkVerdict.clear;
    return LinkAnalysis(
      distanceMeters: distanceMeters,
      pathLossDb: freeSpaceLossDb(distanceMeters, mhz),
      verdict: verdict,
      worstClearanceMeters: worst,
      worstAtMeters: worstAt,
      profile: profile,
      lineStart: start,
      lineEnd: end,
    );
  }

  /// Distance between two points, for [analyse].
  static double distance(double lat1, double lon1, double lat2, double lon2) =>
      BastionGeo.distanceMeters(lat1, lon1, lat2, lon2);
}

/// Ground heights for points, in metres above sea level.
abstract interface class ElevationSource {
  Future<List<double>> heights(List<({double latitude, double longitude})> points);
}

/// Open-Meteo's free elevation service (Copernicus 90 m data). Only called
/// when someone checks a link; it sees the sampled coordinates.
class OpenMeteoElevation implements ElevationSource {
  OpenMeteoElevation({HttpClient Function()? client}) : _client = client ?? HttpClient.new;
  final HttpClient Function() _client;

  static const host = 'api.open-meteo.com';

  @override
  Future<List<double>> heights(List<({double latitude, double longitude})> points) async {
    if (points.length > 100) throw ArgumentError('At most 100 points per request.');
    final uri = Uri.https(host, '/v1/elevation', {
      'latitude': points.map((p) => p.latitude.toStringAsFixed(5)).join(','),
      'longitude': points.map((p) => p.longitude.toStringAsFixed(5)).join(','),
    });
    final client = _client()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.userAgentHeader, 'NOTORYX-Connect');
      final response = await request.close().timeout(const Duration(seconds: 20));
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) {
        throw HttpException('Elevation service answered ${response.statusCode}.');
      }
      final list = (jsonDecode(body) as Map)['elevation'];
      if (list is! List || list.length != points.length) {
        throw const FormatException('Elevation service sent an unexpected reply.');
      }
      return [for (final v in list) (v as num).toDouble()];
    } finally {
      client.close(force: true);
    }
  }
}
