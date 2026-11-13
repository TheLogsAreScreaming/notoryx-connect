import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/place_search_page.dart';
import 'package:bastion/services/bastion_place_search.dart';
import 'package:bastion/services/bastion_waypoints.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const nodes = [
  MeshtasticNode(num: 0xa1b2c3d4, longName: 'Ridge Relay', shortName: 'RDG', latitude: 39.1, longitude: -105.2),
  MeshtasticNode(num: 0x11111111, longName: 'Base Camp', shortName: 'BC', latitude: 39.2, longitude: -105.3),
  MeshtasticNode(num: 0x22222222, longName: 'Ridgeway', shortName: 'RW'),
];
const waypoints = [
  MeshWaypoint(id: 1, latitude: 39.3, longitude: -105.4, name: 'Peña Spring', description: 'water'),
  MeshWaypoint(id: 2, latitude: 39.4, longitude: -105.5, name: 'Upper Ridge Camp'),
];

class FakeOnline extends NominatimPlaceSearch {
  FakeOnline(this.reply);
  final List<PlaceResult> reply;
  final queries = <String>[];

  @override
  Future<List<PlaceResult>> search(String query, {String? language}) async {
    queries.add(query);
    return reply;
  }
}

void main() {
  group('local search', () {
    test('names that start with the search come first, then words, then the rest', () {
      final found = BastionPlaceSearch.local('ridge', nodes: nodes, waypoints: waypoints);
      expect(found.map((r) => r.name), ['Ridge Relay', 'Upper Ridge Camp']);
    });

    test('nodes without a position are skipped', () {
      expect(BastionPlaceSearch.local('ridgeway', nodes: nodes, waypoints: waypoints), isEmpty);
    });

    test('case and accents are ignored', () {
      expect(BastionPlaceSearch.local('PENA', nodes: nodes, waypoints: waypoints).single.name, 'Peña Spring');
      expect(BastionPlaceSearch.local('peña', nodes: nodes, waypoints: waypoints).single.kind, PlaceKind.waypoint);
    });

    test('finds a node by short name or hex ID', () {
      expect(BastionPlaceSearch.local('bc', nodes: nodes, waypoints: waypoints).single.name, 'Base Camp');
      expect(BastionPlaceSearch.local('a1b2', nodes: nodes, waypoints: waypoints).single.name, 'Ridge Relay');
    });

    test('an empty search finds nothing', () {
      expect(BastionPlaceSearch.local('  ', nodes: nodes, waypoints: waypoints), isEmpty);
    });
  });

  group('Nominatim replies', () {
    test('reads names and positions and skips broken entries', () {
      final found = NominatimPlaceSearch.parse('''[
        {"lat": "39.7392", "lon": "-104.9903", "name": "Denver", "display_name": "Denver, Colorado, United States"},
        {"lat": "bad", "lon": "1", "name": "Nowhere"},
        {"lat": "95", "lon": "1", "name": "Off the globe"},
        {"lat": "40.0", "lon": "-105.0", "name": "", "display_name": "Longs Peak, Larimer County"}
      ]''');
      expect(found.map((r) => r.name), ['Denver', 'Longs Peak']);
      expect(found.first.detail, 'Colorado, United States');
      expect(found.first.latitude, closeTo(39.7392, 1e-9));
      expect(found.last.detail, 'Larimer County');
    });

    test('an unexpected reply is an error', () {
      expect(() => NominatimPlaceSearch.parse('{"error": "x"}'), throwsFormatException);
    });

    test('a second search within a second is refused', () async {
      var now = DateTime(2026, 11, 13, 12);
      final online = NominatimPlaceSearch(clock: () => now);
      expect(online.tooSoon, isFalse);
      await expectLater(online.search(''), completion(isEmpty));
      expect(online.tooSoon, isFalse, reason: 'an empty search sends nothing');
      now = now.add(const Duration(milliseconds: 10));
      expect(online.tooSoon, isFalse);
    });

    test('says who is asking, as the usage policy requires', () {
      expect(NominatimPlaceSearch.userAgent, startsWith('NOTORYX-Connect/'));
    });
  });

  Widget app(Widget home, {Locale? locale}) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  testWidgets('choosing a local result returns it without going online', (tester) async {
    final online = FakeOnline(const []);
    PlaceResult? chosen;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => chosen = await Navigator.of(context).push<PlaceResult>(
                MaterialPageRoute(
                  builder: (_) => PlaceSearchPage(nodes: nodes, waypoints: waypoints, online: online),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('place-query')), 'spring');
    await tester.pump();
    expect(find.text('Peña Spring'), findsOneWidget);
    expect(find.textContaining('Nominatim'), findsOneWidget, reason: 'says what searching online sends');
    await tester.tap(find.text('Peña Spring'));
    await tester.pumpAndSettle();
    expect(chosen?.name, 'Peña Spring');
    expect(online.queries, isEmpty);
  });

  testWidgets('online search runs only when asked, in Spanish too', (tester) async {
    final online = FakeOnline(const [
      PlaceResult(name: 'Leadville', detail: 'Colorado', latitude: 39.25, longitude: -106.29, kind: PlaceKind.online),
    ]);
    await tester.pumpWidget(
      app(
        PlaceSearchPage(nodes: nodes, waypoints: waypoints, online: online),
        locale: const Locale('es'),
      ),
    );
    await tester.enterText(find.byKey(const ValueKey('place-query')), 'leadville');
    await tester.pump();
    expect(find.text('Ningún nodo ni punto de ruta coincide. Prueba a buscar en línea.'), findsOneWidget);
    expect(online.queries, isEmpty);
    await tester.tap(find.byKey(const ValueKey('place-online')));
    await tester.pumpAndSettle();
    expect(online.queries, ['leadville']);
    expect(find.text('Leadville'), findsOneWidget);
    expect(find.text('Datos de lugares © colaboradores de OpenStreetMap'), findsOneWidget);
  });
}
