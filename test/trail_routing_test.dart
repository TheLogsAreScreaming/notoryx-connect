import 'dart:convert';
import 'dart:io';

import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/bastion_trail_graph.dart';
import 'package:bastion/services/bastion_trail_store.dart';
import 'package:bastion/trail_routing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Two trails crossing near (35.6, -82.5), a separate island, a private
/// track and a motorway, plus some named places.
Map<String, dynamic> _overpass() {
  Map<String, Object> way(int id, String highway, List<(int, double, double)> nodes, {Map<String, String> tags = const {}}) => {
        'type': 'way',
        'id': id,
        'tags': {'highway': highway, ...tags},
        'nodes': [for (final n in nodes) n.$1],
        'geometry': [for (final n in nodes) {'lat': n.$2, 'lon': n.$3}],
      };
  return {
    'elements': [
      way(1, 'path', [(1, 35.600, -82.500), (2, 35.601, -82.500), (3, 35.602, -82.500), (4, 35.603, -82.500)]),
      way(2, 'track', [(3, 35.602, -82.500), (5, 35.602, -82.499), (6, 35.602, -82.498)]),
      way(3, 'footway', [(10, 35.700, -82.500), (11, 35.701, -82.500)]),
      way(4, 'track', [(6, 35.602, -82.498), (20, 35.610, -82.498)], tags: {'access': 'private'}),
      way(5, 'motorway', [(1, 35.600, -82.500), (30, 35.590, -82.500)]),
      {'type': 'node', 'id': 100, 'lat': 35.602, 'lon': -82.498, 'tags': {'name': 'Bald Knob', 'natural': 'peak'}},
      {'type': 'node', 'id': 101, 'lat': 35.700, 'lon': -82.500, 'tags': {'name': 'Café Hütte', 'tourism': 'alpine_hut'}},
      {'type': 'node', 'id': 102, 'lat': 35.6, 'lon': -82.5, 'tags': {'name': 'Bench', 'leisure': 'bench'}},
    ],
  };
}

class _Overpass implements OverpassClient {
  _Overpass(this.reply);
  final Map<String, dynamic>? reply;
  String? lastQuery;
  @override
  Future<List<int>> query(String q) async {
    lastQuery = q;
    if (reply == null) throw const HttpException('offline');
    return utf8.encode(jsonEncode(reply));
  }
}

