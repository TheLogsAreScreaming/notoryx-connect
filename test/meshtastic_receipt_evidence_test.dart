import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bastion/generated/meshtastic/mesh.pb.dart' as pb;
import 'package:bastion/generated/meshtastic/portnums.pbenum.dart';
import 'package:bastion/services/meshtastic_connection_controller.dart';
import 'package:bastion/services/meshtastic_messaging_service.dart';
import 'package:bastion/services/meshtastic_radio_session.dart';
import 'package:bastion/services/meshtastic_radio_transport.dart';
import 'package:bastion/services/meshtastic_text_codec.dart';
import 'package:flutter_test/flutter_test.dart';

pb.MeshPacket _ack(int from, int requestId,
        {pb.MeshPacket_AckProofStatus? proof, int error = 0}) =>
    pb.MeshPacket(
      from: from,
      to: 0x1,
      id: 5,
      decoded: pb.Data(
        portnum: PortNum.ROUTING_APP,
        requestId: requestId,
        payload: pb.Routing(errorReason: pb.Routing_Error.valueOf(error)).writeToBuffer(),
      ),
    )..ackProofStatus = proof ?? pb.MeshPacket_AckProofStatus.ACK_PROOF_ABSENT;

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

void main() {
  group('codec', () {
    test('reads each firmware verdict on a receipt', () {
      for (final (status, expected) in [
        (pb.MeshPacket_AckProofStatus.ACK_PROOF_VALID, BastionAckProof.proven),
        (pb.MeshPacket_AckProofStatus.ACK_PROOF_INVALID, BastionAckProof.forged),
        (pb.MeshPacket_AckProofStatus.ACK_PROOF_NO_KEY, BastionAckProof.noKey),
        (pb.MeshPacket_AckProofStatus.ACK_PROOF_ABSENT, BastionAckProof.unproven),
      ]) {
        final ack = MeshtasticTextCodec.decodeRoutingAck(
            _ack(0x55, 42, proof: status).writeToBuffer())!;
        expect(ack.proof, expected, reason: '$status');
      }
    });

    test('older firmware without the field reads as not proven', () {
      final bytes = _ack(0x55, 42).writeToBuffer();
      expect(MeshtasticTextCodec.decodeRoutingAck(bytes)!.proof, BastionAckProof.unproven);
    });

    test('a value from newer firmware reads as not proven', () {
      // Field 23 = 9, a value this build doesn't know.
      final bytes = Uint8List.fromList([..._ack(0x55, 42).writeToBuffer(), 0xb8, 0x01, 0x09]);
      expect(MeshtasticTextCodec.decodeRoutingAck(bytes)!.proof, BastionAckProof.unproven);
    });

    test('reads signed and PKI flags on a text message', () {
      final p = pb.MeshPacket(
        from: 0x55,
        to: 0x1,
        id: 9,
        pkiEncrypted: true,
        xeddsaSigned: true,
        decoded: pb.Data(portnum: PortNum.TEXT_MESSAGE_APP, payload: utf8.encode('hi')),
      );
      final m = MeshtasticTextCodec.decodeMeshPacket(p.writeToBuffer())!;
      expect(m.pkiEncrypted, isTrue);
      expect(m.signed, isTrue);
      final plain = MeshtasticTextCodec.decodeMeshPacket((p
            ..pkiEncrypted = false
            ..xeddsaSigned = false)
          .writeToBuffer())!;
      expect(plain.pkiEncrypted, isFalse);
      expect(plain.signed, isFalse);
    });
  });

  group('messaging', () {
    late _Transport transport;
    late MeshtasticConnectionController connection;
    late MeshtasticRadioSession session;
    late MeshtasticMessagingService messaging;

    setUp(() async {
      transport = _Transport();
      connection = MeshtasticConnectionController();
      session = MeshtasticRadioSession(transport: transport, connection: connection);
      await session.connect(deviceName: 'Field Radio');
      connection.markReady();
      messaging = MeshtasticMessagingService(
        session: session,
        connection: connection,
        packetIdFactory: () => 42,
      )..localNodeNum = 0x1;
      await messaging.start();
    });

    Future<void> receive(pb.MeshPacket p) async {
      transport.controller.add(pb.FromRadio(packet: p).writeToBuffer());
      await Future<void>.delayed(Duration.zero);
    }

    test('a proven receipt is delivered and proven', () async {
      await messaging.sendText(text: 'hi', destination: 0x55);
      await receive(_ack(0x55, 42, proof: pb.MeshPacket_AckProofStatus.ACK_PROOF_VALID));
      final m = messaging.messages.single;
      expect(m.deliveryState, BastionDeliveryState.delivered);
      expect(m.ackProof, BastionAckProof.proven);
    });

    test('a forged receipt is not a delivery; a real one still counts', () async {
      await messaging.sendText(text: 'hi', destination: 0x55);
      await receive(_ack(0x55, 42, proof: pb.MeshPacket_AckProofStatus.ACK_PROOF_INVALID));
      expect(messaging.messages.single.deliveryState, BastionDeliveryState.sent);
      expect(messaging.messages.single.ackProof, BastionAckProof.forged);
      await receive(_ack(0x55, 42, proof: pb.MeshPacket_AckProofStatus.ACK_PROOF_VALID));
      expect(messaging.messages.single.deliveryState, BastionDeliveryState.delivered);
      expect(messaging.messages.single.ackProof, BastionAckProof.proven);
    });

    test('an unproven receipt is delivered but says so', () async {
      await messaging.sendText(text: 'hi', destination: 0x55);
      await receive(_ack(0x55, 42));
      expect(messaging.messages.single.deliveryState, BastionDeliveryState.delivered);
      expect(messaging.messages.single.ackProof, BastionAckProof.unproven);
    });

    test('a receipt from the wrong node is ignored', () async {
      await messaging.sendText(text: 'hi', destination: 0x55);
      await receive(_ack(0x66, 42, proof: pb.MeshPacket_AckProofStatus.ACK_PROOF_VALID));
      expect(messaging.messages.single.deliveryState, BastionDeliveryState.sent);
      expect(messaging.messages.single.ackProof, isNull);
    });

    test('a broadcast never gets a recipient receipt', () async {
      await messaging.sendText(text: 'all', destination: MeshtasticTextCodec.broadcastNode);
      await receive(_ack(0x55, 42, proof: pb.MeshPacket_AckProofStatus.ACK_PROOF_VALID));
      expect(messaging.messages.single.deliveryState, BastionDeliveryState.sent);
      expect(messaging.messages.single.ackProof, isNull);
    });

    test('verdicts and flags survive saving', () async {
      await messaging.sendText(text: 'hi', destination: 0x55);
      await receive(_ack(0x55, 42, proof: pb.MeshPacket_AckProofStatus.ACK_PROOF_NO_KEY));
      await receive(pb.MeshPacket(
        from: 0x55, to: 0x1, id: 77, xeddsaSigned: true, pkiEncrypted: true,
        decoded: pb.Data(portnum: PortNum.TEXT_MESSAGE_APP, payload: utf8.encode('yo')),
      ));
      final restored = [
        for (final m in messaging.messages) BastionChatMessage.fromJson(m.toJson()),
      ];
      expect(restored.first.ackProof, BastionAckProof.noKey);
      expect(restored.last.signed, isTrue);
      expect(restored.last.pkiEncrypted, isTrue);
      final future = {...restored.first.toJson(), 'ackProof': 'somethingNew'};
      expect(BastionChatMessage.fromJson(future).ackProof, BastionAckProof.unproven);
    });
  });
}
