import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'l10n/generated/app_localizations.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'beacon_page.dart';
import 'link_planner_page.dart';
import 'map_page.dart';
import 'drive_page.dart';
import 'field_tools_page.dart';
import 'home_page.dart';
import 'services/bastion_units.dart';
import 'services/bastion_app_search.dart';
import 'services/bastion_geo.dart';
import 'services/bastion_node_groups.dart';
import 'services/bastion_drive_log.dart';
import 'services/bastion_field_log.dart';
import 'app_lock_gate.dart';
import 'l10n/bastion_text.dart';
import 'services/bastion_airtime.dart';
import 'services/bastion_app_lock.dart';
import 'services/bastion_background_service.dart';
import 'services/bastion_bot_guard.dart';
import 'services/bastion_history_limit.dart';
import 'services/bastion_mqtt_proxy.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_stale.dart';
import 'services/bastion_radio_data.dart';
import 'nodedb_import_page.dart';
import 'phone_backup_page.dart';
import 'privacy_page.dart';
import 'radio_backup_page.dart';
import 'services/bastion_chat_marks.dart';
import 'services/bastion_conversations.dart';
import 'services/meshtastic_node_database.dart' show MeshtasticNode;
import 'services/bastion_message_search.dart';
import 'services/bastion_scheduled_messages.dart';
import 'services/bastion_send_failure.dart';
import 'services/bastion_sms_relay.dart';
import 'services/bastion_tak_bridge.dart';
import 'tak_bridge_page.dart';
import 'sms_relay_page.dart';
import 'mesh_health_page.dart';
import 'mesh_tools_page.dart';
import 'channel_share_page.dart';
import 'node_detail_page.dart';
import 'checklists_page.dart';
import 'automations_page.dart';
import 'services/bastion_automations.dart';
import 'services/bastion_checklists.dart';
import 'day_replay_page.dart';
import 'node_journal_page.dart';
import 'radio_settings_page.dart';
import 'services/bastion_tile_cache.dart';
import 'traceroute_page.dart';
import 'timeline_page.dart';
import 'services/bastion_timeline.dart';
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
import 'services/meshtastic_text_codec.dart' show BastionAckProof;
import 'services/meshtastic_radio_coordinator.dart';
import 'services/meshtastic_usb_transport.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'node_avatar.dart';
import 'services/bastion_node_looks.dart';
import 'services/bastion_link_preview.dart';
import 'services/bastion_track_log.dart';
import 'track_log_page.dart';
import 'field_guide_page.dart';
import 'backdrop_page.dart';
import 'battery_watch_page.dart';
import 'mesh_activity_page.dart';
import 'antenna_hunt_page.dart';
import 'services/bastion_sos_relay.dart';
import 'services/bastion_trail_store.dart';
import 'trail_routing_page.dart';
import 'services/bastion_mesh_watch.dart';
import 'theme/nx_backdrop.dart';
import 'theme/nx_glass.dart';
import 'theme/nx_components.dart';
import 'services/bastion_backdrop.dart';
import 'connection_doctor_page.dart';
import 'support_report_page.dart';
import 'services/bastion_error_log.dart';
import 'sentinel_page.dart';
import 'connect_link_prompt.dart';
import 'qr_scan_page.dart';
import 'services/bastion_link_intake.dart';
import 'services/bastion_sentinel.dart';
import 'sarneg/sarneg.dart';
import 'sarneg/sarneg_ui.dart';

