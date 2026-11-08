part of '../main.dart';

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
/// Opt-in: this phone carries MQTT for a radio without Wi-Fi.
class _MqttProxyCard extends StatelessWidget {
  const _MqttProxyCard({required this.radio});
  final MeshtasticRadioCoordinator radio;

  @override
  Widget build(BuildContext context) {
    final prefs = BastionPreferences.instance;
    final proxy = radio.mqttProxy;
    final hasConfig = radio.mqttProxyConfig != null;
    final status = !prefs.mqttProxy
        ? 'Off. Uses your phone\'s data when on.'
        : !radio.isReady
            ? 'On. Waits for your radio.'
            : !hasConfig
                ? 'Your radio isn\'t set to use this. Turn on MQTT and "Proxy to client" in its settings.'
                : switch (proxy.state) {
                    MqttProxyState.connected => 'Connected to ${proxy.host}. ${proxy.uplinked} sent, ${proxy.downlinked} received, about ${(proxy.bytesCarried / 1024).toStringAsFixed(1)} KB of data.',
                    MqttProxyState.connecting => 'Connecting to ${proxy.host}…',
                    MqttProxyState.error => proxy.error ?? 'Couldn\'t connect.',
                    MqttProxyState.off => 'Starting…',
                  };
    return Card(child: SwitchListTile(
      key: const ValueKey('mqtt-proxy-switch'),
      secondary: const Icon(Icons.cloud_sync_outlined),
      title: const Text('Carry MQTT through this phone'),
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
        SwitchListTile(
          key: const ValueKey('mesh-drop-switch'),
          title: const Text('Mesh goes quiet'),
          subtitle: const Text('Half or more of the nodes you were hearing stop being heard'),
          value: s.meshDrop,
          onChanged: (v) => _update(context, s.copyWith(meshDrop: v)),
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
