import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';

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

  static String wordOf(AppLocalizations l, HealthLevel level) => switch (level) {
        HealthLevel.good => l.mhGood,
        HealthLevel.busy => l.mhBusy,
        HealthLevel.overloaded => l.mhOverloaded,
        HealthLevel.unknown => l.mhNotReported,
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).mhTitle)),
        body: AnimatedBuilder(
          animation: radio,
          builder: (context, _) {
            final l = AppLocalizations.of(context);
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
                NxBanner(message: l.mhConnect),
              if (h.advice case final advice?)
                NxBanner(
                  tone: h.channelLevel == HealthLevel.overloaded || h.airtimeLevel == HealthLevel.overloaded
                      ? NxTone.danger
                      : NxTone.warning,
                  title: l.mhNeedsRoom,
                  message: advice,
                )
              else if (h.channelLevel == HealthLevel.good)
                NxBanner(tone: NxTone.success, message: l.mhPlentyRoom),
              NxSectionLabel(l.mhAirtime),
              _Gauge(
                label: l.mhChannelBusy,
                detail: l.mhChannelBusyHelp,
                value: h.channelUtilization,
                level: h.channelLevel,
                busy: MeshHealthSummary.busyChannel,
                limit: MeshHealthSummary.overloadedChannel,
              ),
              _Gauge(
                label: l.mhYourTx,
                detail: l.mhYourTxHelp,
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
              NxSectionLabel(l.mhTraffic),
              NxStatRow(children: [
                NxStatTile(label: l.mhMsgsHour, value: '${h.messagesLastHour}'),
                NxStatTile(label: l.mhMsgsDay, value: '${h.messagesLastDay}'),
              ]),
              NxSectionLabel(l.mhNodes),
              NxStatRow(children: [
                NxStatTile(label: l.mhHeard2h, value: '${h.activeNodes}', tone: NxTone.success),
                NxStatTile(label: l.mhQuiet, value: '${h.quietNodes}'),
              ]),
              if (others > 0) ...[
                const SizedBox(height: NxSpace.xs),
                Card(child: Padding(
                  padding: const EdgeInsets.all(NxSpace.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.mhHopDistance, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: NxSpace.xs),
                    for (final hop in (h.hops.keys.toList()..sort((a, b) => (a < 0 ? 99 : a).compareTo(b < 0 ? 99 : b))))
                      _Bar(
                        label: hop < 0 ? l.mhHopUnknown : hop == 0 ? l.mhHopDirect : l.mhHops(hop),
                        count: h.hops[hop]!,
                        total: others,
                      ),
                    const SizedBox(height: NxSpace.sm),
                    Text(l.mhLastSignal, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: NxSpace.xs),
                    for (final b in SignalBucket.values)
                      if (h.signal[b] case final count?)
                        _Bar(label: b.label, detail: b.detail, count: count, total: others),
                  ]),
                )),
              ],
              if (h.busiest.isNotEmpty) ...[
                NxSectionLabel(l.mhBusiest),
                Card(child: Column(children: [
                  for (final (i, b) in h.busiest.indexed) ...[
                    if (i > 0) const Divider(indent: NxSpace.md),
                    ListTile(
                      title: Text(b.node == local ? l.mhYourRadio : radio.nodeName(b.node)),
                      trailing: Text('${b.airUtilTx.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleSmall),
                    ),
                  ],
                ])),
              ],
              const SizedBox(height: NxSpace.sm),
              Text(l.mhFootnote, style: Theme.of(context).textTheme.bodySmall),
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
    final l = AppLocalizations.of(context);
    final shown = value == null ? l.mhNotReported : '${value!.toStringAsFixed(1)}%';
    return Card(child: Padding(
      padding: const EdgeInsets.all(NxSpace.md),
      child: Semantics(
        label: '$label: $shown, ${MeshHealthPage.wordOf(l, level)}',
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
              Text(MeshHealthPage.wordOf(l, level), style: type.labelMedium?.copyWith(color: color)),
            ]),
            Text(l.mhMarks(busy.toStringAsFixed(0), limit.toStringAsFixed(0)),
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
