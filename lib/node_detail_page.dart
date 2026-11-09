import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';

import 'services/bastion_hardware.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_units.dart';
import 'services/bastion_chat_message.dart';
import 'services/bastion_geo.dart';
import 'services/bastion_nodedex.dart';
import 'services/meshtastic_node_database.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'services/bastion_node_keys.dart';
import 'telemetry_chart.dart';
import 'theme/notoryx_theme.dart';
import 'theme/nx_components.dart';
import 'remote_admin_page.dart';
import 'traceroute_page.dart';

/// Everything known about one mesh node, with actions to reach it.
class NodeDetailPage extends StatefulWidget {
  const NodeDetailPage({super.key, required this.radio, required this.nodeNum});

  final MeshtasticRadioCoordinator radio;
  final int nodeNum;

  @override
  State<NodeDetailPage> createState() => _NodeDetailPageState();
}

class _NodeDetailPageState extends State<NodeDetailPage> {
  final _message = TextEditingController();
  bool _sending = false;

  AppLocalizations get l => AppLocalizations.of(context);

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  MeshtasticRadioCoordinator get _radio => widget.radio;

  MeshtasticNode? get _node {
    for (final node in _radio.nodes) {
      if (node.num == widget.nodeNum) return node;
    }
    return null;
  }

  BastionNodeRecord? get _record {
    for (final record in _radio.nodeDex) {
      if (record.num == widget.nodeNum) return record;
    }
    return null;
  }

  String get _hexId => '!${widget.nodeNum.toRadixString(16).padLeft(8, '0')}';

