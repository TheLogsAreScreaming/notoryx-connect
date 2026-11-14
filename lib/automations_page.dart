import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_automations.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// Short weekday names, Monday first, in the phone's language.
List<String> _weekdays(BuildContext context) {
  final format = DateFormat.E(Localizations.localeOf(context).toLanguageTag());
  // 2024-01-01 was a Monday.
  return [for (var d = 0; d < 7; d++) format.format(DateTime(2024, 1, 1 + d))];
}

/// Words for a trigger, as the lists and editor show it.
String describeTrigger(BuildContext context, AutoTrigger t, MeshtasticRadioCoordinator radio) {
  final l = AppLocalizations.of(context);
  switch (t) {
    case BatteryTrigger(:final node, :final below):
      return l.auTrigBattery(radio.nodeName(node), below);
    case TimeTrigger(:final hour, :final minute, :final weekdays):
      final time = '${_two(hour)}:${_two(minute)}';
      if (weekdays.isEmpty) return l.auTrigTime(time);
      final names = _weekdays(context);
      return l.auTrigTimeDays(time, [for (final d in weekdays.toList()..sort()) names[d - 1]].join(', '));
    case GeofenceTrigger(:final zone, :final enter, :final node):
      final name = radio.geofences.where((z) => z.id == zone).firstOrNull?.name ?? l.auZoneMissing;
      final who = node == null ? l.auAnyNode : radio.nodeName(node);
      return enter ? l.auTrigZoneEnter(who, name) : l.auTrigZoneLeave(who, name);
    case MessageTrigger(:final contains, :final channel, :final directOnly):
      final base = contains.trim().isEmpty ? l.auTrigMessageAny : l.auTrigMessageHas(contains.trim());
      if (directOnly) return '$base · ${l.auDirect}';
      if (channel != null) return '$base · ${l.auChannelN(channel)}';
      return base;
    case PresenceTrigger(:final node, :final online, :final after):
      return online
          ? l.auTrigOnline(radio.nodeName(node), after.inMinutes)
          : l.auTrigOffline(radio.nodeName(node), after.inMinutes);
  }
}

/// Words for an action, as the lists and editor show it.
String describeAction(BuildContext context, AutoAction a, MeshtasticRadioCoordinator radio) {
  final l = AppLocalizations.of(context);
  return switch (a) {
    SendAction(:final destination, :final channel, :final text) => l.auActSend(
      destination == automationBroadcast ? l.auChannelN(channel) : radio.nodeName(destination),
      text,
    ),
    AlertAction(:final text) => l.auActAlert(text),
    JoinChannelAction() => l.auKindChannel,
    SoundAction() => l.auKindSound,
    WebhookAction(:final url) => l.auActWebhook(Uri.tryParse(url)?.host ?? url),
  };
}

/// Lists the automations, the web-request switch and what ran lately.
class AutomationsPage extends StatelessWidget {
  const AutomationsPage({super.key, required this.engine, required this.radio});

  final AutomationEngine engine;

  /// Names nodes, zones and channels in the editor.
  final MeshtasticRadioCoordinator radio;

