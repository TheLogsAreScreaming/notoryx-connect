import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/radio_backup_page.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    tester.view.physicalSize = const Size(390, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RadioBackupPage(radio: radio),
    ));
    await tester.pump();
  }

  testWidgets('steps tick off, count up and start over', (tester) async {
    await open(tester);
    expect(find.text('0 of 7 done'), findsOneWidget);
    await tester.tap(find.text('Moving to a new radio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('new-radio-step-0')));
    await tester.tap(find.byKey(const ValueKey('new-radio-step-3')));
    await tester.pump();
    expect(find.text('2 of 7 done'), findsOneWidget);
    await tester.tap(find.text('Start over'));
    await tester.pump();
    expect(find.text('0 of 7 done'), findsOneWidget);
  });

  testWidgets('the checklist is translated', (tester) async {
    await open(tester, locale: const Locale('es'));
    expect(find.text('Pasar a una radio nueva'), findsOneWidget);
    expect(find.text('0 de 7 hechos'), findsOneWidget);
  });
}