  Future<void> _run(Future<void> Function() action, String done) async {
    final l = this.l;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l.ndFailed('$error'))));
    }
  }

  Future<void> _sendDirect() async {
    final text = _message.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final l = this.l;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _radio.sendText(text: text, destination: widget.nodeNum);
      _message.clear();
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l.ndSendFailed('$error'))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editNote(BastionNodeRecord? record) async {
    final controller = TextEditingController(text: record?.note ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.ndFieldNote),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: InputDecoration(labelText: l.ndFieldNote),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note != null) await _radio.setNodeNote(widget.nodeNum, note);
  }

  String _ago(DateTime? time) {
    if (time == null) return l.mapUnknown;
    final d = DateTime.now().difference(time);
    if (d.inMinutes < 1) return l.agoNow;
    if (d.inHours < 1) return l.agoMin(d.inMinutes);
    if (d.inDays < 1) return l.agoHours(d.inHours);
    return l.agoDays(d.inDays);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _radio,
    builder: (context, _) {
      final node = _node;
      final record = _record;
      final telemetry = _radio.deviceTelemetry[widget.nodeNum];
      final local = _radio.localNode;
      final isSelf = widget.nodeNum == _radio.localNodeNum;
      final ready = _radio.isReady && !isSelf;
      final distance =
          node != null &&
              node.hasPosition &&
              local != null &&
              local.hasPosition &&
              !isSelf
          ? BastionGeo.distanceMeters(
              local.latitude!,
              local.longitude!,
              node.latitude!,
              node.longitude!,
            )
          : null;
      final battery = telemetry?.batteryLevel ?? node?.batteryLevel;
      final directMessages = _radio.messages
          .where(
            (m) =>
                (m.direction == BastionMessageDirection.incoming &&
                    m.from == widget.nodeNum &&
                    !m.isBroadcast) ||
                (m.direction == BastionMessageDirection.outgoing &&
                    m.to == widget.nodeNum),
          )
          .toList();
      final recent = directMessages.length > 20
          ? directMessages.sublist(directMessages.length - 20)
          : directMessages;

      return Scaffold(
        appBar: AppBar(
          title: Text(node?.displayName ?? record?.displayName ?? _hexId),
          actions: [
            IconButton(
              tooltip: (record?.favorite ?? false)
                  ? l.ndRemoveFavorite
                  : l.ndAddFavorite,
              icon: Icon(
                (record?.favorite ?? false) ? Icons.star : Icons.star_border,
              ),
              onPressed: () => _radio.setNodeFavorite(
                widget.nodeNum,
                !(record?.favorite ?? false),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Row('ID', node?.id ?? _hexId),
                    if (node?.shortName != null)
                      _Row(l.ndShortName, node!.shortName!),
                    if (node?.hardwareModel != null)
                      _Row(l.ndHardware, BastionHardware.name(node!.hardwareModel!)),
                    if (isSelf) _Row(l.ndThisRadio, l.ndYes),
                    _Row(
                      l.ndLastHeard,
                      _ago(node?.lastHeard ?? record?.lastSeen),
                    ),
                    if (node?.snr != null)
                      _Row('SNR', '${node!.snr!.toStringAsFixed(1)} dB')
                    else if (node?.noRfReason case final reason?)
                      _Row(l.ndSignal, reason),
                    if (node?.hopsAway != null)
                      _Row(
                        l.ndHopsAway,
                        node!.hopsAway == 0 ? l.ndDirect : '${node.hopsAway}',
                      ),
                    if (battery != null)
                      _Row(
                        l.ndBattery,
                        battery > 100 ? l.ndExternalPower : '$battery%',
                      ),
                    if (telemetry?.voltage != null)
                      _Row(
                        l.ndVoltage,
                        '${telemetry!.voltage!.toStringAsFixed(2)} V',
                      ),
                    if (telemetry?.channelUtilization != null)
                      _Row(
                        l.ndChannelUse,
                        '${telemetry!.channelUtilization!.toStringAsFixed(1)}%',
                      ),
                    for (final metric in _radio.telemetryMetricsOf(widget.nodeNum))
                      if (metric.isEnvironment)
                        _Row(metric.label, metric.format(
                          _radio.telemetrySeries(widget.nodeNum, metric).last.value,
                          BastionPreferences.instance.units)),
                    if (node != null && node.hasPosition) ...[
                      _Row(
                        l.ndPosition,
                        '${node.latitude!.toStringAsFixed(5)}, ${node.longitude!.toStringAsFixed(5)}',
                      ),
                      if (node.altitudeMeters != null)
                        _Row(l.ndAltitude, BastionUnitFormat.altitude(node.altitudeMeters!, BastionPreferences.instance.units)),
                      _Row(l.ndPositionAge, _ago(node.positionTime)),
                    ],
                    if (distance != null)
                      _Row(
                        l.ndDistance,
                        BastionUnitFormat.distance(distance, BastionPreferences.instance.units),
                      ),
                    if (record != null)
                      _Row(l.ndEncounters, '${record.encounters}'),
                  ],
                ),
              ),
            ),
            if (!isSelf) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.route),
                    label: Text(l.ndTraceroute),
                    onPressed: ready
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TraceroutePage(
                                radio: _radio,
                                initialTarget: widget.nodeNum,
                              ),
                            ),
                          )
                        : null,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.my_location),
                    label: Text(l.ndRequestPosition),
                    onPressed: ready
                        ? () => _run(
                            () => _radio.requestPosition(widget.nodeNum),
                            l.ndPositionRequested,
                          )
                        : null,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.battery_unknown),
                    label: Text(l.ndRequestTelemetry),
                    onPressed: ready
                        ? () => _run(
                            () => _radio.requestTelemetry(widget.nodeNum),
                            l.ndTelemetryRequested,
                          )
                        : null,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: Text(l.ndRemoteAdmin),
                    onPressed: ready
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => RemoteAdminPage(radio: _radio, nodeNum: widget.nodeNum),
                            ),
                          )
                        : null,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.thermostat),
                    label: Text(l.ndRequestSensors),
                    onPressed: ready
                        ? () => _run(
                            () => _radio.requestEnvironmentTelemetry(widget.nodeNum),
                            l.ndSensorsRequested,
                          )
                        : null,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            TelemetryHistoryCard(
              metrics: _radio.telemetryMetricsOf(widget.nodeNum),
              series: (metric) => _radio.telemetrySeries(widget.nodeNum, metric),
            ),
            if (!isSelf) _KeyCard(radio: _radio, nodeNum: widget.nodeNum),
            _NeighborCard(radio: _radio, nodeNum: widget.nodeNum),
            const SizedBox(height: 8),
            Card(
              child: Column(children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_off_outlined),
                  title: Text(l.ndMute),
                  subtitle: Text(l.ndMuteSub),
                  value: _radio.filters.muted.contains(widget.nodeNum),
                  onChanged: (v) => _radio.filters.setMuted(widget.nodeNum, v),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.block),
                  title: Text(l.ndIgnore),
                  subtitle: Text(l.ndIgnoreSub),
                  isThreeLine: true,
                  value: _radio.filters.isIgnored(widget.nodeNum),
                  onChanged: (v) => _radio.filters.setIgnored(widget.nodeNum, v),
                ),
              ]),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(l.ndFieldNote),
                subtitle: Text(
                  (record?.note.isEmpty ?? true)
                      ? l.ndAddNote
                      : record!.note,
                ),
                onTap: () => _editNote(record),
              ),
            ),
            if (!isSelf) ...[
              const SizedBox(height: 16),
              Text(
                l.ndDirectMessages,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (recent.isEmpty)
                Text(
                  l.ndNoDirect,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              for (final m in recent)
                Align(
                  alignment: m.direction == BastionMessageDirection.outgoing
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(m.text),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      enabled: _radio.isReady,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: l.ndDirectMessage,
                      ),
                      onSubmitted: (_) => _sendDirect(),
                    ),
                  ),
                  IconButton(
                    tooltip: l.ndSend,
                    icon: const Icon(Icons.send),
                    onPressed: _radio.isReady && !_sending ? _sendDirect : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

/// Direct radio links for one node, from Neighbor Info reports in both
/// directions: nodes it reports hearing, and nodes that report hearing it.
class _NeighborCard extends StatelessWidget {
  const _NeighborCard({required this.radio, required this.nodeNum});

  final MeshtasticRadioCoordinator radio;
  final int nodeNum;

  String _name(int num) {
    for (final node in radio.nodes) {
      if (node.num == num) return node.displayName;
    }
    return '!${num.toRadixString(16).padLeft(8, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reports = radio.neighborReports;
    final own = reports[nodeNum];
    final heardBy = [
      for (final report in reports.values)
        for (final n in report.neighbors)
          if (n.nodeNum == nodeNum && report.nodeNum != nodeNum)
            (nodeNum: report.nodeNum, snr: n.snr),
    ];
    String line(({int nodeNum, double snr}) n) =>
        '${_name(n.nodeNum)} • ${n.snr.toStringAsFixed(1)} dB';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.ndRadioLinks,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (own == null && heardBy.isEmpty)
              Text(
                l.ndNoNeighbors,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            if (own != null) ...[
              Text(l.ndHears(own.neighbors.length)),
              for (final n in own.neighbors) Text('  ${line(n)}'),
              if (own.neighbors.isEmpty) Text(l.ndNoneReported),
            ],
            if (heardBy.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(l.ndHeardBy(heardBy.length)),
              for (final n in heardBy) Text('  ${line(n)}'),
            ],
          ],
        ),
      ),
    );
  }
}

