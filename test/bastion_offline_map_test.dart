import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bastion/services/bastion_offline_map.dart';
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A whole 1×1 PNG.
final png = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0, 0, 0, 1, 0, 0, 0, 1, 8, 2, 0, 0, 0, 0x90, 0x77, 0x53, 0xDE, //
  0, 0, 0, 0, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

Future<String> makeMbtiles(Directory dir,
    {String format = 'png', bool withTiles = true, String? bounds, List<Uint8List> extra = const []}) async {
  final path = '${dir.path}/test-${DateTime.now().microsecondsSinceEpoch}.mbtiles';
  final db = await databaseFactoryFfi.openDatabase(path);
  await db.execute('CREATE TABLE metadata (name TEXT, value TEXT)');
  await db.execute('CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB)');
  for (final (k, v) in [('name', 'Ridge area'), ('format', format), ('minzoom', '10'), ('maxzoom', '14'),
    if (bounds != null) ('bounds', bounds)]) {
    await db.insert('metadata', {'name': k, 'value': v});
  }
  for (final (i, data) in extra.indexed) {
    await db.insert('tiles', {'zoom_level': 10, 'tile_column': 6 + i, 'tile_row': 1020, 'tile_data': data});
  }
  if (withTiles) {
    // Map tile z=10, x=5, y=3 is TMS row 1023 - 3 = 1020.
    await db.insert('tiles', {'zoom_level': 10, 'tile_column': 5, 'tile_row': 1020, 'tile_data': Uint8List.fromList([1, 2, 3])});
  }
  await db.close();
  return path;
}

void main() {
  sqfliteFfiInit();
  late Directory dir;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    dir = await Directory.systemTemp.createTemp('offline_map_test');
  });
  tearDown(() async => dir.delete(recursive: true));

  BastionOfflineMap store() => BastionOfflineMap(preferences: SharedPreferencesAsync(), factory: databaseFactoryFfi);

  test('flips map rows to MBTiles rows', () {
    expect(BastionOfflineMap.tmsRow(0, 0), 0);
    expect(BastionOfflineMap.tmsRow(10, 3), 1020);
  });

  test('reads metadata and refuses vector or empty files', () {
    final info = OfflineMapInfo.fromMetadata({'name': 'A', 'format': 'jpg', 'minzoom': '3', 'maxzoom': '9'}, fallbackName: 'f');
    expect([info.name, info.format, info.minZoom, info.maxZoom], ['A', 'jpg', 3, 9]);
    expect(OfflineMapInfo.fromMetadata({}, fallbackName: 'f', minFromTiles: 2, maxFromTiles: 4).name, 'f');
    expect(() => OfflineMapInfo.fromMetadata({'format': 'pbf', 'minzoom': '1', 'maxzoom': '2'}, fallbackName: 'f'),
        throwsFormatException);
    expect(() => OfflineMapInfo.fromMetadata({}, fallbackName: 'f'), throwsFormatException);
  });

  test('imports a file, serves its tiles and survives a restart', () async {
    final src = await makeMbtiles(dir);
    final map = store();
    final info = await map.import(XFile(src), directory: '${dir.path}/maps');
    expect([info.name, info.minZoom, info.maxZoom], ['Ridge area', 10, 14]);
    expect(map.active, isTrue);
    expect(await map.tile(10, 5, 3), [1, 2, 3]);
    expect(await map.tile(10, 5, 4), isNull);

    await map.setActive(false);
    final again = store();
    await again.load();
    expect(again.info?.name, 'Ridge area');
    expect(again.active, isFalse);
    expect(await again.tile(10, 5, 3), [1, 2, 3]);

    await again.remove();
    expect(again.hasMap, isFalse);
    expect(Directory('${dir.path}/maps').listSync(), isEmpty);
  });

  test('a vector or empty file is refused and not kept', () async {
    final map = store();
    await expectLater(map.import(XFile(await makeMbtiles(dir, format: 'pbf')), directory: '${dir.path}/maps'),
        throwsFormatException);
    await expectLater(map.import(XFile(await makeMbtiles(dir, withTiles: false)), directory: '${dir.path}/maps'),
        throwsFormatException);
    expect(map.hasMap, isFalse);
    expect(Directory('${dir.path}/maps').listSync(), isEmpty);
  });

  group('coverage and damage', () {
    test('reads the area from metadata, or works it out from the tiles', () async {
      final withMeta = await makeMbtiles(dir, bounds: '-80.9,35.1,-80.7,35.3');
      final a = await store().import(XFile(withMeta), directory: '${dir.path}/a');
      expect(a.bounds, (-80.9, 35.1, -80.7, 35.3));

      final fromTiles = await makeMbtiles(dir);
      final b = await store().import(XFile(fromTiles), directory: '${dir.path}/b');
      // Tile z10 x5 y3: 178.24..177.89 W, 84.9..84.8 N, roughly.
      final (w, s, e, n) = b.bounds!;
      expect(w, closeTo(-178.24, 0.01));
      expect(e, closeTo(-177.89, 0.01));
      expect(n, greaterThan(s));
      expect(n, closeTo(84.97, 0.05));
    });

    test('bad bounds in metadata fall back to the tiles', () {
      expect(OfflineMapInfo.parseBounds('1,2,3'), isNull);
      expect(OfflineMapInfo.parseBounds('10,50,5,40'), isNull);
      expect(OfflineMapInfo.parseBounds('-1,-2,3,4'), (-1.0, -2.0, 3.0, 4.0));
    });

    test('counts damaged tiles at import and keeps the count', () async {
      final cut = Uint8List.fromList(png.sublist(0, 20));
      final html = Uint8List.fromList('<html>error</html>'.codeUnits);
      final path = await makeMbtiles(dir, extra: [png, cut, html]);
      final map = store();
      final info = await map.import(XFile(path), directory: dir.path);
      // The helper's own [1,2,3] tile, the cut PNG and the HTML page.
      expect(info.damagedTiles, 3);
      final again = store();
      await again.load();
      expect(again.info!.damagedTiles, 3);
      expect(again.info!.bounds, isNotNull);
    });

    test('a whole file reports no damage', () async {
      final path = await makeMbtiles(dir, withTiles: false, extra: [png]);
      final info = await store().import(XFile(path), directory: dir.path);
      expect(info.damagedTiles, 0);
    });
  });

  testWidgets('a damaged tile draws blank instead of failing', (tester) async {
    await tester.runAsync(() async {
      final path = await makeMbtiles(dir);
      final map = store();
      await map.import(XFile(path), directory: dir.path);
      // z10/x5/y3 holds the helper's [1,2,3] bytes: not an image.
      final provider = MbTilesImage(map, 10, 5, 3);
      final done = Completer<Object>();
      provider.resolve(ImageConfiguration.empty).addListener(ImageStreamListener(
            (info, _) => done.complete(info),
            onError: (e, _) => done.complete(e),
          ));
      final result = await done.future;
      expect(result, isA<ImageInfo>());
      expect((result as ImageInfo).image.width, 1);
    });
  });
}
