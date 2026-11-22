import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../generated/meshtastic/mesh.pb.dart' as pb;
import '../generated/meshtastic/mesh.pbenum.dart' show Routing_Error;
import '../generated/meshtastic/portnums.pbenum.dart';
import 'bastion_drive_log.dart';
import 'bastion_geo.dart';
import 'bastion_phone_position.dart';

/// How one check ended.
enum DriveCheckOutcome {
  /// The node answered straight back: both radios reach each other here.
  twoWay,

  /// The node answered, but through another node.
  answeredRelayed,

  /// No answer in time, or the radio gave up.
  noAnswer,
}

/// One check: where it was sent from and what came back.
@immutable
class DriveCheckResult {
  const DriveCheckResult({
    required this.node,
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.outcome,
    this.snr,
  });

  final int node;
  final DateTime time;
  final double latitude;
  final double longitude;
  final DriveCheckOutcome outcome;

  /// Signal of the answer, when there was one.
  final double? snr;
}

/// Why no check is being sent right now.
enum DriveCheckPause {
  /// No drive is recording.
  noDrive,

  /// No node to check has been picked.
  noTarget,

  /// The radio reports a busy channel.
  busyChannel,
}

/// Optional, off by default: while a drive records, sends one small direct
/// packet that can't be passed on (hop limit 0) to a node picked from those
/// heard directly on this drive, and asks for an acknowledgement. An answer
/// that comes straight back proves both radios reach each other from that
/// spot. Never broadcasts.
class BastionDriveCheck extends ChangeNotifier {
  BastionDriveCheck({
    required this.log,
    this.ackTimeout = const Duration(seconds: 30),
  });

  final BastionDriveLog log;

  /// How long to wait for an answer.
  final Duration ackTimeout;

  /// At least this long between checks...
  static const minInterval = Duration(seconds: 30);

  /// ...and at least this far moved.
  static const minMoveMeters = 25.0;

  /// A 300 m square with a direct reading this recent is skipped: it is
  /// already known to have coverage.
  static const recentDirect = Duration(days: 7);

  /// Checks pause while the radio reports more channel use than this (%).
  static const maxChannelUtilization = 25.0;

  static const _squareMeters = 300.0;

  /// Sends a ToRadio frame. Set by the radio coordinator.
  Future<void> Function(Uint8List frame)? send;

  /// Channel the checks go out on.
  int channel = 0;

  bool _enabled = false;
  int? _target;
  ({int id, int node, DateTime time, double lat, double lon})? _waiting;
  Timer? _timeout;
  DateTime? _lastSent;
  (double, double)? _lastAt;
  DriveCheckPause? _pause;
  final _results = <DriveCheckResult>[];
  var _nextId = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;

  bool get enabled => _enabled;
  int? get target => _target;
  bool get waiting => _waiting != null;
  DriveCheckPause? get pause => _pause;

  /// Checks on the running drive, oldest first.
  List<DriveCheckResult> get results => List.unmodifiable(_results);

  /// Nodes heard directly on the running drive: the only ones that can be
  /// checked.
  List<int> get candidates {
    final trip = log.current;
    if (trip == null) return const [];
    return {
      for (final s in log.samplesOf(trip: trip.id))
        if (s.hops == HopClass.direct) s.from,
    }.toList();
  }

  void setEnabled(bool on) {
    _enabled = on;
    if (!on) _cancel();
    notifyListeners();
  }

  void setTarget(int? node) {
    _target = node;
    notifyListeners();
  }

  /// Forgets the last drive's checks. Called when a drive starts or stops;
  /// the check turns itself off when a drive stops.
  void reset() {
    _cancel();
    _enabled = false;
    _target = null;
    _lastSent = null;
    _lastAt = null;
    _pause = null;
    _results.clear();
    notifyListeners();
  }

  void _cancel() {
    _timeout?.cancel();
    _timeout = null;
    _waiting = null;
  }

