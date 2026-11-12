import 'dart:math';

import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'package:protobuf/protobuf.dart';

import 'channel_share_page.dart';
import 'generated/meshtastic/admin.pb.dart';
import 'generated/meshtastic/channel.pb.dart';
import 'generated/meshtastic/config.pb.dart';
import 'generated/meshtastic/mesh.pb.dart' show User;
import 'generated/meshtastic/module_config.pb.dart';
import 'proto_form.dart';
import 'services/bastion_channel_precision.dart';
import 'services/bastion_channel_validation.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_units.dart';
import 'services/bastion_hardware.dart';
import 'services/bastion_radio_policy.dart';
import 'services/bastion_settings_verifier.dart';
import 'services/bastion_node_identity_validation.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'services/meshtastic_admin_session.dart';

/// Editable radio settings backed by the admin session.
///
/// Every editor loads the radio's current value, edits a copy, and writes it
/// back only after explicit confirmation. The radio may reboot after a write;
/// the coordinator reconnects automatically.
class RadioSettingsPage extends StatelessWidget {
  const RadioSettingsPage({super.key, required this.radio});

  final MeshtasticRadioCoordinator radio;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_l(context).rsTitle)),
    body: SafeArea(top: false, child: AnimatedBuilder(
      animation: radio,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!radio.canAdminister)
            Card(
              child: ListTile(
                leading: const Icon(Icons.link_off),
                title: Text(_l(context).rsNotReady),
                subtitle: Text(
                  _l(context).rsNotReadySub,
                ),
              ),
            ),
          Card(child: ListTile(
            title: Text(_l(context).rsAvailability),
            subtitle: Text(_l(context).rsAvailabilitySub),
            trailing: radio.checkingSettings ? TextButton(
              onPressed: radio.cancelSettingsCheck, child: Text(_l(context).rsStopChecking)) : const Icon(Icons.refresh),
            onTap: radio.canAdminister && !radio.checkingSettings
                ? radio.checkSettingsAvailability : null,
          )),
          _entry(
            context,
            Icons.person_outline,
            _l(context).rsOwner,
            _l(context).rsOwnerSub,
            () => _OwnerEditor(radio: radio),
          ),
          _entry(
            context,
            Icons.settings_input_antenna,
            'LoRa',
            _l(context).rsLoraSub,
            () => _LoraEditor(radio: radio),
          ),
          _entry(
            context,
            Icons.forum_outlined,
            _l(context).rsChannels,
            _l(context).rsChannelsSub,
            () => _ChannelListPage(radio: radio),
          ),
          _entry(
            context,
            Icons.memory,
            _l(context).rsDevice,
            _l(context).rsDeviceSub,
            () => _DeviceEditor(radio: radio),
          ),
          _entry(
            context,
            Icons.my_location,
            _l(context).rsPosition,
            _l(context).rsPositionSub,
            () => _PositionEditor(radio: radio),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
            child: Text(
              _l(context).rsAllSettings,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final type in AdminMessage_ConfigType.values)
            if (type != AdminMessage_ConfigType.SESSIONKEY_CONFIG)
              _entry(
                context,
                Icons.tune,
                _sectionName(type),
                radio.availability('config:${type.value}'),
                () => _OneofEditor(
                  radio: radio,
                  title: _sectionName(type),
                  load: () async => await radio.readConfig(type),
                  save: (section) => radio.writeConfig(section as Config),
                  empty: Config.new,
                ),
              ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
            child: Text(
              _l(context).rsModules,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final type in AdminMessage_ModuleConfigType.values)
            _entry(
              context,
              Icons.extension_outlined,
              _sectionName(type),
              radio.availability('module:${type.value}'),
              () => _OneofEditor(
                radio: radio,
                title: _sectionName(type),
                load: () async => await radio.readModuleConfig(type),
                save: (section) =>
                    radio.writeModuleConfig(section as ModuleConfig),
                empty: ModuleConfig.new,
              ),
            ),
        ],
      ),
    )),
  );

  Widget _entry(
    BuildContext context,
    IconData icon,
    String title,
    String detail,
    Widget Function() page,
  ) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right),
      enabled: radio.canAdminister,
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => page())),
    ),
  );
}

