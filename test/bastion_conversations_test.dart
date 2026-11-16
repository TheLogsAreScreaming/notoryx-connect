import 'package:bastion/services/bastion_chat_marks.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/bastion_conversations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const me = 1;
final t0 = DateTime(2026, 11, 15, 12);

BastionChatMessage msg(
  int id, {
  int from = 7,
  int to = 0xffffffff,
  int channel = 0,
  int minutes = 0,
  bool reaction = false,
}) => BastionChatMessage(
  packetId: id,
  from: from,
  to: to,
  channel: channel,
  text: 'm$id',
  timestamp: t0.add(Duration(minutes: minutes)),
  direction: from == me ? BastionMessageDirection.outgoing : BastionMessageDirection.incoming,
  deliveryState: from == me ? BastionDeliveryState.sent : BastionDeliveryState.received,
  isReaction: reaction,
);

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('messages land in the right chat whichever way they travel', () {
    expect(BastionConversation.of(msg(1, channel: 2)).key, 'ch2');
    expect(BastionConversation.of(msg(2, from: 9, to: me)).key, 'dm9');
    expect(BastionConversation.of(msg(3, from: me, to: 9)).key, 'dm9');
    expect(const BastionConversation.direct(9).destination, 9);
    expect(const BastionConversation.channel(2).destination, 0xffffffff);
  });

  test('channels come in slot order, even when empty; direct chats newest first', () {
    final lists = BastionConversations.build(
      messages: [
        msg(1, channel: 0, minutes: 1),
        msg(2, from: 9, to: me, minutes: 5),
        msg(3, from: me, to: 8, minutes: 9),
        msg(4, channel: 5, minutes: 2),
        msg(5, from: 9, to: me, minutes: 30, reaction: true),
      ],
      channelSlots: [2, 0],
      unread: (_) => 0,
    );
    expect(
      [for (final s in lists.channels) s.conversation.key],
      ['ch0', 'ch2', 'ch5'],
      reason: 'a slot only seen in history still gets a row',
    );
    expect(lists.channels[1].last, isNull);
    expect([for (final s in lists.direct) s.conversation.key], ['dm8', 'dm9']);
    expect(lists.direct[1].last!.packetId, 2, reason: 'a reaction is not the latest message');
  });

  test('with no radio and no history the primary channel is still there to write in', () {
    final lists = BastionConversations.build(messages: const [], channelSlots: const [], unread: (_) => 0);
    expect([for (final s in lists.channels) s.conversation.key], ['ch0']);
    expect(lists.direct, isEmpty);
  });

  test('opening one chat clears only its unread count, and it is remembered', () async {
    final marks = BastionChatMarks();
    final messages = [msg(1, minutes: 1), msg(2, from: 9, to: me, minutes: 2)];
    await marks.markRead(t0);
    expect(marks.unreadIn(messages), 2);
    await marks.markConversationRead('ch0', t0.add(const Duration(minutes: 5)));
    expect(marks.unreadIn(messages, conversation: 'ch0'), 0);
    expect(marks.unreadIn(messages, conversation: 'dm9'), 1);
    expect(marks.unreadIn(messages), 1);
    final reloaded = BastionChatMarks();
    await reloaded.load();
    expect(reloaded.unreadIn(messages, conversation: 'ch0'), 0);
    expect(reloaded.unreadIn(messages, conversation: 'dm9'), 1);
  });
}
