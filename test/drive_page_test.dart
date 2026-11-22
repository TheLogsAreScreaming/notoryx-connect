import 'dart:io';

import 'package:bastion/drive_page.dart';
import 'package:bastion/generated/meshtastic/mesh.pb.dart' as pb;
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/bastion_drive_log.dart';
import 'package:bastion/services/bastion_phone_position.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/theme/notoryx_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final now = DateTime.utc(2026, 11, 22, 15);

PhoneFix fix(
  double lat,
  double lon, {
  Duration at = Duration.zero,
  double accuracy = 8,
}) => PhoneFix(
  latitude: lat,
  longitude: lon,
  time: now.add(at),
  accuracyMeters: accuracy,
);

pb.MeshPacket packet(
  int from, {
  Duration at = Duration.zero,
  double snr = -4,
  int hopStart = 3,
  int hopLimit = 3,
}) => pb.MeshPacket(
  from: from,
  id: from & 0xffff,
  rxTime: now.add(at).millisecondsSinceEpoch ~/ 1000,
  rxSnr: snr,
  rxRssi: -100,
  hopStart: hopStart,
  hopLimit: hopLimit,
);

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  Future<BastionDriveLog> loaded() async {
    final log = BastionDriveLog();
    await log.load(useDatabase: false);
    return log;
  }

  group('drive trail', () {
    test(
      'keeps a point once the phone has moved 15 m, and skips rough fixes',
      () async {
        final log = await loaded();
        expect(
          await log.addFix(fix(35.2, -80.8)),
          isFalse,
          reason: 'no drive running',
        );
        final trip = await log.start(42, now: now);
        expect(await log.addFix(fix(35.2, -80.8)), isTrue);
        expect(
          await log.addFix(fix(35.20005, -80.8)),
          isFalse,
          reason: 'about 6 m',
        );
        expect(
          await log.addFix(fix(35.2002, -80.8)),
          isTrue,
          reason: 'about 22 m',
        );
        expect(await log.addFix(fix(35.21, -80.8, accuracy: 80)), isFalse);
        expect(log.pointsOf(trip.id), hasLength(2));
      },
    );

    test('distance comes from the trail', () async {
      final log = await loaded();
      final trip = await log.start(42, now: now);
      for (var i = 0; i <= 10; i++) {
        await log.addFix(fix(35.2 + i * 0.001, -80.8));
      }
      await log.stop(now: now.add(const Duration(minutes: 10)));
      final s = log.summary(trip.id);
      expect(s.meters, closeTo(1113, 5));
      expect(s.duration, const Duration(minutes: 10));
    });

    test('deleting a drive removes its trail', () async {
      final log = await loaded();
      final trip = await log.start(42, now: now);
      await log.addFix(fix(35.2, -80.8));
      await log.stop(now: now);
      await log.deleteTrip(trip.id);
      expect(log.points, isEmpty);
    });
  });

  group('drive summary', () {
    test('counts nodes, direct nodes, new nodes and direct squares', () async {
      final log = await loaded();
      final first = await log.start(42, now: now);
      await log.observe(packet(1), fix(35.2, -80.8), now);
      await log.stop(now: now.add(const Duration(minutes: 1)));
      final later = now.add(const Duration(hours: 1));
      final second = await log.start(42, now: later);
      await log.observe(
        packet(1, at: const Duration(hours: 1), snr: 6),
        fix(35.2, -80.8, at: const Duration(hours: 1)),
        later,
      );
      await log.observe(
        packet(2, at: const Duration(hours: 1), hopStart: 3, hopLimit: 1),
        fix(35.21, -80.8, at: const Duration(hours: 1)),
        later,
      );
      final s = log.summary(second.id, now: later);
      expect(s.readings, 2);
      expect(s.nodes, 2);
      expect(s.directNodes, 1);
      expect(s.newNodes, 1, reason: 'node 1 was heard on the first drive');
      expect(s.squares, 1, reason: 'relayed readings do not prove coverage');
      expect(s.bestSnr, 6);
      expect(log.summary(first.id).newNodes, 1);
    });
  });

  group('rename', () {
    test('renames a drive and ignores a blank name', () async {
      final log = await loaded();
      final trip = await log.start(42, now: now);
      await log.renameTrip(trip.id, '  Ridge loop ');
      expect(log.trips.single.name, 'Ridge loop');
      await log.renameTrip(trip.id, '   ');
      expect(log.trips.single.name, 'Ridge loop');
    });
  });

  group('new node alerts', () {
    test('are off by default', () async {
      final log = await loaded();
      final heard = <NewNodeHeard>[];
      log.newNodes.listen(heard.add);
      await log.start(42, now: now);
      await log.observe(packet(1), fix(35.2, -80.8), now);
      await Future<void>.delayed(Duration.zero);
      expect(log.newNodeAlert, NewNodeAlert.off);
      expect(heard, isEmpty);
    });

    test(
      '"first time on any drive" skips nodes heard on earlier drives',
      () async {
        final log = await loaded();
        await log.setNewNodeAlert(NewNodeAlert.ever);
        await log.start(42, now: now);
        await log.observe(packet(1), fix(35.2, -80.8), now);
        await log.stop(now: now);
        final heard = <NewNodeHeard>[];
        log.newNodes.listen(heard.add);
        await log.start(42, now: now);
        await log.observe(packet(1), fix(35.2, -80.8), now);
        await log.observe(packet(2), fix(35.2, -80.8), now);
        await log.observe(packet(2, snr: -2), fix(35.21, -80.8), now);
        await Future<void>.delayed(Duration.zero);
        expect([for (final h in heard) h.node], [2]);
        expect(heard.single.firstEver, isTrue);
      },
    );

    test(
      '"first time on this drive" includes nodes heard before, once',
      () async {
        final log = await loaded();
        await log.start(42, now: now);
        await log.observe(packet(1), fix(35.2, -80.8), now);
        await log.stop(now: now);
        await log.setNewNodeAlert(NewNodeAlert.trip);
        final heard = <NewNodeHeard>[];
        log.newNodes.listen(heard.add);
        await log.start(42, now: now);
        await log.observe(packet(1), fix(35.2, -80.8), now);
        await log.observe(packet(1, snr: 1), fix(35.21, -80.8), now);
        await Future<void>.delayed(Duration.zero);
        expect(heard, hasLength(1));
        expect(heard.single.firstEver, isFalse);
      },
    );

    test('the setting is remembered', () async {
      final log = await loaded();
      await log.setNewNodeAlert(NewNodeAlert.trip);
      expect((await loaded()).newNodeAlert, NewNodeAlert.trip);
    });
  });

  group('database upgrade', () {
    late Directory dir;
    setUpAll(sqfliteFfiInit);
    setUp(() async => dir = await Directory.systemTemp.createTemp('drives'));
    tearDown(() => dir.delete(recursive: true));

    test('a version 1 database gains the trail table and keeps its drives', () async {
      final path = '${dir.path}/drives.db';
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, _) async {
            await db.execute(
              'CREATE TABLE trips (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, '
              'started TEXT NOT NULL, ended TEXT, radio INTEGER)',
            );
            await db.execute(
              'CREATE TABLE samples (id INTEGER PRIMARY KEY AUTOINCREMENT, trip INTEGER NOT NULL, '
              'ts TEXT NOT NULL, lat REAL NOT NULL, lon REAL NOT NULL, accuracy REAL, from_node INTEGER NOT NULL, '
              'packet INTEGER, port INTEGER, channel INTEGER, snr REAL, rssi INTEGER, hop_start INTEGER, '
              'hop_limit INTEGER, class TEXT NOT NULL, relay INTEGER)',
            );
            await db.insert('trips', {
              'name': 'Old drive',
              'started': now.toIso8601String(),
              'ended': now.toIso8601String(),
              'radio': 42,
            });
          },
        ),
      );
      await old.close();
      final log = BastionDriveLog();
      await log.load(factory: databaseFactoryFfi, path: path);
      expect(log.trips.single.name, 'Old drive');
      final trip = await log.start(42, now: now);
      expect(await log.addFix(fix(35.2, -80.8)), isTrue);
      final reopened = BastionDriveLog();
      await reopened.load(factory: databaseFactoryFfi, path: path);
      expect(reopened.pointsOf(trip.id), hasLength(1));
    });
  });

  group('drive screen', () {
    Future<BastionDriveLog> twoDrives() async {
      final log = await loaded();
      await log.start(42, name: 'Morning', now: now);
      await log.addFix(fix(35.2, -80.8));
      await log.addFix(fix(35.201, -80.8));
      await log.observe(packet(1), fix(35.2, -80.8), now);
      await log.observe(
        packet(2, hopStart: 3, hopLimit: 2, snr: -12),
        fix(35.205, -80.8),
        now,
      );
      await log.stop(now: now.add(const Duration(minutes: 5)));
      await log.start(
        42,
        name: 'Evening',
        now: now.add(const Duration(hours: 8)),
      );
      await log.stop(now: now.add(const Duration(hours: 9)));
      return log;
    }

    Future<void> show(WidgetTester tester, BastionDriveLog log) async {
      tester.view.physicalSize = const Size(600, 2400);
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
          home: DrivePage(radio: radio, log: log, tiles: false),
        ),
      );
      await tester.pump();
    }

    testWidgets('Start needs a radio; saved drives are listed newest first', (
      tester,
    ) async {
      final log = await twoDrives();
      await show(tester, log);
      expect(find.text('Connect to a radio to start a drive.'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('drive-start')))
            .onPressed,
        isNull,
      );
      final evening = tester.getTopLeft(find.text('Evening'));
      final morning = tester.getTopLeft(find.text('Morning'));
      expect(evening.dy, lessThan(morning.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'picking a drive shows its squares, counters and relayed toggle',
      (tester) async {
        final log = await twoDrives();
        await show(tester, log);
        await tester.tap(find.text('Morning'));
        await tester.pump();
        expect(find.text('On the map: Morning'), findsOneWidget);
        expect(find.text('Squares: 0 strong, 1 fair, 0 weak'), findsOneWidget);
        expect(
          find.text('Nodes heard: 2 • direct: 1 • new: 2'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('drive-show-relayed')));
        await tester.pump();
        expect(find.text('Squares: 0 strong, 1 fair, 1 weak'), findsOneWidget);
        await tester.tap(find.text('100 m'));
        await tester.pump();
        expect(find.text('Squares: 0 strong, 1 fair, 1 weak'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('delete asks first', (tester) async {
      final log = await twoDrives();
      await show(tester, log);
      final morning = log.trips.firstWhere((t) => t.name == 'Morning');
      await tester.tap(find.byKey(ValueKey('drive-menu-${morning.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('Delete Morning?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(log.trips, hasLength(2));
      await tester.tap(find.byKey(ValueKey('drive-menu-${morning.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('drive-delete-confirm')));
      await tester.pumpAndSettle();
      expect([for (final t in log.trips) t.name], ['Evening']);
      expect(find.text('Drive deleted.'), findsOneWidget);
    });

    testWidgets('rename', (tester) async {
      final log = await twoDrives();
      await show(tester, log);
      final evening = log.trips.firstWhere((t) => t.name == 'Evening');
      await tester.tap(find.byKey(ValueKey('drive-menu-${evening.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('drive-rename-field')),
        'Night run',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Night run'), findsWidgets);
    });

    testWidgets('the guide has no links', (tester) async {
      await show(tester, await loaded());
      await tester.tap(find.text('How drives work'));
      await tester.pumpAndSettle();
      expect(find.text('Direct and relayed'), findsOneWidget);
      expect(find.textContaining('http'), findsNothing);
    });
  });

  testWidgets("a running drive's time keeps counting with nothing else changing", (tester) async {
    final log = BastionDriveLog();
    await log.load(useDatabase: false);
    await log.start(42, now: DateTime.now().subtract(const Duration(minutes: 3, seconds: 56)));
    tester.view.physicalSize = const Size(600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: NotoryxTheme.build(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DrivePage(radio: radio, log: log, tiles: false),
    ));
    await tester.pump();
    expect(find.textContaining('3 min'), findsOneWidget);
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 6)));
    await tester.pump(const Duration(seconds: 5));
    expect(find.textContaining('4 min'), findsOneWidget);
    await log.stop();
  });
}
