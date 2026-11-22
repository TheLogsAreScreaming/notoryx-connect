import 'dart:convert';

import 'bastion_coverage_grid.dart';
import 'bastion_drive_log.dart';
import 'bastion_geo.dart';

/// File kinds a drive can be exported as.
enum DriveExportFormat {
  gpx('gpx', 'application/gpx+xml'),
  kml('kml', 'application/vnd.google-earth.kml+xml'),
  csv('csv', 'text/csv'),
  geojson('geojson', 'application/geo+json'),
  drive('json', 'application/json');

  const DriveExportFormat(this.extension, this.mimeType);
  final String extension;
  final String mimeType;
}

/// One drive ready to write out: the trip, its trail and its readings,
/// after any trimming.
class DriveExport {
  const DriveExport({
    required this.trip,
    required this.points,
    required this.samples,
    this.trimmedMeters = 0,
  });

  final DriveTrip trip;
  final List<DrivePoint> points;
  final List<DriveSample> samples;

  /// How far around the start and end was left out, 0 for none.
  final double trimmedMeters;

  /// Drops everything within [meters] of where the drive started and
  /// ended, so a shared file doesn't point at a home or workplace.
  static DriveExport of(
    BastionDriveLog log,
    DriveTrip trip, {
    double trimMeters = defaultTrimMeters,
  }) {
    // The saved record, in case [trip] was copied before the drive ended.
    trip = log.trips.where((t) => t.id == trip.id).firstOrNull ?? trip;
    final points = log.pointsOf(trip.id).toList();
    final samples = log.samplesOf(trip: trip.id).toList();
    if (trimMeters <= 0)
      return DriveExport(trip: trip, points: points, samples: samples);
    final ends = [
      if (points.isNotEmpty)
        ...[points.first, points.last].map((p) => (p.latitude, p.longitude))
      else if (samples.isNotEmpty)
        ...[samples.first, samples.last].map((s) => (s.latitude, s.longitude)),
    ];
    bool near(double lat, double lon) => ends.any(
      (e) => BastionGeo.distanceMeters(e.$1, e.$2, lat, lon) < trimMeters,
    );
    return DriveExport(
      trip: trip,
      points: [
        for (final p in points)
          if (!near(p.latitude, p.longitude)) p,
      ],
      samples: [
        for (final s in samples)
          if (!near(s.latitude, s.longitude)) s,
      ],
      trimmedMeters: trimMeters,
    );
  }

  static const defaultTrimMeters = 500.0;

  /// A file name for [format], from the drive's name.
  String fileName(DriveExportFormat format) {
    final base = trip.name
        .replaceAll(RegExp(r'[^A-Za-z0-9._ -]'), '')
        .trim()
        .replaceAll(' ', '-');
    return '${base.isEmpty ? 'drive' : base}.${format.extension}';
  }

  String write(DriveExportFormat format, {DateTime? now}) => switch (format) {
    DriveExportFormat.gpx => gpx(now: now),
    DriveExportFormat.kml => kml(),
    DriveExportFormat.csv => csv(),
    DriveExportFormat.geojson => geojson(),
    DriveExportFormat.drive => driveFile(now: now),
  };

