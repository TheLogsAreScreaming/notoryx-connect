import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'beacon_page.dart';
import 'link_planner_page.dart';
import 'map_page.dart';
import 'field_tools_page.dart';
import 'home_page.dart';
import 'services/bastion_units.dart';
import 'services/bastion_field_log.dart';
import 'app_lock_gate.dart';
import 'l10n/bastion_text.dart';
import 'services/bastion_app_lock.dart';
import 'services/bastion_background_service.dart';
import 'services/bastion_bot_guard.dart';
import 'services/bastion_history_limit.dart';
import 'services/bastion_mqtt_proxy.dart';
import 'services/bastion_heard_filter.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_radio_data.dart';
import 'phone_backup_page.dart';
import 'privacy_page.dart';
import 'radio_backup_page.dart';
import 'services/bastion_chat_marks.dart';
import 'services/bastion_message_search.dart';
import 'services/bastion_scheduled_messages.dart';
import 'services/bastion_sms_relay.dart';
import 'services/bastion_tak_bridge.dart';
import 'tak_bridge_page.dart';
import 'sms_relay_page.dart';
import 'mesh_health_page.dart';
import 'mesh_tools_page.dart';
import 'node_detail_page.dart';
import 'checklists_page.dart';
import 'services/bastion_checklists.dart';
import 'day_replay_page.dart';
import 'node_journal_page.dart';
import 'radio_settings_page.dart';
import 'services/bastion_tile_cache.dart';
import 'traceroute_page.dart';
import 'services/bastion_node_vault.dart';
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
import 'connection_doctor_page.dart';
import 'sentinel_page.dart';
import 'services/bastion_sentinel.dart';

part 'shell/nodes_page.dart';
part 'shell/chats_page.dart';
part 'shell/tools_page.dart';
part 'shell/settings_page.dart';
part 'shell/settings_cards.dart';
part 'shell/shell_labels.dart';

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
  await BastionChatStorage.applySavedEncryption();
  await BastionFieldLog.instance.load();
  await BastionBotGuard.instance.load();
  await BastionAppLock.instance.load();
  await BastionScheduledMessages.instance.load();
  await BastionTakBridge.instance.load();
  if (BastionSmsRelay.available) await BastionSmsRelay.instance.load();
  runApp(const BastionApp());
}

class BastionApp extends StatefulWidget {
  const BastionApp({super.key});
  /// NOTORYX orange from the app icon.
  static const signal = NxPalette.signal;

  /// The same hue, darkened for 4.5:1 contrast on light surfaces.
  static const signalOnLight = NxPalette.signalDeep;
  static const panel = NxPalette.ink1;

  /// The accent for the current theme.
  static Color accentOf(BuildContext context) => Theme.of(context).colorScheme.primary;

  /// The built-in look for [brightness] (Blaze dark, Bare Beauty light).
  static ThemeData appearance(Brightness brightness) => NotoryxTheme.build(brightness);

  @override
  State<BastionApp> createState() => _BastionAppState();
}

class _BastionAppState extends State<BastionApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // A dark-mode theme follows the device's light/dark setting.
  @override
  void didChangePlatformBrightness() {
    if (BastionPreferences.instance.darkModeTheme.isNotEmpty) setState(() {});
  }

  // Seasonal follows the date, so check it again when the app comes back.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) BastionAppLock.instance.onBackground();
    if (state == AppLifecycleState.resumed) {
      BastionAppLock.instance.onForeground();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: BastionPreferences.instance,
    builder: (context, _) {
      final platform = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final theme = NotoryxTheme.fromPalette(BastionPreferences.instance.palette(platform));
      return MaterialApp(
        title: 'NOTORYX Connect', debugShowCheckedModeBanner: false,
        theme: theme, darkTheme: theme, themeMode: ThemeMode.light,
        scrollBehavior: const BastionScrollBehavior(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          // Services and notifications follow the phone's language too.
          BastionText.use(Localizations.localeOf(context));
          return BastionAppLockGate(lock: BastionAppLock.instance, child: child!);
        },
        home: const BastionShell(),
      );
    },
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

  List<String> _labels(BuildContext context) {
    final l = AppLocalizations.of(context);
    return [l.tabHome, l.tabNodes, l.tabChats, l.tabMap, l.tabTools, l.tabSettings];
  }
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
    unawaited(_realRadio.prepareAlerts());
    unawaited(SentinelService.instance.start());
    // The real radio only: demo nodes must never reach ATAK.
    BastionTakBridge.instance.attach(() => _realRadio.nodes);
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
    BastionTakBridge.instance.detach();
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
                return Semantics(
                  container: true,
                  button: true,
                  // Announces a lost or restored radio without moving focus.
                  liveRegion: true,
                  label: AppLocalizations.of(context).radioStatus(_connectionLabel(context, state)),
                  onTapHint: AppLocalizations.of(context).radioStatusHint,
                  onTap: () => _go(1),
                  excludeSemantics: true,
                  child: Tooltip(
                    message: AppLocalizations.of(context).radioStatusTip(_connectionLabel(context, state)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(NxRadius.pill),
                      onTap: () => _go(1),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: NxTouch.min),
                        child: Center(child: NxStatusPill(
                          label: _connectionLabel(context, state),
                          tone: _connectionTone(state),
                          busy: _connectionBusy(state) || radio.isReconnecting,
                        )),
                      ),
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
                  for (final (i, label) in _labels(context).indexed)
                    NavigationRailDestination(icon: _tabIcon(i), label: Text(label)),
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
          for (final (i, label) in _labels(context).indexed)
            NavigationDestination(icon: _tabIcon(i), label: label, tooltip: label),
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