/// Shared load → edit → confirm → write flow for one protobuf message.
class _AdminEditor<T extends GeneratedMessage> extends StatefulWidget {
  const _AdminEditor({
    required this.radio,
    required this.title,
    required this.load,
    required this.save,
    required this.fields,
    this.validate,
    this.warning,
  });

  final String title;
  final MeshtasticRadioCoordinator radio;
  final Future<T> Function() load;
  final Future<void> Function(T draft) save;
  final List<Widget> Function(T draft, VoidCallback changed) fields;

  /// Returns an error that blocks saving, or null.
  final String? Function(T draft)? validate;

  /// Returns an extra warning shown in the confirmation dialog, or null.
  final String? Function(T original, T draft)? warning;

  @override
  State<_AdminEditor<T>> createState() => _AdminEditorState<T>();
}

class _AdminEditorState<T extends GeneratedMessage>
    extends State<_AdminEditor<T>> {
  T? _original;
  T? _draft;
  Object? _loadError;
  bool _saving = false;
  bool _saveAttempted = false;
  String? _saveProblem;
  int? _loadedNode;
  int _readRevision = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loadError = null;
      _original = null;
      _draft = null;
      _saveAttempted = false;
      _saveProblem = null;
    });
    try {
      final node = widget.radio.localNodeNum;
      final value = await widget.load();
      if (!mounted) return;
      // Looked up here, not before the read: _reload also runs from initState.
      if (widget.radio.localNodeNum != node) throw StateError(_l(context).rsRadioChanged);
      _loadedNode = node;
      setState(() {
        _readRevision++;
        _original = value;
        _draft = value.deepCopy();
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  Future<void> _save() async {
    final original = _original;
    final draft = _draft;
    if (original == null || draft == null || _saveAttempted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = _l(context);
    final warning = widget.warning?.call(original, draft);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.rsSaveQ(widget.title)),
        content: Text(
          [
            l.rsSaveWarning,
            ?warning,
          ].join('\n\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.commonSave),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final node = _loadedNode;
    if (node == null || widget.radio.localNodeNum != node) {
      setState(() => _saveProblem = l.rsIdentityChanged);
      return;
    }
    FocusScope.of(context).unfocus();
    final submitted = draft.deepCopy();
    setState(() { _saving = true; _saveAttempted = true; _saveProblem = null; });
    try {
      await BastionSettingsVerifier.save<T>(
        node: node, currentNode: () => widget.radio.localNodeNum,
        original: original, requested: submitted,
        write: () => widget.save(submitted), waitForRadio: widget.radio.waitForSettingsRadio,
        read: widget.load,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l.rsSaved(widget.title))),
      );
      navigator.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() { _saving = false; _saveProblem = 'Save not verified: $error\nThe radio may have applied the change. Reload to inspect its current value; nothing will be resent automatically.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final error = draft == null ? null : widget.validate?.call(draft);
    final dirty = draft != null && draft != _original;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: dirty && error == null && !_saving && !_saveAttempted ? _save : null,
            child: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_l(context).rsSaveButton),
          ),
        ],
      ),
      body: SafeArea(top: false, child: switch ((draft, _loadError)) {
        (_, final Object loadError) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(loadError is MeshtasticSettingsUnavailable
                ? _l(context).rsUnavailable(widget.title)
                : _l(context).rsReadFailed('$loadError')),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _reload,
                child: Text(_l(context).rsRetry),
              ),
            ),
          ],
        ),
        (null, _) => const Center(child: CircularProgressIndicator()),
        (final T draft, _) => AbsorbPointer(
          absorbing: _saving,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_saving) ListTile(title: Text(_l(context).rsWaitingReconnect)),
              if (_saveProblem != null) Semantics(liveRegion: true, child: Text(_saveProblem!)),
              if (_saveAttempted && !_saving || _saveProblem != null && !_saving)
                TextButton(onPressed: _reload, child: Text(_l(context).rsReload)),
              KeyedSubtree(
                key: ValueKey('settings-fields:$_readRevision'),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.fields(draft, () => setState(() {}))),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      }),
    );
  }
}

