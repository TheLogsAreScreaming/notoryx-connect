import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bastion/generated/meshtastic/mesh.pb.dart' as pb;
import 'package:bastion/generated/meshtastic/portnums.pbenum.dart';
import 'package:bastion/generated/meshtastic/storeforward.pb.dart';
import 'package:bastion/services/bastion_message_archive.dart';
import 'package:bastion/services/meshtastic_connection_controller.dart';
import 'package:bastion/services/meshtastic_messaging_service.dart';
import 'package:bastion/services/meshtastic_radio_session.dart';
import 'package:bastion/services/meshtastic_radio_transport.dart';
import 'package:bastion/services/meshtastic_text_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _Transport implements MeshtasticRadioTransport {
  final controller = StreamController<Uint8List>.broadcast();
  @override
  Stream<Uint8List> get fromRadio => controller.stream;
  @override
  bool get isConnected => true;
  @override
  Future<void> connect() async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> sendToRadio(Uint8List envelope) async {}
}

Uint8List _live(int id, String text) => pb.FromRadio(
      packet: pb.MeshPacket(
        from: 0x55,
        to: 0x1,
        id: id,
        rxTime: 1700000000,
        decoded: pb.Data(portnum: PortNum.TEXT_MESSAGE_APP, payload: utf8.encode(text)),
      ),
    ).writeToBuffer();

Uint8List _replay(int originalId, String text) => pb.FromRadio(
      packet: pb.MeshPacket(
        from: 0x55,
        to: 0x1,
        id: 999,
        rxTime: 1700000000,
        decoded: pb.Data(
          portnum: PortNum.STORE_FORWARD_APP,
          payload: StoreAndForward(
            rr: StoreAndForward_RequestResponse.ROUTER_TEXT_DIRECT,
            text: utf8.encode(text),
            originalId: originalId,
          ).writeToBuffer(),
        ),
      ),
    ).writeToBuffer();

void main() {
  late _Transport transport;
  late MeshtasticRadioSession session;
  late MeshtasticConnectionController connection;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    transport = _Transport();
    connection = MeshtasticConnectionController();
    session = MeshtasticRadioSession(transport: transport, connection: connection);
    await session.connect(deviceName: 'Field Radio');
  });

  Future<MeshtasticMessagingService> make() async {
    final m = MeshtasticMessagingService(
      session: session,
      connection: connection,
      archive: BastionMessageArchive(radio: 0x1),
    )..localNodeNum = 0x1;
    await m.start();
    return m;
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  test('a replay is kept as history with when this phone got it', () async {
    final m = await make();
    transport.controller.add(_replay(4242, 'SOS at the ridge'));
    await settle();
    final saved = m.messages.single;
    expect(saved.replayed, isTrue);
    expect(saved.receivedAt, isNotNull);
    expect(saved.timestamp, DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000));
    await m.dispose();
    final reopened = await make();
    expect(reopened.messages.single.replayed, isTrue, reason: 'survives a restart');
    expect(reopened.messages.single.receivedAt, isNotNull);
  });

  test('live then replayed copy stays one live message', () async {
    final m = await make();
    transport.controller.add(_live(4242, 'meet at the gate'));
    await settle();
    transport.controller.add(_replay(4242, 'meet at the gate'));
    await settle();
    expect(m.messages.single.replayed, isFalse);
  });

  test('a replay after a restart does not duplicate saved history', () async {
    final first = await make();
    transport.controller.add(_live(4242, 'meet at the gate'));
    await settle();
    await first.dispose();
    final reopened = await make();
    final events = <MeshtasticTextMessage>[];
    reopened.incoming.listen(events.add);
    transport.controller.add(_replay(4242, 'meet at the gate'));
    await settle();
    expect(reopened.messages, hasLength(1));
    expect(events, isEmpty, reason: 'nothing to alert on');
  });
}