  void _edit(BuildContext context, [Automation? rule]) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AutomationEditorPage(engine: engine, radio: radio, rule: rule),
    ),
  );

  String _problem(AppLocalizations l, AutoRun run) => switch (run.problem) {
    AutoProblem.notConnected => l.auProblemNotConnected,
    AutoProblem.webOff => l.auProblemWebOff,
    AutoProblem.httpError => l.auProblemHttp(run.status ?? 0),
    AutoProblem.failed || null => l.auProblemFailed,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final time = DateFormat.Hm(Localizations.localeOf(context).toLanguageTag());
    return Scaffold(
      appBar: AppBar(title: Text(l.auTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('automations-new'),
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: Text(l.auNew),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([engine, radio]),
        builder: (context, _) {
          final settings = engine.settings;
          return ListView(
            padding: NxSpace.page.copyWith(bottom: 96),
            children: [
              NxPageHeader(title: l.auTitle, subtitle: l.auSubtitle),
              if (engine.storageProblem)
                Card(
                  child: ListTile(
                    leading: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                    title: Text(l.auStorageProblem),
                  ),
                ),
              if (!radio.isReady)
                Card(
                  child: ListTile(leading: const Icon(Icons.link_off), title: Text(l.auNotReady)),
                ),
              Card(
                child: SwitchListTile(
                  key: const ValueKey('automations-webhooks'),
                  secondary: const Icon(Icons.public),
                  title: Text(l.auWebhooks),
                  subtitle: Text(l.auWebhooksSub),
                  value: settings.webhooks,
                  onChanged: (on) => engine.save(settings.copyWith(webhooks: on)),
                ),
              ),
              NxSectionLabel(l.auRules),
              if (settings.rules.isEmpty) Padding(padding: const EdgeInsets.all(NxSpace.md), child: Text(l.auEmpty)),
              for (final rule in settings.rules)
                Card(
                  child: ListTile(
                    key: ValueKey('automation-${rule.id}'),
                    title: Text(rule.name),
                    subtitle: Text(
                      [
                        (rule.matchAll ? l.auWhenAll : l.auWhenAny)(
                          [for (final t in rule.triggers) describeTrigger(context, t, radio)].join('; '),
                        ),
                        l.auThen([for (final a in rule.actions) describeAction(context, a, radio)].join('; ')),
                        if (rule.needsInternet) l.auNeedsInternet,
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                    onTap: () => _edit(context, rule),
                    // The switch names its rule for screen readers.
                    trailing: Semantics(
                      label: l.auToggle(rule.name),
                      child: Switch(
                        value: rule.enabled,
                        onChanged: (on) => engine.save(
                          settings.copyWith(
                            rules: [for (final r in settings.rules) r.id == rule.id ? r.copyWith(enabled: on) : r],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              NxSectionLabel(l.auActivity),
              if (engine.log.isEmpty)
                Padding(padding: const EdgeInsets.all(NxSpace.md), child: Text(l.auNoActivity))
              else
                for (final run in engine.log.take(20))
                  ListTile(
                    dense: true,
                    leading: Icon(
                      run.ok ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                      color: run.ok ? null : Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      run.ok
                          ? l.auRunOk(run.rule, describeAction(context, run.action, radio))
                          : l.auRunFailed(run.rule, describeAction(context, run.action, radio), _problem(l, run)),
                    ),
                    subtitle: Text(time.format(run.time)),
                  ),
            ],
          );
        },
      ),
    );
  }
}

/// Creates or changes one automation.
class AutomationEditorPage extends StatefulWidget {
  const AutomationEditorPage({super.key, required this.engine, required this.radio, this.rule});

  final AutomationEngine engine;
  final MeshtasticRadioCoordinator radio;

  /// The rule to change, or null for a new one.
  final Automation? rule;

  @override
  State<AutomationEditorPage> createState() => _AutomationEditorPageState();
}

enum _TriggerKind { battery, time, zone, message, presence }

enum _ActionKind { send, alert, channel, sound, webhook }

class _AutomationEditorPageState extends State<AutomationEditorPage> {
  late final _name = TextEditingController(text: widget.rule?.name ?? '');
  late bool _matchAll = widget.rule?.matchAll ?? false;
  late final List<AutoTrigger> _triggers = [...?widget.rule?.triggers];
  late final List<AutoAction> _actions = [...?widget.rule?.actions];
  late int _cooldown = widget.rule?.cooldown.inMinutes ?? 5;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _complete => _name.text.trim().isNotEmpty && _triggers.isNotEmpty && _actions.isNotEmpty;

  Future<void> _save() async {
    final settings = widget.engine.settings;
    final rule = Automation(
      id: widget.rule?.id ?? settings.nextId,
      name: _name.text.trim(),
      enabled: widget.rule?.enabled ?? true,
      matchAll: _matchAll,
      triggers: _triggers,
      actions: _actions,
      cooldown: Duration(minutes: _cooldown),
    );
    final rules = widget.rule == null
        ? [...settings.rules, rule]
        : [for (final r in settings.rules) r.id == rule.id ? rule : r];
    await widget.engine.save(settings.copyWith(rules: rules));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final settings = widget.engine.settings;
    await widget.engine.save(
      settings.copyWith(
        rules: [
          for (final r in settings.rules)
            if (r.id != widget.rule!.id) r,
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  String _triggerKindName(AppLocalizations l, _TriggerKind k) => switch (k) {
    _TriggerKind.battery => l.auKindBattery,
    _TriggerKind.time => l.auKindTime,
    _TriggerKind.zone => l.auKindZone,
    _TriggerKind.message => l.auKindMessage,
    _TriggerKind.presence => l.auKindPresence,
  };

  String _actionKindName(AppLocalizations l, _ActionKind k) => switch (k) {
    _ActionKind.send => l.auKindSend,
    _ActionKind.alert => l.auKindAlert,
    _ActionKind.channel => l.auKindChannel,
    _ActionKind.sound => l.auKindSound,
    _ActionKind.webhook => l.auKindWebhook,
  };

  Future<void> _addTrigger(_TriggerKind kind) async {
    final t = await showDialog<AutoTrigger>(
      context: context,
      builder: (_) => _TriggerDialog(kind: kind, radio: widget.radio),
    );
    if (t != null) setState(() => _triggers.add(t));
  }

  Future<void> _addAction(_ActionKind kind) async {
    if (kind == _ActionKind.sound) {
      setState(() => _actions.add(const SoundAction()));
      return;
    }
    final a = await showDialog<AutoAction>(
      context: context,
      builder: (_) => _ActionDialog(kind: kind, radio: widget.radio, webhooksOn: widget.engine.settings.webhooks),
    );
    if (a != null) setState(() => _actions.add(a));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.rule == null ? l.auNew : l.auEdit),
        actions: [
          TextButton(
            key: const ValueKey('automation-save'),
            onPressed: _complete ? _save : null,
            child: Text(l.auSave),
          ),
        ],
      ),
      body: ListView(
        padding: NxSpace.page,
        children: [
          TextField(
            key: const ValueKey('automation-name'),
            controller: _name,
            maxLength: 40,
            decoration: InputDecoration(labelText: l.auName),
            onChanged: (_) => setState(() {}),
          ),
          if (!_complete)
            Padding(
              padding: const EdgeInsets.only(bottom: NxSpace.sm),
              child: Text(l.auNeedAll, style: Theme.of(context).textTheme.bodySmall),
            ),
          Text(l.auMatch, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: NxSpace.xs),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l.auMatchAny)),
              ButtonSegment(value: true, label: Text(l.auMatchAll)),
            ],
            selected: {_matchAll},
            onSelectionChanged: (s) => setState(() => _matchAll = s.first),
          ),
          NxSectionLabel(l.auTriggers),
          for (final (i, t) in _triggers.indexed)
            Card(
              child: ListTile(
                title: Text(describeTrigger(context, t, widget.radio)),
                trailing: IconButton(
                  tooltip: l.auRemove,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _triggers.removeAt(i)),
                ),
              ),
            ),
          _AddMenu<_TriggerKind>(
            key: const ValueKey('automation-add-trigger'),
            label: l.auAddTrigger,
            items: {for (final k in _TriggerKind.values) k: _triggerKindName(l, k)},
            onPick: _addTrigger,
          ),
          NxSectionLabel(l.auActions),
          for (final (i, a) in _actions.indexed)
            Card(
              child: ListTile(
                title: Text(describeAction(context, a, widget.radio)),
                subtitle: a.needsInternet
                    ? Text(widget.engine.settings.webhooks ? l.auNeedsInternet : l.auWebOffNote)
                    : null,
                trailing: IconButton(
                  tooltip: l.auRemove,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _actions.removeAt(i)),
                ),
              ),
            ),
          _AddMenu<_ActionKind>(
            key: const ValueKey('automation-add-action'),
            label: l.auAddAction,
            items: {for (final k in _ActionKind.values) k: _actionKindName(l, k)},
            onPick: _addAction,
          ),
          const SizedBox(height: NxSpace.md),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: _cooldown,
            decoration: InputDecoration(labelText: l.auCooldown),
            items: [
              for (final m in {...Automation.cooldownChoices, _cooldown}.toList()..sort())
                DropdownMenuItem(value: m, child: Text(l.auMinutes(m))),
            ],
            onChanged: (m) => setState(() => _cooldown = m ?? _cooldown),
          ),
          if (widget.rule != null) ...[
            const SizedBox(height: NxSpace.lg),
            OutlinedButton.icon(onPressed: _delete, icon: const Icon(Icons.delete_outline), label: Text(l.auDelete)),
          ],
        ],
      ),
    );
  }
}

class _AddMenu<T> extends StatelessWidget {
  const _AddMenu({super.key, required this.label, required this.items, required this.onPick});

  final String label;
  final Map<T, String> items;
  final void Function(T) onPick;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: PopupMenuButton<T>(
      tooltip: label,
      onSelected: onPick,
      itemBuilder: (_) => [for (final e in items.entries) PopupMenuItem(value: e.key, child: Text(e.value))],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: NxSpace.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: NxSpace.xs),
            Text(label, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      ),
    ),
  );
}

