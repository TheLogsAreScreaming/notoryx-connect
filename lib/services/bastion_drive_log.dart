import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show databaseFactoryFfi, sqfliteFfiInit;

import '../generated/meshtastic/mesh.pb.dart' as pb;
import 'bastion_phone_position.dart';

/// How a packet reached this radio.
enum HopClass {
  /// Heard straight from the sender: proves RF coverage to that node.
  direct,

  /// Passed on by at least one other node: proves coverage only to the
  /// last relayer, whose ID is known by its last byte at most.
  relayed,

  /// The sender's firmware doesn't say (before 2.3.0, `hop_start` is 0).
  unknown,
}

/// Classifies a packet from its hop fields. `hop_start` is the hop limit
/// the sender used; each relay takes one off `hop_limit`.
HopClass classifyHops(int hopStart, int hopLimit) {
  if (hopStart <= 0 || hopLimit < 0 || hopLimit > hopStart) return HopClass.unknown;
  return hopStart == hopLimit ? HopClass.direct : HopClass.relayed;
}

/// One drive, Start to Stop.
@immutable
class DriveTrip {
  const DriveTrip({required this.id, required this.name, required this.started, this.ended, this.radio});

  final int id;
  final String name;
  final DateTime started;
  final DateTime? ended;
  final int? radio;

  bool get running => ended == null;

  Map<String, Object?> toRow() => {
    'id': id,
    'name': name,
    'started': started.toUtc().toIso8601String(),
    'ended': ended?.toUtc().toIso8601String(),
    'radio': radio,
  };

  static DriveTrip fromRow(Map<String, Object?> r) => DriveTrip(
    id: r['id']! as int,
    name: r['name']! as String,
    started: DateTime.parse(r['started']! as String),
    ended: r['ended'] == null ? null : DateTime.parse(r['ended']! as String),
    radio: r['radio'] as int?,
  );
}

/// One packet heard during a drive. The position is always the phone's,
/// never the sender's.
@immutable
class DriveSample {
  const DriveSample({
    required this.trip,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.from,
    required this.hops,
    this.accuracyMeters,
    this.packetId,
    this.port,
    this.channel,
    this.snr,
    this.rssi,
    this.hopStart,
    this.hopLimit,
    this.relayByte,
  });

  final int trip;
  final DateTime time;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final int from;
  final int? packetId;
  final int? port;
  final int? channel;
  final double? snr;
  final int? rssi;
  final int? hopStart;
  final int? hopLimit;
  final HopClass hops;

  /// Last byte of the node that passed the packet on, when the firmware
  /// says. A hint, not an ID: many nodes share each byte.
  final int? relayByte;

  Map<String, Object?> toRow() => {
    'trip': trip,
    'ts': time.toUtc().toIso8601String(),
    'lat': latitude,
    'lon': longitude,
    'accuracy': accuracyMeters,
    'from_node': from,
    'packet': packetId,
    'port': port,
    'channel': channel,
    'snr': snr,
    'rssi': rssi,
    'hop_start': hopStart,
    'hop_limit': hopLimit,
    'class': hops.name,
    'relay': relayByte,
  };

  static DriveSample fromRow(Map<String, Object?> r) => DriveSample(
    trip: r['trip']! as int,
    time: DateTime.parse(r['ts']! as String),
    latitude: (r['lat']! as num).toDouble(),
    longitude: (r['lon']! as num).toDouble(),
    accuracyMeters: (r['accuracy'] as num?)?.toDouble(),
    from: r['from_node']! as int,
    packetId: r['packet'] as int?,
    port: r['port'] as int?,
    channel: r['channel'] as int?,
    snr: (r['snr'] as num?)?.toDouble(),
    rssi: r['rssi'] as int?,
    hopStart: r['hop_start'] as int?,
    hopLimit: r['hop_limit'] as int?,
    hops: HopClass.values.asNameMap()[r['class']] ?? HopClass.unknown,
    relayByte: r['relay'] as int?,
  );
}

