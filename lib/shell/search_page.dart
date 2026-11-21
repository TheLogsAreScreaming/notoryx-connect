part of '../main.dart';

/// One search over everything on this phone: nodes, messages, channels,
/// places and the app's own pages. Tapping a result goes straight there.
class AppSearchPage extends StatefulWidget {
  const AppSearchPage({
    super.key,
    required this.radio,
    required this.discovery,
    required this.onShowPlace,
    required this.onGoTab,
  });

  final MeshtasticRadioCoordinator radio;
  final MeshtasticBleDiscovery discovery;

  /// Closes search, switches to the Map and centres it on the spot.
  final void Function(double lat, double lon) onShowPlace;

  /// Closes search and switches to a tab.
  final void Function(ShellTab tab) onGoTab;

  @override
  State<AppSearchPage> createState() => _AppSearchPageState();
}

/// A page the app can open from search. [tab] is used when it has no page
/// of its own (it lives on a tab).
class _Feature {
  const _Feature(this.info, {this.page, this.tab, this.icon = Icons.tune});
  final SearchFeature info;
  final Widget Function()? page;
  final ShellTab? tab;
  final IconData icon;
}

class _AppSearchPageState extends State<AppSearchPage> {
  final _query = TextEditingController();
  AppSearchResults _results = const AppSearchResults();
  List<_Feature> _features = const [];

  MeshtasticRadioCoordinator get radio => widget.radio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _features = _buildFeatures(AppLocalizations.of(context));
    _run();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<_Feature> _buildFeatures(AppLocalizations l) {
    _Feature f(String id, String title, String sub, {Widget Function()? page, ShellTab? tab, IconData icon = Icons.tune, String keywords = ''}) =>
        _Feature(SearchFeature(id: id, title: title, subtitle: sub, keywords: keywords), page: page, tab: tab, icon: icon);
    return [
      f('radio-settings', l.setChange, l.setChangeSub, icon: Icons.edit_outlined,
          page: () => RadioSettingsPage(radio: radio)),
      f('channels', l.setChannels, l.chWhoCanRead, icon: Icons.tag,
          page: () => ChannelListPage(radio: radio)),
      f('location', l.setShareLoc, l.setPrecisionSub, icon: Icons.my_location, tab: ShellTab.settings),
      f('radio-backup', l.setRadioBackup, l.setRadioBackupSub, icon: Icons.enhanced_encryption_outlined,
          page: () => RadioBackupPage(radio: radio)),
      f('phone-backup', l.setPhoneBackup, l.setPhoneBackupSub, icon: Icons.phone_android_outlined,
          page: () => PhoneBackupPage(radio: radio)),
      f('import-nodes', l.setImportNodes, l.setImportNodesSub, icon: Icons.group_add_outlined,
          page: () => NodeDbImportPage(radio: radio)),
      f('privacy', l.setPrivacy, l.setPrivacySub, icon: Icons.privacy_tip_outlined,
          page: () => PrivacyPage(radio: radio)),
      f('demo', l.setDemo, l.setDemoSub, icon: Icons.play_circle_outline, tab: ShellTab.settings),
      f('doctor', l.toolsDoctor, l.toolsDoctorSub, icon: Icons.medical_services_outlined,
          page: () => ConnectionDoctorPage(radio: radio, discovery: widget.discovery)),
      f('track-log', l.tlgTitle, l.tlgToolSub, icon: Icons.route_outlined, keywords: 'gpx',
          page: () => TrackLogPage(log: BastionTrackLog.instance, share: MapPage.shareGpx, location: GeolocatorLocationSource())),
      f('battery-watch', l.bwTitle, l.bwToolSub, icon: Icons.battery_alert_outlined,
          page: () => BatteryWatchPage(radio: radio)),
      f('team-setup', l.teamTitle, l.teamToolSub, icon: Icons.groups_outlined, keywords: 'qr',
          page: () => TeamSharePage(radio: radio)),
      f('mesh-activity', l.maTitle, l.maToolSub, icon: Icons.query_stats, keywords: 'packet log rx',
          page: () => MeshActivityPage(watch: BastionMeshWatch.instance, nameOf: radio.nodeName)),
      f('field-guide', l.gdTitle, l.gdToolSub, icon: Icons.menu_book_outlined,
          page: () => const FieldGuidePage()),
      f('background', l.bgTitle, l.bgHint, icon: Icons.wallpaper_outlined,
          page: () => const BackdropPage()),
      f('timeline', l.tlTitle, l.tlToolSub, icon: Icons.timeline,
          page: () => TimelinePage(radio: radio, timeline: BastionTimeline.instance)),
      f('checklists', l.clTitle, l.clToolSub, icon: Icons.checklist,
          page: () => ChecklistsPage(store: BastionChecklists.instance)),
      f('health', l.toolsHealth, l.toolsHealthSub, icon: Icons.monitor_heart_outlined,
          page: () => MeshHealthPage(radio: radio)),
      f('link', l.toolsLink, l.toolsLinkSub, icon: Icons.landscape_outlined,
          page: () => LinkPlannerPage(radio: radio)),
      f('range', l.toolsRange, l.toolsRangeSub, icon: Icons.social_distance,
          page: () => MeshToolsPage(radio: radio)),
      f('traceroute', l.toolsTraceroute, l.toolsTraceroute, icon: Icons.route,
          page: () => TraceroutePage(radio: radio)),
      f('store-forward', l.toolsStore, l.toolsStoreSub, icon: Icons.inbox_outlined,
          page: () => MeshToolsPage(radio: radio, initialTab: 1)),
      f('beacons', l.toolsBeacons, l.toolsBeacons, icon: Icons.campaign_outlined,
          page: () => BeaconPage(radio: radio)),
      f('journal', l.njTitle, l.njToolSub, icon: Icons.menu_book_outlined,
          page: () => NodeJournalPage(journal: radio.nodeJournal)),
      f('field-records', l.toolsIncident, l.toolsIncidentSub, icon: Icons.assignment_outlined,
          page: () => FieldToolsPage(radio: radio)),
      f('tak', l.takTitle, l.toolsTakSub, icon: Icons.share_location_outlined,
          page: () => TakBridgePage(bridge: BastionTakBridge.instance)),
    ];
  }