/// Picks a node from the ones the radio knows, keeping [current] if it has
/// gone from the list.
Widget _nodePicker(
  BuildContext context,
  MeshtasticRadioCoordinator radio,
  int? current,
  ValueChanged<int?> onChanged, {
  bool allowAny = false,
}) {
  final l = AppLocalizations.of(context);
  final nodes = [
    for (final n in radio.nodes)
      if (n.num != radio.localNodeNum) n,
  ]..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  return DropdownButtonFormField<int?>(
    initialValue: current,
    isExpanded: true,
    decoration: InputDecoration(labelText: l.auNode),
    items: [
      if (allowAny) DropdownMenuItem<int?>(value: null, child: Text(l.auAnyNode)),
      if (current != null && !nodes.any((n) => n.num == current))
        DropdownMenuItem<int?>(value: current, child: Text(radio.nodeName(current))),
      for (final n in nodes) DropdownMenuItem<int?>(value: n.num, child: Text(n.displayName)),
    ],
    onChanged: onChanged,
  );
}

Widget _channelPicker(
  BuildContext context,
  MeshtasticRadioCoordinator radio,
  int current,
  ValueChanged<int> onChanged,
) {
  final l = AppLocalizations.of(context);
  final known = {
    for (final c in radio.channelMetadata)
      if (c.role != 0) c.index: c.name,
  };
  return DropdownButtonFormField<int>(
    isExpanded: true,
    initialValue: current,
    decoration: InputDecoration(labelText: l.auChannel),
    items: [
      for (var i = 0; i < 8; i++)
        DropdownMenuItem(
          value: i,
          child: Text((known[i] ?? '').isNotEmpty ? '${l.auChannelN(i)} · ${known[i]}' : l.auChannelN(i)),
        ),
    ],
    onChanged: (v) => onChanged(v ?? current),
  );
}

