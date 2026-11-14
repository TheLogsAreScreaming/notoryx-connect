import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

/// A named point in an imported map file.
@immutable
class LayerPoint {
  const LayerPoint({required this.name, required this.latitude, required this.longitude, this.note = ''});

  final String name;
  final double latitude;
  final double longitude;
  final String note;

  Map<String, Object?> toJson() => {'n': name, 'a': latitude, 'o': longitude, if (note.isNotEmpty) 'd': note};

  static LayerPoint? fromJson(Object? j) {
    if (j is! Map) return null;
    final a = j['a'], o = j['o'], n = j['n'];
    if (a is! num || o is! num || n is! String) return null;
    if (!BastionMapLayers.validPosition(a.toDouble(), o.toDouble())) return null;
    return LayerPoint(name: n, latitude: a.toDouble(), longitude: o.toDouble(), note: j['d'] as String? ?? '');
  }
}

/// A named line (route, track or area outline) in an imported map file.
@immutable
class LayerLine {
  const LayerLine({required this.name, required this.points});

  final String name;

  /// (latitude, longitude) pairs.
  final List<(double, double)> points;

  Map<String, Object?> toJson() => {
        'n': name,
        'p': [for (final (a, o) in points) [a, o]],
      };

  static LayerLine? fromJson(Object? j) {
    if (j is! Map || j['n'] is! String || j['p'] is! List) return null;
    final pts = <(double, double)>[
      for (final p in j['p'] as List)
        if (p is List && p.length == 2 && p[0] is num && p[1] is num)
          ((p[0] as num).toDouble(), (p[1] as num).toDouble()),
    ];
    if (pts.length < 2) return null;
    return LayerLine(name: j['n'] as String, points: pts);
  }
}

/// One imported file shown on the map. Kept on this phone only; nothing
/// in a layer is sent over the mesh.
@immutable
class MapLayer {
  const MapLayer({required this.id, required this.name, required this.points, required this.lines, this.visible = true});

  final String id;
  final String name;
  final List<LayerPoint> points;
  final List<LayerLine> lines;
  final bool visible;

  bool get isEmpty => points.isEmpty && lines.isEmpty;

  MapLayer copyWith({bool? visible}) =>
      MapLayer(id: id, name: name, points: points, lines: lines, visible: visible ?? this.visible);

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'visible': visible,
        'points': [for (final p in points) p.toJson()],
        'lines': [for (final l in lines) l.toJson()],
      };

  static MapLayer? fromJson(Object? j) {
    if (j is! Map || j['id'] is! String || j['name'] is! String) return null;
    return MapLayer(
      id: j['id'] as String,
      name: j['name'] as String,
      visible: j['visible'] as bool? ?? true,
      points: [for (final p in (j['points'] as List?) ?? const []) ?LayerPoint.fromJson(p)],
      lines: [for (final l in (j['lines'] as List?) ?? const []) ?LayerLine.fromJson(l)],
    );
  }
}

/// Imported GPX, KML and GeoJSON files drawn on the map.
class BastionMapLayers extends ChangeNotifier {
  BastionMapLayers({SharedPreferencesAsync? preferences}) : _preferences = preferences;

  static final instance = BastionMapLayers();

  static const key = 'bastion.map_layers.v1';
  static const maxLayers = 20;
  static const maxPointsPerLayer = 1000;
  static const maxLinePoints = 500;

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();
  final List<MapLayer> _layers = [];
  bool _loaded = false;

