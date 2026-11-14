import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/local_mesh_discovery_plan.dart';
import 'services/local_mesh_discovery_observation.dart';
import 'services/meshtastic_radio_coordinator.dart';

/// Read-only discovery planning. Does not connect, transmit or change radio settings.
class LocalMeshDiscoveryPage extends StatefulWidget {
  const LocalMeshDiscoveryPage({super.key, this.radio});

  final MeshtasticRadioCoordinator? radio;

  @override
  State<LocalMeshDiscoveryPage> createState() => _LocalMeshDiscoveryPageState();
}

class _LocalMeshDiscoveryPageState extends State<LocalMeshDiscoveryPage> {
  final Set<DiscoveryPreset> _selected = {...LocalMeshDiscoveryPlan.recommended};
  int _minutes = 5;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final plan = _selected.isEmpty ? null : LocalMeshDiscoveryPlan(presets: _selected, dwell: Duration(minutes: _minutes));
    return Scaffold(
      appBar: AppBar(title: Text(l.ldTitle)),
      body: AnimatedBuilder(animation: widget.radio ?? const AlwaysStoppedAnimation<double>(0), builder: (context, _) {
        final observations = latestDiscoveryObservations([
          for (final node in widget.radio?.nodes ?? [])
            if (node.lastHeard != null)
              DiscoveryObservation(nodeNumber: node.num, lastHeard: node.lastHeard!, name: node.displayName, snr: node.snr),
        ]);
        return ListView(padding: const EdgeInsets.all(16), children: [
        Text(l.ldPlanOnly),
        const SizedBox(height: 16),
        Text(l.ldPresets, style: Theme.of(context).textTheme.titleMedium),
        for (final preset in DiscoveryPreset.values)
          CheckboxListTile(
            title: Text(preset.label),
            value: _selected.contains(preset),
            onChanged: (enabled) => setState(() { if (enabled == true) { _selected.add(preset); } else { _selected.remove(preset); } }),
          ),
        const SizedBox(height: 8),
        Text(l.ldListenPer(_minutes)),
        Slider(value: _minutes.toDouble(), min: 1, max: 30, divisions: 29, label: '$_minutes min', onChanged: (value) => setState(() => _minutes = value.round())),
        Text(_selected.isEmpty ? l.ldSelectPreset : l.ldEstimate(plan!.estimatedListeningTime.inMinutes)),
        const SizedBox(height: 16),
        FilledButton(onPressed: null, child: Text(l.ldStartScan)),
        const SizedBox(height: 20),
        Text(l.ldAlreadyHeard, style: Theme.of(context).textTheme.titleMedium),
        Text(l.ldObserved(observations.length)),
        for (final node in observations)
          ListTile(
            title: Text(node.name ?? node.nodeNumber.toRadixString(16).padLeft(8, '0')),
            subtitle: Text(l.ldLastHeard(MaterialLocalizations.of(context).formatShortDate(node.lastHeard.toLocal()), TimeOfDay.fromDateTime(node.lastHeard.toLocal()).format(context))),
            trailing: node.snr == null ? null : Text('SNR ${node.snr!.toStringAsFixed(1)} dB'),
          ),
      ]);
      }),
    );
  }
}
