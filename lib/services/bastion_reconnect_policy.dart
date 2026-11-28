/// Bounded BLE reconnect backoff; callers must stop retries on manual disconnect.
abstract final class BastionReconnectPolicy {
  static Duration delayForAttempt(int attempt) {
    if (attempt < 0) throw ArgumentError.value(attempt, 'attempt');
    const seconds = [1, 2, 4, 8, 16, 30];
    return Duration(seconds: seconds[attempt < seconds.length ? attempt : seconds.length - 1]);
  }

  /// Waits between the slow tries that follow once the fast ones give up:
  /// 30 s, 1 min, 2 min, then every 5 min until the radio is back.
  static Duration slowDelayForAttempt(int attempt) {
    if (attempt < 0) throw ArgumentError.value(attempt, 'attempt');
    const seconds = [30, 60, 120, 300];
    return Duration(seconds: seconds[attempt < seconds.length ? attempt : seconds.length - 1]);
  }

  static bool shouldReconnect({required bool userDisconnected, required bool bluetoothEnabled}) =>
      !userDisconnected && bluetoothEnabled;
}
