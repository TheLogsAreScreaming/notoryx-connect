import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bastion_geo.dart';
import 'meshtastic_node_database.dart';

double _toDouble(Object? v) => (v! as num).toDouble();

/// What the journal has learned about one node, across every radio.
///
/// Hours and days are counted from the Unix epoch in UTC so a record means
/// the same thing after a time-zone change. Only the last [BastionNodeJournal.window]
/// of hours is kept; days and totals are kept for good.
class JournalEntry {
  const JournalEntry({
    required this.num,
    required this.firstHeard,
    required this.lastHeard,
    this.name,
    this.shortName,
    this.hours = const [],
    this.days = 0,
    this.lastDay = -1,
    this.heard = 0,
    this.direct = 0,
    this.relayed = 0,
    this.internet = 0,
    this.externalPower = 0,
    this.places = const [],
    this.tags = const [],
    this.note = '',
  });

  final int num;
  final String? name;
  final String? shortName;
  final DateTime firstHeard;
  final DateTime lastHeard;

  /// Distinct epoch hours (UTC) the node was heard in, oldest first.
  final List<int> hours;

  /// Distinct UTC days the node was heard on, and the latest of them.
  final int days;
  final int lastDay;

  /// Updates heard in total, and how they arrived.
  final int heard;
  final int direct;
  final int relayed;
  final int internet;

  /// Updates that reported the node running on external power.
  final int externalPower;

  /// Distinct places the node reported, as rounded positions (about 500 m).
  final List<({double lat, double lon})> places;

  final List<String> tags;
  final String note;

  String get displayName => (name?.isNotEmpty ?? false) ? name! : nodeId;
  String get nodeId => '!${num.toRadixString(16).padLeft(8, '0')}';

  /// Farthest distance between any two reported places, in metres.
  double get spreadMeters {
    var best = 0.0;
    for (var i = 0; i < places.length; i++) {
      for (var j = i + 1; j < places.length; j++) {
        best = math.max(best, BastionGeo.distanceMeters(
            places[i].lat, places[i].lon, places[j].lat, places[j].lon));
      }
    }
    return best;
  }

  JournalEntry copyWith({
    String? name, String? shortName, DateTime? lastHeard, List<int>? hours,
    int? days, int? lastDay, int? heard, int? direct, int? relayed, int? internet,
    int? externalPower, List<({double lat, double lon})>? places,
    List<String>? tags, String? note,
  }) => JournalEntry(
    num: num, firstHeard: firstHeard,
    name: name ?? this.name, shortName: shortName ?? this.shortName,
    lastHeard: lastHeard ?? this.lastHeard, hours: hours ?? this.hours,
    days: days ?? this.days, lastDay: lastDay ?? this.lastDay,
    heard: heard ?? this.heard, direct: direct ?? this.direct,
    relayed: relayed ?? this.relayed, internet: internet ?? this.internet,
    externalPower: externalPower ?? this.externalPower,
    places: places ?? this.places, tags: tags ?? this.tags, note: note ?? this.note,
  );

  Map<String, Object?> toJson() => {
    'num': num, 'name': name, 'short': shortName,
    'first': firstHeard.toUtc().millisecondsSinceEpoch ~/ 1000,
    'last': lastHeard.toUtc().millisecondsSinceEpoch ~/ 1000,
    'hours': hours, 'days': days, 'lastDay': lastDay, 'heard': heard,
    'direct': direct, 'relayed': relayed, 'internet': internet, 'power': externalPower,
    'places': [for (final p in places) [p.lat, p.lon]],
    if (tags.isNotEmpty) 'tags': tags,
    if (note.isNotEmpty) 'note': note,
  };

  static DateTime _time(Object? seconds) =>
      DateTime.fromMillisecondsSinceEpoch((seconds! as int) * 1000);

