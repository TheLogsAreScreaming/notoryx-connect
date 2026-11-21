import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_mesh_watch.dart';
import 'services/bastion_traffic.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';
import 'traffic_map.dart' show TrafficStyle;

/// Field stats, network changes and a live packet log, as on NOTORYX Core.
class MeshActivityPage extends StatelessWidget {
  const MeshActivityPage({super.key, required this.watch, required this.nameOf, this.initialTab = 0});

  final BastionMeshWatch watch;
  final String Function(int num) nameOf;
  final int initialTab;

  static IconData kindIcon(TrafficKind k) => switch (k) {
        TrafficKind.advert => Icons.person_pin_circle_outlined,
        TrafficKind.direct => Icons.chat_bubble_outline,
        TrafficKind.channel => Icons.forum_outlined,
        TrafficKind.ack => Icons.done_all,
        TrafficKind.trace => Icons.route,
        TrafficKind.other => Icons.more_horiz,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.maTitle),
          bottom: TabBar(tabs: [
            Tab(text: l.maTabStats),
            Tab(text: l.maTabChanges),
            Tab(text: l.maTabPackets),
          ]),
        ),
        body: ListenableBuilder(
          listenable: watch,
          builder: (context, _) => TabBarView(children: [
            _Stats(watch: watch, nameOf: nameOf),
            _Changes(watch: watch),
            _Packets(watch: watch, nameOf: nameOf),
          ]),
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.watch, required this.nameOf});
  final BastionMeshWatch watch;
  final String Function(int) nameOf;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = watch.stats();
    String snr(double v) => '${v.toStringAsFixed(1)} dB';
    return ListView(padding: NxSpace.page, children: [
      Text(l.maRealOnly, style: Theme.of(context).textTheme.bodySmall),
      NxSectionLabel(l.maLastHour),
      if (s.packets == 0)
        Padding(padding: const EdgeInsets.all(NxSpace.sm), child: Text(l.maNothing))
      else ...[
        NxStatRow(children: [
          NxStatTile(label: l.maPackets, value: '${s.packets}', icon: Icons.podcasts),
          NxStatTile(label: l.maSenders, value: '${s.senders}', icon: Icons.hub_outlined),
        ]),
        const SizedBox(height: NxSpace.sm),
        NxStatRow(children: [
          NxStatTile(label: l.maDirect, value: '${s.direct}', icon: Icons.settings_input_antenna),
          NxStatTile(
              label: l.maAvgHops,
              value: s.averageHops == null ? '–' : s.averageHops!.toStringAsFixed(1),
              icon: Icons.alt_route),
        ]),
        Card(
          child: Column(children: [
            if (s.bestSnr != null)
              ListTile(
                  title: Text(l.maSnrRange),
                  trailing: Text('${snr(s.worstSnr!)} … ${snr(s.bestSnr!)}')),
            if (s.viaMqtt > 0) ListTile(title: Text(l.maMqtt), trailing: Text('${s.viaMqtt}')),
          ]),
        ),
        NxSectionLabel(l.maByKind),
        Card(
          child: Column(children: [
            for (final k in TrafficKind.values)
              if (s.byKind[k] case final n?)
                ListTile(
                  leading: Icon(MeshActivityPage.kindIcon(k), color: TrafficStyle.color(k)),
                  title: Text(TrafficStyle.name(l, k)),
                  trailing: Text('$n'),
                ),
          ]),
        ),
        NxSectionLabel(l.maBusiest),
        Card(
          child: Column(children: [
            for (final (num, n) in s.busiest) ListTile(title: Text(nameOf(num)), trailing: Text('$n')),
          ]),
        ),
      ],
    ]);
  }
}

class _Changes extends StatelessWidget {
  const _Changes({required this.watch});
  final BastionMeshWatch watch;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final changes = watch.changes;
    final ml = MaterialLocalizations.of(context);
    if (changes.isEmpty) {
      return Center(child: Padding(padding: NxSpace.page, child: Text(l.maNoChanges, textAlign: TextAlign.center)));
    }
    return ListView(padding: NxSpace.page, children: [
      for (final c in changes)
        ListTile(
          key: ValueKey('change-${c.kind.name}-${c.num}-${c.time.millisecondsSinceEpoch}'),
          leading: Icon(switch (c.kind) {
            NetworkChangeKind.appeared => Icons.fiber_new_outlined,
            NetworkChangeKind.quiet => Icons.notifications_paused_outlined,
            NetworkChangeKind.back => Icons.replay,
            NetworkChangeKind.renamed => Icons.drive_file_rename_outline,
          }),
          title: Text(switch (c.kind) {
            NetworkChangeKind.appeared => l.maAppeared(c.name),
            NetworkChangeKind.quiet => l.maQuiet(c.name),
            NetworkChangeKind.back => l.maBack(c.name),
            NetworkChangeKind.renamed => l.maRenamed(c.oldName ?? '?', c.name),
          }),
          subtitle: Text('${ml.formatShortMonthDay(c.time)} ${ml.formatTimeOfDay(TimeOfDay.fromDateTime(c.time))}'),
        ),
      const SizedBox(height: NxSpace.sm),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: const ValueKey('changes-clear'),
          onPressed: watch.clearChanges,
          icon: const Icon(Icons.delete_sweep_outlined),
          label: Text(l.maClear),
        ),
      ),
    ]);
  }
}

class _Packets extends StatelessWidget {
  const _Packets({required this.watch, required this.nameOf});
  final BastionMeshWatch watch;
  final String Function(int) nameOf;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final packets = watch.packets;
    if (packets.isEmpty) {
      return Center(child: Padding(padding: NxSpace.page, child: Text(l.maNothing, textAlign: TextAlign.center)));
    }
    return ListView.builder(
      itemCount: packets.length,
      itemBuilder: (context, i) {
        final p = packets[i];
        final to = p.to == TrafficPacket.broadcast ? l.maEveryone : nameOf(p.to);
        final time = TimeOfDay.fromDateTime(p.heard).format(context);
        final details = [
          time,
          if (p.hopsAway case final h?) l.maHops(h),
          if (p.snr case final s? when !p.viaMqtt) 'SNR ${s.toStringAsFixed(1)}',
          if (p.rssi case final r? when !p.viaMqtt && r != 0) 'RSSI $r',
          if (p.viaMqtt) l.maViaMqtt,
        ].join(' • ');
        return ListTile(
          dense: true,
          leading: Icon(MeshActivityPage.kindIcon(p.kind), color: TrafficStyle.color(p.kind)),
          title: Text('${TrafficStyle.name(l, p.kind)}: ${l.maFromTo(nameOf(p.from), to)}'),
          subtitle: Text(details),
        );
      },
    );
  }
}
