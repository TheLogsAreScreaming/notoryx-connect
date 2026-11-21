import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'bastion_trail_graph.dart';

// Big replies are parsed off the UI thread.
(TrailGraph, List<TrailPlace>) _parseOverpass(List<int> body) {
  final json = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
  return (TrailGraph.fromOverpass(json), placesFromOverpass(json));
}

/// Why an area couldn't be saved.
enum TrailDownloadProblem { tooLarge, storageFull, noTrails, failed }

class TrailDownloadException implements Exception {
  const TrailDownloadException(this.problem);
  final TrailDownloadProblem problem;

  @override
  String toString() => 'Trail download: ${problem.name}';
}

/// A downloaded area of trails.
@immutable
class TrailArea {
  const TrailArea({required this.id, required this.name, required this.bounds, required this.bytes});
  final String id;
  final String name;
  final TrailBounds bounds;
  final int bytes;
}

/// Sends the Overpass query; swapped out in tests.
abstract interface class OverpassClient {
  /// The reply body, or throws.
  Future<List<int>> query(String overpassQl);
}

class HttpOverpassClient implements OverpassClient {
  const HttpOverpassClient();

  static final endpoint = Uri.parse('https://overpass-api.de/api/interpreter');
  static const timeout = Duration(seconds: 120);

  @override
  Future<List<int>> query(String overpassQl) async {
    final client = HttpClient()..userAgent = 'NOTORYX-Connect';
    try {
      final request = await client.postUrl(endpoint).timeout(timeout);
      request.headers.contentType = ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');
      request.write('data=${Uri.encodeQueryComponent(overpassQl)}');
      final response = await request.close().timeout(timeout);
      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        bytes.addAll(chunk);
      }
      if (response.statusCode != 200) throw HttpException('Overpass replied ${response.statusCode}');
      return bytes;
    } finally {
      client.close(force: true);
    }
  }
}

/// Downloads walkable trails from OpenStreetMap by area and keeps them on
/// the phone, so routes can be planned with no signal. As on NOTORYX Core.
class BastionTrailStore extends ChangeNotifier {
  BastionTrailStore({OverpassClient client = const HttpOverpassClient(), Directory? directory, this.limitBytes = defaultLimitBytes})
      : _client = client,
        _directory = directory;

  static BastionTrailStore instance = BastionTrailStore();

  static const defaultLimitBytes = 500 * 1024 * 1024;

  final OverpassClient _client;
  final int limitBytes;
  Directory? _directory;
  final List<TrailArea> _areas = [];
  final Map<String, TrailGraph> _loaded = {};
  final Map<String, List<TrailPlace>> _places = {};
  var _seq = 0;
  bool _loadedOnce = false;

  List<TrailArea> get areas => List.unmodifiable(_areas);
  int get usedBytes => _areas.fold(0, (n, a) => n + a.bytes);

  /// A square box [radiusKm] around a point.
  static TrailBounds around(double lat, double lon, double radiusKm) {
    final dLat = radiusKm / 111.32;
    final dLon = radiusKm / (111.32 * math.cos(lat * math.pi / 180).abs().clamp(0.01, 1));
    return TrailBounds(south: lat - dLat, west: lon - dLon, north: lat + dLat, east: lon + dLon);
  }

  Future<Directory> _folder() async {
    final dir = _directory ?? Directory('${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}trails');
    _directory = dir;
    await dir.create(recursive: true);
    return dir;
  }

  String _base(Directory dir, String id) => '${dir.path}${Platform.pathSeparator}$id';

  /// Reads what's already downloaded.
  Future<void> load() async {
    if (kIsWeb) return;
    final dir = await _folder();
    _areas.clear();
    await for (final file in dir.list()) {
      if (file is! File || !file.path.endsWith('.meta')) continue;
      try {
        final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final id = j['id'] as String;
        final data = File('${_base(dir, id)}.trail');
        if (!await data.exists()) continue;
        final places = File('${_base(dir, id)}.places');
        _areas.add(TrailArea(
          id: id,
          name: j['name'] as String,
          bounds: TrailBounds(
            south: (j['s'] as num).toDouble(),
            west: (j['w'] as num).toDouble(),
            north: (j['n'] as num).toDouble(),
            east: (j['e'] as num).toDouble(),
          ),
          bytes: await data.length() + (await places.exists() ? await places.length() : 0),
        ));
      } on Object catch (e) {
        debugPrint('Skipping an unreadable trail area: $e');
      }
    }
    _areas.sort((a, b) => a.id.compareTo(b.id));
    _loadedOnce = true;
    notifyListeners();
  }

