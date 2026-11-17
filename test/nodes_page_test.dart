import 'package:bastion/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  testWidgets('connected, Nodes shows a radio bar and nodes grouped by when heard', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try the demo'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.hub_outlined).last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('radio-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-radios')), findsNothing, reason: 'no scan button while connected');
    expect(find.text('No radios found yet'), findsNothing);
    expect(find.byKey(const ValueKey('nodes-search')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-active')).evaluate().isNotEmpty ||
          find.byKey(const ValueKey('group-today')).evaluate().isNotEmpty ||
          find.byKey(const ValueKey('group-older')).evaluate().isNotEmpty,
      isTrue,
    );

    // Search narrows the list.
    await tester.enterText(find.byKey(const ValueKey('nodes-search')), 'ridge');
    await tester.pumpAndSettle();
    expect(find.text('Ridge Relay'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('nodes-search')), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('No nodes match "zzzz"'), findsOneWidget);

    // The bar opens the radio sheet with the connection and the doctor.
    await tester.tap(find.byKey(const ValueKey('radio-bar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('radio-sheet')), findsOneWidget);
    expect(find.text('Disconnect'), findsWidgets);
    expect(find.byKey(const ValueKey('sheet-doctor')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