String _label(ProtobufEnum value) => value.name
    .split('_')
    .map(
      (word) => word.isEmpty ? word : word[0] + word.substring(1).toLowerCase(),
    )
    .join(' ');

Widget _enumField<E extends ProtobufEnum>({
  required String label,
  required E value,
  required List<E> values,
  required ValueChanged<E> onChanged,
}) => DropdownButtonFormField<E>(
  key: ValueKey('$label:${value.value}'),
  initialValue: values.contains(value) ? value : null,
  decoration: InputDecoration(labelText: label),
  items: [
    for (final v in values) DropdownMenuItem(value: v, child: Text(_label(v))),
  ],
  onChanged: (v) {
    if (v != null) onChanged(v);
  },
);

/// Text field that edits a string inside a protobuf draft.
class _DraftTextField extends StatefulWidget {
  const _DraftTextField({
    required this.label,
    required this.initial,
    required this.onChanged,
    this.maxLength,
    this.keyboardType,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;
  final int? maxLength;
  final TextInputType? keyboardType;

  @override
  State<_DraftTextField> createState() => _DraftTextFieldState();
}

class _DraftTextFieldState extends State<_DraftTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    maxLength: widget.maxLength,
    keyboardType: widget.keyboardType,
    decoration: InputDecoration(labelText: widget.label),
    onChanged: widget.onChanged,
  );
}

class _OwnerEditor extends StatelessWidget {
  const _OwnerEditor({required this.radio});

  final MeshtasticRadioCoordinator radio;

  @override
  Widget build(BuildContext context) => _AdminEditor<User>(
    radio: radio,
    title: _l(context).rsOwner,
    load: radio.readOwner,
    save: radio.writeOwner,
    validate: (draft) =>
        BastionNodeIdentityValidation.longNameError(draft.longName) ??
        BastionNodeIdentityValidation.shortNameError(draft.shortName),
    fields: (draft, changed) => [
      _DraftTextField(
        label: _l(context).rsLongName,
        initial: draft.longName,
        maxLength: 39,
        onChanged: (v) {
          draft.longName = v.trim();
          changed();
        },
      ),
      _DraftTextField(
        label: _l(context).rsShortName,
        initial: draft.shortName,
        maxLength: 4,
        onChanged: (v) {
          draft.shortName = v.trim();
          changed();
        },
      ),
    ],
  );
}

class _LoraEditor extends StatelessWidget {
  const _LoraEditor({required this.radio});

  final MeshtasticRadioCoordinator radio;

