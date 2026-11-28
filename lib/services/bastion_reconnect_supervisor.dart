import 'dart:async';

import 'bastion_reconnect_policy.dart';

/// Transport-independent BLE reconnect supervisor.
///
/// The owner must call [cancel] on manual disconnect, radio switching, or
/// disposal. A reconnect is only attempted while the supplied guard permits it.
/// No background service is implied by this in-process component.
class BastionReconnectSupervisor {
  BastionReconnectSupervisor({
    required Future<void> Function() reconnect,
    required bool Function() mayReconnect,
    Future<void> Function(Duration) wait = _defaultWait,
    this.maxAttempts = 6,
  })  : _reconnect = reconnect,
        _mayReconnect = mayReconnect,
        _wait = wait {
    if (maxAttempts < 1) {
      throw ArgumentError.value(maxAttempts, 'maxAttempts');
    }
  }

  final Future<void> Function() _reconnect;
  final bool Function() _mayReconnect;
  final Future<void> Function(Duration) _wait;
  final int maxAttempts;

  bool _cancelled = false;
  bool _running = false;

  /// The generation the running [keepTrying] belongs to; a [cancel] or a new
  /// [recover] moves the generation on, so it counts as stopped at once and
  /// its pending wait finds nothing left to do.
  int? _slowGeneration;
  int _generation = 0;
  int attempts = 0;
  Object? lastError;

  bool get isRunning => _running;

  /// Whether [keepTrying] is between its slow tries.
  bool get isRetryingSlowly => _slowGeneration == _generation;

  /// Slow tries made by the current [keepTrying].
  int slowAttempts = 0;

  Future<bool> recover() async {
    if (_running) return false;
    _cancelled = false;
    _running = true;
    final generation = ++_generation;
    attempts = 0;
    lastError = null;
    try {
      while (attempts < maxAttempts &&
          !_cancelled &&
          generation == _generation &&
          _mayReconnect()) {
        await _wait(BastionReconnectPolicy.delayForAttempt(attempts));
        if (_cancelled || generation != _generation || !_mayReconnect()) {
          return false;
        }
        attempts++;
        try {
          await _reconnect();
          if (_cancelled || generation != _generation) return false;
          lastError = null;
          return true;
        } catch (error) {
          lastError = error;
        }
      }
      return false;
    } finally {
      _running = false;
    }
  }

  /// After [recover] gives up: one try at a time, with the waits in
  /// [BastionReconnectPolicy.slowDelayForAttempt], until a try works, [cancel]
  /// is called or the guard says no. [onWaiting] hears each wait before it
  /// starts, so the owner can say when the next try is.
  Future<bool> keepTrying({void Function(Duration next)? onWaiting}) async {
    if (_running || isRetryingSlowly) return false;
    _cancelled = false;
    final generation = ++_generation;
    _slowGeneration = generation;
    slowAttempts = 0;
    try {
      while (!_cancelled && generation == _generation && _mayReconnect()) {
        final delay = BastionReconnectPolicy.slowDelayForAttempt(slowAttempts);
        onWaiting?.call(delay);
        await _wait(delay);
        if (_cancelled || generation != _generation || !_mayReconnect()) {
          return false;
        }
        slowAttempts++;
        try {
          await _reconnect();
          if (_cancelled || generation != _generation) return false;
          lastError = null;
          return true;
        } catch (error) {
          lastError = error;
        }
      }
      return false;
    } finally {
      if (_slowGeneration == generation) _slowGeneration = null;
    }
  }

  void cancel() {
    _cancelled = true;
    _generation++;
  }

  static Future<void> _defaultWait(Duration delay) =>
      Future<void>.delayed(delay);
}