  /// GPX 1.1: the trail as a track, readings as waypoints.
  String gpx({DateTime? now}) {
    final b = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<gpx version="1.1" creator="NOTORYX Connect" xmlns="http://www.topografix.com/GPX/1/1">',
      )
      ..writeln(
        '  <metadata><name>${_xml(trip.name)}</name><time>${_time(now ?? DateTime.now())}</time></metadata>',
      );
    for (final s in samples) {
      b
        ..writeln(
          '  <wpt lat="${_coord(s.latitude)}" lon="${_coord(s.longitude)}">',
        )
        ..writeln('    <time>${_time(s.time)}</time>')
        ..writeln('    <name>${nodeId(s.from)}</name>')
        ..writeln('    <desc>${_xml(_describe(s))}</desc>')
        ..writeln('  </wpt>');
    }
    if (points.isNotEmpty) {
      b.writeln('  <trk><name>${_xml(trip.name)}</name><trkseg>');
      for (final p in points) {
        b.writeln(
          '    <trkpt lat="${_coord(p.latitude)}" lon="${_coord(p.longitude)}"><time>${_time(p.time)}</time></trkpt>',
        );
      }
      b.writeln('  </trkseg></trk>');
    }
    b.writeln('</gpx>');
    return b.toString();
  }

  /// KML: coloured 300 m coverage squares (direct readings) and the trail.
  String kml() {
    final cells = BastionCoverageGrid.build(samples);
    final b = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<kml xmlns="http://www.opengis.net/kml/2.2"><Document>')
      ..writeln('  <name>${_xml(trip.name)}</name>');
    // KML colours are aabbggrr.
    for (final (band, colour) in [
      (CoverageBand.strong, '6600c853'),
      (CoverageBand.fair, '6600c8ff'),
      (CoverageBand.weak, '663d3dff'),
    ]) {
      b.writeln(
        '  <Style id="${band.name}"><LineStyle><color>ff${colour.substring(2)}</color></LineStyle>'
        '<PolyStyle><color>$colour</color></PolyStyle></Style>',
      );
    }
    for (final c in cells) {
      final ring = [
        (c.west, c.south),
        (c.east, c.south),
        (c.east, c.north),
        (c.west, c.north),
        (c.west, c.south),
      ].map((p) => '${_coord(p.$1)},${_coord(p.$2)},0').join(' ');
      b.writeln(
        '  <Placemark><name>SNR ${c.meanSnr.toStringAsFixed(1)}</name>'
        '<description>${c.readings} readings</description><styleUrl>#${c.band.name}</styleUrl>'
        '<Polygon><outerBoundaryIs><LinearRing><coordinates>$ring</coordinates></LinearRing></outerBoundaryIs></Polygon>'
        '</Placemark>',
      );
    }
    if (points.length >= 2) {
      final line = points
          .map((p) => '${_coord(p.longitude)},${_coord(p.latitude)},0')
          .join(' ');
      b.writeln(
        '  <Placemark><name>${_xml(trip.name)}</name><LineString><coordinates>$line</coordinates></LineString></Placemark>',
      );
    }
    b.writeln('</Document></kml>');
    return b.toString();
  }

  static const csvFields = [
    'ts',
    'lat',
    'lon',
    'accuracy',
    'from_node',
    'packet',
    'port',
    'channel',
    'snr',
    'rssi',
    'hop_start',
    'hop_limit',
    'class',
    'relay',
  ];

  /// One row per reading. Text that a spreadsheet could run as a formula
  /// is prefixed with an apostrophe.
  String csv() {
    String cell(Object? v) {
      var text = v?.toString() ?? '';
      if (v is String && text.isNotEmpty && '=+-@\t\r'.contains(text[0]))
        text = "'$text";
      return '"${text.replaceAll('"', '""')}"';
    }

    final rows = [
      for (final s in samples)
        () {
          final row = s.toRow();
          return csvFields.map((f) => cell(row[f])).join(',');
        }(),
    ];
    return '${csvFields.join(',')}\r\n${rows.map((r) => '$r\r\n').join()}';
  }

  /// GeoJSON: readings as points, direct coverage squares as polygons and
  /// the trail as a line.
  String geojson() {
    final features = <Map<String, Object?>>[
      for (final s in samples)
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [s.longitude, s.latitude],
          },
          'properties': {
            'kind': 'reading',
            'time': s.time.toUtc().toIso8601String(),
            'node': nodeId(s.from),
            'class': s.hops.name,
            'snr': s.snr,
            'rssi': s.rssi,
          },
        },
      for (final c in BastionCoverageGrid.build(samples))
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              [
                [c.west, c.south],
                [c.east, c.south],
                [c.east, c.north],
                [c.west, c.north],
                [c.west, c.south],
              ],
            ],
          },
          'properties': {
            'kind': 'square',
            'meters': 300,
            'readings': c.readings,
            'mean_snr': c.meanSnr,
            'band': c.band.name,
          },
        },
      if (points.length >= 2)
        {
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              for (final p in points) [p.longitude, p.latitude],
            ],
          },
          'properties': {'kind': 'trail', 'name': trip.name},
        },
    ];
    return const JsonEncoder.withIndent(
      '  ',
    ).convert({'type': 'FeatureCollection', 'features': features});
  }

  /// The drive file: everything needed to load the drive into another
  /// phone, versioned so an older app refuses a newer file.
  String driveFile({DateTime? now}) =>
      const JsonEncoder.withIndent(' ').convert({
        'format': DriveFile.format,
        'version': DriveFile.version,
        'app': 'NOTORYX Connect',
        'exported': (now ?? DateTime.now()).toUtc().toIso8601String(),
        'trimmed_meters': trimmedMeters,
        'trip': {
          'name': trip.name,
          'started': trip.started.toUtc().toIso8601String(),
          'ended': trip.ended?.toUtc().toIso8601String(),
        },
        'points': [
          for (final p in points)
            [p.time.toUtc().toIso8601String(), p.latitude, p.longitude],
        ],
        'samples': [
          for (final s in samples)
            {
              for (final e in s.toRow().entries)
                if (e.key != 'trip' && e.value != null) e.key: e.value,
            },
        ],
      });

  static String nodeId(int num) => '!${num.toRadixString(16).padLeft(8, '0')}';

  static String _describe(DriveSample s) => [
    s.hops.name,
    if (s.snr != null) 'SNR ${s.snr!.toStringAsFixed(1)}',
    if (s.rssi != null) 'RSSI ${s.rssi}',
  ].join(', ');

  static String _coord(double v) => v.toStringAsFixed(7);
  static String _time(DateTime t) =>
      '${t.toUtc().toIso8601String().split('.').first}Z';
  static String _xml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;')
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
}

