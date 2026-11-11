import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'l10n/generated/app_localizations.dart';

import 'services/app_exit.dart';
import 'services/bastion_phone_backup.dart';
import 'services/meshtastic_connection_controller.dart';
import 'services/meshtastic_radio_coordinator.dart';

Future<String> _encrypt((String, String) input) =>
    BastionPhoneBackup.encryption.encrypt(input.$1, input.$2);
Future<String> _decrypt((String, String) input) =>
    BastionPhoneBackup.encryption.decrypt(input.$1, input.$2);

/// Saves and opens backup files; faked in tests.
abstract interface class PhoneBackupFiles {
  Future<void> save(String fileName, String text);

  /// The chosen file's text, or null if the user cancelled.
  Future<String?> open();
}

class SystemPhoneBackupFiles implements PhoneBackupFiles {
  const SystemPhoneBackupFiles();
  static const maxFileBytes = 16 * 1024 * 1024;

  @override
  Future<void> save(String fileName, String text) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(Uint8List.fromList(utf8.encode(text)), mimeType: 'application/json')],
      fileNameOverrides: [fileName],
      subject: 'NOTORYX Connect phone backup',
    ));
  }

  @override
  Future<String?> open() async {
    final file = await openFile();
    if (file == null) return null;
    if (await file.length() > maxFileBytes) {
      throw const FormatException('That file is too large to be a phone backup.');
    }
    return file.readAsString();
  }
}

/// Encrypted backup and restore of everything the app stores on this phone.
/// Passwords are never stored.
class PhoneBackupPage extends StatefulWidget {
  const PhoneBackupPage({super.key, required this.radio, this.files = const SystemPhoneBackupFiles()});
  final MeshtasticRadioCoordinator radio;
  final PhoneBackupFiles files;
  @override
  State<PhoneBackupPage> createState() => _PhoneBackupPageState();
}

class _PhoneBackupPageState extends State<PhoneBackupPage> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _status;

  AppLocalizations get l => AppLocalizations.of(context);

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() { _busy = true; _status = null; });
    try {
      await action();
    } on FormatException catch (error) {
      if (mounted) setState(() => _status = error.message);
    } on StateError catch (error) {
      if (mounted) setState(() => _status = error.message);
    } catch (error) {
      if (mounted) setState(() => _status = l.pbFailed('$error'));
    } finally {
      if (mounted) {
        _password.clear();
        setState(() => _busy = false);
      }
    }
  }

  String _checkedPassword() {
    final password = _password.text;
    if (password.length < 12) {
      throw FormatException(l.pbShortPassword);
    }
    return password;
  }

  Future<void> _backup() => _run(() async {
    final password = _checkedPassword();
    final plain = await BastionPhoneBackup().export();
    final encrypted = await compute(_encrypt, (plain, password));
    final day = DateTime.now().toIso8601String().substring(0, 10);
    await widget.files.save('notoryx-phone-backup-$day.json', encrypted);
    if (mounted) {
      setState(() => _status = l.pbCreated);
    }
  });

  Future<void> _restore() => _run(() async {
    if (widget.radio.connection.state != MeshtasticConnectionState.disconnected) {
      throw FormatException(l.pbDisconnectFirst);
    }
    final password = _checkedPassword();
    final encrypted = await widget.files.open();
    if (encrypted == null) return;
    final plain = await compute(_decrypt, (encrypted, password));
    final (summary, values) = BastionPhoneBackup.parse(plain);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(l.pbReplaceQ),
      content: Text(l.pbSummary(summary.exportedAt.toString().substring(0, 16), '${summary.appVersion}',
          summary.radios, summary.messages, summary.items)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.pbReplace)),
      ],
    ));
    if (confirmed != true || !mounted) return;
    await BastionPhoneBackup().restore(values);
    if (!mounted) return;
    await showDialog<void>(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      title: Text(l.pbRestored),
      content: Text(l.pbRestoredBody),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text(l.pvCloseApp))],
    ));
    await closeApp();
  });

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: Text(l.pbTitle)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(l.pbIntro),
        const SizedBox(height: 16),
        TextField(controller: _password, obscureText: true, enableSuggestions: false,
            autocorrect: false, enabled: !_busy,
            decoration: InputDecoration(labelText: l.pbPassword,
                border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _busy ? null : _backup,
            icon: const Icon(Icons.lock), label: Text(l.pbCreate)),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _busy ? null : _restore,
            icon: const Icon(Icons.restore_page_outlined), label: Text(l.pbRestore)),
        if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        if (_status != null) Padding(padding: const EdgeInsets.all(16), child: Text(_status!)),
      ]),
    ),
  );
}
