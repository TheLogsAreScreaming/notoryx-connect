import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'generated/meshtastic/apponly.pb.dart';
import 'qr_scan_page.dart';
import 'services/bastion_channel_import.dart';
import 'services/bastion_nfc.dart';
import 'services/bastion_team_setup.dart';
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
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    BastionNfc.isAvailable().then((v) {
      if (mounted) setState(() => _nfcAvailable = v);
    });
  }

  Future<void> _writeNfc(BuildContext context, String link) async {
    final l = AppLocalizations.of(context);
    if (!mounted) return;
    var writing = true;
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(l.csNfcTitle),
          content: Row(children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 16),
            Expanded(child: Text(l.csNfcWaiting)),
          ]),
          actions: [
            TextButton(
              onPressed: () {
                writing = false;
                BastionNfc.cancel();
                Navigator.of(ctx).pop();
              },
              child: Text(l.commonCancel),
            ),
          ],
        ),
      ),
    ));
    await BastionNfc.writeUri(
      link,
      onError: (reason) {
        if (!mounted) return;
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        if (!writing) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.csNfcError(reason))),
        );
      },
      onDone: () {
        if (!mounted) return;
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.csNfcDone)),
        );
      },
    );
  }

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
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: Text(l.csCopyLink),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final copied = l.csCopied;
                        await Clipboard.setData(ClipboardData(text: link));
                        messenger.showSnackBar(SnackBar(content: Text(copied)));
                      },
                    ),
                    if (_nfcAvailable)
                      OutlinedButton.icon(
                        key: const ValueKey('cs-nfc-write'),
                        icon: const Icon(Icons.nfc),
                        label: Text(l.csNfcWrite),
                        onPressed: () => _writeNfc(context, link),
                      ),
                  ],
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

  /// Set when the code was a team setup rather than a plain channel link.
  TeamSetup? _team;

  /// Whether a team setup's contacts are added to the trip too.
  bool _addContacts = true;
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
      _team = null;
      if (text.trim().isEmpty) {
        _set = null;
        _error = null;
        return;
      }
      try {
        if (TeamSetup.looksLike(text)) {
          final team = TeamSetup.decode(text);
          _team = team;
          _set = team.channels;
          // A team setup adds to what the radio has unless you choose otherwise.
          _replace = false;
        } else {
          _set = MeshtasticChannelUrl.decode(text);
          _replace = !MeshtasticChannelUrl.isAddLink(text);
        }
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
      var added = 0;
      if (_team case final team? when _addContacts) {
        final trip = widget.radio.trip;
        added = team.newMembers(trip.plan, self: widget.radio.localNodeNum);
        await trip.updatePlan(team.mergeInto(trip.plan, self: widget.radio.localNodeNum));
      }
      final written = count == 0 ? l.csAlreadyThere : l.csWritten(count);
      messenger.showSnackBar(SnackBar(content: Text(added == 0 ? written : '$written ${l.teamAdded(added)}')));
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
            if (_team case final team? when team.members.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l.teamContacts(team.members.length), style: Theme.of(context).textTheme.titleSmall),
              Text(team.members.map((m) => m.name.isEmpty ? '!${m.num.toRadixString(16).padLeft(8, '0')}' : m.name).join(', ')),
              SwitchListTile(
                key: const ValueKey('team-add-contacts'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.teamAddContacts),
                subtitle: Text(l.teamAddContactsSub(team.newMembers(widget.radio.trip.plan, self: widget.radio.localNodeNum))),
                value: _addContacts,
                onChanged: (v) => setState(() => _addContacts = v),
              ),
            ],
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

/// One QR code with the radio's channels and LoRa settings plus the trip
/// contacts, so a whole team is set up in one scan. As on NOTORYX Core.
class TeamSharePage extends StatefulWidget {
  const TeamSharePage({super.key, required this.radio});
  final MeshtasticRadioCoordinator radio;

  @override
  State<TeamSharePage> createState() => _TeamSharePageState();
}

class _TeamSharePageState extends State<TeamSharePage> {
  late Future<ChannelSet> _channels = widget.radio.readChannelSet();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.teamTitle)),
      body: FutureBuilder<ChannelSet>(
        future: _channels,
        builder: (context, snapshot) {
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
          final radio = widget.radio;
          final team = TeamSetup.from(
            channels: set,
            plan: radio.trip.plan,
            nameOf: radio.nodeName,
            self: radio.localNodeNum,
          );
          final code = team.encode();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l.teamIntro),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  key: const ValueKey('team-qr'),
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(data: code, size: 280),
                ),
              ),
              const SizedBox(height: 16),
              Text(l.teamChannels, style: Theme.of(context).textTheme.titleSmall),
              for (final (i, s) in set.settings.indexed)
                Text((i == 0 ? l.csPrimary : l.csSecondary)(s.name.isEmpty ? l.csDefaultName : s.name)),
              const SizedBox(height: 12),
              Text(l.teamContacts(team.members.length), style: Theme.of(context).textTheme.titleSmall),
              for (final m in team.members) Text(m.name),
              const SizedBox(height: 12),
              Text(l.teamHowTo),
              const SizedBox(height: 12),
              Text(l.csKeysWarning, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          );
        },
      ),
    );
  }
}
