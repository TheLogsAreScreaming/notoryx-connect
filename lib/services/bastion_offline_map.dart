import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show databaseFactoryFfi, sqfliteFfiInit;

/// What an MBTiles file says about itself.
@immutable
class OfflineMapInfo {
  const OfflineMapInfo({required this.name, required this.format, required this.minZoom, required this.maxZoom});

  final String name;

  /// png, jpg or webp.
  final String format;
  final int minZoom;
  final int maxZoom;

  /// Reads the MBTiles `metadata` table. Throws [FormatException] for vector
  /// tiles (pbf), which this map can't draw, or missing zoom information.
  static OfflineMapInfo fromMetadata(Map<String, String> m, {required String fallbackName, int? minFromTiles, int? maxFromTiles}) {
    final format = (m['format'] ?? 'png').toLowerCase();
    if (format == 'pbf' || format == 'mvt') {
      throw const FormatException('Vector tiles (pbf) are not supported; use a raster MBTiles file');
    }
    if (!const {'png', 'jpg', 'jpeg', 'webp'}.contains(format)) {
      throw FormatException('Unsupported tile format: $format');
    }
    final minZoom = int.tryParse(m['minzoom'] ?? '') ?? minFromTiles;
    final maxZoom = int.tryParse(m['maxzoom'] ?? '') ?? maxFromTiles;
    if (minZoom == null || maxZoom == null || minZoom > maxZoom || maxZoom > 22) {
      throw const FormatException('The file has no usable zoom levels');
    }
    final name = (m['name'] ?? '').trim();
    return OfflineMapInfo(name: name.isEmpty ? fallbackName : name, format: format, minZoom: minZoom, maxZoom: maxZoom);
  }

  Map<String, Object?> toJson() => {'name': name, 'format': format, 'min': minZoom, 'max': maxZoom};

  static OfflineMapInfo? fromJson(Object? j) {
    if (j is! Map) return null;
    final name = j['name'], format = j['format'], min = j['min'], max = j['max'];
    if (name is! String || format is! String || min is! int || max is! int) return null;
    return OfflineMapInfo(name: name, format: format, minZoom: min, maxZoom: max);
  }
}

/// A raster MBTiles file imported by the person and drawn as the map's
/// base layer with no internet. Tiles come only from the file; nothing is
/// downloaded.
class BastionOfflineMap extends ChangeNotifier {
  BastionOfflineMap({SharedPreferencesAsync? preferences, DatabaseFactory? factory})
      : _preferences = preferences,
        _factory = factory;

  static final instance = BastionOfflineMap();
  static const key = 'bastion.offline_map.v1';

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();
  final DatabaseFactory? _factory;
  DatabaseFactory get _db {
    if (_factory != null) return _factory;
    if (!kIsWeb && Platform.isWindows) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    return databaseFactory;
  }

  Database? _open;
  String? _path;
  OfflineMapInfo? _info;
  bool _active = true;
  bool _loaded = false;

