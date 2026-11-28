import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:bastion/services/bastion_pinned_conversations.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  test('starts empty', () {
    final pins = BastionPinnedConversations();
    expect(pins.isPinned('ch0'), isFalse);
    expect(pins.isPinned('dm12345678'), isFalse);
  });

  test('pin persists and is reflected', () async {
    final pins = BastionPinnedConversations();
    await pins.pin('ch0');
    expect(pins.isPinned('ch0'), isTrue);
    expect(pins.isPinned('ch1'), isFalse);
  });

  test('unpin removes the key', () async {
    final pins = BastionPinnedConversations();
    await pins.pin('dm99');
    await pins.unpin('dm99');
    expect(pins.isPinned('dm99'), isFalse);
  });

  test('pin notifies listeners', () async {
    final pins = BastionPinnedConversations();
    int calls = 0;
    pins.addListener(() => calls++);
    await pins.pin('ch0');
    expect(calls, 1);
    await pins.pin('ch0'); // already pinned, no change
    expect(calls, 1);
  });

  test('load restores saved state', () async {
    final a = BastionPinnedConversations();
    await a.pin('ch2');
    await a.pin('dm42');

    final b = BastionPinnedConversations();
    await b.load();
    expect(b.isPinned('ch2'), isTrue);
    expect(b.isPinned('dm42'), isTrue);
    expect(b.isPinned('ch0'), isFalse);
  });
}
