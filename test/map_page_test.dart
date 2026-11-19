import 'package:bastion/map_page.dart';
import 'package:bastion/traffic_map.dart';
import 'package:bastion/services/bastion_demo_radio.dart';
import 'package:bastion/services/bastion_geofences.dart';
import 'package:bastion/services/bastion_preferences.dart';
import 'package:bastion/services/bastion_stale.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('map explains how to get pins when no radio is connected', (tester) async {
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: MapPage(radio: radio))));
    await tester.pump();
    expect(find.text('Connect a radio to show node positions'), findsOneWidget);
    expect(find.text('OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('the map and its heard-within menu are translated', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MapPage(radio: radio)),
    ));
    await tester.pump();
    expect(find.text('Conecta una radio para ver las posiciones de los nodos'), findsOneWidget);
    expect(find.text('OpenStreetMap contributors'), findsOneWidget, reason: 'licence credit stays as written');
    await tester.tap(find.byKey(const ValueKey('map-heard-filter')));
    await tester.pumpAndSettle();
    expect(find.text('Oídos en la última hora'), findsOneWidget);
  });

  testWidgets('a watched route shows in the routes sheet and can be stopped', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await radio.setRouteWatch(const BastionRouteWatch(
      name: 'Ridge',
      points: [(latitude: 0, longitude: 0), (latitude: 0, longitude: 0.02)],
    ));
    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: MapPage(radio: radio))));
    await tester.pump();
    await tester.tap(find.byTooltip('Rally points & routes'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('route-watching')), findsOneWidget);
    expect(find.textContaining('Watching Ridge'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('route-watch-stop')));
    await tester.pumpAndSettle();
    expect(radio.routeWatch, isNull);
    expect(find.byKey(const ValueKey('route-watching')), findsNothing);
  });

  testWidgets('favorites only leaves just your radio and starred nodes', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await BastionPreferences.instance.update(favorites: false);
    final radio = BastionDemoRadio();
    addTearDown(radio.dispose);
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: MapPage(radio: radio))));
    await tester.pump();
    final pins = find.byWidgetPredicate((w) => w.runtimeType.toString() == '_NodePin');
    final all = tester.widgetList(pins).length;
    expect(all, radio.nodes.length);

    await tester.tap(find.byKey(const ValueKey('map-favorites-only')));
    await tester.pump();
    expect(BastionPreferences.instance.favoritesOnly, isTrue);
    expect(tester.widgetList(pins).length, 1 + radio.favoriteNums.length,
        reason: 'your own radio always shows');

    await tester.tap(find.byKey(const ValueKey('map-favorites-only')));
    await tester.pump();
    expect(tester.widgetList(pins).length, all);
  });

  testWidgets('a zone added from the map is saved and drawn', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: MapPage(radio: radio))));
    await tester.pump();

    await tester.tap(find.byTooltip('Zones'));
    await tester.pumpAndSettle();
    expect(find.text('No zones yet.'), findsOneWidget);
    await tester.tap(find.text('Add zone at map center'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name, e.g. Camp'), 'Camp');
    await tester.pump();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(radio.geofences.single.name, 'Camp');
    expect(radio.geofences.single.watch, GeofenceWatch.tripContacts);
    expect(find.textContaining('Trip contacts • alert when they arrive or leave'), findsOneWidget);
    expect(find.byType(CircleLayer), findsOneWidget);

    await tester.tap(find.byTooltip('Delete Camp'));
    await tester.pumpAndSettle();
    expect(radio.geofences, isEmpty);
  });

  Widget app(MeshtasticRadioCoordinator radio) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: MapPage(radio: radio)));

  testWidgets('nodes quiet past the stale setting are drawn faded and say so', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await BastionPreferences.instance.update(stale: BastionStaleAfter.day, favorites: false);
    addTearDown(() => BastionPreferences.instance.update(stale: BastionStaleAfter.standard));
    // Every demo node, this radio included, was last heard two days ago.
    final radio = BastionDemoRadio(clock: () => DateTime.now().subtract(const Duration(days: 2)));
    addTearDown(radio.dispose);
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(radio));
    await tester.pump();

    final others = radio.nodes.where((n) => n.num != radio.localNodeNum).toList();
    for (final n in others) {
      final faded = find.byKey(ValueKey('stale-pin-${n.num}'));
      expect(faded, findsOneWidget, reason: n.displayName);
      expect(tester.widget<Opacity>(faded).opacity, closeTo(0.45, 1e-9));
    }
    expect(find.byKey(ValueKey('stale-pin-${radio.localNodeNum}')), findsNothing,
        reason: 'your own radio is never marked stale');
    expect(find.bySemanticsLabel(RegExp('${RegExp.escape(others.first.displayName)}.*stale · 2 d ago')), findsOneWidget);

    await BastionPreferences.instance.update(stale: BastionStaleAfter.week);
    await tester.pump();
    expect(find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('stale-pin-')),
        findsNothing);

    await BastionPreferences.instance.update(stale: BastionStaleAfter.off);
    await tester.pump();
    expect(find.byKey(ValueKey('stale-pin-${others.first.num}')), findsNothing);
  });

  testWidgets('range rings draw four labelled rings around this radio and are remembered', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await BastionPreferences.instance.update(rings: false);
    addTearDown(() => BastionPreferences.instance.update(rings: false));
    final radio = BastionDemoRadio();
    addTearDown(radio.dispose);
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(radio));
    await tester.pump();
    expect(find.byKey(const ValueKey('range-rings')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('map-range-rings')));
    await tester.pump();
    expect(BastionPreferences.instance.rangeRings, isTrue);
    expect(find.byKey(const ValueKey('range-rings')), findsOneWidget);
    expect(find.text("Range rings need your radio's position, and it has none yet."), findsNothing);
    final rings = find.descendant(of: find.byKey(const ValueKey('range-rings')), matching: find.byType(CircleLayer));
    expect(tester.widget<CircleLayer>(rings).circles, hasLength(4));
    // The clear map area is measured after the first frame.
    await tester.pump();
    await tester.pump();
    final tags = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        RegExp(r'^range-ring-(label|compass)-').hasMatch((w.key! as ValueKey<String>).value));
    expect(find.byKey(const ValueKey('range-ring-label-0')), findsOneWidget, reason: 'the inner ring is always labelled');
    expect(tags.evaluate().length, greaterThanOrEqualTo(2));
    final topBar = tester.getRect(find.ancestor(of: find.byKey(const ValueKey('map-range-rings')), matching: find.byType(Card)).first);
    final sideBar = tester.getRect(find.byType(TrafficToolbar));
    final shown = [for (final e in tags.evaluate()) tester.getRect(find.byWidget(e.widget))];
    for (final r in shown) {
      expect(r.overlaps(topBar), isFalse, reason: 'tag at $r is under the top bar $topBar');
      expect(r.overlaps(sideBar), isFalse, reason: 'tag at $r is under the side toolbar $sideBar');
    }
    for (var i = 0; i < shown.length; i++) {
      for (var j = i + 1; j < shown.length; j++) {
        expect(shown[i].overlaps(shown[j]), isFalse, reason: 'tags overlap');
      }
    }
    final spokes = find.descendant(of: find.byKey(const ValueKey('range-rings')), matching: find.byType(PolylineLayer));
    expect(tester.widget<PolylineLayer>(spokes).polylines, hasLength(8));

    await tester.tap(find.byKey(const ValueKey('map-range-rings')));
    await tester.pump();
    expect(BastionPreferences.instance.rangeRings, isFalse);
    expect(find.byKey(const ValueKey('range-rings')), findsNothing);
  });

  testWidgets('range rings say so when this radio has no position', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    await BastionPreferences.instance.update(rings: false);
    addTearDown(() => BastionPreferences.instance.update(rings: false));
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(app(radio));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('map-range-rings')));
    await tester.pump();
    expect(find.text("Range rings need your radio's position, and it has none yet."), findsOneWidget);
    expect(find.byKey(const ValueKey('range-rings')), findsNothing);
  });
}
