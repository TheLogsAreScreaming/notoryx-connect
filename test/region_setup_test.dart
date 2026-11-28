import 'package:bastion/generated/meshtastic/config.pbenum.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/region_setup_page.dart';
import 'package:bastion/services/bastion_region_suggest.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('suggests a region from the phone\'s country', () {
    expect(
      BastionRegionSuggest.forCountry('us'),
      Config_LoRaConfig_RegionCode.US,
    );
    expect(
      BastionRegionSuggest.forCountry('DE'),
      Config_LoRaConfig_RegionCode.EU_868,
    );
    expect(
      BastionRegionSuggest.forCountry('GB'),
      Config_LoRaConfig_RegionCode.EU_868,
    );
    expect(
      BastionRegionSuggest.forCountry('AU'),
      Config_LoRaConfig_RegionCode.ANZ,
    );
    expect(
      BastionRegionSuggest.forCountry('BR'),
      Config_LoRaConfig_RegionCode.BR_902,
    );
    expect(
      BastionRegionSuggest.forCountry('JP'),
      Config_LoRaConfig_RegionCode.JP,
    );
    expect(BastionRegionSuggest.forCountry('ZZ'), isNull);
    expect(BastionRegionSuggest.forCountry(null), isNull);
  });

  testWidgets('setup preselects the suggestion and saving needs a radio', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RegionSetupPage(radio: radio, countryCode: 'DE'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('EU 868'), findsOneWidget);
    expect(find.textContaining('Suggested for your phone'), findsOneWidget);
    final save = tester.widget<FilledButton>(
      find.byKey(const ValueKey('region-setup-save')),
    );
    expect(save.onPressed, isNull, reason: 'no radio to write to');
  });
}