  @override
  Widget build(BuildContext context) => _AdminEditor<Config_LoRaConfig>(
    radio: radio,
    title: 'LoRa',
    load: () async =>
        (await radio.readConfig(AdminMessage_ConfigType.LORA_CONFIG)).lora,
    save: (draft) => radio.writeConfig(Config(lora: draft)),
    validate: (draft) {
      if (draft.region == Config_LoRaConfig_RegionCode.UNSET) {
        return _l(context).rsChooseRegion;
      }
      if (!draft.usePreset &&
          (draft.bandwidth <= 0 ||
              draft.spreadFactor < 5 ||
              draft.spreadFactor > 12 ||
              draft.codingRate < 5 ||
              draft.codingRate > 8)) {
        return _l(context).rsCustomInvalid;
      }
      return null;
    },
    warning: (original, draft) =>
        original.region != draft.region ||
            original.modemPreset != draft.modemPreset ||
            original.usePreset != draft.usePreset ||
            original.bandwidth != draft.bandwidth ||
            original.spreadFactor != draft.spreadFactor ||
            original.codingRate != draft.codingRate ||
            original.overrideFrequency != draft.overrideFrequency
        ? _l(context).rsRegionWarning
        : null,
    fields: (draft, changed) => [
      _enumField(
        label: _l(context).rsRegion,
        value: draft.region,
        values: Config_LoRaConfig_RegionCode.values,
        onChanged: (v) {
          BastionRadioPolicy.chooseRegion(draft, v, radio.firmwareVersion);
          changed();
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_l(context).rsUsePreset),
        value: draft.usePreset,
        onChanged: (v) {
          draft.usePreset = v;
          changed();
        },
      ),
      if (draft.usePreset)
        _enumField(
          label: _l(context).rsModemPreset,
          value: draft.modemPreset,
          values: Config_LoRaConfig_ModemPreset.values,
          onChanged: (v) {
            draft.modemPreset = v;
            changed();
          },
        ),
      if (!draft.usePreset) ...[
        _DraftTextField(
          label: _l(context).rsBandwidth,
          initial: '${draft.bandwidth}',
          keyboardType: TextInputType.number,
          onChanged: (v) {
            draft.bandwidth = int.tryParse(v) ?? 0;
            changed();
          },
        ),
        _DraftTextField(
          label: _l(context).rsSpreadFactor,
          initial: '${draft.spreadFactor}',
          keyboardType: TextInputType.number,
          onChanged: (v) {
            draft.spreadFactor = int.tryParse(v) ?? 0;
            changed();
          },
        ),
        _DraftTextField(
          label: _l(context).rsCodingRate,
          initial: '${draft.codingRate}',
          keyboardType: TextInputType.number,
          onChanged: (v) {
            draft.codingRate = int.tryParse(v) ?? 0;
            changed();
          },
        ),
      ],
      if (BastionRadioPolicy.showUsNotice(draft))
        const Card(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text(BastionRadioPolicy.usNotice),
          ),
        ),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(BastionRadioPolicy.compatibilityNotice),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_l(context).rsRxBoost),
        subtitle: Text(
          _l(context).rsRxBoostSub,
        ),
        value: draft.sx126xRxBoostedGain,
        onChanged: (v) {
          draft.sx126xRxBoostedGain = v;
          changed();
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_l(context).rsLna),
        subtitle: Text(
          BastionRadioPolicy.canControlLna(draft)
              ? _l(context).rsLnaReported
              : _l(context).rsLnaNone,
        ),
        value: draft.femLnaMode == Config_LoRaConfig_FEM_LNA_Mode.ENABLED,
        onChanged: BastionRadioPolicy.canControlLna(draft)
            ? (v) {
                draft.femLnaMode = v
                    ? Config_LoRaConfig_FEM_LNA_Mode.ENABLED
                    : Config_LoRaConfig_FEM_LNA_Mode.DISABLED;
                changed();
              }
            : null,
      ),
      const SizedBox(height: 16),
      Text(_l(context).rsHopLimit(draft.hopLimit)),
      Slider(
        value: draft.hopLimit.clamp(1, 7).toDouble(),
        min: 1,
        max: 7,
        divisions: 6,
        label: '${draft.hopLimit}',
        onChanged: (v) {
          draft.hopLimit = v.round();
          changed();
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_l(context).rsTransmit),
        subtitle: Text(_l(context).rsTransmitSub),
        value: draft.txEnabled,
        onChanged: (v) {
          draft.txEnabled = v;
          changed();
        },
      ),
    ],
  );
}

class _DeviceEditor extends StatelessWidget {
  const _DeviceEditor({required this.radio});

  final MeshtasticRadioCoordinator radio;

  static const _infrastructureRoles = {
    Config_DeviceConfig_Role.ROUTER,
    Config_DeviceConfig_Role.ROUTER_LATE,
    Config_DeviceConfig_Role.REPEATER,
  };

