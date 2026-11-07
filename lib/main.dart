import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'beacon_page.dart';
import 'link_planner_page.dart';
import 'map_page.dart';
import 'field_tools_page.dart';
import 'home_page.dart';
import 'services/bastion_units.dart';
import 'services/bastion_field_log.dart';
import 'services/bastion_background_service.dart';
import 'services/bastion_bot_guard.dart';
import 'services/bastion_history_limit.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_radio_data.dart';
import 'phone_backup_page.dart';
import 'privacy_page.dart';
import 'radio_backup_page.dart';
import 'services/bastion_chat_marks.dart';
import 'services/bastion_message_search.dart';
import 'mesh_health_page.dart';
import 'mesh_tools_page.dart';
import 'node_detail_page.dart';
import 'radio_settings_page.dart';
import 'services/bastion_tile_cache.dart';
import 'traceroute_page.dart';
import 'services/bastion_nodedex.dart';
import 'services/meshtastic_ble_discovery.dart';
import 'services/meshtastic_connection_controller.dart';
import 'services/bastion_chat_store.dart';
import 'services/bastion_demo_radio.dart';
import 'services/bastion_field_alerts.dart';
import 'services/bastion_home_widget.dart';
import 'services/bastion_firmware.dart';
import 'services/bastion_phone_position.dart';
import 'services/meshtastic_messaging_service.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'services/meshtastic_usb_transport.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('licenses/meshtastic-protobufs-GPL-3.0.txt');
    yield LicenseEntryWithLineBreaks(['Meshtastic protobufs'], text);
  });
  await BastionTileCache.initialize();
  await BastionPreferences.instance.load();
  // Chat history lives in its own database; older saves move over once.
  await BastionChatStorage.useSqlite();
  await BastionFieldLog.instance.load();
  await BastionBotGuard.instance.load();
  runApp(const BastionApp());
}

class BastionApp extends StatelessWidget {
  const BastionApp({super.key});
  /// NOTORYX orange from the app icon; the accent in the dark theme.
  static const signal = NxPalette.signal;

  /// The same hue, darkened so text and icons keep 4.5:1 contrast on the
  /// light theme's surfaces (#FC7202 is only about 2.6:1 there).
  static const signalOnLight = NxPalette.signalDeep;
  static const panel = NxPalette.ink1;

  /// The accent for the current theme.
  static Color accentOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? signal : signalOnLight;

  /// The app theme, built from the NOTORYX design tokens.
  static ThemeData appearance(Brightness brightness) => NotoryxTheme.build(brightness);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: BastionPreferences.instance,
    builder: (context, _) => MaterialApp(
      title: 'NOTORYX Connect', debugShowCheckedModeBanner: false,
      theme: appearance(Brightness.light), darkTheme: appearance(Brightness.dark),
      themeMode: BastionPreferences.instance.theme,
      scrollBehavior: const BastionScrollBehavior(),
      home: const BastionShell(),
    ),
  );
}

/// Gives every vertical list a scroll bar that can be held and dragged to
/// move through a long list in one go, on phones as well as desktops.
class BastionScrollBehavior extends MaterialScrollBehavior {
  const BastionScrollBehavior();

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    if (axisDirectionToAxis(details.direction) != Axis.vertical) return child;
    return Scrollbar(controller: details.controller, interactive: true, child: child);
  }
}

class BastionShell extends StatefulWidget {
  const BastionShell({super.key});
  @override
  State<BastionShell> createState() => _BastionShellState();
}

class _BastionShellState extends State<BastionShell> {
  int index = 0;
  final ble = MeshtasticBleDiscovery();
  final _realRadio = MeshtasticRadioCoordinator();
  BastionDemoRadio? _demo;

  /// The radio the screens show: the pretend one while demo mode is on.
  MeshtasticRadioCoordinator get radio => _demo ?? _realRadio;

  bool get _inDemo => _demo != null;

  /// Swaps in a pretend radio and mesh. Nothing is sent or saved.
  void _setDemo(bool on) {
    if (on == _inDemo) return;
    final old = _demo;
    setState(() {
      _demo = on ? BastionDemoRadio() : null;
      index = 0;
    });
    // Let the screens stop listening before the old demo radio goes away.
    if (old != null) WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    if (on) radio.configureBot(enabled: botMode, reply: awayReply);
  }
  bool botMode = false;
  String awayReply = MeshtasticMessagingService.defaultAwayReply;

  static const labels = ['Home', 'Nodes', 'Chats', 'Map', 'Tools', 'Settings'];
  static const icons = [
    Icons.shield_outlined, Icons.hub_outlined, Icons.chat_bubble_outline, Icons.map_outlined,
    Icons.build_outlined, Icons.settings_outlined,
  ];

  /// Wider than this, the tabs move to a rail on the left.
  static const railBreakpoint = 600.0;

  void _go(int tab) => setState(() => index = tab);

  BastionHomeWidget? _homeWidget;

  @override
  void initState() {
    super.initState();
    _setUpShortcuts();
    // The widget follows the real radio, never the demo.
    if (BastionHomeWidget.supported) {
      _homeWidget = BastionHomeWidget.instance = BastionHomeWidget(_realRadio);
      unawaited(_homeWidget!.start());
    }
  }

  /// Long-press shortcuts on the app icon, each opening a tab.
  void _setUpShortcuts() {
    if (kIsWeb || !Platform.isAndroid) return;
    const tabs = {'home': 0, 'nodes': 1, 'chats': 2, 'map': 3};
    try {
      const actions = QuickActions();
      actions.initialize((type) {
        final tab = tabs[type];
        if (tab != null && mounted) setState(() => index = tab);
      });
      actions.setShortcutItems(const [
        ShortcutItem(type: 'home', localizedTitle: 'Check in / SOS'),
        ShortcutItem(type: 'chats', localizedTitle: 'Chats'),
        ShortcutItem(type: 'nodes', localizedTitle: 'Nodes'),
        ShortcutItem(type: 'map', localizedTitle: 'Map'),
      ]).catchError((Object _) {});
    } catch (_) {
      // Shortcuts are a convenience; the app works without them.
    }
  }

