import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/meshtastic_nodedb_import.dart';
import 'services/meshtastic_radio_coordinator.dart';

MeshtasticNodeDbExport _parse(String text) => MeshtasticNodeDbExport.parse(text);

/// Opens a node database file; faked in tests.
abstract interface class NodeDbFiles {
  /// The chosen file's text, or null if the user cancelled.
  Future<String?> open();
}

class SystemNodeDbFiles implements NodeDbFiles {
  const SystemNodeDbFiles();

  @override
  Future<String?> open() async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(
        label: 'JSON',
        extensions: ['json'],
        mimeTypes: ['application/json', 'text/plain'],
        uniformTypeIdentifiers: ['public.json'],
      ),
    ]);
    if (file == null) return null;
    if (await file.length() > MeshtasticNodeDbExport.maxFileBytes) {
      throw const FormatException('tooLarge');
    }
    return file.readAsString();
  }
}

/// Adds nodes from a node database file saved in the Meshtastic app to the
/// nodes this phone remembers. Nothing is sent to the radio.
class NodeDbImportPage extends StatefulWidget {
  const NodeDbImportPage({
    super.key,
    required this.radio,
    this.files = const SystemNodeDbFiles(),
  });

  final MeshtasticRadioCoordinator radio;
  final NodeDbFiles files;

  @override
  State<NodeDbImportPage> createState() => _NodeDbImportPageState();
}

class _NodeDbImportPageState extends State<NodeDbImportPage> {
  MeshtasticNodeDbExport? _export;
  bool _includeInternet = false;
  bool _busy = false;
  String? _status;

  AppLocalizations get l => AppLocalizations.of(context);

  String _problem(FormatException e) => switch (e.message) {
        'tooLarge' => l.ndbTooLarge,
        'newerVersion' => l.ndbNewerVersion,
        _ => l.ndbNotNodeDb,
      };

  Future<void> _choose() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final text = await widget.files.open();
      if (text == null) return;
      final export = await compute(_parse, text);
      if (!mounted) return;
      setState(() {
        _export = export;
        _includeInternet = false;
        _status = export.nodes.isEmpty ? l.ndbEmpty : null;
      });
    } on FormatException catch (e) {
      if (mounted) setState(() => _status = _problem(e));
    } catch (e) {
      if (mounted) setState(() => _status = l.ndbFailed('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final export = _export;
    if (export == null) return;
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final result = await widget.radio.importNodeDatabase(
        export,
        includeInternet: _includeInternet,
      );
      if (!mounted) return;
      setState(() {
        if (result == null) {
          _status = l.ndbNotSaved;
        } else {
          _status = l.ndbDone(result.added, result.updated, result.keys,
              widget.radio.nodeName(result.radio));
          _export = null;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _status = l.ndbFailed('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final export = _export;
    final radio = widget.radio.nodeListRadio ?? export?.myNodeNum;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(l.ndbTitle)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.ndbIntro),
            const SizedBox(height: 8),
            Text(l.ndbHowTo, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('ndb-choose'),
              onPressed: _busy ? null : _choose,
              icon: const Icon(Icons.file_open_outlined),
              label: Text(l.ndbChoose),
            ),
            if (export != null && export.nodes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        export.exportedFromName == null
                            ? l.ndbFileSummary
                            : l.ndbFileFrom(export.exportedFromName!),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(l.ndbHeardByRadio(export.heardByRadio.length)),
                      Text(l.ndbFavorites(export.favoriteCount)),
                      Text(l.ndbInternet(export.internetOnly.length)),
                    ],
                  ),
                ),
              ),
              if (export.internetOnly.isNotEmpty)
                SwitchListTile(
                  key: const ValueKey('ndb-internet'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.ndbIncludeInternet),
                  subtitle: Text(l.ndbIncludeInternetSub(
                      MeshtasticNodeDbExport.internetLimit)),
                  value: _includeInternet,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() => _includeInternet = v),
                ),
              const SizedBox(height: 8),
              if (radio != null)
                Text(l.ndbAddsTo(widget.radio.nodeName(radio)),
                    style: Theme.of(context).textTheme.bodySmall),
              Text(l.ndbNothingSent,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const ValueKey('ndb-import'),
                onPressed: _busy || radio == null ? null : _import,
                icon: const Icon(Icons.download_done_outlined),
                label: Text(l.ndbImport(
                    export.pick(includeInternet: _includeInternet).length)),
              ),
            ],
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_status != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Semantics(liveRegion: true, child: Text(_status!)),
              ),
          ],
        ),
      ),
    );
  }
}