  Future<void> ensureLoaded() async {
    if (!_loadedOnce) await load();
  }

  /// Fetches the walkable ways and named places in [bounds] and saves them
  /// as [name]. Only called when someone presses Download.
  Future<TrailArea> download(String name, TrailBounds bounds) async {
    if (bounds.areaKm2 > maxTrailAreaKm2) throw const TrailDownloadException(TrailDownloadProblem.tooLarge);
    final box = '${bounds.south},${bounds.west},${bounds.north},${bounds.east}';
    final query = '[out:json][timeout:90];('
        'way["highway"~"$walkableHighwayPattern"]($box);'
        '${placeQueryStatements(box)}'
        ');out body geom;';
    final TrailGraph graph;
    final List<TrailPlace> places;
    try {
      final body = await _client.query(query);
      (graph, places) = await compute(_parseOverpass, body);
    } on Object catch (e) {
      debugPrint('Trail download failed: $e');
      throw const TrailDownloadException(TrailDownloadProblem.failed);
    }
    if (graph.nodeCount == 0 && places.isEmpty) throw const TrailDownloadException(TrailDownloadProblem.noTrails);
    final bytes = graph.toBytes();
    final placeBytes = placesToBytes(places);
    final size = bytes.length + placeBytes.length;
    if (usedBytes + size > limitBytes) throw const TrailDownloadException(TrailDownloadProblem.storageFull);
    final dir = await _folder();
    final id = '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
    final base = _base(dir, id);
    await File('$base.trail').writeAsBytes(bytes, flush: true);
    await File('$base.places').writeAsBytes(placeBytes, flush: true);
    await File('$base.meta').writeAsString(
      jsonEncode({'id': id, 'name': name, 's': bounds.south, 'w': bounds.west, 'n': bounds.north, 'e': bounds.east}),
      flush: true,
    );
    final area = TrailArea(id: id, name: name, bounds: bounds, bytes: size);
    _areas.add(area);
    _loaded[id] = graph;
    _places[id] = places;
    notifyListeners();
    return area;
  }

  Future<void> delete(String id) async {
    final dir = await _folder();
    final base = _base(dir, id);
    for (final path in ['$base.trail', '$base.places', '$base.meta']) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    _areas.removeWhere((a) => a.id == id);
    _loaded.remove(id);
    _places.remove(id);
    notifyListeners();
  }

  /// Every named place in the downloaded areas.
  Future<List<TrailPlace>> allPlaces() async {
    final dir = await _folder();
    final out = <TrailPlace>[];
    for (final area in _areas) {
      var places = _places[area.id];
      if (places == null) {
        final file = File('${_base(dir, area.id)}.places');
        try {
          places = await file.exists() ? placesFromBytes(await file.readAsBytes()) : const <TrailPlace>[];
        } on FormatException {
          places = const <TrailPlace>[];
        }
        _places[area.id] = places;
      }
      out.addAll(places);
    }
    return out;
  }

  /// The downloaded area holding both points, or null.
  TrailArea? areaFor(double lat1, double lon1, double lat2, double lon2) {
    for (final area in _areas) {
      if (area.bounds.contains(lat1, lon1) && area.bounds.contains(lat2, lon2)) return area;
    }
    return null;
  }

  Future<TrailGraph> graphFor(TrailArea area) async {
    final cached = _loaded[area.id];
    if (cached != null) return cached;
    final dir = await _folder();
    final graph = TrailGraph.fromBytes(await File('${_base(dir, area.id)}.trail').readAsBytes());
    _loaded[area.id] = graph;
    return graph;
  }
}