  @override
  void dispose() {
    ble.dispose();
    _homeWidget?.dispose();
    _realRadio.dispose();
    _demo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = PrimaryScrollController.none(child: IndexedStack(key: ValueKey(_inDemo), index: index, children: [
      HomePage(radio: radio, onConnect: () => _go(1), onTryDemo: _inDemo ? null : () => _setDemo(true)),
      _NodesPage(discovery: ble, radio: radio, onOpenTools: () => _go(4),
        onTryDemo: _inDemo ? null : () => _setDemo(true)),
      BastionChatsPage(
        radio: radio,
        visible: index == 2,
        botMode: botMode,
        awayReply: awayReply,
        onBotModeChanged: (value) {
          setState(() => botMode = value);
          radio.configureBot(enabled: value, reply: awayReply);
        },
        onAwayReplyChanged: (value) {
          setState(() => awayReply = value);
          radio.configureBot(enabled: botMode, reply: value);
        },
      ),
      MapPage(radio: radio),
      _ToolsPage(discovery: ble, radio: radio),
      _SettingsPage(radio: radio, demo: _inDemo, onDemoChanged: _setDemo),
    ]));
    final wide = MediaQuery.sizeOf(context).width >= railBreakpoint;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(36) + 20,
        titleSpacing: NxSpace.md,
        title: Semantics(
          label: 'NOTORYX Connect',
          excludeSemantics: true,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('NOTORYX', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20,
              color: scheme.primary, letterSpacing: 2.4, height: 1.1)),
            Text('CONNECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              letterSpacing: 3, color: scheme.onSurfaceVariant)),
          ]),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: NxSpace.md),
            child: AnimatedBuilder(
              animation: radio,
              builder: (context, _) {
                final state = radio.connection.state;
                // Tapping the status opens Nodes, where the radio is managed.
                return Tooltip(
                  message: 'Radio: ${_connectionLabel(state)}. Tap to manage.',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(NxRadius.pill),
                    onTap: () => _go(1),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: NxTouch.min),
                      child: Center(child: NxStatusPill(
                        label: _connectionLabel(state),
                        tone: _connectionTone(state),
                        busy: _connectionBusy(state) || radio.isReconnecting,
                      )),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Each tab keeps its own scroll position, so each scroll bar follows one list.
      body: SafeArea(child: Column(children: [
        if (_inDemo) _DemoBanner(onExit: () => _setDemo(false)),
        Expanded(child: wide
          ? Row(children: [
              NavigationRail(
                selectedIndex: index,
                onDestinationSelected: _go,
                destinations: [
                  for (var i = 0; i < labels.length; i++)
                    NavigationRailDestination(icon: _tabIcon(i), label: Text(labels[i])),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: Align(alignment: Alignment.topCenter,
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840), child: pages))),
            ])
          : pages),
      ])),
      bottomNavigationBar: wide ? null : NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _go,
        destinations: [
          for (var i = 0; i < labels.length; i++)
            NavigationDestination(icon: _tabIcon(i), label: labels[i], tooltip: labels[i]),
        ],
      ),
    );
  }

  /// A tab's icon; Chats carries a badge with the unread count.
  Widget _tabIcon(int i) => i != 2 ? Icon(icons[i]) : AnimatedBuilder(
    animation: radio,
    builder: (context, _) {
      final unread = index == 2 ? 0 : radio.unreadCount;
      return Semantics(
        label: unread == 0 ? null : '$unread unread',
        child: Badge(
          isLabelVisible: unread > 0,
          label: Text(unread > 99 ? '99+' : '$unread'),
          child: Icon(icons[i]),
        ),
      );
    },
  );
}

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
            hintText: 'Location, antenna, observations…',
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
              value: _connectionLabel(radio.connection.state),
              tone: _connectionTone(radio.connection.state),
            ),
          ]),
          const SizedBox(height: NxSpace.sm),
        ],
        if (radio.connection.error != null)
          NxBanner(tone: NxTone.danger, title: 'Connection problem', message: radio.connection.error!),
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
            subtitle: Text('${radio.usesUsbLink ? 'Over USB' : 'Over Wi-Fi'} • ${_connectionLabel(radio.connection.state)}'),
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
              title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
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
          NxSectionLabel('Mesh nodes (${radio.nodes.length})'),
          Card(child: Column(children: [
            for (final (i, node) in radio.nodes.indexed) ...[
              if (i > 0) const Divider(indent: 72),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text(_initials(node.shortName ?? node.displayName),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
                title: Text(node.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
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

/// One or two letters for a node's avatar.
String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.take(trimmed.length >= 2 ? 2 : 1).toString().toUpperCase();
}

IconData _signalIcon(int rssi) {
  if (rssi >= -60) return Icons.signal_cellular_alt;
  if (rssi >= -75) return Icons.signal_cellular_alt_2_bar;
  return Icons.signal_cellular_alt_1_bar;
}

/// "just now", "5 min ago", "3 h ago", or a date, for last-seen times.
String _ago(DateTime time) {
  final d = DateTime.now().difference(time);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} h ago';
  if (d.inDays < 7) return '${d.inDays} d ago';
  final l = time.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
}

class BastionChatsPage extends StatefulWidget {
  const BastionChatsPage({
    required this.radio,
    this.visible = true,
    required this.botMode,
    required this.awayReply,
    required this.onBotModeChanged,
    required this.onAwayReplyChanged,
  });
  final MeshtasticRadioCoordinator radio;

  /// Whether the Chats tab is on screen; seeing it marks messages read.
  final bool visible;
  final bool botMode;
  final String awayReply;
  final ValueChanged<bool> onBotModeChanged;
  final ValueChanged<String> onAwayReplyChanged;

  @override
  State<BastionChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<BastionChatsPage> {
  late final TextEditingController reply =
      TextEditingController(text: widget.awayReply);
  final composer = TextEditingController();
  int destination = 0xffffffff;
  int channel = 0;
  final search = TextEditingController();

  /// Unsent text per conversation, so switching chats doesn't lose it.
  final Map<String, String> _drafts = {};
  String get _draftKey => destination == 0xffffffff ? 'ch$channel' : 'dm$destination';

  /// Messages after this were new when you opened Chats. Kept while the tab
  /// is open so the "new messages" divider doesn't vanish as you read.
  DateTime? _unreadSince;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDrafts());
    if (widget.visible) _opened();
  }

  @override
  void didUpdateWidget(BastionChatsPage old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) _opened();
    if (!widget.visible && old.visible) unawaited(widget.radio.markChatsRead());
  }

  void _opened() {
    _unreadSince = widget.radio.chatMarks.lastRead;
    unawaited(widget.radio.markChatsRead());
  }

  Future<void> _togglePin(BastionChatMessage message) async {
    final problem = await widget.radio.togglePin(message);
    if (problem != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
    }
  }

  /// Inserts "@name " for a node you pick, at the cursor.
  Future<void> _mention() async {
    final nodes = [for (final n in widget.radio.nodes) if (n.num != widget.radio.localNodeNum) n];
    final name = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(child: nodes.isEmpty
          ? const Padding(padding: EdgeInsets.all(24), child: Text('No nodes heard yet to mention.'))
          : ListView(shrinkWrap: true, children: [
              const ListTile(title: Text('Mention a node', style: TextStyle(fontWeight: FontWeight.bold))),
              for (final n in nodes)
                ListTile(
                  leading: const Icon(Icons.alternate_email),
                  title: Text(n.displayName),
                  onTap: () => Navigator.pop(context, n.displayName),
                ),
            ])),
    );
    if (name == null || !mounted) return;
    final text = composer.text;
    final sel = composer.selection;
    final at = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    final before = text.substring(0, at);
    final insert = '${before.isEmpty || before.endsWith(' ') ? '' : ' '}@$name ';
    composer.value = TextEditingValue(
      text: before + insert + text.substring(end),
      selection: TextSelection.collapsed(offset: at + insert.length),
    );
    _saveDraft();
  }

  Future<void> _loadDrafts() async {
    try {
      final raw = await SharedPreferencesAsync().getString(_draftsKey);
      if (raw == null || !mounted) return;
      _drafts.addAll((jsonDecode(raw) as Map).cast<String, String>());
      if (composer.text.isEmpty) composer.text = _drafts[_draftKey] ?? '';
    } catch (_) {
      // Drafts are a convenience; a damaged store is ignored.
    }
  }

  static const _draftsKey = 'bastion.drafts.v1';

  void _saveDraft() {
    final text = composer.text;
    if (text.trim().isEmpty) {
      _drafts.remove(_draftKey);
    } else {
      _drafts[_draftKey] = text;
    }
    try {
      unawaited(SharedPreferencesAsync().setString(_draftsKey, jsonEncode(_drafts))
          .catchError((Object _) {}));
    } catch (_) {
      // Drafts are a convenience; storage may be unavailable.
    }
  }

  /// Switches conversation, keeping each one's unsent text.
  void _switchTo({int? newDestination, int? newChannel}) {
    _saveDraft();
    setState(() {
      destination = newDestination ?? destination;
      channel = newChannel ?? channel;
      composer.text = _drafts[_draftKey] ?? '';
    });
  }

  @override
  void dispose() {
    _saveDraft();
    reply.dispose();
    composer.dispose();
    search.dispose();
    super.dispose();
  }

  static const _pinAction = '\u0000pin';
  static const _copyAction = '\u0000copy';
  static const _reactionChoices = ['👍', '❤️', '😂', '😮', '😢', '✅', '🙏'];

  /// How an incoming message got here: over the internet, directly, or
  /// through relays, naming the last relay when it can be worked out.
  String _pathSummary(BastionChatMessage m) {
    if (m.viaMqtt) return 'Arrived over MQTT (the internet), not over the air';
    final hops = m.hops;
    if (hops == null) return "Path not reported by the sender's firmware";
    if (hops == 0) return 'Heard directly, no relays';
    final relay = m.relayNode;
    final candidates = relay == null
        ? const <String>[]
        : [for (final n in widget.radio.nodes) if ((n.num & 0xff) == relay && n.num != m.from) n.displayName];
    final via = candidates.length == 1
        ? ', last through ${candidates.single}'
        : relay == null
            ? ''
            : ', last through a node ending in ${relay.toRadixString(16).padLeft(2, '0')}';
    return 'Came through $hops relay${hops == 1 ? '' : 's'}$via';
  }

  Future<void> _react(BastionChatMessage message) async {
    final pinned = widget.radio.chatMarks.isPinned(message);
    final emoji = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('React', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 4, children: [
            for (final e in _reactionChoices)
              IconButton(
                tooltip: 'React $e',
                onPressed: () => Navigator.pop(context, e),
                icon: Text(e, style: const TextStyle(fontSize: 28)),
              ),
          ]),
          const Divider(),
          if (message.direction == BastionMessageDirection.incoming)
            ListTile(
              leading: const Icon(Icons.alt_route),
              title: Text(_pathSummary(message)),
              subtitle: Text([
                if (message.rxSnr != null) 'SNR ${message.rxSnr!.toStringAsFixed(1)} dB',
                if (message.rxRssi != null) 'RSSI ${message.rxRssi} dBm',
                if (message.rxSnr == null && message.rxRssi == null) 'No signal reading',
              ].join(' • ')),
            ),
          ListTile(
            leading: Icon(pinned ? Icons.push_pin_outlined : Icons.push_pin),
            title: Text(pinned ? 'Unpin' : 'Pin'),
            onTap: () => Navigator.pop(context, _pinAction),
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy text'),
            onTap: () => Navigator.pop(context, _copyAction),
          ),
        ]),
      )),
    );
    if (emoji == null || !mounted) return;
    if (emoji == _pinAction) return _togglePin(message);
    if (emoji == _copyAction) {
      await Clipboard.setData(ClipboardData(text: message.text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message copied')));
      }
      return;
    }
    try {
      await widget.radio.sendReaction(message, emoji);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error is StateError ? error.message : 'Reaction not sent: $error')));
      }
    }
  }

  Future<void> _send([String? quickText]) async {
    final text = (quickText ?? composer.text).trim();
    if (text.isEmpty) return;
    try {
      await widget.radio.sendText(text: text, destination: destination, channel: channel);
      if (quickText == null) {
        composer.clear();
        _saveDraft();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message not sent: $error')),
        );
      }
    }
  }

  /// Newest-first rows: a date divider at each new day, and a divider
  /// below the messages that arrived since you last looked.
  List<_TimelineRow> _timelineRows(List<BastionChatMessage> newestFirst, DateTime now) {
    final since = _unreadSince;
    final rows = <_TimelineRow>[];
    DateTime? day;
    var sawUnread = false;
    var placedNew = false;
    for (final m in newestFirst) {
      final unread = since != null && BastionChatMarks.isUnread(m, since);
      if (sawUnread && !placedNew && !unread && !m.timestamp.isAfter(since!)) {
        rows.add(const _NewRow());
        placedNew = true;
      }
      if (unread) sawUnread = true;
      final d = BastionChatDays.dayOf(m.timestamp);
      if (d != day) {
        rows.add(_DayRow(BastionChatDays.label(m.timestamp, now)));
        day = d;
      }
      rows.add(_MessageRow(m));
    }
    return rows;
  }

  Widget _messageCard(BuildContext context, BastionChatMessage message, List<BastionChatMessage>? rs) {
    final scheme = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final outgoing = message.direction == BastionMessageDirection.outgoing;
    final mentioned = !outgoing && widget.radio.mentionsMe(message.text);
    final pinned = widget.radio.chatMarks.isPinned(message);
    final sender = outgoing ? 'You' : _nodeName(message.from);
    final route = message.isBroadcast
        ? 'Channel ${message.channel}'
        : outgoing ? _nodeName(message.to) : 'you';
    final failed = message.deliveryState == BastionDeliveryState.failed;
    final statusColor = failed
        ? scheme.error
        : message.deliveryState == BastionDeliveryState.delivered
            ? NxStatusColors.of(context).success
            : scheme.onSurfaceVariant;
    return Card(
      color: mentioned ? scheme.primaryContainer : outgoing ? scheme.surfaceContainer : null,
      shape: mentioned
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(NxRadius.lg),
              side: BorderSide(color: scheme.primary, width: 1.5))
          : null,
      child: InkWell(
        onLongPress: () => _react(message),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(NxSpace.md, NxSpace.sm, NxSpace.md, NxSpace.sm),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: outgoing ? scheme.primary : scheme.secondaryContainer,
              foregroundColor: outgoing ? scheme.onPrimary : scheme.onSecondaryContainer,
              child: outgoing
                  ? const Icon(Icons.north_east, size: 18)
                  : Text(_initials(sender), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: NxSpace.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(
                  [
                    '$sender → $route',
                    // Heard over the internet, not over the air.
                    if (message.viaMqtt) 'via MQTT'
                    else if (_hopsLabel(message.hops) case final hops?) hops,
                  ].join(' • '),
                  style: type.labelMedium?.copyWith(color: mentioned ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
                )),
                if (pinned) Icon(Icons.push_pin, size: 14, semanticLabel: 'Pinned', color: scheme.onSurfaceVariant),
                const SizedBox(width: NxSpace.xxs),
                Text(_clock(message.timestamp), style: type.labelMedium?.copyWith(
                    color: mentioned ? scheme.onPrimaryContainer : scheme.onSurfaceVariant)),
              ]),
              const SizedBox(height: 2),
              Text(message.text, style: type.bodyLarge?.copyWith(
                  color: mentioned ? scheme.onPrimaryContainer : null)),
              if (mentioned)
                Padding(
                  padding: const EdgeInsets.only(top: NxSpace.xxs),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.alternate_email, size: 14, color: scheme.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text('Mentions you', style: type.labelMedium?.copyWith(color: scheme.onPrimaryContainer)),
                  ]),
                ),
              if (rs != null)
                Padding(
                  padding: const EdgeInsets.only(top: NxSpace.xxs),
                  child: Semantics(
                    label: 'Reactions: ${[for (final r in rs) '${r.text} from ${r.direction == BastionMessageDirection.outgoing ? 'you' : _nodeName(r.from)}'].join(', ')}',
                    excludeSemantics: true,
                    child: Wrap(spacing: 6, runSpacing: 4, children: [
                      for (final e in {for (final r in rs) r.text}.toList())
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text('$e ${rs.where((r) => r.text == e).length}'),
                        ),
                    ]),
                  ),
                ),
              if (outgoing || message.deliveryState != BastionDeliveryState.received)
                Padding(
                  padding: const EdgeInsets.only(top: NxSpace.xxs),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_deliveryIcon(message.deliveryState), size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(_deliveryLabel(message.deliveryState), style: type.labelMedium?.copyWith(color: statusColor)),
                  ]),
                ),
            ])),
          ]),
        ),
      ),
    );
  }

  String _nodeName(int nodeNum) {
    for (final node in widget.radio.nodes) {
      if (node.num == nodeNum) return node.displayName;
    }
    return '!${nodeNum.toRadixString(16).padLeft(8, '0')}';
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.radio,
    builder: (context, _) {
      final all = widget.radio.messages;
      // Reactions show under the message they react to, not on their own.
      final messages = [for (final m in all) if (!m.isReaction) m];
      final reactions = <int, List<BastionChatMessage>>{};
      for (final m in all) {
        if (m.isReaction && m.replyId != null) (reactions[m.replyId!] ??= []).add(m);
      }
      final matches = BastionMessageSearch.filter(messages, search.text,
          (message) => message.text);
      final now = DateTime.now();
      final pins = widget.radio.chatMarks.pinnedIn(messages);
      final channels = widget.radio.channelMetadata.where((c) => c.role != 0).toList();
      if (channels.isNotEmpty && !channels.any((c) => c.index == channel)) {
        channel = channels.first.index;
      }
      if (destination != 0xffffffff && !widget.radio.nodes.any((n) => n.num == destination)) {
        destination = 0xffffffff;
      }
      final connected = widget.radio.isReady;
      final scheme = Theme.of(context).colorScheme;
      final filters = widget.radio.filters;
      return ListView(
        padding: NxSpace.page,
        children: [
          NxPageHeader(
            title: 'Chats',
            subtitle: connected
                ? 'Connected. Messages send right away.'
                : 'Offline. Messages wait in a queue and send when your radio connects.',
          ),
          if (widget.radio.messageStorageProblem case final problem?)
            NxBanner(tone: NxTone.danger, icon: Icons.sd_card_alert_outlined,
              title: 'Message storage problem', message: problem),
          if (widget.radio.filteredMessageCount > 0 || filters.showFiltered && filters.words.isNotEmpty)
            NxBanner(
              icon: Icons.filter_alt_outlined,
              message: filters.showFiltered
                  ? 'Showing messages that match your word filters'
                  : '${widget.radio.filteredMessageCount} message${widget.radio.filteredMessageCount == 1 ? '' : 's'} hidden by your word filters',
              action: TextButton(
                onPressed: () => filters.setShowFiltered(!filters.showFiltered),
                child: Text(filters.showFiltered ? 'Hide' : 'Show'),
              ),
            ),
          if (BastionPreferences.instance.statistics) ...[
            NxStatRow(children: [
              NxStatTile(label: 'Link', value: connected ? 'Online' : 'Offline',
                tone: connected ? NxTone.success : NxTone.neutral),
              NxStatTile(label: 'Messages', value: '${messages.length}'),
              NxStatTile(label: 'Queued', value: '${widget.radio.pendingMessageCount}',
                tone: widget.radio.pendingMessageCount > 0 ? NxTone.warning : NxTone.neutral),
            ]),
            const SizedBox(height: NxSpace.xs),
          ],
          const NxSectionLabel('New message'),
          if (destination != 0xffffffff && widget.radio.nodeKeys.hasChanged(destination))
            NxBanner(
              tone: NxTone.danger,
              icon: Icons.gpp_maybe_outlined,
              title: 'Security key changed',
              message: '${_nodeName(destination)} now shows a different key. Check with its owner before '
                  'sending anything private. Open the node to review or trust the new key.',
            ),
          Card(child: Padding(
            padding: const EdgeInsets.all(NxSpace.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              DropdownButtonFormField<int>(
                key: ValueKey(destination),
                initialValue: destination,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'To',
                  prefixIcon: Icon(Icons.cell_tower),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 0xffffffff,
                    child: Text('Everyone on the channel'),
                  ),
                  for (final node in widget.radio.nodes)
                    DropdownMenuItem(
                      value: node.num,
                      child: Text('Direct • ${node.displayName}', overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) _switchTo(newDestination: value);
                },
              ),
              const SizedBox(height: NxSpace.sm),
              DropdownButtonFormField<int>(
                key: ValueKey('channel-$channel'),
                initialValue: channel,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Channel', prefixIcon: Icon(Icons.podcasts)),
                items: channels.isEmpty
                    ? [const DropdownMenuItem(value: 0, child: Text('Channel 0 • Broadcast')),
                       if (channel != 0) DropdownMenuItem(value: channel,
                           child: Text('Channel $channel • Offline'))]
                    : [for (final c in channels) DropdownMenuItem(value: c.index,
                        child: Text('Channel ${c.index} • ${c.name.isEmpty ? 'Default' : c.name}'))],
                onChanged: (value) { if (value != null) _switchTo(newChannel: value); },
              ),
              const SizedBox(height: NxSpace.sm),
              TextField(
                controller: composer,
                maxLength: 228,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: destination == 0xffffffff
                      ? 'Message Channel $channel'
                      : 'Message ${_nodeName(destination)}',
                  suffixIcon: IconButton(
                    tooltip: 'Mention a node',
                    icon: const Icon(Icons.alternate_email),
                    onPressed: _mention,
                  ),
                ),
                onSubmitted: (_) => _send(),
                onChanged: (_) => _saveDraft(),
              ),
              FilledButton.icon(
                onPressed: _send,
                icon: const Icon(Icons.send),
                label: const Text('Send'),
              ),
              const SizedBox(height: NxSpace.sm),
              Text('Quick replies', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: NxSpace.xs),
              Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
                for (final quick in const [
                  'Copy',
                  'On my way',
                  'Need assistance',
                  'What is your position?',
                ])
                  ActionChip(
                    label: Text(quick),
                    onPressed: () => _send(quick),
                  ),
              ]),
            ]),
          )),
          if (pins.isNotEmpty) ...[
            const NxSectionLabel('Pinned'),
            Card(child: Column(children: [
              for (final (i, message) in pins.indexed) ...[
                if (i > 0) const Divider(indent: 56),
                ListTile(
                  leading: Icon(Icons.push_pin, color: scheme.primary),
                  title: Text(message.text, maxLines: 3),
                  subtitle: Text('${message.direction == BastionMessageDirection.outgoing ? 'You' : _nodeName(message.from)} • ${BastionChatDays.label(message.timestamp, now)}'),
                  trailing: IconButton(
                    tooltip: 'Unpin',
                    icon: const Icon(Icons.close),
                    onPressed: () => _togglePin(message),
                  ),
                ),
              ],
            ])),
          ],
          NxSectionLabel('Messages', trailing: messages.isEmpty ? null : Text('Hold a message for more',
            style: Theme.of(context).textTheme.bodySmall)),
          if (messages.isNotEmpty)
            TextField(
              controller: search,
              decoration: InputDecoration(
                labelText: 'Search message history',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.text.isEmpty ? null : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(search.clear),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          if (messages.isNotEmpty && matches.isEmpty)
            const NxEmptyState(icon: Icons.search_off, title: 'No matches',
              detail: 'No messages match your search.'),
          if (messages.isEmpty)
            const NxEmptyState(
              icon: Icons.mark_chat_unread_outlined,
              title: 'No mesh messages yet',
              detail: 'Channel and direct messages appear here once your radio hears them.',
            )
          else
            for (final row in _timelineRows(matches.reversed.toList(), now))
              switch (row) {
                _DayRow(:final label) => _TimelineDivider(label: label),
                _NewRow() => const _TimelineDivider(label: 'New messages above', highlight: true),
                _MessageRow(:final message) => _messageCard(context, message, reactions[message.packetId]),
              },
          const NxSectionLabel('Automatic replies'),
          Card(child: Column(children: [
            SwitchListTile(
              secondary: const Icon(Icons.smart_toy_outlined),
              title: const Text('Bot mode'),
              subtitle: Text(widget.radio.botProblem ?? (widget.botMode
                  ? 'On. Replies to direct messages and answers !help and !status, within quiet hours and airtime limits.'
                  : 'Off. No automatic replies are sent.')),
              value: widget.botMode,
              onChanged: widget.onBotModeChanged,
            ),
            const Divider(indent: 56),
            ExpansionTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Bot reply message'),
              childrenPadding: const EdgeInsets.fromLTRB(NxSpace.md, 0, NxSpace.md, NxSpace.md),
              children: [
                TextField(
                  controller: reply,
                  maxLines: 3,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    hintText: 'Message to send while Bot mode is on',
                  ),
                  onChanged: widget.onAwayReplyChanged,
                ),
              ],
            ),
          ])),
        ],
      );
    },
  );
}

