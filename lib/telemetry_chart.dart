import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'services/bastion_preferences.dart';
import 'services/bastion_telemetry_history.dart';

/// Saved telemetry for one node: pick a metric to see it over time.
class TelemetryHistoryCard extends StatefulWidget {
  const TelemetryHistoryCard({super.key, required this.metrics, required this.series});

  /// Metrics with readings, in display order.
  final List<TelemetryMetric> metrics;

  /// Readings of a metric, oldest first.
  final List<TelemetryPoint> Function(TelemetryMetric) series;

  @override
  State<TelemetryHistoryCard> createState() => _TelemetryHistoryCardState();
}

class _TelemetryHistoryCardState extends State<TelemetryHistoryCard> {
  TelemetryMetric? _picked;

  static String _span(Duration d) => d.inDays >= 1
      ? '${d.inDays} d ${d.inHours % 24} h'
      : d.inHours >= 1
          ? '${d.inHours} h ${d.inMinutes % 60} min'
          : '${d.inMinutes} min';

  @override
  Widget build(BuildContext context) {
    final metrics = widget.metrics;
    final theme = Theme.of(context);
    if (metrics.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.show_chart),
          title: Text('Telemetry history'),
          subtitle: Text('No readings saved yet. Readings from this node are kept for 7 days while your radio is connected.'),
        ),
      );
    }
    final metric = metrics.contains(_picked) ? _picked! : metrics.first;
    final points = widget.series(metric);
    final units = BastionPreferences.instance.units;
    final values = [for (final p in points) p.value];
    final low = values.reduce(math.min), high = values.reduce(math.max);
    final latest = points.last;
    final span = latest.time.difference(points.first.time);
    final summary = '${metric.label}: latest ${metric.format(latest.value, units)}, '
        '${points.length} reading${points.length == 1 ? '' : 's'}'
        '${points.length > 1 ? ' over ${_span(span)}, from ${metric.format(low, units)} to ${metric.format(high, units)}' : ''}.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Telemetry history', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final m in metrics)
                  ChoiceChip(
                    label: Text(m.label),
                    selected: m == metric,
                    onSelected: (_) => setState(() => _picked = m),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              label: summary,
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${metric.format(latest.value, units)} now', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 140,
                            child: CustomPaint(
                              painter: TelemetryChartPainter(
                                points: points,
                                line: theme.colorScheme.primary,
                                grid: theme.colorScheme.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 140,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(metric.format(high, units), style: theme.textTheme.bodySmall),
                              Text(metric.format(low, units), style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      points.length == 1
                          ? 'One reading so far'
                          : 'Last ${_span(span)} • ${points.length} readings',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A line through [points], scaled to fit, with a faint frame. Time runs
/// left to right, so gaps between readings show as longer segments.
class TelemetryChartPainter extends CustomPainter {
  const TelemetryChartPainter({required this.points, required this.line, required this.grid});

  final List<TelemetryPoint> points;
  final Color line;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, 0), frame)
      ..drawLine(Offset(0, size.height), Offset(size.width, size.height), frame);
    if (points.isEmpty) return;
    final t0 = points.first.time.millisecondsSinceEpoch.toDouble();
    final tSpan = math.max(1.0, points.last.time.millisecondsSinceEpoch - t0);
    final values = [for (final p in points) p.value];
    final low = values.reduce(math.min), high = values.reduce(math.max);
    final vSpan = high - low;
    // Inset so dots at the ends aren't clipped.
    const inset = 4.0;
    final w = size.width - 2 * inset, h = size.height - 2 * inset;
    Offset at(TelemetryPoint p) => Offset(
          inset + (points.length == 1 ? w / 2 : (p.time.millisecondsSinceEpoch - t0) / tSpan * w),
          inset + (vSpan == 0 ? h / 2 : h - (p.value - low) / vSpan * h),
        );
    final stroke = Paint()
      ..color = line
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(at(points.first).dx, at(points.first).dy);
    for (final p in points.skip(1)) {
      final o = at(p);
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path, stroke);
    final dot = Paint()..color = line;
    if (points.length <= 60) {
      for (final p in points) {
        canvas.drawCircle(at(p), 2.5, dot);
      }
    } else {
      canvas.drawCircle(at(points.last), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(TelemetryChartPainter old) =>
      old.points != points || old.line != line || old.grid != grid;
}
