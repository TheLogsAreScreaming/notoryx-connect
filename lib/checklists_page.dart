import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_checklists.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// Hands an exported file to the system share sheet; replaced in tests.
typedef ShareChecklistFile = Future<void> Function(String fileName, String mimeType, String text);

Future<void> _shareFile(String fileName, String mimeType, String text) async {
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(Uint8List.fromList(utf8.encode(text)), mimeType: mimeType)],
    fileNameOverrides: [fileName],
    subject: fileName,
  ));
}

String _when(BuildContext context, DateTime t) {
  final m = MaterialLocalizations.of(context);
  final local = t.toLocal();
  return '${m.formatShortDate(local)} ${m.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
}

/// Reusable checklists, runs in progress and completed records.
class ChecklistsPage extends StatefulWidget {
  const ChecklistsPage({super.key, required this.store, this.shareFile = _shareFile});
  final BastionChecklists store;
  final ShareChecklistFile shareFile;

  @override
  State<ChecklistsPage> createState() => _ChecklistsPageState();
}

class _ChecklistsPageState extends State<ChecklistsPage> {
  @override
  void initState() {
    super.initState();
    widget.store.load();
  }

  void _open(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  void _openRun(ChecklistRun run) =>
      _open(ChecklistRunPage(store: widget.store, runId: run.id, shareFile: widget.shareFile));

  Future<void> _start(ChecklistTemplate t) async {
    final run = await widget.store.startRun(t.id);
    if (run != null && mounted) _openRun(run);
  }

  Future<void> _addStarters(AppLocalizations l) async {
    await widget.store.saveTemplate(title: l.toolsChecklist,
        items: [l.toolsCheck0, l.toolsCheck1, l.toolsCheck2, l.toolsCheck3, l.toolsCheck4]);
    await widget.store.saveTemplate(title: l.clStarterRadio,
        items: [l.clStarterRadio0, l.clStarterRadio1, l.clStarterRadio2, l.clStarterRadio3, l.clStarterRadio4]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.clTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(ChecklistEditPage(store: widget.store)),
        icon: const Icon(Icons.add),
        label: Text(l.clNew),
      ),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final store = widget.store;
          final active = store.activeRuns;
          final done = store.finishedRuns;
          return ListView(padding: NxSpace.page.copyWith(bottom: 96), children: [
            NxPageHeader(title: l.clTitle, subtitle: l.clSubtitle),
            if (store.storageProblem)
              NxBanner(icon: Icons.warning_amber, tone: NxTone.warning, message: l.clStorageProblem),
            if (active.isNotEmpty) ...[
              NxSectionLabel(l.clInProgress),
              for (final r in active)
                Card(child: ListTile(
                  leading: const Icon(Icons.pending_actions),
                  title: Text(r.title),
                  subtitle: Text(l.clProgress(r.doneCount, r.items.length)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openRun(r),
                )),
            ],
            NxSectionLabel(l.clChecklists),
            if (store.templates.isEmpty)
              NxEmptyState(
                icon: Icons.checklist,
                title: l.clEmptyTitle,
                detail: l.clEmptyDetail,
                action: OutlinedButton(onPressed: () => _addStarters(l), child: Text(l.clAddStarters)),
              ),
            for (final t in store.templates)
              Card(child: ListTile(
                leading: const Icon(Icons.checklist),
                title: Text(t.title),
                subtitle: Text(l.clSteps(t.items.length)),
                onTap: () => _start(t),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    tooltip: l.clEditNamed(t.title),
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _open(ChecklistEditPage(store: store, template: t)),
                  ),
                  IconButton(
                    tooltip: l.clStartNamed(t.title),
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _start(t),
                  ),
                ]),
              )),
            if (done.isNotEmpty) ...[
              NxSectionLabel(l.clCompleted),
              for (final r in done)
                Card(child: ListTile(
                  leading: Icon(r.doneCount == r.items.length ? Icons.task_alt : Icons.rule),
                  title: Text(r.title),
                  subtitle: Text('${_when(context, r.finishedAt!)} · ${l.clProgress(r.doneCount, r.items.length)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openRun(r),
                )),
            ],
          ]);
        },
      ),
    );
  }
}

/// Creates or edits a checklist's title and steps.
class ChecklistEditPage extends StatefulWidget {
  const ChecklistEditPage({super.key, required this.store, this.template});
  final BastionChecklists store;
  final ChecklistTemplate? template;

  @override
  State<ChecklistEditPage> createState() => _ChecklistEditPageState();
}

