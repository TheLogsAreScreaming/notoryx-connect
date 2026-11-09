import 'dart:convert';

import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';

import 'theme/nx_components.dart';

import 'channel_share_page.dart';
import 'services/bastion_beacons.dart';
import 'services/bastion_plus_code.dart';
import 'services/meshtastic_radio_coordinator.dart';

/// Mesh Beacons: invitations heard on the mesh, and sending one by hand.
class BeaconPage extends StatefulWidget {
  const BeaconPage({super.key, required this.radio});
  final MeshtasticRadioCoordinator radio;
  @override
  State<BeaconPage> createState() => _BeaconPageState();
}

class _BeaconPageState extends State<BeaconPage> {
  final _message = TextEditingController();
  bool _offerChannel = false;
  bool _sending = false;
  String? _status;

  /// This radio's position as a Plus Code; null until it has a position.
  String? get _plusCode {
    final radio = widget.radio;
    final me = radio.nodes.where((n) => n.num == radio.localNodeNum && n.hasPosition).firstOrNull;
    return me == null ? null : BastionPlusCode.encode(me.latitude!, me.longitude!);
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  int get _bytes => utf8.encode(_message.text).length;

  AppLocalizations get l => AppLocalizations.of(context);

  Future<void> _send() async {
    final l = this.l;
    final offer = _offerChannel;
    if (offer) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.bcShareQ),
          content: Text(l.bcShareBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.bcShare)),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      _sending = true;
      _status = null;
    });
    try {
      await widget.radio.sendBeacon(_message.text, offerPrimaryChannel: offer);
      if (!mounted) return;
      setState(() => _status = l.bcSent);
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = switch (error) {
        ArgumentError(:final message) => '$message',
        StateError(:final message) => message,
        _ => l.bcNotSent('$error'),
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l.bcTitle), actions: [
      AnimatedBuilder(
        animation: widget.radio,
        builder: (context, _) => IconButton(
          tooltip: l.bcClear,
          icon: const Icon(Icons.delete_sweep_outlined),
          onPressed: widget.radio.beacons.isEmpty ? null : widget.radio.clearBeacons,
        ),
      ),
    ]),
    body: SafeArea(top: false, child: AnimatedBuilder(
      animation: widget.radio,
      builder: (context, _) {
        final radio = widget.radio;
        final next = radio.nextBeaconAllowed;
        final canSend = radio.isReady && next == null && !_sending &&
            _message.text.trim().isNotEmpty && _bytes <= BastionBeaconLog.maxMessageBytes;
        return ListView(padding: const EdgeInsets.all(16), children: [
          Text(l.bcIntro),
          const SizedBox(height: 16),
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(l.bcSendTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(
                controller: _message,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l.bcMessage,
                  helperText: l.bcMessageHelp,
                  helperMaxLines: 2,
                  counterText: l.bcBytes(_bytes, BastionBeaconLog.maxMessageBytes),
                  errorText: _bytes > BastionBeaconLog.maxMessageBytes ? l.bcTooLong : null,
                ),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  key: const ValueKey('beacon-plus-code'),
                  onPressed: _plusCode == null ? null : () => setState(() {
                    final text = _message.text.trimRight();
                    _message.text = text.isEmpty ? _plusCode! : '$text $_plusCode';
                  }),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: Text(_plusCode == null ? l.bcAddLocationNone : l.bcAddLocation),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l.bcInvite),
                subtitle: Text(l.bcInviteSub),
                value: _offerChannel,
                onChanged: (value) => setState(() => _offerChannel = value),
              ),
              FilledButton.icon(
                onPressed: canSend ? _send : null,
                icon: const Icon(Icons.campaign_outlined),
                label: Text(_sending ? l.bcSending : l.bcSend),
              ),
              if (!radio.isReady)
                Padding(padding: const EdgeInsets.only(top: 8),
                  child: Text(l.bcConnect))
              else if (next != null)
                Padding(padding: const EdgeInsets.only(top: 8),
                  child: Text(l.bcNext(_time(next)))),
              if (_status != null)
                Semantics(liveRegion: true, child: Padding(
                  padding: const EdgeInsets.only(top: 8), child: Text(_status!))),
            ]),
          )),
          NxSectionLabel(l.bcHeard),
          if (radio.beacons.isEmpty)
            Card(child: ListTile(
              leading: const Icon(Icons.wifi_tethering_off),
              title: Text(l.bcNoneHeard),
              subtitle: Text(l.bcNoneHeardSub),
            )),
          for (final beacon in radio.beacons) _BeaconCard(radio: radio, beacon: beacon),
        ]);
      },
    )),
  );
}

class _BeaconCard extends StatelessWidget {
  const _BeaconCard({required this.radio, required this.beacon});
  final MeshtasticRadioCoordinator radio;
  final HeardBeacon beacon;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final details = [
      l.bcFrom(radio.nodeName(beacon.from)),
      l.bcHeardAt(_time(beacon.heardAt)),
      if (beacon.snr != null) 'SNR ${beacon.snr!.toStringAsFixed(1)} dB',
      if (beacon.rssi != null) 'RSSI ${beacon.rssi} dBm',
    ].join(' • ');
    final offer = [
      if (beacon.offerChannel != null)
        l.bcChannel(beacon.offerChannel!.name.isEmpty ? l.bcDefault : beacon.offerChannel!.name),
      if (beacon.offerRegion != null) l.bcRegion(beacon.offerRegion!.name),
      if (beacon.offerPreset != null) l.bcPreset(beacon.offerPreset!.name),
      if (beacon.offerFrequencySlot != null) l.bcSlot(beacon.offerFrequencySlot!),
    ].join(', ');
    final link = beacon.joinLink;
    return Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(beacon.message.isEmpty ? l.bcNoMessage : beacon.message,
          style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(details, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        if (offer.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(l.bcInvitesTo(offer)),
        ],
        if (link != null) ...[
          const SizedBox(height: 8),
          Align(alignment: AlignmentDirectional.centerStart, child: OutlinedButton.icon(
            icon: const Icon(Icons.group_add_outlined),
            label: Text(l.bcJoin),
            onPressed: radio.isReady ? () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => ChannelImportPage(radio: radio, initialLink: link))) : null,
          )),
        ],
      ]),
    ));
  }
}

String _time(DateTime time) {
  final local = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  final now = DateTime.now();
  final sameDay = local.year == now.year && local.month == now.month && local.day == now.day;
  return sameDay
      ? '${two(local.hour)}:${two(local.minute)}'
      : '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}