/// The time of day as HH:mm, for message timestamps.
String _clock(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

IconData _deliveryIcon(BastionDeliveryState state) => switch (state) {
  BastionDeliveryState.received => Icons.call_received,
  BastionDeliveryState.queued => Icons.schedule,
  BastionDeliveryState.sent => Icons.check,
  BastionDeliveryState.delivered => Icons.done_all,
  BastionDeliveryState.failed => Icons.error_outline,
};

String _deliveryLabel(BastionDeliveryState state) => switch (state) {
  BastionDeliveryState.received => 'Received',
  BastionDeliveryState.queued => 'Queued',
  BastionDeliveryState.sent => 'Sent',
  BastionDeliveryState.delivered => 'Delivered',
  BastionDeliveryState.failed => 'Not delivered',
};

class _ToolsPage extends StatefulWidget {
  const _ToolsPage({required this.discovery, required this.radio});
  final MeshtasticBleDiscovery discovery;
  final MeshtasticRadioCoordinator radio;
  @override
  State<_ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<_ToolsPage> {
  final battery = TextEditingController(text: '3000');
  final draw = TextEditingController(text: '100');
  double? runtime;
  final checked = <String>{};
  static const checklist = [
    'Radio charged', 'Antenna attached', 'Region configured',
    'Primary channel verified', 'GPS / position policy checked',
  ];

  @override
  void dispose() { battery.dispose(); draw.dispose(); super.dispose(); }

  void calculate() {
    final mah = double.tryParse(battery.text);
    final ma = double.tryParse(draw.text);
    setState(() => runtime = mah != null && ma != null && ma > 0 ? mah / ma : null);
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.radio, widget.discovery]),
    builder: (context, _) {
      final radio = widget.radio;
      final readings = radio.deviceTelemetry.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return ListView(
    padding: NxSpace.page,
    children: [
      const NxPageHeader(title: 'Tools',
        subtitle: 'Utilities for planning, testing and running a deployment.'),
      const NxSectionLabel('Before you go'),
      Card(child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.checklist),
        title: const Text('Deployment checklist'),
        subtitle: Text('${checked.length} of ${checklist.length} ready'),
        children: [
          for (final item in checklist)
            CheckboxListTile(
              title: Text(item), value: checked.contains(item),
              onChanged: (value) => setState(() {
                value == true ? checked.add(item) : checked.remove(item);
              }),
            ),
        ],
      )),
      Card(child: ExpansionTile(
        leading: const Icon(Icons.battery_charging_full),
        title: const Text('Battery runtime'),
        subtitle: const Text('Estimate hours from capacity and average draw'),
        childrenPadding: const EdgeInsets.fromLTRB(NxSpace.md, 0, NxSpace.md, NxSpace.md),
        children: [
          Row(children: [
            Expanded(child: TextField(controller: battery,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Battery (mAh)'))),
            const SizedBox(width: NxSpace.sm),
            Expanded(child: TextField(controller: draw,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Average draw (mA)'))),
          ]),
          const SizedBox(height: NxSpace.sm),
          SizedBox(width: double.infinity,
            child: FilledButton(onPressed: calculate, child: const Text('Calculate'))),
          if (runtime != null)
            Padding(padding: const EdgeInsets.only(top: NxSpace.sm),
              child: Semantics(liveRegion: true, child: Text('About ${runtime!.toStringAsFixed(1)} hours',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary)))),
        ],
      )),
      const NxSectionLabel('Mesh tools'),
      NxGroupCard(children: [
        ListTile(
          leading: const Icon(Icons.monitor_heart_outlined),
          title: const Text('Mesh health & airtime'),
          subtitle: const Text('How busy the channel is and how much your radio transmits'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(MeshHealthPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.terrain),
          title: const Text('Link planner'),
          subtitle: const Text('Check line of sight between two nodes over the terrain'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(LinkPlannerPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.network_check),
          title: const Text('Range test'),
          subtitle: const Text('Log packets from a range test sender with signal and distance'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(MeshToolsPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          enabled: radio.isReady,
          leading: const Icon(Icons.route),
          title: const Text('Traceroute'),
          subtitle: Text(radio.isReady
            ? 'Show the relay path to a node and back'
            : 'Connect to a radio to trace routes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(TraceroutePage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: const Text('Store & forward'),
          subtitle: const Text('Replay messages you missed from a router'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(MeshToolsPage(radio: radio, initialTab: 1)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.campaign_outlined),
          title: const Text('Mesh beacons'),
          subtitle: Text(radio.beacons.isEmpty
              ? 'Hear mesh invitations nearby and send your own'
              : '${radio.beacons.length} heard • send your own'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(BeaconPage(radio: radio)),
        ),
      ]),
      const NxSectionLabel('Records'),
      Card(child: ListTile(
        leading: const Icon(Icons.assignment_outlined),
        title: const Text('Incident log, templates & coverage'),
        subtitle: const Text('Saved field records and exports'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(FieldToolsPage(radio: radio)),
      )),
      const NxSectionLabel('Signal'),
      Card(child: ExpansionTile(
        leading: const Icon(Icons.monitor_heart_outlined),
        title: const Text('Live telemetry'),
        subtitle: Text(radio.isReady
          ? '${readings.length} node${readings.length == 1 ? '' : 's'} reporting device metrics'
          : 'Connect to a radio to receive telemetry'),
        childrenPadding: const EdgeInsets.fromLTRB(NxSpace.md, 0, NxSpace.md, NxSpace.md),
        children: [
          if (readings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: NxSpace.sm),
              child: Text('Nothing received yet. Metrics appear when nodes send them.'),
            ),
          for (final entry in readings)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(radio.nodeName(entry.key)),
              subtitle: Text([
                if (entry.value.batteryLevel != null)
                  'Battery ${entry.value.batteryLevel}%',
                if (entry.value.voltage != null)
                  '${entry.value.voltage!.toStringAsFixed(2)} V',
                if (entry.value.channelUtilization != null)
                  'Channel busy ${entry.value.channelUtilization!.toStringAsFixed(1)}%',
                if (entry.value.airUtilTx != null)
                  'Transmitting ${entry.value.airUtilTx!.toStringAsFixed(1)}%',
              ].join(' • ')),
            ),
        ],
      )),
      Card(child: ExpansionTile(
        leading: const Icon(Icons.signal_cellular_alt),
        title: const Text('Bluetooth signal guide'),
        subtitle: const Text('What the signal numbers (RSSI) mean'),
        childrenPadding: const EdgeInsets.fromLTRB(NxSpace.md, 0, NxSpace.md, NxSpace.md),
        children: const [
          _ReferenceRow(value: '−50 dBm', label: 'Excellent, very close'),
          _ReferenceRow(value: '−60 dBm', label: 'Strong'),
          _ReferenceRow(value: '−70 dBm', label: 'Usable'),
          _ReferenceRow(value: '−80 dBm', label: 'Weak'),
          _ReferenceRow(value: '≤ −90', label: 'Very weak, may drop'),
        ],
      )),
      Card(child: ListTile(
        leading: const Icon(Icons.bluetooth_searching),
        title: const Text('Scan for radios'),
        subtitle: Text(widget.discovery.scanning
            ? 'Scanning…'
            : '${widget.discovery.results.length} Bluetooth device${widget.discovery.results.length == 1 ? '' : 's'} found'),
        trailing: const Icon(Icons.chevron_right),
        onTap: widget.discovery.scanning ? null : widget.discovery.scan,
      )),
    ],
  );
    },
  );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.radio, required this.demo, required this.onDemoChanged});
  final MeshtasticRadioCoordinator radio;

  /// Whether the pretend radio is showing.
  final bool demo;
  final ValueChanged<bool> onDemoChanged;

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: radio,
    builder: (context, _) {
      final local = radio.localNode;
      final sent = radio.lastPhonePositionSent;
      final locationStatus = radio.locationShareProblem ??
          (!radio.sharePhoneLocation
              ? 'Off. Your phone location is never sent.'
              : !radio.isReady
                  ? 'On. Starts when a radio is connected.'
                  : sent == null
                      ? 'On. Waiting for a GPS fix.'
                      : 'On. Last sent ${sent.toLocal().toString().substring(11, 16)}.');
      return ListView(
    padding: NxSpace.page,
    children: [
      const NxPageHeader(title: 'Settings',
        subtitle: 'Your radio, how the app behaves, and your data.'),
      const NxSectionLabel('Radio'),
      Card(child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.settings_input_antenna),
        title: const Text('Radio configuration'),
        subtitle: Text(radio.canAdminister
          ? 'Connected • settings can be changed'
          : radio.isReady && radio.firmwareSupport == FirmwareSupport.unsupported
              ? 'Read-only: firmware ${radio.firmwareVersion} is older than '
                '${BastionFirmware.minimum.$1}.${BastionFirmware.minimum.$2}. Update at ${BastionFirmware.flasher}.'
              : 'Connect to a radio to view and change its settings'),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Node identity'),
            subtitle: Text(local == null
              ? 'Waiting for this radio\'s node information'
              : '${local.longName ?? 'No long name'} • ${local.shortName ?? 'No short name'}\n'
                '${local.id ?? 'ID not reported'}'),
            isThreeLine: local != null,
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Change radio settings'),
            subtitle: const Text('Owner, LoRa, channels, device role and position'),
            enabled: radio.canAdminister,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, RadioSettingsPage(radio: radio)),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Device & LoRa'),
            subtitle: Text(radio.loraSettings.isEmpty
              ? 'Not received yet (${radio.radioConfigCount} configuration messages)'
              : radio.loraSettings.join('\n'))),
          ListTile(
            leading: const Icon(Icons.podcasts),
            title: const Text('Channels'),
            subtitle: Text(radio.channelSettings.isEmpty
              ? 'Not received yet (${radio.channelConfigCount} channel messages)'
              : radio.channelSettings.join('\n')),
          ),
          ListTile(
            leading: const Icon(Icons.extension_outlined),
            title: const Text('Modules'),
            subtitle: Text('${radio.moduleConfigCount} module messages received. Change them in radio settings.')),
        ],
      )),
      Card(child: Column(children: [
        SwitchListTile(
          secondary: const Icon(Icons.share_location),
          title: const Text('Share phone location with mesh'),
          subtitle: Text('$locationStatus\nUsed when the radio has no GPS of its own. '
              'Updates every 5 min, or sooner when you move.'),
          isThreeLine: true,
          value: radio.sharePhoneLocation,
          onChanged: (value) => radio.setSharePhoneLocation(value),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.blur_on),
          title: const Text('Location precision'),
          subtitle: const Text('Rounded on this phone before it is sent'),
          trailing: DropdownButton<int>(
            value: radio.locationPrecision,
            underline: const SizedBox.shrink(),
            items: [for (final e in BastionPhonePositionSharer.precisionChoices.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value == 0
                  ? 'Precise'
                  : 'About ${BastionUnitFormat.distance(e.value.toDouble(), BastionPreferences.instance.units)}'))],
            onChanged: (v) { if (v != null) radio.setLocationPrecision(v); },
          ),
        ),
      ])),
      _BackgroundCard(radio: radio),
      Card(child: SwitchListTile(
        secondary: const Icon(Icons.battery_saver_outlined),
        title: const Text('Low-power field mode'),
        subtitle: const Text('Shared location uses balanced GPS and updates every 15 min, '
            'or after 200 m of movement. The radio link and coverage recording are unchanged.'),
        isThreeLine: true,
        value: radio.lowPowerMode,
        onChanged: (value) => radio.setLowPowerMode(value))),
      const NxSectionLabel('App'),
      const BastionAppearanceCard(),
      _FieldAlertsCard(radio: radio),
      const _MessagesCard(),
      _FiltersCard(radio: radio),
      const _MapCacheCard(),
      if (BastionHomeWidget.instance case final widget?)
        Card(child: StatefulBuilder(builder: (context, setLocal) => SwitchListTile(
          secondary: const Icon(Icons.widgets_outlined),
          title: const Text('Show messages on the home-screen widget'),
          subtitle: const Text('Off: the widget shows only how many messages are unread. '
              'On: it also shows the sender and text, which anyone holding the phone can see.'),
          isThreeLine: true,
          value: widget.showMessage,
          onChanged: (v) async {
            await widget.setShowMessage(v);
            setLocal(() {});
          },
        ))),
      const NxSectionLabel('Your data'),
      _RadioDataCard(radio: radio),
      NxGroupCard(children: [
        ListTile(
          leading: const Icon(Icons.enhanced_encryption_outlined),
          title: const Text('Encrypted radio backup'),
          subtitle: const Text('Save or restore settings and channel keys, protected by a password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(context, RadioBackupPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.phone_android_outlined),
          title: const Text('Phone data backup'),
          subtitle: const Text('Chats, nodes, waypoints, records and settings, for moving to a new phone'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(context, PhoneBackupPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy & data'),
          subtitle: const Text('What is stored and sent; delete chat history or all phone data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(context, PrivacyPage(radio: radio)),
        ),
      ]),
      Card(child: SwitchListTile(
        secondary: const Icon(Icons.play_circle_outline),
        title: const Text('Demo mode'),
        subtitle: const Text('Explore the app with a pretend radio and mesh. Nothing is sent, '
            'and your own messages and settings are left alone.'),
        isThreeLine: true,
        value: demo,
        onChanged: onDemoChanged,
      )),
      const NxSectionLabel('About'),
      NxGroupCard(children: [
        const ListTile(
          leading: Icon(Icons.info_outline), title: Text('NOTORYX Connect'),
          subtitle: Text('Development build • Independent mesh companion')),
        const Divider(indent: 56),
        const ListTile(
          leading: Icon(Icons.bluetooth), title: Text('Connection'),
          subtitle: Text('Bluetooth LE • Safety mode on: no unverified device is treated as a mesh node')),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.description_outlined), title: const Text('Third-party licenses'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(context: context, applicationName: 'NOTORYX Connect'),
        ),
        const Divider(indent: 56),
        const ListTile(
          leading: Icon(Icons.gavel_outlined),
          title: Text('Trademark & compatibility'),
          subtitle: Text(
            'Compatible with Meshtastic® firmware. Meshtastic® is a registered trademark of Meshtastic LLC. Meshtastic software components are released under various licenses, see GitHub for details. No warranty is provided - use at your own risk.\n\nNOTORYX Connect is independently developed and is not affiliated with, sponsored by, or endorsed by Meshtastic LLC.',
          ),
        ),
      ]),
      const NxBanner(
        tone: NxTone.warning,
        icon: Icons.shield_outlined,
        message: 'Do not rely on this development build as your only way to call for help.',
      ),
    ],
  );
    },
  );
}

