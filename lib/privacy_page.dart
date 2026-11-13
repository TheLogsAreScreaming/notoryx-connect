import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';

import 'services/app_exit.dart';
import 'services/bastion_app_lock.dart';
import 'services/bastion_chat_store.dart';
import 'services/bastion_phone_backup.dart';
import 'services/bastion_tile_cache.dart';
import 'services/meshtastic_connection_controller.dart';
import 'services/meshtastic_radio_coordinator.dart';

/// What the app stores and sends, and controls to delete phone data.
class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key, required this.radio});
  final MeshtasticRadioCoordinator radio;
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _busy = false;
  String? _status;
  bool _lockAvailable = false;

  AppLocalizations get l => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    BastionAppLock.instance.isAvailable().then((v) {
      if (mounted) setState(() => _lockAvailable = v);
    });
  }

  Future<void> _setEncrypted(bool value) async {
    setState(() { _busy = true; _status = null; });
    final problem = await BastionChatStorage.setEncrypted(value);
    if (!mounted) return;
    setState(() { _busy = false; _status = problem ?? (value ? l.pvEncryptedOn : l.pvEncryptedOff); });
  }

  Future<void> _setLock(bool value) async {
    final changed = await BastionAppLock.instance.setEnabled(value, value ? l.pvLockOnReason : l.pvLockOffReason);
    if (!mounted) return;
    setState(() => _status = changed ? null : l.pvLockUnchanged);
  }

  List<String> get _stored => [l.pvStored1, l.pvStored2, l.pvStored3, l.pvStored4, l.pvStored5, l.pvStored6];

  List<String> get _sent => [l.pvSent1, l.pvSent2, l.pvSent3, l.pvSent4, l.pvSent5, l.pvSent6, l.pvSent7, l.pvSent8];

  Future<void> _erase({required bool everything}) async {
    final l = this.l;
    if (widget.radio.connection.state != MeshtasticConnectionState.disconnected) {
      setState(() => _status = l.pvDisconnectFirst);
      return;
    }
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(everything ? l.pvDeleteAllQ : l.pvDeleteChatsQ),
      content: Text(everything ? l.pvDeleteAllBody : l.pvDeleteChatsBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: Text(l.pvDelete),
        ),
      ],
    ));
    if (confirmed != true || !mounted) return;
    setState(() { _busy = true; _status = null; });
    try {
      await BastionPhoneBackup().erase(everything: everything);
      if (everything) await BastionTileCache.clear();
    } catch (error) {
      if (mounted) setState(() { _busy = false; _status = l.pvDeleteFailed('$error'); });
      return;
    }
    if (!mounted) return;
    await showDialog<void>(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      title: Text(l.pvDeleted),
      content: Text(l.pvDeletedBody),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.pvCloseApp))],
    ));
    await closeApp();
  }

  Widget _list(String title, List<String> items) => Card(child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final item in items)
        Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const Text('•  '), Expanded(child: Text(item))],
        )),
    ]),
  ));

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: Text(l.pvTitle)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(l.pvIntro),
        const SizedBox(height: 12),
        Card(child: SwitchListTile(
          key: const ValueKey('app-lock-switch'),
          secondary: const Icon(Icons.lock_outline),
          title: Text(l.pvAppLock),
          subtitle: Text(_lockAvailable
              ? l.pvAppLockSub
              : l.pvAppLockNone),
          value: BastionAppLock.instance.enabled,
          onChanged: _busy || !_lockAvailable ? null : _setLock,
        )),
        Card(child: SwitchListTile(
          key: const ValueKey('chat-encryption-switch'),
          secondary: const Icon(Icons.enhanced_encryption_outlined),
          title: Text(l.pvEncrypt),
          subtitle: Text(l.pvEncryptSub),
          value: BastionChatStorage.encrypted,
          onChanged: _busy ? null : _setEncrypted,
        )),
        _list(l.pvStored, _stored),
        _list(l.pvSent, _sent),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _busy ? null : () => _erase(everything: false),
            icon: const Icon(Icons.delete_sweep_outlined), label: Text(l.pvDeleteChats)),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: _busy ? null : () => _erase(everything: true),
          icon: const Icon(Icons.delete_forever_outlined), label: Text(l.pvDeleteAll)),
        if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        if (_status != null) Padding(padding: const EdgeInsets.all(16), child: Text(_status!)),
      ]),
    ),
  );
}
