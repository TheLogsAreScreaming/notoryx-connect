import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sends a text message from this phone. Separate so tests avoid the platform.
abstract interface class BastionSmsGateway {
  Future<bool> hasPermission();
  Future<void> requestPermission();
  Future<void> send(String number, String text);
}

class BastionPhoneSmsGateway implements BastionSmsGateway {
  static const _channel = MethodChannel('com.bastionmesh.connect/sms');

  @override
  Future<bool> hasPermission() async => await _channel.invokeMethod<bool>('hasPermission') ?? false;
  @override
  Future<void> requestPermission() => _channel.invokeMethod<bool>('requestPermission');
  @override
  Future<void> send(String number, String text) =>
      _channel.invokeMethod<void>('send', {'number': number, 'text': text});
}

/// Lets chosen mesh nodes send SMS through a base-camp phone.
///
/// A node on the allowed list sends a direct message `SMS alias: text`, and
/// the text goes to the number saved under that alias. Numbers can't be typed
/// over the mesh, so nobody can reach an arbitrary number or run up charges.
/// Exists only in sideload builds made with `--dart-define=NOTORYX_SMS=true`.
class BastionSmsRelay extends ChangeNotifier {
  BastionSmsRelay({BastionSmsGateway? gateway, DateTime Function()? now})
      : gateway = gateway ?? BastionPhoneSmsGateway(),
        _now = now ?? DateTime.now;

  static final instance = BastionSmsRelay();
  static const available = bool.fromEnvironment('NOTORYX_SMS');
  static const maxPerHour = 10;
  static const maxLength = 160;
  static const _key = 'bastion.sms_relay.v1';
  static final _command = RegExp(r'^\s*sms\s+([a-z0-9_-]{1,16})\s*:\s*(.+)$', caseSensitive: false, dotAll: true);
  static final aliasPattern = RegExp(r'^[a-z0-9_-]{1,16}$');
  static final numberPattern = RegExp(r'^\+?[0-9]{5,15}$');

  final BastionSmsGateway gateway;
  final DateTime Function() _now;
  bool _enabled = false;
  final Set<int> _allowedNodes = {};
  final Map<String, String> _contacts = {};
  final List<DateTime> _sent = [];
  final Set<int> _seenPackets = {};

  bool get enabled => _enabled;
  Set<int> get allowedNodes => Set.unmodifiable(_allowedNodes);
  Map<String, String> get contacts => Map.unmodifiable(_contacts);

  Future<void> load() async {
    try {
      final raw = await SharedPreferencesAsync().getString(_key);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _enabled = json['enabled'] == true;
      _allowedNodes..clear()..addAll((json['nodes'] as List).cast<int>());
      _contacts..clear()..addAll((json['contacts'] as Map).cast<String, String>());
      notifyListeners();
    } catch (_) {
      // A damaged list leaves the relay off, the safe state.
      _enabled = false;
      _allowedNodes.clear();
      _contacts.clear();
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    await _changed();
  }

  Future<void> setNodeAllowed(int node, bool allowed) async {
    allowed ? _allowedNodes.add(node) : _allowedNodes.remove(node);
    await _changed();
  }

  /// Saves a contact. Returns false when the alias or number isn't valid.
  Future<bool> saveContact(String alias, String number) async {
    final name = alias.trim().toLowerCase();
    final digits = number.replaceAll(RegExp(r'[\s()-]'), '');
    if (!aliasPattern.hasMatch(name) || !numberPattern.hasMatch(digits)) return false;
    _contacts[name] = digits;
    await _changed();
    return true;
  }

  Future<void> removeContact(String alias) async {
    _contacts.remove(alias);
    await _changed();
  }

  /// Handles one received message. Returns the reply to send back over the
  /// mesh, or null when the message wasn't meant for the relay.
  Future<String?> handle({required int from, required String text, required bool isBroadcast, required int packetId}) async {
    final match = _command.firstMatch(text);
    if (!_enabled || isBroadcast || match == null) return null;
    // Stay silent to nodes off the list, so the relay can't be discovered.
    if (!_allowedNodes.contains(from)) return null;
    if (packetId != 0 && !_seenPackets.add(packetId)) return null;
    if (_seenPackets.length > 500) _seenPackets.remove(_seenPackets.first);
    final alias = match[1]!.toLowerCase();
    final body = match[2]!.trim();
    final number = _contacts[alias];
    if (number == null) return 'SMS not sent: no contact "$alias".';
    if (body.length > maxLength) return 'SMS not sent: over $maxLength characters.';
    final now = _now();
    _sent.removeWhere((t) => now.difference(t) >= const Duration(hours: 1));
    if (_sent.length >= maxPerHour) return 'SMS not sent: limit of $maxPerHour an hour reached.';
    try {
      if (!await gateway.hasPermission()) return 'SMS not sent: the base phone has not allowed SMS.';
      await gateway.send(number, body);
    } catch (_) {
      return 'SMS not sent: the base phone could not send it.';
    }
    _sent.add(now);
    return 'SMS to $alias handed to the phone network.';
  }

  Future<void> _changed() async {
    notifyListeners();
    await SharedPreferencesAsync().setString(_key, jsonEncode({
      'enabled': _enabled,
      'nodes': _allowedNodes.toList(),
      'contacts': _contacts,
    }));
  }
}
