import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/bastion_bot_guard.dart';
import 'services/bastion_field_log.dart';
import 'services/bastion_report_templates.dart';
import 'services/meshtastic_radio_coordinator.dart';

/// Local incident records, deliberate template sends and receiver coverage history.
class FieldToolsPage extends StatefulWidget {
  const FieldToolsPage({super.key, required this.radio});
  final MeshtasticRadioCoordinator radio;
  @override
  State<FieldToolsPage> createState() => _FieldToolsPageState();
}

class _FieldToolsPageState extends State<FieldToolsPage> {
  final note = TextEditingController();
  final message = TextEditingController(text: 'ASSISTANCE REQUESTED | Name: | Location: | Need:');
  int channel = 0;
  bool busy = false;
  String? status;
  AppLocalizations get l => AppLocalizations.of(context);

  // The message text goes on air as written, so it stays English.
  List<(String, String)> get templates => [
        (l.frTplAssistance, 'ASSISTANCE REQUESTED | Name: | Location: | Need:'),
        (l.frTplCheckIn, 'CHECK-IN | Name: | Location: | Status:'),
        (l.frTplAllClear, 'ALL CLEAR | Name: | Location: | Details:'),
      ];

  @override
  void dispose() { note.dispose(); message.dispose(); super.dispose(); }

  Future<void> action(Future<void> Function() operation, String success) async {
    setState(() { busy = true; status = null; });
    try { await operation(); if (mounted) setState(() => status = success); }
    catch (error) { if (mounted) setState(() => status = '$error'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  /// Fills the message box from a guided form; sending still goes through review.
  Future<void> fillReport(BastionReportTemplate template) async {
    final radio = widget.radio;
    final me = radio.nodes.where((n) => n.num == radio.localNodeNum && n.hasPosition).firstOrNull;
    final now = TimeOfDay.now();
    final text = await showDialog<String>(context: context, builder: (_) => _ReportDialog(
      template: template,
      position: me == null ? null : '${me.latitude!.toStringAsFixed(5)}, ${me.longitude!.toStringAsFixed(5)}',
      time: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    ));
    if (mounted && text != null) setState(() => message.text = text);
  }

  Future<void> send() async {
    final l = this.l;
    final text = message.text.trim();
    if (text.isEmpty || utf8.encode(text).length > 220) {
      setState(() => status = l.frTooLong); return;
    }
    final node = widget.radio.localNodeNum;
    final selected = channel;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(l.frBroadcastQ(selected)),
      content: SingleChildScrollView(child: Text('$text\n\n${l.frNoProof}')),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.frSendMessage))],
    ));
    if (!mounted || confirmed != true) return;
    await action(() async {
      if (!widget.radio.isReady || widget.radio.localNodeNum != node ||
          !widget.radio.channelMetadata.any((c) => c.index == selected && c.role != 0)) {
        throw StateError(l.frChanged);
      }
      await widget.radio.sendText(text: text, channel: selected);
    }, l.frSubmitted);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l.frTitle)),
    body: SafeArea(top: false, child: AnimatedBuilder(
      animation: Listenable.merge([widget.radio, BastionFieldLog.instance, BastionBotGuard.instance]),
      builder: (context, _) {
        final log = BastionFieldLog.instance;
        final guard = BastionBotGuard.instance;
        final channels = widget.radio.channelMetadata.where((c) => c.role != 0).toList();
        return ListView(padding: const EdgeInsets.all(16), children: [
          if (status != null) Semantics(liveRegion: true, child: Padding(padding: const EdgeInsets.all(8), child: Text(status!))),
          if (log.error != null) ListTile(leading: const Icon(Icons.error_outline), title: Text(log.error!)),
          Card(key: const ValueKey('incident-log'), child: ExpansionTile(initiallyExpanded: true,
            title: Text(l.frIncidentLog), subtitle: Text(l.frIncidentLogSub), childrenPadding: const EdgeInsets.all(16), children: [
              TextField(controller: note, maxLength: 1000, minLines: 2, maxLines: 5,
                decoration: InputDecoration(labelText: l.frIncidentField)),
              FilledButton(onPressed: busy ? null : () => action(() async {
                await log.addIncident(note.text, radio: widget.radio.localNodeNum); note.clear();
              }, l.frIncidentSaved), child: Text(l.frSaveIncident)),
              TextButton(onPressed: () => action(() => Clipboard.setData(ClipboardData(text: log.exportCsv('incident'))),
                l.frIncidentCopied), child: Text(l.frCopyIncident)),
              for (final r in log.records.where((r) => r['kind'] == 'incident').toList().reversed)
                ListTile(title: Text(r['note']! as String), subtitle: Text(l.frRadioOf('${r['time']}', '${r['radio'] ?? l.frUnassigned}')),
                  trailing: IconButton(tooltip: l.frRemoveIncident, icon: const Icon(Icons.delete_outline), onPressed: () async {
                    final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
                      title: Text(l.frRemoveIncidentQ), content: Text(r['note']! as String), actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.frKeep)),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.frRemove))]));
                    if (!mounted || yes != true) return;
                    await action(() => log.removeIncident(r), l.frIncidentRemoved);
                  })),
            ])),
          Card(key: const ValueKey('message-templates'), child: ExpansionTile(title: Text(l.frTemplates),
            subtitle: Text(l.frTemplatesSub),
            childrenPadding: const EdgeInsets.all(16), children: [
              Wrap(spacing: 8, children: [for (final (label, body) in templates)
                OutlinedButton(onPressed: () => setState(() => message.text = body), child: Text(label)),
                for (final r in BastionReportTemplate.all)
                  OutlinedButton(key: ValueKey('report-${r.tag}'), onPressed: () => fillReport(r), child: Text(r.title))]),
              TextField(controller: message, minLines: 3, maxLines: 6,
                decoration: InputDecoration(labelText: l.frMessageField)),
              DropdownButtonFormField<int>(initialValue: channels.any((c) => c.index == channel) ? channel : null,
                decoration: InputDecoration(labelText: l.frBroadcastChannel),
                items: [for (final c in channels) DropdownMenuItem(value: c.index, child: Text(l.frChannelItem(c.index, c.name)))],
                onChanged: (v) { if (v != null) setState(() => channel = v); }),
              const SizedBox(height: 12),
              FilledButton(onPressed: busy || !widget.radio.isReady || channels.isEmpty ? null : send,
                child: Text(l.frReview)),
              Text(l.frNotEmergency),
            ])),
          Card(key: const ValueKey('coverage-log'), child: ExpansionTile(title: Text(l.frCoverage),
            subtitle: Text(l.frCoverageSub),
            childrenPadding: const EdgeInsets.all(16), children: [
              SwitchListTile(title: Text(l.frRecord),
                subtitle: Text(l.frRecordSub),
                value: widget.radio.recordingCoverage,
                onChanged: busy || (!widget.radio.isReady && !widget.radio.recordingCoverage) ? null
                  : (v) => action(() => widget.radio.setCoverageRecording(v), v ? l.frRecordOn : l.frRecordOff)),
              if (widget.radio.coverageProblem != null) Text(widget.radio.coverageProblem!),
              Text(l.frReadings(log.records.where((r) => r['kind'] == 'coverage').length)),
              TextButton(onPressed: () => action(() => Clipboard.setData(ClipboardData(text: log.exportCsv('coverage'))),
                l.frCoverageCopied), child: Text(l.frCopyCoverage)),
              for (final r in log.records.where((r) => r['kind'] == 'coverage').toList().reversed.take(50))
                ListTile(title: Text('Node ${r['from']} • SNR ${r['snr'] ?? '—'} • RSSI ${r['rssi'] ?? '—'}'),
                  subtitle: Text('${r['time']}\nReceiver ${r['lat']}, ${r['lon']} • Radio ${r['radio']}')),
            ])),
          Card(key: const ValueKey('bot-safeguards'), child: ExpansionTile(title: Text(l.frBot),
            subtitle: Text(l.frBotSub),
            children: [
              ListTile(title: Text(l.frBotEnable),
                subtitle: Text(l.frBotRules)),
              SwitchListTile(title: Text(l.frQuiet), value: guard.quietEnabled,
                onChanged: (v) => guard.update(quiet: v)),
              for (final isStart in [true, false]) Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<int>(initialValue: isStart ? guard.quietStart : guard.quietEnd,
                  decoration: InputDecoration(labelText: isStart ? l.frQuietStart : l.frQuietEnd),
                  items: [for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00'))],
                  onChanged: (v) { if (v != null) { guard.update(start: isStart ? v : null, end: isStart ? null : v); } })),
              Padding(padding: const EdgeInsets.all(16), child: DropdownButtonFormField<int>(initialValue: guard.channel,
                decoration: InputDecoration(labelText: l.frBotChannel),
                items: [for (var i = 0; i < 8; i++) DropdownMenuItem(value: i, child: Text(l.frChannelN(i)))],
                onChanged: (v) { if (v != null) { guard.update(selectedChannel: v); } })),
              if (guard.error != null) ListTile(title: Text(guard.error!)),
            ])),
        ]);
      },
    )),
  );
}

