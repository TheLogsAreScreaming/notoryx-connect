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

  group('label placement', () {
    const area = (left: 0.0, top: 100.0, right: 300.0, bottom: 600.0);

    test('clampInto keeps a label inside the clear area', () {
      expect(BastionRangeRings.clampInto(150, 300, area, 20, 10), (
        150,
        300,
      ), reason: 'already inside');
      expect(BastionRangeRings.clampInto(150, 40, area, 20, 10), (
        150,
        110,
      ), reason: 'under the top bar');
      expect(BastionRangeRings.clampInto(340, 300, area, 20, 10), (
        280,
        300,
      ), reason: 'under the side toolbar');
      expect(BastionRangeRings.clampInto(-50, 900, area, 20, 10), (20, 590));
    });

    test('a label wider than the area is centred', () {
      expect(
        BastionRangeRings.clampInto(
          500,
          300,
          (left: 0, top: 0, right: 30, bottom: 600),
          20,
          10,
        ),
        (15, 300),
      );
    });

    test('labels pushed onto the same spot are dropped, earlier ones win', () {
      final spots = BastionRangeRings.placeLabels([
        (x: 150, y: 300, halfW: 36, halfH: 10),
        (x: 150, y: 20, halfW: 36, halfH: 10),
        (x: 150, y: -80, halfW: 36, halfH: 10),
        (x: 150, y: 285, halfW: 36, halfH: 10),
        (x: 150, y: 250, halfW: 36, halfH: 10),
      ], area);
      expect(spots, [
        (150.0, 300.0),
        (150.0, 110.0),
        null,
        null,
        (150.0, 250.0),
      ]);
    });

    test('every placed label lies inside the area', () {
      final spots = BastionRangeRings.placeLabels([
        for (var i = 0; i < 40; i++)
          (x: -200.0 + i * 25, y: 900.0 - i * 30, halfW: 14.0, halfH: 10.0),
      ], area);
      for (final s in spots.nonNulls) {
        expect(s.$1 - 14, greaterThanOrEqualTo(area.left));
        expect(s.$1 + 14, lessThanOrEqualTo(area.right));
        expect(s.$2 - 10, greaterThanOrEqualTo(area.top));
        expect(s.$2 + 10, lessThanOrEqualTo(area.bottom));
      }
    });
  });

  group('placeLabelChoices', () {
    const area = (left: 0.0, top: 0.0, right: 400.0, bottom: 400.0);
    RingLabelBox at(double x, double y) => (x: x, y: y, halfW: 20, halfH: 10);

    test('a label under an obstacle takes its next free spot', () {
      final spots = BastionRangeRings.placeLabelChoices(
        [
          [at(200, 180), at(200, 220), at(200, 240)],
        ],
        area,
        obstacles: [(x: 200, y: 190, halfW: 30, halfH: 24)],
      );
      // 180 and 220 are both within 34 px of the obstacle's centre row.
      expect(spots, [(200.0, 240.0)]);
    });

    test('a label with no free spot is dropped', () {
      final spots = BastionRangeRings.placeLabelChoices(
        [
          [at(200, 200), at(205, 205)],
        ],
        area,
        obstacles: [(x: 200, y: 200, halfW: 60, halfH: 60)],
      );
      expect(spots.single, isNull);
    });

    test('earlier labels win and later ones move round', () {
      final spots = BastionRangeRings.placeLabelChoices([
        [at(100, 100)],
        [at(100, 100), at(100, 300)],
      ], area);
      expect(spots, [(100.0, 100.0), (100.0, 300.0)]);
    });

    test('placeLabels with no obstacles is unchanged', () {
      expect(
        BastionRangeRings.placeLabels([at(100, 100), at(105, 100)], area),
        [(100.0, 100.0), null],
      );
    });
  });
}
