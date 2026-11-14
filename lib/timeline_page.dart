import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n/generated/app_localizations.dart';
import 'node_detail_page.dart';
import 'services/bastion_chat_message.dart';
import 'services/bastion_timeline.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// One feed of what happened on the mesh: messages, nodes heard for the
/// first time, direct signal changes and waypoints, filterable by kind and
/// searchable.
class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key, required this.radio, required this.timeline});

  /// The radio the app shows; node details open on it.
  final MeshtasticRadioCoordinator radio;
  final BastionTimeline timeline;

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  final _search = TextEditingController();
  final Set<TimelineKind> _kinds = {...TimelineKind.values};

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static IconData _icon(TimelineKind kind) => switch (kind) {
        TimelineKind.message => Icons.chat_bubble_outline,
        TimelineKind.nodeJoined => Icons.person_add_alt,
        TimelineKind.signalChange => Icons.network_check,
        TimelineKind.waypoint => Icons.place_outlined,
      };

  static String _kindName(AppLocalizations l, TimelineKind kind) => switch (kind) {
        TimelineKind.message => l.tlKindMessages,
        TimelineKind.nodeJoined => l.tlKindNodes,
        TimelineKind.signalChange => l.tlKindSignal,
        TimelineKind.waypoint => l.tlKindWaypoints,
      };

  String _title(AppLocalizations l, TimelineEvent e) => switch (e.kind) {
        TimelineKind.message => e.outgoing ? l.tlYouSent : l.tlMessageFrom(e.subject),
        TimelineKind.nodeJoined => l.tlNodeJoined(e.subject),
        TimelineKind.signalChange => (e.toSnr ?? 0) >= (e.fromSnr ?? 0)
            ? l.tlSignalUp(e.subject, e.fromSnr!.toStringAsFixed(1), e.toSnr!.toStringAsFixed(1))
            : l.tlSignalDown(e.subject, e.fromSnr!.toStringAsFixed(1), e.toSnr!.toStringAsFixed(1)),
        TimelineKind.waypoint => l.tlWaypoint(e.subject),
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final time = DateFormat.MMMd(locale).add_Hm();
    return Scaffold(
      appBar: AppBar(title: Text(l.tlTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge([widget.radio, widget.timeline]),
        builder: (context, _) {
          final source = widget.timeline.source;
          final ownEvents = source is! CoordinatorTimelineSource || identical(source.radio, widget.radio);
          final all = ownEvents
              ? widget.timeline.all()
              : [
                  // Demo mode: only the radio on screen, never the real one's events.
                  for (final m in widget.radio.messages)
                    if (!m.isReaction)
                      TimelineEvent(kind: TimelineKind.message, at: m.timestamp,
                          subject: widget.radio.nodeName(m.from), detail: m.text, nodeNum: m.from,
                          outgoing: m.direction == BastionMessageDirection.outgoing),
                ];
          final shown = filterTimeline(all, kinds: _kinds, query: _search.text);
          return ListView.builder(
            padding: NxSpace.page,
            itemCount: shown.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  NxPageHeader(title: l.tlTitle, subtitle: l.tlSubtitle),
                  TextField(
                    key: const ValueKey('timeline-search'),
                    controller: _search,
                    decoration: InputDecoration(
                      labelText: l.tlSearch,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l.tlClearSearch,
                              icon: const Icon(Icons.clear),
                              onPressed: _search.clear,
                            ),
                    ),
                  ),
                  const SizedBox(height: NxSpace.sm),
                  Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
                    for (final kind in TimelineKind.values)
                      FilterChip(
                        key: ValueKey('timeline-filter-${kind.name}'),
                        avatar: Icon(_icon(kind), size: 18),
                        label: Text(_kindName(l, kind)),
                        selected: _kinds.contains(kind),
                        onSelected: (on) => setState(() => on ? _kinds.add(kind) : _kinds.remove(kind)),
                      ),
                  ]),
                  const SizedBox(height: NxSpace.xs),
                  Semantics(
                    liveRegion: true,
                    child: Text(l.tlShowing(shown.length), style: Theme.of(context).textTheme.bodySmall),
                  ),
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: NxSpace.lg),
                      child: Text(all.isEmpty ? l.tlEmpty : l.tlNoMatch, textAlign: TextAlign.center),
                    ),
                  const SizedBox(height: NxSpace.xs),
                ]);
              }
              final e = shown[i - 1];
              final node = e.nodeNum;
              final opensNode = node != null && e.kind != TimelineKind.message && node != widget.radio.localNodeNum;
              return Card(
                child: ListTile(
                  leading: Icon(_icon(e.kind)),
                  title: Text(_title(l, e)),
                  subtitle: e.detail == null
                      ? Text(time.format(e.at))
                      : Text('${e.detail}\n${time.format(e.at)}', maxLines: 4),
                  isThreeLine: e.detail != null,
                  trailing: opensNode ? const Icon(Icons.chevron_right) : null,
                  onTap: opensNode
                      ? () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => NodeDetailPage(radio: widget.radio, nodeNum: node)))
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
