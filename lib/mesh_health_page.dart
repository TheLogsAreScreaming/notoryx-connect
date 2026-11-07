import 'package:flutter/material.dart';

import 'services/bastion_mesh_health.dart';
import 'services/bastion_telemetry_history.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'telemetry_chart.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// How busy the channel is, how much this radio transmits, and who is
/// around, with plain advice when the mesh is struggling.
class MeshHealthPage extends StatelessWidget {
  const MeshHealthPage({super.key, required this.radio, this.clock = DateTime.now});
  final MeshtasticRadioCoordinator radio;
  final DateTime Function() clock;

  static NxTone toneOf(HealthLevel level) => switch (level) {
        HealthLevel.good => NxTone.success,
        HealthLevel.busy => NxTone.warning,
        HealthLevel.overloaded => NxTone.danger,
        HealthLevel.unknown => NxTone.neutral,
      };

  static String wordOf(HealthLevel level) => switch (level) {
        HealthLevel.good => 'Good',
        HealthLevel.busy => 'Busy',
        HealthLevel.overloaded => 'Overloaded',
        HealthLevel.unknown => 'Not reported',
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mesh health')),
        body: AnimatedBuilder(
          animation: radio,
          builder: (context, _) {
            final h = MeshHealthSummary.of(
              nodes: radio.nodes,
              telemetry: radio.deviceTelemetry,
              messages: radio.messages,
              local: radio.localNodeNum,
              now: clock(),
            );
            final local = radio.localNodeNum;
            final airMetrics = local == null
                ? const <TelemetryMetric>[]
                : [
                    for (final m in radio.telemetryMetricsOf(local))
                      if (m == TelemetryMetric.channelUtilization || m == TelemetryMetric.airUtilTx) m,
                  ];
            final others = h.activeNodes + h.quietNodes;
            return ListView(padding: NxSpace.page, children: [
              if (!radio.isReady)
                const NxBanner(message: 'Connect to a radio to see live readings. Figures below may be out of date.'),
              if (h.advice case final advice?)
                NxBanner(
                  tone: h.channelLevel == HealthLevel.overloaded || h.airtimeLevel == HealthLevel.overloaded
                      ? NxTone.danger
                      : NxTone.warning,
                  title: 'The mesh needs some room',
                  message: advice,
                )
              else if (h.channelLevel == HealthLevel.good)
                const NxBanner(tone: NxTone.success, message: 'The channel has plenty of room. Messages should get through normally.'),
              const NxSectionLabel('Airtime'),
              _Gauge(
                label: 'Channel busy',
                detail: 'How much of the time anyone is transmitting, as your radio hears it.',
                value: h.channelUtilization,
                level: h.channelLevel,
                busy: MeshHealthSummary.busyChannel,
                limit: MeshHealthSummary.overloadedChannel,
              ),
              _Gauge(
                label: 'Your transmit time',
                detail: 'Share of the last hour your radio spent sending. Many regions allow about 10%.',
                value: h.airUtilTx,
                level: h.airtimeLevel,
                busy: MeshHealthSummary.busyAirtime,
                limit: MeshHealthSummary.overloadedAirtime,
              ),
              if (airMetrics.isNotEmpty)
                TelemetryHistoryCard(
                  metrics: airMetrics,
                  series: (m) => radio.telemetrySeries(local!, m),
                ),
              const NxSectionLabel('Traffic'),
              NxStatRow(children: [
                NxStatTile(label: 'Messages, last hour', value: '${h.messagesLastHour}'),
                NxStatTile(label: 'Messages, last day', value: '${h.messagesLastDay}'),
              ]),
              const NxSectionLabel('Nodes'),
              NxStatRow(children: [
                NxStatTile(label: 'Heard in last 2 h', value: '${h.activeNodes}', tone: NxTone.success),
                NxStatTile(label: 'Quiet longer', value: '${h.quietNodes}'),
              ]),
              if (others > 0) ...[
                const SizedBox(height: NxSpace.xs),
                Card(child: Padding(
                  padding: const EdgeInsets.all(NxSpace.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Distance in hops', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: NxSpace.xs),
                    for (final hop in (h.hops.keys.toList()..sort((a, b) => (a < 0 ? 99 : a).compareTo(b < 0 ? 99 : b))))
                      _Bar(
                        label: hop < 0 ? 'Unknown' : hop == 0 ? 'Direct' : '$hop hop${hop == 1 ? '' : 's'}',
                        count: h.hops[hop]!,
                        total: others,
                      ),
                    const SizedBox(height: NxSpace.sm),
                    Text('Signal of last packet', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: NxSpace.xs),
                    for (final b in SignalBucket.values)
                      if (h.signal[b] case final count?)
                        _Bar(label: b.label, detail: b.detail, count: count, total: others),
                  ]),
                )),
              ],
              if (h.busiest.isNotEmpty) ...[
                const NxSectionLabel('Busiest transmitters'),
                Card(child: Column(children: [
                  for (final (i, b) in h.busiest.indexed) ...[
                    if (i > 0) const Divider(indent: NxSpace.md),
                    ListTile(
                      title: Text(b.node == local ? 'Your radio' : radio.nodeName(b.node)),
                      trailing: Text('${b.airUtilTx.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleSmall),
                    ),
                  ],
                ])),
              ],
              const SizedBox(height: NxSpace.sm),
              Text('Figures come from device telemetry that nodes send every so often, '
                  'so they can lag a few minutes behind.', style: Theme.of(context).textTheme.bodySmall),
            ]);
          },
        ),
      );
}

