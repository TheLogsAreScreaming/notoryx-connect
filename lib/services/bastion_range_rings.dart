import 'dart:math' as math;

import 'bastion_units.dart';

/// Distance rings around this radio on the map, sized to the visible view.
///
/// Pure math only, so it can be tested without a map.
abstract final class BastionRangeRings {
  /// How many rings are drawn.
  static const count = 4;

  /// Mean Earth radius in meters, matching [BastionGeo].
  static const earthRadius = 6371000.0;

  static const metersPerMile = 1609.344;

  /// Smallest metric step: 10 m.
  static const minMetricMeters = 10.0;

  /// Smallest imperial step: 0.1 mi.
  static const minImperialMiles = 0.1;

  /// Ground distance from the centre of a [widthPx] × [heightPx] web-mercator
  /// view at [zoom] to its nearer edge, measured at [latitude] (256 px tiles).
  static double edgeMeters({
    required double latitude,
    required double zoom,
    required double widthPx,
    required double heightPx,
  }) {
    final metersPerPixel =
        2 *
        math.pi *
        earthRadius *
        math.cos(latitude * math.pi / 180) /
        (256 * math.pow(2, zoom));
    return math.min(widthPx, heightPx) / 2 * metersPerPixel.abs();
  }

  /// The ring spacing in meters for a view whose centre is [edgeMeters] from
  /// its nearer edge: a quarter of that, rounded down to 1, 2 or 5 × 10ⁿ in
  /// the chosen [units] (meters, or miles), never below 10 m or 0.1 mi.
  static double niceStep(double edgeMeters, BastionUnits units) {
    final imperial = units == BastionUnits.imperial;
    final unit = imperial ? metersPerMile : 1.0;
    final floor = imperial ? minImperialMiles : minMetricMeters;
    final raw = edgeMeters.isFinite && edgeMeters > 0
        ? edgeMeters / count / unit
        : 0.0;
    if (raw <= floor) return floor * unit;
    // log10(1000) comes out as 2.9999…, so nudge before flooring.
    final exponent = (math.log(raw) / math.ln10 + 1e-9).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    final leading = raw / magnitude;
    // A tiny tolerance so 2000 / 1000 lands on 2, not 1.999….
    final nice = leading >= 5 - 1e-9
        ? 5
        : leading >= 2 - 1e-9
        ? 2
        : 1;
    return math.max(nice * magnitude, floor) * unit;
  }

  /// The radii of the [count] rings, in meters, for spacing [stepMeters].
  static List<double> ringRadii(double stepMeters) => [
    for (var i = 1; i <= count; i++) stepMeters * i,
  ];

  /// The label for a ring of [meters]: "500 m", "1.5 km", "0.3 mi", "2 mi".
  static String ringLabel(double meters, BastionUnits units) {
    if (units == BastionUnits.imperial)
      return '${_trim(meters / metersPerMile)} mi';
    if (meters < 1000 - 1e-6) return '${meters.round()} m';
    return '${_trim(meters / 1000)} km';
  }

  /// Up to two decimals, without trailing zeros: 1.5, 2, 0.25.
  static String _trim(double v) {
    final s = v.toStringAsFixed(2);
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  }

  /// The point [meters] from ([lat], [lon]) on compass [bearing] degrees,
  /// along a great circle. Longitude is wrapped to -180…180.
  static (double, double) pointAt(
    double lat,
    double lon,
    double bearing,
    double meters,
  ) {
    final d = meters / earthRadius;
    final p1 = lat * math.pi / 180;
    final l1 = lon * math.pi / 180;
    final b = bearing * math.pi / 180;
    final p2 = math.asin(
      (math.sin(p1) * math.cos(d) + math.cos(p1) * math.sin(d) * math.cos(b))
          .clamp(-1.0, 1.0),
    );
    final l2 =
        l1 +
        math.atan2(
          math.sin(b) * math.sin(d) * math.cos(p1),
          math.cos(d) - math.sin(p1) * math.sin(p2),
        );
    final lonDeg = (l2 * 180 / math.pi + 540) % 360 - 180;
    return (p2 * 180 / math.pi, lonDeg);
  }

  /// [x], [y] moved just enough that a label of half-size [halfW] × [halfH]
  /// centred there lies inside [area] (screen pixels). A label bigger than
  /// the area is centred in it.
  static (double, double) clampInto(
    double x,
    double y,
    RingArea area,
    double halfW,
    double halfH,
  ) {
    double fit(double v, double lo, double hi, double half) =>
        hi - lo < 2 * half ? (lo + hi) / 2 : v.clamp(lo + half, hi - half);
    return (
      fit(x, area.left, area.right, halfW),
      fit(y, area.top, area.bottom, halfH),
    );
  }

  /// Screen positions for [labels], in order, each clamped inside [area].
  /// A label that would then overlap one placed before it is dropped (null),
  /// so labels pushed to the same edge do not pile up.
  static List<(double, double)?> placeLabels(
    List<RingLabelBox> labels,
    RingArea area,
  ) {
    final placed = <(double, double, double, double)>[];
    return [
      for (final b in labels)
        () {
          final (x, y) = clampInto(b.x, b.y, area, b.halfW, b.halfH);
          final hit = placed.any(
            (p) =>
                (p.$1 - x).abs() < p.$3 + b.halfW &&
                (p.$2 - y).abs() < p.$4 + b.halfH,
          );
          if (hit) return null;
          placed.add((x, y, b.halfW, b.halfH));
          return (x, y);
        }(),
    ];
  }
}

/// The part of the map not covered by its bars and cards, in screen pixels.
typedef RingArea = ({double left, double top, double right, double bottom});

/// A label wanted at ([x], [y]) on screen, with its half width and height.
typedef RingLabelBox = ({double x, double y, double halfW, double halfH});
