import 'dart:async';

import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/bastion_field_alerts.dart';
import 'package:bastion/services/bastion_phone_position.dart';
import 'package:bastion/services/bastion_track_log.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/theme/notoryx_theme.dart';
import 'package:bastion/theme/nx_themes.dart';
import 'package:bastion/track_log_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _Memory implements TrackLogStorage {
  String? data;
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String d) async => data = d;
}

class _Phone implements PhoneLocationSource {
  final fixes = StreamController<PhoneFix>.broadcast();
  int watching = 0;
  @override
  Future<String?> ensureAccess() async => null;
  @override
  Stream<PhoneFix> watch({bool lowPower = false, bool background = false}) {
    watching++;
    return fixes.stream;
  }
}

/// About 11 m of latitude per 0.0001 degree.
const _lat = 35.6, _lon = -82.5;

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  late DateTime now;
  late _Memory memory;
  late BastionTrackLog log;
  setUp(() async {
    now = DateTime.utc(2026, 11, 20, 12);
    memory = _Memory();
    log = BastionTrackLog(storage: memory, clock: () => now);
    await log.load();
  });

  DateTime at(int seconds) => now.add(Duration(seconds: seconds));

  group('recording', () {
    test('keeps points that moved or waited, and drops jumps and repeats', () async {
      await log.start('Ridge walk');
      expect(log.addPosition(_lat, _lon, at(1)), isTrue);
      expect(log.addPosition(_lat + 0.00001, _lon, at(5)), isFalse, reason: 'barely moved, too soon');
      expect(log.addPosition(_lat + 0.0002, _lon, at(10)), isTrue, reason: 'moved about 22 m');
      expect(log.addPosition(_lat + 0.0002, _lon, at(10)), isFalse, reason: 'same time again');
      expect(log.addPosition(_lat + 0.5, _lon, at(20)), isFalse, reason: 'a 55 km jump in 10 s is a bad fix');
      expect(log.addPosition(_lat + 0.0002, _lon, at(200)), isTrue, reason: 'still, but two minutes later');
      expect(log.addPosition(0, 0, at(400)), isFalse, reason: 'no fix');
      expect(log.addPosition(_lat, _lon, now.subtract(const Duration(minutes: 1))), isFalse,
          reason: 'before the start');
      expect(log.recording!.points, hasLength(3));
      expect(log.recording!.meters, closeTo(22.2, 1));

      now = at(600);
      await log.stop();
      expect(log.recording, isNull);
      expect(log.addPosition(_lat + 0.01, _lon, at(700)), isFalse, reason: 'nothing records after Stop');
    });

    test('saves tracks and reads them back', () async {
      await log.start('Ridge walk');
      log.addPosition(_lat, _lon, at(1));
      log.addPosition(_lat + 0.001, _lon, at(60));
      await log.stop();
      final again = BastionTrackLog(storage: memory, clock: () => now);
      await again.load();
      expect(again.tracks.single.name, 'Ridge walk');
      expect(again.tracks.single.points, hasLength(2));
      expect(again.tracks.single.isRecording, isFalse);
    });

    test('a recording still running when the app closed carries on', () async {
      await log.start('Overnight');
      final again = BastionTrackLog(storage: memory, clock: () => now);
      await again.load();
      expect(again.recording?.name, 'Overnight');
    });

    test('exports GPX with every point', () async {
      await log.start('A & B');
      log.addPosition(_lat, _lon, at(1));
      log.addPosition(_lat + 0.001, _lon, at(60));
      final gpx = log.recording!.toGpx(now);
      expect('<trkpt'.allMatches(gpx), hasLength(2));
      expect(gpx, contains('<name>A &amp; B</name>'));
    });

    test('keeps at most the newest tracks, never dropping the watched one', () async {
      for (var i = 0; i < BastionTrackLog.maxTracks + 3; i++) {
        now = now.add(const Duration(hours: 1));
        await log.start('T$i');
        log.addPosition(_lat, _lon, now.add(const Duration(seconds: 1)));
        log.addPosition(_lat + 0.001, _lon, now.add(const Duration(seconds: 60)));
        await log.stop();
        if (i == 0) await log.watchTrack(log.tracks.first);
      }
      expect(log.tracks, hasLength(BastionTrackLog.maxTracks));
      expect(log.tracks.map((t) => t.name), contains('T0'));
      expect(log.tracks.map((t) => t.name), isNot(contains('T1')));
    });
  });

  group('stray warning', () {
    late List<BastionFieldAlert> alerts;
    setUp(() async {
      alerts = [];
      log.onAlert = alerts.add;
      await log.start('Trail');
      for (var i = 0; i < 5; i++) {
        log.addPosition(_lat + i * 0.001, _lon, at(i * 60 + 1));
      }
      await log.stop();
      await log.watchTrack(log.tracks.first, limitMeters: 100);
    });

    test('warns once when you go past the limit, and again only after coming back', () {
      log.addPosition(_lat + 0.002, _lon + 0.0005, at(1000)); // about 45 m off: sets the side
      expect(alerts, isEmpty);
      log.addPosition(_lat + 0.002, _lon + 0.002, at(1100)); // about 180 m off
      expect(alerts, hasLength(1));
      expect(alerts.single.kind, BastionAlertKind.offRoute);
      expect(alerts.single.body, contains('Trail'));
      log.addPosition(_lat + 0.002, _lon + 0.003, at(1200));
      expect(alerts, hasLength(1), reason: 'no repeat while still off');
      log.addPosition(_lat + 0.002, _lon + 0.0008, at(1300)); // about 72 m: not yet back (70 m)
      log.addPosition(_lat + 0.002, _lon + 0.002, at(1400));
      expect(alerts, hasLength(1));
      log.addPosition(_lat + 0.002, _lon + 0.0002, at(1500)); // back on
      log.addPosition(_lat + 0.002, _lon + 0.002, at(1600));
      expect(alerts, hasLength(2));
    });

    test('starting already off the track does not warn', () {
      log.addPosition(_lat + 0.002, _lon + 0.01, at(1000));
      log.addPosition(_lat + 0.002, _lon + 0.011, at(1100));
      expect(alerts, isEmpty);
      expect(log.lastOffMeters, greaterThan(900));
    });

    test('deleting the watched track stops the warning', () async {
      await log.delete(log.tracks.first);
      expect(log.watch, isNull);
      expect(log.wantsPositions, isFalse);
    });
  });

  testWidgets('the feed listens to the phone only while recording or watching', (tester) async {
    final phone = _Phone();
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    final feed = TrackLogFeed(log: log, radio: radio, phone: phone)..start();
    addTearDown(feed.dispose);
    expect(phone.watching, 0);
    await log.start('Walk');
    expect(phone.watching, 1);
    phone.fixes.add(PhoneFix(latitude: _lat, longitude: _lon, time: at(5)));
    await tester.pump();
    expect(log.recording!.points, hasLength(1));
    await log.stop();
    phone.fixes.add(PhoneFix(latitude: _lat + 1, longitude: _lon, time: at(500)));
    await tester.pump();
    expect(log.tracks.first.points, hasLength(1), reason: 'listening stopped with the recording');
  });

  group('page', () {
    Widget app(String? Function(String, String) onShare) => MaterialApp(
          theme: NotoryxTheme.fromPalette(BastionTheme.blaze.palette),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TrackLogPage(log: log, share: (f, t) async => onShare(f, t), location: _Phone()),
        );

    testWidgets('start, stop, export, watch and delete', (tester) async {
      String? sharedName, sharedText;
      await tester.pumpWidget(app((f, t) {
        sharedName = f;
        sharedText = t;
        return null;
      }));
      expect(find.text('No tracks yet. Start a recording before you head out.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('track-start')));
      await tester.pumpAndSettle();
      expect(find.text('Recording'), findsOneWidget);
      log.addPosition(_lat, _lon, at(1));
      log.addPosition(_lat + 0.001, _lon, at(60));
      await tester.pump();
      expect(find.textContaining('2 points'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('track-stop')));
      await tester.pumpAndSettle();
      final row = find.byKey(ValueKey('track-${log.tracks.first.id}'));
      expect(row, findsOneWidget);

      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('track-gpx')));
      await tester.pumpAndSettle();
      expect(sharedName, endsWith('.gpx'));
      expect(sharedText, contains('<trkseg>'));

      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('track-watch-100')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('track-watch-100')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('track-watching')), findsOneWidget);
      expect(find.text('Waiting for a position.'), findsOneWidget);

      await tester.tap(row);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(const ValueKey('track-delete')), 100,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(find.byKey(const ValueKey('track-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('track-delete-confirm')));
      await tester.pumpAndSettle();
      expect(log.tracks, isEmpty);
      expect(find.byKey(const ValueKey('track-watching')), findsNothing);
    });
  });
}
