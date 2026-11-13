import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A reusable checklist: a title and the steps to tick off.
@immutable
class ChecklistTemplate {
  const ChecklistTemplate({required this.id, required this.title, required this.items});
  final String id;
  final String title;
  final List<String> items;

  Map<String, Object?> toJson() => {'id': id, 'title': title, 'items': items};

  static ChecklistTemplate fromJson(Map<String, Object?> json) => ChecklistTemplate(
    id: json['id']! as String,
    title: json['title']! as String,
    items: [for (final i in json['items']! as List) i as String],
  );
}

/// One step of a run, and when it was ticked.
@immutable
class RunItem {
  const RunItem(this.text, {this.doneAt});
  final String text;
  final DateTime? doneAt;
  bool get done => doneAt != null;

  Map<String, Object?> toJson() => {
    'text': text,
    'doneAt': doneAt?.toUtc().toIso8601String(),
  };

  static RunItem fromJson(Map<String, Object?> json) => RunItem(json['text']! as String,
      doneAt: json['doneAt'] == null ? null : DateTime.parse(json['doneAt']! as String));
}

/// One time a checklist was worked through. Copies the steps, so editing the
/// checklist later never changes a saved record.
@immutable
class ChecklistRun {
  const ChecklistRun({
    required this.id,
    required this.templateId,
    required this.title,
    required this.items,
    required this.startedAt,
    this.finishedAt,
    this.note = '',
  });

  final String id;
  final String templateId;
  final String title;
  final List<RunItem> items;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String note;

  bool get finished => finishedAt != null;
  int get doneCount => items.where((i) => i.done).length;

  ChecklistRun copyWith({List<RunItem>? items, DateTime? finishedAt, String? note}) => ChecklistRun(
    id: id, templateId: templateId, title: title, startedAt: startedAt,
    items: items ?? this.items, finishedAt: finishedAt ?? this.finishedAt, note: note ?? this.note,
  );

  Map<String, Object?> toJson() => {
    'id': id, 'templateId': templateId, 'title': title,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'finishedAt': finishedAt?.toUtc().toIso8601String(),
    'note': note,
    'items': [for (final i in items) i.toJson()],
  };

  static ChecklistRun fromJson(Map<String, Object?> json) => ChecklistRun(
    id: json['id']! as String,
    templateId: json['templateId']! as String,
    title: json['title']! as String,
    startedAt: DateTime.parse(json['startedAt']! as String),
    finishedAt: json['finishedAt'] == null ? null : DateTime.parse(json['finishedAt']! as String),
    note: json['note'] as String? ?? '',
    items: [for (final i in json['items']! as List) RunItem.fromJson(Map<String, Object?>.from(i as Map))],
  );
}

/// Exports of a finished run. Times are ISO 8601 UTC so the files mean the
/// same thing wherever they are opened.
abstract final class ChecklistExport {
  static const format = 'notoryx.checklist-run';
  static const formatVersion = 1;

  /// A machine-readable record of [run].
  static String json(ChecklistRun run) => const JsonEncoder.withIndent('  ').convert({
    'format': format,
    'formatVersion': formatVersion,
    'run': run.toJson(),
  });

  /// One row per step, plus the run's start, finish and note on every row.
  static String csv(ChecklistRun run) {
    String cell(String? v) {
      var text = v ?? '';
      // Stop spreadsheets from running user text as a formula.
      if (text.isNotEmpty && '=+-@\t\r'.contains(text[0])) text = "'$text";
      return '"${text.replaceAll('"', '""')}"';
    }

    String? utc(DateTime? t) => t?.toUtc().toIso8601String();
    final rows = [
      ['checklist', 'started_utc', 'finished_utc', 'step', 'item', 'done', 'done_utc', 'note'],
      for (final (i, item) in run.items.indexed)
        [run.title, utc(run.startedAt), utc(run.finishedAt), '${i + 1}', item.text,
          item.done ? 'yes' : 'no', utc(item.doneAt), run.note],
    ];
    return '${rows.map((r) => r.map(cell).join(',')).join('\r\n')}\r\n';
  }

  /// A safe file name such as `checklist-radio-check-20261113-0942.csv`.
  static String fileName(ChecklistRun run, String extension) {
    final t = (run.finishedAt ?? run.startedAt).toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    final slug = run.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    final base = slug.isEmpty ? 'checklist' : 'checklist-$slug';
    return '$base-${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}.$extension';
  }
}

/// Checklists and their completed runs, kept on the phone. Nothing here
/// needs a radio or a network connection.
class BastionChecklists extends ChangeNotifier {
  BastionChecklists({SharedPreferencesAsync? preferences, DateTime Function()? clock})
      : _preferences = preferences,
        _clock = clock ?? DateTime.now;

  static final instance = BastionChecklists();

  static const templatesKey = 'bastion.checklists.templates.v1';
  static const runsKey = 'bastion.checklists.runs.v1';

