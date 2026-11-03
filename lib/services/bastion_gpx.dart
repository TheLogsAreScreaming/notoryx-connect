import 'bastion_trails.dart';
import 'bastion_waypoints.dart';

/// A movement trail to export, with the name shown in mapping apps.
typedef GpxTrack = ({String name, List<TrailPoint> points});

/// Writes GPX 1.1 for waypoints and trails, readable by Gaia GPS, CalTopo,
/// OsmAnd, Google Earth and most GPS units.
abstract final class BastionGpx {
  static String build({
    required List<MeshWaypoint> waypoints,
    required List<GpxTrack> tracks,
    required DateTime createdAt,
  }) {
    final b = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<gpx version="1.1" creator="NOTORYX Connect" '
          'xmlns="http://www.topografix.com/GPX/1/1">')
      ..writeln('  <metadata><name>NOTORYX Connect export</name>'
          '<time>${_time(createdAt)}</time></metadata>');
    for (final w in waypoints) {
      b
        ..writeln('  <wpt lat="${_coord(w.latitude)}" lon="${_coord(w.longitude)}">')
        ..writeln('    <name>${_escape(w.name)}</name>');
      if (w.description.isNotEmpty) b.writeln('    <desc>${_escape(w.description)}</desc>');
      b.writeln('  </wpt>');
    }
    for (final t in tracks) {
      if (t.points.isEmpty) continue;
      b
        ..writeln('  <trk><name>${_escape(t.name)}</name><trkseg>')
        ..writeAll([
          for (final p in t.points)
            '    <trkpt lat="${_coord(p.latitude)}" lon="${_coord(p.longitude)}"><time>${_time(p.time)}</time></trkpt>\n',
        ])
        ..writeln('  </trkseg></trk>');
    }
    b.writeln('</gpx>');
    return b.toString();
  }

  static String _coord(double v) => v.toStringAsFixed(7);

  static String _time(DateTime t) => '${t.toUtc().toIso8601String().split('.').first}Z';

  static String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;')
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
}
