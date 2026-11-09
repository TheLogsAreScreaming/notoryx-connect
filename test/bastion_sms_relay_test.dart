import 'dart:io';

import 'package:bastion/services/bastion_sms_relay.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeGateway implements BastionSmsGateway {
  bool allowed = true, broken = false;
  final sent = <(String, String)>[];
  @override
  Future<bool> hasPermission() async => allowed;
  @override
  Future<void> requestPermission() async {}
  @override
  Future<void> send(String number, String text) async {
    if (broken) throw StateError('no signal');
    sent.add((number, text));
  }
}

void main() {
  late FakeGateway gateway;
  late BastionSmsRelay relay;
  var clock = DateTime(2026, 11, 9);
  var packet = 1;
  Future<String?> msg(String text, {int from = 7, bool broadcast = false}) =>
      relay.handle(from: from, text: text, isBroadcast: broadcast, packetId: packet++);

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    gateway = FakeGateway();
    clock = DateTime(2026, 11, 9);
    relay = BastionSmsRelay(gateway: gateway, now: () => clock);
    await relay.setEnabled(true);
    await relay.setNodeAllowed(7, true);
    await relay.saveContact('Base', '+1 (704) 555-0100');
  });

  test('an allowed direct message goes to the saved number', () async {
    expect(await msg('SMS base: on our way'), contains('handed to the phone network'));
    expect(gateway.sent, [('+17045550100', 'on our way')]);
  });

  test('the relay is off by default', () async {
    final fresh = BastionSmsRelay(gateway: gateway);
    expect(await fresh.handle(from: 7, text: 'SMS base: x', isBroadcast: false, packetId: 1), isNull);
    expect(gateway.sent, isEmpty);
  });

  test('strangers, broadcasts and ordinary chat are silently ignored', () async {
    expect(await msg('SMS base: x', from: 8), isNull);
    expect(await msg('SMS base: x', broadcast: true), isNull);
    expect(await msg('hello base'), isNull);
    expect(gateway.sent, isEmpty);
  });

  test('a phone number cannot be typed over the mesh', () async {
    expect(await msg('SMS 19005551234: pay up'), contains('no contact'));
    expect(gateway.sent, isEmpty);
  });

  test('a repeated packet is sent once', () async {
    await relay.handle(from: 7, text: 'SMS base: once', isBroadcast: false, packetId: 900);
    expect(await relay.handle(from: 7, text: 'SMS base: once', isBroadcast: false, packetId: 900), isNull);
    expect(gateway.sent, hasLength(1));
  });

  test('the hourly limit holds, then resets', () async {
    for (var i = 0; i < BastionSmsRelay.maxPerHour; i++) {
      await msg('SMS base: $i');
    }
    expect(await msg('SMS base: over'), contains('limit'));
    expect(gateway.sent, hasLength(BastionSmsRelay.maxPerHour));
    clock = clock.add(const Duration(hours: 1));
    expect(await msg('SMS base: again'), contains('handed'));
  });

  test('reports long text, missing permission and send failure', () async {
    expect(await msg('SMS base: ${'x' * 161}'), contains('over 160'));
    gateway.allowed = false;
    expect(await msg('SMS base: a'), contains('not allowed'));
    gateway.allowed = true;
    gateway.broken = true;
    expect(await msg('SMS base: a'), contains('could not send'));
    expect(gateway.sent, isEmpty);
  });

  test('rejects bad contacts and survives a restart', () async {
    expect(await relay.saveContact('has space', '+15551234'), isFalse);
    expect(await relay.saveContact('ok', '12'), isFalse);
    final next = BastionSmsRelay(gateway: gateway);
    await next.load();
    expect(next.enabled, isTrue);
    expect(next.allowedNodes, {7});
    expect(next.contacts, {'base': '+17045550100'});
  });

  test('is not compiled into a normal build or Android project', () {
    expect(BastionSmsRelay.available, isFalse);
    final script = File('scripts/prepare_android.py').readAsStringSync();
    final gate = script.indexOf("if '--sms' in sys.argv");
    expect(gate, greaterThan(0));
    expect(script.indexOf('SEND_SMS'), greaterThan(gate), reason: 'the permission must only be added behind --sms');
    expect(Directory('android_overlay').listSync(recursive: true).where((f) => f.path.contains('SmsRelay')), isEmpty);
  });
}