class _TriggerDialog extends StatefulWidget {
  const _TriggerDialog({required this.kind, required this.radio});
  final _TriggerKind kind;
  final MeshtasticRadioCoordinator radio;

  @override
  State<_TriggerDialog> createState() => _TriggerDialogState();
}

class _TriggerDialogState extends State<_TriggerDialog> {
  int? _node;
  int _below = 20;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  final Set<int> _days = {};
  late String? _zone = widget.radio.geofences.firstOrNull?.id;
  bool _enter = true;
  final _contains = TextEditingController();
  int? _channel;
  bool _direct = false;
  bool _online = false;
  int _after = 30;

  @override
  void dispose() {
    _contains.dispose();
    super.dispose();
  }

  AutoTrigger? get _result => switch (widget.kind) {
    _TriggerKind.battery => _node == null ? null : BatteryTrigger(node: _node!, below: _below),
    _TriggerKind.time => TimeTrigger(hour: _time.hour, minute: _time.minute, weekdays: {..._days}),
    _TriggerKind.zone => _zone == null ? null : GeofenceTrigger(zone: _zone!, enter: _enter, node: _node),
    _TriggerKind.message => MessageTrigger(
      contains: _contains.text.trim(),
      channel: _direct ? null : _channel,
      directOnly: _direct,
    ),
    _TriggerKind.presence =>
      _node == null
          ? null
          : PresenceTrigger(
              node: _node!,
              online: _online,
              after: Duration(minutes: _after),
            ),
  };

