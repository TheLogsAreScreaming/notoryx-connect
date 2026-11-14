import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bastion_chat_message.dart';
import 'bastion_waypoints.dart';
import 'meshtastic_node_database.dart';
import 'meshtastic_radio_coordinator.dart';

/// What a line of the timeline is about.
enum TimelineKind { message, nodeJoined, signalChange, waypoint }

/// One line of the timeline. The page puts the facts into words.
@immutable
class TimelineEvent {
  const TimelineEvent({
    required this.kind,
    required this.at,
    required this.subject,
    this.detail,
    this.nodeNum,
    this.fromSnr,
    this.toSnr,
    this.outgoing = false,
  });

  final TimelineKind kind;
  final DateTime at;

  /// Who or what it is about: a node, a sender or a waypoint name.
  final String subject;

  /// Message text or waypoint description.
  final String? detail;

  /// The node it is about, or the node that sent the message or waypoint.
  final int? nodeNum;
  final double? fromSnr;
  final double? toSnr;

  /// A message this phone sent.
  final bool outgoing;

  Map<String, Object?> toJson() => {
        'k': kind.name,
        'at': at.millisecondsSinceEpoch,
        's': subject,
        'd': ?detail,
        'n': ?nodeNum,
        'from': ?fromSnr,
        'to': ?toSnr,
        if (outgoing) 'out': true,
      };

  static TimelineEvent? fromJson(Object? json) {
    if (json is! Map) return null;
    final kind = TimelineKind.values.asNameMap()[json['k']];
    final at = json['at'], subject = json['s'];
    if (kind == null || at is! int || subject is! String) return null;
    return TimelineEvent(
      kind: kind,
      at: DateTime.fromMillisecondsSinceEpoch(at),
      subject: subject,
      detail: json['d'] is String ? json['d'] as String : null,
      nodeNum: json['n'] is int ? json['n'] as int : null,
      fromSnr: (json['from'] as num?)?.toDouble(),
      toSnr: (json['to'] as num?)?.toDouble(),
      outgoing: json['out'] == true,
    );
  }
}

/// SNR change (dB) that counts as a signal change worth a line.
const signalChangeDb = 6.0;

/// Watches each node's direct SNR and reports when it moves by
/// [signalChangeDb] or more from where it settled, so slow drift and
/// packet-to-packet jitter stay quiet.
class SignalChangeTracker {
  final Map<int, double> _baseline = {};

  /// Returns the change for [node] now heard at [snr], or null.
  ({double from, double to})? observe(int node, double snr) {
    final base = _baseline[node];
    if (base == null) {
      _baseline[node] = snr;
      return null;
    }
    if ((snr - base).abs() >= signalChangeDb) {
      _baseline[node] = snr;
      return (from: base, to: snr);
    }
    // Follow small moves slowly, so the baseline stays current.
    _baseline[node] = base * 0.8 + snr * 0.2;
    return null;
  }

  void clear() => _baseline.clear();
}

/// [events] newest first, keeping only [kinds] and lines that contain every
/// word of [query] (ignoring case).
List<TimelineEvent> filterTimeline(
  Iterable<TimelineEvent> events, {
  required Set<TimelineKind> kinds,
  String query = '',
}) {
  final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final out = events.where((e) {
    if (!kinds.contains(e.kind)) return false;
    if (words.isEmpty) return true;
    final hay = '${e.subject} ${e.detail ?? ''}'.toLowerCase();
    return words.every(hay.contains);
  }).toList();
  out.sort((a, b) => b.at.compareTo(a.at));
  return out;
}

/// What the timeline reads from the connected radio.
abstract interface class TimelineSource implements Listenable {
  int? get localNodeNum;
  bool get isReady;
  List<MeshtasticNode> get nodes;
  List<MeshWaypoint> get waypoints;
  List<BastionChatMessage> get messages;
  String nodeName(int num);
}

/// Reads the timeline's facts from the app's radio coordinator.
class CoordinatorTimelineSource implements TimelineSource {
  CoordinatorTimelineSource(this.radio);

