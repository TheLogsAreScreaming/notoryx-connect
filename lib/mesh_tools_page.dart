import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'local_mesh_discovery_page.dart';
import 'network_diagram_page.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_units.dart';
import 'services/bastion_geo.dart';
import 'services/meshtastic_radio_coordinator.dart';

/// Range Test log and Store & Forward history requests.
class MeshToolsPage extends StatelessWidget {
  const MeshToolsPage({super.key, required this.radio, this.initialTab = 0});

  final MeshtasticRadioCoordinator radio;
  final int initialTab;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        initialIndex: initialTab,
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).mtTitle),
            actions: [IconButton(key: const ValueKey('open-network-diagram'), tooltip: AppLocalizations.of(context).topologyTitle, icon: const Icon(Icons.hub_outlined), onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => NetworkDiagramPage(radio: radio)))), IconButton(tooltip: AppLocalizations.of(context).mtLocalDiscovery, icon: const Icon(Icons.radar), onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LocalMeshDiscoveryPage(radio: radio))))],
            bottom: TabBar(tabs: [Tab(text: AppLocalizations.of(context).mtRangeTest), Tab(text: AppLocalizations.of(context).mtStoreForward)]),
          ),
          body: SafeArea(top: false, child: AnimatedBuilder(
            animation: radio,
            builder: (context, _) => PrimaryScrollController.none(child: TabBarView(
              children: [_RangeTestTab(radio: radio), _StoreForwardTab(radio: radio)],
            )),
          )),
        ),
      );
}

String _nameOf(MeshtasticRadioCoordinator radio, int num) {
  for (final node in radio.nodes) {
    if (node.num == num) return node.displayName;
  }
  return '!${num.toRadixString(16).padLeft(8, '0')}';
}

class _RangeTestTab extends StatelessWidget {
  const _RangeTestTab({required this.radio});

  final MeshtasticRadioCoordinator radio;

  String? _distance(int from) {
    final local = radio.localNode;
    if (local == null || !local.hasPosition) return null;
    for (final node in radio.nodes) {
      if (node.num == from && node.hasPosition) {
        final m = BastionGeo.distanceMeters(local.latitude!, local.longitude!, node.latitude!, node.longitude!);
        return BastionUnitFormat.distance(m, BastionPreferences.instance.units);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final entries = radio.rangeTest.reversed.toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l.mtRangeHelp,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Text(l.mtPacketsHeard(entries.length), style: const TextStyle(fontWeight: FontWeight.bold))),
            TextButton(onPressed: entries.isEmpty ? null : radio.clearRangeTest, child: Text(l.mtClear)),
          ],
        ),
        for (final e in entries)
          Card(
            child: ListTile(
              dense: true,
              title: Text('${_nameOf(radio, e.from)} • ${e.text}'),
              subtitle: Text([
                e.receivedAt.toLocal().toString().substring(11, 19),
                if (e.snr != null) 'SNR ${e.snr!.toStringAsFixed(1)} dB',
                if (e.rssi != null) 'RSSI ${e.rssi} dBm',
                ?_distance(e.from),
              ].join(' • ')),
            ),
          ),
      ],
    );
  }
}

class _StoreForwardTab extends StatefulWidget {
  const _StoreForwardTab({required this.radio});

  final MeshtasticRadioCoordinator radio;

  @override
  State<_StoreForwardTab> createState() => _StoreForwardTabState();
}

class _StoreForwardTabState extends State<_StoreForwardTab> {
  Duration _window = const Duration(hours: 2);

  static List<(String, Duration)> _windows(AppLocalizations l) => [
    (l.mtLastMinutes(30), const Duration(minutes: 30)),
    (l.mtLastHours(2), const Duration(hours: 2)),
    (l.mtLastHours(8), const Duration(hours: 8)),
    (l.mtLastHours(24), const Duration(hours: 24)),
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final radio = widget.radio;
    final routers = radio.storeForwardRouters;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l.mtStoreForwardHelp,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        ListenableBuilder(
          listenable: BastionPreferences.instance,
          builder: (context, _) => SwitchListTile(
            key: const ValueKey('sf-catch-up'),
            contentPadding: EdgeInsets.zero,
            title: Text(l.mtCatchUp),
            subtitle: Text(l.mtCatchUpHelp),
            value: BastionPreferences.instance.storeForwardCatchUp,
            onChanged: (v) => BastionPreferences.instance.update(catchUp: v),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<Duration>(
          initialValue: _window,
          decoration: InputDecoration(labelText: l.mtReplayFrom),
          items: [for (final (label, d) in _windows(l)) DropdownMenuItem(value: d, child: Text(label))],
          onChanged: (v) => setState(() => _window = v ?? _window),
        ),
        const SizedBox(height: 12),
        if (radio.lastStoreForwardReply != null)
          Card(child: ListTile(leading: const Icon(Icons.info_outline), title: Text(radio.lastStoreForwardReply!))),
        if (routers.isEmpty)
          Text(
            l.mtNoRouters,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        for (final router in routers)
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(_nameOf(radio, router.nodeNum)),
              subtitle: Text(l.mtHeardAt(TimeOfDay.fromDateTime(router.lastHeard.toLocal()).format(context))),
              trailing: FilledButton.tonal(
                onPressed: radio.isReady
                    ? () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await radio.requestStoredMessages(router.nodeNum, _window);
                          messenger.showSnackBar(SnackBar(content: Text(l.mtHistoryRequested)));
                        } catch (error) {
                          messenger.showSnackBar(SnackBar(content: Text(l.mtRequestFailed('$error'))));
                        }
                      }
                    : null,
                child: Text(l.mtReplay),
              ),
            ),
          ),
      ],
    );
  }
}
