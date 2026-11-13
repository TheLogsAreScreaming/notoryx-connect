import 'package:bastion/day_replay_page.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/bastion_day_tracks.dart';
import 'package:bastion/services/bastion_trails.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final _t0 = DateTime(2026, 11, 12, 9);

MeshtasticNode _at(int num, double lat, double lon, DateTime t) =>
    MeshtasticNode(num: num, latitude: lat, longitude: lon, positionTime: t);

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('replay maths', () {
    final track = [
      TrailPoint(45.0, -122.0, _t0),
      TrailPoint(45.01, -122.0, _t0.add(const Duration(minutes: 10))),
      TrailPoint(45.01, -122.02, _t0.add(const Duration(minutes: 30))),
    ];

    test('nothing before the first report, held after the last', () {
      expect(DayReplay.positionAt(track, _t0.subtract(const Duration(seconds: 1))), isNull);
      final after = DayReplay.positionAt(track, _t0.add(const Duration(hours: 2)))!;
      expect((after.latitude, after.longitude, after.moving), (45.01, -122.02, false));
      expect(after.fixTime, track.last.time);
    });

    test('positions between reports are interpolated and marked as moving', () {
      final mid = DayReplay.positionAt(track, _t0.add(const Duration(minutes: 5)))!;
      expect(mid.latitude, closeTo(45.005, 1e-9));
      expect(mid.longitude, -122.0);
      expect(mid.moving, isTrue);
      expect(mid.fixTime, _t0);
      final onReport = DayReplay.positionAt(track, track[1].time)!;
      expect(onReport.moving, isFalse);
    });

    test('distance walked grows with the replay time', () {
      final early = DayReplay.distance(DayReplay.walked(track, _t0.add(const Duration(minutes: 5))));
      final later = DayReplay.distance(DayReplay.walked(track, _t0.add(const Duration(minutes: 20))));
      final all = DayReplay.distance(track);
      expect(early, closeTo(556, 5));
      expect(later, greaterThan(early));
      expect(later, lessThan(all));
      expect(DayReplay.walked(track, _t0.add(const Duration(hours: 1))), track);
    });

    test('span covers every member', () {
      final span = DayReplay.span({
        1: track,
        2: [TrailPoint(0, 0, _t0.subtract(const Duration(hours: 1)))],
        3: const [],
      })!;
      expect(span.start, _t0.subtract(const Duration(hours: 1)));
      expect(span.end, track.last.time);
      expect(DayReplay.span(const {}), isNull);
    });
  });

  group('day tracks', () {
    test('records only tracked members, by day, skipping small moves until the heartbeat', () async {
      var now = _t0;
      final store = SharedPreferencesAsync();
      final tracks = BastionDayTracks(preferences: store, clock: () => now);
      await tracks.record([_at(1, 45, -122, now), _at(9, 1, 1, now)], {1});
      now = now.add(const Duration(minutes: 1));
      await tracks.record([_at(1, 45.00001, -122, now)], {1}); // 1 m: skipped
      now = now.add(const Duration(minutes: 1));
      await tracks.record([_at(1, 45.001, -122, now)], {1}); // 111 m: kept
      now = now.add(const Duration(minutes: 15));
      await tracks.record([_at(1, 45.001, -122, now)], {1}); // still, but heartbeat
      await tracks.record([_at(1, 45.002, -122, now)], {1}); // same time: skipped
      now = DateTime(2026, 11, 13, 7);
      await tracks.record([_at(1, 46, -122, now)], {1});
      await tracks.flush();

      final reloaded = BastionDayTracks(preferences: store, clock: () => now);
      expect(await reloaded.days(), [DateTime(2026, 11, 13), DateTime(2026, 11, 12)]);
      final day = await reloaded.tracksOn(DateTime(2026, 11, 12));
      expect(day.keys, [1]);
      expect(day[1]!.map((p) => p.latitude), [45, 45.001, 45.001]);
      expect((await reloaded.tracksOn(DateTime(2026, 11, 13)))[1], hasLength(1));
    });

    test('a stale or future report time falls back to the phone clock', () async {
      final tracks = BastionDayTracks(clock: () => _t0);
      await tracks.record([_at(1, 45, -122, _t0.add(const Duration(hours: 3)))], {1});
      expect((await tracks.tracksOn(_t0))[1]!.single.time, _t0);
    });

    test('days older than two weeks are removed when saving', () async {
      var now = DateTime(2026, 11, 1, 12);
      final store = SharedPreferencesAsync();
      final tracks = BastionDayTracks(preferences: store, clock: () => now);
      await tracks.record([_at(1, 45, -122, now)], {1});
      await tracks.flush();
      now = DateTime(2026, 11, 20, 12);
      await tracks.record([_at(1, 45, -122, now)], {1});
      await tracks.flush();
      expect(await tracks.days(), [DateTime(2026, 11, 20)]);
      expect(await store.getString(BastionDayTracks.dayKey(DateTime(2026, 11, 1))), isNull);
    });
  });

  group('page', () {
    Future<BastionDayTracks> seeded() async {
      var now = _t0;
      final tracks = BastionDayTracks(clock: () => now);
      for (var i = 0; i <= 6; i++) {
        now = _t0.add(Duration(minutes: i * 10));
        await tracks.record([_at(1, 45 + i * 0.001, -122, now), if (i >= 3) _at(2, 45, -122 + i * 0.001, now)], {1, 2});
      }
      return tracks;
    }

    Widget app(Widget home, [Locale locale = const Locale('en')]) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

    testWidgets('scrubbing moves the team through the day and is announced', (tester) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final tracks = await seeded();
      await tester.pumpWidget(app(DayReplayPage(
          tracks: tracks, nameOf: (n) => n == 1 ? 'Mara' : 'Sam', showMap: false)));
      await tester.pumpAndSettle();
      expect(find.text('At 9:00 AM'), findsOneWidget);
      expect(find.text('Mara'), findsOneWidget);
      expect(find.text('First position at 9:30 AM\nCovered 0 m so far'), findsOneWidget);
      expect(find.semantics.byValue('9:00 AM'), findsOneWidget);

      await tester.drag(find.byType(Slider), const Offset(1000, 0));
      await tester.pumpAndSettle();
      expect(find.text('At 10:00 AM'), findsOneWidget);
      expect(find.textContaining('Last report 10:00 AM'), findsNWidgets(2));
      semantics.dispose();
    });

    testWidgets('the map describes itself to screen readers', (tester) async {
      final semantics = tester.ensureSemantics();
      final tracks = await seeded();
      await tester.pumpWidget(app(DayReplayPage(tracks: tracks, nameOf: (n) => 'N$n')));
      await tester.pump();
      await tester.pump();
      expect(find.bySemanticsLabel('Map of 2 team members at 9:00 AM. Their positions are listed below.'),
          findsOneWidget);
      semantics.dispose();
    });

    testWidgets('play runs to the end of the day and stops', (tester) async {
      final tracks = await seeded();
      await tester.pumpWidget(app(DayReplayPage(tracks: tracks, nameOf: (n) => 'N$n', showMap: false)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      expect(find.byTooltip('Pause'), findsOneWidget);
      await tester.pump(const Duration(seconds: 13));
      expect(find.text('At 10:00 AM'), findsOneWidget);
      expect(find.byTooltip('Play'), findsOneWidget);
    });

    testWidgets('an empty phone explains how recording starts, in Spanish too', (tester) async {
      await tester.pumpWidget(app(DayReplayPage(tracks: BastionDayTracks(), nameOf: (n) => '$n', showMap: false),
          const Locale('es')));
      await tester.pumpAndSettle();
      expect(find.text('Aún no hay días grabados'), findsOneWidget);
      expect(find.text('Repetición del día'), findsOneWidget);
    });
  });
}
