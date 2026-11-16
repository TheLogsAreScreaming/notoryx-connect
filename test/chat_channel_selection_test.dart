import 'package:bastion/main.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class ChannelRadio extends MeshtasticRadioCoordinator {
  int? sentChannel;
  int? sentTo;
  @override
  List<({int index, int role, String name})> get channelMetadata => [
    (index: 0, role: 1, name: 'Main'),
    (index: 2, role: 2, name: 'Field'),
    (index: 3, role: 0, name: 'Disabled'),
  ];
  @override
  Future<int> sendText({required String text, int destination = 0xffffffff, int channel = 0}) async {
    sentChannel = channel;
    sentTo = destination;
    return 7;
  }
}

void main() {
  testWidgets('each active channel has its own row and sends on its own slot', (tester) async {
    final radio = ChannelRadio();
    addTearDown(radio.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BastionChatsPage(
            radio: radio,
            botMode: false,
            awayReply: '',
            onBotModeChanged: (_) {},
            onAwayReplyChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Main'), findsOneWidget);
    expect(find.text('Field'), findsOneWidget);
    expect(find.text('Disabled'), findsNothing, reason: 'unused slots are not chats');
    await tester.tap(find.byKey(const ValueKey('conversation-ch2')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('chat-composer')), 'secondary test');
    await tester.tap(find.byKey(const ValueKey('chat-send')));
    await tester.pumpAndSettle();
    expect((radio.sentChannel, radio.sentTo), (2, 0xffffffff));

    // The header switches straight to another chat.
    await tester.tap(find.byKey(const ValueKey('chat-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('chat-composer')), 'primary test');
    await tester.tap(find.byKey(const ValueKey('chat-send')));
    await tester.pumpAndSettle();
    expect(radio.sentChannel, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Manage channels opens from Chats with ways to add, join and share', (tester) async {
    final radio = ChannelRadio();
    addTearDown(radio.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BastionChatsPage(
            radio: radio,
            botMode: false,
            awayReply: '',
            onBotModeChanged: (_) {},
            onAwayReplyChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('chats-manage-channels')));
    await tester.pumpAndSettle();
    expect(find.text('Channels'), findsWidgets);
    expect(find.byKey(const ValueKey('channel-new')), findsOneWidget);
    expect(find.byKey(const ValueKey('channel-join')), findsOneWidget);
    expect(find.byKey(const ValueKey('channel-share')), findsOneWidget);
    expect(
      find.text('Connect a radio to add or edit channels.'),
      findsOneWidget,
      reason: 'this test radio is not connected, so the slots cannot be read',
    );
  });
}