class _ChecklistEditPageState extends State<ChecklistEditPage> {
  late final _title = TextEditingController(text: widget.template?.title ?? '');
  late final List<TextEditingController> _items = [
    for (final i in widget.template?.items ?? const ['']) TextEditingController(text: i),
  ];
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    for (final c in _items) {
      c.dispose();
    }
    super.dispose();
  }

  void _move(int from, int to) => setState(() => _items.insert(to, _items.removeAt(from)));

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final saved = await widget.store.saveTemplate(
        id: widget.template?.id, title: _title.text, items: [for (final c in _items) c.text]);
    if (!mounted) return;
    if (saved == null) {
      setState(() => _error = l.clNeedTitleAndStep);
      return;
    }
    navigator.pop();
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(l.clDeleteTitle),
      content: Text(l.clDeleteBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.clCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.clDelete)),
      ],
    ));
    if (yes != true) return;
    await widget.store.deleteTemplate(widget.template!.id);
    if (mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? l.clNew : l.clEdit),
        actions: [
          if (widget.template != null)
            IconButton(tooltip: l.clDelete, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(padding: NxSpace.page, children: [
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.clName),
        ),
        NxSectionLabel(l.clStepsLabel),
        for (final (i, c) in _items.indexed)
          Padding(
            key: ObjectKey(c),
            padding: const EdgeInsets.only(bottom: NxSpace.xs),
            child: Row(children: [
              Expanded(child: TextField(
                controller: c,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.clStepN(i + 1)),
              )),
              IconButton(
                tooltip: l.clMoveUp(i + 1),
                icon: const Icon(Icons.arrow_upward),
                onPressed: i == 0 ? null : () => _move(i, i - 1),
              ),
              IconButton(
                tooltip: l.clMoveDown(i + 1),
                icon: const Icon(Icons.arrow_downward),
                onPressed: i == _items.length - 1 ? null : () => _move(i, i + 1),
              ),
              IconButton(
                tooltip: l.clRemoveStep(i + 1),
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _items.length == 1 ? null : () => setState(() => _items.removeAt(i).dispose()),
              ),
            ]),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(() => _items.add(TextEditingController())),
            icon: const Icon(Icons.add),
            label: Text(l.clAddStep),
          ),
        ),
        if (_error != null)
          Semantics(liveRegion: true, child: Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: NxSpace.md),
        FilledButton(onPressed: _save, child: Text(l.clSave)),
      ]),
    );
  }
}

/// Works through one run, or shows a finished run as a record with export.
class ChecklistRunPage extends StatefulWidget {
  const ChecklistRunPage({super.key, required this.store, required this.runId, this.shareFile = _shareFile});
  final BastionChecklists store;
  final String runId;
  final ShareChecklistFile shareFile;

  @override
  State<ChecklistRunPage> createState() => _ChecklistRunPageState();
}

class _ChecklistRunPageState extends State<ChecklistRunPage> {
  late final _note = TextEditingController(text: widget.store.run(widget.runId)?.note ?? '');

  @override
  void dispose() {
    // Keep a note typed but not yet saved; the store saves after this frame.
    final run = widget.store.run(widget.runId);
    if (run != null && !run.finished && _note.text.trim() != run.note) {
      unawaited(widget.store.setNote(run.id, _note.text));
    }
    _note.dispose();
    super.dispose();
  }

  Future<void> _finish(ChecklistRun run) async {
    final l = AppLocalizations.of(context);
    final left = run.items.length - run.doneCount;
    if (left > 0) {
      final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
        title: Text(l.clFinishEarlyTitle),
        content: Text(l.clFinishEarlyBody(left)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.clKeepGoing)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.clFinish)),
        ],
      ));
      if (yes != true) return;
    }
    await widget.store.setNote(run.id, _note.text);
    await widget.store.finish(run.id);
  }

  Future<void> _export(ChecklistRun run, bool csv) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.shareFile(
        ChecklistExport.fileName(run, csv ? 'csv' : 'json'),
        csv ? 'text/csv' : 'application/json',
        csv ? ChecklistExport.csv(run) : ChecklistExport.json(run),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.clExportFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final run = widget.store.run(widget.runId);
        if (run == null) return Scaffold(appBar: AppBar());
        final type = Theme.of(context).textTheme;
        return Scaffold(
          appBar: AppBar(title: Text(run.title)),
          body: ListView(padding: NxSpace.page, children: [
            Text(l.clStarted(_when(context, run.startedAt)), style: type.bodyMedium),
            if (run.finished) Text(l.clFinishedAt(_when(context, run.finishedAt!)), style: type.bodyMedium),
            const SizedBox(height: NxSpace.xs),
            Semantics(liveRegion: true, child: Text(l.clProgress(run.doneCount, run.items.length),
                style: type.titleMedium)),
            const SizedBox(height: NxSpace.xs),
            // The count above is announced; the bar repeats it visually.
            ExcludeSemantics(child: LinearProgressIndicator(
              value: run.items.isEmpty ? 0 : run.doneCount / run.items.length,
            )),
            const SizedBox(height: NxSpace.sm),
            Card(child: Column(children: [
              for (final (i, item) in run.items.indexed)
                CheckboxListTile(
                  value: item.done,
                  title: Text(item.text),
                  subtitle: item.done ? Text(l.clTickedAt(_when(context, item.doneAt!))) : null,
                  onChanged: run.finished ? null : (v) => widget.store.setDone(run.id, i, v ?? false),
                ),
            ])),
            NxSectionLabel(l.clNote),
            if (run.finished)
              Text(run.note.isEmpty ? l.clNoNote : run.note)
            else
              TextField(
                controller: _note,
                minLines: 2,
                maxLines: 6,
                decoration: InputDecoration(labelText: l.clNote, hintText: l.clNoteHint),
                onEditingComplete: () => widget.store.setNote(run.id, _note.text),
              ),
            const SizedBox(height: NxSpace.md),
            if (!run.finished)
              FilledButton.icon(
                onPressed: () => _finish(run),
                icon: const Icon(Icons.task_alt),
                label: Text(l.clFinish),
              )
            else ...[
              NxSectionLabel(l.clExport),
              Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
                OutlinedButton.icon(
                  onPressed: () => _export(run, true),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: Text(l.clExportCsv),
                ),
                OutlinedButton.icon(
                  onPressed: () => _export(run, false),
                  icon: const Icon(Icons.data_object),
                  label: Text(l.clExportJson),
                ),
              ]),
            ],
          ]),
        );
      },
    );
  }
}
