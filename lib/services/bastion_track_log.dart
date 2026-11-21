import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'bastion_field_alerts.dart';
import 'bastion_geo.dart';
import 'bastion_geofences.dart';
import 'bastion_gpx.dart';
import 'bastion_trails.dart';
import 'bastion_phone_position.dart';
import 'bastion_preferences.dart';
import 'bastion_units.dart';
import 'meshtastic_radio_coordinator.dart';
import '../l10n/bastion_text.dart';

/// One recorded position.
@immutable
class TrackPoint {
  const TrackPoint(this.time, this.latitude, this.longitude);
  final DateTime time;
  final double latitude;
  final double longitude;

  List<num> toJson() => [time.toUtc().millisecondsSinceEpoch, latitude, longitude];

  static TrackPoint? fromJson(Object? j) {
    if (j is! List || j.length != 3) return null;
    final [t, a, o] = j;
    if (t is! int || a is! num || o is! num) return null;
    return TrackPoint(DateTime.fromMillisecondsSinceEpoch(t, isUtc: true), a.toDouble(), o.toDouble());
  }
}

/// One recording, from Start to Stop.
class Track {
  Track({required this.id, required this.name, required this.started, this.ended, List<TrackPoint>? points})
      : points = points ?? [];

  final String id;
  String name;
  final DateTime started;
  DateTime? ended;
  final List<TrackPoint> points;

  bool get isRecording => ended == null;

  /// Total length along the points, in metres.
  double get meters {
    var m = 0.0;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      m += BastionGeo.distanceMeters(a.latitude, a.longitude, b.latitude, b.longitude);
    }
    return m;
  }

  Duration duration(DateTime now) => (ended ?? now).difference(started);

  /// The track as GPX, for mapping apps and GPS units.
  String toGpx(DateTime now) => BastionGpx.build(
        waypoints: const [],
        tracks: [
          (
            name: name,
            points: [for (final p in points) TrailPoint(p.latitude, p.longitude, p.time)],
          ),
        ],
        createdAt: now,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'started': started.toUtc().millisecondsSinceEpoch,
        if (ended case final e?) 'ended': e.toUtc().millisecondsSinceEpoch,
        'points': [for (final p in points) p.toJson()],
      };

  static Track? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], name = j['name'], started = j['started'], ended = j['ended'], points = j['points'];
    if (id is! String || started is! int) return null;
    return Track(
      id: id,
      name: name is String && name.isNotEmpty ? name : id,
      started: DateTime.fromMillisecondsSinceEpoch(started, isUtc: true),
      ended: ended is int ? DateTime.fromMillisecondsSinceEpoch(ended, isUtc: true) : null,
      points: [if (points is List) for (final p in points) ?TrackPoint.fromJson(p)],
    );
  }
}

/// Where the track log is saved; tests keep it in memory.
abstract interface class TrackLogStorage {
  Future<String?> read();
  Future<void> write(String data);
}

class FileTrackLogStorage implements TrackLogStorage {
  const FileTrackLogStorage();

  Future<File?> _file() async {
    if (kIsWeb) return null;
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/track_log_v1.json');
  }

  @override
  Future<String?> read() async {
    final f = await _file();
    if (f == null || !await f.exists()) return null;
    return f.readAsString();
  }

  @override
  Future<void> write(String data) async {
    final f = await _file();
    if (f == null) return;
    await f.parent.create(recursive: true);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(data, flush: true);
    await tmp.rename(f.path);
  }
}

/// A recorded track watched for you wandering off it.
@immutable
class SelfRouteWatch {
  const SelfRouteWatch({required this.trackId, required this.limitMeters});
  final String trackId;
  final double limitMeters;

  Map<String, Object> toJson() => {'track': trackId, 'limit': limitMeters};

  static SelfRouteWatch? fromJson(Object? j) {
    if (j is! Map) return null;
    final t = j['track'], l = j['limit'];
    if (t is! String || l is! num) return null;
    return SelfRouteWatch(trackId: t, limitMeters: l.toDouble());
  }
}

/// Records your own breadcrumb trail, Start to Stop, and can warn you when
/// you stray from a saved track. Points come from the radio's GPS and from
/// the phone's location. Kept on this phone only; nothing is sent.
class BastionTrackLog extends ChangeNotifier {
  BastionTrackLog({TrackLogStorage storage = const FileTrackLogStorage(), DateTime Function()? clock})
      : _storage = storage,
        _clock = clock ?? DateTime.now;

