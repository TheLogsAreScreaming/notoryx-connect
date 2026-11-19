import 'package:bastion/generated/meshtastic/channel.pb.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/radio_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'channel_precision_test.dart' show ChannelRadio;

Widget app(Widget home) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Future<void> saveAndConfirm(WidgetTester tester) async {
  await tester.tap(find.text('SAVE'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {});

  testWidgets('a new channel starts switched on with a private key, so it only needs a name', (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final radio = ChannelRadio();
    addTearDown(radio.dispose);
    await tester.pumpWidget(app(ChannelEditorPage(radio: radio, index: 1, startNew: true)));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.byKey(const ValueKey('channel-use'))).value, isTrue);
    expect(find.text('Private'), findsOneWidget);
    expect(find.byKey(const ValueKey('privacy-new-key')), findsOneWidget, reason: 'only shown when Private is chosen');
    await tester.enterText(find.byType(TextField).first, 'Team');
    await saveAndConfirm(tester);
    final saved = radio.channels[1];
    expect(saved.role, Channel_Role.SECONDARY);
    expect(saved.settings.name, 'Team');
    expect(saved.settings.psk, hasLength(32));
  });

  testWidgets('an existing disabled slot can be switched on, and set to public', (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final radio = ChannelRadio();
    addTearDown(radio.dispose);
    await tester.pumpWidget(app(ChannelEditorPage(radio: radio, index: 2)));
    await tester.pumpAndSettle();
    expect(find.text('Off: this slot is empty.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('channel-use')));
    await tester.pumpAndSettle();
    expect(find.text('On: your radio sends and listens on this channel.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('privacy-public')));
    await tester.pumpAndSettle();
    await saveAndConfirm(tester);
    expect(radio.channels[2].role, Channel_Role.SECONDARY);
    expect(radio.channels[2].settings.psk, [1]);
  });

  testWidgets('switching on an empty slot gives it a private key, not no encryption', (tester) async {
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final radio = ChannelRadio();
    addTearDown(radio.dispose);
    await tester.pumpWidget(app(ChannelEditorPage(radio: radio, index: 2)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('channel-use')));
    await tester.pumpAndSettle();
    await saveAndConfirm(tester);
    expect(radio.channels[2].role, Channel_Role.SECONDARY);
    expect(radio.channels[2].settings.psk, hasLength(32));
  });

  testWidgets('the main channel says it is always on instead of offering a switch', (tester) async {
    final radio = ChannelRadio();
    addTearDown(radio.dispose);
    await tester.pumpWidget(app(ChannelEditorPage(radio: radio, index: 0)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('channel-use')), findsNothing);
    expect(find.text('Your main channel. It is always on.'), findsOneWidget);
  });
}
