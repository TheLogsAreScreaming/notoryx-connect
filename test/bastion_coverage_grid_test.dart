import 'package:bastion/services/bastion_field_log.dart';
import 'dart:convert';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/map_page.dart';
import 'package:bastion/services/bastion_coverage_grid.dart';
import 'package:bastion/services/bastion_node_vault.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/theme/notoryx_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Map<String, Object?> reading(double lat, double lon, Object? snr, {int radio = 1}) =>
    {'kind': 'coverage', 'radio': radio, 'lat': lat, 'lon': lon, 'snr': snr};

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('grid', () {
    test('nearby readings average into one square', () {
      final cells = BastionCoverageGrid.build([reading(35.2001, -80.8001, 4), reading(35.2002, -80.8002, -2)]);
      expect(cells, hasLength(1));
      expect((cells.single.readings, cells.single.meanSnr), (2, 1.0));
      expect(cells.single.band, CoverageBand.strong);
    });

    test('bands follow the SNR thresholds', () {
      CoverageBand band(double snr) => BastionCoverageGrid.build([reading(1, 1, snr)]).single.band;
      expect([band(0), band(-1), band(-10), band(-10.5)],
          [CoverageBand.strong, CoverageBand.fair, CoverageBand.fair, CoverageBand.weak]);
    });

    test('skips other radios, other kinds and unusable readings', () {
      expect(BastionCoverageGrid.build([
        reading(1, 1, 1, radio: 2),
        reading(1, 1, null),
        reading(1, 1, double.nan),
        {'kind': 'incident', 'radio': 1, 'lat': 1, 'lon': 1, 'snr': 1},
      ], radio: 1), isEmpty);
    });

    test('density tops out', () {
      final cells = BastionCoverageGrid.build([for (var i = 0; i < 30; i++) reading(1, 1, 0)]);
      expect(cells.single.density, 1);
    });
  });

  group('remembered positions', () {
    MeshtasticNode node(int num, double lat) => MeshtasticNode(num: num, latitude: lat, longitude: 2);
    final t0 = DateTime(2026, 11, 9, 12);

    test('survive a reload after the radio forgets the node', () async {
      final dex = BastionNodeVault();
      await dex.useRadio(9);
      await dex.observe(node(5, 1));
      await dex.rememberPositions([node(5, 1.5)], now: t0);
      final reopened = BastionNodeVault();
      await reopened.useRadio(9);
      expect(reopened.records.single.latitude, 1.5);
    });

    test('are saved at most once a minute, then catch up', () async {
      final dex = BastionNodeVault();
      await dex.useRadio(9);
      await dex.observe(node(5, 1));
      await dex.rememberPositions([node(5, 1.1)], now: t0);
      await dex.rememberPositions([node(5, 1.2)], now: t0.add(const Duration(seconds: 10)));
      Future<double?> saved() async {
        final again = BastionNodeVault();
        await again.useRadio(9);
        return again.records.single.latitude;
      }
      expect(await saved(), 1.1);
      await dex.rememberPositions([node(5, 1.2)], now: t0.add(const Duration(minutes: 2)));
      expect(await saved(), 1.2);
    });

    test('older saved records without a position still load', () async {
      final record = BastionNodeRecord.fromJson({
        'num': 5, 'firstSeen': '2026-01-01T00:00:00Z', 'lastSeen': '2026-01-01T00:00:00Z', 'encounters': 1,
      });
      expect(record.hasPosition, isFalse);
      expect(record.toJson().containsKey('lat'), isFalse);
    });
  });

  testWidgets('the heatmap is summarised in words', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.withData({
      'bastion.field_log.v1': jsonEncode([
        for (final r in [
          reading(35.2001, -80.8001, 5),
          reading(35.3001, -80.8001, -5),
          reading(35.4001, -80.8001, -15),
          reading(35.4002, -80.8002, -15),
        ])
          {...r, 'time': DateTime.now().toUtc().toIso8601String()},
      ]),
    });
    await BastionFieldLog.instance.load();
    addTearDown(() async {
      // The log is shared, so leave it empty for the next test.
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      await BastionFieldLog.instance.load();
    });
    expect(BastionFieldLog.instance.records, hasLength(4));
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: NotoryxTheme.build(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MapPage(radio: radio)),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-heatmap')));
    await tester.pump();
    expect(find.text('Coverage map: 1 strong, 1 fair, 1 weak areas, from 4 readings.'), findsOneWidget);
  });

  testWidgets('heatmap and remembered buttons explain an empty map', (tester) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: NotoryxTheme.build(Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MapPage(radio: radio)),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('map-heatmap')));
    await tester.pump();
    expect(find.textContaining('No coverage readings yet'), findsOneWidget);
    expect(find.byIcon(Icons.grid_on), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
