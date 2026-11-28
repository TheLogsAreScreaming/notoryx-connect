import 'package:bastion/services/bastion_connect_link.dart';
import 'package:bastion/services/bastion_link_intake.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a Bluetooth link with a PIN, both link forms', () {
    for (final text in [
      'meshtastic://meshtastic/connections?address=xaa:bb:cc:dd:ee:ff&pin=123456',
      'https://meshtastic.org/connections?address=xAA:BB:CC:DD:EE:FF&pin=123456',
    ]) {
      final link = ConnectLink.parse(text)!;
      expect(link.kind, ConnectLinkKind.bluetooth, reason: text);
      expect(link.address, 'AA:BB:CC:DD:EE:FF');
      expect(link.pin, '123456');
    }
  });

  test('a PIN that is not six digits, or starts with 0, is dropped', () {
    for (final pin in ['12345', '1234567', '012345', 'abcdef']) {
      final link = ConnectLink.parse(
        'meshtastic://meshtastic/connections?address=xAA:BB:CC:DD:EE:FF&pin=$pin',
      )!;
      expect(link.pin, isNull, reason: pin);
    }
  });

  test('network links with and without a port', () {
    final a = ConnectLink.parse(
      'meshtastic://meshtastic/connections?address=t192.168.1.20',
    )!;
    expect((a.kind, a.address, a.port), (ConnectLinkKind.network, '192.168.1.20', 4403));
    final b = ConnectLink.parse(
      'meshtastic://meshtastic/connections?address=t192.168.1.20:4500&pin=123456',
    )!;
    expect((b.address, b.port, b.pin), ('192.168.1.20', 4500, null));
    final c = ConnectLink.parse(
      'meshtastic://meshtastic/connections?address=t%5B2001:db8::5%5D:4403',
    )!;
    expect((c.address, c.port), ('2001:db8::5', 4403));
  });

  test('serial and disconnect links', () {
    expect(
      ConnectLink.parse('meshtastic://meshtastic/connections?address=s/dev/ttyUSB0')!.kind,
      ConnectLinkKind.serial,
    );
    expect(
      ConnectLink.parse('meshtastic://meshtastic/connections?address=n')!.kind,
      ConnectLinkKind.disconnect,
    );
  });

  test('anything else is not a connect link', () {
    for (final text in [
      'hello',
      'https://meshtastic.org/e/#CgMSAQE',
      'https://example.com/connections?address=xAA:BB:CC:DD:EE:FF',
      'meshtastic://meshtastic/connections',
      'meshtastic://meshtastic/connections?address=xAA:BB:CC',
      'meshtastic://meshtastic/connections?address=nX',
      'meshtastic://meshtastic/connections?address=qfoo',
      'meshtastic://meshtastic/connections?address=t192.168.1.20:99999',
      'meshtastic://meshtastic/settings?address=xAA:BB:CC:DD:EE:FF',
    ]) {
      expect(ConnectLink.parse(text), isNull, reason: text);
    }
  });

  test('a radio\'s own link round-trips', () {
    final text = ConnectLink.forBluetooth('aa:bb:cc:dd:ee:ff', pin: '654321');
    final link = ConnectLink.parse(text)!;
    expect((link.address, link.pin), ('AA:BB:CC:DD:EE:FF', '654321'));
  });

  test('the same link reported twice is delivered once', () async {
    var now = DateTime(2026);
    final intake = BastionLinkIntake(clock: () => now);
    final seen = <String>[];
    final sub = intake.links.listen(seen.add);
    intake.deliver('a');
    intake.deliver('a');
    now = now.add(const Duration(seconds: 6));
    intake.deliver('a');
    intake.deliver('b');
    await Future<void>.delayed(Duration.zero);
    expect(seen, ['a', 'a', 'b']);
    await sub.cancel();
    await intake.dispose();
  });
}
