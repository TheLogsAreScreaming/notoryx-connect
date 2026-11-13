import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bastion_field_alerts.dart';
import 'bastion_geo.dart';

/// Whose movement a zone watches.
enum GeofenceWatch { tripContacts, favorites, allNodes }

/// When a zone alerts.
enum GeofenceAlertOn { arrive, leave, both }

/// A circle on the map that alerts when watched nodes arrive or leave.
@immutable
class BastionGeofence {
  const BastionGeofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.watch = GeofenceWatch.tripContacts,
    this.alertOn = GeofenceAlertOn.both,
  });

  /// Radius choices offered when adding a zone.
  static const radiusChoices = [100.0, 250.0, 500.0, 1000.0, 2000.0, 5000.0];

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final GeofenceWatch watch;
  final GeofenceAlertOn alertOn;

  bool get alertsOnArrive => alertOn != GeofenceAlertOn.leave;
  bool get alertsOnLeave => alertOn != GeofenceAlertOn.arrive;

  /// GPS positions wander; a node must be this far past the edge to change
  /// sides, so one standing on the line doesn't alert over and over.
  double get margin => math.max(20, radiusMeters * 0.1);

  Map<String, Object> toJson() => {
    'id': id, 'name': name, 'lat': latitude, 'lon': longitude,
    'radius': radiusMeters, 'watch': watch.name, 'alertOn': alertOn.name,
  };

  static BastionGeofence? fromJson(Object? json) {
    if (json is! Map) return null;
    final lat = json['lat'], lon = json['lon'], radius = json['radius'];
    final id = json['id'], name = json['name'];
    if (id is! String || name is! String || lat is! num || lon is! num || radius is! num) return null;
    if (lat.abs() > 90 || lon.abs() > 180 || radius <= 0) return null;
    return BastionGeofence(
      id: id, name: name, latitude: lat.toDouble(), longitude: lon.toDouble(),
      radiusMeters: radius.toDouble(),
      watch: GeofenceWatch.values.where((w) => w.name == json['watch']).firstOrNull ??
          GeofenceWatch.tripContacts,
      alertOn: GeofenceAlertOn.values.where((a) => a.name == json['alertOn']).firstOrNull ??
          GeofenceAlertOn.both,
    );
  }
}

/// A watched node's position, as the engine sees it.
typedef GeofencePosition = ({int num, String name, double latitude, double longitude});

/// Saved zones. Unreadable storage is never overwritten.
class BastionGeofenceStore {
  BastionGeofenceStore({SharedPreferencesAsync? preferences}) : _preferences = preferences;

  static const key = 'bastion.geofences.v1';
  static const maxZones = 20;

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();
  final List<BastionGeofence> _zones = [];
  bool _loadFailed = false;

  List<BastionGeofence> get zones => List.unmodifiable(_zones);

  Future<void> load() async {
    _zones.clear();
    try {
      final raw = await _store.getString(key);
      if (raw == null) return;
      final list = jsonDecode(raw);
      if (list is! List) return;
      _zones.addAll(list.map(BastionGeofence.fromJson).nonNulls);
    } on FormatException {
      // Damaged zones are replaced by the next change.
    } catch (_) {
      _loadFailed = true;
    }
  }

  /// Adds or replaces [zone] (by id). Returns a problem for the user, or null.
  Future<String?> put(BastionGeofence zone) async {
    if (_loadFailed) return 'Zones could not be read from phone storage, so changes are not saved.';
    final i = _zones.indexWhere((z) => z.id == zone.id);
    if (i < 0 && _zones.length >= maxZones) return 'You can have up to $maxZones zones.';
    if (i < 0) {
      _zones.add(zone);
    } else {
      _zones[i] = zone;
    }
    return _save();
  }

  Future<String?> remove(String id) async {
    if (_loadFailed) return 'Zones could not be read from phone storage, so changes are not saved.';
    _zones.removeWhere((z) => z.id == id);
    return _save();
  }

  Future<String?> _save() async {
    try {
      await _store.setString(key, jsonEncode([for (final z in _zones) z.toJson()]));
      return null;
    } catch (_) {
      return 'The change applies now but could not be saved.';
    }
  }
}

/// Decides zone alerts from node positions. A node's first position in a
/// session only sets which side it is on, so connecting never sets off a
/// burst of alerts; after that each crossing alerts once.
class BastionGeofenceEngine {
  final Map<String, bool> _inside = {};
  bool _inSession = false;

  void startSession() {
    _inside.clear();
    _inSession = true;
  }

  void endSession() {
    _inside.clear();
    _inSession = false;
  }

  /// Checks [positions] of the nodes [watched] by each zone.
  List<BastionFieldAlert> check(
    List<BastionGeofence> zones,
    Iterable<GeofencePosition> positions,
    Set<int> Function(GeofenceWatch) watched,
  ) {
    if (!_inSession) return const [];
    final alerts = <BastionFieldAlert>[];
    final live = <String>{};
    for (final zone in zones) {
      final nodes = watched(zone.watch);
      for (final p in positions) {
        if (!nodes.contains(p.num)) continue;
        final key = '${zone.id}:${p.num}';
        live.add(key);
        final distance = BastionGeo.distanceMeters(zone.latitude, zone.longitude, p.latitude, p.longitude);
        final was = _inside[key];
        final now = was == null
            ? distance <= zone.radiusMeters
            : was
                ? distance <= zone.radiusMeters + zone.margin
                : distance < zone.radiusMeters - zone.margin;
        _inside[key] = now;
        if (was == null || was == now) continue;
        if (now && zone.alertsOnArrive) {
          alerts.add(BastionFieldAlert(BastionAlertKind.geofenceArrive, p.num,
              '${p.name} arrived at ${zone.name}', '${p.name} is inside ${zone.name}.'));
        } else if (!now && zone.alertsOnLeave) {
          alerts.add(BastionFieldAlert(BastionAlertKind.geofenceLeave, p.num,
              '${p.name} left ${zone.name}', '${p.name} is outside ${zone.name}.'));
        }
      }
    }
    // Forget nodes no longer watched (trip ended, zone deleted), so a later
    // first position only sets the side again.
    _inside.removeWhere((key, _) => !live.contains(key));
    return alerts;
  }
}