/// Guided form for one report, showing how much of the message is used.
class _ReportDialog extends StatefulWidget {
  const _ReportDialog({required this.template, this.position, required this.time});
  final BastionReportTemplate template;
  final String? position;
  final String time;
  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  late final Map<String, TextEditingController> fields = {
    for (final f in widget.template.fields) f.code: TextEditingController(text: _prefill(f)),
  };

  String _prefill(BastionReportField f) => switch ((widget.template.tag, f.code)) {
        ('SALUTE', 'L') || ('9LINE', '1') => widget.position ?? '',
        ('SALUTE', 'T') => widget.time,
        _ => '',
      };

  @override
  void dispose() {
    for (final c in fields.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.template.compose({for (final e in fields.entries) e.key: e.value.text});
    final bytes = BastionReportTemplate.bytesOf(text);
    final over = bytes > BastionReportTemplate.maxBytes;
    final scheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.template.title),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final f in widget.template.fields)
          TextField(key: ValueKey('report-field-${f.code}'), controller: fields[f.code],
            decoration: InputDecoration(labelText: '${f.code}. ${f.label}', hintText: f.hint),
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 12),
        Text(over ? l.frBytesOver(bytes, BastionReportTemplate.maxBytes)
                  : l.frBytes(bytes, BastionReportTemplate.maxBytes),
          style: TextStyle(color: over ? scheme.error : scheme.onSurfaceVariant)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(onPressed: text.isEmpty || over ? null : () => Navigator.pop(context, text), child: Text(l.frUseReport)),
      ],
    );
  }
}