  List<MapLayer> get layers => List.unmodifiable(_layers);

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = await _store.getString(key);
      if (raw == null) return;
      final list = jsonDecode(raw);
      if (list is! List) return;
      _layers
        ..clear()
        ..addAll([for (final l in list) ?MapLayer.fromJson(l)]);
      notifyListeners();
    } catch (_) {
      // A damaged store is ignored rather than blocking the map.
    }
  }

  /// Parses [text] (GPX, KML or GeoJSON) and adds it as a layer called [name].
  /// Throws [FormatException] for unreadable or empty files, and
  /// [StateError] when [maxLayers] are already saved.
  Future<MapLayer> import(String name, String text) async {
    if (_layers.length >= maxLayers) throw StateError('Too many map layers');
    final parsed = parse(text, name: name, id: 'layer-${DateTime.now().microsecondsSinceEpoch}');
    if (parsed.isEmpty) throw const FormatException('No points or lines found');
    _layers.add(parsed);
    await _save();
    notifyListeners();
    return parsed;
  }

  Future<void> setVisible(String id, bool visible) async {
    final i = _layers.indexWhere((l) => l.id == id);
    if (i < 0) return;
    _layers[i] = _layers[i].copyWith(visible: visible);
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _layers.removeWhere((l) => l.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      await _store.setString(key, jsonEncode([for (final l in _layers) l.toJson()]));
    } catch (_) {
      // Layers still show this session.
    }
  }

  static bool validPosition(double lat, double lon) =>
      lat.isFinite && lon.isFinite && lat.abs() <= 90 && lon.abs() <= 180;

  /// Reads GPX, KML or GeoJSON, telling them apart by content.
  static MapLayer parse(String text, {required String name, required String id}) {
    final t = text.trimLeft();
    final (points, lines) = t.startsWith('{')
        ? _geoJson(t)
        : _xml(t);
    return MapLayer(
      id: id,
      name: name,
      points: points.take(maxPointsPerLayer).toList(),
      lines: lines,
    );
  }

  static List<T> _thin<T>(List<T> items, int max) {
    if (items.length <= max) return items;
    return [for (var i = 0; i < max; i++) items[(i * (items.length - 1) / (max - 1)).round()]];
  }

  static String _name(String? n, String fallback) => (n != null && n.trim().isNotEmpty) ? n.trim() : fallback;

  static (List<LayerPoint>, List<LayerLine>) _xml(String text) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(text);
    } on XmlException catch (e) {
      throw FormatException('Not a GPX or KML file: ${e.message}');
    }
    final root = doc.rootElement.localName.toLowerCase();
    if (root == 'gpx') return _gpx(doc);
    if (root == 'kml') return _kml(doc);
    throw const FormatException('Not a GPX, KML or GeoJSON file');
  }

  static String? _child(XmlElement e, String tag) => e.findElements(tag, namespaceUri: '*').firstOrNull?.innerText;

  static (double, double)? _attrPoint(XmlElement e) {
    final lat = double.tryParse(e.getAttribute('lat') ?? '');
    final lon = double.tryParse(e.getAttribute('lon') ?? '');
    if (lat == null || lon == null || !validPosition(lat, lon)) return null;
    return (lat, lon);
  }

  static (List<LayerPoint>, List<LayerLine>) _gpx(XmlDocument doc) {
    final points = <LayerPoint>[];
    final lines = <LayerLine>[];
    var i = 0;
    for (final w in doc.findAllElements('wpt', namespaceUri: '*')) {
      final p = _attrPoint(w);
      if (p == null) continue;
      points.add(LayerPoint(
        name: _name(_child(w, 'name'), 'Point ${++i}'),
        latitude: p.$1,
        longitude: p.$2,
        note: (_child(w, 'desc') ?? _child(w, 'cmt') ?? '').trim(),
      ));
    }
    void line(XmlElement owner, Iterable<XmlElement> pts, String fallback) {
      final list = [for (final p in pts) ?_attrPoint(p)];
      if (list.length >= 2) {
        lines.add(LayerLine(name: _name(_child(owner, 'name'), fallback), points: _thin(list, maxLinePoints)));
      }
    }

    var r = 0;
    for (final rte in doc.findAllElements('rte', namespaceUri: '*')) {
      line(rte, rte.findElements('rtept', namespaceUri: '*'), 'Route ${++r}');
    }
    for (final trk in doc.findAllElements('trk', namespaceUri: '*')) {
      line(trk, trk.findAllElements('trkpt', namespaceUri: '*'), 'Track ${++r}');
    }
    return (points, lines);
  }

  static (List<LayerPoint>, List<LayerLine>) _kml(XmlDocument doc) {
    (double, double)? coord(String raw) {
      final parts = raw.trim().split(',');
      if (parts.length < 2) return null;
      final lon = double.tryParse(parts[0]), lat = double.tryParse(parts[1]);
      if (lat == null || lon == null || !validPosition(lat, lon)) return null;
      return (lat, lon);
    }

    List<String> coords(XmlElement e) =>
        (e.findAllElements('coordinates', namespaceUri: '*').firstOrNull?.innerText ?? '')
            .trim()
            .split(RegExp(r'\s+'))
            .where((s) => s.isNotEmpty)
            .toList();

    final points = <LayerPoint>[];
    final lines = <LayerLine>[];
    var i = 0, r = 0;
    for (final mark in doc.findAllElements('Placemark', namespaceUri: '*')) {
      final name = _child(mark, 'name');
      final note = (_child(mark, 'description') ?? '').trim();
      for (final pt in mark.findAllElements('Point', namespaceUri: '*')) {
        final c = coords(pt);
        final p = c.isEmpty ? null : coord(c.first);
        if (p != null) points.add(LayerPoint(name: _name(name, 'Point ${++i}'), latitude: p.$1, longitude: p.$2, note: note));
      }
      for (final ln in [
        ...mark.findAllElements('LineString', namespaceUri: '*'),
        for (final poly in mark.findAllElements('Polygon', namespaceUri: '*'))
          ...poly.findAllElements('outerBoundaryIs', namespaceUri: '*'),
      ]) {
        final list = [for (final c in coords(ln)) ?coord(c)];
        if (list.length >= 2) lines.add(LayerLine(name: _name(name, 'Line ${++r}'), points: _thin(list, maxLinePoints)));
      }
    }
    return (points, lines);
  }

  static (List<LayerPoint>, List<LayerLine>) _geoJson(String text) {
    final Object? root;
    try {
      root = jsonDecode(text);
    } on FormatException catch (e) {
      throw FormatException('Not a GeoJSON file: ${e.message}');
    }
    if (root is! Map) throw const FormatException('Not a GeoJSON file');
    final points = <LayerPoint>[];
    final lines = <LayerLine>[];
    var i = 0, r = 0;

    (double, double)? pos(Object? c) {
      if (c is! List || c.length < 2 || c[0] is! num || c[1] is! num) return null;
      final lon = (c[0] as num).toDouble(), lat = (c[1] as num).toDouble();
      return validPosition(lat, lon) ? (lat, lon) : null;
    }

    void addPoint(Object? c, String? name, String note) {
      final p = pos(c);
      if (p != null) points.add(LayerPoint(name: _name(name, 'Point ${++i}'), latitude: p.$1, longitude: p.$2, note: note));
    }

    void addLine(Object? c, String? name) {
      if (c is! List) return;
      final list = [for (final p in c) ?pos(p)];
      if (list.length >= 2) lines.add(LayerLine(name: _name(name, 'Line ${++r}'), points: _thin(list, maxLinePoints)));
    }

    void geometry(Object? g, String? name, String note) {
      if (g is! Map) return;
      final c = g['coordinates'];
      switch (g['type']) {
        case 'Point':
          addPoint(c, name, note);
        case 'MultiPoint':
          if (c is List) {
            for (final p in c) {
              addPoint(p, name, note);
            }
          }
        case 'LineString':
          addLine(c, name);
        case 'MultiLineString':
          if (c is List) {
            for (final l in c) {
              addLine(l, name);
            }
          }
        case 'Polygon':
          if (c is List && c.isNotEmpty) addLine(c.first, name);
        case 'MultiPolygon':
          if (c is List) {
            for (final poly in c) {
              if (poly is List && poly.isNotEmpty) addLine(poly.first, name);
            }
          }
        case 'GeometryCollection':
          if (g['geometries'] case final List list) {
            for (final sub in list) {
              geometry(sub, name, note);
            }
          }
      }
    }

    void feature(Object? f) {
      if (f is! Map) return;
      final props = f['properties'];
      String? name;
      var note = '';
      if (props is Map) {
        if ((props['name'] ?? props['title']) case final String n) name = n;
        if ((props['description'] ?? props['desc']) case final String d) note = d.trim();
      }
      geometry(f['geometry'], name, note);
    }

    switch (root['type']) {
      case 'FeatureCollection':
        if (root['features'] case final List fs) {
          for (final f in fs) {
            feature(f);
          }
        }
      case 'Feature':
        feature(root);
      case 'Point' || 'MultiPoint' || 'LineString' || 'MultiLineString' || 'Polygon' || 'MultiPolygon' || 'GeometryCollection':
        geometry(root, null, '');
      default:
        throw const FormatException('Not a GeoJSON file');
    }
    return (points, lines);
  }

}
