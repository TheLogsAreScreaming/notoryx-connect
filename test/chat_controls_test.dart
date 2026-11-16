import 'package:bastion/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

Future<void> openChats(WidgetTester tester) async {
  await tester.pumpWidget(const BastionApp());
  await tester.tap(find.byIcon(Icons.chat_bubble_outline).last);
  await tester.pumpAndSettle();
}

Future<void> openPrimary(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('conversation-ch0')));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  testWidgets('a message typed in a chat shows there and in Chats search', (tester) async {
    await openChats(tester);
    await openPrimary(tester);
    await tester.enterText(find.byKey(const ValueKey('chat-composer')), 'field check alpha');
    await tester.tap(find.byKey(const ValueKey('chat-send')));
    await tester.pumpAndSettle();
    expect(find.text('field check alpha'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('You: field check alpha'), findsOneWidget, reason: 'the row shows the latest message');
    await tester.tap(find.byKey(const ValueKey('chats-search')));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Search message history'), 'alpha');
    await tester.pumpAndSettle();
    expect(find.text('field check alpha'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Search message history'), 'unmatched');
    await tester.pumpAndSettle();
    expect(find.text('No messages match your search.'), findsOneWidget);
  });

  testWidgets('a message scheduled in a chat is listed there and can be cancelled', (tester) async {
    await openChats(tester);
    await openPrimary(tester);
    await tester.enterText(find.byKey(const ValueKey('chat-composer')), 'leaving camp');
    await tester.tap(find.byKey(const ValueKey('chat-schedule')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('In 1 hour'));
    await tester.pumpAndSettle();
    expect(find.text('leaving camp'), findsOneWidget);
    await tester.tap(find.byTooltip('Cancel scheduled message'));
    await tester.pumpAndSettle();
    expect(find.text('leaving camp'), findsNothing);
  });

  testWidgets('send later with an empty message box explains what to do', (tester) async {
    await openChats(tester);
    await openPrimary(tester);
    await tester.tap(find.byKey(const ValueKey('chat-schedule')));
    await tester.pump();
    expect(find.text('Type a message first, then choose when to send it.'), findsOneWidget);
  });

  testWidgets('Chats warns when message history cannot be read', (tester) async {
    SharedPreferencesAsyncPlatform.instance = _UnreadableStore();
    await openChats(tester);
    expect(find.text('Message storage problem'), findsOneWidget);
    expect(find.textContaining('stored history is not overwritten'), findsOneWidget);
  });
}

final class _UnreadableStore extends InMemorySharedPreferencesAsync {
  _UnreadableStore() : super.empty();
  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) async {
    if (key == 'bastion.comms.archive.v1') throw StateError('read failed');
    return super.getString(key, options);
  }
}