/// The node's security key as a short code, with a warning and a way to
/// accept it when the key has changed.
class _KeyCard extends StatelessWidget {
  const _KeyCard({required this.radio, required this.nodeNum});
  final MeshtasticRadioCoordinator radio;
  final int nodeNum;

  Future<void> _trust(BuildContext context, String name) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(l.ndTrustQ),
      content: Text(l.ndTrustBody(name)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(l.ndTrust)),
      ],
    ));
    if (ok == true) await radio.trustNodeKey(nodeNum);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final keys = radio.nodeKeys;
    final known = keys.knownKey(nodeNum);
    final changed = keys.changedKey(nodeNum);
    final name = radio.nodeName(nodeNum);
    final type = Theme.of(context).textTheme;
    if (changed != null) {
      return NxBanner(
        tone: NxTone.danger,
        icon: Icons.gpp_maybe_outlined,
        title: l.ndKeyChanged,
        message: l.ndKeyChangedBody(BastionNodeKeys.safetyCode(changed),
            known == null ? l.mapUnknown : BastionNodeKeys.safetyCode(known)),
        action: OutlinedButton(onPressed: () => _trust(context, name), child: Text(l.ndTrust)),
      );
    }
    return Card(child: ListTile(
      leading: const Icon(Icons.key_outlined),
      title: Text(l.ndSecurityKey),
      subtitle: Text(known == null
          ? l.ndKeyNotShared
          : l.ndSafetyCode(BastionNodeKeys.safetyCode(known)),
          style: type.bodyMedium),
      isThreeLine: known != null,
    ));
  }
}
