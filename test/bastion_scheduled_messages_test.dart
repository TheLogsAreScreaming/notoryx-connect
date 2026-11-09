import 'package:bastion/services/bastion_scheduled_messages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  final t0 = DateTime(2026, 11, 8, 12);
  late BastionScheduledMessages store;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    store = BastionScheduledMessages();
  });
  Future<void> add(String text, DateTime at) => store.add(text: text, destination: 7, channel: 2, dueAt: at);

  test('sends only what is due, once, and keeps the target', () async {
    await add('soon', t0);
    await add('later', t0.add(const Duration(hours: 2)));
    final sent = <String>[];
    Future<void> send(BastionScheduledMessage m) async => sent.add('${m.text}/${m.destination}/${m.channel}');
    await store.flushDue(t0, send);
    await store.flushDue(t0, send);
    expect(sent, ['soon/7/2']);
    expect(store.items.map((m) => m.text), ['later']);
  });

  test('a message over an hour late is held as missed, not sent', () async {
    await add('stale', t0);
    final now = t0.add(const Duration(hours: 1, minutes: 1));
    await store.flushDue(now, (_) async => fail('must not send'));
    expect(store.items, hasLength(1));
    expect(BastionScheduledMessages.isMissed(store.items.single, now), isTrue);
  });

  test('a failed send stays listed and is retried', () async {
    await add('retry', t0);
    await store.flushDue(t0, (_) async => throw StateError('radio'));
    expect(store.items, hasLength(1));
    await store.flushDue(t0, (_) async {});
    expect(store.items, isEmpty);
  });

  test('survives a restart, and a damaged list is ignored', () async {
    await add('kept', t0);
    final reopened = BastionScheduledMessages();
    await reopened.load();
    expect(reopened.items.single.text, 'kept');
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'bastion.scheduled_messages': 'not json'});
    final damaged = BastionScheduledMessages();
    await damaged.load();
    expect(damaged.items, isEmpty);
  });

  test('the list has a limit', () async {
    for (var i = 0; i < BastionScheduledMessages.maxItems; i++) {
      expect(await store.add(text: '$i', destination: 1, channel: 0, dueAt: t0), isTrue);
    }
    expect(await store.add(text: 'x', destination: 1, channel: 0, dueAt: t0), isFalse);
    expect(store.items.map((m) => m.id).toSet(), hasLength(BastionScheduledMessages.maxItems));
  });
}
