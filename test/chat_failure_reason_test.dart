import 'dart:convert';

import 'package:bastion/main.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

BastionChatMessage _dm(int id, String text, BastionDeliveryState state, {int? failure}) => BastionChatMessage(
      packetId: id,
      from: 1,
      to: 0x55,
      channel: 0,
      text: text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
      direction: BastionMessageDirection.outgoing,
      deliveryState: state,
      failureCode: failure,
    );

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  testWidgets('a failed direct message says why and what to do', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await SharedPreferencesAsync().setString('bastion.comms.archive.v1', jsonEncode({
      'messages': [
        _dm(7, 'no key here', BastionDeliveryState.failed, failure: 39).toJson(),
        _dm(8, 'old failure', BastionDeliveryState.failed).toJson(),
      ],
      'pending': [],
    }));
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chat_bubble_outline).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('conversation-dm85')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('chat-failure-7')), findsOneWidget);
    expect(find.textContaining("doesn't have their key yet"), findsOneWidget);
    // Saved before this build: failed, with no reason to show.
    expect(find.byKey(const ValueKey('chat-failure-8')), findsNothing);
    expect(find.text('Not delivered'), findsNWidgets(2));
  });
}
