import 'bastion_geo.dart';
import 'bastion_waypoints.dart';

/// Rally points and shared routes, carried as ordinary Meshtastic waypoints
/// so every Meshtastic app still shows them as pins.
///
/// A rally point is a waypoint with the 🚩 icon. A route is a set of
/// waypoints named "<route> 1/4", "<route> 2/4" … from the same sender,
/// which this app joins into a line.
abstract final class BastionRoutes {
  /// 🚩, the icon that marks a rally point.
  static const rallyIcon = 0x1F6A9;

  /// 🔸, the icon used for route stops.
  static const stopIcon = 0x1F538;

  /// Each stop is a separate packet, so routes stay short.
  static const maxStops = 10;

  static bool isRally(MeshWaypoint w) => w.icon == rallyIcon;

  static final _stopName = RegExp(r'^(.*\S) (\d{1,2})/(\d{1,2})$');

  /// The route name, stop number and stop count in [w]'s name, if any.
  static ({String route, int index, int count})? stopOf(MeshWaypoint w) {
    final m = _stopName.firstMatch(w.name);
    if (m == null) return null;
    final index = int.parse(m.group(2)!), count = int.parse(m.group(3)!);
    if (count < 2 || count > maxStops || index < 1 || index > count) return null;
    return (route: m.group(1)!, index: index, count: count);
  }

  /// Joins route stops in [waypoints] into routes, newest sender first.
  /// Stops of one route share a name, a stop count and a sender.
  static List<SharedRoute> group(List<MeshWaypoint> waypoints) {
    final byKey = <(int?, String, int), Map<int, MeshWaypoint>>{};
    for (final w in waypoints) {
      final stop = stopOf(w);
      if (stop == null) continue;
      (byKey[(w.from, stop.route, stop.count)] ??= {})[stop.index] = w;
    }
    return [
      for (final MapEntry(:key, :value) in byKey.entries)
        SharedRoute(
          name: key.$2,
          from: key.$1,
          count: key.$3,
          stops: [for (final i in value.keys.toList()..sort()) value[i]!],
        ),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// The waypoints that share a route named [name] through [points], each
  /// [lifetime] long. The name is shortened so "<name> 10/10" fits.
  static List<MeshWaypoint> build({
    required String name,
    required List<({double latitude, double longitude})> points,
    required int Function() newId,
    DateTime? expires,
    int lockedTo = 0,
  }) {
    if (points.length < 2) throw ArgumentError('A route needs at least two stops.');
    if (points.length > maxStops) throw ArgumentError('A route can have at most $maxStops stops.');
    final count = points.length;
    final suffixRoom = ' $count/$count'.length;
    var base = name.trim().isEmpty ? 'Route' : name.trim();
    final room = BastionWaypointStore.maxNameLength - suffixRoom;
    if (base.length > room) base = base.substring(0, room).trimRight();
    return [
      for (final (i, p) in points.indexed)
        MeshWaypoint(
          id: newId(),
          latitude: p.latitude,
          longitude: p.longitude,
          name: '$base ${i + 1}/$count',
          description: i == 0 ? 'Start of route $base' : i == count - 1 ? 'End of route $base' : '',
          icon: stopIcon,
          expires: expires,
          lockedTo: lockedTo,
        ),
    ];
  }

  /// Length of a path through [points], in metres.
  static double lengthOf(List<({double latitude, double longitude})> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += BastionGeo.distanceMeters(
          points[i - 1].latitude, points[i - 1].longitude, points[i].latitude, points[i].longitude);
    }
    return total;
  }
}

/// A route other radios (or this one) shared as numbered waypoints.
class SharedRoute {
  const SharedRoute({required this.name, required this.from, required this.count, required this.stops});

  final String name;

  /// Sender, or null when shared from this phone.
  final int? from;

  /// How many stops the route has; [stops] may have fewer if some were missed.
  final int count;

  /// Stops heard so far, in route order.
  final List<MeshWaypoint> stops;

  bool get complete => stops.length == count;

  List<({double latitude, double longitude})> get points =>
      [for (final s in stops) (latitude: s.latitude, longitude: s.longitude)];

  double get lengthMeters => BastionRoutes.lengthOf(points);
}
