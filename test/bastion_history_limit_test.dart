import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/bastion_history_limit.dart';
import 'package:bastion/services/bastion_message_archive.dart';
import 'package:bastion/services/meshtastic_text_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const me = 0x11;
var _id = 0;

BastionChatMessage channel(int ch) => BastionChatMessage(
      packetId: ++_id,
      from: 0x22,
      to: MeshtasticTextCodec.broadcastNode,
      channel: ch,
      text: 'c$_id',
      timestamp: DateTime.utc(2026, 11, 5).add(Duration(seconds: _id)),
      direction: BastionMessageDirection.incoming,
      deliveryState: BastionDeliveryState.received,
    );

BastionChatMessage dm(int other, {bool outgoing = false}) => BastionChatMessage(
      packetId: ++_id,
      from: outgoing ? me : other,
      to: outgoing ? other : me,
      channel: 0,
      text: 'd$_id',
      timestamp: DateTime.utc(2026, 11, 5).add(Duration(seconds: _id)),
      direction: outgoing ? BastionMessageDirection.outgoing : BastionMessageDirection.incoming,
      deliveryState: outgoing ? BastionDeliveryState.sent : BastionDeliveryState.received,
    );

void main() {
  test('a busy channel does not push out a direct thread', () {
    final early = dm(0x33);
    final messages = [early, for (var i = 0; i < 10; i++) channel(0)];
    final kept = BastionHistoryLimit.trim(messages, 3);
    expect(kept, contains(early));
    expect(kept.where((m) => m.isBroadcast), hasLength(3));
    expect(kept.where((m) => m.isBroadcast).first, messages[8]);
  });

  test('sent and received messages share one direct conversation', () {
    final messages = [dm(0x33), dm(0x33, outgoing: true), dm(0x33), dm(0x44)];
    final kept = BastionHistoryLimit.trim(messages, 2);
    expect(kept, [messages[1], messages[2], messages[3]]);
  });

  test('each channel is its own conversation and order is kept', () {
    final messages = [channel(0), channel(1), channel(0), channel(1), channel(0)];
    expect(BastionHistoryLimit.trim(messages, 2), messages.sublist(1));
  });

  test('nothing is dropped under the limit', () {
    final messages = [channel(0), dm(0x33), channel(2)];
    expect(BastionHistoryLimit.trim(messages, 500), messages);
  });

  test('the archive saves up to the chosen limit per conversation', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final prefs = SharedPreferencesAsync();
    var limit = 1000;
    final archive = BastionMessageArchive(preferences: prefs, radio: 0x11, historyLimit: () => limit);
    final messages = [for (var i = 0; i < 1200; i++) channel(0), dm(0x33)];
    await archive.save(messages: messages, pending: const []);
    var loaded = await BastionMessageArchive(preferences: prefs, radio: 0x11).load();
    expect(loaded.messages, hasLength(1001));

    limit = 500;
    await archive.save(messages: messages, pending: const []);
    loaded = await BastionMessageArchive(preferences: prefs, radio: 0x11).load();
    expect(loaded.messages, hasLength(501));
    expect(loaded.messages.last.text, messages.last.text);
  });
}
