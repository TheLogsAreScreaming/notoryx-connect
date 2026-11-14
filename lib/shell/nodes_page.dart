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
          SnackBar(content: Text(AppLocalizations.of(context).nodesConnectFailed('$error'))),
        );
      }
    }
  }

  static const _lastHostKey = 'bastion.network.last_host';

  /// Lists USB devices and connects to the one picked.
  Future<void> _connectUsb(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await showModalBottomSheet<UsbRadioInfo>(
      context: context,
      builder: (_) => const _UsbRadioSheet(),
    );
    if (picked == null) return;
    try {
      await radio.connect(MeshtasticBleDevice.usb(picked.deviceId, picked.name));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l.nodesUsbFailed('$error'))));
    }
  }

  /// Asks for a radio's network address and connects to it over TCP.
  Future<void> _connectNetwork(BuildContext context) async {
    final l = AppLocalizations.of(context);
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
      messenger.showSnackBar(SnackBar(content: Text(l.nodesConnectFailed('$error'))));
    }
  }

  Future<void> _editNote(BuildContext context, BastionNodeRecord record) async {
    final l = AppLocalizations.of(context);
    final editor = TextEditingController(text: record.note);
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.nodesNotesFor(record.displayName)),
        content: TextField(
          controller: editor,
          autofocus: true,
          maxLines: 3,
          maxLength: 300,
          decoration: InputDecoration(
            labelText: l.nodesNotesHint,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, editor.text),
            child: Text(l.commonSave)),
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
      final l = AppLocalizations.of(context);
      final scheme = Theme.of(context).colorScheme;
      final local = radio.localNode;
      final connectedName = radio.connection.deviceName;
      final heard = BastionPreferences.instance.heardWithin;
      final favoritesOnly = BastionPreferences.instance.favoritesOnly;
      final favorites = radio.favoriteNums;
      final now = DateTime.now();
      final shown = [
        for (final n in radio.nodes)
          if (heard.matches(n.lastHeard, now, always: n.num == local?.num) &&
              (!favoritesOnly || n.num == local?.num || favorites.contains(n.num)))
            n,
      ];
      return ListView(
      padding: NxSpace.page,
      children: [
        NxPageHeader(
          title: l.tabNodes,
          subtitle: radio.isReady
              ? l.nodesConnectedTo(local?.displayName ?? connectedName ?? l.nodesYourRadio)
              : l.nodesFindRadio,
        ),
        if (BastionPreferences.instance.statistics) ...[
          NxStatRow(children: [
            NxStatTile(label: l.nodesRadiosFound, value: '${discovery.results.length}'),
            NxStatTile(label: l.nodesMeshNodes, value: '${radio.nodes.length}'),
            NxStatTile(
              label: l.nodesStatus,
              value: _connectionLabel(context, radio.connection.state),
              tone: _connectionTone(radio.connection.state),
            ),
          ]),
          const SizedBox(height: NxSpace.sm),
        ],
        if (radio.connection.error != null)
          NxBanner(tone: NxTone.danger, title: l.nodesConnProblem, message: radio.connection.error!,
            action: TextButton(
              key: const ValueKey('open-doctor'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ConnectionDoctorPage(radio: radio, discovery: discovery))),
              child: Text(l.nodesDiagnose),
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
        NxSectionLabel(l.nodesNearby),
        if (discovery.scanning)
          Row(children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: NxSpace.sm),
            Expanded(child: Text(l.nodesLooking, style: Theme.of(context).textTheme.bodyLarge)),
            TextButton(onPressed: discovery.stop, child: Text(l.nodesStopScan)),
          ])
        else
          FilledButton.icon(
            onPressed: discovery.scan,
            icon: const Icon(Icons.bluetooth_searching),
            label: Text(l.toolsScan),
          ),
        const SizedBox(height: NxSpace.xs),
        // Every link type (Bluetooth too) gets a connected-radio card with a
        // Disconnect button, so it never depends on the radio showing up in
        // the scan list (it doesn't after an auto-reconnect at launch).
        if ((radio.usesNetworkLink || radio.usesUsbLink || radio.connection.deviceName != null) &&
            (radio.isReady || radio.isReconnecting || radio.busy))
          Card(key: const ValueKey('connected-radio-card'), child: ListTile(
            leading: Icon(radio.usesUsbLink ? Icons.usb : radio.usesNetworkLink ? Icons.wifi : Icons.bluetooth_connected),
            title: Text((radio.usesUsbLink ? radio.linkName : radio.usesNetworkLink ? radio.networkHost : radio.connection.deviceName) ?? l.nodesRadio),
            subtitle: Text('${radio.usesUsbLink ? l.nodesOverUsb : radio.usesNetworkLink ? l.nodesOverWifi : l.nodesOverBluetooth} • ${_connectionLabel(context, radio.connection.state)}'),
            trailing: OutlinedButton(
              key: const ValueKey('disconnect-radio'),
              onPressed: radio.busy ? null : radio.disconnect,
              child: Text(l.commonDisconnect, maxLines: 1, softWrap: false),
            ),
          ))
        else
          Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
            OutlinedButton.icon(
              onPressed: radio.busy ? null : () => _connectNetwork(context),
              icon: const Icon(Icons.wifi),
              label: Text(l.nodesConnectWifi),
            ),
            if (BastionUsb.supported)
              OutlinedButton.icon(
                onPressed: radio.busy ? null : () => _connectUsb(context),
                icon: const Icon(Icons.usb),
                label: Text(l.nodesConnectUsb),
              ),
          ]),
        if (discovery.error != null)
          NxBanner(tone: NxTone.warning, message: discovery.error!),
        const SizedBox(height: NxSpace.xs),
        if (discovery.results.isEmpty && !discovery.scanning)
          NxEmptyState(icon: Icons.bluetooth_disabled,
            title: l.nodesNoRadios,
            detail: l.nodesNoRadiosBody,
            action: onTryDemo == null ? null : TextButton.icon(
              onPressed: onTryDemo,
              icon: const Icon(Icons.play_circle_outline),
              label: Text(l.nodesTryDemo),
            ))
        else
          for (final item in discovery.results)
            Card(child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.surfaceContainerHigh,
                child: Icon(_signalIcon(item.rssi), color: scheme.onSurfaceVariant)),
              title: Text(item.name),
              subtitle: Text([
                item.advertisesMeshtastic ? l.nodesMeshtasticRadio : l.nodesBluetoothDevice,
                _rssiLabel(context, item.rssi),
              ].join(' • ')),
              trailing: (radio.isReady || radio.isReconnecting) &&
                      radio.connection.deviceName == item.name
                  ? OutlinedButton(
                      onPressed: radio.busy ? null : radio.disconnect,
                      child: Text(l.commonDisconnect, maxLines: 1, softWrap: false),
                    )
                  : FilledButton(
                      onPressed: radio.busy ? null : () => _connect(context, item),
                      child: Text(l.commonConnect, maxLines: 1, softWrap: false),
                    ),
            )),
        if (radio.nodes.isNotEmpty) ...[
          NxSectionLabel(heard.window == null && !favoritesOnly
              ? l.nodesCount(radio.nodes.length)
              : l.nodesCountOf(shown.length, radio.nodes.length)),
          _HeardFilterChips(
            value: heard,
            onChanged: (v) => BastionPreferences.instance.update(heard: v),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: NxSpace.xs),
            child: FilterChip(
              key: const ValueKey('nodes-favorites-only'),
              avatar: Icon(favoritesOnly ? Icons.star : Icons.star_border),
              showCheckmark: false,
              label: Text(l.nodesFavoritesOnly),
              selected: favoritesOnly,
              onSelected: (v) => BastionPreferences.instance.update(favorites: v),
            ),
          ),
          if (shown.isEmpty && favoritesOnly && heard.window == null)
            NxEmptyState(icon: Icons.star_border,
              title: l.nodesNoFavorites,
              detail: l.nodesNoFavoritesHint,
              action: TextButton(
                onPressed: () => BastionPreferences.instance.update(favorites: false),
                child: Text(l.nodesShowAll),
              ))
          else if (shown.isEmpty)
            NxEmptyState(icon: Icons.filter_alt_off_outlined,
              title: l.nodesNoneHeard(_heardLabel(context, heard)),
              detail: l.nodesPickLonger,
              action: TextButton(
                onPressed: () => BastionPreferences.instance.update(heard: BastionHeardWithin.any),
                child: Text(l.nodesShowAll),
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
                    ? Tooltip(message: l.chatsKeyChanged,
                        child: Icon(Icons.gpp_maybe_outlined, color: scheme.error, semanticLabel: l.chatsKeyChanged))
                    : switch (radio.lookalikeOf(node.num)) {
                        final like? => Tooltip(
                            message: l.nodesLookalike(radio.nodeName(like)),
                            child: Icon(Icons.content_copy_outlined, color: scheme.error,
                                semanticLabel: l.nodesLookalike(radio.nodeName(like)))),
                        null => const Icon(Icons.chevron_right),
                      },
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => NodeDetailPage(radio: radio, nodeNum: node.num),
                )),
              ),
            ],
          ])),
        ],
        if (radio.isReady && BastionPreferences.instance.meshHealth) ...[
          NxSectionLabel(l.nodesHealth, trailing: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => MeshHealthPage(radio: radio))),
            child: Text(l.nodesDetails),
          )),
          NxStatRow(children: [
            NxStatTile(label: l.nodesKnown, value: '${radio.nodes.length}'),
            NxStatTile(label: l.chatsStatMessages, value: '${radio.messages.length}'),
            NxStatTile(label: l.nodesWaiting, value: '${radio.pendingMessageCount}'),
          ]),
          const SizedBox(height: NxSpace.xs),
          Card(child: Padding(
            padding: const EdgeInsets.all(NxSpace.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.nodesSignalQuality, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: NxSpace.xxs),
              Text(l.nodesSignalSummary(radio.receivedTextPackets,
                radio.latestSnr == null ? l.nodesNotMeasured : '${radio.latestSnr!.toStringAsFixed(1)} dB'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: NxSpace.sm),
              if (radio.snrHistory.isNotEmpty)
                Semantics(
                  label: l.nodesSignalHistory(radio.snrHistory.length.clamp(0, 20)),
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
                Text(l.nodesSignalStarts),
              const SizedBox(height: NxSpace.xs),
              Text(l.nodesMeasuredFrom,
                style: Theme.of(context).textTheme.bodySmall),
            ]),
          )),
        ],
        if (radio.nodeVault.isNotEmpty && BastionPreferences.instance.encounters) ...[
          NxSectionLabel(l.nodesEncounters),
          for (final record in radio.nodeVault)
            Card(child: ListTile(
              leading: Icon(record.favorite ? Icons.star : Icons.person_pin_circle_outlined,
                color: record.favorite ? scheme.primary : null),
              title: Text(record.displayName),
              subtitle: Text('${l.nodesSeen(record.encounters, _ago(context, record.lastSeen))}'
                '\n${record.note.isEmpty ? l.nodesTapNotes : record.note}'),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: record.favorite ? l.nodesRemoveFav : l.nodesAddFav,
                icon: Icon(record.favorite ? Icons.star : Icons.star_border),
                onPressed: () => radio.setNodeFavorite(record.num, !record.favorite),
              ),
              onTap: () => _editNote(context, record),
            )),
        ],
        NxSectionLabel(l.nodesMore),
        Card(child: ListTile(
          leading: const Icon(Icons.construction),
          title: Text(l.nodesFieldTools),
          subtitle: Text(l.nodesFieldToolsSub),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenTools,
        )),
        NxBanner(
          tone: radio.isReady ? NxTone.success : NxTone.neutral,
          message: radio.isReady
              ? l.nodesReadyBanner
              : l.nodesHelpBanner,
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
      label: AppLocalizations.of(context).nodesHeardWithin,
      child: Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
        for (final v in BastionHeardWithin.values)
          ChoiceChip(
            key: ValueKey('heard-${v.name}'),
            label: Text(_heardLabel(context, v)),
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
    final l = AppLocalizations.of(context);
    final host = _host.text.trim();
    final port = int.tryParse(_port.text.trim());
    final ok = validHost(host) && port != null && port > 0 && port < 65536;
    return AlertDialog(
      title: Text(l.nodesConnectWifi),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.nodesWifiHelp),
        const SizedBox(height: NxSpace.sm),
        TextField(
          controller: _host,
          autofocus: true,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(labelText: l.nodesAddress, hintText: l.nodesAddressHint),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: NxSpace.sm),
        TextField(
          controller: _port,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: l.nodesPort, helperText: l.nodesPortHelp),
          onChanged: (_) => setState(() {}),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: ok ? () => Navigator.pop(context, (host: host, port: port)) : null,
          child: Text(l.commonConnect),
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
  Widget build(BuildContext context) { final l = AppLocalizations.of(context); return SafeArea(child: Padding(
    padding: const EdgeInsets.fromLTRB(NxSpace.md, 0, NxSpace.md, NxSpace.md),
    child: FutureBuilder<List<UsbRadioInfo>>(
      future: _devices,
      builder: (context, snap) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l.nodesConnectUsb, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: NxSpace.xxs),
        Text(l.nodesUsbHelp),
        const SizedBox(height: NxSpace.sm),
        if (snap.connectionState != ConnectionState.done)
          const Center(child: Padding(padding: EdgeInsets.all(NxSpace.md), child: CircularProgressIndicator()))
        else if (snap.hasError)
          NxBanner(tone: NxTone.danger, message: l.nodesUsbListFailed('${snap.error}'))
        else if (snap.data!.isEmpty)
          NxEmptyState(icon: Icons.usb_off, title: l.nodesNoUsb,
            detail: l.nodesNoUsbBody)
        else
          for (final d in snap.data!)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(d.likelyRadio ? Icons.settings_input_antenna : Icons.usb),
              title: Text(d.name),
              subtitle: Text(d.likelyRadio ? l.nodesLikelyRadio(d.chip ?? '') : l.nodesOtherUsb),
              trailing: FilledButton(onPressed: () => Navigator.pop(context, d), child: Text(l.commonConnect)),
            ),
        TextButton.icon(
          onPressed: () => setState(() => _devices = _load()),
          icon: const Icon(Icons.refresh),
          label: Text(l.nodesRefresh),
        ),
      ]),
    ),
  )); }
}
