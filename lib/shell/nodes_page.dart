part of '../main.dart';

class _NodesPage extends StatelessWidget {
  const _NodesPage({
    required this.discovery,
    required this.radio,
    required this.onOpenTools,
    this.onTryDemo,
  });
  final MeshtasticBleDiscovery discovery;
  final MeshtasticRadioCoordinator radio;
  final VoidCallback onOpenTools;

  /// Starts demo mode; null while it is already on.
  final VoidCallback? onTryDemo;

  Future<void> _connect(BuildContext context, MeshtasticBleDevice item) async {
    try {
      await radio.connect(item);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not connect: $error')),
        );
      }
    }
  }

  static const _lastHostKey = 'bastion.network.last_host';

  /// Lists USB devices and connects to the one picked.
  Future<void> _connectUsb(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showModalBottomSheet<UsbRadioInfo>(
      context: context,
      builder: (_) => const _UsbRadioSheet(),
    );
    if (picked == null) return;
    try {
      await radio.connect(MeshtasticBleDevice.usb(picked.deviceId, picked.name));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Could not connect over USB: $error')));
    }
  }

  /// Asks for a radio's network address and connects to it over TCP.
  Future<void> _connectNetwork(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    String? last;
    try {
      last = await SharedPreferencesAsync().getString(_lastHostKey);
    } catch (_) {
      // Remembering the address is a convenience.
    }
    if (!context.mounted) return;
    final address = await showDialog<({String host, int port})>(
      context: context,
      builder: (_) => _NetworkRadioDialog(initialHost: last ?? ''),
    );
    if (address == null) return;
    try {
      await SharedPreferencesAsync().setString(_lastHostKey, address.host);
    } catch (_) {
      // Remembering the address is a convenience.
    }
    try {
      await radio.connect(MeshtasticBleDevice.network(address.host, port: address.port));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Could not connect: $error')));
    }
  }

  Future<void> _editNote(BuildContext context, BastionNodeRecord record) async {
    final editor = TextEditingController(text: record.note);
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Notes for ${record.displayName}'),
        content: TextField(
          controller: editor,
          autofocus: true,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(
            labelText: 'Location, antenna, observations…',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, editor.text),
            child: const Text('Save')),
        ],
      ),
    );
    editor.dispose();
    if (note != null) await radio.setNodeNote(record.num, note);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([discovery, radio, BastionPreferences.instance]),
    builder: (context, _) {
      final scheme = Theme.of(context).colorScheme;
      final local = radio.localNode;
      final connectedName = radio.connection.deviceName;
      final heard = BastionPreferences.instance.heardWithin;
      final now = DateTime.now();
      final shown = [
        for (final n in radio.nodes)
          if (heard.matches(n.lastHeard, now, always: n.num == local?.num)) n,
      ];
      return ListView(
      padding: NxSpace.page,
      children: [
        NxPageHeader(
          title: 'Nodes',
          subtitle: radio.isReady
              ? 'Connected to ${local?.displayName ?? connectedName ?? 'your radio'}.'
              : 'Find your radio nearby and connect over Bluetooth.',
        ),
        if (BastionPreferences.instance.statistics) ...[
          NxStatRow(children: [
            NxStatTile(label: 'Radios found', value: '${discovery.results.length}'),
            NxStatTile(label: 'Mesh nodes', value: '${radio.nodes.length}'),
            NxStatTile(
              label: 'Status',
              value: _connectionLabel(context, radio.connection.state),
              tone: _connectionTone(radio.connection.state),
            ),
          ]),
          const SizedBox(height: NxSpace.sm),
        ],
        if (radio.connection.error != null)
          NxBanner(tone: NxTone.danger, title: 'Connection problem', message: radio.connection.error!,
            action: TextButton(
              key: const ValueKey('open-doctor'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ConnectionDoctorPage(radio: radio, discovery: discovery))),
              child: const Text('Diagnose'),
            )),
        if (radio.backgroundProblem != null)
          NxBanner(tone: NxTone.warning, message: radio.backgroundProblem!),
        if (radio.isReady)
          if (BastionFirmware.advice(radio.firmwareVersion) case final advice?)
            NxBanner(
              tone: radio.firmwareSupport == FirmwareSupport.unsupported ? NxTone.warning : NxTone.info,
              icon: Icons.system_update_alt,
              message: advice,
            ),
        const NxSectionLabel('Radios nearby'),
        if (discovery.scanning)
          Row(children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: NxSpace.sm),
            Expanded(child: Text('Looking for radios…', style: Theme.of(context).textTheme.bodyLarge)),
            TextButton(onPressed: discovery.stop, child: const Text('Stop scan')),
          ])
        else
          FilledButton.icon(
            onPressed: discovery.scan,
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Scan for radios'),
          ),
        const SizedBox(height: NxSpace.xs),
        if ((radio.usesNetworkLink || radio.usesUsbLink) && (radio.isReady || radio.isReconnecting || radio.busy))
          Card(child: ListTile(
            leading: Icon(radio.usesUsbLink ? Icons.usb : Icons.wifi),
            title: Text((radio.usesUsbLink ? radio.linkName : radio.networkHost) ?? 'Radio'),
            subtitle: Text('${radio.usesUsbLink ? 'Over USB' : 'Over Wi-Fi'} • ${_connectionLabel(context, radio.connection.state)}'),
            trailing: OutlinedButton(
              onPressed: radio.busy ? null : radio.disconnect,
              child: const Text('Disconnect', maxLines: 1, softWrap: false),
            ),
          ))
        else
          Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
            OutlinedButton.icon(
              onPressed: radio.busy ? null : () => _connectNetwork(context),
              icon: const Icon(Icons.wifi),
              label: const Text('Connect over Wi-Fi'),
            ),
            if (BastionUsb.supported)
              OutlinedButton.icon(
                onPressed: radio.busy ? null : () => _connectUsb(context),
                icon: const Icon(Icons.usb),
                label: const Text('Connect over USB'),
              ),
          ]),
        if (discovery.error != null)
          NxBanner(tone: NxTone.warning, message: discovery.error!),
        const SizedBox(height: NxSpace.xs),
        if (discovery.results.isEmpty && !discovery.scanning)
          NxEmptyState(icon: Icons.bluetooth_disabled,
            title: 'No radios found yet',
            detail: 'Turn your radio on, keep it close, then tap Scan for radios.',
            action: onTryDemo == null ? null : TextButton.icon(
              onPressed: onTryDemo,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('No radio? Try the demo'),
            ))
        else
          for (final item in discovery.results)
            Card(child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.surfaceContainerHigh,
                child: Icon(_signalIcon(item.rssi), color: scheme.onSurfaceVariant)),
              title: Text(item.name),
              subtitle: Text([
                item.advertisesMeshtastic ? 'Meshtastic radio' : 'Bluetooth device',
                _rssiLabel(item.rssi),
              ].join(' • ')),
              trailing: (radio.isReady || radio.isReconnecting) &&
                      radio.connection.deviceName == item.name
                  ? OutlinedButton(
                      onPressed: radio.busy ? null : radio.disconnect,
                      child: const Text('Disconnect', maxLines: 1, softWrap: false),
                    )
                  : FilledButton(
                      onPressed: radio.busy ? null : () => _connect(context, item),
                      child: const Text('Connect', maxLines: 1, softWrap: false),
                    ),
            )),
        if (radio.nodes.isNotEmpty) ...[
          NxSectionLabel(heard.window == null
              ? 'Mesh nodes (${radio.nodes.length})'
              : 'Mesh nodes (${shown.length} of ${radio.nodes.length})'),
          _HeardFilterChips(
            value: heard,
            onChanged: (v) => BastionPreferences.instance.update(heard: v),
          ),
          if (shown.isEmpty)
            NxEmptyState(icon: Icons.filter_alt_off_outlined,
              title: 'No nodes heard in the last ${heard.label}',
              detail: 'Pick a longer time to see older nodes.',
              action: TextButton(
                onPressed: () => BastionPreferences.instance.update(heard: BastionHeardWithin.any),
                child: const Text('Show all nodes'),
              ))
          else
          Card(child: Column(children: [
            for (final (i, node) in shown.indexed) ...[
              if (i > 0) const Divider(indent: 72),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text(_initials(node.shortName ?? node.displayName),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                title: Text(node.displayName),
                subtitle: Text([
                  if (node.shortName?.isNotEmpty ?? false) node.shortName!,
                  node.id ?? '!${node.num.toRadixString(16).padLeft(8, '0')}',
                ].join(' • ')),
                trailing: radio.nodeKeys.hasChanged(node.num)
                    ? Tooltip(message: 'Security key changed',
                        child: Icon(Icons.gpp_maybe_outlined, color: scheme.error, semanticLabel: 'Security key changed'))
                    : const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => NodeDetailPage(radio: radio, nodeNum: node.num),
                )),
              ),
            ],
          ])),
        ],
        if (radio.isReady && BastionPreferences.instance.meshHealth) ...[
          NxSectionLabel('Mesh health', trailing: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => MeshHealthPage(radio: radio))),
            child: const Text('Details'),
          )),
          NxStatRow(children: [
            NxStatTile(label: 'Known nodes', value: '${radio.nodes.length}'),
            NxStatTile(label: 'Messages', value: '${radio.messages.length}'),
            NxStatTile(label: 'Waiting to send', value: '${radio.pendingMessageCount}'),
          ]),
          const SizedBox(height: NxSpace.xs),
          Card(child: Padding(
            padding: const EdgeInsets.all(NxSpace.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Signal quality', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: NxSpace.xxs),
              Text('${radio.receivedTextPackets} messages heard • latest signal-to-noise '
                '${radio.latestSnr == null ? 'not yet measured' : '${radio.latestSnr!.toStringAsFixed(1)} dB'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: NxSpace.sm),
              if (radio.snrHistory.isNotEmpty)
                Semantics(
                  label: 'Signal history of the last ${radio.snrHistory.length.clamp(0, 20)} messages',
                  excludeSemantics: true,
                  child: Wrap(spacing: 4, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.end, children: [
                    for (final snr in radio.snrHistory.reversed.take(20).toList().reversed)
                      Tooltip(message: '${snr.toStringAsFixed(1)} dB',
                        child: Container(
                          width: 10,
                          height: 12 + (snr + 20).clamp(0, 40).toDouble(),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        )),
                  ]),
                )
              else
                const Text('Signal history starts when another node sends a message.'),
              const SizedBox(height: NxSpace.xs),
              Text('Measured from received text messages only.',
                style: Theme.of(context).textTheme.bodySmall),
            ]),
          )),
        ],
        if (radio.nodeDex.isNotEmpty && BastionPreferences.instance.encounters) ...[
          const NxSectionLabel('Saved encounters'),
          for (final record in radio.nodeDex)
            Card(child: ListTile(
              leading: Icon(record.favorite ? Icons.star : Icons.person_pin_circle_outlined,
                color: record.favorite ? scheme.primary : null),
              title: Text(record.displayName),
              subtitle: Text('Seen ${record.encounters} time${record.encounters == 1 ? '' : 's'} • last ${_ago(record.lastSeen)}'
                '\n${record.note.isEmpty ? 'Tap to add notes' : record.note}'),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: record.favorite ? 'Remove favorite' : 'Add to favorites',
                icon: Icon(record.favorite ? Icons.star : Icons.star_border),
                onPressed: () => radio.setNodeFavorite(record.num, !record.favorite),
              ),
              onTap: () => _editNote(context, record),
            )),
        ],
        const NxSectionLabel('More'),
        Card(child: ListTile(
          leading: const Icon(Icons.construction),
          title: const Text('Field tools'),
          subtitle: const Text('Signal reference, checklists, backups and more'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenTools,
        )),
        NxBanner(
          tone: radio.isReady ? NxTone.success : NxTone.neutral,
          message: radio.isReady
              ? 'Your radio is connected. Nodes update live as they are heard.'
              : 'Tap Scan for radios, then Connect. The app checks it is a Meshtastic radio and downloads its node list before it is ready to use.',
        ),
      ],
    );
    },
  );
}

