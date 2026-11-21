import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'meshtastic_text_codec.dart';

/// SOS relay, after NOTORYX Core's: passes on a channel SOS that the mesh
/// itself won't carry any further.
///
/// Meshtastic radios already rebroadcast what they hear, so this only acts
/// in the two cases where that stops:
/// - the SOS reached this radio with its hop limit used up, so no radio
///   will forward it again; or
/// - this radio is set not to rebroadcast (Client Mute, or rebroadcast
///   mode None).
///
/// It then waits [waitFor] plus a random jitter, and if no other phone's
/// relay of the same SOS is heard meanwhile, sends one message on the same
/// channel, from this radio, with a fresh hop limit:
/// `[NOTORYX SOS relay] !sender Name: <the original message>`.
///
/// Only Connect's own channel SOS and all-clear messages are relayed. A
/// relay is never relayed again (no chains or loops), each SOS is relayed at
/// most once, there's an hourly cap, and messages that came over MQTT or as
/// store-and-forward replays are left alone. Off by default.
class BastionSosRelay extends ChangeNotifier {
  BastionSosRelay({
    required this.send,
    required this.radioRelaysItself,
    required this.self,
    required this.nameOf,
    this.onRelayed,
    this.waitFor = const Duration(seconds: 10),
    this.maxJitter = const Duration(seconds: 6),
    SharedPreferencesAsync? prefs,
    DateTime Function()? clock,
    math.Random? random,
  })  : _prefs = prefs,
        _clock = clock ?? DateTime.now,
        _random = random ?? math.Random();

  /// The one the app uses, once the shell has made it.
  static BastionSosRelay? instance;

  static const prefsKey = 'bastion.sos_relay.v1';
  static const sosPrefix = '[NOTORYX SOS]';
  static const relayPrefix = '[NOTORYX SOS relay]';

  /// At most this many relays in [rateWindow], however many are heard.
  static const maxRelays = 6;
  static const rateWindow = Duration(hours: 1);

  /// Longest relay message, as for any field message.
  static const maxBytes = 200;

  /// Sends [text] on [channel]; returns when the radio has it.
  final Future<void> Function(String text, int channel) send;

  /// Whether the connected radio rebroadcasts packets itself.
  final bool Function() radioRelaysItself;

  /// This radio's node number.
  final int? Function() self;
  final String Function(int num) nameOf;

  /// Told after each relay, e.g. to show a notification.
  final void Function(int from, String text)? onRelayed;
  final Duration waitFor;
  final Duration maxJitter;

  final SharedPreferencesAsync? _prefs;
  final DateTime Function() _clock;
  final math.Random _random;
  bool _enabled = false;
  final Map<String, Timer> _pending = {};
  final LinkedHashSet<String> _handled = LinkedHashSet();
  final List<DateTime> _relayTimes = [];
  int _relayed = 0;
  DateTime? _lastAt;
  int? _lastFrom;

  bool get enabled => _enabled;

  /// Relays sent since the app started.
  int get relayed => _relayed;
  DateTime? get lastRelayAt => _lastAt;
  int? get lastRelayFrom => _lastFrom;

  SharedPreferencesAsync get _store => _prefs ?? SharedPreferencesAsync();

  Future<void> load() async {
    try {
      _enabled = await _store.getBool(prefsKey) ?? false;
    } catch (_) {
      _enabled = false;
    }
    notifyListeners();
  }

  Future<void> setEnabled(bool on) async {
    if (on == _enabled) return;
    _enabled = on;
    if (!on) _cancelAll();
    notifyListeners();
    try {
      await _store.setBool(prefsKey, on);
    } catch (e) {
      debugPrint('Could not save SOS relay setting: $e');
    }
  }

  /// The original message's text without the SOS prefix, if [text] is one
  /// of Connect's SOS or all-clear messages; null otherwise.
  static String? sosBody(String text) {
    final t = text.trim();
    if (t.startsWith(relayPrefix) || !t.startsWith(sosPrefix)) return null;
    return t.substring(sosPrefix.length).trim();
  }

  /// The original sender and text a relay message carries, or null.
  static ({int from, String body})? relayOf(String text) {
    final t = text.trim();
    if (!t.startsWith(relayPrefix)) return null;
    final m = RegExp(r'^!([0-9a-f]{8})\b[^:]*:\s*(.*)$', dotAll: true).firstMatch(t.substring(relayPrefix.length).trim());
    if (m == null) return null;
    return (from: int.parse(m.group(1)!, radix: 16), body: m.group(2)!.trim());
  }

  static String _key(int from, String body) => '$from|$body';

  /// The relay message for [body] from [from] named [name], cut to fit.
  static String relayText(int from, String name, String body) {
    final id = '!${from.toRadixString(16).padLeft(8, '0')}';
    var cleanName = name.replaceAll(':', ' ').trim();
    if (cleanName.isEmpty || cleanName == id) cleanName = '';
    String build(String n) => '$relayPrefix $id${n.isEmpty ? '' : ' $n'}: $body';
    var text = build(cleanName);
    // Drop the name, then trim the end, rather than go over the limit.
    if (utf8.encode(text).length > maxBytes) text = build('');
    while (utf8.encode(text).length > maxBytes) {
      text = text.characters.skipLast(1).toString();
    }
    return text;
  }

  /// Looks at every incoming message.
  void onMessage(MeshtasticTextMessage m) {
    if (!_enabled) return;
    // Another phone's relay of an SOS we are waiting on: it is carried.
    if (relayOf(m.text) case final r?) {
      final key = _key(r.from, r.body);
      _pending.remove(key)?.cancel();
      _remember(key);
      return;
    }
    final body = sosBody(m.text);
    if (body == null) return;
    final key = _key(m.from, body);
    if (_handled.contains(key) || _pending.containsKey(key)) return;
    if (m.from == self() || m.viaMqtt || m.replayed || m.isReaction) return;
    // Direct messages are for their recipient; only channel SOS is passed on.
    if (m.to != MeshtasticTextCodec.broadcastNode) return;
    final exhausted = m.hopsLeft == 0;
    if (!exhausted && radioRelaysItself()) {
      // The mesh will carry it; nothing to add.
      _remember(key);
      return;
    }
    final jitter = maxJitter.inMilliseconds <= 0
        ? Duration.zero
        : Duration(milliseconds: _random.nextInt(maxJitter.inMilliseconds));
    _pending[key] = Timer(waitFor + jitter, () => unawaited(_relay(key, m, body)));
  }

  Future<void> _relay(String key, MeshtasticTextMessage m, String body) async {
    _pending.remove(key);
    _remember(key);
    if (!_enabled) return;
    final now = _clock();
    _relayTimes.removeWhere((t) => now.difference(t) > rateWindow);
    if (_relayTimes.length >= maxRelays) {
      debugPrint('SOS relay: hourly limit reached, not relaying');
      return;
    }
    final text = relayText(m.from, nameOf(m.from), body);
    try {
      await send(text, m.channel);
    } on Object catch (e) {
      debugPrint('SOS relay failed: $e');
      return;
    }
    _relayTimes.add(now);
    _relayed++;
    _lastAt = now;
    _lastFrom = m.from;
    onRelayed?.call(m.from, text);
    notifyListeners();
  }

  void _remember(String key) {
    _handled.add(key);
    while (_handled.length > 500) {
      _handled.remove(_handled.first);
    }
  }

  void _cancelAll() {
    for (final t in _pending.values) {
      t.cancel();
    }
    _pending.clear();
  }

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }
}
