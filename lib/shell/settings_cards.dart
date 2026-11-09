part of '../main.dart';

/// Message housekeeping and read-aloud.
class _MessagesCard extends StatelessWidget {
  const _MessagesCard();
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: BastionPreferences.instance,
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final p = BastionPreferences.instance;
      return Card(child: ExpansionTile(
        leading: const Icon(Icons.forum_outlined),
        title: Text(l.chatsStatMessages),
        subtitle: Text([
          p.channelRetentionDays == 0
              ? l.setChannelsKept
              : l.setChannelsDeleted(p.channelRetentionDays),
          l.setNewestPer(p.historyLimit >= 1000 ? '${p.historyLimit ~/ 1000},000' : '${p.historyLimit}'),
          if (p.readAloud) l.setReadOn,
        ].join(' • ')),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          DropdownButtonFormField<int>(
            initialValue: BastionPreferences.retentionChoices.contains(p.channelRetentionDays)
                ? p.channelRetentionDays : 0,
            decoration: InputDecoration(
              labelText: l.setDeleteOld,
              helperText: l.setDirectKept,
            ),
            items: [for (final d in BastionPreferences.retentionChoices)
              DropdownMenuItem(value: d, child: Text(d == 0 ? l.setNever : l.setAfterDays(d)))],
            onChanged: (d) => p.update(retentionDays: d),
          ),
          DropdownButtonFormField<int>(
            initialValue: p.historyLimit,
            decoration: InputDecoration(
              labelText: l.setHistory,
              helperText: l.setHistoryHelp,
              helperMaxLines: 2,
            ),
            items: [for (final n in BastionHistoryLimit.choices)
              DropdownMenuItem(value: n, child: Text(l.setKeepNewest(n >= 1000 ? '${n ~/ 1000},000' : '$n')))],
            onChanged: (n) => p.update(keepMessages: n),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.setReadAloud),
            subtitle: Text(l.setReadSub),
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
/// Opt-in: this phone carries MQTT for a radio without Wi-Fi.
class _MqttProxyCard extends StatelessWidget {
  const _MqttProxyCard({required this.radio});
  final MeshtasticRadioCoordinator radio;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final prefs = BastionPreferences.instance;
    final proxy = radio.mqttProxy;
    final hasConfig = radio.mqttProxyConfig != null;
    final status = !prefs.mqttProxy
        ? l.setMqttOff
        : !radio.isReady
            ? l.setMqttWait
            : !hasConfig
                ? l.setMqttNoConfig
                : switch (proxy.state) {
                    MqttProxyState.connected => l.setMqttConnected('${proxy.host}', proxy.uplinked, proxy.downlinked, (proxy.bytesCarried / 1024).toStringAsFixed(1)),
                    MqttProxyState.connecting => l.setMqttConnecting('${proxy.host}'),
                    MqttProxyState.error => proxy.error ?? l.setMqttFailed,
                    MqttProxyState.off => l.setMqttStarting,
                  };
    return Card(child: SwitchListTile(
      key: const ValueKey('mqtt-proxy-switch'),
      secondary: const Icon(Icons.cloud_sync_outlined),
      title: Text(l.setMqttTitle),
      subtitle: Text(status),
      value: prefs.mqttProxy,
      onChanged: (v) => prefs.update(proxyMqtt: v),
    ));
  }
}

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
    final l = AppLocalizations.of(context);
    final problem = widget.radio.backgroundProblem;
    return Card(child: ListTile(
      leading: Icon(problem != null || optimized ? Icons.warning_amber : Icons.check_circle_outline,
        color: problem != null || optimized ? Theme.of(context).colorScheme.error : BastionApp.accentOf(context)),
      title: Text(l.setBackground),
      subtitle: Text(problem ?? (optimized
          ? l.setBgOptimized
          : l.setBgAllowed)),
      isThreeLine: true,
      trailing: optimized ? TextButton(
        onPressed: BastionForegroundService.openBatterySettings,
        child: Text(l.setOpenSettings)) : null,
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
      final l = AppLocalizations.of(context);
      final bytes = snapshot.data;
      return ListTile(
        leading: const Icon(Icons.offline_pin_outlined),
        title: Text(l.setOfflineTiles),
        subtitle: Text('${bytes == null ? l.setSizeUnknown : l.setMbSaved((bytes / (1024 * 1024)).toStringAsFixed(1))}'
          '\n${l.setTilesHelp}'),
        isThreeLine: true,
        trailing: TextButton(
          onPressed: bytes == null || bytes == 0 ? null : () async {
            await BastionTileCache.clear();
            if (mounted) setState(() => _size = BastionTileCache.sizeBytes());
          },
          child: Text(l.setClear),
        ),
      );
    },
  ));
}

class _FieldAlertsCard extends StatelessWidget {
  const _FieldAlertsCard({required this.radio});
  final MeshtasticRadioCoordinator radio;

