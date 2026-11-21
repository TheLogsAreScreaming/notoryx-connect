import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/main.dart';
import 'support/shell_nav.dart';

void main() {
  testWidgets('NOTORYX Connect has five tabs, with Tools and Settings under More', (tester) async {
    await tester.pumpWidget(const BastionApp());
    expect(find.text('NOTORYX'), findsOneWidget);
    expect(find.text('CONNECT'), findsOneWidget);
    // HOME opens first, with the trip, check-ins and SOS.
    expect(find.text('No radio connected'), findsOneWidget);
    expect(find.text('Plan your trip'), findsOneWidget);
    expect(find.text("Check in: I'm OK"), findsOneWidget);
    expect(find.text('Hold for SOS'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.hub_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Nodes'), findsWidgets);
    expect(find.text('Scan for radios'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chat_bubble_outline).last);
    await tester.pumpAndSettle();
    expect(find.text('Chats'), findsWidgets);
    expect(find.text('Primary channel'), findsOneWidget);
    expect(find.text('Manage channels'), findsOneWidget);
    expect(find.text('Queued'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Bot mode'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bot mode'), findsOneWidget);

    await openTools(tester);
    expect(find.text('Tools'), findsWidgets);
    expect(find.text('Connection doctor'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Deployment checklist'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Deployment checklist'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Battery runtime'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Battery runtime'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Bluetooth signal guide'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Bluetooth signal guide'), findsOneWidget);

    await openSettings(tester);
    await tester.scrollUntilVisible(
      find.text('Change radio settings'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Change radio settings'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Low-power field mode'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Low-power field mode'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Trademark & compatibility'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('NOTORYX Connect'), findsOneWidget);
    expect(find.textContaining('Bastion'), findsNothing);
  });
}
