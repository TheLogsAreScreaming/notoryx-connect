import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:protobuf/protobuf.dart';

import 'generated/meshtastic/admin.pb.dart';
import 'generated/meshtastic/config.pb.dart';
import 'generated/meshtastic/mesh.pb.dart';
import 'proto_form.dart';
import 'services/bastion_node_identity_validation.dart';
import 'services/meshtastic_admin_session.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// One settings section that can be read and written on a remote node.
class RemoteConfigSection {
  const RemoteConfigSection(this.label, this.type, this.read, this.wrap, {this.risky = false});

  final String label;
  final AdminMessage_ConfigType type;
  final GeneratedMessage Function(Config) read;
  final Config Function(GeneratedMessage) wrap;

  /// A wrong value can cut the node off the mesh until someone reaches it.
  final bool risky;

  static final all = <RemoteConfigSection>[
    RemoteConfigSection('Device', AdminMessage_ConfigType.DEVICE_CONFIG,
        (c) => c.device, (m) => Config(device: m as Config_DeviceConfig)),
    RemoteConfigSection('Position', AdminMessage_ConfigType.POSITION_CONFIG,
        (c) => c.position, (m) => Config(position: m as Config_PositionConfig)),
    RemoteConfigSection('Power', AdminMessage_ConfigType.POWER_CONFIG,
        (c) => c.power, (m) => Config(power: m as Config_PowerConfig)),
    RemoteConfigSection('Display', AdminMessage_ConfigType.DISPLAY_CONFIG,
        (c) => c.display, (m) => Config(display: m as Config_DisplayConfig)),
    RemoteConfigSection('LoRa', AdminMessage_ConfigType.LORA_CONFIG,
        (c) => c.lora, (m) => Config(lora: m as Config_LoRaConfig), risky: true),
  ];
}

/// Reads and changes another node's settings over the mesh.
///
/// Every request costs airtime, so nothing is fetched until asked. The node
/// only answers if this radio's public key is one of its admin keys.
class RemoteAdminPage extends StatefulWidget {
  const RemoteAdminPage({
    super.key,
    required this.radio,
    required this.nodeNum,
    this.openSession,
  });

  final MeshtasticRadioCoordinator radio;
  final int nodeNum;

  /// Replaces [MeshtasticRadioCoordinator.openRemoteAdmin], for tests.
  final MeshtasticAdminSession Function()? openSession;

  @override
  State<RemoteAdminPage> createState() => _RemoteAdminPageState();
}

class _RemoteAdminPageState extends State<RemoteAdminPage> {
  MeshtasticAdminSession? _session;
  String? _openProblem;
  bool _working = false;
  String? _error;
  DeviceMetadata? _metadata;
  User? _owner;
  RemoteConfigSection? _section;
  GeneratedMessage? _draft;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    try {
      _session = widget.openSession?.call() ?? widget.radio.openRemoteAdmin(widget.nodeNum);
    } on StateError catch (e) {
      _openProblem = e.message;
    }
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  String get _nodeName {
    for (final n in widget.radio.nodes) {
      if (n.num == widget.nodeNum) return n.longName ?? n.shortName ?? _hexId;
    }
    return _hexId;
  }

  String get _hexId => '!${widget.nodeNum.toRadixString(16).padLeft(8, '0')}';

  Future<T?> _call<T>(Future<T> Function(MeshtasticAdminSession s) action) async {
    final session = _session;
    if (session == null || _working) return null;
    setState(() { _working = true; _error = null; });
    try {
      return await action(session);
    } on MeshtasticAdminException catch (e) {
      if (mounted) setState(() => _error = e.plainReason);
    } on MeshtasticSettingsUnavailable catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
    return null;
  }

  void _toast(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _checkAccess() async {
    final metadata = await _call((s) => s.getMetadata());
    final owner = metadata == null ? null : await _call((s) => s.getOwner());
    if (!mounted || metadata == null) return;
    setState(() { _metadata = metadata; _owner = owner; });
  }

  Future<void> _openSection(RemoteConfigSection section) async {
    final config = await _call((s) => s.getConfig(section.type));
    if (!mounted || config == null) return;
    setState(() {
      _section = section;
      _draft = section.read(config).deepCopy();
      _dirty = false;
    });
  }

  Future<void> _saveSection() async {
    final section = _section;
    final draft = _draft;
    if (section == null || draft == null) return;
    if (section.risky && !await _confirm(
      'Change LoRa settings remotely?',
      'If the node ends up on a different region, preset or frequency from the rest of the mesh, '
      'it can no longer be reached and someone will have to fix it in person.',
      'Save anyway',
    )) {
      return;
    }
    final saved = await _call((s) async { await s.setConfig(section.wrap(draft)); return true; });
    if (saved == true) {
      setState(() => _dirty = false);
      _toast('${section.label} settings sent. The node may restart to apply them.');
    }
  }

  Future<void> _editOwner() async {
    final owner = _owner;
    if (owner == null) return;
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _OwnerDialog(longName: owner.longName, shortName: owner.shortName),
    );
    if (result == null) return;
    final updated = owner.deepCopy()
      ..longName = result.$1
      ..shortName = result.$2;
    final saved = await _call((s) async { await s.setOwner(updated); return true; });
    if (saved == true) {
      setState(() => _owner = updated);
      _toast('Name sent to the node.');
    }
  }