  static BastionTrackLog instance = BastionTrackLog();

  /// The oldest finished tracks are dropped beyond this many.
  static const maxTracks = 30;

  /// A running track stops taking points at this size.
  static const maxPoints = 20000;

  /// A new point needs to be this far from the last one...
  static const minMoveMeters = 10.0;

  /// ...or this long after it.
  static const minInterval = Duration(minutes: 2);

  /// Fixes this far from the last point in under a minute are GPS jumps.
  static const maxJumpMeters = 2000.0;

  /// Choices for how far off a track counts as straying.
  static const limits = BastionRouteWatch.limits;

  /// Back within this share of the limit counts as back on the track.
  static const rearm = 0.7;

  final TrackLogStorage _storage;
  final DateTime Function() _clock;
  final List<Track> _tracks = [];
  SelfRouteWatch? _watch;
  bool? _wasOff;
  double? _lastOffMeters;
  bool _loaded = false;

  /// Called with an alert when you stray from the watched track.
  void Function(BastionFieldAlert alert)? onAlert;

  /// Words for the alert; set by the app so they follow its language.
  ({String title, String body}) Function(String trackName, double meters)? describe;

  /// Newest first.
  List<Track> get tracks => List.unmodifiable(_tracks.reversed);

  Track? get recording => _tracks.where((t) => t.isRecording).firstOrNull;

  SelfRouteWatch? get watch => _watch;

  Track? get watchedTrack => _watch == null ? null : _tracks.where((t) => t.id == _watch!.trackId).firstOrNull;

  /// How far off the watched track the last position was, or null.
  double? get lastOffMeters => _lastOffMeters;

  /// Whether positions are wanted now (recording or watching).
  bool get wantsPositions => recording != null || watchedTrack != null;

  Future<void> load() async {
    _tracks.clear();
    _watch = null;
    try {
      final raw = await _storage.read();
      if (raw != null && raw.isNotEmpty) {
        final j = jsonDecode(raw);
        if (j is Map) {
          for (final t in (j['tracks'] as List? ?? const [])) {
            if (Track.fromJson(t) case final track?) _tracks.add(track);
          }
          _watch = SelfRouteWatch.fromJson(j['watch']);
        }
      }
    } catch (e) {
      debugPrint('Track log unreadable, starting fresh: $e');
    }
    // A recording still running when the app closed carries on.
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      await _storage.write(jsonEncode({
        'tracks': [for (final t in _tracks) t.toJson()],
        'watch': ?_watch?.toJson(),
      }));
    } catch (e) {
      debugPrint('Could not save track log: $e');
    }
  }

  /// Starts a new recording named [name]. Does nothing if one is running.
  Future<Track> start(String name) async {
    if (recording case final running?) return running;
    final now = _clock();
    final track = Track(id: now.microsecondsSinceEpoch.toRadixString(36), name: name, started: now);
    _tracks.add(track);
    while (_tracks.length > maxTracks) {
      final oldest = _tracks.indexWhere((t) => !t.isRecording && t.id != _watch?.trackId);
      if (oldest < 0) break;
      _tracks.removeAt(oldest);
    }
    notifyListeners();
    await _save();
    return track;
  }

  Future<void> stop() async {
    final running = recording;
    if (running == null) return;
    running.ended = _clock();
    notifyListeners();
    await _save();
  }

  Future<void> rename(Track track, String name) async {
    if (name.trim().isEmpty) return;
    track.name = name.trim();
    notifyListeners();
    await _save();
  }

  Future<void> delete(Track track) async {
    _tracks.removeWhere((t) => t.id == track.id);
    if (_watch?.trackId == track.id) _setWatch(null);
    notifyListeners();
    await _save();
  }

  /// Warns when you go more than [limitMeters] off [track]; null stops.
  Future<void> watchTrack(Track? track, {double limitMeters = 100}) async {
    _setWatch(track == null || track.points.length < 2
        ? null
        : SelfRouteWatch(trackId: track.id, limitMeters: limitMeters));
    notifyListeners();
    await _save();
  }

  void _setWatch(SelfRouteWatch? next) {
    _watch = next;
    _wasOff = null;
    _lastOffMeters = null;
  }

  /// Takes a position from the radio's GPS or the phone. Returns whether
  /// the running track grew.
  bool addPosition(double latitude, double longitude, DateTime time) {
    if (!_loaded) return false;
    if (latitude == 0 && longitude == 0) return false;
    _checkWatch(latitude, longitude);
    final track = recording;
    if (track == null || track.points.length >= maxPoints) {
      notifyListeners();
      return false;
    }
    if (time.isBefore(track.started)) return false;
    if (track.points.isNotEmpty) {
      final last = track.points.last;
      if (!time.isAfter(last.time)) return false;
      final moved = BastionGeo.distanceMeters(last.latitude, last.longitude, latitude, longitude);
      final gap = time.difference(last.time);
      if (moved > maxJumpMeters && gap < const Duration(minutes: 1)) return false;
      if (moved < minMoveMeters && gap < minInterval) return false;
    }
    track.points.add(TrackPoint(time, latitude, longitude));
    notifyListeners();
    // Points are saved every so often rather than one by one.
    if (track.points.length % 10 == 1) unawaited(_save());
    return true;
  }

  void _checkWatch(double latitude, double longitude) {
    final w = _watch;
    final track = watchedTrack;
    if (w == null || track == null) return;
    final line = [for (final p in track.points) (latitude: p.latitude, longitude: p.longitude)];
    final off = BastionRouteWatch.metersFrom(latitude, longitude, line);
    _lastOffMeters = off;
    final was = _wasOff;
    if (was == null) {
      // The first position only sets which side you're on.
      _wasOff = off > w.limitMeters;
      return;
    }
    if (!was && off > w.limitMeters) {
      _wasOff = true;
      final words = describe?.call(track.name, off) ??
          (title: 'Off your route', body: 'You are ${off.round()} m from ${track.name}.');
      onAlert?.call(BastionFieldAlert(BastionAlertKind.offRoute, 0, words.title, words.body));
    } else if (was && off < w.limitMeters * rearm) {
      _wasOff = false;
    }
  }

  /// Saves any points not yet written, e.g. when the app goes to the
  /// background.
  Future<void> flush() => _save();
}