  final MeshtasticRadioCoordinator radio;

  @override
  int? get localNodeNum => radio.localNodeNum;
  @override
  bool get isReady => radio.isReady;
  @override
  List<MeshtasticNode> get nodes => radio.nodes;
  @override
  List<MeshWaypoint> get waypoints => radio.waypoints;
  @override
  List<BastionChatMessage> get messages => radio.messages;
  @override
  String nodeName(int num) => radio.nodeName(num);
  @override
  void addListener(VoidCallback listener) => radio.addListener(listener);
  @override
  void removeListener(VoidCallback listener) => radio.removeListener(listener);
}

/// Keeps the timeline's own events for each radio: nodes heard for the first
/// time, direct signal changes and waypoints. Messages aren't copied here;
/// [messageEvents] reads them from the chat history when the timeline is
/// shown, so they stay where (and as encrypted as) they already are.
class BastionTimeline extends ChangeNotifier {
  BastionTimeline({SharedPreferencesAsync? preferences, DateTime Function()? clock})
      : _givenPrefs = preferences,
        _now = clock ?? DateTime.now;

  /// The one the app shell attaches to the real radio.
  static final BastionTimeline instance = BastionTimeline();

  static const maxEvents = 500;
  static String storageName(int radio) => 'bastion.timeline.$radio';

  SharedPreferencesAsync? _givenPrefs;

  // Made on first use, so creating the app-wide instance touches no storage.
  SharedPreferencesAsync get _prefs => _givenPrefs ??= SharedPreferencesAsync();
  final DateTime Function() _now;

  TimelineSource? _source;
  int? _radio;
  bool _loaded = false;
  bool _primed = false;
  final List<TimelineEvent> _events = [];
  final Set<int> _knownNodes = {};
  Set<int>? _knownWaypoints;
  final Map<int, DateTime> _lastHeard = {};
  final _signals = SignalChangeTracker();
  Timer? _saveTimer;
  Future<void>? _loading;

  /// The source being watched, or null.
  TimelineSource? get source => _source;

  /// The radio whose timeline this is, or null before one connects.
  int? get radio => _radio;

  /// The timeline's own events, newest first.
  List<TimelineEvent> get events => List.unmodifiable(_events);

  /// Starts watching [source]. Replaces any earlier source.
  void attach(TimelineSource source) {
    detach();
    _source = source;
    source.addListener(_changed);
    _changed();
  }

  /// Stops watching and saves what is pending.
  void detach() {
    _source?.removeListener(_changed);
    _source = null;
    if (_saveTimer != null) unawaited(_save());
  }

  /// The source's chat history as timeline lines, newest last.
  List<TimelineEvent> messageEvents() {
    final source = _source;
    if (source == null) return const [];
    return [
      for (final m in source.messages)
        if (!m.isReaction)
          TimelineEvent(
            kind: TimelineKind.message,
            at: m.timestamp,
            subject: source.nodeName(m.from),
            detail: m.text,
            nodeNum: m.from,
            outgoing: m.direction == BastionMessageDirection.outgoing,
          ),
    ];
  }

  /// Everything on the timeline: its own events and the chat history.
  List<TimelineEvent> all() => [..._events, ...messageEvents()];

  void _changed() {
    final source = _source;
    if (source == null) return;
    final radio = source.localNodeNum;
    if (radio != null && radio != 0 && radio != _radio) {
      if (_saveTimer != null) unawaited(_save());
      _radio = radio;
      _loaded = false;
      _primed = false;
      _events.clear();
      _knownNodes.clear();
      _knownWaypoints = null;
      _lastHeard.clear();
      _signals.clear();
      _loading = _load(radio).whenComplete(() {
        _loading = null;
        _changed();
      });
      notifyListeners();
      return;
    }
    if (!_loaded || _loading != null || !source.isReady) return;
    _observe(source);
  }

  /// Waits for the current radio's saved timeline to load (for tests).
  @visibleForTesting
  Future<void> settled() async {
    while (_loading != null) {
      await _loading;
    }
  }

