import 'package:bastion/map_page.dart';
import 'package:bastion/services/bastion_geofences.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('map explains how to get pins when no radio is connected', (tester) async {
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MapPage(radio: radio))));
    await tester.pump();
    expect(find.text('Connect a radio to show node positions'), findsOneWidget);
    expect(find.text('OpenStreetMap contributors'), findsOneWidget);
  });

  testWidgets('a zone added from the map is saved and drawn', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.binding.setSurfaceSize(const Size(1000, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MapPage(radio: radio))));
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