  Future<void> _update(BuildContext context, BastionAlertSettings settings) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await radio.setAlertSettings(settings)) {
      messenger.showSnackBar(SnackBar(
          content: Text(l.setAlertSaveFailed)));
    }
  }

  static String _duration(Duration d) =>
      d.inHours >= 1 ? '${d.inHours} h' : '${d.inMinutes} min';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = radio.alertSettings;
    return Card(child: ExpansionTile(
      leading: const Icon(Icons.notifications_active_outlined),
      title: Text(l.setAlerts),
      subtitle: Text(l.setAlertsSub),
      children: [
        SwitchListTile(
          title: Text(l.setLowBattery),
          subtitle: Text(l.setLowBatterySub(s.batteryThreshold)),
          value: s.lowBattery,
          onChanged: (v) => _update(context, s.copyWith(lowBattery: v)),
        ),
        ListTile(
          title: Text(l.setThreshold),
          enabled: s.lowBattery,
          trailing: DropdownButton<int>(
            value: s.batteryThreshold,
            items: [for (final v in BastionAlertSettings.batteryChoices)
              DropdownMenuItem(value: v, child: Text('$v%'))],
            onChanged: s.lowBattery ? (v) => _update(context, s.copyWith(batteryThreshold: v)) : null,
          ),
        ),
        SwitchListTile(
          title: Text(l.setNewNode),
          subtitle: Text(l.setNewNodeSub),
          value: s.newNode,
          onChanged: (v) => _update(context, s.copyWith(newNode: v)),
        ),
        SwitchListTile(
          title: Text(l.setFavQuiet),
          subtitle: Text(l.setFavQuietSub(_duration(s.silence))),
          value: s.favoriteSilent,
          onChanged: (v) => _update(context, s.copyWith(favoriteSilent: v)),
        ),
        SwitchListTile(
          key: const ValueKey('mesh-drop-switch'),
          title: Text(l.setMeshQuiet),
          subtitle: Text(l.setMeshQuietSub),
          value: s.meshDrop,
          onChanged: (v) => _update(context, s.copyWith(meshDrop: v)),
        ),
        ListTile(
          title: Text(l.setQuietAfter),
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

  AppLocalizations get l => AppLocalizations.of(context);

  bool get _canMove => widget.radio.isReady && widget.radio.localNodeNum != null && !_moving;

  void _load() => setState(() => _radios = widget.radio.storedRadios());

  Future<void> _move(StoredRadio from) async {
    final to = widget.radio.localNode?.displayName ?? l.setTheConnected;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.setMoveTitle(from.label)),
        content: Text(l.setMoveBody(to, from.id)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.setMove)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _moving = true; _result = null; });
    final problem = await widget.radio.moveRadioData(from.radio);
    if (!mounted) return;
    setState(() {
      _moving = false;
      _result = problem ?? l.setMoved(from.label, to);
    });
    _load();
  }

  @override
  Widget build(BuildContext context) => Card(child: ExpansionTile(
    leading: const Icon(Icons.sd_storage_outlined),
    title: Text(l.setRadioData),
    subtitle: Text(l.setRadioDataSub),
    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    onExpansionChanged: (open) { if (open) _load(); },
    children: [
      FutureBuilder<List<StoredRadio>>(
        future: _radios,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Text(l.setDataUnreadable);
          final radios = snapshot.data;
          if (radios == null) return const LinearProgressIndicator();
          if (radios.isEmpty) return Text(l.setNoData);
          return Column(children: [
            for (final r in radios)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r.label),
                subtitle: Text(l.setDataCounts(r.messages, r.nodes, r.trails)),
                trailing: r.radio == widget.radio.localNodeNum
                    ? Text(l.connConnected)
                    : TextButton(
                        onPressed: _canMove ? () => _move(r) : null,
                        child: Text(l.setMoveToConnected),
                      ),
              ),
          ]);
        },
      ),
      if (!widget.radio.isReady)
        Text(l.setConnectNew),
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
    final l = AppLocalizations.of(context);
    final f = widget.radio.filters;
    return Card(child: ExpansionTile(
      leading: const Icon(Icons.filter_alt_outlined),
      title: Text(l.setFilters),
      subtitle: Text(l.setFilterCounts(f.ignored.length, f.muted.length, f.words.length)),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        Align(alignment: AlignmentDirectional.centerStart, child: Text(l.setFilteredWords,
            style: Theme.of(context).textTheme.titleSmall)),
        Text(l.setFilterHelp),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextField(
            controller: _word,
            decoration: InputDecoration(labelText: l.setWordField, errorText: _error),
            onSubmitted: (_) => _add(),
          )),
          IconButton(tooltip: l.setAddWord, icon: const Icon(Icons.add), onPressed: _add),
        ]),
        Wrap(spacing: 8, children: [
          for (final w in f.words)
            InputChip(label: Text(w), onDeleted: () => f.removeWord(w), deleteButtonTooltipMessage: l.setRemoveWord(w)),
        ]),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l.setShowFiltered),
          value: f.showFiltered,
          onChanged: f.setShowFiltered,
        ),
        const Divider(),
        Align(alignment: AlignmentDirectional.centerStart, child: Text(l.setIgnoredMuted,
            style: Theme.of(context).textTheme.titleSmall)),
        if (f.ignored.isEmpty && f.muted.isEmpty)
          ListTile(contentPadding: EdgeInsets.zero,
              title: Text(l.setNoneIgnored)),
        for (final n in f.ignored)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.block),
            title: Text(_name(n)),
            subtitle: Text(l.setIgnored),
            trailing: TextButton(onPressed: () => f.setIgnored(n, false), child: Text(l.setUnignore)),
          ),
        for (final n in f.muted)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_off_outlined),
            title: Text(_name(n)),
            subtitle: Text(l.setMuted),
            trailing: TextButton(onPressed: () => f.setMuted(n, false), child: Text(l.setUnmute)),
          ),
        if (f.problem != null) Text(f.problem!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ],
    ));
  }
}
