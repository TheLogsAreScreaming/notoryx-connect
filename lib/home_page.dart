import 'dart:async';

import 'package:flutter/material.dart';

import 'services/bastion_chat_message.dart';
import 'services/bastion_trip.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';
import 'trip_page.dart';

/// HOME: the Field Console, with the trip, check-ins and SOS up front.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.radio, required this.onConnect, this.onTryDemo});
  final MeshtasticRadioCoordinator radio;

  /// Starts demo mode; null while it is already on.
  final VoidCallback? onTryDemo;

  /// Opens the NODES tab to connect a radio.
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: radio,
    builder: (context, _) {
      final trip = radio.trip;
      final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant);
      return ListView(padding: NxSpace.page, children: [
        if (trip.sos.active) ...[_SosBanner(trip: trip), const SizedBox(height: NxSpace.sm)],
        _ConsoleCard(radio: radio, onConnect: onConnect, onTryDemo: onTryDemo),
        _TripCard(radio: radio),
        const NxSectionLabel('Check in'),
        _CheckInButtons(radio: radio),
        const NxSectionLabel('Emergency'),
        _SosButton(trip: trip),
        const SizedBox(height: NxSpace.xs),
        Text(trip.sosBlocked ??
            'Hold for 2 seconds. It goes to your trip contacts${trip.plan.sosChannel >= 0 ? ' and channel ${trip.plan.sosChannel}' : ''}, '
            'and repeats every 5 minutes until someone replies.',
          style: muted),
        if (trip.problem != null)
          NxBanner(tone: NxTone.danger, message: trip.problem!),
        const SizedBox(height: NxSpace.md),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: NxSpace.xs),
          Expanded(child: Text('Sent or queued does not mean received. Confirm with a reply or a call.',
            style: Theme.of(context).textTheme.bodySmall)),
        ]),
      ]);
    },
  );
}

class _ConsoleCard extends StatelessWidget {
  const _ConsoleCard({required this.radio, required this.onConnect, this.onTryDemo});
  final MeshtasticRadioCoordinator radio;
  final VoidCallback onConnect;
  final VoidCallback? onTryDemo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final status = NxStatusColors.of(context);
    final node = radio.localNode;
    final battery = node?.batteryLevel;
    final ready = radio.isReady;
    final tone = ready ? NxTone.success : NxTone.neutral;
    return Card(child: Padding(
      padding: const EdgeInsets.all(NxSpace.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: ready ? status.successContainer : scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(NxRadius.md),
            ),
            child: Icon(ready ? Icons.settings_input_antenna : Icons.portable_wifi_off,
              color: status.strong(tone, scheme)),
          ),
          const SizedBox(width: NxSpace.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Semantics(header: true, child: Text(ready ? 'Radio connected' : 'No radio connected',
              style: type.titleMedium)),
            const SizedBox(height: 2),
            Text(ready
                ? (node == null ? 'Your radio' : node.longName ?? node.shortName ?? 'Your radio')
                : 'Connect to check in, send an SOS and see the mesh.',
              style: type.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: NxSpace.sm),
        if (ready)
          NxStatRow(children: [
            NxStatTile(label: 'Nodes', value: '${radio.nodes.length}', icon: Icons.hub_outlined),
            NxStatTile(
              label: 'Battery',
              icon: battery != null && battery > 100 ? Icons.power : Icons.battery_std,
              value: battery == null ? 'Unknown' : battery > 100 ? 'Plugged in' : '$battery%',
              tone: battery != null && battery <= 20 ? NxTone.warning : NxTone.neutral,
            ),
          ])
        else
          Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
            FilledButton.icon(onPressed: onConnect, icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Connect radio')),
            if (onTryDemo != null)
              TextButton.icon(onPressed: onTryDemo, icon: const Icon(Icons.play_circle_outline),
                label: const Text('Try the demo')),
          ]),
      ]),
    ));
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.radio});
  final MeshtasticRadioCoordinator radio;

  @override
  Widget build(BuildContext context) {
    final trip = radio.trip;
    final plan = trip.plan;
    final overdue = trip.overdue;
    final status = [
      plan.active ? 'Trip running' : 'Trip not started',
      '${plan.members.length} contact${plan.members.length == 1 ? '' : 's'}',
    ].join(' • ');
    final scheme = Theme.of(context).colorScheme;
    return Card(child: ListTile(
      leading: Icon(Icons.hiking, color: overdue.isEmpty ? scheme.primary : scheme.error),
      title: Text(plan.active ? 'Trip: ${plan.name}' : 'Plan your trip'),
      subtitle: Text(overdue.isEmpty
          ? status
          : '$status\nOverdue: ${overdue.map(radio.nodeName).join(', ')}'),
      isThreeLine: overdue.isNotEmpty,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => TripPage(radio: radio))),
    ));
  }
}

class _CheckInButtons extends StatefulWidget {
  const _CheckInButtons({required this.radio});
  final MeshtasticRadioCoordinator radio;
  @override
  State<_CheckInButtons> createState() => _CheckInButtonsState();
}

