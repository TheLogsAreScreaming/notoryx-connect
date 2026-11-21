import 'package:flutter/foundation.dart';

import 'bastion_telemetry_history.dart';
import 'meshtastic_node_database.dart';

/// One node's battery, with which way it is heading.
@immutable
class BatteryRow {
  const BatteryRow({
    required this.num,
    required this.name,
    required this.level,
    required this.lastHeard,
    this.perDay,
    this.daysLeft,
  });

  final int num;
  final String name;

  /// Percent, or above 100 for external power.
  final int level;
  final DateTime? lastHeard;

  /// Percentage points gained (+) or lost (-) per day over the readings
  /// window; null without enough readings.
  final double? perDay;

  /// Days until empty at the current rate; null unless it is draining.
  final double? daysLeft;

  bool get pluggedIn => level > 100;
}

/// Every node that reports its battery, the most worrying first, as on
/// NOTORYX Core.
abstract final class BastionBatteryWatch {
  /// Readings older than this don't count toward the trend.
  static const window = Duration(hours: 48);

  /// A trend needs readings at least this far apart.
  static const minSpan = Duration(hours: 2);

  /// Changes smaller than this per day are shown as steady.
  static const steadyPerDay = 2.0;

  static List<BatteryRow> rows({
    required List<MeshtasticNode> nodes,
    required List<TelemetryPoint> Function(int num) batterySeries,
    required DateTime now,
  }) {
    final rows = <BatteryRow>[];
    for (final n in nodes) {
      final level = n.batteryLevel;
      if (level == null) continue;
      final trend = level > 100 ? null : perDay(batterySeries(n.num), now);
      rows.add(BatteryRow(
        num: n.num,
        name: n.displayName,
        level: level,
        lastHeard: n.lastHeard,
        perDay: trend,
        daysLeft: trend != null && trend < -steadyPerDay ? level / -trend : null,
      ));
    }
    // Lowest first, then fastest draining; external power last.
    rows.sort((a, b) {
      if (a.pluggedIn != b.pluggedIn) return a.pluggedIn ? 1 : -1;
      final byLevel = a.level.compareTo(b.level);
      if (byLevel != 0) return byLevel;
      return (a.perDay ?? 0).compareTo(b.perDay ?? 0);
    });
    return rows;
  }

  /// Least-squares slope of the readings in [window], in points per day.
  static double? perDay(List<TelemetryPoint> series, DateTime now) {
    final from = now.subtract(window);
    final pts = [for (final p in series) if (p.time.isAfter(from) && p.value <= 100) p];
    if (pts.length < 2) return null;
    if (pts.last.time.difference(pts.first.time) < minSpan) return null;
    final t0 = pts.first.time;
    double x(TelemetryPoint p) => p.time.difference(t0).inSeconds / 86400;
    final n = pts.length;
    final mx = pts.map(x).reduce((a, b) => a + b) / n;
    final my = pts.map((p) => p.value).reduce((a, b) => a + b) / n;
    var num = 0.0, den = 0.0;
    for (final p in pts) {
      num += (x(p) - mx) * (p.value - my);
      den += (x(p) - mx) * (x(p) - mx);
    }
    return den == 0 ? null : num / den;
  }
}