void main() {
  group('graph', () {
    final graph = TrailGraph.fromOverpass(_overpass());

    test('skips private ways and motorways', () {
      // 4 + 2 new on the track + 2 on the island; the private and motorway
      // ways add nothing.
      expect(graph.nodeCount, 8);
    });

    test('routes along trails from near the start to near the end', () {
      final r = graph.route(35.6001, -82.5001, 35.602, -82.4981);
      expect(r.problem, isNull);
      expect(r.points.first, (35.600, -82.500));
      expect(r.points.last, (35.602, -82.498));
      expect(r.meters, closeTo(222 + 181, 15));
    });

    test('says why there is no route', () {
      expect(graph.route(35.65, -82.5, 35.602, -82.498).problem, TrailRouteProblem.startTooFar);
      expect(graph.route(35.6, -82.5, 35.65, -82.5).problem, TrailRouteProblem.endTooFar);
      expect(graph.route(35.6, -82.5, 35.701, -82.5).problem, TrailRouteProblem.notConnected);
    });

    test('survives saving and loading', () {
      final again = TrailGraph.fromBytes(graph.toBytes());
      expect(again.nodeCount, graph.nodeCount);
      expect(again.route(35.6, -82.5, 35.602, -82.498).problem, isNull);
      expect(() => TrailGraph.fromBytes([1, 2, 3]), throwsFormatException);
    });
  });

  test('places: only the named kinds, found without accents, names that start with the query first', () {
    final places = placesFromOverpass(_overpass());
    expect(places.map((p) => p.name), unorderedEquals(['Bald Knob', 'Café Hütte']));
    expect(searchPlaces(places, 'cafe hutte').single.kind, TrailPlaceKind.hut);
    final mixed = [
      const TrailPlace('Upper Bald', TrailPlaceKind.peak, 0, 0),
      const TrailPlace('Bald Knob', TrailPlaceKind.peak, 0, 0),
    ];
    expect(searchPlaces(mixed, 'bald').first.name, 'Bald Knob');
    expect(placesFromBytes(placesToBytes(places)).length, 2);
  });

  test('a box around a point is about the right size', () {
    final b = BastionTrailStore.around(35.6, -82.5, 10);
    expect(b.areaKm2, closeTo(400, 10));
    expect(b.contains(35.6, -82.5), isTrue);
    expect(BastionTrailStore.around(35.6, -82.5, 30).areaKm2, lessThan(maxTrailAreaKm2 + 1100),
        reason: 'the largest choice the page offers is 20 km');
  });

  group('store', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('bastion-trails-'));
    tearDown(() => dir.deleteSync(recursive: true));

    testWidgets('downloads, keeps, routes, lists places and deletes an area', (tester) async {
      await tester.runAsync(() async {
        final client = _Overpass(_overpass());
        final store = BastionTrailStore(client: client, directory: dir);
        await store.load();
        final area = await store.download('Home', BastionTrailStore.around(35.6, -82.5, 5));
        expect(client.lastQuery, contains('way["highway"'));
        expect(area.bytes, greaterThan(0));

        final again = BastionTrailStore(client: client, directory: dir);
        await again.load();
        expect(again.areas.single.name, 'Home');
        expect((await again.allPlaces()).length, 2);
        final found = again.areaFor(35.6, -82.5, 35.602, -82.498)!;
        expect((await again.graphFor(found)).route(35.6, -82.5, 35.602, -82.498).problem, isNull);
        expect(again.areaFor(35.6, -82.5, 40, -80), isNull);

        await again.delete(found.id);
        expect(again.areas, isEmpty);
        expect(dir.listSync(), isEmpty);
      });
    });

    test('refuses areas that are too big, empty, or would overfill storage', () async {
      final store = BastionTrailStore(client: _Overpass(_overpass()), directory: dir, limitBytes: 10);
      await expectLater(store.download('Huge', BastionTrailStore.around(35, -82, 60)),
          throwsA(isA<TrailDownloadException>().having((e) => e.problem, 'problem', TrailDownloadProblem.tooLarge)));
      await expectLater(
          BastionTrailStore(client: _Overpass({'elements': []}), directory: dir)
              .download('Empty', BastionTrailStore.around(35, -82, 5)),
          throwsA(isA<TrailDownloadException>().having((e) => e.problem, 'p', TrailDownloadProblem.noTrails)));
      await expectLater(
          BastionTrailStore(client: _Overpass(null), directory: dir).download('Offline', BastionTrailStore.around(35, -82, 5)),
          throwsA(isA<TrailDownloadException>().having((e) => e.problem, 'p', TrailDownloadProblem.failed)));
    });
  });

  testWidgets('the page downloads around you and plans a route to a place', (tester) async {
    late Directory dir;
    late BastionTrailStore store;
    await tester.runAsync(() async {
      dir = Directory.systemTemp.createTempSync('bastion-trails-page-');
      store = BastionTrailStore(client: _Overpass(_overpass()), directory: dir);
      await store.load();
    });
    addTearDown(() => dir.deleteSync(recursive: true));
    String? shared;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TrailRoutingPage(
        store: store,
        whereAmI: () async => (35.6001, -82.5001),
        share: (name, text) async => shared = text,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Download an area first, below.'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('trail-download')));
    await tester.tap(find.byKey(const ValueKey('trail-download')));
    // The download writes files and parses in an isolate: real time.
    for (var i = 0; i < 50 && store.areas.isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(store.areas, hasLength(1));
    expect(find.text('Area saved. It works with no signal now.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('trail-search')), 'bald');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('trail-place-Bald Knob')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text('Route to Bald Knob'), findsOneWidget);
    expect(find.textContaining('at an easy pace'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const ValueKey('trail-gpx')));
    await tester.tap(find.byKey(const ValueKey('trail-gpx')));
    await tester.pump();
    expect(shared, contains('<rtept'));
  });
}
