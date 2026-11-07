import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../generated/meshtastic/telemetry.pb.dart';
import 'bastion_units.dart';

/// A telemetry value worth charting.
enum TelemetryMetric {
  battery('Battery', '%'),
  voltage('Voltage', 'V'),
  channelUtilization('Channel use', '%'),
  airUtilTx('Transmit airtime', '%'),
  temperature('Temperature', '°C'),
  humidity('Humidity', '%'),
  pressure('Pressure', 'hPa'),
  iaq('Air quality (IAQ)', ''),
  lux('Light', 'lx'),
  windSpeed('Wind', 'm/s'),
  rainfall1h('Rain, last hour', 'mm'),
  soilMoisture('Soil moisture', '%');

  const TelemetryMetric(this.label, this.unit);
  final String label;
  final String unit;

  /// Whether this comes from an environment sensor rather than the radio.
  bool get isEnvironment => index >= TelemetryMetric.temperature.index;

  /// [value] with its unit; temperatures follow the units setting.
  String format(double value, BastionUnits units) {
    if (this == temperature && units == BastionUnits.imperial) {
      return '${(value * 9 / 5 + 32).toStringAsFixed(1)} °F';
    }
    final digits = switch (this) {
      battery || iaq || humidity || soilMoisture || pressure || lux => 0,
      voltage => 2,
      _ => 1,
    };
    final text = value.toStringAsFixed(digits);
    return unit.isEmpty ? text : '$text${unit == '%' ? '' : ' '}$unit';
  }

  /// The readings in one Meshtastic Telemetry message.
  static Map<TelemetryMetric, double> readingsOf(Telemetry telemetry) {
    final readings = <TelemetryMetric, double>{};
    if (telemetry.hasDeviceMetrics()) {
      final d = telemetry.deviceMetrics;
      // Above 100 means external power, not a level.
      if (d.hasBatteryLevel() && d.batteryLevel <= 100) readings[battery] = d.batteryLevel.toDouble();
      if (d.hasVoltage() && d.voltage > 0) readings[voltage] = d.voltage;
      if (d.hasChannelUtilization()) readings[channelUtilization] = d.channelUtilization;
      if (d.hasAirUtilTx()) readings[airUtilTx] = d.airUtilTx;
    }
    if (telemetry.hasEnvironmentMetrics()) {
      final e = telemetry.environmentMetrics;
      if (e.hasTemperature()) readings[temperature] = e.temperature;
      if (e.hasRelativeHumidity()) readings[humidity] = e.relativeHumidity;
      if (e.hasBarometricPressure()) readings[pressure] = e.barometricPressure;
      if (e.hasIaq()) readings[iaq] = e.iaq.toDouble();
      if (e.hasLux()) readings[lux] = e.lux;
      if (e.hasWindSpeed()) readings[windSpeed] = e.windSpeed;
      if (e.hasRainfall1h()) readings[rainfall1h] = e.rainfall1h;
      if (e.hasSoilMoisture()) readings[soilMoisture] = e.soilMoisture.toDouble();
    }
    readings.removeWhere((_, v) => !v.isFinite);
    return readings;
  }
}

/// One saved reading.
class TelemetryPoint {
  const TelemetryPoint(this.time, this.value);
  final DateTime time;
  final double value;

  List<num> toJson() => [time.millisecondsSinceEpoch ~/ 1000, value];

  static TelemetryPoint fromJson(Object? json) {
    final list = json! as List;
    return TelemetryPoint(
        DateTime.fromMillisecondsSinceEpoch((list[0] as int) * 1000), (list[1] as num).toDouble());
  }
}

/// Telemetry readings over time for each node, kept per radio for charts.
///
/// Keeps [keep] of history and at most [maxPoints] per node and metric.
/// Saving is throttled to [saveEvery]; [flush] saves anything pending.
/// Unreadable storage is never overwritten.
class BastionTelemetryHistory {
  BastionTelemetryHistory({SharedPreferencesAsync? preferences, DateTime Function()? clock})
      : _preferences = preferences,
        _clock = clock ?? DateTime.now;

  static const keep = Duration(days: 7);
  static const maxPoints = 300;
  static const saveEvery = Duration(minutes: 1);

  static String key(int radio) =>
      'bastion.telemetry.v1.radio.${radio.toRadixString(16).padLeft(8, '0')}';

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();
  final DateTime Function() _clock;
  final Map<int, Map<TelemetryMetric, List<TelemetryPoint>>> _series = {};
  int? _radio;
  bool _loadFailed = false;
  bool _dirty = false;
  DateTime? _lastSave;

