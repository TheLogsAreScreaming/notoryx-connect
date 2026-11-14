import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'meshtastic_node_database.dart';

double? _toDouble(Object? value) => value is num ? value.toDouble() : null;

class BastionNodeRecord {
  const BastionNodeRecord({
    required this.num,
    required this.firstSeen,
    required this.lastSeen,
    required this.encounters,
    this.id,
    this.longName,
    this.shortName,
    this.hardwareModel,
    this.favorite = false,
    this.note = '',
    this.latitude,
    this.longitude,
    this.positionTime,
  });

  final int num;
  final String? id;
  final String? longName;
  final String? shortName;
  final int? hardwareModel;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int encounters;
  final bool favorite;
  final String note;

  /// Where the node last reported, kept after the radio forgets it.
  final double? latitude;
  final double? longitude;
  final DateTime? positionTime;

  bool get hasPosition => latitude != null && longitude != null;

  String get displayName => (longName?.isNotEmpty ?? false)
      ? longName!
      : (id ?? '!${num.toRadixString(16).padLeft(8, '0')}');

  BastionNodeRecord copyWith({
    String? id, String? longName, String? shortName, int? hardwareModel,
    DateTime? lastSeen, int? encounters, bool? favorite, String? note,
    double? latitude, double? longitude, DateTime? positionTime,
  }) => BastionNodeRecord(
    num: num, id: id ?? this.id, longName: longName ?? this.longName,
    shortName: shortName ?? this.shortName,
    hardwareModel: hardwareModel ?? this.hardwareModel,
    firstSeen: firstSeen, lastSeen: lastSeen ?? this.lastSeen,
    encounters: encounters ?? this.encounters,
    favorite: favorite ?? this.favorite, note: note ?? this.note,
    latitude: latitude ?? this.latitude, longitude: longitude ?? this.longitude,
    positionTime: positionTime ?? this.positionTime,
  );

  Map<String, Object?> toJson() => {
    'num': num, 'id': id, 'longName': longName, 'shortName': shortName,
    'hardwareModel': hardwareModel,
    'firstSeen': firstSeen.toUtc().toIso8601String(),
    'lastSeen': lastSeen.toUtc().toIso8601String(),
    'encounters': encounters, 'favorite': favorite, 'note': note,
    if (hasPosition) 'lat': latitude,
    if (hasPosition) 'lon': longitude,
    if (positionTime != null) 'positionTime': positionTime!.toUtc().toIso8601String(),
  };

  static BastionNodeRecord fromJson(Map<String, Object?> json) =>
      BastionNodeRecord(
        num: json['num']! as int, id: json['id'] as String?,
        longName: json['longName'] as String?,
        shortName: json['shortName'] as String?,
        hardwareModel: json['hardwareModel'] as int?,
        firstSeen: DateTime.parse(json['firstSeen']! as String).toLocal(),
        lastSeen: DateTime.parse(json['lastSeen']! as String).toLocal(),
        encounters: json['encounters']! as int,
        favorite: json['favorite'] as bool? ?? false,
        note: json['note'] as String? ?? '',
        latitude: _toDouble(json['lat']),
        longitude: _toDouble(json['lon']),
        positionTime: json['positionTime'] == null ? null : DateTime.tryParse(json['positionTime']! as String)?.toLocal(),
      );
}

/// Nodes this phone has seen, kept per connected radio.
///
/// Encounter history (first/last seen, count) belongs to the radio that heard
/// the node. Favorites and notes describe the remote node itself, so they are
/// shared across radios. History saved before this split moves to the first
/// radio that connects; the original is kept under `$legacyKey.migrated`.
class BastionNodeVault {
  BastionNodeVault({SharedPreferencesAsync? preferences})
      : _preferences = preferences;

  static const legacyKey = 'bastion.nodevault.v1';
  static const annotationsKey = 'bastion.nodevault.annotations.v1';
  static String radioKey(int radio) =>
      'bastion.nodevault.v2.radio.${radio.toRadixString(16).padLeft(8, '0')}';

  static const _prefix = 'bastion.nodevault.';

  /// The prefix older builds saved under, before the list was renamed.
  static const _formerPrefix = 'bastion.node' 'dex.';