  /// Oldest finished runs beyond this are dropped.
  static const maxRuns = 500;

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();
  final DateTime Function() _clock;
  final List<ChecklistTemplate> _templates = [];
  final List<ChecklistRun> _runs = [];
  Future<void>? _loading;
  bool _blocked = false;
  int _counter = 0;

  List<ChecklistTemplate> get templates => List.unmodifiable(_templates);

  /// Runs still being worked through, newest first.
  List<ChecklistRun> get activeRuns => List.unmodifiable(
      _runs.where((r) => !r.finished).toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt)));

  /// Finished runs, newest first.
  List<ChecklistRun> get finishedRuns => List.unmodifiable(
      _runs.where((r) => r.finished).toList()..sort((a, b) => b.finishedAt!.compareTo(a.finishedAt!)));

  ChecklistRun? run(String id) => _runs.where((r) => r.id == id).firstOrNull;
  ChecklistTemplate? template(String id) => _templates.where((t) => t.id == id).firstOrNull;

  /// Whether saved checklists could not be read; nothing is saved then, so
  /// what is stored is never overwritten.
  bool get storageProblem => _blocked;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final t = await _store.getString(templatesKey);
      final r = await _store.getString(runsKey);
      _templates.addAll(_decode(t, ChecklistTemplate.fromJson));
      _runs.addAll(_decode(r, ChecklistRun.fromJson));
    } catch (_) {
      _blocked = true;
    }
    notifyListeners();
  }

  static List<T> _decode<T>(String? raw, T Function(Map<String, Object?>) read) {
    if (raw == null) return const [];
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];
    return [
      for (final item in decoded)
        if (_tryRead(item, read) case final T value) value,
    ];
  }

  static T? _tryRead<T>(Object? item, T Function(Map<String, Object?>) read) {
    try {
      return read(Map<String, Object?>.from(item! as Map));
    } catch (_) {
      return null; // One damaged record must not hide the rest.
    }
  }

  String _newId() => '${_clock().microsecondsSinceEpoch.toRadixString(36)}${(_counter++).toRadixString(36)}';

  Future<bool> _save() async {
    notifyListeners();
    if (_blocked) return false;
    try {
      await _store.setString(templatesKey, jsonEncode([for (final t in _templates) t.toJson()]));
      await _store.setString(runsKey, jsonEncode([for (final r in _runs) r.toJson()]));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Adds or replaces a checklist. Blank steps are dropped; returns null
  /// when the title or every step is blank.
  Future<ChecklistTemplate?> saveTemplate({String? id, required String title, required List<String> items}) async {
    await load();
    final clean = [for (final i in items) if (i.trim().isNotEmpty) i.trim()];
    if (title.trim().isEmpty || clean.isEmpty) return null;
    final template = ChecklistTemplate(id: id ?? _newId(), title: title.trim(), items: clean);
    final at = _templates.indexWhere((t) => t.id == template.id);
    at < 0 ? _templates.add(template) : _templates[at] = template;
    await _save();
    return template;
  }

  /// Removes a checklist. Records of earlier runs are kept.
  Future<bool> deleteTemplate(String id) async {
    await load();
    _templates.removeWhere((t) => t.id == id);
    return _save();
  }

  Future<ChecklistRun?> startRun(String templateId) async {
    await load();
    final t = template(templateId);
    if (t == null) return null;
    final run = ChecklistRun(id: _newId(), templateId: t.id, title: t.title,
        items: [for (final i in t.items) RunItem(i)], startedAt: _clock());
    _runs.add(run);
    await _save();
    return run;
  }

  Future<bool> _update(String id, ChecklistRun Function(ChecklistRun) change) async {
    await load();
    final at = _runs.indexWhere((r) => r.id == id);
    if (at < 0 || _runs[at].finished) return false;
    _runs[at] = change(_runs[at]);
    return _save();
  }

  Future<bool> setDone(String runId, int index, bool done) => _update(runId, (r) => r.copyWith(items: [
    for (final (i, item) in r.items.indexed)
      i == index ? RunItem(item.text, doneAt: done ? (item.doneAt ?? _clock()) : null) : item,
  ]));

  Future<bool> setNote(String runId, String note) => _update(runId, (r) => r.copyWith(note: note.trim()));

  /// Closes a run and keeps it as a timestamped record.
  Future<bool> finish(String runId) async {
    final ok = await _update(runId, (r) => r.copyWith(finishedAt: _clock()));
    final finished = _runs.where((r) => r.finished).toList()..sort((a, b) => a.finishedAt!.compareTo(b.finishedAt!));
    if (finished.length > maxRuns) {
      final drop = finished.take(finished.length - maxRuns).map((r) => r.id).toSet();
      _runs.removeWhere((r) => drop.contains(r.id));
      await _save();
    }
    return ok;
  }

  Future<bool> deleteRun(String runId) async {
    await load();
    _runs.removeWhere((r) => r.id == runId);
    return _save();
  }
}