/// Where trips and samples are kept.
abstract interface class DriveLogStore {
  Future<List<DriveTrip>> trips();
  Future<List<DriveSample>> samples();
  Future<int> addTrip(String name, DateTime started, int? radio);
  Future<void> endTrip(int id, DateTime ended);
  Future<void> addSamples(List<DriveSample> samples);
  Future<void> deleteTrip(int id);
}

/// Kept in memory only: tests, and phones where the database won't open.
class MemoryDriveLogStore implements DriveLogStore {
  final _trips = <DriveTrip>[];
  final _samples = <DriveSample>[];
  var _next = 1;

  @override
  Future<List<DriveTrip>> trips() async => List.of(_trips);
  @override
  Future<List<DriveSample>> samples() async => List.of(_samples);
  @override
  Future<int> addTrip(String name, DateTime started, int? radio) async {
    final id = _next++;
    _trips.add(DriveTrip(id: id, name: name, started: started, radio: radio));
    return id;
  }

  @override
  Future<void> endTrip(int id, DateTime ended) async {
    final i = _trips.indexWhere((t) => t.id == id);
    if (i < 0) return;
    final t = _trips[i];
    _trips[i] = DriveTrip(id: t.id, name: t.name, started: t.started, ended: ended, radio: t.radio);
  }

  @override
  Future<void> addSamples(List<DriveSample> samples) async => _samples.addAll(samples);
  @override
  Future<void> deleteTrip(int id) async {
    _trips.removeWhere((t) => t.id == id);
    _samples.removeWhere((s) => s.trip == id);
  }
}

/// Trips and samples in an SQLite database, one row per sample.
class SqliteDriveLogStore implements DriveLogStore {
  SqliteDriveLogStore._(this._db);
  final Database _db;

  static const schemaVersion = 1;

  static Future<SqliteDriveLogStore> open(DatabaseFactory factory, String path) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: (db, _) async {
          await db.execute(
            'CREATE TABLE trips (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, '
            'started TEXT NOT NULL, ended TEXT, radio INTEGER)',
          );
          await db.execute(
            'CREATE TABLE samples (id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'trip INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE, ts TEXT NOT NULL, '
            'lat REAL NOT NULL, lon REAL NOT NULL, accuracy REAL, from_node INTEGER NOT NULL, '
            'packet INTEGER, port INTEGER, channel INTEGER, snr REAL, rssi INTEGER, '
            'hop_start INTEGER, hop_limit INTEGER, class TEXT NOT NULL, relay INTEGER)',
          );
          await db.execute('CREATE INDEX samples_trip ON samples (trip, ts)');
        },
      ),
    );
    return SqliteDriveLogStore._(db);
  }

  Future<void> close() => _db.close();

  @override
  Future<List<DriveTrip>> trips() async => [
    for (final r in await _db.query('trips', orderBy: 'id')) DriveTrip.fromRow(r),
  ];
  @override
  Future<List<DriveSample>> samples() async => [
    for (final r in await _db.query('samples', orderBy: 'id')) DriveSample.fromRow(r),
  ];
  @override
  Future<int> addTrip(String name, DateTime started, int? radio) =>
      _db.insert('trips', {'name': name, 'started': started.toUtc().toIso8601String(), 'radio': radio});
  @override
  Future<void> endTrip(int id, DateTime ended) =>
      _db.update('trips', {'ended': ended.toUtc().toIso8601String()}, where: 'id = ?', whereArgs: [id]);
  @override
  Future<void> addSamples(List<DriveSample> samples) => _db.transaction((txn) async {
    final batch = txn.batch();
    for (final s in samples) {
      batch.insert('samples', s.toRow());
    }
    await batch.commit(noResult: true);
  });
  @override
  Future<void> deleteTrip(int id) => _db.transaction((txn) async {
    await txn.delete('samples', where: 'trip = ?', whereArgs: [id]);
    await txn.delete('trips', where: 'id = ?', whereArgs: [id]);
  });
}

