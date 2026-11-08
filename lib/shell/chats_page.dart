part of '../main.dart';

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
      child: Semantics(
        onLongPressHint: 'react to this message',
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
                    labelText: 'Message to send while Bot mode is on',
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
