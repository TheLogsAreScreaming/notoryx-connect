import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'bastion_geo.dart';
import 'meshtastic_node_database.dart';

/// One recorded position of a node.
class TrailPoint {
  const TrailPoint(this.latitude, this.longitude, this.time);

  final double latitude;
  final double longitude;
  final DateTime time;

  List<num> toJson() => [latitude, longitude, time.millisecondsSinceEpoch ~/ 1000];

  static TrailPoint fromJson(Object? json) {
    final list = json! as List;
    return TrailPoint((list[0] as num).toDouble(), (list[1] as num).toDouble(),
        DateTime.fromMillisecondsSinceEpoch((list[2] as int) * 1000));
  }
}

/// Recent movement trails for trip contacts and this radio, kept per radio.
///
/// A point is added when a tracked node reports a position at least
/// [minMoveMeters] from its last point. Trails keep [keep] of history and at
/// most [maxPoints] per node. Saving is throttled to [saveEvery] so moving
/// nodes don't wear storage; [flush] saves anything pending.
class BastionTrails {
  BastionTrails({SharedPreferencesAsync? preferences, DateTime Function()? clock})
      : _preferences = preferences,
        _clock = clock ?? DateTime.now;

  static const minMoveMeters = 15.0;
  static const maxPoints = 300;
  static const keep = Duration(hours: 24);
  static const saveEvery = Duration(seconds: 30);

  static String key(int radio) =>
      'bastion.trails.v1.radio.${radio.toRadixString(16).padLeft(8, '0')}';

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();
  final DateTime Function() _clock;
  final Map<int, List<TrailPoint>> _trails = {};
  int? _radio;
  bool _loadFailed = false;
  bool _dirty = false;
  DateTime? _lastSave;

  /// The trail of [num], oldest first; empty when nothing is recorded.
  List<TrailPoint> trailOf(int num) => List.unmodifiable(_trails[num] ?? const []);

  /// Shows [radio]'s trails, saving the previous radio's first.
  Future<void> useRadio(int radio) async {
    if (radio == _radio) return;
    await flush();
    _radio = radio;
    _trails.clear();
    _loadFailed = false;
    try {
      final raw = await _store.getString(key(radio));
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, Object?>;
      for (final e in map.entries) {
        final num = int.tryParse(e.key);
        if (num == null) continue;
        try {
          _trails[num] = [for (final p in e.value! as List) TrailPoint.fromJson(p)];
        } catch (_) {
          // Skip a damaged trail; the others still load.
        }
      }
      _prune(_clock());
    } on FormatException {
      // Damaged storage is replaced by the next save.
    } catch (_) {
      _loadFailed = true; // Storage unreadable: never overwrite it this session.
    }
  }

  /// Records new positions of [tracked] nodes; returns whether any trail grew.
  bool record(Iterable<MeshtasticNode> nodes, Set<int> tracked) {
    if (_radio == null || tracked.isEmpty) return false;
    final now = _clock();
    var changed = false;
    for (final node in nodes) {
      if (!tracked.contains(node.num) || !node.hasPosition) continue;
      final trail = _trails.putIfAbsent(node.num, () => []);
      final last = trail.isEmpty ? null : trail.last;
      if (last != null &&
          BastionGeo.distanceMeters(last.latitude, last.longitude, node.latitude!, node.longitude!) <
              minMoveMeters) {
        continue;
      }
      trail.add(TrailPoint(node.latitude!, node.longitude!, now));
      changed = true;
    }
    if (!changed) return false;
    _prune(now);
    _dirty = true;
    if (_lastSave == null || now.difference(_lastSave!) >= saveEvery) unawaited(flush());
    return true;
  }

  void _prune(DateTime now) {
    for (final trail in _trails.values) {
      trail.removeWhere((p) => now.difference(p.time) > keep);
      if (trail.length > maxPoints) trail.removeRange(0, trail.length - maxPoints);
    }
    _trails.removeWhere((_, trail) => trail.isEmpty);
  }

  /// Saves pending points now.
  Future<void> flush() async {
    final radio = _radio;
    if (!_dirty || radio == null || _loadFailed) return;
    _dirty = false;
    _lastSave = _clock();
    try {
      await _store.setString(key(radio), jsonEncode({
        for (final e in _trails.entries) '${e.key}': [for (final p in e.value) p.toJson()],
      }));
    } catch (_) {
      _dirty = true; // Try again on the next point.
    }
  }
}