/// Drive recording: every RF packet the radio hears while a drive runs is
/// saved with the phone's position, signal and how many hops it took.
/// Kept on this phone only; nothing is sent.
class BastionDriveLog extends ChangeNotifier {
  BastionDriveLog({DriveLogStore? store}) : _store = store ?? MemoryDriveLogStore();

  static final instance = BastionDriveLog();

  /// The oldest finished trips are dropped beyond this many.
  static const maxTrips = 200;

  /// The oldest finished trips are dropped while samples exceed this.
  static const maxSamples = 100000;

  /// A node is logged at most once per square of this size...
  static const throttleCellMeters = 100.0;

  /// ...within this long.
  static const throttleWindow = Duration(seconds: 60);

  /// Name of the trip that holds readings from before trips existed.
  static const earlierTripName = 'Earlier readings';

  static const _importedPref = 'bastion.drive_log.imported';
  static const _oldLogPref = 'bastion.field_log.v1';

  DriveLogStore _store;
  final _trips = <DriveTrip>[];
  final _samples = <DriveSample>[];
  final _lastLogged = <(int, int, int), DateTime>{};
  Future<void> _pending = Future.value();
  int? _radio;
  String? error;

  /// Trips, oldest first.
  List<DriveTrip> get trips => List.unmodifiable(_trips);

  /// Every saved sample, oldest first.
  List<DriveSample> get samples => List.unmodifiable(_samples);

  DriveTrip? get current => _trips.where((t) => t.running).lastOrNull;
  bool get recording => current != null;

  /// Samples of [trip], or of every trip.
  Iterable<DriveSample> samplesOf({int? trip}) => trip == null ? _samples : _samples.where((s) => s.trip == trip);

  /// Swaps the store, for tests. Call [load] afterwards.
  @visibleForTesting
  void useStore(DriveLogStore store) {
    _store = store;
    _trips.clear();
    _samples.clear();
    _lastLogged.clear();
    _radio = null;
  }

  /// Opens the database (falling back to memory), loads it and moves
  /// coverage readings from the old field log over once.
  Future<void> load({DatabaseFactory? factory, String? path, bool useDatabase = true}) async {
    error = null;
    if (useDatabase) {
      try {
        if (!kIsWeb && Platform.isWindows) sqfliteFfiInit();
        final db = factory ?? (!kIsWeb && Platform.isWindows ? databaseFactoryFfi : databaseFactory);
        _store = await SqliteDriveLogStore.open(db, path ?? '${await db.getDatabasesPath()}/notoryx_drives.db');
      } catch (e) {
        debugPrint('Drive database unavailable, keeping drives in memory: $e');
      }
    }
    try {
      _trips
        ..clear()
        ..addAll(await _store.trips());
      _samples
        ..clear()
        ..addAll(await _store.samples());
      // A drive left running by a crash or a killed app is closed, not resumed.
      for (final t in List.of(_trips.where((t) => t.running))) {
        final end = _samples.where((s) => s.trip == t.id).lastOrNull?.time ?? t.started;
        await _store.endTrip(t.id, end);
        _trips[_trips.indexOf(t)] = DriveTrip(id: t.id, name: t.name, started: t.started, ended: end, radio: t.radio);
      }
      await _importOldReadings();
    } catch (e) {
      error = 'Saved drives could not be loaded. Recording is disabled.';
    }
    notifyListeners();
  }