  /// Called with each phone fix while a drive records. Sends a check when
  /// every limit allows it. Returns whether one was sent.
  Future<bool> onFix(
    PhoneFix fix, {
    required DateTime now,
    double? channelUtilization,
  }) async {
    final trip = log.current;
    final node = _target;
    final sender = send;
    DriveCheckPause? pause;
    if (trip == null) {
      pause = DriveCheckPause.noDrive;
    } else if (node == null || !candidates.contains(node)) {
      pause = DriveCheckPause.noTarget;
    } else if (channelUtilization != null &&
        channelUtilization > maxChannelUtilization) {
      pause = DriveCheckPause.busyChannel;
    }
    if (pause != _pause) {
      _pause = pause;
      notifyListeners();
    }
    if (!_enabled || pause != null || sender == null || _waiting != null)
      return false;
    final accuracy = fix.accuracyMeters;
    if (accuracy == null || accuracy > 50) return false;
    if (_lastSent case final last? when now.difference(last) < minInterval)
      return false;
    if (_lastAt case final at?
        when BastionGeo.distanceMeters(
              at.$1,
              at.$2,
              fix.latitude,
              fix.longitude,
            ) <
            minMoveMeters)
      return false;
    if (_knownHere(fix, now)) return false;
    final id = _nextId = (_nextId + 1) & 0x7fffffff;
    final frame = pb.ToRadio(
      packet: pb.MeshPacket(
        to: node,
        channel: channel,
        id: id == 0 ? 1 : id,
        wantAck: true,
        hopLimit: 0,
        decoded: pb.Data(
          portnum: PortNum.PRIVATE_APP,
          payload: utf8.encode('check'),
        ),
      ),
    ).writeToBuffer();
    _lastSent = now;
    _lastAt = (fix.latitude, fix.longitude);
    _waiting = (
      id: id == 0 ? 1 : id,
      node: node!,
      time: now,
      lat: fix.latitude,
      lon: fix.longitude,
    );
    _timeout = Timer(ackTimeout, () => _finish(DriveCheckOutcome.noAnswer));
    notifyListeners();
    try {
      await sender(frame);
    } catch (_) {
      _cancel();
      notifyListeners();
      rethrow;
    }
    return true;
  }

  /// Whether the fix's 300 m square already has a recent direct reading.
  bool _knownHere(PhoneFix fix, DateTime now) {
    final here = BastionDriveLog.squareOf(
      fix.latitude,
      fix.longitude,
      _squareMeters,
    );
    final since = now.subtract(recentDirect);
    return log.samples.any(
      (s) =>
          s.hops == HopClass.direct &&
          s.time.isAfter(since) &&
          BastionDriveLog.squareOf(s.latitude, s.longitude, _squareMeters) ==
              here,
    );
  }

  /// Called with every packet from the radio, to catch the answer.
  void onPacket(pb.MeshPacket packet) {
    final w = _waiting;
    if (w == null ||
        !packet.hasDecoded() ||
        packet.decoded.portnum != PortNum.ROUTING_APP)
      return;
    if (packet.decoded.requestId != w.id) return;
    pb.Routing routing;
    try {
      routing = pb.Routing.fromBuffer(packet.decoded.payload);
    } catch (_) {
      return;
    }
    // Any reply from the node itself, even a refusal, proves it heard us.
    // From anyone else (the local radio giving up), an error means no
    // answer and anything else is ignored.
    if (packet.from != w.node) {
      final failed =
          routing.hasErrorReason() && routing.errorReason != Routing_Error.NONE;
      if (failed) _finish(DriveCheckOutcome.noAnswer);
      return;
    }
    final direct =
        classifyHops(packet.hopStart, packet.hopLimit) == HopClass.direct;
    _finish(
      direct ? DriveCheckOutcome.twoWay : DriveCheckOutcome.answeredRelayed,
      snr: packet.hasRxSnr() ? packet.rxSnr : null,
    );
  }

  void _finish(DriveCheckOutcome outcome, {double? snr}) {
    final w = _waiting;
    if (w == null) return;
    _cancel();
    _results.add(
      DriveCheckResult(
        node: w.node,
        time: w.time,
        latitude: w.lat,
        longitude: w.lon,
        outcome: outcome,
        snr: snr,
      ),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }
}
