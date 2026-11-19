import 'package:bastion/services/bastion_geo.dart';
import 'package:bastion/services/bastion_range_rings.dart';
import 'package:bastion/services/bastion_units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const metric = BastionUnits.metric;
  const imperial = BastionUnits.imperial;
  const mile = BastionRangeRings.metersPerMile;

  group('niceStep', () {
    test(
      'a quarter of the edge distance, rounded down to 1, 2 or 5 × 10ⁿ meters',
      () {
        expect(BastionRangeRings.niceStep(4000, metric), 1000);
        expect(BastionRangeRings.niceStep(3999, metric), 500);
        expect(BastionRangeRings.niceStep(8000, metric), 2000);
        expect(BastionRangeRings.niceStep(19999, metric), 2000);
        expect(BastionRangeRings.niceStep(20000, metric), 5000);
        expect(BastionRangeRings.niceStep(39999, metric), 5000);
        expect(BastionRangeRings.niceStep(400, metric), 100);
        expect(BastionRangeRings.niceStep(1234567, metric), 200000);
      },
    );

    test('never below 10 m', () {
      expect(BastionRangeRings.niceStep(40, metric), 10);
      expect(BastionRangeRings.niceStep(3, metric), 10);
      expect(BastionRangeRings.niceStep(0, metric), 10);
      expect(BastionRangeRings.niceStep(double.nan, metric), 10);
    });

    test('imperial steps are in miles and start at 0.1 mi', () {
      expect(
        BastionRangeRings.niceStep(4 * mile, imperial),
        closeTo(mile, 1e-6),
      );
      expect(
        BastionRangeRings.niceStep(4 * 0.3 * mile, imperial),
        closeTo(0.2 * mile, 1e-6),
      );
      expect(
        BastionRangeRings.niceStep(4 * 7 * mile, imperial),
        closeTo(5 * mile, 1e-6),
      );
      expect(
        BastionRangeRings.niceStep(4 * 0.12 * mile, imperial),
        closeTo(0.1 * mile, 1e-6),
      );
      expect(
        BastionRangeRings.niceStep(50, imperial),
        closeTo(0.1 * mile, 1e-6),
      );
    });
  });

  test('ringRadii gives four evenly spaced rings', () {
    expect(BastionRangeRings.ringRadii(500), [500, 1000, 1500, 2000]);
  });

  group('ringLabel', () {
    test('meters below 1 km, then km without trailing zeros', () {
      expect(BastionRangeRings.ringLabel(10, metric), '10 m');
      expect(BastionRangeRings.ringLabel(500, metric), '500 m');
      expect(BastionRangeRings.ringLabel(1000, metric), '1 km');
      expect(BastionRangeRings.ringLabel(1500, metric), '1.5 km');
      expect(BastionRangeRings.ringLabel(20000, metric), '20 km');
    });

    test('miles in imperial', () {
      expect(BastionRangeRings.ringLabel(0.1 * mile, imperial), '0.1 mi');
      expect(BastionRangeRings.ringLabel(0.3 * mile, imperial), '0.3 mi');
      expect(BastionRangeRings.ringLabel(1.5 * mile, imperial), '1.5 mi');
      expect(BastionRangeRings.ringLabel(20 * mile, imperial), '20 mi');
    });

    test('every ring of every step reads cleanly', () {
      for (final edge in <double>[
        40,
        900,
        3000,
        45000,
        4 * mile,
        4 * 0.5 * mile,
      ]) {
        for (final units in BastionUnits.values) {
          for (final r in BastionRangeRings.ringRadii(
            BastionRangeRings.niceStep(edge, units),
          )) {
            expect(
              BastionRangeRings.ringLabel(r, units),
              matches(RegExp(r'^\d+(\.\d{1,2})? (m|km|mi)$')),
            );
          }
        }
      }
    });
  });

  group('pointAt', () {
    test('lands the asked distance away on the asked bearing', () {
      for (final bearing in <double>[0, 45, 90, 135, 180, 225, 270, 315]) {
        final (lat, lon) = BastionRangeRings.pointAt(
          39.75,
          -105.0,
          bearing,
          5000,
        );
        expect(
          BastionGeo.distanceMeters(39.75, -105.0, lat, lon),
          closeTo(5000, 0.5),
        );
        final back = BastionGeo.bearingDegrees(39.75, -105.0, lat, lon);
        final diff = ((back - bearing + 540) % 360) - 180;
        expect(diff.abs(), lessThan(0.1), reason: 'bearing $bearing');
      }
    });

    test('north moves only latitude, by about 1° per 111 km', () {
      final (lat, lon) = BastionRangeRings.pointAt(0, 10, 0, 111195);
      expect(lat, closeTo(1, 1e-3));
      expect(lon, closeTo(10, 1e-9));
    });

    test('wraps across the date line', () {
      final (_, lon) = BastionRangeRings.pointAt(0, 179.99, 90, 5000);
      expect(lon, lessThan(-179.9));
    });

    test('zero distance is the centre', () {
      final (lat, lon) = BastionRangeRings.pointAt(12.5, 34.5, 200, 0);
      expect(lat, closeTo(12.5, 1e-12));
      expect(lon, closeTo(34.5, 1e-12));
    });
  });

  test('edgeMeters halves the shorter side at the equator', () {
    // At zoom 0 the 256 px world is 40,030 km wide.
    final world = BastionRangeRings.edgeMeters(
      latitude: 0,
      zoom: 0,
      widthPx: 256,
      heightPx: 512,
    );
    expect(
      world,
      closeTo(2 * 3.141592653589793 * BastionRangeRings.earthRadius / 2, 1),
    );
    final narrower = BastionRangeRings.edgeMeters(
      latitude: 60,
      zoom: 0,
      widthPx: 256,
      heightPx: 512,
    );
    expect(narrower, closeTo(world / 2, 1), reason: 'cos 60° = 0.5');
  });
}
