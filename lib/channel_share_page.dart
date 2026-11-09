import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'generated/meshtastic/apponly.pb.dart';
import 'qr_scan_page.dart';
import 'services/bastion_channel_import.dart';
import 'services/meshtastic_channel_url.dart';
import 'services/meshtastic_radio_coordinator.dart';

/// Shows the radio's channels as a Meshtastic QR code and link.
class ChannelSharePage extends StatefulWidget {
  const ChannelSharePage({super.key, required this.radio});

  final MeshtasticRadioCoordinator radio;

  @override
  State<ChannelSharePage> createState() => _ChannelSharePageState();
}

class _ChannelSharePageState extends State<ChannelSharePage> {
  late Future<ChannelSet> _channels = widget.radio.readChannelSet();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).csShareTitle)),
        body: FutureBuilder<ChannelSet>(
          future: _channels,
          builder: (context, snapshot) {
            final l = AppLocalizations.of(context);
            if (snapshot.hasError) {
              return ListView(padding: const EdgeInsets.all(16), children: [
                Text(l.csReadFailed('${snapshot.error}')),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () => setState(() => _channels = widget.radio.readChannelSet()),
                    child: Text(l.csRetry),
                  ),
                ),
              ]);
            }
            final set = snapshot.data;
            if (set == null) return const Center(child: CircularProgressIndicator());
            final link = MeshtasticChannelUrl.encode(set);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: QrImageView(data: link, size: 260),
                  ),
                ),
                const SizedBox(height: 16),
                for (final (i, s) in set.settings.indexed)
                  Text((i == 0 ? l.csPrimary : l.csSecondary)(s.name.isEmpty ? l.csDefaultName : s.name)),
                const SizedBox(height: 12),
                SelectableText(link, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: Text(l.csCopyLink),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final copied = l.csCopied;
                      await Clipboard.setData(ClipboardData(text: link));
                      messenger.showSnackBar(SnackBar(content: Text(copied)));
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l.csKeysWarning,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            );
          },
        ),
      );
}

/// Pastes a Meshtastic channel link and applies it to the radio.
class ChannelImportPage extends StatefulWidget {
  const ChannelImportPage({super.key, required this.radio, this.initialLink});

  final MeshtasticRadioCoordinator radio;

  /// A channel link to fill in, e.g. from a Mesh Beacon invitation.
  final String? initialLink;

  @override
  State<ChannelImportPage> createState() => _ChannelImportPageState();
}

class _ChannelImportPageState extends State<ChannelImportPage> {
  final _link = TextEditingController();
  ChannelSet? _set;
  String? _error;
  bool _replace = false;
  bool _saving = false;
  String? _importProblem;

  /// Set after an import that may have changed the radio but was not
  /// verified; blocks a second write until the user checks the radio.
  bool _importUncertain = false;

  @override
  void initState() {
    super.initState();
    final link = widget.initialLink;
    if (link != null) {
      _link.text = link;
      _parse(link);
    }
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _parse(String text) {
    setState(() {
      if (text.trim().isEmpty) {
        _set = null;
        _error = null;
        return;
      }
      try {
        _set = MeshtasticChannelUrl.decode(text);
        _replace = !MeshtasticChannelUrl.isAddLink(text);
        _error = null;
      } on FormatException catch (e) {
        _set = null;
        _error = e.message;
      }
    });
  }

  Future<void> _apply() async {
    final set = _set;
    if (set == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_replace ? l.csReplaceQ : l.csAddQ),
        content: Text(_replace
            ? (set.hasLoraConfig() ? l.csReplaceLoraBody : l.csReplaceBody)
            : l.csAddBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.csApply)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() { _saving = true; _importProblem = null; });
    try {
      final count = await widget.radio.applyChannelSet(set, replace: _replace);
      messenger.showSnackBar(SnackBar(content: Text(count == 0
          ? l.csAlreadyThere
          : l.csWritten(count))));
      navigator.pop();
    } on ChannelImportException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _importProblem = error.radioMayHaveChanged
            ? l.csNotVerified(error.message)
            : l.csRefused(error.message);
        _importUncertain = error.radioMayHaveChanged;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() { _saving = false; _importProblem = l.csFailed('$error'); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final set = _set;
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.csImportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // The scanner plugin has no Windows version; paste the link instead.
          if (!Platform.isWindows)
          FilledButton.tonalIcon(
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l.csScan),
            onPressed: () async {
              final scanned = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => QrScanPage(title: l.csScanTitle)),
              );
              if (scanned == null || !mounted) return;
              _link.text = scanned;
              _parse(scanned);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _link,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l.csLinkLabel,
              hintText: MeshtasticChannelUrl.prefix,
              errorText: _error,
              suffixIcon: IconButton(
                tooltip: l.csPaste,
                icon: const Icon(Icons.content_paste),
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  final text = data?.text ?? '';
                  _link.text = text;
                  _parse(text);
                },
              ),
            ),
            onChanged: _parse,
          ),
          if (set != null) ...[
            const SizedBox(height: 12),
            for (final (i, s) in set.settings.indexed)
              Text('${i + 1}. ${s.name.isEmpty ? l.csDefaultName : s.name}'),
            if (set.hasLoraConfig())
              Text(l.csLora(set.loraConfig.region.name,
                  set.loraConfig.usePreset ? set.loraConfig.modemPreset.name : l.csCustomModem)),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l.csAdd)),
                ButtonSegment(value: true, label: Text(l.csReplaceAll)),
              ],
              selected: {_replace},
              onSelectionChanged: (v) => setState(() => _replace = v.single),
            ),
            const SizedBox(height: 12),
            if (_importProblem != null) ...[
              Text(_importProblem!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _saving || _importUncertain || !widget.radio.canAdminister ? null : _apply,
              child: _saving
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.csApplyRadio),
            ),
          ],
        ],
      ),
    );
  }
}