  @override
  Widget build(BuildContext context) => _AdminEditor<Config_DeviceConfig>(
    radio: radio,
    title: _l(context).rsDevice,
    load: () async =>
        (await radio.readConfig(AdminMessage_ConfigType.DEVICE_CONFIG)).device,
    save: (draft) => radio.writeConfig(Config(device: draft)),
    warning: (original, draft) =>
        original.role != draft.role && _infrastructureRoles.contains(draft.role)
        ? _l(context).rsInfraWarning(_label(draft.role))
        : null,
    fields: (draft, changed) => [
      _enumField(
        label: _l(context).rsRole,
        value: draft.role,
        // ROUTER_CLIENT is deprecated in firmware.
        values: Config_DeviceConfig_Role.values
            .where((r) => r != Config_DeviceConfig_Role.ROUTER_CLIENT)
            .toList(),
        onChanged: (v) {
          draft.role = v;
          changed();
        },
      ),
      _enumField(
        label: _l(context).rsRebroadcast,
        value: draft.rebroadcastMode,
        values: Config_DeviceConfig_RebroadcastMode.values,
        onChanged: (v) {
          draft.rebroadcastMode = v;
          changed();
        },
      ),
    ],
  );
}

class _PositionEditor extends StatelessWidget {
  const _PositionEditor({required this.radio});

  final MeshtasticRadioCoordinator radio;

  @override
  Widget build(BuildContext context) => _AdminEditor<Config_PositionConfig>(
    radio: radio,
    title: _l(context).rsPosition,
    load: () async =>
        (await radio.readConfig(AdminMessage_ConfigType.POSITION_CONFIG))
            .position,
    save: (draft) => radio.writeConfig(Config(position: draft)),
    validate: (draft) =>
        draft.positionBroadcastSecs != 0 && draft.positionBroadcastSecs < 30
        ? _l(context).rsIntervalInvalid
        : null,
    fields: (draft, changed) => [
      _enumField(
        label: _l(context).rsGpsMode,
        value: draft.gpsMode,
        values: Config_PositionConfig_GpsMode.values,
        onChanged: (v) {
          draft.gpsMode = v;
          changed();
        },
      ),
      _DraftTextField(
        label: _l(context).rsInterval,
        initial: '${draft.positionBroadcastSecs}',
        keyboardType: TextInputType.number,
        onChanged: (v) {
          draft.positionBroadcastSecs = int.tryParse(v) ?? 0;
          changed();
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_l(context).rsSmart),
        subtitle: Text(_l(context).rsSmartSub),
        value: draft.positionBroadcastSmartEnabled,
        onChanged: (v) {
          draft.positionBroadcastSmartEnabled = v;
          changed();
        },
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_l(context).rsFixed),
        subtitle: Text(_l(context).rsFixedSub),
        value: draft.fixedPosition,
        onChanged: (v) {
          draft.fixedPosition = v;
          changed();
        },
      ),
    ],
  );
}

class _ChannelListPage extends StatefulWidget {
  const _ChannelListPage({required this.radio});

  final MeshtasticRadioCoordinator radio;

  @override
  State<_ChannelListPage> createState() => _ChannelListPageState();
}

class _ChannelListPageState extends State<_ChannelListPage> {
  final List<Channel> _channels = [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _channels.clear();
      _error = null;
      _loading = true;
    });
    try {
      for (var i = 0; i < 8; i++) {
        final channel = await widget.radio.readChannel(i);
        if (!mounted) return;
        setState(() => _channels.add(channel));
      }
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_l(context).rsChannels),
      actions: [
        IconButton(
          tooltip: _l(context).rsShareQr,
          icon: const Icon(Icons.qr_code),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChannelSharePage(radio: widget.radio),
            ),
          ),
        ),
        IconButton(
          tooltip: _l(context).rsImportLink,
          icon: const Icon(Icons.download),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChannelImportPage(radio: widget.radio),
              ),
            );
            if (mounted) await _load();
          },
        ),
      ],
    ),
    body: SafeArea(top: false, child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final channel in _channels)
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${channel.index}')),
              title: Text(
                channel.role == Channel_Role.DISABLED
                    ? _l(context).rsDisabled
                    : channel.settings.name.isEmpty
                    ? _l(context).rsDefaultName
                    : channel.settings.name,
              ),
              subtitle: Text(
                '${_label(channel.role)} • ${_describeKey(_l(context), channel.settings.psk)}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => _ChannelEditor(
                      radio: widget.radio,
                      index: channel.index,
                    ),
                  ),
                );
                if (mounted) await _load();
              },
            ),
          ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_error != null) ...[
          Text(_l(context).rsChannelsFailed('$_error')),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(onPressed: _load, child: Text(_l(context).rsRetry)),
          ),
        ],
      ],
    )),
  );
}

