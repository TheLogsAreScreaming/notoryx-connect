import 'dart:convert';

import 'package:bastion/main.dart';
import 'package:bastion/services/bastion_chat_marks.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

BastionChatMessage _msg(int id, DateTime at, {String text = 'hi', bool outgoing = false, int from = 5}) =>
    BastionChatMessage(
      packetId: id,
      from: outgoing ? 1 : from,
      to: 0xffffffff,
      channel: 0,
      text: text,
      timestamp: at,
      direction: outgoing ? BastionMessageDirection.outgoing : BastionMessageDirection.incoming,
      deliveryState: outgoing ? BastionDeliveryState.sent : BastionDeliveryState.received,
    );

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('day labels', () {
    final now = DateTime(2026, 11, 6, 9);
    test('today, yesterday, weekday, date, year', () {
      expect(BastionChatDays.label(DateTime(2026, 11, 6, 0, 1), now), 'Today');
      expect(BastionChatDays.label(DateTime(2026, 11, 5, 23, 59), now), 'Yesterday');
      expect(BastionChatDays.label(DateTime(2026, 11, 2, 12), now), 'Monday');
      expect(BastionChatDays.label(DateTime(2026, 10, 30, 12), now), 'Oct 30');
      expect(BastionChatDays.label(DateTime(2025, 12, 31, 12), now), 'Dec 31, 2025');
    });
  });

  group('mentions', () {
    test('matches whole names, any case', () {
      expect(BastionMentions.mentions('hey @Ridge are you up', ['Ridge Runner', 'RDG']), isFalse);
      expect(BastionMentions.mentions('hey @ridge runner, copy?', ['Ridge Runner', 'RDG']), isTrue);
      expect(BastionMentions.mentions('@RDG', ['Ridge Runner', 'RDG']), isTrue);
      expect(BastionMentions.mentions('@rdgx check', ['Ridge Runner', 'RDG']), isFalse);
      expect(BastionMentions.mentions('@rdgx and @rdg!', [null, 'RDG']), isTrue);
      expect(BastionMentions.mentions('email rdg@host', ['RDG']), isFalse);
      expect(BastionMentions.mentions('@ anyone', ['', null]), isFalse);
    });
  });

  group('marks store', () {
    test('pins toggle, persist and cap', () async {
      final marks = BastionChatMarks();
      await marks.load();
      final a = _msg(1, DateTime(2026, 11, 6));
      expect(await marks.togglePin(a), isNull);
      expect(marks.isPinned(a), isTrue);
      final again = BastionChatMarks();
      await again.load();
      expect(again.pinnedIn([a]), [a]);
      expect(await again.togglePin(a), isNull);
      expect(again.isPinned(a), isFalse);
      for (var i = 0; i < BastionChatMarks.maxPins; i++) {
        expect(await again.togglePin(_msg(100 + i, DateTime(2026))), isNull);
      }
      expect(await again.togglePin(a), contains('up to'));
    });

    test('unread counts only incoming text after last read', () async {
      final marks = BastionChatMarks();
      await marks.load();
      final t = DateTime(2026, 11, 6, 8);
      final list = [
        _msg(1, t.subtract(const Duration(hours: 1))),
        _msg(2, t.add(const Duration(minutes: 5))),
        _msg(3, t.add(const Duration(minutes: 6)), outgoing: true),
      ];
      expect(marks.unreadIn(list), 0, reason: 'never opened counts as read');
      await marks.markRead(t);
      expect(marks.unreadIn(list), 1);
      await marks.markRead(t.subtract(const Duration(days: 1)));
      expect(marks.lastRead, t, reason: 'the marker never moves back');
    });

    test('unreadable storage is never overwritten', () async {
      final store = _UnreadableStore();
      SharedPreferencesAsyncPlatform.instance = store;
      final marks = BastionChatMarks();
      await marks.load();
      expect(await marks.togglePin(_msg(1, DateTime(2026))), contains('could not be read'));
      await marks.markRead(DateTime(2026));
      expect(store.writes, 0);
    });
  });

  testWidgets('Chats shows pins, day dividers and the new-messages line', (tester) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateTime.now();
    final seen = now.subtract(const Duration(minutes: 30));
    final old = _msg(1, now.subtract(const Duration(days: 1)), text: 'yesterday note');
    // Keep the fresh message inside today even just after midnight, or the
    // "Today" divider can't appear.
    final sinceMidnight = now.difference(DateTime(now.year, now.month, now.day));
    final gap = sinceMidnight < const Duration(minutes: 10) ? sinceMidnight ~/ 2 : const Duration(minutes: 5);
    final fresh = _msg(2, now.subtract(gap), text: 'fresh news');
    final prefs = SharedPreferencesAsync();
    await prefs.setString('bastion.comms.archive.v1', jsonEncode({
      'messages': [old.toJson(), fresh.toJson()],
      'pending': [],
    }));
    await prefs.setString(BastionChatMarks.key, jsonEncode({
      'pins': [BastionChatMarks.idOf(old)],
      'lastRead': seen.toUtc().toIso8601String(),
    }));
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    expect(find.text('1'), findsWidgets, reason: 'unread badge on Chats');
    await tester.tap(find.byIcon(Icons.chat_bubble_outline).last);
    await tester.pumpAndSettle();
    expect(find.text('PINNED'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsWidgets);
    expect(find.bySemanticsLabel('New messages above'), findsOneWidget);
    expect(find.text('yesterday note'), findsNWidgets(2), reason: 'pinned copy and timeline');

    // Unpin from the pinned section.
    await tester.tap(find.byTooltip('Unpin'));
    await tester.pumpAndSettle();
    expect(find.text('PINNED'), findsNothing);

    // Pin from the long-press sheet.
    await tester.longPress(find.text('fresh news'));
    await tester.pumpAndSettle();
    expect(find.text('Copy text'), findsOneWidget);
    await tester.tap(find.text('Pin'));
    await tester.pumpAndSettle();
    expect(find.text('PINNED'), findsOneWidget);
    expect(find.byIcon(Icons.push_pin), findsNWidgets(2), reason: 'pinned section and pin mark on the card');
  });

  testWidgets('@ button inserts a mention at the cursor', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BastionApp());
    await tester.tap(find.byIcon(Icons.chat_bubble_outline).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Mention a node'));
    await tester.pumpAndSettle();
    expect(find.text('No nodes heard yet to mention.'), findsOneWidget);
  });
}

final class _UnreadableStore extends InMemorySharedPreferencesAsync {
  _UnreadableStore() : super.empty();
  int writes = 0;
  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) async {
    if (key == BastionChatMarks.key) throw StateError('read failed');
    return super.getString(key, options);
  }

  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) async {
    if (key == BastionChatMarks.key) writes++;
    return super.setString(key, value, options);
  }
}
