import 'package:bastion/main.dart';
import 'package:bastion/services/bastion_battery_watch.dart';
import 'package:bastion/services/bastion_field_alerts.dart';
import 'package:bastion/services/bastion_telemetry_history.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/shell_nav.dart';

final _now = DateTime(2026, 11, 20, 12);

List<TelemetryPoint> _draining(double perDay, {double start = 80, int hours = 24}) => [
      for (var h = hours; h >= 0; h -= 2)
        TelemetryPoint(_now.subtract(Duration(hours: h)), start + perDay * (hours - h) / 24),
    ];

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('battery watch', () {
    test('the trend is the slope of the last two days of readings', () {
      expect(BastionBatteryWatch.perDay(_draining(-12), _now), closeTo(-12, 0.01));
      expect(BastionBatteryWatch.perDay(_draining(5), _now), closeTo(5, 0.01));
      expect(BastionBatteryWatch.perDay([TelemetryPoint(_now, 50)], _now), isNull, reason: 'one reading');
      expect(
          BastionBatteryWatch.perDay(
              [TelemetryPoint(_now.subtract(const Duration(minutes: 30)), 50), TelemetryPoint(_now, 49)], _now),
          isNull,
          reason: 'too close together');
      final old = [
        TelemetryPoint(_now.subtract(const Duration(days: 5)), 90),
        TelemetryPoint(_now.subtract(const Duration(days: 4)), 10),
      ];
      expect(BastionBatteryWatch.perDay(old, _now), isNull, reason: 'readings outside the window');
    });

    test('lowest first, fastest draining breaks ties, external power last', () {
      final rows = BastionBatteryWatch.rows(
        nodes: [
          MeshtasticNode(num: 1, longName: 'Plugged', batteryLevel: 101),
          MeshtasticNode(num: 2, longName: 'Half slow', batteryLevel: 50),
          MeshtasticNode(num: 3, longName: 'Low', batteryLevel: 15),
          MeshtasticNode(num: 4, longName: 'Half fast', batteryLevel: 50),
          MeshtasticNode(num: 5, longName: 'No battery'),
        ],
        batterySeries: (n) => switch (n) { 2 => _draining(-5), 4 => _draining(-25), _ => const [] },
        now: _now,
      );
      expect(rows.map((r) => r.name), ['Low', 'Half fast', 'Half slow', 'Plugged']);
      expect(rows[1].daysLeft, closeTo(2, 0.01));
      expect(rows.last.pluggedIn, isTrue);
    });

    testWidgets('Tools opens it, and it lists the demo mesh by battery', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const BastionApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.play_circle_outline).first);
      await tester.pumpAndSettle();
      await openTools(tester);
      await tester.tap(find.byKey(const ValueKey('tools-battery-watch')));
      await tester.pumpAndSettle();
      expect(find.text('Battery watch'), findsOneWidget);
      final levels = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((t) => t.key)
          .whereType<ValueKey<String>>()
          .where((k) => k.value.startsWith('battery-'))
          .toList();
      expect(levels, isNotEmpty);
    });
  });

  group('favorite is back', () {
    late DateTime now;
    late BastionFieldAlertEngine engine;
    const on = BastionAlertSettings(favoriteBack: true);
    setUp(() {
      now = _now;
      engine = BastionFieldAlertEngine(clock: () => now)..startSession(1);
    });

    test('alerts when a favorite is heard after the chosen silence', () {
      final alert = engine.favoriteBack(9, 'Base', favorite: true,
          lastHeardBefore: now.subtract(const Duration(hours: 7)), settings: on);
      expect(alert?.kind, BastionAlertKind.favoriteBack);
      expect(alert?.title, 'Base is back');
      expect(alert?.body, contains('7'));
    });

    test('stays quiet for short gaps, non-favorites, your own radio, or when off', () {
      final recent = now.subtract(const Duration(hours: 2));
      final long = now.subtract(const Duration(days: 2));
      expect(engine.favoriteBack(9, 'B', favorite: true, lastHeardBefore: recent, settings: on), isNull);
      expect(engine.favoriteBack(9, 'B', favorite: false, lastHeardBefore: long, settings: on), isNull);
      expect(engine.favoriteBack(1, 'Me', favorite: true, lastHeardBefore: long, settings: on), isNull);
      expect(engine.favoriteBack(9, 'B', favorite: true, lastHeardBefore: null, settings: on), isNull);
      expect(
          engine.favoriteBack(9, 'B',
              favorite: true, lastHeardBefore: long, settings: const BastionAlertSettings()),
          isNull);
      engine.endSession();
      expect(engine.favoriteBack(9, 'B', favorite: true, lastHeardBefore: long, settings: on), isNull);
    });

    test('the setting is saved with its delay', () {
      final s = const BastionAlertSettings().copyWith(favoriteBack: true, backAfter: const Duration(days: 3));
      final back = BastionAlertSettings.fromJson(s.toJson());
      expect(back.favoriteBack, isTrue);
      expect(back.backAfter, const Duration(days: 3));
      expect(BastionAlertSettings.fromJson({'backAfterMinutes': 7}).backAfter, const Duration(hours: 6));
    });
  });
}