  /// Moves anything saved under the former key names (older builds, or a
  /// restored older backup) to the current names, then removes the old keys.
  /// A value already saved under the current name is kept. Safe to call often.
  static Future<void> migrateStoredKeys(SharedPreferencesAsync store) async {
    final Set<String> keys;
    try {
      keys = await store.getKeys();
    } on Object catch (e) {
      debugPrint('NodeVault: stored keys unavailable: $e');
      return;
    }
    for (final key in keys) {
      if (!key.startsWith(_formerPrefix)) continue;
      final target = _prefix + key.substring(_formerPrefix.length);
      try {
        final value = await store.getString(key);
        if (value != null && await store.getString(target) == null) {
          await store.setString(target, value);
        }
      } on Object catch (e, s) {
        debugPrint('NodeVault: could not move $key: $e\n$s');
        continue;
      }
      await store.remove(key);
    }
  }

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();
  final Map<int, BastionNodeRecord> _records = {};
  final Map<int, ({bool favorite, String note})> _annotations = {};
  int? _radio;
  bool _annotationsLoaded = false;
  bool _recordsBlocked = false;
  bool _annotationsBlocked = false;
  bool _positionsDirty = false;
  DateTime? _positionsSavedAt;

  /// The radio whose encounters are shown; null before any radio connected.
  int? get radio => _radio;

  List<BastionNodeRecord> get records {
    final result = [
      for (final r in _records.values)
        if (_annotations[r.num] case final a?)
          r.copyWith(favorite: a.favorite, note: a.note)
        else
          r,
    ]..sort((a, b) {
        if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
        return b.lastSeen.compareTo(a.lastSeen);
      });
    return List.unmodifiable(result);
  }

  /// Loads unassigned (pre-split) history; used before any radio connected.
  Future<void> load() => useRadio(null);

  /// Shows [radio]'s encounters, first moving any unassigned history to it.
  /// Nodes observed while no radio was attached are merged in.
  Future<void> useRadio(int? radio) async {
    try {
      await migrateStoredKeys(_store);
    } on Object catch (e) {
      debugPrint('NodeVault: could not move stored keys: $e');
    }
    final observed = _radio == null && radio != null ? Map.of(_records) : <int, BastionNodeRecord>{};
    _radio = radio;
    _records.clear();
    _recordsBlocked = false;
    await _loadAnnotations();
    final key = radio == null ? legacyKey : radioKey(radio);
    final stored = await _read(key);
    if (stored == null) {
      _recordsBlocked = true;
      return;
    }
    _records.addAll(stored);
    if (radio == null) return;

    final legacy = await _read(legacyKey);
    final migrate = legacy != null && legacy.isNotEmpty;
    if (migrate) {
      for (final r in legacy.values) {
        _records[r.num] = _merge(_records[r.num], r);
        if (r.favorite || r.note.isNotEmpty) {
          _annotations.putIfAbsent(r.num, () => (favorite: r.favorite, note: r.note));
        }
      }
    }
    for (final r in observed.values) {
      _records[r.num] = _merge(_records[r.num], r);
    }
    if (!migrate && observed.isEmpty) return;
    final saved = await _saveRecords() & await _saveAnnotations();
    if (migrate && saved) {
      try {
        final raw = await _store.getString(legacyKey);
        if (raw != null) await _store.setString('$legacyKey.migrated', raw);
        await _store.remove(legacyKey);
      } catch (_) {
        // The radio copy is saved; a later migration merges, not duplicates.
      }
    }
  }

  /// Merges [from]'s encounters into the current radio's and saves them.
  /// Returns false when either could not be read or saved.
  Future<bool> importRadio(int from) async {
    if (_radio == null || _recordsBlocked) return false;
    final stored = await _read(radioKey(from));
    if (stored == null) return false;
    for (final r in stored.values) {
      _records[r.num] = _merge(_records[r.num], r);
    }
    return _saveRecords();
  }

  /// Keeps observing in memory without a radio (between connect and the
  /// radio identifying itself); [useRadio] then saves them to that radio.
  void detach() {
    if (_radio == null) return;
    _radio = null;
    _records.clear();
  }

  static BastionNodeRecord _merge(BastionNodeRecord? a, BastionNodeRecord b) {
    if (a == null) return b;
    final newer = b.lastSeen.isAfter(a.lastSeen) ? b : a;
    final placed = !a.hasPosition ? b : !b.hasPosition ? a : (b.positionTime ?? b.lastSeen).isAfter(a.positionTime ?? a.lastSeen) ? b : a;
    return BastionNodeRecord(
      num: a.num, id: newer.id ?? a.id ?? b.id,
      longName: newer.longName ?? a.longName ?? b.longName,
      shortName: newer.shortName ?? a.shortName ?? b.shortName,
      hardwareModel: newer.hardwareModel ?? a.hardwareModel ?? b.hardwareModel,
      firstSeen: a.firstSeen.isBefore(b.firstSeen) ? a.firstSeen : b.firstSeen,
      lastSeen: newer.lastSeen, encounters: a.encounters + b.encounters,
      latitude: placed.latitude, longitude: placed.longitude, positionTime: placed.positionTime,
    );
  }