  static JournalEntry fromJson(Map<String, Object?> json) => JournalEntry(
    num: json['num']! as int,
    name: json['name'] as String?, shortName: json['short'] as String?,
    firstHeard: _time(json['first']), lastHeard: _time(json['last']),
    hours: [for (final h in json['hours'] as List? ?? const []) h as int],
    days: json['days'] as int? ?? 0, lastDay: json['lastDay'] as int? ?? -1,
    heard: json['heard'] as int? ?? 0, direct: json['direct'] as int? ?? 0,
    relayed: json['relayed'] as int? ?? 0, internet: json['internet'] as int? ?? 0,
    externalPower: json['power'] as int? ?? 0,
    places: [
      for (final p in json['places'] as List? ?? const [])
        (lat: _toDouble((p as List)[0]), lon: _toDouble(p[1])),
    ],
    tags: [for (final t in json['tags'] as List? ?? const []) t as String],
    note: json['note'] as String? ?? '',
  );
}

/// The behaviour a node shows, each with its own word and icon in the UI.
enum NodeBehaviour {
  /// On the air nearly every hour and never moves: a relay or base station.
  steadyRelay,

  /// Reports from places far apart.
  roamer,

  /// Comes back on several days, but is not on all the time.
  regular,

  /// Heard only briefly, long enough ago that it has had a chance to return.
  rarelyHeard,

  /// First heard within the last day; too soon to say more.
  newcomer,

  /// Used to be heard often but has been silent for a week or more.
  goneQuiet,

  /// Mostly reaches this radio through an internet gateway, not over the air.
  internetLinked,
}

/// One fact behind a label, with the numbers the UI puts into words.
enum EvidenceKind {
  /// [a] of the last [b] hours had the node on the air.
  hoursOnAir,

  /// Reported [a] different places, at most [b] metres apart.
  placesSpread,

  /// Reported a single place, or places within [b] metres.
  staysPut,

  /// [a] updates said it runs on external power.
  externalPower,

  /// Heard on [a] different days.
  daysHeard,

  /// Heard in only [a] hours since it was first heard [b] days ago.
  fewHours,

  /// First heard [a] hours ago.
  firstHeardHoursAgo,

  /// Silent for [a] days.
  silentDays,

  /// [a] of [b] updates came over the internet.
  viaInternet,
}

class Evidence {
  const Evidence(this.kind, this.a, [this.b = 0]);
  final EvidenceKind kind;
  final int a;
  final int b;

  @override
  bool operator ==(Object other) =>
      other is Evidence && other.kind == kind && other.a == a && other.b == b;
  @override
  int get hashCode => Object.hash(kind, a, b);
  @override
  String toString() => '$kind($a, $b)';
}

/// A behaviour label, how sure the journal is (0–1), and why.
class BehaviourLabel {
  const BehaviourLabel(this.behaviour, this.confidence, this.evidence);
  final NodeBehaviour behaviour;
  final double confidence;
  final List<Evidence> evidence;

  /// Low below 0.5, high from 0.8; the UI shows these words, not the number.
  ConfidenceBand get band => confidence >= 0.8
      ? ConfidenceBand.high
      : confidence >= 0.5
          ? ConfidenceBand.medium
          : ConfidenceBand.low;
}

enum ConfidenceBand { low, medium, high }

/// Sorts nodes into behaviours from what the journal has seen.
///
/// Pure and deterministic: the same entry and [now] always give the same
/// labels, strongest first. A node with too little history gets none.
abstract final class NodeBehaviourClassifier {
  static const _hour = 3600;
  static const _day = 24;

  static int _epochHour(DateTime t) => t.toUtc().millisecondsSinceEpoch ~/ 1000 ~/ _hour;

