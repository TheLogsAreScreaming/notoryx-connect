import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'meshtastic_traceroute.dart';

/// Traceroutes other nodes ran to this radio, newest first, kept on this
/// phone (phone backups include them: `bastion.` prefix).
class BastionInboundTraces extends ChangeNotifier {
  BastionInboundTraces({SharedPreferencesAsync? prefs}) : _prefs = prefs;

  static const storageName = 'bastion.inbound_traceroutes_v1';
  static const maxKept = 50;

  SharedPreferencesAsync? _prefs;
  final List<InboundTraceroute> _traces = [];

  List<InboundTraceroute> get traces => List.unmodifiable(_traces);

  Future<void> load() async {
    try {
      _prefs ??= SharedPreferencesAsync();
      final raw = await _prefs!.getString(storageName);
      _traces.clear();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            final t = InboundTraceroute.fromJson(item);
            if (t != null) _traces.add(t);
          }
        }
      }
    } catch (e) {
      debugPrint('Inbound traceroutes: could not load ($e)');
    }
    notifyListeners();
  }

  Future<void> add(InboundTraceroute trace) async {
    _traces.insert(0, trace);
    if (_traces.length > maxKept) _traces.removeRange(maxKept, _traces.length);
    notifyListeners();
    try {
      await (_prefs ??= SharedPreferencesAsync()).setString(
        storageName,
        jsonEncode([for (final t in _traces) t.toJson()]),
      );
    } catch (e) {
      debugPrint('Inbound traceroutes: could not save ($e)');
    }
  }

  Future<void> clear() async {
    _traces.clear();
    notifyListeners();
    try {
      await (_prefs ??= SharedPreferencesAsync()).remove(storageName);
    } catch (_) {}
  }
}
