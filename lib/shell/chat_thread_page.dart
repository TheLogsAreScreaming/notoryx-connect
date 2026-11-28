part of '../main.dart';

/// One chat: a channel or a direct conversation, newest message at the
/// bottom and the message box pinned under it.
class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({super.key, required this.radio, required this.conversation, this.initialText});

  final MeshtasticRadioCoordinator radio;
  final BastionConversation conversation;

  /// Text to put in the message box, for example a forwarded message.
  final String? initialText;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  final composer = TextEditingController();
  final BastionScheduledMessages _scheduled = BastionScheduledMessages.instance;

  /// Messages after this were new when the chat was opened. Kept while it is
  /// open so the "new messages" divider doesn't vanish as you read.
  DateTime? _unreadSince;
  bool _showPins = false;

  /// The message the user is replying to, set by swiping a bubble.
  BastionChatMessage? _replyingTo;

  /// The message list; newest at offset 0, since the list runs upwards.
  final _scroll = ScrollController();

  /// Whether the list is scrolled back far enough to offer a jump to the
  /// newest message.
  final _awayFromLatest = ValueNotifier(false);

  /// How far back (logical pixels) before the jump button shows.
  static const jumpAfter = 400.0;

  void _onScroll() {
    if (!_scroll.hasClients) return;
    _awayFromLatest.value = _scroll.offset > jumpAfter;
  }

  void _jumpToLatest() {
    if (!_scroll.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(0);
    } else {
      unawaited(_scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut));
    }
  }

  AppLocalizations get l => AppLocalizations.of(context);
  BastionConversation get conversation => widget.conversation;
  MeshtasticRadioCoordinator get radio => widget.radio;

  static const _draftsKey = 'bastion.drafts.v1';

  @override
  void initState() {
    super.initState();
    _unreadSince = radio.chatMarks.readSince(conversation.key);
    if (widget.initialText case final text?) {
      composer.text = text;
    } else {
      unawaited(_loadDraft());
    }
    unawaited(radio.markConversationRead(conversation.key));
    radio.addListener(_markReadWhileOpen);
    _scroll.addListener(_onScroll);
  }

  /// New messages in an open chat count as read.
  void _markReadWhileOpen() {
    if (!mounted) return;
    if (radio.chatMarks.unreadIn(radio.messages, conversation: conversation.key) > 0) {
      unawaited(radio.markConversationRead(conversation.key));
    }
  }

  @override
  void dispose() {
    radio.removeListener(_markReadWhileOpen);
    _saveDraft();
    composer.dispose();
    _scroll.dispose();
    _awayFromLatest.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _readDrafts() async {
    try {
      final raw = await SharedPreferencesAsync().getString(_draftsKey);
      if (raw == null) return {};
      return (jsonDecode(raw) as Map).cast<String, String>();
    } catch (_) {
      // Drafts are a convenience; a damaged store is ignored.
      return {};
    }
  }

  Future<void> _loadDraft() async {
    final drafts = await _readDrafts();
    if (!mounted || composer.text.isNotEmpty) return;
    composer.text = drafts[conversation.key] ?? '';
  }

  void _saveDraft() {
    final key = conversation.key;
    final text = composer.text;
    unawaited(() async {
      try {
        final drafts = await _readDrafts();
        if (text.trim().isEmpty) {
          drafts.remove(key);
        } else {
          drafts[key] = text;
        }
        await SharedPreferencesAsync().setString(_draftsKey, jsonEncode(drafts));
      } catch (_) {
        // Drafts are a convenience; storage may be unavailable.
      }
    }());
  }

  String _nodeName(int nodeNum) {
    for (final node in radio.nodes) {
      if (node.num == nodeNum) return node.displayName;
    }
    return '!${nodeNum.toRadixString(16).padLeft(8, '0')}';
  }

  Future<void> _send([String? quickText]) async {
    final text = (quickText ?? composer.text).trim();
    if (text.isEmpty) return;
    final replyId = _replyingTo?.packetId;
    try {
      await radio.sendText(
        text: text,
        destination: conversation.destination,
        channel: conversation.channel,
        replyId: replyId,
      );
      if (quickText == null) {
        composer.clear();
        _saveDraft();
      }
      if (replyId != null) setState(() => _replyingTo = null);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.chatsSendFailed('$error'))));
      }
    }
  }

  /// Saves the message box text to send at a time the user picks.
  Future<void> _schedule() async {
    final text = composer.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.chatsScheduleTypeFirst)));
      return;
    }
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 8);
    final choice = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (sheet) => SafeArea(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: Text(l.chatsSchedule, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(l.chatsScheduleNote)),
        for (final (label, at) in [
          (l.chatsSchedule15, now.add(const Duration(minutes: 15))),
          (l.chatsSchedule60, now.add(const Duration(hours: 1))),
          (l.chatsSchedule240, now.add(const Duration(hours: 4))),
          (l.chatsScheduleTomorrow, tomorrow),
        ])
          ListTile(leading: const Icon(Icons.schedule), title: Text(label), onTap: () => Navigator.pop(sheet, at)),
        ListTile(
          leading: const Icon(Icons.calendar_month),
          title: Text(l.chatsSchedulePick),
          onTap: () async {
            final navigator = Navigator.of(sheet);
            final date = await showDatePicker(context: sheet, firstDate: now, lastDate: now.add(const Duration(days: 30)), initialDate: now);
            if (date == null || !sheet.mounted) return;
            final time = await showTimePicker(context: sheet, initialTime: TimeOfDay.fromDateTime(now));
            if (time == null) return;
            navigator.pop(DateTime(date.year, date.month, date.day, time.hour, time.minute));
          },
        ),
      ]))),
    );
    if (choice == null || !mounted) return;
    final saved = await _scheduled.add(
        text: text, destination: conversation.destination, channel: conversation.channel, dueAt: choice);
    if (!mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.chatsScheduleFull(BastionScheduledMessages.maxItems))));
      return;
    }
    composer.clear();
    _saveDraft();
  }

  /// Inserts "@name " for a node you pick, at the cursor.
  Future<void> _mention() async {
    final nodes = [for (final n in radio.nodes) if (n.num != radio.localNodeNum) n];
    final name = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(child: nodes.isEmpty
          ? Padding(padding: const EdgeInsets.all(24), child: Text(l.chatsNoMention))
          : ListView(shrinkWrap: true, children: [
              ListTile(title: Text(l.chatsMentionNode, style: const TextStyle(fontWeight: FontWeight.bold))),
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

  /// Opens another chat in place of this one.
  void _open(BastionConversation target, {String? text}) {
    if (target == conversation && text == null) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => ChatThreadPage(radio: radio, conversation: target, initialText: text),
    ));
  }

  /// Lets you jump to any other chat without going back to the list.
  Future<void> _switchChat() async {
    final target = await pickConversation(context, radio, title: l.chatsSwitch, current: conversation);
    if (target != null && mounted) _open(target);
  }

  /// Picks a chat and puts the message in its box for review.
  Future<void> _forward(BastionChatMessage message) async {
    final target = await pickConversation(context, radio, title: l.chatsForwardTo, everyNode: true);
    if (target == null || !mounted) return;
    final from = message.direction == BastionMessageDirection.outgoing ? null : _nodeName(message.from);
    // Sent on air exactly as written, so this stays English.
    final text = from == null ? 'Fwd: ${message.text}' : 'Fwd from $from: ${message.text}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.chatsForwardReview)));
    _open(target, text: text);
  }

  Future<void> _togglePin(BastionChatMessage message) async {
    final problem = await radio.togglePin(message);
    if (problem != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
    }
  }

  static const _pinAction = '\u0000pin';
  static const _copyAction = '\u0000copy';
  static const _sendHeldAction = '\u0000sendHeld';
  static const _deleteQueuedAction = '\u0000deleteQueued';
  static const _forwardAction = '\u0000forward';
  static const _reportAction = '\u0000report';
  static const _replyAction = '\u0000reply';
  static const _reactionChoices = ['👍', '❤️', '😂', '😮', '😢', '✅', '🙏'];

  /// The delivery state, plus what the radio said about the receipt.
  String _receiptLabel(BuildContext context, BastionChatMessage m) {
    final base = _deliveryLabel(context, m.deliveryState);
    if (m.deliveryState != BastionDeliveryState.delivered && m.ackProof != BastionAckProof.forged) {
      return base;
    }
    return switch (m.ackProof) {
      BastionAckProof.proven => l.deliveryProven,
      BastionAckProof.noKey => l.deliveryNoKey,
      BastionAckProof.unproven => l.deliveryUnproven,
      BastionAckProof.forged => '$base • ${l.deliveryForged}',
      null => base,
    };
  }

  /// How an incoming message got here: over the internet, directly, or
  /// through relays, naming the last relay when it can be worked out.
  String _pathSummary(BastionChatMessage m) {
    if (m.replayed) {
      final got = m.receivedAt;
      return got == null ? l.chatsReplayedFull : '${l.chatsReplayedFull} ${l.chatsReplayedAt(_clock(got))}';
    }
    if (m.viaMqtt) return l.chatsViaMqttFull;
    final hops = m.hops;
    if (hops == null) return l.chatsPathUnknown;
    if (hops == 0) return l.chatsHeardDirect;
    final relay = m.relayNode;
    final candidates = relay == null
        ? const <String>[]
        : [for (final n in radio.nodes) if ((n.num & 0xff) == relay && n.num != m.from) n.displayName];
    final via = candidates.length == 1
        ? l.chatsLastThrough(candidates.single)
        : relay == null
            ? ''
            : l.chatsLastThroughEnding(relay.toRadixString(16).padLeft(2, '0'));
    return l.chatsCameThrough(hops, via);
  }

  Future<void> _actions(BastionChatMessage message) async {
    final pinned = radio.chatMarks.isPinned(message);
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(child: SingleChildScrollView(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l.chatsReact, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 4, children: [
            for (final e in _reactionChoices)
              IconButton(
                tooltip: l.chatsReactEmoji(e),
                onPressed: () => Navigator.pop(context, e),
                icon: Text(e, style: const TextStyle(fontSize: 28)),
              ),
          ]),
          const Divider(),
          if (message.direction == BastionMessageDirection.incoming && (message.signed || message.pkiEncrypted))
            ListTile(
              key: const ValueKey('chat-security'),
              leading: const Icon(Icons.verified_user_outlined),
              title: Text([
                if (message.pkiEncrypted) l.chatsPkiEncrypted,
                if (message.signed) l.chatsSigned,
              ].join(' • ')),
            ),
          if (message.deliveryState == BastionDeliveryState.held) ...[
            ListTile(
              key: const ValueKey('chat-held-explain'),
              leading: const Icon(Icons.pause_circle_outline),
              title: Text(l.chatsHeldExplain),
            ),
            ListTile(
              key: const ValueKey('chat-send-held'),
              leading: const Icon(Icons.send),
              title: Text(l.chatsSendHeld),
              onTap: () => Navigator.pop(context, _sendHeldAction),
            ),
          ],
          if (message.deliveryState == BastionDeliveryState.held || message.deliveryState == BastionDeliveryState.queued)
            ListTile(
              key: const ValueKey('chat-delete-queued'),
              leading: const Icon(Icons.delete_outline),
              title: Text(l.chatsDeleteQueued),
              onTap: () => Navigator.pop(context, _deleteQueuedAction),
            ),
          if (message.direction == BastionMessageDirection.incoming)
            ListTile(
              leading: const Icon(Icons.alt_route),
              title: Text(_pathSummary(message)),
              subtitle: Text([
                if (message.rxSnr != null) 'SNR ${message.rxSnr!.toStringAsFixed(1)} dB',
                if (message.rxRssi != null) 'RSSI ${message.rxRssi} dBm',
                if (message.rxSnr == null && message.rxRssi == null) l.chatsNoSignal,
              ].join(' • ')),
            ),
          if (!message.isReaction)
            ListTile(
              leading: const Icon(Icons.reply),
              title: Text(l.chatsReply),
              onTap: () => Navigator.pop(context, _replyAction),
            ),
          ListTile(
            leading: Icon(pinned ? Icons.push_pin_outlined : Icons.push_pin),
            title: Text(pinned ? l.chatsUnpin : l.chatsPin),
            onTap: () => Navigator.pop(context, _pinAction),
          ),
          ListTile(
            leading: const Icon(Icons.copy),
            title: Text(l.chatsCopyText),
            onTap: () => Navigator.pop(context, _copyAction),
          ),
          ListTile(
            leading: const Icon(Icons.forward),
            title: Text(l.chatsForward),
            onTap: () => Navigator.pop(context, _forwardAction),
          ),
          if (message.direction == BastionMessageDirection.incoming)
            ListTile(
              key: const ValueKey('chat-sentinel-report'),
              leading: const Icon(Icons.flag_outlined),
              title: Text(l.sntReport),
              onTap: () => Navigator.pop(context, _reportAction),
            ),
        ]),
      ))),
    );
    if (choice == null || !mounted) return;
    if (choice == _sendHeldAction) return radio.sendHeld(message.packetId);
    if (choice == _deleteQueuedAction) return radio.deleteQueued(message.packetId);
    if (choice == _pinAction) return _togglePin(message);
    if (choice == _replyAction) { setState(() => _replyingTo = message); return; }
    if (choice == _forwardAction) return _forward(message);
    if (choice == _reportAction) {
      return showSentinelReportSheet(context,
          nodeNum: message.from, nodeName: _nodeName(message.from), messageExcerpt: message.text);
    }
    if (choice == _copyAction) {
      await Clipboard.setData(ClipboardData(text: message.text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.chatsCopied)));
      return;
    }
    try {
      await radio.sendReaction(message, choice);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error is StateError ? error.message : l.chatsReactionFailed('$error'))));
      }
    }
  }

  /// Oldest-first rows: a date divider at each new day, and a divider above
  /// the first message that arrived since the chat was last opened.
  List<_TimelineRow> _rows(List<BastionChatMessage> oldestFirst, DateTime now) {
    final since = _unreadSince;
    final rows = <_TimelineRow>[];
    DateTime? day;
    var placedNew = false;
    for (final m in oldestFirst) {
      final d = BastionChatDays.dayOf(m.timestamp);
      if (d != day) {
        rows.add(_DayRow(BastionChatDays.label(m.timestamp, now)));
        day = d;
      }
      if (!placedNew && since != null && BastionChatMarks.isUnread(m, since)) {
        rows.add(const _NewRow());
        placedNew = true;
      }
      rows.add(_MessageRow(m));
    }
    return rows;
  }

  /// Wraps a bubble widget with a horizontal swipe gesture that sets it as
  /// the message being replied to. Swiping right on incoming messages and
  /// left on outgoing matches the natural "reply" gesture on most chat apps.
  Widget _swipeable(BuildContext context, BastionChatMessage message, Widget child) {
    if (message.isReaction) return child;
    final outgoing = message.direction == BastionMessageDirection.outgoing;
    return Dismissible(
      key: ValueKey('swipe-reply-${message.packetId}'),
      direction: outgoing ? DismissDirection.endToStart : DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        setState(() => _replyingTo = message);
        return false; // never actually dismiss the item
      },
      background: Align(
        alignment: outgoing ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.reply, color: Theme.of(context).colorScheme.primary),
        ),
      ),
      child: child,
    );
  }

  Widget _bubble(BuildContext context, BastionChatMessage message, List<BastionChatMessage>? reactions) {
    final scheme = Theme.of(context).colorScheme;
    final type = Theme.of(context).textTheme;
    final outgoing = message.direction == BastionMessageDirection.outgoing;
    final mentioned = !outgoing && radio.mentionsMe(message.text);
    final pinned = radio.chatMarks.isPinned(message);
    final failed = message.deliveryState == BastionDeliveryState.failed;
    final statusColor = failed
        ? scheme.error
        : message.deliveryState == BastionDeliveryState.delivered
            ? NxStatusColors.of(context).success
            : scheme.onSurfaceVariant;
    final background = mentioned
        ? scheme.primaryContainer
        : outgoing
            ? scheme.secondaryContainer
            : scheme.surfaceContainerHigh;
    final foreground = mentioned
        ? scheme.onPrimaryContainer
        : outgoing
            ? scheme.onSecondaryContainer
            : scheme.onSurface;
    final meta = [
      _clock(message.timestamp),
      if (message.replayed) l.chatsReplayed
      else if (message.viaMqtt) l.chatsViaMqtt
      else if (!outgoing)
        if (_hopsLabel(context, message.hops) case final hops?) hops,
    ].join(' • ');
    return Align(
      alignment: outgoing ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Material(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(16),
                topEnd: const Radius.circular(16),
                bottomStart: Radius.circular(outgoing ? 16 : 4),
                bottomEnd: Radius.circular(outgoing ? 4 : 16),
              ),
              side: mentioned ? BorderSide(color: scheme.primary, width: 1.5) : BorderSide.none,
            ),
            child: Semantics(
              onTapHint: l.chatsReactHint,
              onLongPressHint: l.chatsReactHint,
              child: InkWell(
                key: ValueKey('bubble-${message.from}-${message.packetId}'),
                borderRadius: BorderRadius.circular(16),
                // A plain tap works too, for anyone who can't long-press.
                onTap: () => _actions(message),
                onLongPress: () => _actions(message),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (!outgoing && conversation.isChannel)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(child: Text(_nodeName(message.from),
                            style: type.labelLarge?.copyWith(color: mentioned ? foreground : scheme.primary))),
                        SentinelFlag(message.from),
                      ]),
                    Text(message.text, style: type.bodyLarge?.copyWith(color: foreground)),
                    if (isSarnegMessage(message.text))
                      SarnegDecodeLine(text: message.text, at: message.timestamp, color: foreground),
                    if (BastionPreferences.instance.linkPreviews)
                      if (BastionLinkPreviews.firstLink(message.text) case final link?)
                        _LinkPreviewCard(link: link, foreground: foreground),
                    if (mentioned)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.alternate_email, size: 14, color: foreground),
                          const SizedBox(width: 4),
                          Text(l.chatsMentionsYou, style: type.labelMedium?.copyWith(color: foreground)),
                        ]),
                      ),
                    if (reactions != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Semantics(
                          label: l.chatsReactions([
                            for (final r in reactions)
                              l.chatsReactionFrom(r.text,
                                  r.direction == BastionMessageDirection.outgoing ? l.chatsYouLower : _nodeName(r.from))
                          ].join(', ')),
                          excludeSemantics: true,
                          child: Wrap(spacing: 6, runSpacing: 4, children: [
                            for (final e in {for (final r in reactions) r.text})
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text('$e ${reactions.where((r) => r.text == e).length}'),
                              ),
                          ]),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 4, children: [
                      if (pinned) Icon(Icons.push_pin, size: 13, semanticLabel: l.chatsPinned, color: scheme.onSurfaceVariant),
                      Text(meta, style: type.labelSmall?.copyWith(color: foreground.withValues(alpha: 0.8))),
                      if (outgoing || message.deliveryState != BastionDeliveryState.received) ...[
                        Icon(
                          message.ackProof == BastionAckProof.forged
                              ? Icons.gpp_bad_outlined
                              : message.ackProof == BastionAckProof.proven
                                  ? Icons.verified_outlined
                                  : _deliveryIcon(message.deliveryState),
                          size: 14,
                          color: message.ackProof == BastionAckProof.forged ? scheme.error : statusColor,
                        ),
                        Text(_receiptLabel(context, message),
                            style: type.labelSmall?.copyWith(
                                color: message.ackProof == BastionAckProof.forged ? scheme.error : statusColor)),
                      ],
                    ]),
                    if (failed && message.failureCode != null)
                      Padding(
                        key: ValueKey('chat-failure-${message.packetId}'),
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(_sendFailureLabel(context, message.failureCode!),
                            style: type.bodySmall?.copyWith(color: foreground)),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _airtimeCounter(BuildContext context, int length, int max) {
    if (length == 0) return null;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final lora = radio.loraConfig;
    final params = lora == null ? null : BastionAirtime.fromConfig(lora);
    if (params == null) return Text('$length/$max', style: style);
    final bytes = utf8.encode(composer.text).length;
    final seconds = BastionAirtime.textMessage(bytes, params).inMicroseconds / 1e6;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Text(l.chatsAirtime(length, max, NumberFormat('0.0', locale).format(seconds)), style: style);
  }

  Widget _composer(BuildContext context, String name) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_replyingTo case final reply?)
              Row(children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 0, 0),
                    child: Text(
                      l.chatsReplyTo(
                        reply.direction == BastionMessageDirection.outgoing ? l.chatsYou : _nodeName(reply.from),
                      ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l.chatsCancelReply,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _replyingTo = null),
                ),
              ]),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                // Sent over the air exactly as written, so these stay English.
                for (final quick in const ['Copy', 'On my way', 'Need assistance', 'What is your position?'])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ActionChip(label: Text(quick), onPressed: () => _send(quick)),
                  ),
              ]),
            ),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              IconButton(
                tooltip: l.chatsMentionNode,
                icon: const Icon(Icons.alternate_email),
                onPressed: _mention,
              ),
              SarnegComposeButton(controller: composer, onChanged: _saveDraft),
              Expanded(
                child: TextField(
                  key: const ValueKey('chat-composer'),
                  controller: composer,
                  maxLength: 228,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) =>
                      _airtimeCounter(context, currentLength, maxLength ?? 228),
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l.chatsMessageNode(name),
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _send(),
                  onChanged: (_) => _saveDraft(),
                ),
              ),
              IconButton(
                key: const ValueKey('chat-schedule'),
                tooltip: l.chatsSchedule,
                icon: const Icon(Icons.schedule_send),
                onPressed: _schedule,
              ),
              IconButton.filled(
                key: const ValueKey('chat-send'),
                tooltip: l.chatsSend,
                icon: const Icon(Icons.send),
                onPressed: _send,
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _scheduledFor(BuildContext context) => ListenableBuilder(
        listenable: _scheduled,
        builder: (context, _) {
          final items = [
            for (final m in _scheduled.items)
              if (m.destination == conversation.destination && (conversation.isChannel ? m.channel == conversation.channel : true)) m
          ];
          if (items.isEmpty) return const SizedBox.shrink();
          final now = DateTime.now();
          final material = MaterialLocalizations.of(context);
          return Card(
            margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Column(children: [
              for (final m in items)
                ListTile(
                  key: ValueKey('scheduled-${m.id}'),
                  dense: true,
                  leading: Icon(BastionScheduledMessages.isMissed(m, now) ? Icons.error_outline : Icons.schedule),
                  title: Text(m.text),
                  subtitle: Text(BastionScheduledMessages.isMissed(m, now)
                      ? l.chatsScheduleMissed
                      : l.chatsScheduledFor(BastionChatDays.label(m.dueAt, now),
                          material.formatTimeOfDay(TimeOfDay.fromDateTime(m.dueAt)))),
                  trailing: IconButton(
                    tooltip: l.chatsScheduleCancel,
                    icon: const Icon(Icons.close),
                    onPressed: () => unawaited(_scheduled.cancel(m.id)),
                  ),
                ),
            ]),
          );
        },
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([radio, SentinelService.instance]),
        builder: (context, _) {
          final scheme = Theme.of(context).colorScheme;
          final sentinel = SentinelService.instance;
          final all = radio.messages;
          final mine = [
            for (final m in all)
              if (!m.isReaction && conversation.includes(m) && !sentinelHides(sentinel, m)) m
          ];
          final reactions = <int, List<BastionChatMessage>>{};
          for (final m in all) {
            if (m.isReaction && m.replyId != null) (reactions[m.replyId!] ??= []).add(m);
          }
          final now = DateTime.now();
          final rows = _rows(mine, now).reversed.toList();
          final pins = radio.chatMarks.pinnedIn(mine);
          final name = conversationTitle(l, radio, conversation);
          final node = conversation.node;
          return Scaffold(
            appBar: AppBar(
              titleSpacing: 0,
              title: Semantics(
                button: true,
                hint: l.chatsSwitch,
                child: InkWell(
                  key: const ValueKey('chat-switch'),
                  onTap: _switchChat,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(conversationSubtitle(l, radio, conversation),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                      ])),
                      const ExcludeSemantics(child: Icon(Icons.arrow_drop_down)),
                    ]),
                  ),
                ),
              ),
              actions: [
                if (conversation.isChannel) ...[
                  IconButton(
                    tooltip: l.chatsShareChannel,
                    icon: const Icon(Icons.qr_code),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => ChannelSharePage(radio: radio))),
                  ),
                  IconButton(
                    key: const ValueKey('chat-edit-channel'),
                    tooltip: l.chatsEditChannel,
                    icon: const Icon(Icons.tune),
                    onPressed: () => openChannelEditor(context, radio, conversation.channel),
                  ),
                ] else if (node != null)
                  IconButton(
                    tooltip: l.chatsNodeInfo,
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => NodeDetailPage(radio: radio, nodeNum: node))),
                  ),
              ],
            ),
            body: Column(children: [
              if (node != null && radio.nodeKeys.hasChanged(node))
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: NxBanner(
                    tone: NxTone.danger,
                    icon: Icons.gpp_maybe_outlined,
                    title: l.chatsKeyChanged,
                    message: l.chatsKeyChangedBody(name),
                  ),
                ),
              if (node != null)
                if (radio.lookalikeOf(node) case final like?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: NxBanner(
                      tone: NxTone.warning,
                      icon: Icons.content_copy_outlined,
                      title: l.nodesLookalike(_nodeName(like)),
                      message: l.chatsLookalikeBody(name, _nodeName(like)),
                    ),
                  ),
              if (pins.isNotEmpty)
                Material(
                  color: scheme.surfaceContainerLow,
                  child: Column(children: [
                    ListTile(
                      key: const ValueKey('chat-pins'),
                      dense: true,
                      leading: Icon(Icons.push_pin, color: scheme.primary),
                      title: Text(_showPins ? l.chatsPinnedCount(pins.length) : pins.first.text,
                          maxLines: _showPins ? 1 : 2),
                      trailing: Icon(_showPins ? Icons.expand_less : Icons.expand_more),
                      onTap: () => setState(() => _showPins = !_showPins),
                    ),
                    if (_showPins)
                      for (final m in pins)
                        ListTile(
                          dense: true,
                          title: Text(m.text),
                          subtitle: Text('${m.direction == BastionMessageDirection.outgoing ? l.chatsYou : _nodeName(m.from)} • ${BastionChatDays.label(m.timestamp, now)}'),
                          trailing: IconButton(
                            tooltip: l.chatsUnpin,
                            icon: const Icon(Icons.close),
                            onPressed: () => _togglePin(m),
                          ),
                        ),
                  ]),
                ),
              Expanded(
                child: mine.isEmpty
                    ? Center(child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: NxEmptyState(
                          icon: Icons.chat_bubble_outline,
                          title: l.chatsThreadEmpty,
                          detail: radio.isReady ? l.chatsConnectedSub : l.chatsOfflineSub,
                        ),
                      ))
                    : Stack(children: [
                        ListView.builder(
                          controller: _scroll,
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          itemCount: rows.length,
                          itemBuilder: (context, i) => switch (rows[i]) {
                            _DayRow(:final label) => _TimelineDivider(label: label),
                            _NewRow() => _TimelineDivider(label: l.chatsNewBelow, highlight: true),
                            _MessageRow(:final message) => _swipeable(
                                context, message,
                                _bubble(context, message, reactions[message.packetId])),
                          },
                        ),
                        // Back to the newest message after scrolling up, as in
                        // NOTORYX Core.
                        PositionedDirectional(
                          end: NxSpace.md,
                          bottom: NxSpace.md,
                          child: ValueListenableBuilder(
                            valueListenable: _awayFromLatest,
                            builder: (context, away, _) => away
                                ? FloatingActionButton.small(
                                    key: const ValueKey('chat-jump-latest'),
                                    heroTag: null,
                                    tooltip: l.chatJumpLatest,
                                    onPressed: _jumpToLatest,
                                    child: const Icon(Icons.keyboard_double_arrow_down),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ]),
              ),
              _scheduledFor(context),
              _composer(context, name),
            ]),
          );
        },
      );
}