  Future<void> _reboot() async {
    if (!await _confirm('Restart $_nodeName?',
        'The node goes off the mesh for a short while as it restarts.', 'Restart')) {
      return;
    }
    final sent = await _call((s) async { await s.reboot(); return true; });
    if (sent == true) _toast('Restart requested.');
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(action)),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final section = _section;
    final draft = _draft;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirm('Discard changes?', 'Your edits haven\'t been sent to the node.', 'Discard')) {
          setState(() => _dirty = false);
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Remote admin')),
        body: ListView(padding: NxSpace.page, children: [
          NxPageHeader(
            title: _nodeName,
            subtitle: 'Change this node\'s settings over the mesh. Each request uses airtime and can take up to a minute.',
          ),
          if (_openProblem != null)
            NxBanner(tone: NxTone.warning, title: 'Remote admin isn\'t available', message: _openProblem!)
          else ...[
            _AdminKeyCard(publicKey: widget.radio.localPublicKey, nodeName: _nodeName),
            if (_working) Padding(
              padding: const EdgeInsets.symmetric(vertical: NxSpace.xs),
              child: Semantics(label: 'Waiting for the node', child: const LinearProgressIndicator()),
            ),
            if (_error != null) NxBanner(tone: NxTone.danger, message: _error!),
            NxSectionLabel('Access'),
            if (_metadata == null)
              NxGroupCard(padding: const EdgeInsets.all(NxSpace.md), children: [
                const Text('Ask the node for its details. If it answers, your radio is allowed to manage it.'),
                const SizedBox(height: NxSpace.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.icon(
                    onPressed: _working ? null : _checkAccess,
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Check access'),
                  ),
                ),
              ])
            else ...[
              NxGroupCard(children: [
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: const Text('Access confirmed'),
                  subtitle: Text('Firmware ${_metadata!.firmwareVersion.isEmpty ? 'unknown' : _metadata!.firmwareVersion}'
                      ' · ${_metadata!.role.name.replaceAll('_', ' ').toLowerCase()}'),
                ),
                if (_owner != null) ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(_owner!.longName.isEmpty ? 'No name' : _owner!.longName),
                  subtitle: Text('Short name ${_owner!.shortName.isEmpty ? '—' : _owner!.shortName}'),
                  trailing: TextButton(onPressed: _working ? null : _editOwner, child: const Text('Rename')),
                ),
                ListTile(
                  leading: const Icon(Icons.restart_alt),
                  title: const Text('Restart node'),
                  onTap: _working ? null : _reboot,
                ),
              ]),
              NxSectionLabel('Settings'),
              Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
                for (final s in RemoteConfigSection.all)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: identical(s, section),
                    onSelected: _working || _dirty ? null : (_) => _openSection(s),
                  ),
              ]),
              if (section != null && draft != null) ...[
                if (section.risky)
                  const NxBanner(
                    tone: NxTone.warning,
                    message: 'A wrong LoRa setting can cut this node off the mesh. Change it only if you can reach the node in person.',
                  ),
                NxGroupCard(padding: const EdgeInsets.all(NxSpace.sm), children: [
                  ProtoFieldList(
                    message: draft,
                    writable: () => draft,
                    changed: () => setState(() => _dirty = true),
                  ),
                ]),
                const SizedBox(height: NxSpace.sm),
                Row(children: [
                  Expanded(child: FilledButton(
                    onPressed: _working || !_dirty ? null : _saveSection,
                    child: Text('Send ${section.label} settings'),
                  )),
                  const SizedBox(width: NxSpace.xs),
                  OutlinedButton(
                    onPressed: _working || !_dirty ? null : () => _openSection(section),
                    child: const Text('Undo'),
                  ),
                ]),
              ],
            ],
          ],
        ]),
      ),
    );
  }
}

/// Shows this radio's public key and how to give it admin rights on a node.
class _AdminKeyCard extends StatelessWidget {
  const _AdminKeyCard({required this.publicKey, required this.nodeName});

  final List<int>? publicKey;
  final String nodeName;

  @override
  Widget build(BuildContext context) {
    final key = publicKey;
    final encoded = key == null ? null : base64Encode(key);
    return NxGroupCard(padding: const EdgeInsets.all(NxSpace.md), children: [
      Text('Your radio\'s admin key', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: NxSpace.xxs),
      Text('Before $nodeName will accept changes, its owner adds this key under '
          'Radio settings → Security → Admin key, using any Meshtastic app.'),
      const SizedBox(height: NxSpace.xs),
      if (encoded == null)
        const Text('Your radio hasn\'t reported its key yet.')
      else
        Row(children: [
          Expanded(child: SelectableText(encoded, style: const TextStyle(fontFamily: 'monospace'))),
          IconButton(
            tooltip: 'Copy admin key',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: encoded));
              messenger.showSnackBar(const SnackBar(content: Text('Admin key copied.')));
            },
          ),
        ]),
    ]);
  }
}

class _OwnerDialog extends StatefulWidget {
  const _OwnerDialog({required this.longName, required this.shortName});
  final String longName;
  final String shortName;

  @override
  State<_OwnerDialog> createState() => _OwnerDialogState();
}

class _OwnerDialogState extends State<_OwnerDialog> {
  late final _long = TextEditingController(text: widget.longName);
  late final _short = TextEditingController(text: widget.shortName);
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _long.dispose();
    _short.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Rename node'),
        content: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _long,
              decoration: const InputDecoration(labelText: 'Long name'),
              validator: (v) => BastionNodeIdentityValidation.longNameError(v ?? ''),
            ),
            const SizedBox(height: NxSpace.sm),
            TextFormField(
              controller: _short,
              decoration: const InputDecoration(labelText: 'Short name'),
              validator: (v) => BastionNodeIdentityValidation.shortNameError(v ?? ''),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (_form.currentState!.validate()) {
                Navigator.pop(context, (_long.text.trim(), _short.text.trim()));
              }
            },
            child: const Text('Send'),
          ),
        ],
      );
}
