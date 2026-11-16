import 'bastion_chat_marks.dart';
import 'bastion_chat_message.dart';
import 'meshtastic_text_codec.dart';

/// One chat: a channel everyone on it can read, or a direct chat with one node.
class BastionConversation {
  const BastionConversation.channel(this.channel) : node = null;
  const BastionConversation.direct(int this.node, {this.channel = 0});

  /// The channel slot. For a direct chat, the slot its messages travel on.
  final int channel;

  /// The other node in a direct chat; null for a channel.
  final int? node;

  bool get isChannel => node == null;

  /// Matches [BastionChatMarks.conversationOf] and the draft keys.
  String get key => isChannel ? 'ch$channel' : 'dm$node';

  /// Where a message typed here is sent.
  int get destination => node ?? MeshtasticTextCodec.broadcastNode;

  bool includes(BastionChatMessage m) => BastionChatMarks.conversationOf(m) == key;

  /// The chat a message belongs to.
  static BastionConversation of(BastionChatMessage m) => m.isBroadcast
      ? BastionConversation.channel(m.channel)
      : BastionConversation.direct(
          m.direction == BastionMessageDirection.outgoing ? m.to : m.from,
          channel: m.channel,
        );

  @override
  bool operator ==(Object other) => other is BastionConversation && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// A row in the Chats list.
class BastionConversationSummary {
  const BastionConversationSummary(this.conversation, this.last, this.unread);

  final BastionConversation conversation;

  /// The newest message that isn't a reaction, or null for an empty channel.
  final BastionChatMessage? last;
  final int unread;
}

abstract final class BastionConversations {
  /// One row per active channel slot (in slot order, even with no messages
  /// yet, plus any slot that only appears in history), then one row per
  /// direct chat, newest first.
  static ({List<BastionConversationSummary> channels, List<BastionConversationSummary> direct}) build({
    required List<BastionChatMessage> messages,
    required List<int> channelSlots,
    required int Function(String conversation) unread,
  }) {
    final newest = <String, BastionChatMessage>{};
    final direct = <String, BastionConversation>{};
    for (final m in messages) {
      if (m.isReaction) continue;
      final c = BastionConversation.of(m);
      final seen = newest[c.key];
      if (seen == null || !m.timestamp.isBefore(seen.timestamp)) {
        newest[c.key] = m;
        if (!c.isChannel) direct[c.key] = c;
      }
    }
    final slots = <int>{...channelSlots};
    for (final m in newest.values) {
      if (m.isBroadcast) slots.add(m.channel);
    }
    // With no radio and no history there is still the primary channel to
    // write in; messages wait in the queue until a radio connects.
    if (slots.isEmpty) slots.add(0);
    final channels = [
      for (final slot in (slots.toList()..sort()))
        BastionConversationSummary(
          BastionConversation.channel(slot),
          newest['ch$slot'],
          unread('ch$slot'),
        ),
    ];
    final chats = [
      for (final c in direct.values) BastionConversationSummary(c, newest[c.key], unread(c.key)),
    ]..sort((a, b) => b.last!.timestamp.compareTo(a.last!.timestamp));
    return (channels: channels, direct: chats);
  }
}
