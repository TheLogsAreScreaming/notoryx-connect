import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:protobuf/protobuf.dart';

import 'l10n/generated/app_localizations.dart';

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

  AppLocalizations get l => AppLocalizations.of(context);

  /// The section's name in the phone's language; LoRa stays as it is.
  String _sectionName(RemoteConfigSection s) => switch (s.type) {
        AdminMessage_ConfigType.DEVICE_CONFIG => l.rsDevice,
        AdminMessage_ConfigType.POSITION_CONFIG => l.rsPosition,
        AdminMessage_ConfigType.POWER_CONFIG => l.raPower,
        AdminMessage_ConfigType.DISPLAY_CONFIG => l.raDisplay,
        _ => s.label,
      };

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
      l.raLoraQ,
      l.raLoraBody,
      l.raSaveAnyway,
    )) {
      return;
    }
    final saved = await _call((s) async { await s.setConfig(section.wrap(draft)); return true; });
    if (saved == true) {
      setState(() => _dirty = false);
      _toast(l.raSent(_sectionName(section)));
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
      _toast(l.raNameSent);
    }
  }

  Future<void> _reboot() async {
    if (!await _confirm(l.raRestartQ(_nodeName), l.raRestartBody, l.raRestart)) {
      return;
    }
    final sent = await _call((s) async { await s.reboot(); return true; });
    if (sent == true) _toast(l.raRestartRequested);
  }

  Future<bool> _confirm(String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l.commonCancel)),
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
        if (await _confirm(l.raDiscardQ, l.raDiscardBody, l.raDiscard)) {
          setState(() => _dirty = false);
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l.raTitle)),
        body: ListView(padding: NxSpace.page, children: [
          NxPageHeader(
            title: _nodeName,
            subtitle: l.raIntro,
          ),
          if (_openProblem != null)
            NxBanner(tone: NxTone.warning, title: l.raUnavailable, message: _openProblem!)
          else ...[
            _AdminKeyCard(publicKey: widget.radio.localPublicKey, nodeName: _nodeName),
            if (_working) Padding(
              padding: const EdgeInsets.symmetric(vertical: NxSpace.xs),
              child: Semantics(label: l.raWaiting, child: const LinearProgressIndicator()),
            ),
            if (_error != null) NxBanner(tone: NxTone.danger, message: _error!),
            NxSectionLabel(l.raAccess),
            if (_metadata == null)
              NxGroupCard(padding: const EdgeInsets.all(NxSpace.md), children: [
                Text(l.raAccessHint),
                const SizedBox(height: NxSpace.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.icon(
                    onPressed: _working ? null : _checkAccess,
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    label: Text(l.raCheckAccess),
                  ),
                ),
              ])
            else ...[
              NxGroupCard(children: [
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(l.raAccessConfirmed),
                  subtitle: Text(l.raFirmware(
                      _metadata!.firmwareVersion.isEmpty ? l.raUnknown : _metadata!.firmwareVersion,
                      _metadata!.role.name.replaceAll('_', ' ').toLowerCase())),
                ),
                if (_owner != null) ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(_owner!.longName.isEmpty ? l.raNoName : _owner!.longName),
                  subtitle: Text(l.raShortName(_owner!.shortName.isEmpty ? '—' : _owner!.shortName)),
                  trailing: TextButton(onPressed: _working ? null : _editOwner, child: Text(l.raRename)),
                ),
                ListTile(
                  leading: const Icon(Icons.restart_alt),
                  title: Text(l.raRestartNode),
                  onTap: _working ? null : _reboot,
                ),
              ]),
              NxSectionLabel(l.raSettings),
              Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
                for (final s in RemoteConfigSection.all)
                  ChoiceChip(
                    label: Text(_sectionName(s)),
                    selected: identical(s, section),
                    onSelected: _working || _dirty ? null : (_) => _openSection(s),
                  ),
              ]),
              if (section != null && draft != null) ...[
                if (section.risky)
                  NxBanner(
                    tone: NxTone.warning,
                    message: l.raLoraWarning,
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
                    child: Text(l.raSend(_sectionName(section))),
                  )),
                  const SizedBox(width: NxSpace.xs),
                  OutlinedButton(
                    onPressed: _working || !_dirty ? null : () => _openSection(section),
                    child: Text(l.raUndo),
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
    final l = AppLocalizations.of(context);
    final key = publicKey;
    final encoded = key == null ? null : base64Encode(key);
    return NxGroupCard(padding: const EdgeInsets.all(NxSpace.md), children: [
      Text(l.raKeyTitle, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: NxSpace.xxs),
      Text(l.raKeyBody(nodeName)),
      const SizedBox(height: NxSpace.xs),
      if (encoded == null)
        Text(l.raNoKey)
      else
        Row(children: [
          Expanded(child: SelectableText(encoded, style: const TextStyle(fontFamily: 'monospace'))),
          IconButton(
            tooltip: l.raCopyKey,
            icon: const Icon(Icons.copy),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final copied = l.raKeyCopied;
              await Clipboard.setData(ClipboardData(text: encoded));
              messenger.showSnackBar(SnackBar(content: Text(copied)));
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
        title: Text(AppLocalizations.of(context).raRenameTitle),
        content: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: _long,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).rsLongName),
              validator: (v) => BastionNodeIdentityValidation.longNameError(v ?? ''),
            ),
            const SizedBox(height: NxSpace.sm),
            TextFormField(
              controller: _short,
              decoration: InputDecoration(labelText: AppLocalizations.of(context).rsShortName),
              validator: (v) => BastionNodeIdentityValidation.shortNameError(v ?? ''),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).commonCancel)),
          FilledButton(
            onPressed: () {
              if (_form.currentState!.validate()) {
                Navigator.pop(context, (_long.text.trim(), _short.text.trim()));
              }
            },
            child: Text(AppLocalizations.of(context).raSendButton),
          ),
        ],
      );
}
