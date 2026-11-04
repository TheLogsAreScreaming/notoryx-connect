import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/bastion_reconnect_policy.dart';

void main() {
  test('negative retry indices are rejected', () {
    expect(() => BastionReconnectPolicy.delayForAttempt(-1), throwsArgumentError);
  });

  test('backoff follows every step and caps at thirty seconds', () {
    const seconds = [1, 2, 4, 8, 16, 30];
    for (var i = 0; i < seconds.length; i++) {
      expect(BastionReconnectPolicy.delayForAttempt(i), Duration(seconds: seconds[i]));
    }
    expect(BastionReconnectPolicy.delayForAttempt(6), const Duration(seconds: 30));
    expect(BastionReconnectPolicy.delayForAttempt(1000), const Duration(seconds: 30));
  });

  test('manual disconnect always overrides bluetooth availability', () {
    for (final enabled in [false, true]) {
      expect(
        BastionReconnectPolicy.shouldReconnect(
          userDisconnected: true, bluetoothEnabled: enabled,
        ),
        isFalse,
      );
    }
  });

  test('only an unrequested disconnect with bluetooth enabled can retry', () {
    expect(
      BastionReconnectPolicy.shouldReconnect(
        userDisconnected: false, bluetoothEnabled: true,
      ),
      isTrue,
    );
    expect(
      BastionReconnectPolicy.shouldReconnect(
        userDisconnected: false, bluetoothEnabled: false,
      ),
      isFalse,
    );
  });
}