/// Chips that limit the node list to nodes heard recently.
class _HeardFilterChips extends StatelessWidget {
  const _HeardFilterChips({required this.value, required this.onChanged});
  final BastionHeardWithin value;
  final ValueChanged<BastionHeardWithin> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: NxSpace.xs),
    child: Semantics(
      label: 'Show nodes heard within',
      child: Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
        for (final v in BastionHeardWithin.values)
          ChoiceChip(
            key: ValueKey('heard-${v.name}'),
            label: Text(v.label),
            selected: v == value,
            onSelected: (_) => onChanged(v),
          ),
      ]),
    ),
  );
}

/// Asks for the address of a radio on Wi-Fi or Ethernet.
class _NetworkRadioDialog extends StatefulWidget {
  const _NetworkRadioDialog({required this.initialHost});
  final String initialHost;

  @override
  State<_NetworkRadioDialog> createState() => _NetworkRadioDialogState();
}

class _NetworkRadioDialogState extends State<_NetworkRadioDialog> {
  late final _host = TextEditingController(text: widget.initialHost);
  final _port = TextEditingController(text: '4403');

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  /// A host name or IPv4/IPv6 address, without spaces or a scheme.
  static bool validHost(String host) =>
      host.isNotEmpty && host.length <= 253 && !host.contains(RegExp(r'[\s/]')) && !host.contains('://');

