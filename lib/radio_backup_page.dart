import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/bastion_encrypted_backup.dart';
import 'services/bastion_radio_backup.dart';
import 'services/meshtastic_radio_coordinator.dart';

Future<String> _encryptBackup((String, String) input) =>
    BastionEncryptedBackup().encrypt(input.$1, input.$2);
Future<String> _decryptBackup((String, String) input) =>
    BastionEncryptedBackup().decrypt(input.$1, input.$2);

/// Explicit export/import of encrypted settings; passwords are never persisted.
class RadioBackupPage extends StatefulWidget {
  const RadioBackupPage({super.key, required this.radio});
  final MeshtasticRadioCoordinator radio;
  @override
  State<RadioBackupPage> createState() => _RadioBackupPageState();
}

class _RadioBackupPageState extends State<RadioBackupPage> {
  final _password = TextEditingController();
  final _encrypted = TextEditingController();
  bool _busy = false;
  String? _status;
  // Steps ticked in the new-radio checklist; kept only while the page is open.
  final Set<int> _done = {};

  AppLocalizations get l => AppLocalizations.of(context);

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    _encrypted.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() { _busy = true; _status = null; });
    try { await action(); }
    on FormatException catch (error) {
      if (mounted) setState(() => _status = error.message);
    } catch (_) {
      if (mounted) setState(() => _status = l.rbFailed);
    } finally {
      if (mounted) {
        _password.clear();
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _backup() => _run(() async {
    final password = _password.text;
    if (password.length < 12) throw FormatException(l.pbShortPassword);
    final snapshot = await BastionRadioBackup(widget.radio).capture();
    final plain = await snapshot.encode();
    final encrypted = await compute(_encryptBackup, (plain, password));
    if (!mounted) return;
    _encrypted.text = encrypted;
    setState(() => _status = l.rbReady);
  });

  Future<void> _restore() => _run(() async {
    final password = _password.text;
    final encrypted = _encrypted.text;
    final plain = await compute(_decryptBackup, (encrypted, password));
    final snapshot = await RadioBackupSnapshot.decode(plain);
    if (!mounted) return;
    final target = widget.radio.backupNodeNum;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(l.rbReplaceQ),
      content: Text(l.rbSummary('!${snapshot.nodeNum.toRadixString(16)}', '${snapshot.firmware}',
          '${snapshot.createdAt.toLocal()}', '!${target.toRadixString(16)}',
          snapshot.configs.length, snapshot.modules.length)),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.rbReplace))],
    ));
    if (confirmed != true || !mounted) return;
    if (widget.radio.backupNodeNum != target) throw StateError(l.rbRadioChanged);
    await BastionRadioBackup(widget.radio).restore(snapshot);
    if (mounted) setState(() => _status = l.rbRestored);
  });

  /// A guide for replacing a radio; the backup above does the copying.
  Widget _newRadioChecklist() {
    final steps = [l.nrStep1, l.nrStep2, l.nrStep3, l.nrStep4, l.nrStep5, l.nrStep6, l.nrStep7];
    return Card(key: const ValueKey('new-radio-checklist'), child: ExpansionTile(
      leading: const Icon(Icons.swap_horiz),
      title: Text(l.nrTitle),
      subtitle: Text(l.nrSub(_done.length, steps.length)),
      children: [
        for (final (i, step) in steps.indexed)
          CheckboxListTile(
            key: ValueKey('new-radio-step-$i'),
            value: _done.contains(i),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text('${i + 1}. $step'),
            onChanged: (v) => setState(() => v == true ? _done.add(i) : _done.remove(i)),
          ),
        if (_done.isNotEmpty)
          Align(alignment: AlignmentDirectional.centerEnd, child: TextButton(
            onPressed: () => setState(_done.clear), child: Text(l.nrReset))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
    appBar: AppBar(title: Text(l.rbTitle)),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Text(l.rbIntro),
      const SizedBox(height: 16),
      TextField(controller: _password, obscureText: true, enableSuggestions: false,
          autocorrect: false, enabled: !_busy,
          decoration: InputDecoration(labelText: l.pbPassword,
              border: const OutlineInputBorder())),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: _busy ? null : _backup,
          icon: const Icon(Icons.lock), label: Text(l.rbCreate)),
      const SizedBox(height: 16),
      TextField(controller: _encrypted, maxLines: 5, enabled: !_busy,
          enableSuggestions: false, autocorrect: false,
          decoration: InputDecoration(labelText: l.rbText,
              hintText: l.rbTextHint, border: const OutlineInputBorder())),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _busy ? null : () async {
        if (_encrypted.text.isEmpty) return;
        await Clipboard.setData(ClipboardData(text: _encrypted.text));
        if (mounted) setState(() => _status = l.rbCopied);
      }, icon: const Icon(Icons.copy), label: Text(l.rbCopy)),
      OutlinedButton.icon(onPressed: _busy ? null : _restore,
          icon: const Icon(Icons.settings_backup_restore), label: Text(l.rbReview)),
      if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      if (_status != null) Padding(padding: const EdgeInsets.all(16), child: Text(_status!)),
      // Below the status, so backup results stay next to the buttons.
      const SizedBox(height: 16),
      _newRadioChecklist(),
    ]),
  ));
}