  static List<BehaviourLabel> classify(JournalEntry e, DateTime now) {
    final labels = <BehaviourLabel>[];
    final nowHour = _epochHour(now);
    final firstHour = _epochHour(e.firstHeard);
    final silentHours = nowHour - _epochHour(e.lastHeard);
    final ageHours = math.max(1, nowHour - firstHour + 1);

    // Coverage over the hours the journal could have heard it, capped to the window.
    final span = math.min(ageHours, BastionNodeJournal.window.inHours);
    final windowStart = nowHour - span + 1;
    final onAir = e.hours.where((h) => h >= windowStart).length;
    final coverage = onAir / span;
    final spread = e.spreadMeters.round();

    if (e.heard >= 4 && e.internet / e.heard >= 0.6) {
      labels.add(BehaviourLabel(NodeBehaviour.internetLinked,
          _clamp(0.5 + e.internet / e.heard / 2 * math.min(1, e.heard / 20)),
          [Evidence(EvidenceKind.viaInternet, e.internet, e.heard)]));
    }

    if (silentHours >= 7 * _day && (e.days >= 3 || e.hours.length >= 12)) {
      labels.add(BehaviourLabel(NodeBehaviour.goneQuiet,
          _clamp(0.5 + silentHours / (30 * _day) * 0.5),
          [Evidence(EvidenceKind.silentDays, silentHours ~/ _day), Evidence(EvidenceKind.daysHeard, e.days)]));
    }

    if (ageHours < _day) {
      labels.add(BehaviourLabel(NodeBehaviour.newcomer, 0.9,
          [Evidence(EvidenceKind.firstHeardHoursAgo, ageHours - 1)]));
      return _sorted(labels);
    }

    if (e.places.length >= 2 && spread >= 2000) {
      labels.add(BehaviourLabel(NodeBehaviour.roamer,
          _clamp(0.4 + math.min(e.places.length, 8) / 16 + math.min(spread, 20000) / 40000),
          [Evidence(EvidenceKind.placesSpread, e.places.length, spread)]));
    }

    final still = e.places.length <= 1 || spread < 1000;
    if (span >= 12 && coverage >= 0.6 && still && silentHours < 6) {
      final evidence = [
        Evidence(EvidenceKind.hoursOnAir, onAir, span),
        if (e.places.isNotEmpty) Evidence(EvidenceKind.staysPut, e.places.length, spread),
        if (e.externalPower > 0) Evidence(EvidenceKind.externalPower, e.externalPower),
      ];
      labels.add(BehaviourLabel(NodeBehaviour.steadyRelay,
          _clamp(coverage * 0.6 + math.min(span, 72) / 72 * 0.25 +
              (e.places.isNotEmpty ? 0.05 : 0) + (e.externalPower > 0 ? 0.1 : 0)),
          evidence));
    } else if (e.days >= 3 && coverage < 0.6) {
      labels.add(BehaviourLabel(NodeBehaviour.regular,
          _clamp(0.4 + math.min(e.days, 10) / 20),
          [Evidence(EvidenceKind.daysHeard, e.days)]));
    }

    if (ageHours >= 3 * _day && e.days <= 2 && e.hours.length <= 3) {
      labels.add(BehaviourLabel(NodeBehaviour.rarelyHeard,
          _clamp(0.4 + math.min(ageHours / _day, 14) / 28),
          [Evidence(EvidenceKind.fewHours, e.hours.length, ageHours ~/ _day)]));
    }
    return _sorted(labels);
  }

  static double _clamp(double v) => v.clamp(0.0, 0.99);

  static List<BehaviourLabel> _sorted(List<BehaviourLabel> labels) =>
      labels..sort((a, b) {
        final c = b.confidence.compareTo(a.confidence);
        return c != 0 ? c : a.behaviour.index.compareTo(b.behaviour.index);
      });
}

/// Every node this phone has ever heard, on any radio, with tags and notes.
///
/// Updates are kept in memory and saved at most every [saveEvery]; [flush]
/// saves anything pending. When storage can't be read the journal keeps
/// working in memory and never overwrites what is there.
class BastionNodeJournal extends ChangeNotifier {
  BastionNodeJournal({SharedPreferencesAsync? preferences, DateTime Function()? clock})
      : _preferences = preferences,
        _clock = clock ?? DateTime.now;

  static const storageKey = 'bastion.nodejournal.v1';
  static const window = Duration(days: 14);
  static const saveEvery = Duration(seconds: 30);
  static const maxPlaces = 24;
  static const maxTags = 12;

  /// Places closer than this share one entry (about 500 m of latitude).
  static const placeStep = 0.005;

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();
  final DateTime Function() _clock;
  final Map<int, JournalEntry> _entries = {};
  Future<void>? _loading;
  bool _blocked = false;
  bool _dirty = false;
  DateTime? _lastSave;

  /// All entries, most recently heard first.
  List<JournalEntry> get entries => List.unmodifiable(
      _entries.values.toList()..sort((a, b) {
        final c = b.lastHeard.compareTo(a.lastHeard);
        return c != 0 ? c : a.num.compareTo(b.num);
      }));

  JournalEntry? entry(int num) => _entries[num];

