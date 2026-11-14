import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'meshtastic_ble_discovery.dart';

/// Remembers the radio to reconnect to when the app starts again.
///
/// Saved after a connection succeeds and cleared when the user disconnects,
/// so a radio the user left on purpose is never reconnected. USB radios are
/// not kept: their Android device id changes every time the cable is plugged in.
class BastionLastLink {
  BastionLastLink({SharedPreferencesAsync? preferences})
    : _preferences = preferences;

  static const key = 'bastion.comms.last_link';

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();

  /// The radio to reconnect to, or null when there is none.
  Future<MeshtasticBleDevice?> load() async {
    try {
      final raw = await _store.getString(key);
      if (raw == null) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final id = json['id'], name = json['name'];
      if (id is! String || id.isEmpty || name is! String) return null;
      final device = MeshtasticBleDevice(
        id: id,
        name: name,
        rssi: 0,
        advertisedServices: const [],
      );
      return device.isUsb ? null : device;
    } catch (_) {
      return null;
    }
  }

  /// Remembers [device]; USB radios are skipped.
  Future<void> save(MeshtasticBleDevice device) async {
    if (device.isUsb) return;
    try {
      await _store.setString(
        key,
        jsonEncode({'id': device.id, 'name': device.name}),
      );
    } catch (_) {
      // Only means no automatic reconnect next launch.
    }
  }

  /// Forgets the radio, after the user disconnects.
  Future<void> clear() async {
    try {
      await _store.remove(key);
    } catch (_) {}
  }
}
