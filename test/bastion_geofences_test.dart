import 'package:bastion/services/bastion_field_alerts.dart';
import 'package:bastion/services/bastion_geofences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

// About 111 m per 0.001 degree of latitude.
const camp = BastionGeofence(id: 'camp', name: 'Camp', latitude: 40, longitude: -105, radiusMeters: 500);

GeofencePosition at(double metersNorth, {int num = 7}) =>
    (num: num, name: 'Hiker', latitude: 40 + metersNorth / 111195, longitude: -105);

Set<int> Function(GeofenceWatch) watching(Set<int> nodes) => (_) => nodes;

void main() {
  group('off-route alerts', () {
    // A route east along the equator, about 2.2 km long.
    const line = [(latitude: 0.0, longitude: 0.0), (latitude: 0.0, longitude: 0.02)];
    const route = BastionRouteWatch(name: 'Ridge', points: line, limitMeters: 100);
    GeofencePosition at(double lat, {int num = 7}) =>
        (num: num, name: 'Ann', latitude: lat, longitude: 0.01);

    test('distance is to the nearest segment', () {
      expect(BastionRouteWatch.metersFrom(0.001, 0.01, line), closeTo(111, 1));
      expect(BastionRouteWatch.metersFrom(0, 0.021, line), closeTo(111, 1));
    });

    test('alerts once on leaving, rearms after coming back, only for watched nodes', () {
      final engine = BastionRouteWatchEngine()..startSession();
      expect(engine.check(route, [at(0)], {7}), isEmpty);
      final off = engine.check(route, [at(0.0015)], {7});
      expect(off.single.kind, BastionAlertKind.offRoute);
      expect(off.single.body, 'Ann is 167 m from Ridge.');
      expect(engine.check(route, [at(0.002)], {7}), isEmpty);
      expect(engine.check(route, [at(0.0008)], {7}), isEmpty, reason: 'not back until within 70 m');
      expect(engine.check(route, [at(0.0002)], {7}), isEmpty);
      expect(engine.check(route, [at(0.0015)], {7}), hasLength(1));
      expect(engine.check(route, [at(0), at(0.01, num: 8)], {7}), isEmpty);
      expect(engine.check(route, [at(0.01, num: 8)], {7}), isEmpty);
    });

    test('nothing alerts outside a session, or for someone first seen off the route', () {
      final engine = BastionRouteWatchEngine();
      expect(engine.check(route, [at(0)], {7}), isEmpty);
      expect(engine.check(route, [at(0.01)], {7}), isEmpty);
      engine.startSession();
      expect(engine.check(route, [at(0.01)], {7}), isEmpty);
      expect(engine.check(route, [at(0.02)], {7}), isEmpty);
    });

    test('the watch survives a restart and junk is ignored', () async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final store = BastionRouteWatchStore();
      expect(await store.set(const BastionRouteWatch(
        name: 'Ridge', points: line, limitMeters: 200, watch: GeofenceWatch.favorites)), isNull);
      final again = BastionRouteWatchStore();
      await again.load();
      expect(again.watch!.name, 'Ridge');
      expect(again.watch!.limitMeters, 200);
      expect(again.watch!.watch, GeofenceWatch.favorites);
      expect(again.watch!.points, hasLength(2));
      await again.set(null);
      final gone = BastionRouteWatchStore();
      await gone.load();
      expect(gone.watch, isNull);
      expect(BastionRouteWatch.fromJson({'name': 'x', 'limit': 5, 'points': [[1, 2]]}), isNull,
          reason: 'a route needs two points');
    });
  });

  late BastionGeofenceEngine engine;
  setUp(() => engine = BastionGeofenceEngine()..startSession());

  test('the first position only sets the side, then crossings alert once', () {
    expect(engine.check([camp], [at(100)], watching({7})), isEmpty);
    final left = engine.check([camp], [at(700)], watching({7}));
    expect(left.single.kind, BastionAlertKind.geofenceLeave);
    expect(left.single.title, 'Hiker left Camp');
    expect(engine.check([camp], [at(900)], watching({7})), isEmpty);
    final back = engine.check([camp], [at(200)], watching({7}));
    expect(back.single.kind, BastionAlertKind.geofenceArrive);
    expect(back.single.title, 'Hiker arrived at Camp');
  });

  test('wandering near the edge does not alert over and over', () {
    engine.check([camp], [at(490)], watching({7}));
    // Margin is 50 m for a 500 m zone.
    expect(engine.check([camp], [at(530)], watching({7})), isEmpty);
    expect(engine.check([camp], [at(470)], watching({7})), isEmpty);
    expect(engine.check([camp], [at(560)], watching({7})), hasLength(1));
    expect(engine.check([camp], [at(520)], watching({7})), isEmpty);
    expect(engine.check([camp], [at(440)], watching({7})), hasLength(1));
  });

  test('a zone set to arrive only stays quiet when a node leaves', () {
    const arriveOnly = BastionGeofence(id: 'a', name: 'Trailhead', latitude: 40, longitude: -105,
        radiusMeters: 500, alertOn: GeofenceAlertOn.arrive);
    engine.check([arriveOnly], [at(100)], watching({7}));
    expect(engine.check([arriveOnly], [at(1000)], watching({7})), isEmpty);
    expect(engine.check([arriveOnly], [at(100)], watching({7})), hasLength(1));
  });

  test('only watched nodes alert', () {
    engine.check([camp], [at(100, num: 8)], watching({7}));
    expect(engine.check([camp], [at(1000, num: 8)], watching({7})), isEmpty);
  });

  test('nothing alerts outside a connected session', () {
    engine.endSession();
    expect(engine.check([camp], [at(100)], watching({7})), isEmpty);
    expect(engine.check([camp], [at(1000)], watching({7})), isEmpty);
  });

  test('a node watched again starts fresh instead of alerting from old state', () {
    engine.check([camp], [at(100)], watching({7}));
    engine.check([camp], [at(1000)], watching(<int>{}));
    expect(engine.check([camp], [at(1000)], watching({7})), isEmpty);
  });

  test('zones survive a restart and bad entries are skipped', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final store = BastionGeofenceStore();
    await store.load();
    expect(await store.put(camp), isNull);
    expect(await store.put(const BastionGeofence(id: 'camp', name: 'Base camp', latitude: 40,
        longitude: -105, radiusMeters: 250, watch: GeofenceWatch.favorites)), isNull);
    final reloaded = BastionGeofenceStore();
    await reloaded.load();
    expect(reloaded.zones.single.name, 'Base camp');
    expect(reloaded.zones.single.watch, GeofenceWatch.favorites);
    expect(await reloaded.remove('camp'), isNull);
    expect(BastionGeofence.fromJson({'id': 'x', 'name': 'x', 'lat': 95, 'lon': 0, 'radius': 10}), isNull);
  });

  test('zones are capped', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final store = BastionGeofenceStore();
    await store.load();
    for (var i = 0; i < BastionGeofenceStore.maxZones; i++) {
      expect(await store.put(BastionGeofence(id: '$i', name: '$i', latitude: 0, longitude: 0, radiusMeters: 100)), isNull);
    }
    expect(await store.put(const BastionGeofence(id: 'more', name: 'more', latitude: 0, longitude: 0, radiusMeters: 100)),
        contains('up to 20'));
  });

  test('unreadable zones are never overwritten', () async {
    SharedPreferencesAsyncPlatform.instance = _FailingStore();
    final store = BastionGeofenceStore(preferences: SharedPreferencesAsync());
    await store.load();
    expect(await store.put(camp), contains('could not be read'));
  });
}

final class _FailingStore extends InMemorySharedPreferencesAsync {
  _FailingStore() : super.empty();
  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) async => throw StateError('read failed');
}
