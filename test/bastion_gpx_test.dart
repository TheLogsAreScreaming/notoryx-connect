import 'dart:io';

import 'package:bastion/map_page.dart';
import 'package:bastion/services/bastion_gpx.dart';
import 'package:bastion/services/bastion_trails.dart';
import 'package:bastion/services/bastion_waypoints.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime.utc(2026, 10, 29, 15, 4, 5);
  final waypoint = MeshWaypoint(id: 1, latitude: 35.1234567, longitude: -83.7654321,
      name: 'Camp <A> & "B"', description: "Bob's\u0007 spot");
  final track = (name: 'Ridge', points: [
    TrailPoint(35.0, -83.0, DateTime.utc(2026, 10, 29, 12)),
    TrailPoint(35.001, -83.0, DateTime.utc(2026, 10, 29, 12, 5)),
  ]);

  test('GPX 1.1 with waypoints and tracks, escaped and in UTC', () {
    final gpx = BastionGpx.build(waypoints: [waypoint], tracks: [track, (name: 'Empty', points: <TrailPoint>[])], createdAt: created);
    expect(gpx, startsWith('<?xml version="1.0" encoding="UTF-8"?>'));
    expect(gpx, contains('<gpx version="1.1" creator="NOTORYX Connect" xmlns="http://www.topografix.com/GPX/1/1">'));
    expect(gpx, contains('<time>2026-10-29T15:04:05Z</time>'));
    expect(gpx, contains('<wpt lat="35.1234567" lon="-83.7654321">'));
    expect(gpx, contains('<name>Camp &lt;A&gt; &amp; &quot;B&quot;</name>'));
    expect(gpx, contains('<desc>Bob&apos;s spot</desc>'), reason: 'control characters are not valid XML');
    expect('<trkpt'.allMatches(gpx), hasLength(2));
    expect(gpx, contains('<time>2026-10-29T12:05:00Z</time>'));
    expect(gpx, isNot(contains('Empty')), reason: 'empty trails are skipped');
    expect(gpx.trim(), endsWith('</gpx>'));
  });

  test('the output is well-formed XML', () async {
    final gpx = BastionGpx.build(waypoints: [waypoint], tracks: [track], createdAt: created);
    final dir = await Directory.systemTemp.createTemp('gpx');
    final file = File('${dir.path}/t.gpx')..writeAsStringSync(gpx);
    final result = await Process.run('python3', ['-I', '-c',
      'import sys, xml.etree.ElementTree as ET; r = ET.parse(sys.argv[1]).getroot(); '
      'ns = {"g": "http://www.topografix.com/GPX/1/1"}; '
      'print(len(r.findall("g:wpt", ns)), len(r.findall("g:trk/g:trkseg/g:trkpt", ns)))', file.path]);
    await dir.delete(recursive: true);
    expect(result.exitCode, 0, reason: '${result.stderr}');
    expect((result.stdout as String).trim(), '1 2');
  }, skip: Process.runSync('which', ['python3']).exitCode != 0 ? 'python3 not available' : false);

  testWidgets('no Export GPX button when there is nothing to export', (tester) async {
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MapPage(radio: radio))));
    await tester.pump();
    expect(find.byTooltip('Export GPX'), findsNothing);
  });
}
