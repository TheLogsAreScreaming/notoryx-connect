import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/link_planner_page.dart';
import 'package:bastion/services/bastion_link_planner.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

List<double> _flat(int n, double h) => List.filled(n, h);

class _FakeElevation implements ElevationSource {
  _FakeElevation(this.ground);
  final List<double> Function(int count) ground;
  int calls = 0;
  @override
  Future<List<double>> heights(List<({double latitude, double longitude})> points) async {
    calls++;
    return ground(points.length);
  }
}

class _RoughRadio extends MeshtasticRadioCoordinator {
  @override
  int? get localNodeNum => 1;
  @override
  List<MeshtasticNode> get nodes => const [
        MeshtasticNode(num: 1, longName: 'Base', latitude: 40.0, longitude: -105.0),
        MeshtasticNode(num: 2, longName: 'Ridge', latitude: 40.05, longitude: -105.0),
        MeshtasticNode(num: 4, longName: 'Fuzzy', latitude: 40.02, longitude: -105.03, positionPrecisionBits: 13),
      ];
}

class _PlacedRadio extends MeshtasticRadioCoordinator {
  @override
  int? get localNodeNum => 1;
  @override
  List<MeshtasticNode> get nodes => const [
        MeshtasticNode(num: 1, longName: 'Base', latitude: 40.0, longitude: -105.0),
        MeshtasticNode(num: 2, longName: 'Ridge', latitude: 40.05, longitude: -105.0),
        MeshtasticNode(num: 3, longName: 'No GPS'),
      ];
}

void main() {
  test('flat ground over a short hop is clear', () {
    final r = BastionLinkPlanner.analyse(
      distanceMeters: 2000, ground: _flat(64, 1000), startAntennaMeters: 10, endAntennaMeters: 10, mhz: 915);
    expect(r.verdict, LinkVerdict.clear);
    expect(r.pathLossDb, closeTo(97.7, 0.5));
  });

  test('a hill in the middle blocks the link', () {
    final ground = _flat(64, 1000)..[32] = 1100;
    final r = BastionLinkPlanner.analyse(
      distanceMeters: 5000, ground: ground, startAntennaMeters: 2, endAntennaMeters: 2, mhz: 915);
    expect(r.verdict, LinkVerdict.blocked);
    expect(r.worstClearanceMeters, lessThan(0));
    expect(r.worstAtMeters, closeTo(5000 * 32 / 63, 1));
  });

  test('earth curvature makes long low links marginal or blocked', () {
    final r = BastionLinkPlanner.analyse(
      distanceMeters: 40000, ground: _flat(64, 0), startAntennaMeters: 2, endAntennaMeters: 2, mhz: 915);
    expect(r.verdict, isNot(LinkVerdict.clear));
  });

  test('ground just under the path makes it marginal', () {
    final ground = _flat(64, 1000)..[32] = 1006;
    final r = BastionLinkPlanner.analyse(
      distanceMeters: 3000, ground: ground, startAntennaMeters: 10, endAntennaMeters: 10, mhz: 915);
    expect(r.verdict, LinkVerdict.marginal);
  });

  test('sample points run from end to end and the Fresnel zone peaks mid-path', () {
    final pts = BastionLinkPlanner.samplePoints(40, -105, 41, -104, 5);
    expect(pts.first, (latitude: 40.0, longitude: -105.0));
    expect(pts.last, (latitude: 41.0, longitude: -104.0));
    expect(BastionLinkPlanner.fresnelRadius(500, 500, 915),
        greaterThan(BastionLinkPlanner.fresnelRadius(100, 900, 915)));
  });

  testWidgets('the planner checks two placed nodes and shows the verdict', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final radio = _PlacedRadio();
    addTearDown(radio.dispose);
    final elevation = _FakeElevation((n) => List.generate(n, (i) => i == n ~/ 2 ? 1500.0 : 1000.0));
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: LinkPlannerPage(radio: radio, elevation: elevation)));
    await tester.pumpAndSettle();
    expect(find.text('No GPS'), findsNothing, reason: 'only nodes with a position can be picked');
    await tester.tap(find.text('To'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ridge').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check line of sight'));
    await tester.pumpAndSettle();
    expect(elevation.calls, 1);
    expect(find.text('Blocked by terrain'), findsOneWidget);
    expect(find.text('Height profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('the Fresnel floor sits below the line, deepest mid-path, and touches it at the ends', () {
    final r = BastionLinkPlanner.analyse(
      distanceMeters: 4000, ground: _flat(64, 1000), startAntennaMeters: 10, endAntennaMeters: 10, mhz: 915);
    expect(r.mhz, 915);
    expect(r.fresnelFloorAt(0), closeTo(r.lineStart, 1e-9));
    expect(r.fresnelFloorAt(4000), closeTo(r.lineEnd, 1e-9));
    final mid = r.lineAt(2000) - r.fresnelFloorAt(2000);
    expect(mid, closeTo(BastionLinkPlanner.fresnelRadius(2000, 2000, 915), 1e-9));
    expect(mid, greaterThan(r.lineAt(500) - r.fresnelFloorAt(500)));
  });

  testWidgets('opened from a node, the planner starts from this radio to that node', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final radio = _PlacedRadio();
    addTearDown(radio.dispose);
    final elevation = _FakeElevation((n) => _flat(n, 1000));
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
        home: LinkPlannerPage(radio: radio, elevation: elevation, initialFrom: 1, initialTo: 2)));
    await tester.pumpAndSettle();
    expect(find.text('Base'), findsOneWidget);
    expect(find.text('Ridge'), findsOneWidget);
    expect(find.byKey(const ValueKey('lp-approximate')), findsNothing);
    await tester.tap(find.text('Check line of sight'));
    await tester.pumpAndSettle();
    expect(elevation.calls, 1);
    expect(find.text('Height profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a node with a rounded position gets an approximate warning', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final radio = _RoughRadio();
    addTearDown(radio.dispose);
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
        home: LinkPlannerPage(radio: radio, elevation: _FakeElevation((n) => _flat(n, 0)), initialTo: 4)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lp-approximate')), findsOneWidget);
    expect(find.textContaining('Fuzzy shares only an approximate position'), findsOneWidget);
  });
}