  void _observe(TimelineSource source) {
    final now = _now();
    var changed = false;
    final nodes = [for (final n in source.nodes) if (n.num != _radio) n];
    if (!_primed) {
      // The radio's node list as it stands when the link is ready is the
      // starting point. Nodes known from an earlier session stay quiet;
      // only ones that are new since then get a line.
      _primed = true;
      final firstTime = _knownNodes.isEmpty;
      for (final n in nodes) {
        if (_knownNodes.add(n.num) && !firstTime) {
          _add(TimelineEvent(kind: TimelineKind.nodeJoined, at: n.lastHeard ?? now,
              subject: n.displayName, nodeNum: n.num));
        }
        if (n.lastHeard != null) _lastHeard[n.num] = n.lastHeard!;
        if (n.snr != null && n.hopsAway == 0) _signals.observe(n.num, n.snr!);
      }
      changed = true;
    } else {
      for (final n in nodes) {
        if (_knownNodes.add(n.num)) {
          _add(TimelineEvent(kind: TimelineKind.nodeJoined, at: n.lastHeard ?? now,
              subject: n.displayName, nodeNum: n.num));
          changed = true;
        }
        final heard = n.lastHeard;
        if (heard == null || heard == _lastHeard[n.num]) continue;
        _lastHeard[n.num] = heard;
        if (n.snr == null || n.hopsAway != 0) continue;
        final change = _signals.observe(n.num, n.snr!);
        if (change == null) continue;
        _add(TimelineEvent(kind: TimelineKind.signalChange, at: heard, subject: n.displayName,
            nodeNum: n.num, fromSnr: change.from, toSnr: change.to));
        changed = true;
      }
    }
    final ids = {for (final w in source.waypoints) w.id};
    final known = _knownWaypoints;
    _knownWaypoints = ids;
    if (known != null) {
      for (final w in source.waypoints) {
        if (known.contains(w.id)) continue;
        _add(TimelineEvent(kind: TimelineKind.waypoint, at: now, subject: w.name,
            detail: w.description.isEmpty ? null : w.description, nodeNum: w.from));
        changed = true;
      }
    } else {
      changed = true;
    }
    if (changed) {
      _scheduleSave();
      notifyListeners();
    }
  }

  void _add(TimelineEvent e) {
    _events.insert(0, e);
    if (_events.length > maxEvents) _events.removeRange(maxEvents, _events.length);
  }

  Future<void> _load(int radio) async {
    try {
      final raw = await _prefs.getString(storageName(radio));
      if (raw != null && radio == _radio) {
        final json = jsonDecode(raw);
        if (json is Map) {
          _events
            ..clear()
            ..addAll([for (final e in (json['events'] as List? ?? const [])) ?TimelineEvent.fromJson(e)]);
          _knownNodes.addAll([for (final n in (json['nodes'] as List? ?? const [])) if (n is int) n]);
          final w = json['waypoints'];
          if (w is List) _knownWaypoints = {for (final id in w) if (id is int) id};
        }
      }
    } catch (_) {
      // An unreadable timeline starts again; nothing else depends on it.
    }
    if (radio == _radio) {
      _loaded = true;
      notifyListeners();
    }
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () => unawaited(_save()));
  }

  Future<void> _save() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    final radio = _radio;
    if (radio == null || !_loaded) return;
    try {
      await _prefs.setString(storageName(radio), jsonEncode({
        'events': [for (final e in _events) e.toJson()],
        'nodes': _knownNodes.toList(),
        'waypoints': ?_knownWaypoints?.toList(),
      }));
    } catch (_) {
      // Best effort: the timeline is a convenience, not a record of truth.
    }
  }

  /// Saves now (for tests and when the app goes to the background).
  Future<void> flush() => _save();

  /// Forgets this radio's timeline events (messages stay in chat history).
  Future<void> clear() async {
    _events.clear();
    notifyListeners();
    await _save();
  }

  @override
  void dispose() {
    detach();
    _saveTimer?.cancel();
    super.dispose();
  }
}