  /// Metrics with readings for [node], radio metrics first.
  List<TelemetryMetric> metricsOf(int node) =>
      [for (final m in TelemetryMetric.values) if (_series[node]?[m]?.isNotEmpty ?? false) m];

  /// Readings of [metric] from [node], oldest first.
  List<TelemetryPoint> seriesOf(int node, TelemetryMetric metric) =>
      List.unmodifiable(_series[node]?[metric] ?? const []);

  /// Shows [radio]'s history, saving the previous radio's first.
  Future<void> useRadio(int radio) async {
    if (radio == _radio) return;
    await flush();
    _radio = radio;
    _series.clear();
    _loadFailed = false;
    try {
      final raw = await _store.getString(key(radio));
      if (raw == null) return;
      _series.addAll(_decode(raw));
      _prune(_clock());
    } on FormatException {
      // Damaged storage is replaced by the next save.
    } catch (_) {
      _loadFailed = true;
    }
  }

  /// Records [readings] from [node]. [sampleTime] is the sender's clock in
  /// epoch seconds; it is used when plausible, otherwise the time received.
  void record(int node, Map<TelemetryMetric, double> readings, {int? sampleTime}) {
    if (_radio == null || readings.isEmpty) return;
    final now = _clock();
    var time = now;
    if (sampleTime != null && sampleTime > 0) {
      final sent = DateTime.fromMillisecondsSinceEpoch(sampleTime * 1000);
      if (sent.isBefore(now.add(const Duration(minutes: 5))) && now.difference(sent) < keep) time = sent;
    }
    final byMetric = _series.putIfAbsent(node, () => {});
    for (final e in readings.entries) {
      final points = byMetric.putIfAbsent(e.key, () => []);
      if (points.any((p) => p.time == time)) continue;
      points
        ..add(TelemetryPoint(time, e.value))
        ..sort((a, b) => a.time.compareTo(b.time));
    }
    _prune(now);
    _dirty = true;
    if (_lastSave == null || now.difference(_lastSave!) >= saveEvery) unawaited(flush());
  }

  /// Merges [from]'s saved history into the current radio's and saves it.
  /// Returns false when either could not be read or saved.
  Future<bool> importRadio(int from) async {
    if (_radio == null || _loadFailed) return false;
    final Map<int, Map<TelemetryMetric, List<TelemetryPoint>>> other;
    try {
      final raw = await _store.getString(key(from));
      if (raw == null) return true;
      other = _decode(raw);
    } catch (_) {
      return false;
    }
    for (final node in other.entries) {
      final mine = _series.putIfAbsent(node.key, () => {});
      for (final metric in node.value.entries) {
        final seen = <DateTime>{};
        mine[metric.key] = [
          for (final p in [...?mine[metric.key], ...metric.value]..sort((a, b) => a.time.compareTo(b.time)))
            if (seen.add(p.time)) p,
        ];
      }
    }
    _prune(_clock());
    _dirty = true;
    await flush();
    return !_dirty;
  }

  void _prune(DateTime now) {
    for (final byMetric in _series.values) {
      for (final points in byMetric.values) {
        points.removeWhere((p) => now.difference(p.time) > keep);
        if (points.length > maxPoints) points.removeRange(0, points.length - maxPoints);
      }
      byMetric.removeWhere((_, points) => points.isEmpty);
    }
    _series.removeWhere((_, byMetric) => byMetric.isEmpty);
  }

  static Map<int, Map<TelemetryMetric, List<TelemetryPoint>>> _decode(String raw) {
    final root = jsonDecode(raw) as Map<String, Object?>;
    final result = <int, Map<TelemetryMetric, List<TelemetryPoint>>>{};
    for (final node in root.entries) {
      final num = int.tryParse(node.key);
      if (num == null || node.value is! Map) continue;
      for (final metric in (node.value! as Map).entries) {
        final m = TelemetryMetric.values.where((v) => v.name == metric.key).firstOrNull;
        if (m == null) continue;
        try {
          (result[num] ??= {})[m] = [for (final p in metric.value as List) TelemetryPoint.fromJson(p)];
        } catch (_) {
          // Skip a damaged series; the others still load.
        }
      }
    }
    return result;
  }

  /// Saves pending readings now.
  Future<void> flush() async {
    final radio = _radio;
    if (!_dirty || radio == null || _loadFailed) return;
    _dirty = false;
    _lastSave = _clock();
    try {
      await _store.setString(key(radio), jsonEncode({
        for (final node in _series.entries)
          '${node.key}': {
            for (final metric in node.value.entries)
              metric.key.name: [for (final p in metric.value) p.toJson()],
          },
      }));
    } catch (_) {
      _dirty = true; // Try again with the next reading.
    }
  }
}
