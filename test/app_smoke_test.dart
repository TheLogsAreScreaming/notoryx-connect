import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/main.dart';

void main() {
  testWidgets('NOTORYX Connect exposes six functional field tabs', (tester) async {
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
    expect(find.text('New message'.toUpperCase()), findsOneWidget);
    expect(find.text('Channel 0 • Broadcast'), findsOneWidget);
    expect(find.text('Queued'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Bot mode'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bot mode'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.build_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Tools'), findsWidgets);
    expect(find.text('Deployment checklist'), findsOneWidget);
    expect(find.text('Battery runtime'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Bluetooth signal guide'), 250,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Bluetooth signal guide'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined).last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Radio configuration'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Radio configuration'), findsOneWidget);
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
