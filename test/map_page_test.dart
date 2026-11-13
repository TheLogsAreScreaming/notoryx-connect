import 'package:bastion/map_page.dart';
import 'package:bastion/services/bastion_demo_radio.dart';
import 'package:bastion/services/bastion_geofences.dart';
import 'package:bastion/services/bastion_preferences.dart';
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
}
