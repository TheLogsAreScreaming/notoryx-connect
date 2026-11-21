import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'node_avatar.dart';
import 'node_detail_page.dart';
import 'services/bastion_battery_watch.dart';
import 'services/bastion_telemetry_history.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// Every node reporting its battery, the most worrying first, with which
/// way it is heading. As on NOTORYX Core.
class BatteryWatchPage extends StatelessWidget {
  const BatteryWatchPage({super.key, required this.radio});
  final MeshtasticRadioCoordinator radio;

  /// Below this the level reads as a warning.
  static const low = 20;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.bwTitle)),
      body: ListenableBuilder(
        listenable: radio,
        builder: (context, _) {
          final rows = BastionBatteryWatch.rows(
            nodes: radio.nodes,
            batterySeries: (num) => radio.telemetrySeries(num, TelemetryMetric.battery),
            now: DateTime.now(),
          );
          if (rows.isEmpty) {
            return Center(
              child: NxEmptyState(icon: Icons.battery_unknown_outlined, title: l.bwTitle, detail: l.bwEmpty),
            );
          }
          return ListView(
            padding: NxSpace.page,
            children: [
              for (final r in rows)
                Card(
                  child: ListTile(
                    key: ValueKey('battery-${r.num}'),
                    leading: NodeAvatar(num: r.num, label: r.name),
                    title: Text(r.name),
                    subtitle: Text(_trend(l, r)),
                    trailing: _Level(row: r),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => NodeDetailPage(radio: radio, nodeNum: r.num),
                    )),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _trend(AppLocalizations l, BatteryRow r) {
    if (r.pluggedIn) return l.bwPlugged;
    final rate = r.perDay;
    if (rate == null) return l.bwNoTrend;
    if (rate.abs() < BastionBatteryWatch.steadyPerDay) return l.bwSteady;
    final pct = rate.abs().round().toString();
    if (rate > 0) return l.bwRising(pct);
    final left = r.daysLeft;
    final eta = left == null ? null : left < 1 ? l.bwUnderDay : l.bwDaysLeft(left.round());
    return [l.bwDropping(pct), ?eta].join(' • ');
  }
}

class _Level extends StatelessWidget {
  const _Level({required this.row});
  final BatteryRow row;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final status = NxStatusColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lowLevel = !row.pluggedIn && row.level <= BatteryWatchPage.low;
    // An icon whose shape changes with the level, plus the number.
    final icon = row.pluggedIn
        ? Icons.power
        : row.level <= 10
            ? Icons.battery_alert
            : row.level <= 30
                ? Icons.battery_2_bar
                : row.level <= 60
                    ? Icons.battery_4_bar
                    : row.level <= 90
                        ? Icons.battery_6_bar
                        : Icons.battery_full;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: lowLevel ? status.warning : scheme.onSurfaceVariant),
      const SizedBox(width: 4),
      Text(row.pluggedIn ? l.bwPluggedShort : '${row.level}%',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: lowLevel ? status.warning : null)),
    ]);
  }
}