/// The name shown for a chat.
String conversationTitle(AppLocalizations l, MeshtasticRadioCoordinator radio, BastionConversation c) {
  if (c.isChannel) {
    for (final m in radio.channelMetadata) {
      if (m.index == c.channel && m.name.isNotEmpty) return m.name;
    }
    return c.channel == 0 ? l.chatsPrimaryChannel : l.chatsChannelN(c.channel);
  }
  // Live nodes first, then nodes restored from an import, then the !id.
  return radio.nodeName(c.node!);
}

/// The line under a chat's name: which channel slot, or a direct chat.
String conversationSubtitle(AppLocalizations l, MeshtasticRadioCoordinator radio, BastionConversation c) {
  if (!c.isChannel) return l.chatsDirectSub;
  final active = radio.channelMetadata.any((m) => m.index == c.channel && m.role != 0);
  return active || radio.channelMetadata.isEmpty ? l.chatsChannelN(c.channel) : l.chatsChannelOffline(c.channel);
}

/// Opens the editor for one channel slot, or says a radio is needed.
Future<void> openChannelEditor(BuildContext context, MeshtasticRadioCoordinator radio, int index) async {
  if (!radio.isReady) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).chatsNeedRadioChannels)));
    return;
  }
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => ChannelEditorPage(radio: radio, index: index),
  ));
}