  void _run() {
    final l = AppLocalizations.of(context);
    setState(() {
      _results = BastionAppSearch.run(
        _query.text,
        nodes: radio.nodes,
        remembered: radio.nodeVault,
        messages: radio.messages,
        channels: [
          for (final c in radio.channelMetadata)
            if (c.role != 0)
              SearchChannel(c.index, conversationTitle(l, radio, BastionConversation.channel(c.index))),
        ],
        places: radio.waypoints,
        features: [for (final f in _features) f.info],
      );
    });
  }

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  void _openFeature(SearchFeature info) {
    final feature = _features.firstWhere((f) => f.info.id == info.id);
    if (feature.page case final page?) {
      _push(page());
    } else if (feature.tab case final tab?) {
      Navigator.of(context).pop();
      widget.onGoTab(tab);
    }
  }

  String _when(BuildContext context, DateTime t) {
    final m = MaterialLocalizations.of(context);
    final local = t.toLocal();
    return '${m.formatShortMonthDay(local)} ${m.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final r = _results;
    final typed = _query.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          key: const ValueKey('app-search-field'),
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l.searchHint,
            border: InputBorder.none,
          ),
          onChanged: (_) => _run(),
        ),
        actions: [
          if (typed)
            IconButton(
              tooltip: l.searchClear,
              icon: const Icon(Icons.close),
              onPressed: () {
                _query.clear();
                _run();
              },
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: !typed
            ? ListView(padding: NxSpace.page, children: [Text(l.searchStart)])
            : r.isEmpty
                ? ListView(padding: NxSpace.page, children: [
                    Semantics(liveRegion: true, child: Text(l.searchNone(_query.text.trim()))),
                  ])
                : ListView(
                    padding: NxSpace.page,
                    children: [
                      if (r.nodes.isNotEmpty) ...[
                        NxSectionLabel(l.searchNodes),
                        for (final n in r.nodes)
                          ListTile(
                            leading: const Icon(Icons.router_outlined),
                            title: Text(n.name),
                            subtitle: Text([
                              n.id,
                              if (n.shortName != null) n.shortName!,
                              if (n.remembered) l.searchRemembered,
                            ].join(' • ')),
                            onTap: () => _push(NodeDetailPage(radio: radio, nodeNum: n.num)),
                          ),
                      ],
                      if (r.channels.isNotEmpty) ...[
                        NxSectionLabel(l.searchChannels),
                        for (final c in r.channels)
                          ListTile(
                            leading: const Icon(Icons.tag),
                            title: Text(c.name),
                            onTap: () => _push(ChatThreadPage(
                                radio: radio, conversation: BastionConversation.channel(c.index))),
                          ),
                      ],
                      if (r.messages.isNotEmpty) ...[
                        NxSectionLabel(l.searchMessages),
                        for (final m in r.messages)
                          ListTile(
                            leading: Icon(m.conversation.isChannel
                                ? Icons.forum_outlined
                                : Icons.chat_bubble_outline),
                            title: Text(m.message.text),
                            subtitle: Text(
                                '${conversationTitle(l, radio, m.conversation)} • ${_when(context, m.message.timestamp)}'),
                            onTap: () => _push(ChatThreadPage(radio: radio, conversation: m.conversation)),
                          ),
                      ],
                      if (r.places.isNotEmpty) ...[
                        NxSectionLabel(l.searchPlaces),
                        for (final p in r.places)
                          ListTile(
                            leading: const Icon(Icons.place_outlined),
                            title: Text(p.name),
                            subtitle: p.description.isEmpty ? null : Text(p.description),
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onShowPlace(p.latitude, p.longitude);
                            },
                          ),
                      ],
                      if (r.features.isNotEmpty) ...[
                        NxSectionLabel(l.searchFeatures),
                        for (final f in r.features)
                          ListTile(
                            leading: Icon(_features.firstWhere((x) => x.info.id == f.id).icon),
                            title: Text(f.title),
                            subtitle: Text(f.subtitle),
                            onTap: () => _openFeature(f),
                          ),
                      ],
                    ],
                  ),
      ),
    );
  }
}