  OfflineMapInfo? get info => _info;
  bool get active => _active && _open != null;
  bool get hasMap => _open != null;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = await _store.getString(key);
      if (raw == null) return;
      final j = jsonDecode(raw);
      if (j is! Map) return;
      final path = j['path'];
      final info = OfflineMapInfo.fromJson(j['info']);
      if (path is! String || info == null || !File(path).existsSync()) return;
      _open = await _db.openDatabase(path, options: OpenDatabaseOptions(readOnly: true, singleInstance: false));
      _path = path;
      _info = info;
      _active = j['active'] as bool? ?? true;
      notifyListeners();
    } catch (error) {
      debugPrint('Offline map unavailable: $error');
    }
  }

  /// Copies [file] into app storage and opens it. Replaces any earlier file.
  Future<OfflineMapInfo> import(XFile file, {String? directory}) async {
    final dir = directory ?? '${(await getApplicationSupportDirectory()).path}/offline_maps';
    await Directory(dir).create(recursive: true);
    final dest = '$dir/map-${DateTime.now().millisecondsSinceEpoch}.mbtiles';
    await file.saveTo(dest);
    try {
      final db = await _db.openDatabase(dest, options: OpenDatabaseOptions(readOnly: true, singleInstance: false));
      final OfflineMapInfo info;
      try {
        info = await readInfo(db, fallbackName: file.name.replaceFirst(RegExp(r'\.mbtiles$', caseSensitive: false), ''));
      } catch (_) {
        await db.close();
        rethrow;
      }
      await _closeAndDelete();
      _open = db;
      _path = dest;
      _info = info;
      _active = true;
      await _save();
      notifyListeners();
      return info;
    } catch (_) {
      try {
        File(dest).deleteSync();
      } catch (_) {}
      rethrow;
    }
  }

  /// Reads and checks an MBTiles file's metadata and zoom levels.
  static Future<OfflineMapInfo> readInfo(Database db, {required String fallbackName}) async {
    final Map<String, String> meta;
    try {
      meta = {
        for (final r in await db.query('metadata'))
          if (r['name'] is String && r['value'] != null) r['name']! as String: '${r['value']}',
      };
    } on DatabaseException {
      throw const FormatException('Not an MBTiles file');
    }
    int? min, max;
    try {
      final r = await db.rawQuery('SELECT MIN(zoom_level) AS mn, MAX(zoom_level) AS mx FROM tiles');
      min = r.first['mn'] as int?;
      max = r.first['mx'] as int?;
    } on DatabaseException {
      throw const FormatException('Not an MBTiles file');
    }
    if (min == null) throw const FormatException('The file has no tiles');
    return OfflineMapInfo.fromMetadata(meta, fallbackName: fallbackName, minFromTiles: min, maxFromTiles: max);
  }

  Future<void> setActive(bool value) async {
    _active = value;
    await _save();
    notifyListeners();
  }

  Future<void> remove() async {
    await _closeAndDelete();
    _info = null;
    try {
      await _store.remove(key);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _closeAndDelete() async {
    final db = _open, path = _path;
    _open = null;
    _path = null;
    if (db != null) await db.close();
    if (path != null) {
      try {
        File(path).deleteSync();
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final path = _path, info = _info;
    if (path == null || info == null) return;
    try {
      await _store.setString(key, jsonEncode({'path': path, 'info': info.toJson(), 'active': _active}));
    } catch (_) {}
  }

  /// MBTiles rows count from the bottom (TMS); the map counts from the top.
  static int tmsRow(int z, int y) => (1 << z) - 1 - y;

  /// The tile image bytes at [z]/[x]/[y] (map numbering), or null.
  Future<Uint8List?> tile(int z, int x, int y) async {
    final db = _open;
    if (db == null) return null;
    try {
      final rows = await db.query('tiles',
          columns: ['tile_data'],
          where: 'zoom_level = ? AND tile_column = ? AND tile_row = ?',
          whereArgs: [z, x, tmsRow(z, y)],
          limit: 1);
      if (rows.isEmpty) return null;
      final data = rows.first['tile_data'];
      return data is Uint8List ? data : null;
    } catch (_) {
      return null;
    }
  }

  TileProvider get tileProvider => _MbTilesProvider(this);
}

class _MbTilesProvider extends TileProvider {
  _MbTilesProvider(this.map);
  final BastionOfflineMap map;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MbTilesImage(map, coordinates.z, coordinates.x, coordinates.y);
}

/// One tile read from the offline map file. Missing tiles draw nothing.
@immutable
class MbTilesImage extends ImageProvider<MbTilesImage> {
  const MbTilesImage(this.map, this.z, this.x, this.y);

  final BastionOfflineMap map;
  final int z, x, y;

  // A 1×1 transparent PNG for tiles the file doesn't have.
  static final _empty = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

  @override
  Future<MbTilesImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(MbTilesImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(_load(decode));

  Future<ImageInfo> _load(ImageDecoderCallback decode) async {
    final bytes = await map.tile(z, x, y) ?? _empty;
    final codec = await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    final frame = await codec.getNextFrame();
    return ImageInfo(image: frame.image);
  }

  @override
  bool operator ==(Object other) =>
      other is MbTilesImage && identical(other.map, map) && other.z == z && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(identityHashCode(map), z, x, y);
}