/// A sheet listing every chat (and, with [everyNode], every known node) to
/// pick one from.
Future<BastionConversation?> pickConversation(
  BuildContext context,
  MeshtasticRadioCoordinator radio, {
  required String title,
  BastionConversation? current,
  bool everyNode = false,
}) {
  final l = AppLocalizations.of(context);
  final lists = BastionConversations.build(
    messages: radio.messages,
    channelSlots: [for (final c in radio.channelMetadata) if (c.role != 0) c.index],
    unread: (key) => radio.chatMarks.unreadIn(radio.messages, conversation: key),
  );
  final known = {for (final s in lists.direct) s.conversation.node};
  bool pickable(MeshtasticNode n) => n.num != radio.localNodeNum && !known.contains(n.num);
  // Nodes the radio hears now. Typing in the search box looks through every
  // node the phone knows, including ones restored from an import.
  final heard = everyNode ? [for (final n in radio.nodes) if (pickable(n)) n] : const <MeshtasticNode>[];
  var query = '';
  List<MeshtasticNode> matches() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return heard;
    return [
      for (final n in radio.knownNodes)
        if (pickable(n) &&
            (n.displayName.toLowerCase().contains(q) ||
                (n.id?.toLowerCase().contains(q) ?? false) ||
                (n.shortName?.toLowerCase().contains(q) ?? false)))
          n,
    ].take(50).toList();
  }

  return showModalBottomSheet<BastionConversation>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(child: StatefulBuilder(builder: (sheet, setSheet) {
      final others = matches();
      // While searching, matches come first and rows that don't match are
      // hidden, so results are not pushed under the keyboard.
      final q = query.trim().toLowerCase();
      final searching = q.isNotEmpty;
      bool titleMatches(BastionConversation c) => conversationTitle(l, radio, c).toLowerCase().contains(q);
      final channels = [for (final s in lists.channels) if (!searching || titleMatches(s.conversation)) s];
      final direct = [for (final s in lists.direct) if (!searching || titleMatches(s.conversation)) s];
      final channelRows = [
        if (channels.isNotEmpty) NxSectionLabel(l.chatsChannelsSection),
        for (final s in channels)
          ListTile(
            leading: const Icon(Icons.tag),
            title: Text(conversationTitle(l, radio, s.conversation)),
            subtitle: Text(conversationSubtitle(l, radio, s.conversation)),
            selected: s.conversation == current,
            trailing: s.unread > 0 ? Badge(label: Text('${s.unread}')) : null,
            onTap: () => Navigator.pop(sheet, s.conversation),
          ),
      ];
      final directRows = [
        if (direct.isNotEmpty || others.isNotEmpty) NxSectionLabel(l.chatsDirectSection),
        // New nodes first while searching: they are what the search is for.
        if (searching) ..._newNodeRows(sheet, others),
        for (final s in direct)
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(conversationTitle(l, radio, s.conversation)),
            selected: s.conversation == current,
            trailing: s.unread > 0 ? Badge(label: Text('${s.unread}')) : null,
            onTap: () => Navigator.pop(sheet, s.conversation),
          ),
        if (!searching) ..._newNodeRows(sheet, others),
      ];
      final nothing = searching && channels.isEmpty && direct.isEmpty && others.isEmpty;
      // Lift the sheet above the keyboard so results stay visible while typing.
      return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
      child: DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(controller: controller, children: [
        ListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
        if (everyNode)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              key: const ValueKey('pick-node-search'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l.nodesSearch,
              ),
              onChanged: (v) => setSheet(() => query = v),
            ),
          ),
        if (nothing) ListTile(title: Text(l.nodesNoMatch(query.trim())), subtitle: Text(l.nodesNoMatchHint)),
        if (searching) ...[...directRows, ...channelRows] else ...[...channelRows, ...directRows],
      ]),
    ));
    })),
  );
}