  /// Copies coverage readings from the old field log into one finished
  /// trip, once. Their hop count was never saved, so they are "unknown".
  Future<void> _importOldReadings() async {
    final prefs = SharedPreferencesAsync();
    if (await prefs.getBool(_importedPref) == true) return;
    final raw = await prefs.getString(_oldLogPref);
    final old = <Map<String, Object?>>[];
    if (raw != null) {
      try {
        for (final e in jsonDecode(raw) as List) {
          final r = Map<String, Object?>.from(e as Map);
          if (r['kind'] == 'coverage' && r['lat'] is num && r['lon'] is num && r['from'] is int && r['time'] is String)
            old.add(r);
        }
      } catch (_) {
        // Unreadable old data is left where it is.
      }
    }
    if (old.isNotEmpty) {
      old.sort((a, b) => (a['time']! as String).compareTo(b['time']! as String));
      final start = DateTime.parse(old.first['time']! as String);
      final end = DateTime.parse(old.last['time']! as String);
      final id = await _store.addTrip(earlierTripName, start, old.first['radio'] as int?);
      await _store.endTrip(id, end);
      final imported = [
        for (final r in old)
          DriveSample(
            trip: id,
            time: DateTime.parse(r['time']! as String),
            latitude: (r['lat']! as num).toDouble(),
            longitude: (r['lon']! as num).toDouble(),
            accuracyMeters: (r['accuracy'] as num?)?.toDouble(),
            from: r['from']! as int,
            packetId: r['packet'] as int?,
            snr: (r['snr'] as num?)?.toDouble(),
            rssi: (r['rssi'] as num?)?.toInt(),
            hops: HopClass.unknown,
          ),
      ];
      await _store.addSamples(imported);
      _trips.add(
        DriveTrip(id: id, name: earlierTripName, started: start, ended: end, radio: old.first['radio'] as int?),
      );
      _samples.addAll(imported);
    }
    await prefs.setBool(_importedPref, true);
  }

  /// Starts a new trip for [radio]. Does nothing if one is running.
  Future<DriveTrip> start(int radio, {String? name, DateTime? now}) async {
    if (error != null) throw StateError(error!);
    final running = current;
    if (running != null) return running;
    final at = (now ?? DateTime.now()).toUtc();
    final label = name?.trim().isNotEmpty == true ? name!.trim() : _defaultName(at.toLocal());
    final id = await _store.addTrip(label, at, radio);
    final trip = DriveTrip(id: id, name: label, started: at, radio: radio);
    _trips.add(trip);
    _radio = radio;
    _lastLogged.clear();
    await _enforceLimits();
    notifyListeners();
    return trip;
  }

  /// Ends the running trip, if any.
  Future<void> stop({DateTime? now}) async {
    final running = current;
    _radio = null;
    _lastLogged.clear();
    if (running == null) return;
    final at = (now ?? DateTime.now()).toUtc();
    final i = _trips.indexOf(running);
    _trips[i] = DriveTrip(
      id: running.id,
      name: running.name,
      started: running.started,
      ended: at,
      radio: running.radio,
    );
    notifyListeners();
    try {
      await _store.endTrip(running.id, at);
    } catch (_) {
      error = 'The drive could not be saved.';
      notifyListeners();
    }
  }

  /// Deletes a finished trip and its samples.
  Future<void> deleteTrip(int id) async {
    if (current?.id == id) throw StateError('Stop the drive before deleting it.');
    await _store.deleteTrip(id);
    _trips.removeWhere((t) => t.id == id);
    _samples.removeWhere((s) => s.trip == id);
    notifyListeners();
  }

  /// Saves [packet] if it is a fresh RF packet and the phone has a recent,
  /// accurate fix. Returns whether it was saved.
  Future<bool> observe(pb.MeshPacket packet, PhoneFix? fix, DateTime now) {
    final operation = _pending.then((_) => _observe(packet, fix, now));
    _pending = operation.then((_) {}, onError: (Object _) {});
    return operation;
  }

