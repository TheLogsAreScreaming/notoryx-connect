import 'package:bastion/services/bastion_map_layers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

MapLayer parse(String text) => BastionMapLayers.parse(text, name: 'T', id: 't');

void main() {
  test('reads GPX waypoints, routes and tracks', () {
    final l = parse('''<?xml version="1.0"?>
<gpx version="1.1" xmlns="http://www.topografix.com/GPX/1/1">
  <wpt lat="45.1" lon="-110.2"><name>Camp</name><desc>Water here</desc></wpt>
  <wpt lat="200" lon="0"><name>Bad</name></wpt>
  <rte><name>Plan</name><rtept lat="45" lon="-110"/><rtept lat="45.1" lon="-110.1"/></rte>
  <trk><name>Walked</name><trkseg><trkpt lat="45" lon="-110"/><trkpt lat="45.2" lon="-110.2"/></trkseg></trk>
</gpx>''');
    expect(l.points.single.name, 'Camp');
    expect(l.points.single.note, 'Water here');
    expect(l.lines.map((x) => x.name), ['Plan', 'Walked']);
  });

  test('reads KML points, lines and polygon outlines', () {
    final l = parse('''<kml xmlns="http://www.opengis.net/kml/2.2"><Document>
<Placemark><name>LZ</name><Point><coordinates>-110.2,45.1,0</coordinates></Point></Placemark>
<Placemark><name>Sector A</name><Polygon><outerBoundaryIs><LinearRing>
<coordinates>-110,45 -110.1,45 -110.1,45.1 -110,45</coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>
</Document></kml>''');
    expect(l.points.single.latitude, 45.1);
    expect(l.lines.single.name, 'Sector A');
    expect(l.lines.single.points, hasLength(4));
  });

  test('reads GeoJSON features and bare geometries', () {
    final l = parse('{"type":"FeatureCollection","features":['
        '{"type":"Feature","properties":{"name":"Hut"},"geometry":{"type":"Point","coordinates":[10,46]}},'
        '{"type":"Feature","properties":{"title":"Ridge"},"geometry":{"type":"LineString","coordinates":[[10,46],[10.1,46.1]]}}]}');
    expect(l.points.single.name, 'Hut');
    expect(l.lines.single.name, 'Ridge');
    expect(parse('{"type":"Point","coordinates":[1,2]}').points, hasLength(1));
  });

  test('rejects files that are none of the formats', () {
    expect(() => parse('{"a":1}'), throwsFormatException);
    expect(() => parse('<html></html>'), throwsFormatException);
    expect(() => parse('not a file'), throwsFormatException);
  });

  test('thins very long lines', () {
    final pts = [for (var i = 0; i < 2000; i++) '<trkpt lat="${i / 10000}" lon="0"/>'].join();
    final l = parse('<gpx><trk><trkseg>$pts</trkseg></trk></gpx>');
    expect(l.lines.single.points, hasLength(BastionMapLayers.maxLinePoints));
    expect(l.lines.single.points.first.$1, 0);
    expect(l.lines.single.points.last.$1, closeTo(0.1999, 1e-9));
  });

  test('saves, hides and removes layers', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final store = BastionMapLayers(preferences: SharedPreferencesAsync());
    await store.load();
    final layer = await store.import('Trip', '{"type":"Point","coordinates":[1,2]}');
    await store.setVisible(layer.id, false);

    final again = BastionMapLayers(preferences: SharedPreferencesAsync());
    await again.load();
    expect(again.layers.single.name, 'Trip');
    expect(again.layers.single.visible, isFalse);

    await again.remove(layer.id);
    expect(again.layers, isEmpty);
    await expectLater(store.import('Empty', '{"type":"FeatureCollection","features":[]}'), throwsFormatException);
  });
}
