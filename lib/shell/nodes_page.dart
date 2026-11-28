part of '../main.dart';

/// Scan results to list under the connected-radio card: the connected radio
/// already has that card, so it isn't listed a second time.
@visibleForTesting
List<MeshtasticBleDevice> scanRowsBesideCard(
  List<MeshtasticBleDevice> results, {
  required bool connectedCard,
  required String? linkId,
}) => [
  for (final item in results)
    if (!(connectedCard && item.id == linkId)) item,
];

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
          SnackBar(
            content: Text(
              AppLocalizations.of(context).nodesConnectFailed('$error'),
            ),
          ),
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
      await radio.connect(
        MeshtasticBleDevice.usb(picked.deviceId, picked.name),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.nodesUsbFailed('$error'))),
      );
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
      await radio.connect(
        MeshtasticBleDevice.network(address.host, port: address.port),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(l.nodesConnectFailed('$error'))),
      );
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
          decoration: InputDecoration(labelText: l.nodesNotesHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, editor.text),
            child: Text(l.commonSave),
          ),
        ],
      ),
    );
    editor.dispose();
    if (note != null) await radio.setNodeNote(record.num, note);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([
      discovery,
      radio,
      BastionPreferences.instance,
    ]),
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final local = radio.localNode;
      final connectedName = radio.connection.deviceName;
      // Every link type (Bluetooth too) gets a connected-radio card.
      final showsConnectedCard =
          (radio.usesNetworkLink ||
              radio.usesUsbLink ||
              connectedName != null) &&
          (radio.isReady || radio.isReconnecting || radio.busy);
      return ListView(
        padding: NxSpace.page,
        children: [
          NxPageHeader(
            title: l.tabNodes,
            subtitle: radio.isReady
                ? l.nodesConnectedTo(
                    local?.displayName ?? connectedName ?? l.nodesYourRadio,
                  )
                : l.nodesFindRadio,
          ),
          if (radio.connection.error != null)
            NxBanner(
              tone: NxTone.danger,
              title: l.nodesConnProblem,
              message: radio.connection.error!,
              action: TextButton(
                key: const ValueKey('open-doctor'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ConnectionDoctorPage(
                      radio: radio,
                      discovery: discovery,
                    ),
                  ),
                ),
                child: Text(l.nodesDiagnose),
              ),
            ),
          if (radio.backgroundProblem != null)
            NxBanner(tone: NxTone.warning, message: radio.backgroundProblem!),
          if (radio.isReady)
            if (BastionFirmware.advice(radio.firmwareVersion)
                case final advice?)
              NxBanner(
                tone: radio.firmwareSupport == FirmwareSupport.unsupported
                    ? NxTone.warning
                    : NxTone.info,
                icon: Icons.system_update_alt,
                message: advice,
              ),
          if (showsConnectedCard)
            _RadioBar(radio: radio, onTap: () => _openRadioSheet(context))
          else
            ..._radioWidgets(context),
          if (radio.knownNodes.any((n) => n.num != local?.num))
            _NodeList(radio: radio)
          else if (showsConnectedCard)
            NxEmptyState(
              icon: Icons.hub_outlined,
              title: l.nodesNoMeshYet,
              detail: l.nodesNoMeshYetBody,
            ),
        ],
      );
    },
  );

  /// Everything about the radio link: the connected radio, scanning for
  /// radios, Wi-Fi and USB. Shown on the page when no radio is connected,
  /// and in the radio sheet when one is.
  List<Widget> _radioWidgets(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final connectedName = radio.connection.deviceName;
    final showsConnectedCard =
        (radio.usesNetworkLink || radio.usesUsbLink || connectedName != null) &&
        (radio.isReady || radio.isReconnecting || radio.busy);
    return [
          NxSectionLabel(showsConnectedCard ? l.nodesYourRadioHeading : l.nodesNearby),
          if (discovery.scanning)
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: NxSpace.sm),
                Expanded(
                  child: Text(
                    l.nodesLooking,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                TextButton(
                  onPressed: discovery.stop,
                  child: Text(l.nodesStopScan),
                ),
              ],
            )
          else if (!showsConnectedCard)
            FilledButton.icon(
              key: const ValueKey('scan-radios'),
              onPressed: discovery.scan,
              icon: const Icon(Icons.bluetooth_searching),
              label: Text(l.toolsScan),
            ),
          const SizedBox(height: NxSpace.xs),
          // Every link type (Bluetooth too) gets a connected-radio card with a
          // Disconnect button, so it never depends on the radio showing up in
          // the scan list (it doesn't after an auto-reconnect at launch).
          if (showsConnectedCard)
            Card(
              key: const ValueKey('connected-radio-card'),
              child: ListTile(
                leading: Icon(
                  radio.usesUsbLink
                      ? Icons.usb
                      : radio.usesNetworkLink
                      ? Icons.wifi
                      : Icons.bluetooth_connected,
                ),
                title: Text(
                  (radio.usesUsbLink
                          ? radio.linkName
                          : radio.usesNetworkLink
                          ? radio.networkHost
                          : radio.connection.deviceName) ??
                      l.nodesRadio,
                ),
                subtitle: Text(
                  '${radio.usesUsbLink
                      ? l.nodesOverUsb
                      : radio.usesNetworkLink
                      ? l.nodesOverWifi
                      : l.nodesOverBluetooth} • ${_connectionLabel(context, radio.connection.state)}',
                ),
                trailing: OutlinedButton(
                  key: const ValueKey('disconnect-radio'),
                  onPressed: radio.busy ? null : radio.disconnect,
                  child: Text(l.commonDisconnect, maxLines: 1, softWrap: false),
                ),
              ),
            )
          else
            Wrap(
              spacing: NxSpace.xs,
              runSpacing: NxSpace.xs,
              children: [
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
              ],
            ),
          if (discovery.error != null)
            NxBanner(tone: NxTone.warning, message: discovery.error!),
          const SizedBox(height: NxSpace.xs),
          // With a radio connected there is nothing to invite you to scan for.
          if (discovery.results.isEmpty && !discovery.scanning && !showsConnectedCard)
            NxEmptyState(
              icon: Icons.bluetooth_disabled,
              title: l.nodesNoRadios,
              detail: l.nodesNoRadiosBody,
              action: onTryDemo == null
                  ? null
                  : TextButton.icon(
                      onPressed: onTryDemo,
                      icon: const Icon(Icons.play_circle_outline),
                      label: Text(l.nodesTryDemo),
                    ),
            )
          else
            // The connected radio already has its own card above.
            for (final item in discovery.results)
              if (!(showsConnectedCard && item.id == radio.linkId))
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.surfaceContainerHigh,
                      child: Icon(
                        _signalIcon(item.rssi),
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Text(
                      [
                        item.looksLikeMeshtastic
                            ? l.nodesMeshtasticRadio
                            : l.nodesBluetoothDevice,
                        _rssiLabel(context, item.rssi),
                      ].join(' • '),
                    ),
                    trailing:
                        (radio.isReady || radio.isReconnecting) &&
                            radio.connection.deviceName == item.name
                        ? OutlinedButton(
                            onPressed: radio.busy ? null : radio.disconnect,
                            child: Text(
                              l.commonDisconnect,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          )
                        : FilledButton(
                            onPressed: radio.busy
                                ? null
                                : () => _connect(context, item),
                            child: Text(
                              l.commonConnect,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                  ),
                ),
          // With a radio connected, scanning is only for switching radios.
          if (showsConnectedCard && !discovery.scanning)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const ValueKey('find-another-radio'),
                onPressed: discovery.scan,
                icon: const Icon(Icons.bluetooth_searching),
                label: Text(l.nodesFindAnother),
              ),
            ),
          if (discovery.hiddenCount > 0 || discovery.showAll)
            SwitchListTile(
              key: const ValueKey('scan-show-all'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.devices_other),
              title: Text(l.nodesShowAllBluetooth),
              subtitle: Text(discovery.showAll ? l.nodesShowAllOn : l.nodesHiddenDevices(discovery.hiddenCount)),
              value: discovery.showAll,
              onChanged: (value) => discovery.showAll = value,
            ),
    ];
  }

  List<Widget> _healthWidgets(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return [
          if (radio.isReady && BastionPreferences.instance.meshHealth) ...[
            NxSectionLabel(
              l.nodesHealth,
              trailing: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MeshHealthPage(radio: radio),
                  ),
                ),
                child: Text(l.nodesDetails),
              ),
            ),
            NxStatRow(
              children: [
                NxStatTile(label: l.nodesKnown, value: '${radio.nodes.length}'),
                NxStatTile(
                  label: l.chatsStatMessages,
                  value: '${radio.messages.length}',
                ),
                NxStatTile(
                  label: l.nodesWaiting,
                  value: '${radio.pendingMessageCount}',
                ),
              ],
            ),
            const SizedBox(height: NxSpace.xs),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(NxSpace.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.nodesSignalQuality,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: NxSpace.xxs),
                    Text(
                      l.nodesSignalSummary(
                        radio.receivedTextPackets,
                        radio.latestSnr == null
                            ? l.nodesNotMeasured
                            : '${radio.latestSnr!.toStringAsFixed(1)} dB',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: NxSpace.sm),
                    if (radio.snrHistory.isNotEmpty)
                      Semantics(
                        label: l.nodesSignalHistory(
                          radio.snrHistory.length.clamp(0, 20),
                        ),
                        excludeSemantics: true,
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            for (final snr
                                in radio.snrHistory.reversed
                                    .take(20)
                                    .toList()
                                    .reversed)
                              Tooltip(
                                message: '${snr.toStringAsFixed(1)} dB',
                                child: Container(
                                  width: 10,
                                  height:
                                      12 + (snr + 20).clamp(0, 40).toDouble(),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Text(l.nodesSignalStarts),
                    const SizedBox(height: NxSpace.xs),
                    Text(
                      l.nodesMeasuredFrom,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
    ];
  }

  List<Widget> _encounterWidgets(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return [
          if (radio.nodeVault.isNotEmpty &&
              BastionPreferences.instance.encounters) ...[
            NxSectionLabel(l.nodesEncounters),
            for (final record in radio.nodeVault)
              Card(
                child: ListTile(
                  leading: Icon(
                    record.favorite
                        ? Icons.star
                        : Icons.person_pin_circle_outlined,
                    color: record.favorite ? scheme.primary : null,
                  ),
                  title: Text(record.displayName),
                  subtitle: Text(
                    '${l.nodesSeen(record.encounters, _ago(context, record.lastSeen))}'
                    '\n${record.note.isEmpty ? l.nodesTapNotes : record.note}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: record.favorite ? l.nodesRemoveFav : l.nodesAddFav,
                    icon: Icon(
                      record.favorite ? Icons.star : Icons.star_border,
                    ),
                    onPressed: () =>
                        radio.setNodeFavorite(record.num, !record.favorite),
                  ),
                  onTap: () => _editNote(context, record),
                  // Long-press: the name this phone shows for the node.
                  onLongPress: () async {
                    final name = await showLocalNameDialog(
                      context,
                      current: BastionLocalNames.instance.nameFor(record.num) ?? '',
                      radioName: record.radioName,
                    );
                    if (name != null) await radio.setNodeLocalName(record.num, name);
                  },
                ),
              ),
          ],
    ];
  }

  /// The radio sheet: connection, scanning, the connection doctor, mesh
  /// health and saved encounters.
  Future<void> _openRadioSheet(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheet) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          builder: (sheet, controller) => AnimatedBuilder(
            animation: Listenable.merge([discovery, radio, BastionPreferences.instance]),
            builder: (sheet, _) => ListView(
              key: const ValueKey('radio-sheet'),
              controller: controller,
              padding: NxSpace.page,
              children: [
                ..._radioWidgets(sheet),
                Card(
                  child: ListTile(
                    key: const ValueKey('sheet-doctor'),
                    leading: const Icon(Icons.medical_services_outlined),
                    title: Text(AppLocalizations.of(sheet).toolsDoctor),
                    subtitle: Text(AppLocalizations.of(sheet).toolsDoctorSub),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(sheet).push(MaterialPageRoute<void>(
                      builder: (_) => ConnectionDoctorPage(radio: radio, discovery: discovery),
                    )),
                  ),
                ),
                ..._healthWidgets(sheet),
                ..._encounterWidgets(sheet),
              ],
            ),
          ),
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
      host.isNotEmpty &&
      host.length <= 253 &&
      !host.contains(RegExp(r'[\s/]')) &&
      !host.contains('://');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final host = _host.text.trim();
    final port = int.tryParse(_port.text.trim());
    final ok = validHost(host) && port != null && port > 0 && port < 65536;
    return AlertDialog(
      title: Text(l.nodesConnectWifi),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.nodesWifiHelp),
          const SizedBox(height: NxSpace.sm),
          TextField(
            controller: _host,
            autofocus: true,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l.nodesAddress,
              hintText: l.nodesAddressHint,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: NxSpace.sm),
          TextField(
            controller: _port,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l.nodesPort,
              helperText: l.nodesPortHelp,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          onPressed: ok
              ? () => Navigator.pop(context, (host: host, port: port))
              : null,
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
      [...await BastionUsb.gateway.list()]
        ..sort((a, b) => (b.likelyRadio ? 1 : 0) - (a.likelyRadio ? 1 : 0));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          NxSpace.md,
          0,
          NxSpace.md,
          NxSpace.md,
        ),
        child: FutureBuilder<List<UsbRadioInfo>>(
          future: _devices,
          builder: (context, snap) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.nodesConnectUsb,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: NxSpace.xxs),
              Text(l.nodesUsbHelp),
              const SizedBox(height: NxSpace.sm),
              if (snap.connectionState != ConnectionState.done)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(NxSpace.md),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snap.hasError)
                NxBanner(
                  tone: NxTone.danger,
                  message: l.nodesUsbListFailed('${snap.error}'),
                )
              else if (snap.data!.isEmpty)
                NxEmptyState(
                  icon: Icons.usb_off,
                  title: l.nodesNoUsb,
                  detail: l.nodesNoUsbBody,
                )
              else
                for (final d in snap.data!)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      d.likelyRadio ? Icons.settings_input_antenna : Icons.usb,
                    ),
                    title: Text(d.name),
                    subtitle: Text(
                      d.likelyRadio
                          ? l.nodesLikelyRadio(d.chip ?? '')
                          : l.nodesOtherUsb,
                    ),
                    trailing: FilledButton(
                      onPressed: () => Navigator.pop(context, d),
                      child: Text(l.commonConnect),
                    ),
                  ),
              TextButton.icon(
                onPressed: () => setState(() => _devices = _load()),
                icon: const Icon(Icons.refresh),
                label: Text(l.nodesRefresh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One slim bar for the connected radio; tapping it opens the radio sheet.
class _RadioBar extends StatelessWidget {
  const _RadioBar({required this.radio, required this.onTap});
  final MeshtasticRadioCoordinator radio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final state = radio.connection.state;
    final tone = _connectionTone(state);
    final color = NxStatusColors.of(context).strong(tone, scheme);
    final name = (radio.usesUsbLink
            ? radio.linkName
            : radio.usesNetworkLink
                ? radio.networkHost
                : radio.connection.deviceName) ??
        l.nodesRadio;
    final link = radio.usesUsbLink
        ? l.nodesOverUsb
        : radio.usesNetworkLink
            ? l.nodesOverWifi
            : l.nodesOverBluetooth;
    final status = _connectionLabel(context, state);
    return Padding(
      padding: const EdgeInsets.only(bottom: NxSpace.sm),
      child: Semantics(
        button: true,
        label: '$name, $link, $status',
        hint: l.nodesManage,
        excludeSemantics: true,
        child: Material(
          color: scheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: color.withValues(alpha: 0.6)),
          ),
          child: InkWell(
            key: const ValueKey('radio-bar'),
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(children: [
                  Icon(
                    radio.usesUsbLink
                        ? Icons.usb
                        : radio.usesNetworkLink
                            ? Icons.wifi
                            : Icons.bluetooth_connected,
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: type.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    Text('$link • $status', style: type.bodySmall?.copyWith(color: color)),
                  ])),
                  Text(l.nodesManage, style: type.labelLarge?.copyWith(color: scheme.primary)),
                  Icon(Icons.chevron_right, color: scheme.primary),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The mesh nodes, grouped by when they were last heard, with a search box
/// and a favorites filter.
class _NodeList extends StatefulWidget {
  const _NodeList({required this.radio});
  final MeshtasticRadioCoordinator radio;

  @override
  State<_NodeList> createState() => _NodeListState();
}

class _NodeListState extends State<_NodeList> {
  final _search = TextEditingController();
  bool _showOlder = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final radio = widget.radio;
    final favoritesOnly = BastionPreferences.instance.favoritesOnly;
    final query = _search.text.trim();
    // The radio's list plus remembered and imported nodes it no longer has.
    final known = radio.knownNodes;
    final groups = BastionNodeGroups.of(
      known,
      now: DateTime.now(),
      localNum: radio.localNode?.num,
      query: query,
      favoritesOnly: favoritesOnly,
      favorites: radio.favoriteNums,
    );
    final all = known.where((n) => n.num != radio.localNode?.num).length;
    // While searching, nothing stays folded away.
    final showOlder = _showOlder || query.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      NxSectionLabel(l.nodesCount(all)),
      TextField(
        key: const ValueKey('nodes-search'),
        controller: _search,
        decoration: InputDecoration(
          hintText: l.nodesSearch,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: query.isEmpty
              ? null
              : IconButton(
                  tooltip: l.chatsClearSearch,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_search.clear),
                ),
        ),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: NxSpace.xs),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: FilterChip(
          key: const ValueKey('nodes-favorites-only'),
          avatar: Icon(favoritesOnly ? Icons.star : Icons.star_border),
          showCheckmark: false,
          label: Text(l.nodesFavoritesOnly),
          selected: favoritesOnly,
          onSelected: (v) => BastionPreferences.instance.update(favorites: v),
        ),
      ),
      if (groups.total == 0)
        favoritesOnly && query.isEmpty
            ? NxEmptyState(
                icon: Icons.star_border,
                title: l.nodesNoFavorites,
                detail: l.nodesNoFavoritesHint,
                action: TextButton(
                  onPressed: () => BastionPreferences.instance.update(favorites: false),
                  child: Text(l.nodesShowAll),
                ),
              )
            : NxEmptyState(icon: Icons.search_off, title: l.nodesNoMatch(query), detail: l.nodesNoMatchHint),
      if (groups.active.isNotEmpty) ...[
        _GroupHeader(key: const ValueKey('group-active'), label: l.nodesActiveNow, count: groups.active.length),
        _NodeCard(radio: radio, nodes: groups.active),
      ],
      if (groups.today.isNotEmpty) ...[
        _GroupHeader(key: const ValueKey('group-today'), label: l.svcToday, count: groups.today.length),
        _NodeCard(radio: radio, nodes: groups.today),
      ],
      if (groups.older.isNotEmpty) ...[
        _GroupHeader(
          key: const ValueKey('group-older'),
          label: l.nodesOlder,
          count: groups.older.length,
          expanded: showOlder,
          onToggle: query.isNotEmpty ? null : () => setState(() => _showOlder = !_showOlder),
        ),
        if (showOlder) _NodeCard(radio: radio, nodes: groups.older),
      ],
    ]);
  }
}