/// Rows for nodes with no chat yet; tapping one starts a DM.
List<Widget> _newNodeRows(BuildContext sheet, List<MeshtasticNode> nodes) => [
      for (final n in nodes)
        ListTile(
          leading: const Icon(Icons.person_add_alt),
          title: Text(n.displayName),
          onTap: () => Navigator.pop(sheet, BastionConversation.direct(n.num)),
        ),
    ];

/// A quiet card under a message with a web link: the site, the page title
/// and a line about it. Shown only when link previews are on in Privacy.
class _LinkPreviewCard extends StatelessWidget {
  const _LinkPreviewCard({required this.link, required this.foreground});
  final Uri link;
  final Color foreground;

  @override
  Widget build(BuildContext context) => FutureBuilder<LinkPreview?>(
        future: BastionLinkPreviews.instance.previewFor(link),
        builder: (context, snap) {
          final p = snap.data;
          if (p == null) return const SizedBox.shrink();
          final type = Theme.of(context).textTheme;
          return Container(
            key: ValueKey('link-preview-${link.host}'),
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: BorderDirectional(start: BorderSide(color: foreground.withValues(alpha: .6), width: 3)),
              color: foreground.withValues(alpha: .06),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.host, style: type.labelSmall?.copyWith(color: foreground.withValues(alpha: .85))),
              Text(p.title, style: type.titleSmall?.copyWith(color: foreground)),
              if (p.description case final d?) Text(d, style: type.bodySmall?.copyWith(color: foreground)),
            ]),
          );
        },
      );
}