/// Safe channel editor preview. No channel write is attempted until authenticated
/// admin responses and verified radio readback are implemented.
class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 80, child: Text(value,
        style: TextStyle(fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary))),
      Expanded(child: Text(label)),
    ]),
  );
}

String _rssiLabel(int rssi) {
  if (rssi >= -60) return 'Strong Bluetooth signal';
  if (rssi >= -75) return 'Usable Bluetooth signal';
  if (rssi >= -90) return 'Weak Bluetooth signal';
  return 'Very weak Bluetooth signal';
}


String _connectionLabel(MeshtasticConnectionState state) => switch (state) {
  MeshtasticConnectionState.disconnected => 'Offline',
  MeshtasticConnectionState.discovering => 'Scanning',
  MeshtasticConnectionState.connecting => 'Connecting',
  MeshtasticConnectionState.connected => 'Syncing',
  MeshtasticConnectionState.synchronizing => 'Syncing',
  MeshtasticConnectionState.ready => 'Connected',
  MeshtasticConnectionState.error => 'Error',
};

NxTone _connectionTone(MeshtasticConnectionState state) => switch (state) {
  MeshtasticConnectionState.disconnected => NxTone.neutral,
  MeshtasticConnectionState.discovering ||
  MeshtasticConnectionState.connecting ||
  MeshtasticConnectionState.connected ||
  MeshtasticConnectionState.synchronizing => NxTone.info,
  MeshtasticConnectionState.ready => NxTone.success,
  MeshtasticConnectionState.error => NxTone.danger,
};