/// "Active now · 4", optionally a button that folds the group away.
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({super.key, required this.label, required this.count, this.expanded, this.onToggle});
  final String label;
  final int count;

  /// Null for a group that can't be folded.
  final bool? expanded;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Text('$label · $count',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700));
    if (expanded == null) {
      return Semantics(
        header: true,
        child: Padding(padding: const EdgeInsets.fromLTRB(4, 16, 4, 6), child: text),
      );
    }
    return Semantics(
      button: true,
      header: true,
      expanded: expanded,
      hint: expanded! ? l.chatsHide : l.chatsShow,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
            child: Row(children: [
              Expanded(child: text),
              if (onToggle != null)
                ExcludeSemantics(child: Icon(expanded! ? Icons.expand_less : Icons.expand_more, color: scheme.primary)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({required this.radio, required this.nodes});
  final MeshtasticRadioCoordinator radio;
  final List<MeshtasticNode> nodes;

  @override
  Widget build(BuildContext context) => Card(
        child: Column(children: [
          for (final (i, node) in nodes.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            _NodeRow(radio: radio, node: node),
          ],
        ]),
      );
}

/// One node: when it was heard, how far away, how many hops, battery and
/// signal, plus any security warning.
class _NodeRow extends StatelessWidget {
  const _NodeRow({required this.radio, required this.node});
  final MeshtasticRadioCoordinator radio;
  final MeshtasticNode node;

  String? _distance(BuildContext context) {
    final me = radio.localNode;
    if (me == null || !me.hasPosition || !node.hasPosition) return null;
    final meters = BastionGeo.distanceMeters(me.latitude!, me.longitude!, node.latitude!, node.longitude!);
    final bearing = BastionGeo.bearingDegrees(me.latitude!, me.longitude!, node.latitude!, node.longitude!);
    return '${BastionUnitFormat.distance(meters, BastionPreferences.instance.units)} ${BastionGeo.compassPoint(bearing)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final favorite = radio.favoriteNums.contains(node.num);
    final now = DateTime.now();
    // A radio with an unset clock reports 1970 or a far-future time: no age.
    final heard = knownHeardTime(node.lastHeard, now);
    final battery = node.batteryLevel;
    // Your own radio is never stale; the badge is for nodes gone quiet.
    final stale = node.num != radio.localNodeNum &&
        BastionPreferences.instance.staleAfter.marks(heard, now);
    final details = [
      heard == null
          ? (node.lastHeard == null ? l.nodesNeverHeard : l.nodesHeardUnknown)
          : stale
              ? l.nodesStale(_ago(context, heard))
              : _ago(context, heard),
      ?_distance(context),
      if (node.viaMqtt) l.chatsViaMqtt else ?_hopsLabel(context, node.hopsAway),
      if (battery != null) battery > 100 ? l.homePluggedIn : l.toolsBatteryPct(battery),
    ];
    final keyChanged = radio.nodeKeys.hasChanged(node.num);
    final like = radio.lookalikeOf(node.num);
    final bars = BastionNodeGroups.bars(node.snr);
    final warning = keyChanged
        ? l.chatsKeyChanged
        : like != null
            ? l.nodesLookalike(radio.nodeName(like))
            : null;
    final signal = switch (bars) {
      3 => l.toolsSigStrong,
      2 => l.toolsSigUsable,
      1 => l.toolsSigWeak,
      0 => l.toolsSigVeryWeak,
      _ => null,
    };
    return Semantics(
      button: true,
      label: [
        node.displayName,
        if (favorite) l.nodesFavorite,
        ...details,
        if (signal != null) '${l.ndSignal}: $signal',
        ?warning,
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('node-${node.num}'),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => NodeDetailPage(radio: radio, nodeNum: node.num),
        )),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 68),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              NodeAvatar(num: node.num, label: node.shortName ?? node.displayName),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(node.displayName, style: type.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                  if (favorite) Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4),
                    child: Icon(Icons.star, size: 16, color: scheme.primary),
                  ),
                  // Shape and words, not only colour, say the node is stale.
                  if (stale) Padding(
                    key: ValueKey('node-${node.num}-stale'),
                    padding: const EdgeInsetsDirectional.only(start: 4),
                    child: Icon(Icons.history_toggle_off, size: 16, color: scheme.onSurfaceVariant),
                  ),
                ]),
                const SizedBox(height: 2),
                Text(details.join(' • '), style: type.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ])),
              const SizedBox(width: 8),
              if (warning != null)
                Icon(keyChanged ? Icons.gpp_maybe_outlined : Icons.content_copy_outlined, color: scheme.error)
              else if (bars != null)
                _SignalBars(bars: bars)
              else
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Three bars, filled up to [bars]; the count is said in words elsewhere.
class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.bars});
  final int bars;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 22,
      height: 18,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (var i = 1; i <= 3; i++)
          Container(
            width: 5,
            height: 6.0 * i,
            decoration: BoxDecoration(
              color: i <= bars ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
      ]),
    );
  }
}