/// A shared route watched for people wandering off it. Keeps its own copy of
/// the route's points, so it keeps working after the route's waypoints
/// expire.
@immutable
class BastionRouteWatch {
  const BastionRouteWatch({
    required this.name,
    required this.points,
    this.limitMeters = 100,
    this.watch = GeofenceWatch.tripContacts,
  });

  final String name;
  final List<({double latitude, double longitude})> points;

  /// Farther than this from the route counts as off it.
  final double limitMeters;
  final GeofenceWatch watch;

  static const limits = [25.0, 50.0, 100.0, 200.0, 500.0, 1000.0];

  Map<String, Object?> toJson() => {
        'name': name,
        'limit': limitMeters,
        'watch': watch.name,
        'points': [for (final p in points) [p.latitude, p.longitude]],
      };

  static BastionRouteWatch? fromJson(Object? json) {
    if (json is! Map) return null;
    final name = json['name'], limit = json['limit'], raw = json['points'];
    if (name is! String || limit is! num || limit <= 0 || raw is! List) return null;
    final points = [
      for (final p in raw)
        if (p is List && p.length == 2 && p[0] is num && p[1] is num)
          (latitude: (p[0] as num).toDouble(), longitude: (p[1] as num).toDouble()),
    ];
    if (points.length < 2) return null;
    return BastionRouteWatch(
      name: name,
      points: points,
      limitMeters: limit.toDouble(),
      watch: GeofenceWatch.values.where((w) => w.name == json['watch']).firstOrNull ??
          GeofenceWatch.tripContacts,
    );
  }

  /// Shortest distance from a point to the route line, in metres; each
  /// segment is flattened around the point.
  static double metersFrom(
    double latitude,
    double longitude,
    List<({double latitude, double longitude})> line,
  ) {
    const earth = 6371008.8;
    double rad(double d) => d * math.pi / 180;
    final k = math.cos(rad(latitude));
    ({double x, double y}) local(({double latitude, double longitude}) p) => (
          x: rad(p.longitude - longitude) * k * earth,
          y: rad(p.latitude - latitude) * earth,
        );
    var a = local(line.first);
    var best = math.sqrt(a.x * a.x + a.y * a.y);
    for (var i = 1; i < line.length; i++) {
      final b = local(line[i]);
      final dx = b.x - a.x, dy = b.y - a.y;
      final len2 = dx * dx + dy * dy;
      final t = len2 == 0 ? 0.0 : (-(a.x * dx + a.y * dy) / len2).clamp(0.0, 1.0);
      final px = a.x + t * dx, py = a.y + t * dy;
      best = math.min(best, math.sqrt(px * px + py * py));
      a = b;
    }
    return best;
  }
}

/// The one watched route, kept on the phone.
class BastionRouteWatchStore {
  BastionRouteWatchStore({SharedPreferencesAsync? preferences}) : _preferences = preferences;

  static const key = 'bastion.route_watch.v1';
  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();
  BastionRouteWatch? watch;

  Future<void> load() async {
    try {
      final raw = await _store.getString(key);
      watch = raw == null ? null : BastionRouteWatch.fromJson(jsonDecode(raw));
    } catch (_) {
      watch = null;
    }
  }

  /// Saves [next], or stops watching when null. Returns a problem, or null.
  Future<String?> set(BastionRouteWatch? next) async {
    watch = next;
    try {
      if (next == null) {
        await _store.remove(key);
      } else {
        await _store.setString(key, jsonEncode(next.toJson()));
      }
      return null;
    } catch (_) {
      return 'The change applies now but could not be saved.';
    }
  }
}

/// Decides off-route alerts. A node's first position in a session only sets
/// which side it is on; after that it alerts once when it goes past the
/// limit and rearms once it is back within 70% of it.
class BastionRouteWatchEngine {
  final Map<int, bool> _off = {};
  bool _inSession = false;
  BastionRouteWatch? _last;

  void startSession() {
    _off.clear();
    _inSession = true;
  }

  void endSession() {
    _off.clear();
    _inSession = false;
  }

  List<BastionFieldAlert> check(
    BastionRouteWatch? route,
    Iterable<GeofencePosition> positions,
    Set<int> watched,
  ) {
    if (!identical(route, _last)) {
      _off.clear();
      _last = route;
    }
    if (!_inSession || route == null) return const [];
    final alerts = <BastionFieldAlert>[];
    for (final p in positions) {
      if (!watched.contains(p.num)) continue;
      final d = BastionRouteWatch.metersFrom(p.latitude, p.longitude, route.points);
      final was = _off[p.num];
      final off = (was ?? false) ? d > route.limitMeters * .7 : d > route.limitMeters;
      _off[p.num] = off;
      if (was == false && off) {
        alerts.add(BastionFieldAlert(BastionAlertKind.offRoute, p.num,
            '${p.name} is off ${route.name}', '${p.name} is ${d.round()} m from ${route.name}.'));
      }
    }
    _off.removeWhere((num, _) => !watched.contains(num));
    return alerts;
  }
}