/// Feeds the track log: the radio's own GPS positions, and the phone's
/// location while the app is in front and the log wants positions. Alerts go
/// out as local notifications through the radio's alert channel.
class TrackLogFeed with WidgetsBindingObserver {
  TrackLogFeed({required this.log, required this.radio, PhoneLocationSource? phone})
      : _phone = phone ?? GeolocatorLocationSource();

  final BastionTrackLog log;
  final MeshtasticRadioCoordinator radio;
  final PhoneLocationSource _phone;
  StreamSubscription<PhoneFix>? _fixes;
  DateTime? _lastRadioFix;
  bool _foreground = true;

  void start() {
    log.onAlert = (alert) => unawaited(radio.showLocalAlert(alert));
    log.describe = (name, meters) => (
          title: BastionText.l.tlgOffTitle,
          body: BastionText.l.tlgOffBody(BastionUnitFormat.distance(meters, BastionPreferences.instance.units), name),
        );
    radio.addListener(_onRadio);
    log.addListener(_sync);
    WidgetsBinding.instance.addObserver(this);
    _sync();
  }

  void _onRadio() {
    final me = radio.localNode;
    final at = me?.positionTime;
    if (me == null || !me.hasPosition || at == null) return;
    if (_lastRadioFix != null && !at.isAfter(_lastRadioFix!)) return;
    _lastRadioFix = at;
    log.addPosition(me.latitude!, me.longitude!, at);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.paused) unawaited(log.flush());
    _sync();
  }

  /// Phone location runs only while it's wanted and the app is in front.
  void _sync() {
    final want = log.wantsPositions && _foreground;
    if (want && _fixes == null) {
      _fixes = _phone.watch().listen(
            (f) => log.addPosition(f.latitude, f.longitude, f.time),
            onError: (Object e) => debugPrint('Track log phone location: $e'),
          );
    } else if (!want && _fixes != null) {
      unawaited(_fixes!.cancel());
      _fixes = null;
    }
  }

  void dispose() {
    radio.removeListener(_onRadio);
    log.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_fixes?.cancel());
    _fixes = null;
  }
}
