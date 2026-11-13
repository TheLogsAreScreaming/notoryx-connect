import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/bastion_text.dart';

/// Which local field alerts are on, and their thresholds.
@immutable
class BastionAlertSettings {
  const BastionAlertSettings({
    this.lowBattery = true,
    this.batteryThreshold = 20,
    this.newNode = false,
    this.favoriteSilent = false,
    this.silence = const Duration(hours: 2),
    this.meshDrop = false,
  });

  static const key = 'bastion.alerts.v1';
  static const batteryChoices = [10, 20, 30];
  static const silenceChoices = [
    Duration(minutes: 30), Duration(hours: 1), Duration(hours: 2), Duration(hours: 6),
  ];

  /// Your radio or a favorite node at or below [batteryThreshold] percent.
  final bool lowBattery;
  final int batteryThreshold;

  /// This radio hears a node it has never heard before.
  final bool newNode;

  /// A favorite node is not heard for [silence] while connected.
  final bool favoriteSilent;
  final Duration silence;

  /// Far fewer nodes are being heard than earlier in this session.
  final bool meshDrop;

  BastionAlertSettings copyWith({bool? lowBattery, int? batteryThreshold, bool? newNode,
      bool? favoriteSilent, Duration? silence, bool? meshDrop}) => BastionAlertSettings(
    lowBattery: lowBattery ?? this.lowBattery,
    batteryThreshold: batteryThreshold ?? this.batteryThreshold,
    newNode: newNode ?? this.newNode,
    favoriteSilent: favoriteSilent ?? this.favoriteSilent,
    silence: silence ?? this.silence,
    meshDrop: meshDrop ?? this.meshDrop,
  );

  Map<String, Object> toJson() => {
    'lowBattery': lowBattery, 'batteryThreshold': batteryThreshold,
    'newNode': newNode, 'favoriteSilent': favoriteSilent, 'silenceMinutes': silence.inMinutes,
    'meshDrop': meshDrop,
  };

  /// Unknown or out-of-range values fall back to the defaults.
  static BastionAlertSettings fromJson(Object? json) {
    const d = BastionAlertSettings();
    if (json is! Map) return d;
    final battery = json['batteryThreshold'];
    final minutes = json['silenceMinutes'];
    return BastionAlertSettings(
      lowBattery: json['lowBattery'] is bool ? json['lowBattery'] as bool : d.lowBattery,
      batteryThreshold: batteryChoices.contains(battery) ? battery as int : d.batteryThreshold,
      newNode: json['newNode'] is bool ? json['newNode'] as bool : d.newNode,
      favoriteSilent: json['favoriteSilent'] is bool ? json['favoriteSilent'] as bool : d.favoriteSilent,
      silence: silenceChoices.firstWhere((c) => c.inMinutes == minutes, orElse: () => d.silence),
      meshDrop: json['meshDrop'] is bool ? json['meshDrop'] as bool : d.meshDrop,
    );
  }

  static Future<BastionAlertSettings> load([SharedPreferencesAsync? store]) async {
    try {
      final raw = await (store ?? SharedPreferencesAsync()).getString(key);
      return raw == null ? const BastionAlertSettings() : fromJson(jsonDecode(raw));
    } catch (_) {
      return const BastionAlertSettings();
    }
  }