part 'shell/nodes_page.dart';
part 'shell/chats_page.dart';
part 'shell/chat_thread_page.dart';
part 'shell/tools_page.dart';
part 'shell/settings_page.dart';
part 'shell/settings_cards.dart';
part 'shell/shell_labels.dart';
part 'shell/search_page.dart';
part 'shell/more_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep recent app errors in memory for the support report.
  BastionErrorLog.instance.install();
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(
      'licenses/meshtastic-protobufs-GPL-3.0.txt',
    );
    yield LicenseEntryWithLineBreaks(['Meshtastic protobufs'], text);
  });
  LicenseRegistry.addLicense(() async* {
    for (final (name, file) in [
      ('Inter', 'Inter-OFL.txt'),
      ('JetBrains Mono', 'JetBrainsMono-OFL.txt'),
    ]) {
      final text = await rootBundle.loadString('assets/fonts/$file');
      yield LicenseEntryWithLineBreaks([name], text);
    }
  });
  await BastionTileCache.initialize();
  await BastionPreferences.instance.load();
  await BastionBackdrop.instance.load();
  await BastionNodeLooks.instance.load();
  await BastionTrackLog.instance.load();
  await BastionMeshWatch.instance.load();
  // Chat history lives in its own database; older saves move over once.
  await BastionChatStorage.useSqlite();
  await BastionChatStorage.applySavedEncryption();
  await BastionFieldLog.instance.load();
  // Drives live in their own database; old coverage readings move over once.
  await BastionDriveLog.instance.load();
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
  static Color accentOf(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// The built-in look for [brightness] (BLACKOUT dark, Bare Beauty light).
  static ThemeData appearance(Brightness brightness) =>
      NotoryxTheme.build(brightness);

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

  // Rebuild when the app comes back, after the app lock check.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused)
      BastionAppLock.instance.onBackground();
    if (state == AppLifecycleState.resumed) {
      BastionAppLock.instance.onForeground();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: BastionPreferences.instance,
    builder: (context, _) {
      final platform =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      final theme = NotoryxTheme.fromPalette(
        BastionPreferences.instance.palette(platform),
      );
      return MaterialApp(
        title: 'NOTORYX Connect',
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.light,
        scrollBehavior: const BastionScrollBehavior(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) {
          // Services and notifications follow the phone's language too.
          BastionText.use(Localizations.localeOf(context));
          return BastionAppLockGate(
            lock: BastionAppLock.instance,
            child: child!,
          );
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
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (axisDirectionToAxis(details.direction) != Axis.vertical) return child;
    return Scrollbar(
      controller: details.controller,
      interactive: true,
      child: child,
    );
  }
}

class BastionShell extends StatefulWidget {
  const BastionShell({super.key});
  @override
  State<BastionShell> createState() => _BastionShellState();
}

class _BastionShellState extends State<BastionShell> {
  ShellTab tab = ShellTab.home;

  /// The side of More shown when it is next opened.
  ShellTab _moreSection = ShellTab.tools;
  final ble = MeshtasticBleDiscovery();

  /// A spot search asked the Map to centre on.
  final _mapFocus = ValueNotifier<({double lat, double lon})?>(null);

  void _openSearch() => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => AppSearchPage(
          radio: radio,
          discovery: ble,
          onShowPlace: (lat, lon) {
            _mapFocus.value = (lat: lat, lon: lon);
            _go(ShellTab.map);
          },
          onGoTab: _go,
        ),
      ));
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
      tab = ShellTab.home;
    });
    // Let the screens stop listening before the old demo radio goes away.
    if (old != null)
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    if (on) radio.configureBot(enabled: botMode, reply: awayReply);
  }

  bool botMode = false;
  String awayReply = MeshtasticMessagingService.defaultAwayReply;

  /// The bottom bar, in order: Home, Chats, Nodes, Map, More.
  List<String> _labels(BuildContext context) {
    final l = AppLocalizations.of(context);
    return [l.tabHome, l.tabChats, l.tabNodes, l.tabMap, l.tabMore];
  }

  static const icons = [
    Icons.shield_outlined,
    Icons.chat_bubble_outline,
    Icons.hub_outlined,
    Icons.map_outlined,
    Icons.more_horiz,
  ];

  static const _scenes = [NxScene.home, NxScene.chats, NxScene.nodes, NxScene.map, NxScene.more];

  /// The tab at bar position [i]; More opens on the side used last.
  ShellTab _atDestination(int i) => i == 4 ? _moreSection : ShellTab.values[i];

  /// Wider than this, the tabs move to a rail on the left.
  static const railBreakpoint = 600.0;

  void _go(ShellTab to) => setState(() {
        tab = to;
        if (to.isMore) _moreSection = to;
      });

  void _goDestination(int i) => _go(_atDestination(i));

  BastionHomeWidget? _homeWidget;
  final BastionLinkIntake _links = BastionLinkIntake();
  StreamSubscription<String>? _linkSub;
  TrackLogFeed? _trackFeed;
  MeshWatchFeed? _meshFeed;

  @override
  void initState() {
    super.initState();
    unawaited(_realRadio.prepareAlerts());
    // Connect links from a QR code, a web page or an NFC tag (Android).
    _linkSub = _links.links.listen((link) {
      if (!mounted) return;
      if (_inDemo) _setDemo(false);
      _go(ShellTab.nodes);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(handleConnectLink(context, _realRadio, link));
      });
    });
    unawaited(_links.start());
    // Pick up the radio from last time, e.g. after Android closed the app.
    unawaited(_realRadio.reconnectAtLaunch());
    // Automations act on the real radio only, never the demo.
    final automations = BastionAutomations.instance = AutomationEngine(
      hooks: coordinatorAutomationHooks(_realRadio),
    );
    unawaited(automations.load());
    automations.attach(CoordinatorAutomationSource(_realRadio));
    unawaited(SentinelService.instance.start());
    // The real radio only: demo nodes must never reach ATAK.
    BastionTakBridge.instance.attach(() => _realRadio.nodes);
    // The timeline records the real radio only, never the demo.
    BastionTimeline.instance.attach(CoordinatorTimelineSource(_realRadio));
    _trackFeed = TrackLogFeed(log: BastionTrackLog.instance, radio: _realRadio)..start();
    // Mesh activity records the real radio only, never the demo.
    BastionMeshWatch.instance.attach(_realRadio.traffic);
    _meshFeed = MeshWatchFeed(
      watch: BastionMeshWatch.instance,
      nodes: () => _realRadio.nodes,
      self: () => _realRadio.localNodeNum,
      ready: () => _realRadio.isReady,
    )..start();
    _realRadio.addListener(_meshFeed!.check);
    // The SOS relay listens to the real radio only, never the demo.
    final relay = BastionSosRelay.instance = BastionSosRelay(
      send: (text, channel) => _realRadio.sendText(text: text, channel: channel),
      radioRelaysItself: () => _realRadio.rebroadcasts,
      self: () => _realRadio.localNodeNum,
      nameOf: _realRadio.nodeName,
      onRelayed: (from, text) => unawaited(_realRadio.showLocalAlert(BastionFieldAlert(
        BastionAlertKind.sosRelayed,
        from,
        BastionText.l.srRelayedTitle,
        BastionText.l.srRelayedBody(_realRadio.nodeName(from)),
      ))),
    );
    unawaited(relay.load());
    _realRadio.onIncomingText = relay.onMessage;
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
    const tabs = {'home': ShellTab.home, 'nodes': ShellTab.nodes, 'chats': ShellTab.chats, 'map': ShellTab.map};
    try {
      const actions = QuickActions();
      actions.initialize((type) {
        final tab = tabs[type];
        if (tab != null && mounted) _go(tab);
      });
      actions
          .setShortcutItems(const [
            ShortcutItem(type: 'home', localizedTitle: 'Check in / SOS'),
            ShortcutItem(type: 'chats', localizedTitle: 'Chats'),
            ShortcutItem(type: 'nodes', localizedTitle: 'Nodes'),
            ShortcutItem(type: 'map', localizedTitle: 'Map'),
          ])
          .catchError((Object _) {});
    } catch (_) {
      // Shortcuts are a convenience; the app works without them.
    }
  }

  @override
  void dispose() {
    ble.dispose();
    _mapFocus.dispose();
    BastionAutomations.instance?.dispose();
    BastionAutomations.instance = null;
    _homeWidget?.dispose();
    BastionTakBridge.instance.detach();
    BastionTimeline.instance.detach();
    _trackFeed?.dispose();
    if (_meshFeed case final f?) {
      _realRadio.removeListener(f.check);
      f.dispose();
    }
    unawaited(_linkSub?.cancel());
    unawaited(_links.dispose());
    BastionMeshWatch.instance.detach();
    _realRadio.onIncomingText = null;
    BastionSosRelay.instance?.dispose();
    BastionSosRelay.instance = null;
    _realRadio.dispose();
    _demo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = PrimaryScrollController.none(
      child: IndexedStack(
        key: ValueKey(_inDemo),
        index: tab.destination,
        children: [
          HomePage(
            radio: radio,
            onConnect: () => _go(ShellTab.nodes),
            fieldTools: _homeTools(context),
            onTryDemo: _inDemo ? null : () => _setDemo(true),
          ),
          BastionChatsPage(
            radio: radio,
            visible: tab == ShellTab.chats,
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
          _NodesPage(
            discovery: ble,
            radio: radio,
            onOpenTools: () => _go(ShellTab.tools),
            onTryDemo: _inDemo ? null : () => _setDemo(true),
          ),
          MapPage(radio: radio, focus: _mapFocus),
          _MorePage(
            section: _moreSection,
            onSection: _go,
            tools: _ToolsPage(discovery: ble, radio: radio),
            settings: _SettingsPage(radio: radio, demo: _inDemo, onDemoChanged: _setDemo),
          ),
        ],
      ),
    );
    final wide = MediaQuery.sizeOf(context).width >= railBreakpoint;
    final scheme = Theme.of(context).colorScheme;
    // The glow sits behind the whole main screen; the bar and cards are
    // see-through so it carries into them.
    return NxBackdrop(
      scene: _scenes[tab.destination],
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: MediaQuery.textScalerOf(context).scale(36) + 20,
        titleSpacing: NxSpace.md,
        // NOTORYX Core's header: the app's mark and the radio it is talking to.
        title: AnimatedBuilder(
          animation: radio,
          builder: (context, _) {
            final me = radio.localNode;
            final name = radio.isReady && me != null ? me.displayName : 'NOTORYX Connect';
            return Row(children: [
              // The mark is decorative; the name below is what's announced.
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset('assets/images/notoryx_logo.png', width: 28, height: 28,
                      filterQuality: FilterQuality.medium),
                ),
              ),
              const SizedBox(width: NxSpace.sm),
              Flexible(
                child: Semantics(
                  label: 'NOTORYX Connect',
                  excludeSemantics: true,
                  child: Text(name,
                      key: const ValueKey('shell-title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: scheme.onSurface)),
                ),
              ),
            ]);
          },
        ),
        actions: [
          IconButton(
            key: const ValueKey('app-search'),
            tooltip: AppLocalizations.of(context).searchTooltip,
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
          ),
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
                  label: AppLocalizations.of(
                    context,
                  ).radioStatus(_connectionLabel(context, state)),
                  onTapHint: AppLocalizations.of(context).radioStatusHint,
                  onTap: () => _go(ShellTab.nodes),
                  excludeSemantics: true,
                  child: Tooltip(
                    message: AppLocalizations.of(
                      context,
                    ).radioStatusTip(_connectionLabel(context, state)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(NxRadius.pill),
                      onTap: () => _go(ShellTab.nodes),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: NxTouch.min,
                          minWidth: NxTouch.min,
                        ),
                        child: Center(
                          child: _MonoStatus(
                            // At large text the word would squeeze the title
                            // out; the dot's shape, the tooltip and the
                            // spoken label still say the state.
                            compact: MediaQuery.textScalerOf(context).scale(10) >= 15,
                            label: _connectionLabel(context, state),
                            tone: _connectionTone(state),
                            busy:
                                _connectionBusy(state) || radio.isReconnecting,
                          ),
                        ),
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
      body: SafeArea(
        child: Column(
          children: [
            if (_inDemo) _DemoBanner(onExit: () => _setDemo(false)),
            Expanded(
              child: wide
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: tab.destination,
                          onDestinationSelected: _goDestination,
                          destinations: [
                            for (final (i, label) in _labels(context).indexed)
                              NavigationRailDestination(
                                icon: _tabIcon(i),
                                label: Text(label),
                              ),
                          ],
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 840),
                              child: pages,
                            ),
                          ),
                        ),
                      ],
                    )
                  : pages,
            ),
          ],
        ),
      ),
      // The screen runs on under Core's floating glass bar.
      extendBody: !wide,
      bottomNavigationBar: wide
          ? null
          : NxFloatingBar(
              child: NavigationBar(
                selectedIndex: tab.destination,
                onDestinationSelected: (i) {
                  if (i != tab.destination) HapticFeedback.selectionClick();
                  _goDestination(i);
                },
                destinations: [
                  for (final (i, label) in _labels(context).indexed)
                    NavigationDestination(
                      icon: _tabIcon(i),
                      label: label,
                      tooltip: label,
                    ),
                ],
              ),
            ),
    ),
    );
  }

  void _push(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  /// Home's Field tools, colored as on NOTORYX Core.
  List<HomeTool> _homeTools(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return [
      (icon: Icons.query_stats, color: scheme.primary, title: l.maTitle, subtitle: l.maToolSub,
          onTap: () => _push(MeshActivityPage(watch: BastionMeshWatch.instance, nameOf: radio.nodeName))),
      (icon: Icons.route_outlined, color: scheme.tertiary, title: l.tlgTitle, subtitle: l.tlgToolSub,
          onTap: () => _push(TrackLogPage(log: BastionTrackLog.instance, share: MapPage.shareGpx, location: GeolocatorLocationSource()))),
      (icon: Icons.hiking, color: scheme.secondary, title: l.trlTitle, subtitle: l.trlToolSub,
          onTap: () => _push(TrailRoutingPage(
                store: BastionTrailStore.instance,
                whereAmI: radioOrPhonePosition(radio),
                share: MapPage.shareGpx,
                savedPlaces: waypointPlaces(radio),
              ))),
      (icon: Icons.medical_services_outlined, color: NxStatusColors.of(context).info, title: l.toolsDoctor, subtitle: l.toolsDoctorSub,
          onTap: () => _push(ConnectionDoctorPage(radio: radio, discovery: ble))),
    ];
  }

  /// A tab's icon; Chats carries a badge with the unread count.
  Widget _tabIcon(int i) => i != 1
      ? Icon(icons[i])
      : AnimatedBuilder(
          animation: radio,
          builder: (context, _) {
            final unread = tab == ShellTab.chats ? 0 : radio.unreadCount;
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
    final (bg, fg) = status.container(
      NxTone.info,
      Theme.of(context).colorScheme,
    );
    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        color: bg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NxSpace.md,
            NxSpace.xxs,
            NxSpace.xs,
            NxSpace.xxs,
          ),
          child: Row(
            children: [
              Icon(Icons.play_circle_outline, color: fg, size: 20),
              const SizedBox(width: NxSpace.xs),
              Expanded(
                child: Text(
                  'Demo mode: pretend radio and messages. Nothing is sent.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: fg),
                ),
              ),
              TextButton(
                onPressed: onExit,
                style: TextButton.styleFrom(foregroundColor: fg),
                child: const Text('Exit demo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The radio status as on NOTORYX Core: a dot and the state in the mono
/// face, quiet when offline and in the signal color when connected.
class _MonoStatus extends StatelessWidget {
  const _MonoStatus({required this.label, required this.tone, this.busy = false, this.compact = false});
  final String label;
  final NxTone tone;
  final bool busy;

  /// Dot only, no word.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = NxStatusColors.of(context).strong(tone, scheme);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NxSpace.xs),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (busy)
          SizedBox.square(dimension: 10, child: CircularProgressIndicator(strokeWidth: 1.6, color: color))
        else
          // Filled when connected, hollow otherwise: shape as well as color.
          Icon(tone == NxTone.success ? Icons.circle : Icons.circle_outlined, size: 10, color: color),
        if (!compact) ...[
        const SizedBox(width: 6),
        Text(label.toLowerCase(),
            style: TextStyle(
              fontFamily: NxFonts.mono,
              fontFamilyFallback: NxFonts.monoFallback,
              fontSize: 13,
              color: tone == NxTone.neutral ? scheme.onSurfaceVariant : color,
            )),
        ],
      ]),
    );
  }
}