  List<Widget> _fields(AppLocalizations l) {
    final radio = widget.radio;
    switch (widget.kind) {
      case _TriggerKind.battery:
        return [
          _nodePicker(context, radio, _node, (v) => setState(() => _node = v)),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: _below,
            decoration: InputDecoration(labelText: l.auBelow),
            items: [
              for (final p in const [10, 15, 20, 30, 50]) DropdownMenuItem(value: p, child: Text('$p%')),
            ],
            onChanged: (v) => setState(() => _below = v ?? _below),
          ),
        ];
      case _TriggerKind.time:
        final names = _weekdays(context);
        return [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: Text(l.auTime),
            trailing: Text(_time.format(context)),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _time);
              if (picked != null) setState(() => _time = picked);
            },
          ),
          Text(l.auDays, style: Theme.of(context).textTheme.bodySmall),
          Wrap(
            spacing: NxSpace.xxs,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(names[d - 1]),
                  selected: _days.contains(d),
                  onSelected: (on) => setState(() => on ? _days.add(d) : _days.remove(d)),
                ),
            ],
          ),
        ];
      case _TriggerKind.zone:
        if (radio.geofences.isEmpty) return [Text(l.auNoZones)];
        return [
          DropdownButtonFormField<String>(
            initialValue: _zone,
            isExpanded: true,
            decoration: InputDecoration(labelText: l.auZone),
            items: [for (final z in radio.geofences) DropdownMenuItem(value: z.id, child: Text(z.name))],
            onChanged: (v) => setState(() => _zone = v),
          ),
          _nodePicker(context, radio, _node, (v) => setState(() => _node = v), allowAny: true),
          const SizedBox(height: NxSpace.sm),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(l.auEnters)),
              ButtonSegment(value: false, label: Text(l.auLeaves)),
            ],
            selected: {_enter},
            onSelectionChanged: (s) => setState(() => _enter = s.first),
          ),
        ];
      case _TriggerKind.message:
        return [
          TextField(
            controller: _contains,
            decoration: InputDecoration(labelText: l.auContains),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.auDirect),
            value: _direct,
            onChanged: (v) => setState(() => _direct = v),
          ),
          if (!_direct)
            DropdownButtonFormField<int?>(
              isExpanded: true,
              initialValue: _channel,
              decoration: InputDecoration(labelText: l.auChannel),
              items: [
                DropdownMenuItem<int?>(value: null, child: Text(l.auAnywhere)),
                for (var i = 0; i < 8; i++) DropdownMenuItem<int?>(value: i, child: Text(l.auChannelN(i))),
              ],
              onChanged: (v) => setState(() => _channel = v),
            ),
        ];
      case _TriggerKind.presence:
        return [
          _nodePicker(context, radio, _node, (v) => setState(() => _node = v)),
          const SizedBox(height: NxSpace.sm),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l.auGoesQuiet)),
              ButtonSegment(value: true, label: Text(l.auComesBack)),
            ],
            selected: {_online},
            onSelectionChanged: (s) => setState(() => _online = s.first),
          ),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: _after,
            decoration: InputDecoration(labelText: l.auAfter),
            items: [
              for (final m in const [15, 30, 60, 120, 360]) DropdownMenuItem(value: m, child: Text(l.auMinutes(m))),
            ],
            onChanged: (v) => setState(() => _after = v ?? _after),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final result = _result;
    return AlertDialog(
      title: Text(switch (widget.kind) {
        _TriggerKind.battery => l.auKindBattery,
        _TriggerKind.time => l.auKindTime,
        _TriggerKind.zone => l.auKindZone,
        _TriggerKind.message => l.auKindMessage,
        _TriggerKind.presence => l.auKindPresence,
      }),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _fields(l),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.auCancel)),
        FilledButton(
          key: const ValueKey('automation-dialog-add'),
          onPressed: result == null ? null : () => Navigator.pop(context, result),
          child: Text(l.auAdd),
        ),
      ],
    );
  }
}

