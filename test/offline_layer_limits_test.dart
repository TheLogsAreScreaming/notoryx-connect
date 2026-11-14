import 'dart:math' as math;

import 'package:bastion/map_page.dart';
import 'package:bastion/services/bastion_offline_map.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tiles at [z] covering longitudes [w]..[e] and latitudes [s]..[n].
int tilesAt(int z, double w, double s, double e, double n) {
  final count = 1 << z;
  int x(double lon) => ((lon + 180) / 360 * count).floor().clamp(0, count - 1);
  int y(double lat) {
    final r = lat * math.pi / 180;
    return ((1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * count)
        .floor()
        .clamp(0, count - 1);
  }

  return (x(e) - x(w) + 1) * (y(s) - y(n) + 1);
}

void main() {
  const area = OfflineMapInfo(
      name: 'Test area', format: 'png', minZoom: 10, maxZoom: 13,
      bounds: (-73.20, 41.25, -72.98, 41.40));

  test('the offline layer is limited to the file area', () {
    final b = offlineLayerBounds(area)!;
    expect(b.west, -73.20);
    expect(b.south, 41.25);
    expect(b.east, -72.98);
    expect(b.north, 41.40);
    expect(offlineLayerBounds(const OfflineMapInfo(name: 'x', format: 'png', minZoom: 10, maxZoom: 13)), isNull);
  });

  test("the offline layer isn't drawn far below the file's lowest zoom", () {
    expect(offlineLayerMinZoom(area), 7);
    expect(offlineLayerMinZoom(const OfflineMapInfo(name: 'x', format: 'png', minZoom: 10, maxZoom: 13)), 9);
    expect(offlineLayerMinZoom(const OfflineMapInfo(name: 'x', format: 'png', minZoom: 1, maxZoom: 5)), 0);
  });

  test('a zoomed-out view asks for a handful of tiles, not the whole map', () {
    // Before: the visible US at zoom-10 tiles. After: only the file's area.
    final wholeView = tilesAt(10, -125, 24, -66, 50);
    final fileArea = tilesAt(10, -73.20, 41.25, -72.98, 41.40);
    expect(wholeView, greaterThan(10000));
    expect(fileArea, lessThan(10));
  });
}
