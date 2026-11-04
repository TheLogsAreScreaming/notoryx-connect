import 'package:flutter/material.dart';
import 'services/local_mesh_discovery_plan.dart';
import 'services/local_mesh_discovery_observation.dart';
import 'services/meshtastic_radio_coordinator.dart';

/// Read-only discovery planning. Does not connect, transmit or change radio settings.
class LocalMeshDiscoveryPage extends StatefulWidget {
  const LocalMeshDiscoveryPage({super.key, required this.radio});

  final MeshtasticRadioCoordinator radio;

  @override
  State<LocalMeshDiscoveryPage> createState() => _LocalMeshDiscoveryPageState();
}

class _LocalMeshDiscoveryPageState extends State<LocalMeshDiscoveryPage> {
  final Set<DiscoveryPreset> _selected = {...LocalMeshDiscoveryPlan.recommended};
  int _minutes = 5;

  @override
  Widget build(BuildContext context) {
    final plan = _selected.isEmpty ? null : LocalMeshDiscoveryPlan(presets: _selected, dwell: Duration(minutes: _minutes));
    final observations = latestDiscoveryObservations([
      for (final node in widget.radio.nodes)
        if (node.lastHeard != null)
          DiscoveryObservation(nodeNumber: node.num, lastHeard: node.lastHeard!, name: node.displayName, snr: node.snr),
    ]);
    return Scaffold(
      appBar: AppBar(title: const Text('Local mesh discovery')),
      body: AnimatedBuilder(animation: widget.radio, builder: (context, _) => ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Plan only — scanning is not enabled. No radio settings are changed and no packets are transmitted.'),
        const SizedBox(height: 16),
        Text('LoRa presets', style: Theme.of(context).textTheme.titleMedium),
        for (final preset in DiscoveryPreset.values)
          CheckboxListTile(
            title: Text(preset.label),
            value: _selected.contains(preset),
            onChanged: (enabled) => setState(() { if (enabled == true) { _selected.add(preset); } else { _selected.remove(preset); } }),
          ),
        const SizedBox(height: 8),
        Text('Listen per preset: $_minutes minutes'),
        Slider(value: _minutes.toDouble(), min: 1, max: 30, divisions: 29, label: '$_minutes min', onChanged: (value) => setState(() => _minutes = value.round())),
        Text(_selected.isEmpty ? 'Select at least one preset.' : 'Estimated listening time: ${plan!.estimatedListeningTime.inMinutes} minutes'),
        const SizedBox(height: 16),
        const FilledButton(onPressed: null, child: Text('Start scan (not yet available)')),
        const SizedBox(height: 20),
        Text('Already heard on connected radio', style: Theme.of(context).textTheme.titleMedium),
        Text('${observations.length} observed nodes — existing radio data only; no scan has started.'),
        for (final node in observations)
          ListTile(
            title: Text(node.name ?? '!\${node.nodeNumber.toRadixString(16).padLeft(8, '0')}'),
            subtitle: Text('Last heard: \${node.lastHeard.toLocal()}'),
            trailing: node.snr == null ? null : Text('SNR \${node.snr!.toStringAsFixed(1)} dB'),
          ),
      ])),
    );
  }
}