  /// Whether storage could not be read; changes then stay in memory only.
  bool get storageProblem => _blocked;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final String? raw;
    try {
      raw = await _store.getString(storageKey);
    } catch (_) {
      _blocked = true;
      return;
    }
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final item in decoded) {
        try {
          final e = JournalEntry.fromJson(Map<String, Object?>.from(item as Map));
          // Updates heard before loading finished win over the saved copy.
          _entries.putIfAbsent(e.num, () => e);
        } catch (_) {
          // One damaged entry must not hide the rest.
        }
      }
    } on FormatException {
      // Unreadable journal: start again, the next save replaces it.
    }
    notifyListeners();
  }

  static ({double lat, double lon}) _place(double lat, double lon) => (
    lat: double.parse(((lat / placeStep).round() * placeStep).toStringAsFixed(4)),
    lon: double.parse(((lon / placeStep).round() * placeStep).toStringAsFixed(4)),
  );

  /// Records one update from [node]. Saves when [saveEvery] has passed.
  Future<void> observe(MeshtasticNode node) async {
    await load();
    final now = _clock();
    final hour = now.toUtc().millisecondsSinceEpoch ~/ 1000 ~/ 3600;
    final day = hour ~/ 24;
    final old = _entries[node.num] ??
        JournalEntry(num: node.num, firstHeard: now, lastHeard: now);
    final hours = old.hours.isNotEmpty && old.hours.last == hour
        ? old.hours
        : [
            for (final h in old.hours) if (h > hour - window.inHours) h,
            hour,
          ];
    var places = old.places;
    if (node.hasPosition) {
      final p = _place(node.latitude!, node.longitude!);
      if (!places.contains(p)) {
        places = [...places, p];
        if (places.length > maxPlaces) places = places.sublist(places.length - maxPlaces);
      }
    }
    _entries[node.num] = old.copyWith(
      name: (node.longName?.isNotEmpty ?? false) ? node.longName : old.name,
      shortName: (node.shortName?.isNotEmpty ?? false) ? node.shortName : old.shortName,
      lastHeard: now, hours: hours,
      days: old.lastDay == day ? old.days : old.days + 1, lastDay: day,
      heard: old.heard + 1,
      direct: old.direct + (!node.viaMqtt && node.hopsAway == 0 ? 1 : 0),
      relayed: old.relayed + (!node.viaMqtt && (node.hopsAway ?? 0) > 0 ? 1 : 0),
      internet: old.internet + (node.viaMqtt ? 1 : 0),
      externalPower: old.externalPower + (node.batteryLevel == 101 ? 1 : 0),
      places: places,
    );
    _dirty = true;
    notifyListeners();
    final last = _lastSave;
    if (last == null || now.difference(last) >= saveEvery) await flush();
  }

  /// Replaces [num]'s tags. Blank tags are dropped; duplicates ignore case.
  Future<bool> setTags(int num, Iterable<String> tags) async {
    await load();
    final old = _entries[num];
    if (old == null) return false;
    final seen = <String>{};
    final clean = [
      for (final t in tags.map((t) => t.trim()))
        if (t.isNotEmpty && seen.add(t.toLowerCase())) t,
    ].take(maxTags).toList();
    _entries[num] = old.copyWith(tags: clean);
    _dirty = true;
    notifyListeners();
    return flush();
  }

  Future<bool> setNote(int num, String note) async {
    await load();
    final old = _entries[num];
    if (old == null) return false;
    _entries[num] = old.copyWith(note: note.trim());
    _dirty = true;
    notifyListeners();
    return flush();
  }

  /// Every tag in use, sorted, for suggestions.
  List<String> get allTags {
    final seen = <String, String>{};
    for (final e in _entries.values) {
      for (final t in e.tags) {
        seen.putIfAbsent(t.toLowerCase(), () => t);
      }
    }
    return seen.values.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  /// Saves pending changes. Returns false when nothing could be saved.
  Future<bool> flush() async {
    if (!_dirty) return true;
    if (_blocked) return false;
    _lastSave = _clock();
    try {
      await _store.setString(storageKey,
          jsonEncode([for (final e in _entries.values) e.toJson()]));
      _dirty = false;
      return true;
    } catch (_) {
      return false;
    }
  }
}