  /// Reads records stored under [key]; null when storage could not be read.
  Future<Map<int, BastionNodeRecord>?> _read(String key) async {
    final String? raw;
    try {
      raw = await _store.getString(key);
    } catch (_) {
      return null;
    }
    final result = <int, BastionNodeRecord>{};
    if (raw == null) return result;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return result;
      for (final item in decoded) {
        try {
          final record = BastionNodeRecord.fromJson(Map<String, Object?>.from(item as Map));
          result[record.num] = record;
        } catch (_) {
          // One malformed record must not hide the rest.
        }
      }
    } on FormatException {
      return result;
    }
    return result;
  }

  Future<void> _loadAnnotations() async {
    if (_annotationsLoaded) return;
    _annotationsLoaded = true;
    try {
      final raw = await _store.getString(annotationsKey);
      if (raw == null) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      decoded.forEach((k, v) {
        final num = int.tryParse('$k');
        if (num != null && v is Map) {
          _annotations[num] = (favorite: v['favorite'] == true, note: v['note'] as String? ?? '');
        }
      });
    } on FormatException {
      // Damaged notes are replaced on the next change.
    } catch (_) {
      _annotationsBlocked = true;
    }
  }

  Future<void> observe(MeshtasticNode node) async {
    final now = DateTime.now();
    final old = _records[node.num];
    _records[node.num] = old == null
        ? BastionNodeRecord(
            num: node.num, id: node.id, longName: node.longName,
            shortName: node.shortName, hardwareModel: node.hardwareModel,
            firstSeen: now, lastSeen: now, encounters: 1)
        : old.copyWith(
            id: node.id, longName: node.longName, shortName: node.shortName,
            hardwareModel: node.hardwareModel, lastSeen: now,
            encounters: old.encounters + 1);
    if (_radio != null) await _saveRecords();
  }

  /// Copies the latest positions of known nodes, so they survive the radio's
  /// own node list dropping them. Saved at most once a minute.
  Future<void> rememberPositions(Iterable<MeshtasticNode> nodes, {DateTime? now}) async {
    var changed = false;
    for (final node in nodes) {
      final old = _records[node.num];
      if (old == null || !node.hasPosition) continue;
      if (old.latitude == node.latitude && old.longitude == node.longitude) continue;
      _records[node.num] = old.copyWith(
          latitude: node.latitude, longitude: node.longitude, positionTime: node.positionTime);
      changed = true;
    }
    if (changed) _positionsDirty = true;
    final at = now ?? DateTime.now();
    final last = _positionsSavedAt;
    if (!_positionsDirty || (last != null && at.difference(last) < const Duration(minutes: 1))) return;
    _positionsSavedAt = at;
    if (await _saveRecords()) _positionsDirty = false;
  }

  Future<void> setFavorite(int num, bool value) async {
    if (!_records.containsKey(num)) return;
    final old = _annotations[num];
    _annotations[num] = (favorite: value, note: old?.note ?? '');
    await _saveAnnotations();
  }

  Future<void> setNote(int num, String value) async {
    if (!_records.containsKey(num)) return;
    final old = _annotations[num];
    _annotations[num] = (favorite: old?.favorite ?? false, note: value.trim());
    await _saveAnnotations();
  }

  Future<bool> _saveRecords() async {
    final radio = _radio;
    if (radio == null || _recordsBlocked) return false;
    try {
      await _store.setString(radioKey(radio), jsonEncode(
        _records.values.map((r) => r.copyWith(favorite: false, note: '').toJson()).toList()));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _saveAnnotations() async {
    if (_annotationsBlocked) return false;
    try {
      await _store.setString(annotationsKey, jsonEncode({
        for (final e in _annotations.entries)
          if (e.value.favorite || e.value.note.isNotEmpty)
            '${e.key}': {'favorite': e.value.favorite, 'note': e.value.note},
      }));
      return true;
    } catch (_) {
      return false;
    }
  }
}