  @override
  Widget build(BuildContext context) {
    final host = _host.text.trim();
    final port = int.tryParse(_port.text.trim());
    final ok = validHost(host) && port != null && port > 0 && port < 65536;
    return AlertDialog(
      title: const Text('Connect over Wi-Fi'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('For radios with Wi-Fi or Ethernet turned on. Your phone must be on the same network.'),
        const SizedBox(height: NxSpace.sm),
        TextField(
          controller: _host,
          autofocus: true,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Radio address', hintText: 'e.g. 192.168.1.42 or meshtastic.local'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NxSpace.sm),
        TextField(
          controller: _port,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Port', helperText: 'Meshtastic uses 4403'),
          onChanged: (_) => setState(() {}),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: ok ? () => Navigator.pop(context, (host: host, port: port)) : null,
          child: const Text('Connect'),
        ),
      ],
    );
  }
}

/// USB devices plugged into the phone, likely radios first.
class _UsbRadioSheet extends StatefulWidget {
  const _UsbRadioSheet();

  @override
  State<_UsbRadioSheet> createState() => _UsbRadioSheetState();
}

class _UsbRadioSheetState extends State<_UsbRadioSheet> {
  late Future<List<UsbRadioInfo>> _devices = _load();

  Future<List<UsbRadioInfo>> _load() async =>
      [...await BastionUsb.gateway.list()]..sort((a, b) => (b.likelyRadio ? 1 : 0) - (a.likelyRadio ? 1 : 0));

  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(
    padding: const EdgeInsets.fromLTRB(NxSpace.md, 0, NxSpace.md, NxSpace.md),
    child: FutureBuilder<List<UsbRadioInfo>>(
      future: _devices,
      builder: (context, snap) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Connect over USB', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: NxSpace.xxs),
        const Text('Plug the radio into the phone with a USB data cable (an OTG adapter may be needed). '
            'Android asks for permission the first time.'),
        const SizedBox(height: NxSpace.sm),
        if (snap.connectionState != ConnectionState.done)
          const Center(child: Padding(padding: EdgeInsets.all(NxSpace.md), child: CircularProgressIndicator()))
        else if (snap.hasError)
          NxBanner(tone: NxTone.danger, message: 'Could not list USB devices: ${snap.error}')
        else if (snap.data!.isEmpty)
          const NxEmptyState(icon: Icons.usb_off, title: 'No USB devices found',
            detail: 'Check the cable carries data, not just power, then refresh.')
        else
          for (final d in snap.data!)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(d.likelyRadio ? Icons.settings_input_antenna : Icons.usb),
              title: Text(d.name),
              subtitle: Text(d.likelyRadio ? 'Likely a radio • ${d.chip}' : 'Other USB device'),
              trailing: FilledButton(onPressed: () => Navigator.pop(context, d), child: const Text('Connect')),
            ),
        TextButton.icon(
          onPressed: () => setState(() => _devices = _load()),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ]),
    ),
  ));
}