bool _connectionBusy(MeshtasticConnectionState state) => switch (state) {
  MeshtasticConnectionState.discovering ||
  MeshtasticConnectionState.connecting ||
  MeshtasticConnectionState.connected ||
  MeshtasticConnectionState.synchronizing => true,
  _ => false,
};

/// Message housekeeping and read-aloud.
class _MessagesCard extends StatelessWidget {
  const _MessagesCard();
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: BastionPreferences.instance,
    builder: (context, _) {
      final p = BastionPreferences.instance;
      return Card(child: ExpansionTile(
        leading: const Icon(Icons.forum_outlined),
        title: const Text('Messages'),
        subtitle: Text([
          p.channelRetentionDays == 0
              ? 'Channel messages kept'
              : 'Channel messages deleted after ${p.channelRetentionDays} day${p.channelRetentionDays == 1 ? '' : 's'}',
          'newest ${p.historyLimit >= 1000 ? '${p.historyLimit ~/ 1000},000' : p.historyLimit} per conversation',
          if (p.readAloud) 'read aloud on',
        ].join(' • ')),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          DropdownButtonFormField<int>(
            initialValue: BastionPreferences.retentionChoices.contains(p.channelRetentionDays)
                ? p.channelRetentionDays : 0,
            decoration: const InputDecoration(
              labelText: 'Delete old channel messages',
              helperText: 'Direct messages are always kept',
            ),
            items: [for (final d in BastionPreferences.retentionChoices)
              DropdownMenuItem(value: d, child: Text(d == 0 ? 'Never' : 'After $d day${d == 1 ? '' : 's'}'))],
            onChanged: (d) => p.update(retentionDays: d),
          ),
          DropdownButtonFormField<int>(
            initialValue: p.historyLimit,
            decoration: const InputDecoration(
              labelText: 'Message history',
              helperText: 'Per channel or direct conversation. A lower limit deletes older messages.',
              helperMaxLines: 2,
            ),
            items: [for (final n in BastionHistoryLimit.choices)
              DropdownMenuItem(value: n, child: Text('Keep newest ${n >= 1000 ? '${n ~/ 1000},000' : n}'))],
            onChanged: (n) => p.update(keepMessages: n),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Read messages aloud'),
            subtitle: const Text('Uses the phone\'s text-to-speech, including with the screen off'),
            value: p.readAloud,
            onChanged: (v) => p.update(speak: v),
          ),
        ],
      ));
    },
  );
}

