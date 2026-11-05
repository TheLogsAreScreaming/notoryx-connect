import 'bastion_chat_message.dart';

/// Keeps the newest messages of each conversation, so a busy channel can't
/// push a quiet direct-message thread out of history.
class BastionHistoryLimit {
  /// Messages kept per conversation when nothing else is chosen.
  static const standard = 500;

  /// Choices offered in Settings → Messages.
  static const choices = [500, 1000, 2000, 5000];

  /// The conversation [message] belongs to: a channel, or the other node of
  /// a direct message.
  static String conversation(BastionChatMessage message) {
    if (message.isBroadcast) return 'channel:${message.channel}';
    final other = message.direction == BastionMessageDirection.incoming
        ? message.from
        : message.to;
    return 'node:$other';
  }

  /// The newest [perConversation] messages of each conversation in
  /// [messages], in their original order.
  static List<BastionChatMessage> trim(
    List<BastionChatMessage> messages,
    int perConversation,
  ) {
    final counts = <String, int>{};
    final keep = List.filled(messages.length, false);
    for (var i = messages.length - 1; i >= 0; i--) {
      final key = conversation(messages[i]);
      final seen = counts[key] ?? 0;
      if (seen < perConversation) keep[i] = true;
      counts[key] = seen + 1;
    }
    return [
      for (var i = 0; i < messages.length; i++)
        if (keep[i]) messages[i],
    ];
  }
}
