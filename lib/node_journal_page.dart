import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'node_mark.dart';
import 'services/bastion_node_journal.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_units.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// The word and icon for each behaviour, so colour is never the only cue.
({String word, IconData icon}) behaviourLook(AppLocalizations l, NodeBehaviour b) => switch (b) {
  NodeBehaviour.steadyRelay => (word: l.njSteadyRelay, icon: Icons.cell_tower),
  NodeBehaviour.roamer => (word: l.njRoamer, icon: Icons.hiking),
  NodeBehaviour.regular => (word: l.njRegular, icon: Icons.event_repeat),
  NodeBehaviour.rarelyHeard => (word: l.njRarelyHeard, icon: Icons.visibility_outlined),
  NodeBehaviour.newcomer => (word: l.njNewcomer, icon: Icons.fiber_new_outlined),
  NodeBehaviour.goneQuiet => (word: l.njGoneQuiet, icon: Icons.bedtime_outlined),
  NodeBehaviour.internetLinked => (word: l.njInternetLinked, icon: Icons.public),
};

String confidenceWord(AppLocalizations l, ConfidenceBand band) => switch (band) {
  ConfidenceBand.low => l.njConfLow,
  ConfidenceBand.medium => l.njConfMedium,
  ConfidenceBand.high => l.njConfHigh,
};

String evidenceText(AppLocalizations l, Evidence e, BastionUnits units) {
  String d(int metres) => BastionUnitFormat.distance(metres.toDouble(), units);
  return switch (e.kind) {
    EvidenceKind.hoursOnAir => l.njEvHoursOnAir(e.a, e.b),
    EvidenceKind.placesSpread => l.njEvPlacesSpread(e.a, d(e.b)),
    EvidenceKind.staysPut => l.njEvStaysPut(d(e.b)),
    EvidenceKind.externalPower => l.njEvExternalPower(e.a),
    EvidenceKind.daysHeard => l.njEvDaysHeard(e.a),
    EvidenceKind.fewHours => l.njEvFewHours(e.a, e.b),
    EvidenceKind.firstHeardHoursAgo => l.njEvFirstHeard(e.a),
    EvidenceKind.silentDays => l.njEvSilentDays(e.a),
    EvidenceKind.viaInternet => l.njEvViaInternet(e.a, e.b),
  };
}

String _when(BuildContext context, DateTime t) {
  final m = MaterialLocalizations.of(context);
  final local = t.toLocal();
  return '${m.formatShortDate(local)} ${m.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

/// Every node the phone has heard, with behaviour labels, tags and search.
class NodeJournalPage extends StatefulWidget {
  const NodeJournalPage({super.key, required this.journal, this.clock = DateTime.now});
  final BastionNodeJournal journal;
  final DateTime Function() clock;

  @override
  State<NodeJournalPage> createState() => _NodeJournalPageState();
}

class _NodeJournalPageState extends State<NodeJournalPage> {
  final _search = TextEditingController();
  NodeBehaviour? _only;

  @override
  void initState() {
    super.initState();
    widget.journal.load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(JournalEntry e, List<BehaviourLabel> labels) {
    if (_only != null && !labels.any((x) => x.behaviour == _only)) return false;
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [e.displayName, e.shortName ?? '', e.nodeId, ...e.tags]
        .any((s) => s.toLowerCase().contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.njTitle)),
      body: ListenableBuilder(
        listenable: widget.journal,
        builder: (context, _) {
          final now = widget.clock();
          final all = [
            for (final e in widget.journal.entries)
              (entry: e, labels: NodeBehaviourClassifier.classify(e, now)),
          ];
          final shown = [for (final r in all) if (_matches(r.entry, r.labels)) r];
          return ListView(padding: NxSpace.page, children: [
            NxPageHeader(title: l.njTitle, subtitle: l.njSubtitle),
            if (widget.journal.storageProblem)
              Padding(
                padding: const EdgeInsets.only(bottom: NxSpace.sm),
                child: NxBanner(icon: Icons.warning_amber, message: l.njStorageProblem, tone: NxTone.warning),
              ),
            if (all.isEmpty)
              NxEmptyState(icon: Icons.menu_book_outlined, title: l.njEmptyTitle, detail: l.njEmptyDetail)
            else ...[
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: l.njSearch,
                ),
              ),
              const SizedBox(height: NxSpace.xs),
              Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
                ChoiceChip(
                  label: Text(l.njAll),
                  selected: _only == null,
                  onSelected: (_) => setState(() => _only = null),
                ),
                for (final b in NodeBehaviour.values)
                  ChoiceChip(
                    avatar: Icon(behaviourLook(l, b).icon, size: 18),
                    label: Text(behaviourLook(l, b).word),
                    selected: _only == b,
                    onSelected: (on) => setState(() => _only = on ? b : null),
                  ),
              ]),
              const SizedBox(height: NxSpace.sm),
              Semantics(liveRegion: true, child: Text(l.njCount(shown.length, all.length),
                  style: Theme.of(context).textTheme.labelLarge)),
              const SizedBox(height: NxSpace.xs),
              if (shown.isEmpty)
                Padding(padding: const EdgeInsets.all(NxSpace.md), child: Text(l.njNoMatch)),
              for (final r in shown)
                Card(child: ListTile(
                  key: ValueKey('journal-${r.entry.num}'),
                  leading: NodeMark(num: r.entry.num),
                  title: Text(r.entry.displayName),
                  subtitle: Text([
                    if (r.labels.isEmpty)
                      l.njLearning
                    else
                      '${behaviourLook(l, r.labels.first.behaviour).word} · ${confidenceWord(l, r.labels.first.band)}',
                    l.njLastHeard(_when(context, r.entry.lastHeard)),
                    if (r.entry.tags.isNotEmpty) r.entry.tags.join(', '),
                  ].join('\n')),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => JournalEntryPage(
                        journal: widget.journal, num: r.entry.num, clock: widget.clock))),
                )),
            ],
          ]);
        },
      ),
    );
  }
}