AppLocalizations _l(BuildContext context) => AppLocalizations.of(context);

String _describeKey(AppLocalizations l, List<int> psk) => switch (psk.length) {
  0 => l.rsNoEncryption,
  1 when psk.first == 0 => l.rsNoEncryption,
  1 => l.rsDefaultKey,
  16 => l.rsAes128,
  32 => l.rsAes256,
  _ => l.rsUnknownKey,
};

class _ChannelEditor extends StatelessWidget {
  const _ChannelEditor({required this.radio, required this.index});

  final MeshtasticRadioCoordinator radio;
  final int index;

  @override
  Widget build(BuildContext context) => _AdminEditor<Channel>(
    radio: radio,
    title: _l(context).rsChannelN(index),
    load: () => radio.readChannel(index),
    save: radio.writeChannel,
    validate: (draft) => BastionChannelValidation.validate(
      index: draft.index,
      role: draft.role.value,
      name: draft.settings.name,
      key: draft.settings.psk,
    ),
    warning: (original, draft) =>
        BastionChannelValidation.requiresKeyChangeConfirmation(
          original.settings.psk,
          draft.settings.psk,
        )
        ? _l(context).rsKeyWarning
        : null,
    fields: (draft, changed) => [
      if (index != 0)
        _enumField(
          label: _l(context).rsRole,
          value: draft.role,
          values: const [Channel_Role.SECONDARY, Channel_Role.DISABLED],
          onChanged: (v) {
            draft.role = v;
            changed();
          },
        ),
      _DraftTextField(
        label: _l(context).rsChannelName,
        initial: draft.settings.name,
        maxLength: 11,
        onChanged: (v) {
          draft.ensureSettings().name = v;
          changed();
        },
      ),
      _precisionField(context, draft, changed),
      const SizedBox(height: 8),
      Text(_l(context).rsEncryption(_describeKey(_l(context), draft.settings.psk))),
      Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            onPressed: () {
              draft.ensureSettings().psk = const [1];
              changed();
            },
            child: Text(_l(context).rsDefaultKey),
          ),
          OutlinedButton(
            onPressed: () {
              final random = Random.secure();
              draft.ensureSettings().psk = List.generate(
                32,
                (_) => random.nextInt(256),
              );
              changed();
            },
            child: Text(_l(context).rsNewAes256),
          ),
          OutlinedButton(
            onPressed: () {
              draft.ensureSettings().psk = const [0];
              changed();
            },
            child: Text(_l(context).rsNoEncryption),
          ),
        ],
      ),
    ],
  );
}

