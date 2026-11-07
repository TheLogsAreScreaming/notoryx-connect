import 'package:bastion/map_page.dart';
import 'package:bastion/services/bastion_routes.dart';
import 'package:bastion/services/bastion_waypoints.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

MeshWaypoint _wp(String name, {int? from, int? icon, double lat = 40, double lon = -105}) =>
    MeshWaypoint(id: name.hashCode & 0x7fffffff, latitude: lat, longitude: lon, name: name, icon: icon, from: from);

/// A ready radio that records shared waypoints instead of sending them.
class _RouteRadio extends MeshtasticRadioCoordinator {
  final shared = <MeshWaypoint>[];
  @override
  bool get isReady => true;
  @override
  List<MeshWaypoint> get waypoints => shared;
  @override
  Future<void> sendWaypoint(MeshWaypoint waypoint, {int channel = 0}) async {
    shared.add(waypoint);
    notifyListeners();
  }
}

void main() {
  test('route stops are recognised by their numbered names', () {
    expect(BastionRoutes.stopOf(_wp('Ridge loop 2/4')), (route: 'Ridge loop', index: 2, count: 4));
    expect(BastionRoutes.stopOf(_wp('Camp')), isNull);
    expect(BastionRoutes.stopOf(_wp('Bad 5/4')), isNull);
    expect(BastionRoutes.stopOf(_wp('Single 1/1')), isNull);
  });

  test('stops group into routes per sender, in order, and report gaps', () {
    final routes = BastionRoutes.group([
      _wp('Loop 2/3', from: 7, lat: 40.01),
      _wp('Loop 1/3', from: 7, lat: 40.00),
      _wp('Loop 1/3', from: 9),
      _wp('Loop 2/3', from: 9),
      _wp('Loop 3/3', from: 9),
      _wp('Camp', from: 7),
    ]);
    expect(routes, hasLength(2));
    final partial = routes.firstWhere((r) => r.from == 7);
    expect(partial.complete, isFalse);
    expect([for (final s in partial.stops) s.name], ['Loop 1/3', 'Loop 2/3']);
    expect(partial.lengthMeters, closeTo(1112, 5));
    expect(routes.firstWhere((r) => r.from == 9).complete, isTrue);
  });

  test('building a route numbers the stops and keeps names within the limit', () {
    var id = 0;
    final stops = BastionRoutes.build(
      name: 'A very long route name that will not fit',
      points: [for (var i = 0; i < 10; i++) (latitude: 40.0 + i / 100, longitude: -105.0)],
      newId: () => ++id,
    );
    expect(stops, hasLength(10));
    expect(stops.every((s) => s.name.length <= BastionWaypointStore.maxNameLength), isTrue);
    expect(stops.last.name, endsWith(' 10/10'));
    expect(stops.every((s) => s.icon == BastionRoutes.stopIcon), isTrue);
    expect(BastionRoutes.group(stops).single.complete, isTrue);
    expect(() => BastionRoutes.build(name: 'x', points: [(latitude: 0, longitude: 0)], newId: () => 1),
        throwsArgumentError);
  });

  test('a rally point is a flag waypoint', () {
    expect(BastionRoutes.isRally(_wp('Meet', icon: BastionRoutes.rallyIcon)), isTrue);
    expect(BastionRoutes.isRally(_wp('Camp', icon: 0x26FA)), isFalse);
  });

  testWidgets('a route planned on the map is shared as numbered stops', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    routeStopSpacing = Duration.zero;
    addTearDown(() => routeStopSpacing = const Duration(seconds: 3));
    final radio = _RouteRadio();
    addTearDown(radio.dispose);
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MapPage(radio: radio))));
    await tester.pump();

    await tester.tap(find.byTooltip('Rally points & routes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan a route'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Tap the map to add stops'), findsOneWidget);
    await tester.tapAt(const Offset(400, 500));
    await tester.pump();
    await tester.tapAt(const Offset(600, 520));
    await tester.pump();
    await tester.tapAt(const Offset(700, 600));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 of 10 stops'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(find.textContaining('2 of 10 stops'), findsOneWidget);

    await tester.tap(find.text('Share route'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Route name'), 'Ridge');
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
    expect([for (final w in radio.shared) w.name], ['Ridge 1/2', 'Ridge 2/2']);
    expect(find.textContaining('Tap the map to add stops'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
