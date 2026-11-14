import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';

import 'services/bastion_link_planner.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_units.dart';
import 'services/meshtastic_node_database.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// Checks whether two nodes can reach each other over the terrain between
/// them, with a height profile of the path.
class LinkPlannerPage extends StatefulWidget {
  LinkPlannerPage({super.key, required this.radio, ElevationSource? elevation})
      : elevation = elevation ?? OpenMeteoElevation();
  final MeshtasticRadioCoordinator radio;
  final ElevationSource elevation;

  @override
  State<LinkPlannerPage> createState() => _LinkPlannerPageState();
}

class _LinkPlannerPageState extends State<LinkPlannerPage> {
  int? _from;
  int? _to;
  double _mhz = BastionLinkPlanner.bands.first.$1;
  final _fromHeight = TextEditingController(text: '2');
  final _toHeight = TextEditingController(text: '2');
  LinkAnalysis? _result;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final placed = _placed;
    final local = widget.radio.localNodeNum;
    if (placed.any((n) => n.num == local)) _from = local;
  }

  @override
  void dispose() {
    _fromHeight.dispose();
    _toHeight.dispose();
    super.dispose();
  }

  List<MeshtasticNode> get _placed => [
        for (final n in widget.radio.nodes)
          if (n.hasPosition) n,
      ]..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

  MeshtasticNode? _node(int? num) {
    for (final n in widget.radio.nodes) {
      if (n.num == num) return n;
    }
    return null;
  }

  Future<void> _check() async {
    final a = _node(_from), b = _node(_to);
    final ha = double.tryParse(_fromHeight.text.trim()), hb = double.tryParse(_toHeight.text.trim());
    if (a == null || b == null) return;
    if (ha == null || hb == null || ha < 0 || hb < 0 || ha > 300 || hb > 300) {
      setState(() => _error = AppLocalizations.of(context).lpHeightRange);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final points = BastionLinkPlanner.samplePoints(a.latitude!, a.longitude!, b.latitude!, b.longitude!);
      final ground = await widget.elevation.heights(points);
      final result = BastionLinkPlanner.analyse(
        distanceMeters: BastionLinkPlanner.distance(a.latitude!, a.longitude!, b.latitude!, b.longitude!),
        ground: ground,
        startAntennaMeters: ha,
        endAntennaMeters: hb,
        mhz: _mhz,
      );
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) setState(() => _error = AppLocalizations.of(context).lpTerrainFailed('$error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final placed = _placed;
    final units = BastionPreferences.instance.units;
    final type = Theme.of(context).textTheme;
    final ready = _from != null && _to != null && _from != _to && !_busy;
    return Scaffold(
      appBar: AppBar(title: Text(l.lpTitle)),
      body: ListView(padding: NxSpace.page, children: [
        Text(l.lpIntro,
          style: type.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        if (placed.length < 2)
          NxBanner(tone: NxTone.warning,
            message: l.lpNeedPositions),
        NxSectionLabel(l.lpLink),
        Card(child: Padding(
          padding: const EdgeInsets.all(NxSpace.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _NodePicker(label: l.lpFrom, value: _from, nodes: placed,
              onChanged: (v) => setState(() { _from = v; _result = null; })),
            const SizedBox(height: NxSpace.sm),
            _NodePicker(label: l.lpTo, value: _to, nodes: placed,
              onChanged: (v) => setState(() { _to = v; _result = null; })),
            const SizedBox(height: NxSpace.sm),
            Row(children: [
              Expanded(child: TextField(controller: _fromHeight, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.lpFromAntenna))),
              const SizedBox(width: NxSpace.sm),
              Expanded(child: TextField(controller: _toHeight, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l.lpToAntenna))),
            ]),
            const SizedBox(height: NxSpace.sm),
            DropdownButtonFormField<double>(
              initialValue: _mhz,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.lpBand),
              items: [for (final (mhz, label) in BastionLinkPlanner.bands) DropdownMenuItem(value: mhz, child: Text(label))],
              onChanged: (v) => setState(() { if (v != null) _mhz = v; _result = null; }),
            ),
            const SizedBox(height: NxSpace.sm),
            FilledButton.icon(
              onPressed: ready ? _check : null,
              icon: _busy
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.terrain),
              label: Text(_busy ? l.lpChecking : l.lpCheck),
            ),
            const SizedBox(height: NxSpace.xs),
            Text(l.lpPrivacy, style: type.bodySmall),
          ]),
        )),
        if (_error case final e?) NxBanner(tone: NxTone.danger, message: e),
        if (_result case final r?) ...[
          NxSectionLabel(l.lpResult),
          NxBanner(
            tone: switch (r.verdict) {
              LinkVerdict.clear => NxTone.success,
              LinkVerdict.marginal => NxTone.warning,
              LinkVerdict.blocked => NxTone.danger,
            },
            title: switch (r.verdict) {
              LinkVerdict.clear => l.lpClearTitle,
              LinkVerdict.marginal => l.lpMarginalTitle,
              LinkVerdict.blocked => l.lpBlockedTitle,
            },
            message: switch (r.verdict) {
              LinkVerdict.clear => l.lpClearBody,
              LinkVerdict.marginal => l.lpMarginalBody,
              LinkVerdict.blocked => l.lpBlockedBody(BastionUnitFormat.distance(r.worstAtMeters, units)),
            },
          ),
          NxStatRow(children: [
            NxStatTile(label: l.lpDistance, value: BastionUnitFormat.distance(r.distanceMeters, units)),
            NxStatTile(label: l.lpPathLoss, value: '${r.pathLossDb.toStringAsFixed(0)} dB'),
            NxStatTile(
              label: r.worstClearanceMeters < 0 ? l.lpBlockedBy : l.lpLowestClearance,
              value: '${r.worstClearanceMeters.abs().toStringAsFixed(0)} m',
            ),
          ]),
          const SizedBox(height: NxSpace.xs),
          Card(child: Padding(
            padding: const EdgeInsets.all(NxSpace.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.lpProfile, style: type.titleSmall),
              const SizedBox(height: NxSpace.xs),
              Semantics(
                label: l.lpProfileLabel(r.profile.map((p) => p.groundMeters).reduce((a, b) => a < b ? a : b).round(),
                    r.profile.map((p) => p.groundMeters).reduce((a, b) => a > b ? a : b).round()),
                excludeSemantics: true,
                child: SizedBox(height: 160, child: CustomPaint(
                  size: Size.infinite,
                  painter: _ProfilePainter(r,
                    ground: Theme.of(context).colorScheme.secondary,
                    line: Theme.of(context).colorScheme.primary,
                    blocked: NxStatusColors.of(context).strong(NxTone.danger, Theme.of(context).colorScheme)),
                )),
              ),
              const SizedBox(height: NxSpace.xs),
              Text(l.lpProfileLegend,
                style: type.bodySmall),
            ]),
          )),
          const SizedBox(height: NxSpace.xs),
          Text(l.lpEstimateNote,
            style: type.bodySmall),
        ],
      ]),
    );
  }
}

