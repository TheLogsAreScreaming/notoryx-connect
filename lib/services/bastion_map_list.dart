import 'bastion_coverage_grid.dart';
import 'bastion_geo.dart';
import 'bastion_waypoints.dart';
import 'meshtastic_node_database.dart';

enum MapListKind { teamMember, node, waypoint, weakArea }

/// One thing on the map, described without needing to see it.
class MapListRow {
  const MapListRow({
    required this.kind,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.num,
    this.meters,
    this.bearing,
    this.heard,
    this.positionAt,
    this.readings,
    this.snr,
  });

  final MapListKind kind;
  final String name;
  final double latitude, longitude;

  /// Nodes and trip contacts: the node number, to open its details.
  final int? num;

  /// From this radio's position; null when that isn't known.
  final double? meters;

  /// Compass bearing from this radio, 0–360; null with [meters].
  final double? bearing;

  /// Nodes: when last heard, and when their position was taken. Weak areas:
  /// [heard] is when the newest reading there was taken.
  final DateTime? heard;
  final DateTime? positionAt;

  /// Weak areas: how many readings and their mean SNR.
  final int? readings;
  final double? snr;
}

/// Eight compass directions, for words rather than "NE".
enum CompassPoint { n, ne, e, se, s, sw, w, nw }

CompassPoint compassOf(double bearing) =>
    CompassPoint.values[((bearing % 360) / 45).round() % 8];

/// Everything on the map as rows: trip contacts and other nodes with a
/// position, waypoints, and squares of weak coverage. Each group nearest
/// first; without a position for this radio, by name.
({List<MapListRow> team, List<MapListRow> nodes, List<MapListRow> waypoints, List<MapListRow> weakAreas})
    buildMapList({
  (double, double)? me,
  int? selfNum,
  Set<int> team = const {},
  required Iterable<MeshtasticNode> nodes,
  required Iterable<MeshWaypoint> waypoints,
  required Iterable<CoverageCell> cells,
}) {
  MapListRow row(MapListKind kind, String name, double lat, double lon,
      {int? num, DateTime? heard, DateTime? positionAt, int? readings, double? snr}) {
    final from = me;
    return MapListRow(
      kind: kind,
      name: name,
      latitude: lat,
      longitude: lon,
      num: num,
      meters: from == null ? null : BastionGeo.distanceMeters(from.$1, from.$2, lat, lon),
      bearing: from == null ? null : BastionGeo.bearingDegrees(from.$1, from.$2, lat, lon),
      heard: heard,
      positionAt: positionAt,
      readings: readings,
      snr: snr,
    );
  }

  int byDistance(MapListRow a, MapListRow b) {
    final da = a.meters, db = b.meters;
    if (da != null && db != null && da != db) return da.compareTo(db);
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  }

  MapListRow nodeRow(MeshtasticNode n, MapListKind kind) => row(kind, n.displayName, n.latitude!, n.longitude!,
      num: n.num, heard: n.lastHeard, positionAt: n.positionTime);
  final placed = [for (final n in nodes) if (n.hasPosition && n.num != selfNum) n];

  return (
    team: [for (final n in placed) if (team.contains(n.num)) nodeRow(n, MapListKind.teamMember)]..sort(byDistance),
    nodes: [for (final n in placed) if (!team.contains(n.num)) nodeRow(n, MapListKind.node)]..sort(byDistance),
    waypoints: [
      for (final w in waypoints) row(MapListKind.waypoint, w.name, w.latitude, w.longitude),
    ]..sort(byDistance),
    weakAreas: [
      for (final c in cells)
        if (c.band == CoverageBand.weak)
          row(MapListKind.weakArea, '', c.centreLatitude, c.centreLongitude,
              heard: c.latest, readings: c.readings, snr: c.meanSnr),
    ]..sort(byDistance),
  );
}

/// Whether [row] matches a search [query]: name, or the node ID in hex
/// (with or without the leading "!"). An empty query matches everything.
bool mapListMatches(MapListRow row, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (row.name.toLowerCase().contains(q)) return true;
  final num = row.num;
  if (num == null) return false;
  final id = num.toRadixString(16).padLeft(8, '0');
  return id.contains(q.startsWith('!') ? q.substring(1) : q);
}