class _CheckInButtonsState extends State<_CheckInButtons> {
  bool _sending = false;
  String? _error;

  Future<void> _checkIn(String label) async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.radio.trip.checkIn(label);
    } catch (e) {
      if (mounted) setState(() => _error = e is StateError ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.radio.trip;
    final blocked = trip.checkInBlocked;
    final enabled = blocked == null && !_sending;
    final last = trip.lastCheckIn;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton.icon(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(NxTouch.large)),
        onPressed: enabled ? () => _checkIn(checkInLabels.first) : null,
        icon: _sending
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
            : const Icon(Icons.check_circle_outline),
        label: Text("Check in: ${checkInLabels.first}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: NxSpace.xs),
      Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
        for (final label in checkInLabels.skip(1))
          OutlinedButton(onPressed: enabled ? () => _checkIn(label) : null, child: Text(label)),
      ]),
      const SizedBox(height: NxSpace.xs),
      if (blocked != null)
        Text(blocked, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant))
      else if (last != null)
        _Delivery(radio: widget.radio, record: last),
      if (_error != null)
        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    ]);
  }
}

class _Delivery extends StatelessWidget {
  const _Delivery({required this.radio, required this.record});
  final MeshtasticRadioCoordinator radio;
  final CheckInRecord record;

  @override
  Widget build(BuildContext context) {
    final delivery = radio.trip.delivery(record);
    final delivered = delivery.values.where((s) => s == BastionDeliveryState.delivered).length;
    final failed = [for (final e in delivery.entries) if (e.value == BastionDeliveryState.failed) e.key];
    final waiting = delivery.length - delivered - failed.length;
    final parts = [
      '${record.label} at ${_time(record.at)}: delivered to $delivered of ${delivery.length}',
      if (failed.isNotEmpty) 'not delivered to ${failed.map(radio.nodeName).join(', ')}',
      if (waiting > 0) '$waiting waiting',
    ];
    return Row(children: [
      Expanded(child: Text(parts.join(' • '))),
      if (failed.isNotEmpty)
        TextButton(onPressed: radio.trip.resendFailed, child: const Text('Resend')),
    ]);
  }
}

/// Hold for 2 seconds to start an SOS, so it can't be sent by accident.
class _SosButton extends StatefulWidget {
  const _SosButton({required this.trip});
  final BastionTripController trip;
  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hold.reset();
        unawaited(_start());
      }
    });
  String? _error;

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      await widget.trip.startSos();
    } catch (e) {
      if (mounted) setState(() => _error = e is StateError ? e.message : '$e');
    }
  }

  /// Screen readers can't hold, so they confirm in a dialog instead.
  Future<void> _confirm() async {
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Send SOS?'),
      content: const Text('Your SOS repeats every 5 minutes until someone replies or you stop it.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send SOS')),
      ],
    ));
    if (ok == true) await _start();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.trip.sosBlocked == null && !widget.trip.sos.active;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(
        button: true,
        enabled: enabled,
        label: 'Hold for SOS',
        onTap: enabled ? _confirm : null,
        excludeSemantics: true,
        child: GestureDetector(
          onTapDown: enabled ? (_) => _hold.forward() : null,
          onTapUp: (_) => _hold.reverse(),
          onTapCancel: () => _hold.reverse(),
          child: AnimatedBuilder(
            animation: _hold,
            builder: (context, _) => Container(
              height: NxTouch.large,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(NxRadius.md),
                border: enabled ? null : Border.all(color: scheme.outlineVariant),
                color: enabled ? scheme.errorContainer : scheme.surfaceContainerHighest,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(children: [
                FractionallySizedBox(widthFactor: _hold.value,
                  child: Container(color: scheme.error.withValues(alpha: .45))),
                Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.sos, color: enabled ? scheme.onErrorContainer : scheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Text('Hold for SOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: enabled ? scheme.onErrorContainer : scheme.onSurfaceVariant)),
                ])),
              ]),
            ),
          ),
        ),
      ),
      if (_error != null)
        Padding(padding: const EdgeInsets.only(top: 6),
          child: Text(_error!, style: TextStyle(color: scheme.error))),
    ]);
  }
}

class _SosBanner extends StatelessWidget {
  const _SosBanner({required this.trip});
  final BastionTripController trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sos = trip.sos;
    final next = sos.nextSendAt;
    final detail = sos.acknowledgedBy != null
        ? '${sos.acknowledgedBy} replied. Repeats stopped.'
        : next != null
            ? 'Sent ${sos.sends} of $sosMaxSends. Next at ${_time(next)}.'
            : 'Sent $sosMaxSends times. Repeats finished; the SOS stays shown until you stop it.';
    return Semantics(liveRegion: true, child: Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(Icons.sos, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Text('SOS active', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onErrorContainer)),
          ]),
          const SizedBox(height: 6),
          Text(detail, style: TextStyle(color: scheme.onErrorContainer)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton(onPressed: () => trip.stopSos(allClear: true), child: const Text("I'm safe")),
            OutlinedButton(onPressed: trip.stopSos, child: const Text('Stop without message')),
          ]),
        ]),
      ),
    ));
  }
}

String _time(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