/// A drive file read back in, checked in full before anything is saved.
class DriveFile {
  const DriveFile({
    required this.name,
    required this.started,
    this.ended,
    required this.points,
    required this.samples,
  });

  static const format = 'notoryx-drive';
  static const version = 1;

  final String name;
  final DateTime started;
  final DateTime? ended;

  /// Trip id 0: the real id is given when the drive is saved.
  final List<DrivePoint> points;
  final List<DriveSample> samples;

  /// Reads a drive file. Throws [FormatException] for anything that isn't
  /// a valid drive file this app understands, including one from a newer
  /// version.
  static DriveFile parse(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      throw const FormatException('Not a drive file.');
    }
    if (json is! Map || json['format'] != format)
      throw const FormatException('Not a drive file.');
    final v = json['version'];
    if (v is! int || v < 1) throw const FormatException('Not a drive file.');
    if (v > version)
      throw const FormatException(
        'This drive file is from a newer version of the app.',
      );
    final trip = json['trip'];
    if (trip is! Map)
      throw const FormatException('The drive file has no trip.');
    final name = trip['name'];
    final started = _date(trip['started']);
    final ended = trip['ended'] == null ? null : _date(trip['ended']);
    if (name is! String || name.trim().isEmpty || name.length > 200)
      throw const FormatException('The drive has no name.');
    final rawPoints = json['points'] ?? const [];
    final rawSamples = json['samples'] ?? const [];
    if (rawPoints is! List || rawSamples is! List)
      throw const FormatException('The drive file is damaged.');
    if (rawSamples.length > BastionDriveLog.maxSamples ||
        rawPoints.length > BastionDriveLog.maxPoints)
      throw const FormatException('The drive file is too big.');
    final points = <DrivePoint>[];
    for (final p in rawPoints) {
      if (p is! List || p.length != 3 || p[1] is! num || p[2] is! num)
        throw const FormatException('A trail point is damaged.');
      final lat = (p[1] as num).toDouble(), lon = (p[2] as num).toDouble();
      _checkPosition(lat, lon);
      points.add(
        DrivePoint(trip: 0, time: _date(p[0]), latitude: lat, longitude: lon),
      );
    }
    final samples = <DriveSample>[];
    for (final s in rawSamples) {
      if (s is! Map) throw const FormatException('A reading is damaged.');
      final row = Map<String, Object?>.from(s)..['trip'] = 0;
      final DriveSample sample;
      try {
        _date(row['ts']);
        if (row['class'] is! String ||
            !HopClass.values.any((c) => c.name == row['class']))
          throw const FormatException('');
        sample = DriveSample.fromRow(row);
      } catch (_) {
        throw const FormatException('A reading is damaged.');
      }
      _checkPosition(sample.latitude, sample.longitude);
      if (sample.snr case final snr? when !snr.isFinite)
        throw const FormatException('A reading is damaged.');
      samples.add(sample);
    }
    return DriveFile(
      name: name.trim(),
      started: started,
      ended: ended,
      points: points,
      samples: samples,
    );
  }

  static DateTime _date(Object? v) {
    final parsed = v is String ? DateTime.tryParse(v) : null;
    if (parsed == null)
      throw const FormatException('A date in the drive file is damaged.');
    return parsed.toUtc();
  }

  static void _checkPosition(double lat, double lon) {
    if (!lat.isFinite || !lon.isFinite || lat.abs() > 90 || lon.abs() > 180)
      throw const FormatException('A position in the drive file is damaged.');
  }
}