/// Shows whether Android lets the app keep the radio link open in the
/// background, with a shortcut to the battery optimization setting.
class _BackgroundCard extends StatefulWidget {
  const _BackgroundCard({required this.radio});
  final MeshtasticRadioCoordinator radio;
  @override
  State<_BackgroundCard> createState() => _BackgroundCardState();
}

class _BackgroundCardState extends State<_BackgroundCard> {
  bool? _optimized;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Re-check when the user comes back from Android's settings.
    _lifecycle = AppLifecycleListener(onResume: _check);
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final optimized = await BastionForegroundService.batteryOptimized();
    if (mounted) setState(() => _optimized = optimized);
  }

  @override
  Widget build(BuildContext context) {
    final optimized = _optimized;
    if (optimized == null) return const SizedBox.shrink();
    final problem = widget.radio.backgroundProblem;
    return Card(child: ListTile(
      leading: Icon(problem != null || optimized ? Icons.warning_amber : Icons.check_circle_outline,
        color: problem != null || optimized ? Theme.of(context).colorScheme.error : BastionApp.accentOf(context)),
      title: const Text('Background connection'),
      subtitle: Text(problem ?? (optimized
          ? 'Battery optimization can pause NOTORYX Connect when it is not on screen and drop the '
            'radio link. Set its battery use to Unrestricted to stay connected.'
          : 'Allowed to run in the background. A notification shows while a radio is connected.')),
      isThreeLine: true,
      trailing: optimized ? TextButton(
        onPressed: BastionForegroundService.openBatterySettings,
        child: const Text('Open settings')) : null,
    ));
  }
}

