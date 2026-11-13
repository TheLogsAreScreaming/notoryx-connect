import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'bastion_geo.dart';
import 'bastion_trails.dart';
import 'meshtastic_node_database.dart';

/// Where someone was at one moment of a replay.
class ReplayFix {
  const ReplayFix(this.latitude, this.longitude, this.fixTime, {required this.moving});
  final double latitude;
  final double longitude;

  /// The last real position report at or before the replay time.
  final DateTime fixTime;

  /// True when the replay time falls between two reports and the position
  /// is estimated along the straight line between them.
  final bool moving;
}

/// Pure helpers for playing a day of tracks back.
abstract final class DayReplay {
  /// [track]'s position at [t]: interpolated between reports, held at the
  /// last report afterwards, null before the first. [track] is oldest first.
  static ReplayFix? positionAt(List<TrailPoint> track, DateTime t) {
    if (track.isEmpty || t.isBefore(track.first.time)) return null;
    for (var i = 0; i < track.length - 1; i++) {
      final a = track[i], b = track[i + 1];
      if (t.isBefore(b.time)) {
        final span = b.time.difference(a.time).inMilliseconds;
        final f = span <= 0 ? 0.0 : t.difference(a.time).inMilliseconds / span;
        return ReplayFix(
          a.latitude + (b.latitude - a.latitude) * f,
          a.longitude + (b.longitude - a.longitude) * f,
          a.time,
          moving: f > 0,
        );
      }
    }
    final last = track.last;
    return ReplayFix(last.latitude, last.longitude, last.time, moving: false);
  }

  /// The part of [track] walked by [t], ending at the replay position.
  static List<TrailPoint> walked(List<TrailPoint> track, DateTime t) {
    final at = positionAt(track, t);
    if (at == null) return const [];
    return [
      for (final p in track) if (!p.time.isAfter(t)) p,
      if (at.moving) TrailPoint(at.latitude, at.longitude, t),
    ];
  }

  /// Metres covered along [points].
  static double distance(List<TrailPoint> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += BastionGeo.distanceMeters(points[i - 1].latitude, points[i - 1].longitude,
          points[i].latitude, points[i].longitude);
    }
    return total;
  }

  /// Earliest and latest report across [tracks]; null when there are none.
  static ({DateTime start, DateTime end})? span(Map<int, List<TrailPoint>> tracks) {
    DateTime? start, end;
    for (final t in tracks.values) {
      if (t.isEmpty) continue;
      if (start == null || t.first.time.isBefore(start)) start = t.first.time;
      if (end == null || t.last.time.isAfter(end)) end = t.last.time;
    }
    return start == null ? null : (start: start, end: end!);
  }
}

/// Team members' positions kept by local calendar day, for day replay.
///
/// Records trip contacts and this radio, like the 24-hour trails, but keeps
/// [keepDays] days. A point is added when someone moves [minMoveMeters] or
/// [heartbeat] has passed, so a stop still shows on the timeline.
class BastionDayTracks {
  BastionDayTracks({SharedPreferencesAsync? preferences, DateTime Function()? clock})
      : _preferences = preferences,
        _clock = clock ?? DateTime.now;

  static const keepDays = 14;
  static const minMoveMeters = 10.0;
  static const heartbeat = Duration(minutes: 10);
  static const maxPointsPerDay = 2000;
  static const saveEvery = Duration(seconds: 30);
  static const indexKey = 'bastion.daytracks.v1.days';
  static String dayKey(DateTime day) => 'bastion.daytracks.v1.${dayName(day)}';

