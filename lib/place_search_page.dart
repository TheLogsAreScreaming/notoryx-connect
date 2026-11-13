import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_place_search.dart';
import 'services/bastion_waypoints.dart';
import 'services/meshtastic_node_database.dart';
import 'theme/notoryx_tokens.dart';

/// Finds a node, waypoint or (online, on request) a named place, and returns
/// the chosen [PlaceResult] so the map can move there.
class PlaceSearchPage extends StatefulWidget {
  const PlaceSearchPage({super.key, required this.nodes, required this.waypoints, this.online});

  final List<MeshtasticNode> nodes;
  final List<MeshWaypoint> waypoints;

  /// Overridden in tests; the real Nominatim service is used when null.
  final NominatimPlaceSearch? online;

  @override
  State<PlaceSearchPage> createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends State<PlaceSearchPage> {
  final _query = TextEditingController();
  late final NominatimPlaceSearch _online = widget.online ?? NominatimPlaceSearch();
  List<PlaceResult> _local = const [];
  List<PlaceResult>? _found;
  String? _onlineFor;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _changed(String text) => setState(() {
    _local = BastionPlaceSearch.local(text, nodes: widget.nodes, waypoints: widget.waypoints);
    if (text.trim() != _onlineFor) {
      _found = null;
      _error = null;
    }
  });

  Future<void> _searchOnline() async {
    final l = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final text = _query.text.trim();
    if (text.isEmpty || _busy) return;
    if (_online.tooSoon) {
      setState(() => _error = l.psTooSoon);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final found = await _online.search(text, language: language);
      if (!mounted) return;
      setState(() {
        _found = found;
        _onlineFor = text;
      });
    } catch (_) {
      if (mounted) setState(() => _error = l.psOnlineFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hasText = _query.text.trim().isNotEmpty;
    final found = _found;
    return Scaffold(
      appBar: AppBar(title: Text(l.psTitle)),
      body: ListView(
        padding: const EdgeInsets.all(NxSpace.md),
        children: [
          TextField(
            key: const ValueKey('place-query'),
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: l.psHint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: _changed,
          ),
          const SizedBox(height: NxSpace.sm),
          if (hasText && _local.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: NxSpace.sm),
              child: Text(l.psNoLocal),
            ),
          for (final r in _local) _ResultTile(result: r),
          if (hasText) ...[
            const Divider(height: NxSpace.xl),
            Text(l.psOnlineNote, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: NxSpace.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                key: const ValueKey('place-online'),
                onPressed: _busy ? null : _searchOnline,
                icon: _busy
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.travel_explore),
                label: Text(l.psSearchOnline),
              ),
            ),
            if (_error case final error?)
              Padding(
                padding: const EdgeInsets.only(top: NxSpace.sm),
                child: Semantics(liveRegion: true, child: Text(error)),
              ),
            if (found != null && found.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: NxSpace.sm),
                child: Semantics(liveRegion: true, child: Text(l.psNoOnline)),
              ),
            if (found != null)
              for (final r in found) _ResultTile(result: r),
            if (found != null && found.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: NxSpace.sm),
                child: Text(l.psAttribution, style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});
  final PlaceResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (icon, kind) = switch (result.kind) {
      PlaceKind.node => (Icons.router_outlined, l.psKindNode),
      PlaceKind.waypoint => (Icons.place_outlined, l.psKindWaypoint),
      PlaceKind.online => (Icons.public, l.psKindOnline),
    };
    final where = '${result.latitude.toStringAsFixed(5)}, ${result.longitude.toStringAsFixed(5)}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, semanticLabel: kind),
      title: Text(result.name),
      subtitle: Text(result.detail.isEmpty ? where : '${result.detail}\n$where'),
      onTap: () => Navigator.of(context).pop(result),
    );
  }
}
