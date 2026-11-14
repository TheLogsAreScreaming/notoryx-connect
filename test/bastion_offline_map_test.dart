import 'dart:io';
import 'dart:typed_data';

import 'package:bastion/services/bastion_offline_map.dart';
import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<String> makeMbtiles(Directory dir, {String format = 'png', bool withTiles = true}) async {
  final path = '${dir.path}/test-${DateTime.now().microsecondsSinceEpoch}.mbtiles';
  final db = await databaseFactoryFfi.openDatabase(path);
  await db.execute('CREATE TABLE metadata (name TEXT, value TEXT)');
  await db.execute('CREATE TABLE tiles (zoom_level INTEGER, tile_column INTEGER, tile_row INTEGER, tile_data BLOB)');
  for (final (k, v) in [('name', 'Ridge area'), ('format', format), ('minzoom', '10'), ('maxzoom', '14')]) {
    await db.insert('metadata', {'name': k, 'value': v});
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
}