class _ActionDialog extends StatefulWidget {
  const _ActionDialog({required this.kind, required this.radio, required this.webhooksOn});
  final _ActionKind kind;
  final MeshtasticRadioCoordinator radio;
  final bool webhooksOn;

  @override
  State<_ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<_ActionDialog> {
  final _text = TextEditingController();
  bool _toChannel = true;
  int _channel = 0;
  int? _node;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  AutoAction? get _result {
    final text = _text.text.trim();
    switch (widget.kind) {
      case _ActionKind.send:
        if (text.isEmpty || (!_toChannel && _node == null)) return null;
        return SendAction(destination: _toChannel ? automationBroadcast : _node!, channel: _channel, text: text);
      case _ActionKind.alert:
        return text.isEmpty ? null : AlertAction(text);
      case _ActionKind.channel:
        return JoinChannelAction.validLink(text) ? JoinChannelAction(text) : null;
      case _ActionKind.webhook:
        return WebhookAction.validUrl(text) ? WebhookAction(text) : null;
      case _ActionKind.sound:
        return const SoundAction();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fill = l.auPlaceholders('{node}, {battery}, {zone}, {time}, {text}, {rule}');
    final text = _text.text.trim();
    final result = _result;
    final fields = switch (widget.kind) {
      _ActionKind.send => [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(l.auEveryone)),
            ButtonSegment(value: false, label: Text(l.auOneNode)),
          ],
          selected: {_toChannel},
          onSelectionChanged: (s) => setState(() => _toChannel = s.first),
        ),
        if (!_toChannel) _nodePicker(context, widget.radio, _node, (v) => setState(() => _node = v)),
        _channelPicker(context, widget.radio, _channel, (v) => setState(() => _channel = v)),
        TextField(
          controller: _text,
          maxLength: 180,
          decoration: InputDecoration(labelText: l.auMessage, helperText: fill, helperMaxLines: 3),
        ),
      ],
      _ActionKind.alert => [
        TextField(
          controller: _text,
          decoration: InputDecoration(labelText: l.auAlertText, helperText: fill, helperMaxLines: 3),
        ),
      ],
      _ActionKind.channel => [
        TextField(
          controller: _text,
          decoration: InputDecoration(
            labelText: l.auLink,
            helperText: l.auLinkHint,
            helperMaxLines: 3,
            errorText: text.isNotEmpty && result == null ? l.auBadLink : null,
          ),
        ),
      ],
      _ActionKind.webhook => [
        TextField(
          controller: _text,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: l.auUrl,
            helperText: widget.webhooksOn ? l.auNeedsInternet : l.auWebOffNote,
            helperMaxLines: 3,
            errorText: text.isNotEmpty && result == null ? l.auBadUrl : null,
          ),
        ),
      ],
      _ActionKind.sound => <Widget>[],
    };
    return AlertDialog(
      title: Text(switch (widget.kind) {
        _ActionKind.send => l.auKindSend,
        _ActionKind.alert => l.auKindAlert,
        _ActionKind.channel => l.auKindChannel,
        _ActionKind.sound => l.auKindSound,
        _ActionKind.webhook => l.auKindWebhook,
      }),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final f in fields)
              Padding(
                padding: const EdgeInsets.only(bottom: NxSpace.xs),
                child: f,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.auCancel)),
        FilledButton(
          key: const ValueKey('automation-dialog-add'),
          onPressed: result == null ? null : () => Navigator.pop(context, result),
          child: Text(l.auAdd),
        ),
      ],
    );
  }
}