class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.label,
    required this.detail,
    required this.value,
    required this.level,
    required this.busy,
    required this.limit,
  });
  final String label;
  final String detail;
  final double? value;
  final HealthLevel level;
  final double busy;
  final double limit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final tone = MeshHealthPage.toneOf(level);
    final color = NxStatusColors.of(context).strong(tone, scheme);
    final scale = limit * 1.5;
    final shown = value == null ? 'Not reported' : '${value!.toStringAsFixed(1)}%';
    return Card(child: Padding(
      padding: const EdgeInsets.all(NxSpace.md),
      child: Semantics(
        label: '$label: $shown, ${MeshHealthPage.wordOf(level)}',
        excludeSemantics: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(alignment: WrapAlignment.spaceBetween, spacing: NxSpace.sm, children: [
            Text(label, style: type.titleSmall),
            Text(shown, style: type.titleMedium?.copyWith(color: color)),
          ]),
          const SizedBox(height: NxSpace.xs),
          LayoutBuilder(builder: (context, c) => Stack(children: [
            Container(height: 10, decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(NxRadius.pill))),
            Container(
              height: 10,
              width: c.maxWidth * ((value ?? 0) / scale).clamp(0, 1),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(NxRadius.pill)),
            ),
            for (final mark in [busy, limit])
              Positioned(left: c.maxWidth * (mark / scale) - 1, top: 0, bottom: 0,
                child: Container(width: 2, color: scheme.onSurfaceVariant)),
          ])),
          const SizedBox(height: NxSpace.xs),
          Wrap(spacing: NxSpace.sm, runSpacing: NxSpace.xxs, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(NxBanner.iconFor(tone), size: 16, color: color),
              const SizedBox(width: NxSpace.xxs),
              Text(MeshHealthPage.wordOf(level), style: type.labelMedium?.copyWith(color: color)),
            ]),
            Text('Marks at ${busy.toStringAsFixed(0)}% busy and ${limit.toStringAsFixed(0)}% limit',
              style: type.bodySmall),
          ]),
          const SizedBox(height: NxSpace.xxs),
          Text(detail, style: type.bodySmall),
        ]),
      ),
    ));
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.count, required this.total, this.detail});
  final String label;
  final String? detail;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '$label: $count of $total nodes',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          SizedBox(width: 96, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Expanded(child: LayoutBuilder(builder: (context, c) => Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 12,
              width: (c.maxWidth * (total == 0 ? 0 : count / total)).clamp(4, c.maxWidth),
              decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(NxRadius.pill)),
            ),
          ))),
          const SizedBox(width: NxSpace.xs),
          SizedBox(width: 28, child: Text('$count', textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelLarge)),
        ]),
      ),
    );
  }
}
