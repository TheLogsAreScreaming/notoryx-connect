import 'dart:convert';
import 'dart:math' as math;

import 'package:bastion/services/bastion_sos_relay.dart';
import 'package:bastion/services/bastion_trip.dart';
import 'package:bastion/services/meshtastic_text_codec.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _me = 0x0a;
const _hiker = 0xb2c649cb;
final _sos = sosText(DateTime.utc(2026, 11, 20, 12), latitude: 35.6, longitude: -82.5, battery: 40);

MeshtasticTextMessage _msg(String text,
        {int from = _hiker,
        int to = MeshtasticTextCodec.broadcastNode,
        int? hopsLeft = 0,
        bool mqtt = false,
        bool replayed = false,
        int channel = 2}) =>
    MeshtasticTextMessage(
      packetId: text.hashCode & 0xffff,
      from: from,
      to: to,
      channel: channel,
      text: text,
      hopsLeft: hopsLeft,
      viaMqtt: mqtt,
      replayed: replayed,
    );

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  late List<(String, int)> sent;
  late List<int> told;
  late bool radioRelays;

  BastionSosRelay make() => BastionSosRelay(
        send: (text, channel) async => sent.add((text, channel)),
        radioRelaysItself: () => radioRelays,
        self: () => _me,
        nameOf: (n) => n == _hiker ? 'Ridge Hiker' : '!${n.toRadixString(16)}',
        onRelayed: (from, _) => told.add(from),
        random: math.Random(1),
      );

  setUp(() {
    sent = [];
    told = [];
    radioRelays = true;
  });

  test('off by default, and the choice is saved', () async {
    final relay = make();
    await relay.load();
    expect(relay.enabled, isFalse);
    await relay.setEnabled(true);
    final again = make();
    await again.load();
    expect(again.enabled, isTrue);
  });

  test('relays a channel SOS with no hops left, once, after the wait, on the same channel', () {
    fakeAsync((time) {
      final relay = make()..setEnabled(true);
      time.flushMicrotasks();
      relay.onMessage(_msg(_sos));
      time.elapse(const Duration(seconds: 9));
      expect(sent, isEmpty, reason: 'waits for another phone first');
      time.elapse(const Duration(seconds: 8));
      expect(sent, hasLength(1));
      final (text, channel) = sent.single;
      expect(channel, 2);
      expect(text, startsWith('${BastionSosRelay.relayPrefix} !b2c649cb Ridge Hiker: Need help'));
      expect(text, contains('Pos 35.60000,-82.50000'));
      expect(utf8.encode(text).length, lessThanOrEqualTo(BastionSosRelay.maxBytes));
      expect(told, [_hiker]);

      relay.onMessage(_msg(_sos));
      time.elapse(const Duration(seconds: 30));
      expect(sent, hasLength(1), reason: 'the same SOS is relayed once');
    });
  });

  test('when the mesh can still carry it, it is left to the radios', () {
    fakeAsync((time) {
      final relay = make()..setEnabled(true);
      time.flushMicrotasks();
      relay.onMessage(_msg(_sos, hopsLeft: 2));
      relay.onMessage(_msg(_sos.replaceFirst('12:00', '12:05'), hopsLeft: null));
      time.elapse(const Duration(minutes: 1));
      expect(sent, isEmpty);
    });
  });

  test('a radio that does not rebroadcast relays even with hops left', () {
    fakeAsync((time) {
      radioRelays = false;
      final relay = make()..setEnabled(true);
      time.flushMicrotasks();
      relay.onMessage(_msg(_sos, hopsLeft: 3));
      time.elapse(const Duration(seconds: 20));
      expect(sent, hasLength(1));
    });
  });

  test("another phone's relay of the same SOS cancels ours", () {
    fakeAsync((time) {
      final relay = make()..setEnabled(true);
      time.flushMicrotasks();
      relay.onMessage(_msg(_sos));
      time.elapse(const Duration(seconds: 5));
      final theirs = BastionSosRelay.relayText(_hiker, 'Hiker', BastionSosRelay.sosBody(_sos)!);
      relay.onMessage(_msg(theirs, from: 0x77, hopsLeft: 0));
      time.elapse(const Duration(seconds: 30));
      expect(sent, isEmpty);
    });
  });

  test('never relays a relay, a direct message, MQTT, a replay, your own SOS or other text', () {
    fakeAsync((time) {
      final relay = make()..setEnabled(true);
      time.flushMicrotasks();
      final relayMsg = BastionSosRelay.relayText(_hiker, 'Hiker', 'Need help');
      relay
        ..onMessage(_msg(relayMsg, from: 0x77))
        ..onMessage(_msg(_sos, to: _me))
        ..onMessage(_msg(_sos, mqtt: true))
        ..onMessage(_msg(_sos, replayed: true))
        ..onMessage(_msg(_sos, from: _me))
        ..onMessage(_msg('SOS help me'))
        ..onMessage(_msg('[NOTORYX Check-in] OK | 2026-11-20 12:00 UTC'));
      time.elapse(const Duration(minutes: 1));
      expect(sent, isEmpty);
    });
  });

  test('all clear is passed on too, and nothing is sent while off', () {
    fakeAsync((time) {
      final relay = make();
      relay.onMessage(_msg(_sos));
      time.elapse(const Duration(minutes: 1));
      expect(sent, isEmpty);
      relay.setEnabled(true);
      time.flushMicrotasks();
      relay.onMessage(_msg(sosAllClearText(DateTime.utc(2026, 11, 20, 13))));
      time.elapse(const Duration(seconds: 20));
      expect(sent.single.$1, contains('All clear'));
    });
  });

  test('turning it off cancels a relay that was waiting', () {
    fakeAsync((time) {
      final relay = make()..setEnabled(true);
      time.flushMicrotasks();
      relay.onMessage(_msg(_sos));
      time.elapse(const Duration(seconds: 3));
      relay.setEnabled(false);
      time.elapse(const Duration(minutes: 1));
      expect(sent, isEmpty);
    });
  });

  test('at most six relays an hour', () {
    fakeAsync((time) {
      final relay = make()..setEnabled(true);
      time.flushMicrotasks();
      for (var i = 0; i < 10; i++) {
        relay.onMessage(_msg(sosText(DateTime.utc(2026, 11, 20, 12, i)), from: 0x100 + i));
      }
      time.elapse(const Duration(minutes: 1));
      expect(sent, hasLength(BastionSosRelay.maxRelays));
    });
  });

  test('a long name is dropped before the message is cut', () {
    final text = BastionSosRelay.relayText(_hiker, 'N' * 120, BastionSosRelay.sosBody(_sos)!);
    expect(utf8.encode(text).length, lessThanOrEqualTo(BastionSosRelay.maxBytes));
    expect(text, contains('Need help'));
    expect(BastionSosRelay.relayOf(text)?.from, _hiker);
  });
}
