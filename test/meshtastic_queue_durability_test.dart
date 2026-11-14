import 'dart:async';
import 'dart:typed_data';

import 'package:bastion/services/bastion_message_archive.dart';
import 'package:bastion/services/meshtastic_connection_controller.dart';
import 'package:bastion/services/meshtastic_messaging_service.dart';
import 'package:bastion/services/meshtastic_radio_session.dart';
import 'package:bastion/services/meshtastic_radio_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _Transport implements MeshtasticRadioTransport {
  final sent = <Uint8List>[];
  final controller = StreamController<Uint8List>.broadcast();
  bool connected = false;
  Object? failNext;
  Completer<void>? hang;

  @override
  Stream<Uint8List> get fromRadio => controller.stream;
  @override
  bool get isConnected => connected;
  @override
  Future<void> connect() async => connected = true;
  @override
  Future<void> disconnect() async => connected = false;
  @override
  Future<void> sendToRadio(Uint8List envelope) async {
    final error = failNext;
    if (error != null) {
      failNext = null;
      throw error;
    }
    if (hang != null) await hang!.future;
    sent.add(envelope);
  }
}

void main() {
  late _Transport transport;
  late MeshtasticConnectionController connection;
  late MeshtasticRadioSession session;
  late DateTime now;
  var nextId = 100;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    transport = _Transport();
    connection = MeshtasticConnectionController();
    session = MeshtasticRadioSession(transport: transport, connection: connection);
    now = DateTime(2026, 11, 14, 12);
    await session.connect(deviceName: 'Field Radio');
  });

  Future<MeshtasticMessagingService> make({Duration spacing = Duration.zero}) async {
    final service = MeshtasticMessagingService(
      session: session,
      connection: connection,
      archive: BastionMessageArchive(radio: 0x1234),
      packetIdFactory: () => nextId++,
      clock: () => now,
      spacing: spacing,
    );
    await service.start();
    return service;
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('a queued message is on disk as soon as sendText returns', () async {
    final first = await make();
    await first.sendText(text: 'saved', destination: 7);
    // The app dies here; a fresh service reads the same storage.
    final reopened = await make();
    expect(reopened.pending.single.text, 'saved');
  });

  test('a message queued over a day ago is held, not sent', () async {
    final service = await make();
    await service.sendText(text: 'on my way', destination: 7);
    now = now.add(const Duration(hours: 25));
    connection.markReady();
    await settle();
    expect(transport.sent, isEmpty);
    expect(service.held.single.text, 'on my way');
    expect(service.messages.single.deliveryState, BastionDeliveryState.held);
  });

  test('a send that throws is held, not retried by itself', () async {
    final service = await make();
    await service.sendText(text: 'maybe', destination: 7);
    transport.failNext = StateError('link dropped');
    connection.markReady();
    await settle();
    expect(transport.sent, isEmpty);
    expect(service.held, hasLength(1));
    await service.flush();
    expect(transport.sent, isEmpty);
  });

  test('one held message does not block the rest', () async {
    final service = await make();
    await service.sendText(text: 'first', destination: 7);
    await service.sendText(text: 'second', destination: 7);
    transport.failNext = StateError('link dropped');
    connection.markReady();
    await settle();
    expect(transport.sent, hasLength(1));
    expect(service.held.single.text, 'first');
    expect(service.pending, hasLength(1));
  });

  test('an app stop mid-send leaves it held after restart', () async {
    final service = await make();
    await service.sendText(text: 'in the air', destination: 7);
    transport.hang = Completer<void>();
    connection.markReady();
    await settle();
    // Killed while the radio write is still open.
    transport.hang = null;
    final reopened = await make();
    expect(reopened.held.single.text, 'in the air');
    expect(reopened.messages.single.deliveryState, BastionDeliveryState.held);
    final before = transport.sent.length;
    await reopened.flush();
    expect(transport.sent.length, before, reason: 'may already be out');
  });

  test('send now releases a held message', () async {
    final service = await make();
    await service.sendText(text: 'old', destination: 7);
    now = now.add(const Duration(days: 2));
    connection.markReady();
    await settle();
    expect(transport.sent, isEmpty);
    await service.sendHeld(service.held.single.packetId);
    expect(transport.sent, hasLength(1));
    expect(service.pending, isEmpty);
    expect(service.messages.single.deliveryState, BastionDeliveryState.sent);
  });

  test('delete removes a queued message and its chat line', () async {
    final service = await make();
    final id = await service.sendText(text: 'never mind', destination: 7);
    service.deleteQueued(id);
    connection.markReady();
    await settle();
    expect(transport.sent, isEmpty);
    expect(service.pending, isEmpty);
    expect(service.messages, isEmpty);
  });

  test('queued messages from older builds (no time) are held', () async {
    final archive = BastionMessageArchive(radio: 0x1234);
    await archive.load();
    await archive.save(messages: const [], pending: const [
      PendingTextMessage(text: 'legacy', destination: 7, channel: 0, packetId: 9),
    ]);
    final service = await make();
    connection.markReady();
    await settle();
    expect(transport.sent, isEmpty);
    expect(service.held.single.text, 'legacy');
  });

  test('a backlog drains one at a time with a pause between', () async {
    final service = await make(spacing: const Duration(milliseconds: 200));
    for (final t in ['a', 'b', 'c']) {
      await service.sendText(text: t, destination: 7);
    }
    connection.markReady();
    await settle();
    expect(transport.sent, hasLength(1));
    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(transport.sent, hasLength(3));
    expect(service.pending, isEmpty);
  });
}