  Future<bool> _observe(pb.MeshPacket packet, PhoneFix? fix, DateTime now) async {
    final trip = current;
    if (trip == null || error != null || fix == null) return false;
    if (packet.from == 0 || packet.from == 0xffffffff || packet.from == _radio || packet.viaMqtt) return false;
    if (!packet.hasRxTime() || (!packet.hasRxSnr() && !packet.hasRxRssi())) return false;
    if (packet.hasRxSnr() && !packet.rxSnr.isFinite) return false;
    final age = now.difference(DateTime.fromMillisecondsSinceEpoch(packet.rxTime * 1000, isUtc: true));
    final fixAge = now.difference(fix.time);
    if (age.isNegative || age > const Duration(minutes: 2) || fixAge.isNegative || fixAge > const Duration(seconds: 30))
      return false;
    final accuracy = fix.accuracyMeters;
    if (accuracy == null || !accuracy.isFinite || accuracy < 0 || accuracy > 50) return false;
    if (!fix.latitude.isFinite || !fix.longitude.isFinite || fix.latitude.abs() > 90 || fix.longitude.abs() > 180)
      return false;
    final (row, col) = squareOf(fix.latitude, fix.longitude, throttleCellMeters);
    final key = (packet.from, row, col);
    final last = _lastLogged[key];
    if (last != null && now.difference(last) < throttleWindow) return false;
    final sample = DriveSample(
      trip: trip.id,
      time: now.toUtc(),
      latitude: fix.latitude,
      longitude: fix.longitude,
      accuracyMeters: accuracy,
      from: packet.from,
      packetId: packet.id == 0 ? null : packet.id,
      port: packet.hasDecoded() ? packet.decoded.portnum.value : null,
      channel: packet.channel,
      snr: packet.hasRxSnr() ? packet.rxSnr : null,
      rssi: packet.hasRxRssi() ? packet.rxRssi : null,
      hopStart: packet.hopStart,
      hopLimit: packet.hopLimit,
      hops: classifyHops(packet.hopStart, packet.hopLimit),
      relayByte: packet.relayNode == 0 ? null : packet.relayNode & 0xff,
    );
    try {
      await _store.addSamples([sample]);
    } catch (_) {
      error = 'Drive readings could not be saved. Recording stopped.';
      await stop(now: now);
      notifyListeners();
      rethrow;
    }
    _lastLogged[key] = now;
    _samples.add(sample);
    if (_samples.length > maxSamples) await _enforceLimits();
    notifyListeners();
    return true;
  }

  /// Drops the oldest finished trips while there are too many trips or
  /// samples. The running trip is never dropped.
  Future<void> _enforceLimits() async {
    while (_trips.length > maxTrips || _samples.length > maxSamples) {
      final oldest = _trips.where((t) => !t.running).firstOrNull;
      if (oldest == null) return;
      await _store.deleteTrip(oldest.id);
      _trips.remove(oldest);
      _samples.removeWhere((s) => s.trip == oldest.id);
    }
  }

  /// Samples of [trip] (or all) as CSV, oldest first.
  String exportCsv({int? trip}) {
    const fields = [
      'trip',
      'ts',
      'lat',
      'lon',
      'accuracy',
      'from_node',
      'packet',
      'port',
      'channel',
      'snr',
      'rssi',
      'hop_start',
      'hop_limit',
      'class',
      'relay',
    ];
    String cell(Object? v) => '"${(v?.toString() ?? '').replaceAll('"', '""')}"';
    final rows = samplesOf(trip: trip).map((s) {
      final row = s.toRow();
      return fields.map((f) => cell(row[f])).join(',');
    });
    return '${fields.join(',')}\r\n${rows.join('\r\n')}\r\n';
  }

  static String _defaultName(DateTime local) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'Drive ${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  /// Row and column of the square of [meters] holding a position. Squares
  /// are the same size in metres everywhere: columns narrow with latitude.
  static (int, int) squareOf(double lat, double lon, double meters) {
    final latStep = meters / _metersPerDegree;
    final row = (lat / latStep).floor();
    return (row, (lon / _lonStep(row, latStep, meters)).floor());
  }

  /// Edges of the square at [row], [col] (see [squareOf]).
  static ({double south, double west, double north, double east}) squareBounds(int row, int col, double meters) {
    final latStep = meters / _metersPerDegree;
    final lonStep = _lonStep(row, latStep, meters);
    return (south: row * latStep, north: (row + 1) * latStep, west: col * lonStep, east: (col + 1) * lonStep);
  }

  static const _metersPerDegree = 111320.0;

  static double _lonStep(int row, double latStep, double meters) {
    final centre = (row + 0.5) * latStep;
    return meters / (_metersPerDegree * math.max(0.01, math.cos(centre * math.pi / 180)));
  }
}
