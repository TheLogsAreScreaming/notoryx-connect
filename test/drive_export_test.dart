import 'dart:convert';

import 'package:bastion/drive_page.dart';
import 'package:bastion/generated/meshtastic/mesh.pb.dart' as pb;
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/bastion_drive_export.dart';
import 'package:bastion/services/bastion_drive_log.dart';
import 'package:bastion/services/bastion_phone_position.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/theme/notoryx_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:xml/xml.dart';

final now = DateTime.utc(2026, 11, 22, 15);

PhoneFix fix(double lat, double lon) =>
    PhoneFix(latitude: lat, longitude: lon, time: now, accuracyMeters: 8);

pb.MeshPacket packet(int from, {double snr = -4, int hopLimit = 3}) =>
    pb.MeshPacket(
      from: from,
      id: from,
      rxTime: now.millisecondsSinceEpoch ~/ 1000,
      rxSnr: snr,
      rxRssi: -100,
      hopStart: 3,
      hopLimit: hopLimit,
    );

/// A 3 km drive north with a reading every 300 m.
Future<(BastionDriveLog, DriveTrip)> drive({
  String name = 'Ridge <loop> & back',
}) async {
  final log = BastionDriveLog();
  await log.load(useDatabase: false);
  final trip = await log.start(42, name: name, now: now);
  for (var i = 0; i <= 30; i++) {
    final lat = 35.2 + i * 0.0009;
    await log.addFix(fix(lat, -80.8));
    if (i % 3 == 0)
      await log.observe(
        packet(100 + i, hopLimit: i % 2 == 0 ? 3 : 1),
        fix(lat, -80.8),
        now,
      );
  }
  await log.stop(now: now.add(const Duration(minutes: 20)));
  return (log, trip);
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  group('trim', () {
    test(
      'drops points and readings within 500 m of the start and end',
      () async {
        final (log, trip) = await drive();
        final all = DriveExport.of(log, trip, trimMeters: 0);
        final trimmed = DriveExport.of(log, trip);
        expect(all.samples, hasLength(11));
        expect(trimmed.samples.length, lessThan(all.samples.length));
        final start = log.pointsOf(trip.id).first;
        for (final s in trimmed.samples) {
          expect(
            (s.latitude - start.latitude).abs() * 111320,
            greaterThanOrEqualTo(500),
          );
        }
        expect(
          trimmed.points.first.latitude,
          greaterThan(start.latitude + 0.004),
        );
        expect(trimmed.trimmedMeters, 500);
      },
    );
  });

  group('formats', () {
    test('GPX is valid XML with a track and escaped names', () async {
      final (log, trip) = await drive();
      final doc = XmlDocument.parse(
        DriveExport.of(log, trip, trimMeters: 0).gpx(now: now),
      );
      expect(doc.findAllElements('trkpt'), hasLength(31));
      expect(doc.findAllElements('wpt'), hasLength(11));
      expect(
        doc.findAllElements('name').first.innerText,
        'Ridge <loop> & back',
      );
      expect(doc.findAllElements('desc').first.innerText, contains('SNR -4.0'));
    });

    test(
      'KML has coloured squares for direct readings only, and the trail',
      () async {
        final (log, trip) = await drive();
        final doc = XmlDocument.parse(
          DriveExport.of(log, trip, trimMeters: 0).kml(),
        );
        final placemarks = doc.findAllElements('Placemark').toList();
        expect(
          placemarks.where((p) => p.findElements('Polygon').isNotEmpty),
          hasLength(6),
        );
        expect(
          placemarks.where((p) => p.findElements('LineString').isNotEmpty),
          hasLength(1),
        );
      },
    );

    test(
      'CSV has a header and one row per reading; negative numbers stay numbers',
      () async {
        final (log, trip) = await drive();
        final lines = DriveExport.of(
          log,
          trip,
          trimMeters: 0,
        ).csv().trim().split('\r\n');
        expect(lines.first, DriveExport.csvFields.join(','));
        expect(lines, hasLength(12));
        expect(lines[1], contains('"-4.0"'));
        expect(lines[1], contains('"-80.8"'));
      },
    );

    test('GeoJSON has readings, squares and the trail', () async {
      final (log, trip) = await drive();
      final json =
          jsonDecode(DriveExport.of(log, trip, trimMeters: 0).geojson()) as Map;
      final kinds = [
        for (final f in json['features'] as List)
          (f as Map)['properties']['kind'],
      ];
      expect(kinds.where((k) => k == 'reading'), hasLength(11));
      expect(kinds.where((k) => k == 'square'), hasLength(6));
      expect(kinds.where((k) => k == 'trail'), hasLength(1));
    });

    test('file names are safe', () async {
      final (log, trip) = await drive(name: 'a/b:c*d');
      expect(
        DriveExport.of(log, trip).fileName(DriveExportFormat.kml),
        'abcd.kml',
      );
      final (log2, trip2) = await drive(name: '///');
      expect(
        DriveExport.of(log2, trip2).fileName(DriveExportFormat.drive),
        'drive.json',
      );
    });
  });

  group('drive file', () {
    test(
      'round trip: export, import, export again gives the same readings and trail',
      () async {
        final (log, trip) = await drive();
        final first = DriveExport.of(
          log,
          trip,
          trimMeters: 0,
        ).driveFile(now: now);
        final file = DriveFile.parse(first);
        final target = BastionDriveLog();
        await target.load(useDatabase: false);
        final copy = await target.importTrip(
          name: file.name,
          started: file.started,
          ended: file.ended,
          points: file.points,
          samples: file.samples,
        );
        expect(copy.running, isFalse);
        final second = DriveExport.of(
          target,
          copy,
          trimMeters: 0,
        ).driveFile(now: now);
        expect(second, first);
      },
    );

    test('a newer version is refused', () {
      final text = jsonEncode({
        'format': DriveFile.format,
        'version': DriveFile.version + 1,
        'trip': {},
      });
      expect(
        () => DriveFile.parse(text),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('newer'),
          ),
        ),
      );
    });

    test(
      'other files and damaged readings are refused before anything is saved',
      () async {
        expect(() => DriveFile.parse('not json'), throwsFormatException);
        expect(
          () => DriveFile.parse('{"type":"FeatureCollection"}'),
          throwsFormatException,
        );
        final (log, trip) = await drive();
        final json =
            jsonDecode(DriveExport.of(log, trip, trimMeters: 0).driveFile())
                as Map<String, dynamic>;
        (json['samples'] as List).last['lat'] = 123.0;
        expect(() => DriveFile.parse(jsonEncode(json)), throwsFormatException);
        (json['samples'] as List).last
          ..['lat'] = 35.2
          ..['class'] = 'teleported';
        expect(() => DriveFile.parse(jsonEncode(json)), throwsFormatException);
      },
    );
  });

  group('drive screen', () {
    Future<MeshtasticRadioCoordinator> show(
      WidgetTester tester,
      BastionDriveLog log, {
      required DriveShare share,
      DrivePick? pick,
    }) async {
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final radio = MeshtasticRadioCoordinator();
      addTearDown(radio.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: NotoryxTheme.build(Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DrivePage(
            radio: radio,
            log: log,
            tiles: false,
            share: share,
            pick: pick ?? () async => null,
          ),
        ),
      );
      await tester.pump();
      return radio;
    }

    testWidgets(
      'each export goes to the share sheet with its type, trimmed by default',
      (tester) async {
        final (log, _) = await drive(name: 'Loop');
        final shared = <(String, String, String)>[];
        await show(
          tester,
          log,
          share: (n, t, m) async => shared.add((n, t, m)),
        );
        for (final f in DriveExportFormat.values) {
          await tester.tap(find.byKey(ValueKey('drive-export-${f.name}')));
          await tester.pump();
        }
        expect(
          [for (final s in shared) s.$1],
          ['Loop.gpx', 'Loop.kml', 'Loop.csv', 'Loop.geojson', 'Loop.json'],
        );
        expect(shared.last.$3, 'application/json');
        expect((jsonDecode(shared.last.$2) as Map)['trimmed_meters'], 500);
      },
    );

    testWidgets('import adds a drive and shows it', (tester) async {
      final (source, trip) = await drive(name: 'Shared');
      final text = DriveExport.of(source, trip, trimMeters: 0).driveFile();
      final log = BastionDriveLog();
      await log.load(useDatabase: false);
      await show(
        tester,
        log,
        share: (_, _, _) async {},
        pick: () async => text,
      );
      await tester.tap(find.byKey(const ValueKey('drive-import')));
      await tester.pumpAndSettle();
      expect(log.trips.single.name, 'Shared (imported)');
      expect(find.text('Drive imported with 11 readings.'), findsOneWidget);
      expect(find.text('On the map: Shared (imported)'), findsOneWidget);
    });

    testWidgets('a bad file says why and saves nothing', (tester) async {
      final log = BastionDriveLog();
      await log.load(useDatabase: false);
      await show(
        tester,
        log,
        share: (_, _, _) async {},
        pick: () async => '{"format":"something-else"}',
      );
      await tester.tap(find.byKey(const ValueKey('drive-import')));
      await tester.pumpAndSettle();
      expect(log.trips, isEmpty);
      expect(
        find.text("That file can't be imported: Not a drive file."),
        findsOneWidget,
      );
    });
  });
}
