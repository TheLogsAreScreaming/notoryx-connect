import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/bastion_reconnect_policy.dart';
import 'package:bastion/services/bastion_reconnect_supervisor.dart';

void main() {
  test('retries transient failures with bounded exponential delays', () async {
    var calls = 0;
    final delays = <Duration>[];
    final supervisor = BastionReconnectSupervisor(
      reconnect: () async {
        calls++;
        if (calls < 3) throw StateError('radio unavailable');
      },
      mayReconnect: () => true,
      wait: (delay) async { delays.add(delay); },
    );
    expect(await supervisor.recover(), isTrue);
    expect(calls, 3);
    expect(delays, [
      const Duration(seconds: 1),
      const Duration(seconds: 2),
      const Duration(seconds: 4),
    ]);
    expect(supervisor.lastError, isNull);
  });

  test('manual cancellation prevents a pending reconnect', () async {
    final gate = Completer<void>();
    var calls = 0;
    final supervisor = BastionReconnectSupervisor(
      reconnect: () async { calls++; },
      mayReconnect: () => true,
      wait: (_) => gate.future,
    );
    final result = supervisor.recover();
    supervisor.cancel();
    gate.complete();
    expect(await result, isFalse);
    expect(calls, 0);
  });

  test('disabled Bluetooth prevents reconnect attempts', () async {
    var calls = 0;
    final supervisor = BastionReconnectSupervisor(
      reconnect: () async { calls++; },
      mayReconnect: () => false,
      wait: (_) async {},
    );
    expect(await supervisor.recover(), isFalse);
    expect(calls, 0);
  });

  test('limits retries and preserves last failure', () async {
    var calls = 0;
    final supervisor = BastionReconnectSupervisor(
      reconnect: () async {
        calls++;
        throw StateError('offline');
      },
      mayReconnect: () => true,
      wait: (_) async {},
      maxAttempts: 2,
    );
    expect(await supervisor.recover(), isFalse);
    expect(calls, 2);
    expect(supervisor.lastError, isA<StateError>());
  });

  group('after giving up', () {
    test('keeps trying slowly until the radio is back', () async {
      var calls = 0;
      final waits = <Duration>[];
      final heard = <Duration>[];
      final supervisor = BastionReconnectSupervisor(
        reconnect: () async {
          calls++;
          if (calls < 6) throw StateError('out of range');
        },
        mayReconnect: () => true,
        wait: (delay) async => waits.add(delay),
      );
      expect(await supervisor.keepTrying(onWaiting: heard.add), isTrue);
      expect(calls, 6);
      expect(supervisor.slowAttempts, 6);
      const expected = [
        Duration(seconds: 30),
        Duration(minutes: 1),
        Duration(minutes: 2),
        Duration(minutes: 5),
        Duration(minutes: 5),
        Duration(minutes: 5),
      ];
      expect(waits, expected);
      expect(heard, expected, reason: 'the owner hears each wait before it starts');
      expect(supervisor.lastError, isNull);
      expect(supervisor.isRetryingSlowly, isFalse);
    });

    test('cancel stops it at once, and a new round can start', () async {
      final gate = Completer<void>();
      var calls = 0;
      final supervisor = BastionReconnectSupervisor(
        reconnect: () async => calls++,
        mayReconnect: () => true,
        wait: (_) => gate.future,
      );
      final first = supervisor.keepTrying();
      expect(supervisor.isRetryingSlowly, isTrue);
      supervisor.cancel();
      expect(supervisor.isRetryingSlowly, isFalse, reason: 'no wait for the pending timer');

      final second = supervisor.keepTrying();
      expect(supervisor.isRetryingSlowly, isTrue);
      gate.complete();
      expect(await first, isFalse);
      expect(await second, isTrue);
      expect(calls, 1, reason: 'only the new round tries');
    });

    test('stops when reconnecting is no longer allowed', () async {
      var allowed = true;
      var calls = 0;
      final supervisor = BastionReconnectSupervisor(
        reconnect: () async {
          calls++;
          allowed = false; // Bluetooth went off, or the user disconnected.
          throw StateError('offline');
        },
        mayReconnect: () => allowed,
        wait: (_) async {},
      );
      expect(await supervisor.keepTrying(), isFalse);
      expect(calls, 1);
      expect(supervisor.isRetryingSlowly, isFalse);
    });

    test('a new fast recovery ends the slow round', () async {
      final gate = Completer<void>();
      final supervisor = BastionReconnectSupervisor(
        reconnect: () async {},
        mayReconnect: () => true,
        wait: (delay) => delay >= const Duration(seconds: 30) ? gate.future : Future<void>.value(),
      );
      final slow = supervisor.keepTrying();
      expect(await supervisor.recover(), isTrue);
      expect(supervisor.isRetryingSlowly, isFalse);
      gate.complete();
      expect(await slow, isFalse);
    });
  });

  test('slow waits are 30 s, 1, 2 then 5 minutes', () {
    expect(() => BastionReconnectPolicy.slowDelayForAttempt(-1), throwsArgumentError);
    expect(BastionReconnectPolicy.slowDelayForAttempt(0), const Duration(seconds: 30));
    expect(BastionReconnectPolicy.slowDelayForAttempt(3), const Duration(minutes: 5));
    expect(BastionReconnectPolicy.slowDelayForAttempt(500), const Duration(minutes: 5));
  });
}
