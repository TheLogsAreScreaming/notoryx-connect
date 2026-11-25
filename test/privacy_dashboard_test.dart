import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/privacy_dashboard_page.dart';
import 'package:bastion/services/bastion_preferences.dart';
import 'package:bastion/services/bastion_privacy.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  test('lists every route, with switchable items marked', () {
    final items = privacyItems(shareLocation: true, mqttProxy: false, linkPreviews: false, moderation: true, tak: false);
    expect(items.where((i) => i.state == PrivacyState.on).map((i) => i.thing),
        [PrivacyThing.moderation, PrivacyThing.location]);
    expect(items.map((i) => i.route).toSet(), PrivacyRoute.values.toSet());
    expect(items.any((i) => i.thing == PrivacyThing.sms), isFalse);
    expect(items.firstWhere((i) => i.thing == PrivacyThing.mapTiles).state, PrivacyState.whenAsked);
    expect(items.firstWhere((i) => i.thing == PrivacyThing.tak).canSwitch, isFalse);
    expect(items.firstWhere((i) => i.thing == PrivacyThing.mqttProxy).canSwitch, isTrue);
  });

  test('the SMS relay shows only in builds that have it', () {
    final items = privacyItems(
        shareLocation: false, mqttProxy: false, linkPreviews: false, moderation: false, tak: false, sms: true);
    expect(items.last.thing, PrivacyThing.sms);
    expect(items.last.state, PrivacyState.on);
  });

  testWidgets('shows what is on, and link previews can be switched here', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await BastionPreferences.instance.update(previews: false, proxyMqtt: false);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PrivacyDashboardPage(radio: radio),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Over the internet'), findsOneWidget);
    expect(find.text('Over the mesh'), findsOneWidget);
    expect(find.textContaining('Open-Meteo'), findsOneWidget);
    final before = tester.widget<Text>(find.byKey(const ValueKey('privacy-summary'))).data;

    await tester.tap(find.byKey(const ValueKey('privacy-linkPreviews')));
    await tester.pumpAndSettle();
    expect(BastionPreferences.instance.linkPreviews, isTrue);
    expect(tester.widget<Text>(find.byKey(const ValueKey('privacy-summary'))).data, isNot(before));
    expect(
      tester.widget<SwitchListTile>(find.byKey(const ValueKey('privacy-linkPreviews'))).value,
      isTrue,
    );
    await BastionPreferences.instance.update(previews: false);

    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
