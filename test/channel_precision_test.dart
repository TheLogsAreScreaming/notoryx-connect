import 'package:bastion/generated/meshtastic/channel.pb.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/radio_settings_page.dart';
import 'package:bastion/services/bastion_channel_precision.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ChannelRadio extends MeshtasticRadioCoordinator {
  final channels = [
    Channel(index: 0, role: Channel_Role.PRIMARY, settings: ChannelSettings(name: 'Base', psk: [1])),
    for (var i = 1; i < 8; i++) Channel(index: i, role: Channel_Role.DISABLED),
  ];
  int writes = 0;
  @override bool get canAdminister => true;
  @override int? get localNodeNum => 42;
  @override Future<Channel> readChannel(int index) async => channels[index].deepCopy();
  @override Future<void> writeChannel(Channel channel) async { writes++; channels[channel.index] = channel.deepCopy(); }
  @override Future<void> waitForSettingsRadio(int node) async {}
}

void main() {
  test('choices run from no position to exact, coarsest first', () {
    final keys = BastionChannelPrecision.choices.keys.toList();
    expect(keys.first, BastionChannelPrecision.none);
    expect(keys.last, BastionChannelPrecision.exact);
    final metres = [for (final e in BastionChannelPrecision.choices.entries) if (e.value > 0) e.value];
    expect(metres, [...metres]..sort((a, b) => b.compareTo(a)));
  });

  testWidgets('a channel without the setting says so, and a choice is written and verified', (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = ChannelRadio();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RadioSettingsPage(radio: radio),
    ));
    await tester.tap(find.text('Channels'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Base'));
    await tester.pumpAndSettle();
    expect(find.text('Not set: the firmware decides'), findsOneWidget);
    await tester.tap(find.text('Not set: the firmware decides'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Don't share position").last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(radio.writes, 1);
    expect(radio.channels[0].settings.hasModuleSettings(), isTrue);
    expect(radio.channels[0].settings.moduleSettings.positionPrecision, BastionChannelPrecision.none);
    expect(radio.channels[0].settings.name, 'Base', reason: 'other settings untouched');
  });
}
