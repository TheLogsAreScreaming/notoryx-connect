import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';

import 'services/meshtastic_node_database.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'services/bastion_route_map.dart';
import 'services/bastion_trace_card.dart';
import 'services/meshtastic_traceroute.dart';
import 'trace_card_page.dart';
import 'traceroute_map.dart';

/// Picks a mesh node and shows the route to it and back with per-hop SNR.
class TraceroutePage extends StatefulWidget {
  const TraceroutePage({super.key, required this.radio, this.initialTarget});

  final MeshtasticRadioCoordinator radio;

  /// Node to preselect, e.g. when opened from a node's detail screen.
  final int? initialTarget;

  @override
  State<TraceroutePage> createState() => _TraceroutePageState();
}

class _TraceroutePageState extends State<TraceroutePage> {
  late int? _target = widget.initialTarget;
  TracerouteResult? _result;
  DateTime? _sentAt;
  Duration? _roundTrip;
  Object? _error;
  bool _running = false;

  Future<void> _run() async {
    final target = _target;
    if (target == null) return;
    setState(() {
      _running = true;
      _result = null;
      _error = null;
    });
    final sentAt = DateTime.now();
    final clock = Stopwatch()..start();
    try {
      final result = await widget.radio.traceroute(target);
      clock.stop();
      if (mounted) {
        setState(() {
          _result = result;
          _sentAt = sentAt;
          _roundTrip = clock.elapsed;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  bool _hasPosition(int num) {
    for (final node in widget.radio.nodes) {
      if (node.num == num) return node.latitude != null && node.longitude != null;
    }
    return false;
  }

  String _name(int num) {
    if (num == widget.radio.localNodeNum) return AppLocalizations.of(context).trcThisRadio;
    for (final node in widget.radio.nodes) {
      if (node.num == num) return node.displayName;
    }
    return '!${num.toRadixString(16).padLeft(8, '0')}';
  }

  void _openCard(TracerouteResult result, int local) {
    final card = TraceCard.from(
      result,
      local: local,
      destination: _target!,
      nodes: widget.radio.nodes,
      name: _name,
      sentAt: _sentAt!,
      roundTrip: _roundTrip!,
    );
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TraceCardPage(card: card)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).trcTitle)),
        body: AnimatedBuilder(
          animation: widget.radio,
          builder: (context, _) {
            final l = AppLocalizations.of(context);
            final local = widget.radio.localNodeNum;
            final nodes = widget.radio.nodes.where((n) => n.num != local).toList()
              ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _target,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.trcDestination),
                  items: [
                    for (final MeshtasticNode node in nodes)
                      DropdownMenuItem(value: node.num, child: Text(node.displayName)),
                  ],
                  onChanged: _running ? null : (v) => setState(() => _target = v),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _target != null && !_running && widget.radio.canTraceroute ? _run : null,
                  icon: _running
                      ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.route),
                  label: Text(_running ? l.trcRunning : l.trcRun),
                ),
                const SizedBox(height: 8),
                Text(
                  l.trcHelp,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (!widget.radio.canTraceroute && !_running)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l.trcConnectFirst),
                  ),
                if (nodes.isEmpty && widget.radio.isReady)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l.trcNoNodes),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text('$_error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                if (_result case final result?) ...[
                  const SizedBox(height: 16),
                  Text(
                    result.intermediateHops == 0
                        ? l.trcDirect
                        : l.trcRelays(result.intermediateHops),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (local != null && _sentAt != null && _roundTrip != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: FilledButton.tonalIcon(
                        key: const ValueKey('traceroute-open-card'),
                        onPressed: () => _openCard(result, local),
                        icon: const Icon(Icons.ios_share),
                        label: Text(AppLocalizations.of(context).tcOpen),
                      ),
                    ),
                  _RouteCard(
                    title: l.trcRouteThere,
                    start: l.trcThisRadio,
                    hops: result.towards,
                    name: _name,
                  ),
                  if (result.back.isNotEmpty)
                    _RouteCard(
                      title: l.trcRouteBack,
                      start: _name(_target!),
                      hops: result.back,
                      name: _name,
                    )
                  else
                    Card(
                      child: ListTile(
                        title: Text(l.trcRouteBack),
                        subtitle: Text(l.trcNoRouteBack),
                      ),
                    ),
                  if (local != null) ...[
                    if (RouteMapPath.of(result, local: local, destination: _target!,
                        hasPosition: _hasPosition) case final path when path.drawable)
                      TracerouteMap(path: path, nodes: widget.radio.nodes, name: _name)
                    else
                      Card(child: ListTile(
                        leading: const Icon(Icons.location_off_outlined),
                        title: Text(l.trcNoMap),
                        subtitle: Text(l.trcNoMapHelp),
                      )),
                  ],
                ],
              ],
            );
          },
        ),
      );
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.title,
    required this.start,
    required this.hops,
    required this.name,
  });

  final String title;
  final String start;
  final List<TracerouteHop> hops;
  final String Function(int) name;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(start),
              for (final hop in hops)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '↓ ${hop.snrDb == null ? AppLocalizations.of(context).trcSnrUnknown : '${hop.snrDb!.toStringAsFixed(1)} dB'}\n'
                    '${name(hop.nodeNum)}',
                  ),
                ),
            ],
          ),
        ),
      );
}