  /// Returns false when the choice could not be saved (it still applies now).
  Future<bool> save([SharedPreferencesAsync? store]) async {
    try {
      await (store ?? SharedPreferencesAsync()).setString(key, jsonEncode(toJson()));
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  bool operator ==(Object other) => other is BastionAlertSettings &&
      jsonEncode(toJson()) == jsonEncode(other.toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

enum BastionAlertKind { lowBattery, newNode, favoriteSilent, sosAcknowledged, checkInDue, contactOverdue, geofenceArrive, geofenceLeave, keyChanged, meshDrop, offRoute }

@immutable
class BastionFieldAlert {
  const BastionFieldAlert(this.kind, this.nodeNum, this.title, this.body);
  final BastionAlertKind kind;
  final int nodeNum;
  final String title;
  final String body;

  /// Stable per condition, so a repeat replaces rather than stacks.
  int get notificationId => (kind.index << 28 ^ nodeNum) & 0x7fffffff;
}

/// Decides local field alerts from verified radio observations. Nothing is
/// ever transmitted. Each condition alerts once and rearms only after it
/// recovers; nothing alerts outside a connected session.
class BastionFieldAlertEngine {
  BastionFieldAlertEngine({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  /// Battery must rise this far above the threshold before it can alert again.
  static const batteryHysteresis = 5;

  final DateTime Function() _clock;
  final Set<String> _active = {};
  DateTime? _sessionStart;
  int? _localNode;

  bool get inSession => _sessionStart != null;

  /// Call when the radio is ready (after its node list has synchronized).
  void startSession(int localNode) {
    _active.clear();
    _meshPeak = 0;
    _localNode = localNode;
    _sessionStart = _clock();
  }

  void endSession() {
    _active.clear();
    _sessionStart = null;
    _localNode = null;
  }

  /// Fresh battery telemetry from [nodeNum]. Only your radio and favorites
  /// alert. Unknown (null) and external power (above 100) never alert.
  BastionFieldAlert? battery(int nodeNum, int? level, String name,
      {required bool favorite, required BastionAlertSettings settings}) {
    if (!inSession || !settings.lowBattery || level == null || level < 0 || level > 100) return null;
    final isLocal = nodeNum == _localNode;
    if (!isLocal && !favorite) return null;
    final key = 'battery:$nodeNum';
    if (level > settings.batteryThreshold + batteryHysteresis) {
      _active.remove(key);
      return null;
    }
    if (level > settings.batteryThreshold || !_active.add(key)) return null;
    return BastionFieldAlert(BastionAlertKind.lowBattery, nodeNum,
        isLocal ? BastionText.l.svcLowBatteryOwn : BastionText.l.svcLowBattery(name),
        isLocal ? BastionText.l.svcLowBatteryOwnBody(level) : BastionText.l.svcLowBatteryBody(name, level));
  }

  /// A node update heard live. [knownBefore] says whether this radio had
  /// heard the node before this update.
  BastionFieldAlert? nodeHeard(int nodeNum, String name,
      {required bool knownBefore, required BastionAlertSettings settings}) {
    _active.remove('silent:$nodeNum');
    if (!inSession || !settings.newNode || knownBefore || nodeNum == _localNode) return null;
    if (!_active.add('new:$nodeNum')) return null;
    return BastionFieldAlert(BastionAlertKind.newNode, nodeNum, BastionText.l.svcNewNode(name),
        BastionText.l.svcNewNodeBody(name));
  }

  /// Below this many nodes, normal comings and goings look like an outage.
  static const meshDropMinimum = 6;
  static const meshActiveWindow = Duration(hours: 1);
  int _meshPeak = 0;

  /// Alerts once when the nodes heard in the last hour fall to half of this
  /// session's peak or less, and rearms when most are back. Waits an hour
  /// into the session, so a fresh connection doesn't look like a drop.
  BastionFieldAlert? checkMeshDrop(Iterable<DateTime?> lastHeard, BastionAlertSettings settings) {
    final start = _sessionStart;
    if (start == null || !settings.meshDrop) return null;
    final now = _clock();
    final active = lastHeard.where((t) => t != null && now.difference(t) <= meshActiveWindow).length;
    if (active > _meshPeak) _meshPeak = active;
    const key = 'meshDrop';
    if (_active.contains(key) && active * 4 >= _meshPeak * 3) {
      _active.remove(key);
      _meshPeak = active;
      return null;
    }
    if (_meshPeak < meshDropMinimum || active * 2 > _meshPeak) return null;
    if (now.difference(start) < meshActiveWindow || !_active.add(key)) return null;
    return BastionFieldAlert(BastionAlertKind.meshDrop, 0, BastionText.l.svcMeshQuieter,
        BastionText.l.svcMeshQuieterBody(active, _meshPeak));
  }

  /// Favorites not heard for [BastionAlertSettings.silence] during this
  /// session. Call periodically while connected.
  List<BastionFieldAlert> checkSilence(
      Iterable<({int num, String name, DateTime? lastHeard})> favorites,
      BastionAlertSettings settings) {
    final start = _sessionStart;
    if (start == null || !settings.favoriteSilent) return const [];
    final now = _clock();
    final alerts = <BastionFieldAlert>[];
    for (final f in favorites) {
      if (f.num == _localNode) continue;
      final heard = f.lastHeard;
      final since = heard != null && heard.isAfter(start) ? heard : start;
      final key = 'silent:${f.num}';
      if (now.difference(since) < settings.silence) {
        _active.remove(key);
      } else if (_active.add(key)) {
        alerts.add(BastionFieldAlert(BastionAlertKind.favoriteSilent, f.num,
            BastionText.l.svcQuiet(f.name),
            BastionText.l.svcQuietBody(_describe(now.difference(since)))));
      }
    }
    return alerts;
  }

  static String _describe(Duration d) =>
      d.inHours >= 1 ? BastionText.l.svcHoursMinutes(d.inHours, d.inMinutes % 60) : BastionText.l.svcMinutes(d.inMinutes);
}
