import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/l10n/generated/app_localizations_en.dart';
import 'package:bastion/services/bastion_trace_card.dart';
import 'package:bastion/services/bastion_units.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_traceroute.dart';
import 'package:bastion/trace_card_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const local = 0x100;
const relay = 0x200;
const target = 0x300;

const nodes = [
  MeshtasticNode(num: local, longName: 'Base', latitude: 45.0, longitude: -122.0),
  MeshtasticNode(num: relay, longName: 'Ridge', latitude: 45.05, longitude: -122.0),
  MeshtasticNode(num: target, longName: 'Camp', latitude: 45.05, longitude: -121.95),
];

String name(int num) => switch (num) {
      local => 'Base',
      relay => 'Ridge',
      target => 'Camp',
      _ => '!${num.toRadixString(16).padLeft(8, '0')}',
    };

TraceCard card({List<TracerouteHop> back = const [], List<MeshtasticNode> known = nodes}) => TraceCard.from(
      TracerouteResult(
        towards: const [TracerouteHop(relay, 6.25), TracerouteHop(target, -3.5)],
        back: back,
      ),
      local: local,
      destination: target,
      nodes: known,
      name: name,
      sentAt: DateTime.utc(2026, 11, 13, 18, 30),
      roundTrip: const Duration(milliseconds: 4280),
    );

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('model', () {
    test('names, places and counts every hop', () {
      final c = card(back: const [TracerouteHop(relay, 5.0), TracerouteHop(local, -9.75)]);
      expect(c.sender, 'Base');
      expect(c.target, 'Camp');
      expect(c.relays, 1);
      expect(c.towards.map((h) => h.name), ['Ridge', 'Camp']);
      expect(c.towards.first.nodeId, '!00000200');
      expect(c.back.last.snrDb, -9.75);
      expect(c.weakestSnr, -9.75);
      expect(c.unplaced, isEmpty);
    });

    test('the map goes out and back and ends where it started', () {
      final c = card(back: const [TracerouteHop(relay, 5.0), TracerouteHop(local, -9.75)]);
      final p = c.routePoints;
      expect(p.first, (lat: 45.0, lon: -122.0));
      expect(p.last, (lat: 45.0, lon: -122.0));
      expect(p, hasLength(5)); // base, ridge, camp, ridge, base
      expect(c.routeMeters, greaterThan(15000));
    });

    test('without a reported way back, the sketch returns the way it went', () {
      final p = card().routePoints;
      expect(p, [
        (lat: 45.0, lon: -122.0),
        (lat: 45.05, lon: -122.0),
        (lat: 45.05, lon: -121.95),
        (lat: 45.05, lon: -122.0),
        (lat: 45.0, lon: -122.0),
      ]);
    });

    test('no map from fewer than two places, and unplaced nodes are named once', () {
      final c = card(
        back: const [TracerouteHop(relay, 5.0), TracerouteHop(local, 1.0)],
        known: const [MeshtasticNode(num: relay, latitude: 45.0, longitude: -122.0)],
      );
      expect(c.routePoints, isEmpty);
      expect(c.unplaced, ['Camp', 'Base']);
    });

    test('a hop with no SNR is left out of the weakest link', () {
      final c = TraceCard.from(
        const TracerouteResult(towards: [TracerouteHop(target, null)], back: []),
        local: local, destination: target, nodes: nodes, name: name,
        sentAt: DateTime.utc(2026), roundTrip: Duration.zero,
      );
      expect(c.weakestSnr, isNull);
      expect(c.relays, 0);
    });

    test('projection keeps the route inside the box', () {
      final xy = projectRoute(card().routePoints, width: 320, height: 180, padding: 20);
      for (final p in xy) {
        expect(p.x, inInclusiveRange(20, 300));
        expect(p.y, inInclusiveRange(20, 160));
      }
      // North is up: the camp (further north) is drawn above the base.
      expect(xy[2].y, lessThan(xy[0].y));
    });
  });

  test('plain text lists the timing and every hop', () async {
    await initializeDateFormatting('en');
    final text = traceCardText(AppLocalizationsEn(), card(), units: BastionUnits.metric, locale: 'en');
    expect(text, contains('From Base'));
    expect(text, contains('To Camp'));
    expect(text, contains('Round trip 4.3 s'));
    expect(text, contains('1 relay'));
    expect(text, contains('1. Ridge (!00000200) · 6.3 dB'));
    expect(text, contains('2. Camp (!00000300) · -3.5 dB'));
    expect(text, contains('Not reported by this firmware'));
    expect(text, contains('Weakest link -3.5 dB'));
    expect(text, contains('km as drawn'));
  });

  testWidgets('the card is translated and the sketch has a spoken label', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TraceCardPage(card: card()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Desde Base'), findsOneWidget);
    expect(find.text('Ruta de ida'), findsOneWidget);
    expect(find.text('Este firmware no la informa'), findsOneWidget);
    expect(find.text('Compartir imagen'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Esquema del recorrido de ida y vuelta desde Base por Ridge, Camp')),
        findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    semantics.dispose();
  });
}
