import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/local_mesh_discovery_page.dart';

void main() {
  testWidgets('discovery planner is explicitly non-operational', (tester) async {
    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: const LocalMeshDiscoveryPage()));
    expect(find.text('Local mesh discovery'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Start scan (not yet available)'), 200);
    expect(find.text('Start scan (not yet available)'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Start scan (not yet available)'));
    expect(button.onPressed, isNull);
    expect(find.text('Estimated listening time: 10 minutes'), findsOneWidget);
  });

  testWidgets('deselecting all presets blocks a scan plan', (tester) async {
    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: const LocalMeshDiscoveryPage()));
    await tester.tap(find.text('Long Range - Fast'));
    await tester.pump();
    await tester.tap(find.text('Medium Range - Fast'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Select at least one preset.'), 200);
    expect(find.text('Select at least one preset.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });
}