  /// "2026-11-13" for the local day containing [t].
  static String dayName(DateTime t) {
    final d = t.toLocal();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();
  final DateTime Function() _clock;

  /// Days with tracks, by name, and the loaded tracks of each.
  final Set<String> _days = {};
  final Map<String, Map<int, List<TrailPoint>>> _loaded = {};
  final Set<String> _dirtyDays = {};
  bool _indexLoaded = false;
  bool _blocked = false;
  DateTime? _lastSave;

  Future<void> _loadIndex() async {
    if (_indexLoaded) return;
    _indexLoaded = true;
    try {
      final raw = await _store.getString(indexKey);
      if (raw != null) _days.addAll([for (final d in jsonDecode(raw) as List) d as String]);
    } on FormatException {
      // A damaged index is rebuilt from the days recorded from now on.
    } catch (_) {
      _blocked = true;
    }
  }

  /// Local days with at least one recorded position, newest first.
  Future<List<DateTime>> days() async {
    await _loadIndex();
    final names = {..._days, ..._loaded.keys}.toList()..sort((a, b) => b.compareTo(a));
    return [for (final n in names) DateTime.parse(n)];
  }

  Map<int, List<TrailPoint>> _decode(String raw) {
    final map = jsonDecode(raw) as Map<String, Object?>;
    final tracks = <int, List<TrailPoint>>{};
    for (final e in map.entries) {
      final num = int.tryParse(e.key);
      if (num == null) continue;
      try {
        tracks[num] = [for (final p in e.value! as List) TrailPoint.fromJson(p)];
      } catch (_) {
        // A damaged track is skipped; the others still play.
      }
    }
    return tracks;
  }

  Future<Map<int, List<TrailPoint>>> _day(String name) async {
    final cached = _loaded[name];
    if (cached != null) return cached;
    var tracks = <int, List<TrailPoint>>{};
    try {
      final raw = await _store.getString('bastion.daytracks.v1.$name');
      if (raw != null) tracks = _decode(raw);
    } on FormatException {
      // Start the day again.
    } catch (_) {
      _blocked = true;
    }
    return _loaded[name] ??= tracks;
  }

  /// Every member's track on [day], oldest point first.
  Future<Map<int, List<TrailPoint>>> tracksOn(DateTime day) async {
    final tracks = await _day(dayName(day));
    return {for (final e in tracks.entries) e.key: List.unmodifiable(e.value)};
  }

  /// Records new positions of [tracked] nodes from [nodes].
  Future<bool> record(Iterable<MeshtasticNode> nodes, Set<int> tracked) async {
    if (tracked.isEmpty) return false;
    await _loadIndex();
    final now = _clock();
    var changed = false;
    for (final node in nodes) {
      if (!tracked.contains(node.num) || !node.hasPosition) continue;
      final reported = node.positionTime;
      final at = reported != null && !reported.isAfter(now.add(const Duration(minutes: 1))) &&
              now.difference(reported) < const Duration(hours: 24)
          ? reported
          : now;
      final name = dayName(at);
      final track = (await _day(name)).putIfAbsent(node.num, () => []);
      final last = track.isEmpty ? null : track.last;
      if (last != null) {
        if (!at.isAfter(last.time)) continue;
        final moved = BastionGeo.distanceMeters(
            last.latitude, last.longitude, node.latitude!, node.longitude!);
        if (moved < minMoveMeters && at.difference(last.time) < heartbeat) continue;
      }
      track.add(TrailPoint(node.latitude!, node.longitude!, at));
      if (track.length > maxPointsPerDay) track.removeRange(0, track.length - maxPointsPerDay);
      _days.add(name);
      _dirtyDays.add(name);
      changed = true;
    }
    if (changed && (_lastSave == null || now.difference(_lastSave!) >= saveEvery)) await flush();
    return changed;
  }

  /// Saves pending days and forgets days older than [keepDays].
  Future<bool> flush() async {
    if (_blocked) return false;
    final now = _clock();
    _lastSave = now;
    final oldest = dayName(DateTime(now.year, now.month, now.day - keepDays + 1));
    final expired = [for (final d in _days) if (d.compareTo(oldest) < 0) d];
    try {
      for (final d in expired) {
        await _store.remove('bastion.daytracks.v1.$d');
        _days.remove(d);
        _loaded.remove(d);
        _dirtyDays.remove(d);
      }
      for (final d in _dirtyDays.toList()) {
        final tracks = _loaded[d];
        if (tracks == null) continue;
        await _store.setString('bastion.daytracks.v1.$d', jsonEncode({
          for (final e in tracks.entries) '${e.key}': [for (final p in e.value) p.toJson()],
        }));
        _dirtyDays.remove(d);
      }
      await _store.setString(indexKey, jsonEncode(_days.toList()..sort()));
      return true;
    } catch (_) {
      return false;
    }
  }
}
