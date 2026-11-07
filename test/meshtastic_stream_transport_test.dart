import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bastion/services/meshtastic_ble_discovery.dart';
import 'package:bastion/services/meshtastic_stream_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stream framing', () {
    test('frames round-trip', () {
      final framed = MeshtasticStreamFramer.frame([1, 2, 3]);
      expect(framed, [0x94, 0xC3, 0, 3, 1, 2, 3]);
      expect(MeshtasticStreamFramer().add(framed), [Uint8List.fromList([1, 2, 3])]);
    });

    test('frames split across reads are joined', () {
      final f = MeshtasticStreamFramer();
      final framed = MeshtasticStreamFramer.frame(List.generate(300, (i) => i & 0xff));
      expect(f.add(framed.sublist(0, 1)), isEmpty);
      expect(f.add(framed.sublist(1, 3)), isEmpty);
      expect(f.add(framed.sublist(3, 200)), isEmpty);
      expect(f.add(framed.sublist(200)).single.length, 300);
    });

    test('log text between frames is skipped', () {
      final f = MeshtasticStreamFramer();
      final bytes = [
        ...'DEBUG boot\r\n'.codeUnits,
        ...MeshtasticStreamFramer.frame([7]),
        ...'more log'.codeUnits,
        ...MeshtasticStreamFramer.frame([8, 9]),
      ];
      expect(f.add(bytes), [Uint8List.fromList([7]), Uint8List.fromList([8, 9])]);
    });

    test('a bogus header with an impossible length resyncs', () {
      final f = MeshtasticStreamFramer();
      final bytes = [0x94, 0xC3, 0xFF, 0xFF, ...MeshtasticStreamFramer.frame([5])];
      expect(f.add(bytes), [Uint8List.fromList([5])]);
    });

    test('oversized packets are refused', () {
      expect(() => MeshtasticStreamFramer.frame(List.filled(600, 0)), throwsArgumentError);
    });
  });

  test('network radios carry their address', () {
    final d = MeshtasticBleDevice.network('192.168.1.42', port: 4403);
    expect(d.isNetwork, isTrue);
    expect(d.networkAddress, (host: '192.168.1.42', port: 4403));
    expect(MeshtasticBleDevice.network('fe80::1').networkAddress, (host: 'fe80::1', port: 4403));
    const ble = MeshtasticBleDevice(id: 'AA:BB', name: 'x', rssi: -50, advertisedServices: []);
    expect(ble.isNetwork, isFalse);
    expect(ble.networkAddress, isNull);
  });

  test('the TCP transport exchanges framed packets and reports a dropped link', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final accepted = Completer<Socket>();
    server.listen(accepted.complete);

    final transport = MeshtasticTcpTransport(host: '127.0.0.1', port: server.port);
    final received = <Uint8List>[];
    transport.fromRadio.listen(received.add);
    final lost = Completer<void>();
    transport.linkLost.listen((_) => lost.complete());
    await transport.connect();
    expect(transport.isConnected, isTrue);

    final peer = await accepted.future;
    final fromClient = <int>[];
    peer.listen(fromClient.addAll);
    await transport.sendToRadio(Uint8List.fromList([4, 5]));
    peer.add([...'log'.codeUnits, ...MeshtasticStreamFramer.frame([1, 2, 3])]);
    await peer.flush();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(fromClient, [0x94, 0xC3, 0, 2, 4, 5]);
    expect(received, [Uint8List.fromList([1, 2, 3])]);

    await peer.close();
    await lost.future.timeout(const Duration(seconds: 2));
    expect(transport.isConnected, isFalse);
  });

  test('a local disconnect does not count as a lost link', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((s) => s.listen((_) {}));
    final transport = MeshtasticTcpTransport(host: '127.0.0.1', port: server.port);
    var lost = false;
    transport.linkLost.listen((_) => lost = true);
    await transport.connect();
    await transport.disconnect();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(lost, isFalse);
  });

  test('an unreachable radio gives a clear error', () async {
    final transport = MeshtasticTcpTransport(
      host: 'radio.invalid',
      connector: (host, port, {timeout}) => Future.error(const SocketException('no route')),
    );
    await expectLater(transport.connect(), throwsA(isA<StateError>()
        .having((e) => e.message, 'message', contains('radio.invalid:4403'))));
  });
}