/// One node's journal page: its mark, labels with evidence, tags and notes.
class JournalEntryPage extends StatefulWidget {
  const JournalEntryPage({super.key, required this.journal, required this.num, this.clock = DateTime.now});
  final BastionNodeJournal journal;
  final int num;
  final DateTime Function() clock;

  @override
  State<JournalEntryPage> createState() => _JournalEntryPageState();
}

class _JournalEntryPageState extends State<JournalEntryPage> {
  late final _note = TextEditingController(text: widget.journal.entry(widget.num)?.note ?? '');
  final _tag = TextEditingController();
  String? _status;

  @override
  void dispose() {
    _note.dispose();
    _tag.dispose();
    super.dispose();
  }

  Future<void> _report(Future<bool> work) async {
    final l = AppLocalizations.of(context);
    final ok = await work;
    if (!mounted) return;
    setState(() => _status = ok ? l.njSaved : l.njSaveFailed);
  }

  void _addTag(JournalEntry e) {
    final t = _tag.text.trim();
    if (t.isEmpty) return;
    _tag.clear();
    _report(widget.journal.setTags(e.num, [...e.tags, t]));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final units = BastionPreferences.instance.units;
    return ListenableBuilder(
      listenable: widget.journal,
      builder: (context, _) {
        final e = widget.journal.entry(widget.num);
        if (e == null) return Scaffold(appBar: AppBar());
        final labels = NodeBehaviourClassifier.classify(e, widget.clock());
        final type = Theme.of(context).textTheme;
        final suggestions = [
          for (final t in widget.journal.allTags)
            if (!e.tags.any((x) => x.toLowerCase() == t.toLowerCase())) t,
        ];
        return Scaffold(
          appBar: AppBar(title: Text(e.displayName)),
          body: ListView(padding: NxSpace.page, children: [
            Row(children: [
              NodeMark(num: e.num, size: 72),
              const SizedBox(width: NxSpace.md),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Semantics(header: true, child: Text(e.displayName, style: type.titleLarge)),
                Text(e.nodeId, style: type.bodyMedium),
                Text(l.njFirstHeard(_when(context, e.firstHeard)), style: type.bodySmall),
                Text(l.njLastHeard(_when(context, e.lastHeard)), style: type.bodySmall),
                Text(l.njStats(e.heard, e.days), style: type.bodySmall),
              ])),
            ]),
            NxSectionLabel(l.njWhy),
            if (labels.isEmpty)
              Card(child: Padding(padding: const EdgeInsets.all(NxSpace.md), child: Text(l.njNoLabels))),
            for (final label in labels)
              Card(child: Padding(
                padding: const EdgeInsets.all(NxSpace.md),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(behaviourLook(l, label.behaviour).icon),
                    const SizedBox(width: NxSpace.xs),
                    Expanded(child: Text(behaviourLook(l, label.behaviour).word, style: type.titleMedium)),
                    NxStatusPill(
                      label: confidenceWord(l, label.band),
                      tone: switch (label.band) {
                        ConfidenceBand.high => NxTone.success,
                        ConfidenceBand.medium => NxTone.info,
                        ConfidenceBand.low => NxTone.neutral,
                      },
                    ),
                  ]),
                  const SizedBox(height: NxSpace.xs),
                  for (final ev in label.evidence)
                    Padding(
                      padding: const EdgeInsets.only(top: NxSpace.xxs),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const ExcludeSemantics(child: Text('•  ')),
                        Expanded(child: Text(evidenceText(l, ev, units))),
                      ]),
                    ),
                ]),
              )),
            NxSectionLabel(l.njTags),
            Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
              for (final t in e.tags)
                InputChip(
                  label: Text(t),
                  deleteButtonTooltipMessage: l.njRemoveTag(t),
                  onDeleted: () => _report(widget.journal.setTags(e.num, [...e.tags]..remove(t))),
                ),
            ]),
            const SizedBox(height: NxSpace.xs),
            Row(children: [
              Expanded(child: TextField(
                controller: _tag,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addTag(e),
                decoration: InputDecoration(labelText: l.njAddTag),
              )),
              const SizedBox(width: NxSpace.xs),
              IconButton.filledTonal(
                tooltip: l.njAddTag,
                onPressed: () => _addTag(e),
                icon: const Icon(Icons.add),
              ),
            ]),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: NxSpace.xs),
              Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
                for (final t in suggestions.take(8))
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(t),
                    tooltip: l.njAddThisTag(t),
                    onPressed: () => _report(widget.journal.setTags(e.num, [...e.tags, t])),
                  ),
              ]),
            ],
            NxSectionLabel(l.njNotes),
            TextField(
              controller: _note,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(labelText: l.njNotes, hintText: l.njNoteHint),
            ),
            const SizedBox(height: NxSpace.xs),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: () => _report(widget.journal.setNote(e.num, _note.text)),
                child: Text(l.njSaveNote),
              ),
            ),
            if (_status != null)
              Semantics(liveRegion: true, child: Padding(
                padding: const EdgeInsets.only(top: NxSpace.xs),
                child: Text(_status!),
              )),
          ]),
        );
      },
    );
  }
}