/// The radio's own position precision for one channel.
Widget _precisionField(BuildContext context, Channel draft, VoidCallback changed) {
  final l = _l(context);
  final set = draft.settings.hasModuleSettings();
  final bits = draft.settings.moduleSettings.positionPrecision;
  String label(int value, int metres) => switch (value) {
        BastionChannelPrecision.none => l.cpNone,
        BastionChannelPrecision.exact => l.cpExact,
        _ => l.cpWithin(BastionUnitFormat.distance(metres.toDouble(), BastionPreferences.instance.units)),
      };
  return DropdownButtonFormField<int>(
    key: ValueKey('channel-precision:$set:$bits'),
    isExpanded: true,
    initialValue: set && BastionChannelPrecision.choices.containsKey(bits) ? bits : null,
    hint: Text(l.cpNotSet),
    decoration: InputDecoration(labelText: l.cpLabel, helperText: l.cpHelp, helperMaxLines: 3),
    items: [
      for (final e in BastionChannelPrecision.choices.entries)
        DropdownMenuItem(value: e.key, child: Text(label(e.key, e.value))),
    ],
    onChanged: (v) {
      if (v == null) return;
      draft.ensureSettings().ensureModuleSettings().positionPrecision = v;
      changed();
    },
  );
}

/// Friendly names for protocol abbreviations.
String _sectionName(ProtobufEnum type) => switch (type.name) {
  'LORA_CONFIG' => 'LoRa',
  'DEVICEUI_CONFIG' => 'Device UI',
  'MQTT_CONFIG' => 'MQTT',
  'EXTNOTIF_CONFIG' => 'External notifications',
  'STOREFORWARD_CONFIG' => 'Store & Forward',
  'RANGETEST_CONFIG' => 'Range test',
  'CANNEDMSG_CONFIG' => 'Canned messages',
  'REMOTEHARDWARE_CONFIG' => 'Remote hardware',
  'NEIGHBORINFO_CONFIG' => 'Neighbor info',
  'AMBIENTLIGHTING_CONFIG' => 'Ambient lighting',
  'DETECTIONSENSOR_CONFIG' => 'Detection sensor',
  'STATUSMESSAGE_CONFIG' => 'Status message',
  'TRAFFICMANAGEMENT_CONFIG' => 'Traffic management',
  'TAK_CONFIG' => 'TAK',
  'MESHBEACON_CONFIG' => 'Mesh Beacon',
  _ => _label(type).replaceAll(RegExp(r' Config$'), ''),
};

/// Edits whichever single section a Config or ModuleConfig reply carries.
///
/// Both messages are a oneof of sections; the radio answers a read with the
/// requested one set. The form edits that section and writes it back wrapped
/// in the same oneof.
class _OneofEditor extends StatefulWidget {
  const _OneofEditor({
    required this.radio,
    required this.title,
    required this.load,
    required this.save,
    required this.empty,
  });

  final MeshtasticRadioCoordinator radio;
  final String title;
  final Future<GeneratedMessage> Function() load;
  final Future<void> Function(GeneratedMessage wrapped) save;
  final GeneratedMessage Function() empty;

  static FieldInfo<dynamic> _setSection(GeneratedMessage message) {
    for (final field in message.info_.sortedByTag) {
      if (message.hasField(field.tagNumber)) return field;
    }
    throw StateError(
      'The radio returned no settings section.',
    );
  }

  @override
  State<_OneofEditor> createState() => _OneofEditorState();
}

class _OneofEditorState extends State<_OneofEditor> {
  /// Field number of the section the radio returned; set by load.
  int? _tag;

  @override
  Widget build(BuildContext context) => _AdminEditor<GeneratedMessage>(
    radio: widget.radio,
    title: widget.title,
    load: () async {
      final wrapped = await widget.load();
      final tag = _OneofEditor._setSection(wrapped).tagNumber;
      _tag = tag;
      return wrapped.getField(tag) as GeneratedMessage;
    },
    save: (draft) => widget.save(widget.empty()..setField(_tag!, draft)),
    fields: (draft, changed) {
      final model = widget.radio.localNode?.hardwareModel;
      final hideGpsPins =
          draft is Config_PositionConfig && BastionHardware.hasFixedGps(model);
      return [
        ProtoFieldList(
          message: draft,
          writable: () => draft,
          changed: changed,
          hiddenFields: hideGpsPins ? BastionHardware.diyGpsFields : const {},
          notice: hideGpsPins
              ? _l(context).rsGpsHidden(BastionHardware.name(model!))
              : null,
        ),
      ];
    },
  );
}