class _MapCacheCard extends StatefulWidget {
  const _MapCacheCard();

  @override
  State<_MapCacheCard> createState() => _MapCacheCardState();
}

class _MapCacheCardState extends State<_MapCacheCard> {
  late Future<int?> _size = BastionTileCache.sizeBytes();

  @override
  Widget build(BuildContext context) => Card(child: FutureBuilder<int?>(
    future: _size,
    builder: (context, snapshot) {
      final bytes = snapshot.data;
      return ListTile(
        leading: const Icon(Icons.offline_pin_outlined),
        title: const Text('Offline map tiles'),
        subtitle: Text('${bytes == null ? 'Size unknown' : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB saved'}'
          '\nMap areas you view online stay available offline for a year (up to 500 MB).'),
        isThreeLine: true,
        trailing: TextButton(
          onPressed: bytes == null || bytes == 0 ? null : () async {
            await BastionTileCache.clear();
            if (mounted) setState(() => _size = BastionTileCache.sizeBytes());
          },
          child: const Text('Clear'),
        ),
      );
    },
  ));
}

class _FieldAlertsCard extends StatelessWidget {
  const _FieldAlertsCard({required this.radio});
  final MeshtasticRadioCoordinator radio;

  Future<void> _update(BuildContext context, BastionAlertSettings settings) async {
    final messenger = ScaffoldMessenger.of(context);
    if (!await radio.setAlertSettings(settings)) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Alert settings apply now, but could not be saved.')));
    }
  }

  static String _duration(Duration d) =>
      d.inHours >= 1 ? '${d.inHours} h' : '${d.inMinutes} min';

  @override
  Widget build(BuildContext context) {
    final s = radio.alertSettings;
    return Card(child: ExpansionTile(
      leading: const Icon(Icons.notifications_active_outlined),
      title: const Text('Field alerts'),
      subtitle: const Text('Phone notifications only; nothing is sent over the mesh'),
      children: [
        SwitchListTile(
          title: const Text('Low battery'),
          subtitle: Text('Your radio or a favorite reports ${s.batteryThreshold}% or less'),
          value: s.lowBattery,
          onChanged: (v) => _update(context, s.copyWith(lowBattery: v)),
        ),
        ListTile(
          title: const Text('Battery threshold'),
          enabled: s.lowBattery,
          trailing: DropdownButton<int>(
            value: s.batteryThreshold,
            items: [for (final v in BastionAlertSettings.batteryChoices)
              DropdownMenuItem(value: v, child: Text('$v%'))],
            onChanged: s.lowBattery ? (v) => _update(context, s.copyWith(batteryThreshold: v)) : null,
          ),
        ),
        SwitchListTile(
          title: const Text('New node'),
          subtitle: const Text('Your radio hears a node for the first time'),
          value: s.newNode,
          onChanged: (v) => _update(context, s.copyWith(newNode: v)),
        ),
        SwitchListTile(
          title: const Text('Favorite goes quiet'),
          subtitle: Text('A favorite is not heard for ${_duration(s.silence)} while connected'),
          value: s.favoriteSilent,
          onChanged: (v) => _update(context, s.copyWith(favoriteSilent: v)),
        ),
        ListTile(
          title: const Text('Quiet after'),
          enabled: s.favoriteSilent,
          trailing: DropdownButton<Duration>(
            value: s.silence,
            items: [for (final v in BastionAlertSettings.silenceChoices)
              DropdownMenuItem(value: v, child: Text(_duration(v)))],
            onChanged: s.favoriteSilent ? (v) => _update(context, s.copyWith(silence: v)) : null,
          ),
        ),
      ],
    ));
  }
}