class _NodePicker extends StatelessWidget {
  const _NodePicker({required this.label, required this.value, required this.nodes, required this.onChanged});
  final String label;
  final int? value;
  final List<MeshtasticNode> nodes;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
        key: ValueKey('$label-$value-${nodes.length}'),
        initialValue: nodes.any((n) => n.num == value) ? value : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [for (final n in nodes) DropdownMenuItem(value: n.num, child: Text(n.displayName, overflow: TextOverflow.ellipsis))],
        onChanged: onChanged,
      );
}

class _ProfilePainter extends CustomPainter {
  _ProfilePainter(this.r, {required this.ground, required this.line, required this.blocked});
  final LinkAnalysis r;
  final Color ground;
  final Color line;
  final Color blocked;

  @override
  void paint(Canvas canvas, Size size) {
    final heights = [for (final p in r.profile) p.groundMeters, r.lineStart, r.lineEnd];
    var lo = heights.reduce((a, b) => a < b ? a : b);
    var hi = heights.reduce((a, b) => a > b ? a : b);
    final pad = (hi - lo) * 0.1 + 5;
    lo -= pad;
    hi += pad;
    final total = r.distanceMeters <= 0 ? 1.0 : r.distanceMeters;
    Offset at(double d, double h) => Offset(size.width * d / total, size.height * (1 - (h - lo) / (hi - lo)));
    final path = Path()..moveTo(0, size.height);
    for (final p in r.profile) {
      path.lineTo(at(p.distanceMeters, p.groundMeters).dx, at(p.distanceMeters, p.groundMeters).dy);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = ground.withValues(alpha: 0.45));
    final sight = Paint()
      ..color = r.verdict == LinkVerdict.blocked ? blocked : line
      ..strokeWidth = 2.5;
    canvas.drawLine(at(0, r.lineStart), at(total, r.lineEnd), sight);
    if (r.verdict == LinkVerdict.blocked) {
      final x = size.width * r.worstAtMeters / total;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()
        ..color = blocked
        ..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(_ProfilePainter old) => old.r != r || old.ground != ground || old.line != line;
}
