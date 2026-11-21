part of '../main.dart';

/// The Chats tab: one row per channel, then one per direct chat, newest
/// first. Tapping a row opens [ChatThreadPage].
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

  /// Whether the Chats tab is on screen.
  final bool visible;
  final bool botMode;
  final String awayReply;
  final ValueChanged<bool> onBotModeChanged;
  final ValueChanged<String> onAwayReplyChanged;

  @override
  State<BastionChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<BastionChatsPage> {
  late final TextEditingController reply = TextEditingController(text: widget.awayReply);
  final search = TextEditingController();
  bool _searching = false;

  AppLocalizations get l => AppLocalizations.of(context);
  MeshtasticRadioCoordinator get radio => widget.radio;

  final BastionScheduledMessages _scheduled = BastionScheduledMessages.instance;
  Timer? _scheduleTimer;

  @override
  void initState() {
    super.initState();
    // Lives as long as the app shell, so scheduled messages go out from any tab.
    _scheduleTimer = Timer.periodic(const Duration(seconds: 20), (_) => unawaited(_sendDue()));
  }

  Future<void> _sendDue() async {
    if (!radio.isReady) return;
    await _scheduled.flushDue(DateTime.now(), (m) async {
      await radio.sendText(text: m.text, destination: m.destination, channel: m.channel);
    });
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    reply.dispose();
    search.dispose();
    super.dispose();
  }

  void _open(BastionConversation c) => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ChatThreadPage(radio: radio, conversation: c),
      ));

  Future<void> _newChat() async {
    final target = await pickConversation(context, radio, title: l.chatsNewChat, everyNode: true);
    if (target != null && mounted) _open(target);
  }

  void _manageChannels() => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ChannelListPage(radio: radio),
      ));

  String _nodeName(int nodeNum) {
    for (final node in radio.nodes) {
      if (node.num == nodeNum) return node.displayName;
    }
    return '!${nodeNum.toRadixString(16).padLeft(8, '0')}';
  }

  /// "You: text", "Name: text" in a channel, or just the text in a direct chat.
  String _preview(BastionConversationSummary s) {
    final m = s.last;
    if (m == null) return l.chatsNoMessagesYet;
    if (m.direction == BastionMessageDirection.outgoing) return l.chatsYouPrefix(m.text);
    return s.conversation.isChannel ? '${_nodeName(m.from)}: ${m.text}' : m.text;
  }

  String _when(DateTime t, DateTime now) =>
      BastionChatDays.dayOf(t) == BastionChatDays.dayOf(now) ? _clock(t) : BastionChatDays.label(t, now);

  Widget _row(BuildContext context, BastionConversationSummary s, DateTime now) {
    final scheme = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final c = s.conversation;
    final title = conversationTitle(l, radio, c);
    final unread = s.unread > 0;
    final last = s.last;
    final failed = last != null &&
        last.direction == BastionMessageDirection.outgoing &&
        last.deliveryState == BastionDeliveryState.failed;
    return Semantics(
      button: true,
      label: [
        title,
        if (c.isChannel) conversationSubtitle(l, radio, c) else l.chatsDirectSub,
        if (unread) l.chatsUnread(s.unread),
        _preview(s),
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('conversation-${c.key}'),
        onTap: () => _open(c),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 76),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              if (c.isChannel)
                CircleAvatar(
                  radius: 24,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Text('${c.channel}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                )
              else
                NodeAvatar(num: c.node!, label: title, radius: 24),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (c.isChannel) Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Icon(Icons.tag, size: 18, color: scheme.onSurfaceVariant),
                  ),
                  Expanded(child: Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.titleMedium?.copyWith(fontWeight: unread ? FontWeight.w700 : FontWeight.w600))),
                  if (last != null)
                    Text(_when(last.timestamp, now),
                        style: type.labelMedium?.copyWith(color: unread ? scheme.primary : scheme.onSurfaceVariant)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  if (failed) Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Icon(Icons.error_outline, size: 16, color: scheme.error),
                  ),
                  Expanded(child: Text(_preview(s),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: type.bodyMedium?.copyWith(
                          color: unread ? scheme.onSurface : scheme.onSurfaceVariant,
                          fontWeight: unread ? FontWeight.w600 : null))),
                  if (unread)
                    Container(
                      margin: const EdgeInsetsDirectional.only(start: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(12)),
                      child: Text('${s.unread}', style: type.labelMedium?.copyWith(color: scheme.onPrimary, fontWeight: FontWeight.w700)),
                    ),
                ]),
              ])),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _searchResults(BuildContext context, List<BastionChatMessage> messages, DateTime now) {
    final matches = BastionMessageSearch.filter(messages, search.text, (m) => m.text).reversed.toList();
    if (matches.isEmpty) {
      return NxEmptyState(icon: Icons.search_off, title: l.chatsNoMatches, detail: l.chatsNoMatchesBody);
    }
    return Column(children: [
      for (final m in matches.take(100))
        ListTile(
          leading: Icon(m.isBroadcast ? Icons.tag : Icons.person_outline),
          title: Text(m.text),
          subtitle: Text('${conversationTitle(l, radio, BastionConversation.of(m))} • '
              '${m.direction == BastionMessageDirection.outgoing ? l.chatsYou : _nodeName(m.from)} • '
              '${_when(m.timestamp, now)}'),
          onTap: () => _open(BastionConversation.of(m)),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([radio, SentinelService.instance]),
        builder: (context, _) {
          final sentinel = SentinelService.instance;
          final messages = [for (final m in radio.messages) if (!m.isReaction && !sentinelHides(sentinel, m)) m];
          final now = DateTime.now();
          final connected = radio.isReady;
          final filters = radio.filters;
          final lists = BastionConversations.build(
            messages: messages,
            channelSlots: [for (final c in radio.channelMetadata) if (c.role != 0) c.index],
            unread: (key) => radio.chatMarks.unreadIn(messages, conversation: key),
          );
          final scheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
                child: Row(children: [
                  Expanded(child: Text(l.tabChats, style: Theme.of(context).textTheme.headlineSmall)),
                  IconButton(
                    key: const ValueKey('chats-search'),
                    tooltip: l.chatsSearch,
                    icon: Icon(_searching ? Icons.close : Icons.search),
                    onPressed: () => setState(() {
                      _searching = !_searching;
                      if (!_searching) search.clear();
                    }),
                  ),
                  IconButton(
                    key: const ValueKey('chats-manage-channels'),
                    tooltip: l.chatsManageChannels,
                    icon: const Icon(Icons.tune),
                    onPressed: _manageChannels,
                  ),
                  IconButton(
                    key: const ValueKey('chats-new'),
                    tooltip: l.chatsNewChat,
                    icon: const Icon(Icons.edit_square),
                    onPressed: _newChat,
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(connected ? l.chatsConnectedSub : l.chatsOfflineSub,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
              ),
              if (_searching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: search,
                    autofocus: true,
                    decoration: InputDecoration(labelText: l.chatsSearch, prefixIcon: const Icon(Icons.search)),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              if (radio.messageStorageProblem case final problem?)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: NxBanner(tone: NxTone.danger, icon: Icons.sd_card_alert_outlined,
                      title: l.chatsStorageProblem, message: problem),
                ),
              if (radio.filteredMessageCount > 0 || filters.showFiltered && filters.words.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: NxBanner(
                    icon: Icons.filter_alt_outlined,
                    message: filters.showFiltered ? l.chatsFilterShowing : l.chatsFilterHidden(radio.filteredMessageCount),
                    action: TextButton(
                      onPressed: () => filters.setShowFiltered(!filters.showFiltered),
                      child: Text(filters.showFiltered ? l.chatsHide : l.chatsShow),
                    ),
                  ),
                ),
              if (BastionPreferences.instance.statistics)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: NxStatRow(children: [
                    NxStatTile(label: l.chatsStatLink, value: connected ? l.chatsOnline : l.connOffline,
                        tone: connected ? NxTone.success : NxTone.neutral),
                    NxStatTile(label: l.chatsStatMessages, value: '${messages.length}'),
                    NxStatTile(label: l.chatsStatQueued, value: '${radio.pendingMessageCount}',
                        tone: radio.pendingMessageCount > 0 ? NxTone.warning : NxTone.neutral),
                  ]),
                ),
              if (_searching && search.text.trim().isNotEmpty)
                _searchResults(context, messages, now)
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: NxSectionLabel(l.chatsChannelsSection, trailing: TextButton(
                    onPressed: _manageChannels,
                    child: Text(l.chatsManageChannels),
                  )),
                ),
                if (lists.channels.isEmpty)
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: Text(l.chatsNoChannels),
                    onTap: _manageChannels,
                  ),
                for (final s in lists.channels) _row(context, s, now),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: NxSectionLabel(l.chatsDirectSection),
                ),
                if (lists.direct.isEmpty)
                  ListTile(
                    leading: const Icon(Icons.person_add_alt),
                    title: Text(l.chatsNoDirect),
                    subtitle: Text(l.chatsNoDirectHint),
                    onTap: _newChat,
                  ),
                for (final s in lists.direct) _row(context, s, now),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(child: Column(children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.smart_toy_outlined),
                    title: Text(l.chatsBot),
                    subtitle: Text(radio.botProblem ?? (widget.botMode ? l.chatsBotOn : l.chatsBotOff)),
                    value: widget.botMode,
                    onChanged: widget.onBotModeChanged,
                  ),
                  const Divider(indent: 56),
                  ExpansionTile(
                    leading: const Icon(Icons.edit_note),
                    title: Text(l.chatsBotReply),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      TextField(
                        controller: reply,
                        maxLines: 3,
                        maxLength: 160,
                        decoration: InputDecoration(labelText: l.chatsBotReplyField),
                        onChanged: widget.onAwayReplyChanged,
                      ),
                    ],
                  ),
                ])),
              ),
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

/// A labelled line across the timeline: a date, or where new messages start.
class _TimelineDivider extends StatelessWidget {
  const _TimelineDivider({required this.label, this.highlight = false});
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant;
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
              if (highlight) Icon(Icons.arrow_downward, size: 14, color: color),
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
