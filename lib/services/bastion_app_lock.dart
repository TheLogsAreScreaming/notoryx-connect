import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks the phone to confirm its owner. Separate so tests avoid the platform.
abstract interface class BastionDeviceAuth {
  /// Whether this phone can check a fingerprint, face or screen lock.
  Future<bool> isAvailable();

  /// Shows the system prompt; true when the owner was confirmed.
  Future<bool> authenticate(String reason);
}

class BastionLocalDeviceAuth implements BastionDeviceAuth {
  final _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) => _auth.authenticate(localizedReason: reason);
}

/// Covers the app until the phone's owner is confirmed.
///
/// Only the screen is locked: the radio link, alerts and background work
/// carry on underneath. It is off until the person turns it on.
class BastionAppLock extends ChangeNotifier {
  BastionAppLock({BastionDeviceAuth? auth, DateTime Function()? now})
      : _auth = auth ?? BastionLocalDeviceAuth(),
        _now = now ?? DateTime.now;

  static final instance = BastionAppLock();
  static const _key = 'bastion.app_lock';

  /// Time away after which coming back asks again.
  static const grace = Duration(minutes: 1);

  final BastionDeviceAuth _auth;
  final DateTime Function() _now;
  bool _enabled = false;
  bool _locked = false;
  bool _busy = false;
  DateTime? _leftAt;

  bool get enabled => _enabled;
  bool get locked => _locked;

  Future<bool> isAvailable() => _auth.isAvailable();

  Future<void> load() async {
    try {
      _enabled = await SharedPreferencesAsync().getBool(_key) ?? false;
    } catch (_) {
      _enabled = false;
    }
    _locked = _enabled;
    notifyListeners();
  }

  /// Turns the lock on or off once the owner is confirmed, so nobody can be
  /// shut out by a lock they never managed to open. Returns whether it changed.
  Future<bool> setEnabled(bool value, String reason) async {
    if (value == _enabled) return true;
    if (!await _confirm(reason)) return false;
    _enabled = value;
    _locked = false;
    await SharedPreferencesAsync().setBool(_key, value);
    notifyListeners();
    return true;
  }

  /// Asks for the owner. A phone that no longer has any screen lock opens
  /// straight away instead of trapping data behind an unanswerable prompt.
  Future<void> unlock(String reason) async {
    if (!_locked || _busy) return;
    _busy = true;
    try {
      if (!await _auth.isAvailable() || await _confirm(reason)) {
        _locked = false;
        _leftAt = null;
        notifyListeners();
      }
    } finally {
      _busy = false;
    }
  }

  Future<bool> _confirm(String reason) async {
    try {
      return await _auth.authenticate(reason);
    } on Exception {
      return false;
    }
  }

  void onBackground() => _leftAt ??= _now();

  void onForeground() {
    final left = _leftAt;
    _leftAt = null;
    if (!_enabled || _locked || left == null) return;
    if (_now().difference(left) >= grace) {
      _locked = true;
      notifyListeners();
    }
  }
}
