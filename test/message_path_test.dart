import 'package:bastion/generated/meshtastic/mesh.pb.dart';
import 'package:bastion/generated/meshtastic/portnums.pbenum.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/meshtastic_text_codec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

MeshPacket _packet({int hopStart = 0, int hopLimit = 0, int rssi = 0, int relay = 0}) => MeshPacket(
      from: 0x11223344,
      to: 0xffffffff,
      id: 77,
      decoded: Data(portnum: PortNum.TEXT_MESSAGE_APP, payload: utf8.encode('hello')),
      hopStart: hopStart,
      hopLimit: hopLimit,
      rxRssi: rssi,
      relayNode: relay,
    );

void main() {
  test('hops, signal and last relay are read from the packet', () {
    final m = MeshtasticTextCodec.decodeMeshPacket(
        _packet(hopStart: 3, hopLimit: 1, rssi: -104, relay: 0xAB).writeToBuffer())!;
    expect(m.text, 'hello');
    expect(m.hops, 2);
    expect(m.rxRssi, -104);
    expect(m.relayNode, 0xAB);
  });

  test('a direct packet has zero hops', () {
    final m = MeshtasticTextCodec.decodeMeshPacket(_packet(hopStart: 3, hopLimit: 3).writeToBuffer())!;
    expect(m.hops, 0);
  });

  test('old firmware without hop_start reports no hop count', () {
    final m = MeshtasticTextCodec.decodeMeshPacket(_packet(hopLimit: 2).writeToBuffer())!;
    expect(m.hops, isNull);
    expect(m.rxRssi, isNull);
    expect(m.relayNode, isNull);
  });

  test('hop data survives saving and loading', () {
    final m = BastionChatMessage(
      packetId: 1, from: 2, to: 3, channel: 0, text: 'x', timestamp: DateTime.utc(2026),
      direction: BastionMessageDirection.incoming, deliveryState: BastionDeliveryState.received,
      hops: 2, rxRssi: -99, relayNode: 0x1f,
    );
    final back = BastionChatMessage.fromJson(jsonDecode(jsonEncode(m.toJson())) as Map<String, Object?>);
    expect((back.hops, back.rxRssi, back.relayNode), (2, -99, 0x1f));
    final old = BastionChatMessage.fromJson({...m.toJson()}..remove('hops')..remove('rxRssi')..remove('relay'));
    expect(old.hops, isNull, reason: 'messages saved before this change still load');
    expect(m.copyWith(deliveryState: BastionDeliveryState.received).hops, 2);
  });
}