/// Lists the radios with data on this phone, and moves a lost or replaced
/// radio's messages, nodes and history to the connected radio.
class _RadioDataCard extends StatefulWidget {
  const _RadioDataCard({required this.radio});
  final MeshtasticRadioCoordinator radio;
  @override
  State<_RadioDataCard> createState() => _RadioDataCardState();
}

class _RadioDataCardState extends State<_RadioDataCard> {
  Future<List<StoredRadio>>? _radios;
  String? _result;
  bool _moving = false;

  bool get _canMove => widget.radio.isReady && widget.radio.localNodeNum != null && !_moving;

  void _load() => setState(() => _radios = widget.radio.storedRadios());

  Future<void> _move(StoredRadio from) async {
    final to = widget.radio.localNode?.displayName ?? 'the connected radio';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move ${from.label}?'),
        content: Text('Its messages, offline queue, NodeDex history, trails and telemetry history move to $to. '
            'Whatever $to already has is kept, so nothing is overwritten. '
            '${from.id} then no longer has an entry of its own.\n\n'
            'To be safe, make a phone data backup first.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Move')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _moving = true; _result = null; });
    final problem = await widget.radio.moveRadioData(from.radio);
    if (!mounted) return;
    setState(() {
      _moving = false;
      _result = problem ?? 'Moved ${from.label} to $to.';
    });
    _load();
  }

  @override
  Widget build(BuildContext context) => Card(child: ExpansionTile(
    leading: const Icon(Icons.sd_storage_outlined),
    title: const Text('Radio data'),
    subtitle: const Text('Lost or replaced a radio? Move its messages, nodes and history to the new one'),
    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    onExpansionChanged: (open) { if (open) _load(); },
    children: [
      FutureBuilder<List<StoredRadio>>(
        future: _radios,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Text('Radio data could not be read.');
          final radios = snapshot.data;
          if (radios == null) return const LinearProgressIndicator();
          if (radios.isEmpty) return const Text('No radio data on this phone yet.');
          return Column(children: [
            for (final r in radios)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r.label),
                subtitle: Text('${r.messages} message${r.messages == 1 ? '' : 's'} • '
                    '${r.nodes} node${r.nodes == 1 ? '' : 's'} • '
                    '${r.trails} trail${r.trails == 1 ? '' : 's'}'),
                trailing: r.radio == widget.radio.localNodeNum
                    ? const Text('Connected')
                    : TextButton(
                        onPressed: _canMove ? () => _move(r) : null,
                        child: const Text('Move to connected'),
                      ),
              ),
          ]);
        },
      ),
      if (!widget.radio.isReady)
        const Text("Connect to the new radio to move an old radio's data to it."),
      if (_moving) const LinearProgressIndicator(),
      if (_result != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_result!)),
    ],
  ));
}

class _FiltersCard extends StatefulWidget {
  const _FiltersCard({required this.radio});
  final MeshtasticRadioCoordinator radio;
  @override
  State<_FiltersCard> createState() => _FiltersCardState();
}

class _FiltersCardState extends State<_FiltersCard> {
  final _word = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  String _name(int num) {
    for (final n in widget.radio.allNodes) {
      if (n.num == num) return n.displayName;
    }
    return '!${num.toRadixString(16).padLeft(8, '0')}';
  }

  Future<void> _add() async {
    final error = await widget.radio.filters.addWord(_word.text);
    if (!mounted) return;
    setState(() => _error = error);
    if (error == null) _word.clear();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.radio.filters;
    return Card(child: ExpansionTile(
      leading: const Icon(Icons.filter_alt_outlined),
      title: const Text('Filters'),
      subtitle: Text('${f.ignored.length} ignored • ${f.muted.length} muted • ${f.words.length} filtered words'),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: Text('Filtered words',
            style: Theme.of(context).textTheme.titleSmall)),
        const Text('Incoming messages with these words are hidden, not deleted.'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(
            controller: _word,
            decoration: InputDecoration(labelText: 'Word or phrase', errorText: _error),
            onSubmitted: (_) => _add(),
          )),
          IconButton(tooltip: 'Add filtered word', icon: const Icon(Icons.add), onPressed: _add),
        ]),
        Wrap(spacing: 8, children: [
          for (final w in f.words)
            InputChip(label: Text(w), onDeleted: () => f.removeWord(w), deleteButtonTooltipMessage: 'Remove $w'),
        ]),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show filtered messages'),
          value: f.showFiltered,
          onChanged: f.setShowFiltered,
        ),
        const Divider(),
        Align(alignment: AlignmentDirectional.centerStart, child: Text('Ignored and muted nodes',
            style: Theme.of(context).textTheme.titleSmall)),
        if (f.ignored.isEmpty && f.muted.isEmpty)
          const ListTile(contentPadding: EdgeInsets.zero,
              title: Text('None. Open a node to ignore or mute it.')),
        for (final n in f.ignored)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.block),
            title: Text(_name(n)),
            subtitle: const Text('Ignored'),
            trailing: TextButton(onPressed: () => f.setIgnored(n, false), child: const Text('Unignore')),
          ),
        for (final n in f.muted)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_off_outlined),
            title: Text(_name(n)),
            subtitle: const Text('Muted'),
            trailing: TextButton(onPressed: () => f.setMuted(n, false), child: const Text('Unmute')),
          ),
        if (f.problem != null) Text(f.problem!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    ));
  }
}

sealed class _TimelineRow {
  const _TimelineRow();
}

final class _DayRow extends _TimelineRow {
  const _DayRow(this.label);
  final String label;
}

final class _NewRow extends _TimelineRow {
  const _NewRow();
}

final class _MessageRow extends _TimelineRow {
  const _MessageRow(this.message);
  final BastionChatMessage message;
}

/// A labelled line across the timeline: a date, or where new messages end.
class _TimelineDivider extends StatelessWidget {
  const _TimelineDivider({required this.label, this.highlight = false});
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      header: true,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(child: Divider(color: color, thickness: highlight ? 2 : 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (highlight) Icon(Icons.arrow_upward, size: 14, color: color),
              if (highlight) const SizedBox(width: 4),
              Flexible(child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color))),
            ]),
          ),
          Expanded(child: Divider(color: color, thickness: highlight ? 2 : 1)),
        ]),
      ),
    );
  }
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

/// Shown on every screen while demo mode is on, so it is never mistaken for
/// a real mesh.
class _DemoBanner extends StatelessWidget {
  const _DemoBanner({required this.onExit});
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final status = NxStatusColors.of(context);
    final (bg, fg) = status.container(NxTone.info, Theme.of(context).colorScheme);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(NxSpace.md, NxSpace.xxs, NxSpace.xs, NxSpace.xxs),
          child: Row(children: [
            Icon(Icons.play_circle_outline, color: fg, size: 20),
            const SizedBox(width: NxSpace.xs),
            Expanded(child: Text('Demo mode: pretend radio and messages. Nothing is sent.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg))),
            TextButton(
              onPressed: onExit,
              style: TextButton.styleFrom(foregroundColor: fg),
              child: const Text('Exit demo'),
            ),
          ]),
        ),
      ),
    );
  }
}

/// "Direct" or "2 hops", or null when the hop count is unknown.
String? _hopsLabel(int? hops) => switch (hops) {
  null => null,
  0 => 'Direct',
  1 => '1 hop',
  final n => '$n hops',
};

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
