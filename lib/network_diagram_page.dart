import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'node_detail_page.dart';
import 'services/bastion_topology.dart';
import 'services/meshtastic_radio_coordinator.dart';

/// Where each dot goes.
class TopologyLayout {
  const TopologyLayout(this.centers, this.radii, this.center, this.gap, this.rings);

  final Map<int, Offset> centers;
  final Map<int, double> radii;
  final Offset center;
  final double gap;
  final int rings;

  /// The dot under [p], allowing a finger-sized margin.
  int? hit(Offset p, {double slop = 16}) {
    int? best;
    var bestD = double.infinity;
    for (final e in centers.entries) {
      final d = (e.value - p).distance;
      if (d <= radii[e.key]! + slop && d < bestD) {
        best = e.key;
        bestD = d;
      }
    }
    return best;
  }
}

/// Your radio in the middle, nodes on rings by hops. Rings after the first
/// are ordered by where their links sit on the ring inside, so lines cross
/// less.
TopologyLayout layoutTopology(BastionTopology t, Size size) {
  final rings = t.rings;
  final center = Offset(size.width / 2, size.height / 2);
  final maxR = math.max(0.0, math.min(size.width, size.height) / 2 - 18);
  final gap = rings == 0 ? 0.0 : maxR / rings;
  final most = t.dots.values.fold(1, (m, d) => math.max(m, d.links));
  final near = <int, Set<int>>{};
  for (final (a, b) in t.links.keys) {
    (near[a] ??= {}).add(b);
    (near[b] ??= {}).add(a);
  }
  final angle = <int, double>{};
  final centers = <int, Offset>{};
  final radii = <int, double>{};
  for (final d in t.dots.values.where((d) => d.ring == 0)) {
    angle[d.num] = 0;
    centers[d.num] = center;
    radii[d.num] = 11;
  }
  for (var r = 1; r <= rings; r++) {
    final ids = [
      for (final d in t.dots.values)
        if (d.ring == r) d.num,
    ]..sort((a, b) => t.dots[b]!.links.compareTo(t.dots[a]!.links));
    if (r > 1) {
      double score(int id) {
        var x = 0.0, y = 0.0;
        for (final n in near[id] ?? const <int>{}) {
          final a = angle[n];
          if (a == null) continue;
          x += math.cos(a);
          y += math.sin(a);
        }
        if (x == 0 && y == 0) return double.infinity;
        final a = math.atan2(y, x);
        return a < 0 ? a + 2 * math.pi : a;
      }

      final s = {for (final id in ids) id: score(id)};
      ids.sort((a, b) => s[a]!.compareTo(s[b]!));
    }
    for (var i = 0; i < ids.length; i++) {
      final a = -math.pi / 2 + (i + (r.isEven ? .5 : 0)) * 2 * math.pi / ids.length;
      angle[ids[i]] = a < 0 ? a + 2 * math.pi : a;
      centers[ids[i]] = center + Offset(math.cos(a) * gap * r, math.sin(a) * gap * r);
      radii[ids[i]] = 5 + 6 * math.sqrt(t.dots[ids[i]]!.links / most);
    }
  }
  return TopologyLayout(centers, radii, center, gap, rings);
}

class _Painter extends CustomPainter {
  _Painter(this.t, this.layout, this.scheme, this.labelStyle);

  final BastionTopology t;
  final TopologyLayout layout;
  final ColorScheme scheme;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = scheme.outlineVariant.withValues(alpha: .6);
    for (var i = 1; i <= layout.rings; i++) {
      canvas.drawCircle(layout.center, layout.gap * i, ring);
    }
    for (final MapEntry(key: (a, b), value: snr) in t.links.entries) {
      // Stronger links are bolder; links only known from hearing directly
      // are thin.
      final f = snr == null ? .3 : ((snr + 20) / 30).clamp(.15, 1.0);
      canvas.drawLine(
        layout.centers[a]!,
        layout.centers[b]!,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1 + 3 * f
          ..color = scheme.primary.withValues(alpha: .25 + .6 * f),
      );
    }
    for (final d in t.dots.values) {
      final c = layout.centers[d.num]!, r = layout.radii[d.num]!;
      canvas.drawCircle(c, r, Paint()..color = d.ring == 0 ? scheme.tertiary : scheme.primary);
      canvas.drawCircle(c, r, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = scheme.surface);
    }
    final busiest = t.dots.values.toList()
      ..sort((a, b) => a.ring == 0 ? -1 : b.ring == 0 ? 1 : b.links.compareTo(a.links));
    for (final d in busiest.take(14)) {
      final tp = TextPainter(
        text: TextSpan(text: d.name, style: labelStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 110);
      final c = layout.centers[d.num]!, r = layout.radii[d.num]!;
      final dx = (c.dx - tp.width / 2).clamp(2.0, math.max(2.0, size.width - tp.width - 2)).toDouble();
      var dy = c.dy + r + 2;
      if (dy + tp.height > size.height) dy = c.dy - r - tp.height - 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(dx - 3, dy - 1, tp.width + 6, tp.height + 2), const Radius.circular(4)),
        Paint()..color = scheme.surface.withValues(alpha: .85),
      );
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(_Painter old) => old.t != t || old.scheme != scheme;
}

/// The mesh drawn as rings of hops around your radio, joined by the links
/// Neighbor Info reports reveal.
class NetworkDiagramPage extends StatelessWidget {
  const NetworkDiagramPage({super.key, required this.radio});

  final MeshtasticRadioCoordinator radio;

  void _open(BuildContext context, int num) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => NodeDetailPage(radio: radio, nodeNum: num)),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.topologyTitle)),
      body: AnimatedBuilder(
        animation: radio,
        builder: (context, _) {
          final local = radio.localNodeNum;
          final t = BastionTopology.build(local: local, nodes: radio.nodes, reports: radio.neighborReports);
          if (t.dots.length <= 1) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.topologyEmpty, textAlign: TextAlign.center),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LayoutBuilder(builder: (context, box) {
                final size = Size(box.maxWidth, box.maxWidth.clamp(220.0, 560.0));
                final layout = layoutTopology(t, size);
                return Semantics(
                  label: l.topologySemantics(t.dots.length - 1, t.rings),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      final num = layout.hit(d.localPosition);
                      if (num != null && num != local) _open(context, num);
                    },
                    child: SizedBox.fromSize(
                      key: const ValueKey('network-diagram'),
                      size: size,
                      child: CustomPaint(
                        painter: _Painter(
                          t,
                          layout,
                          scheme,
                          (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
                              .copyWith(color: scheme.onSurface, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Text(radio.neighborReports.isEmpty ? l.topologyNoReports : l.topologyHint,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              for (var r = 1; r <= t.rings; r++) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l.topologyRing(r - 1), style: Theme.of(context).textTheme.titleSmall),
                ),
                for (final d in t.dots.values.where((d) => d.ring == r))
                  ListTile(
                    key: ValueKey('topo-${d.num}'),
                    dense: true,
                    title: Text(d.name),
                    subtitle: d.links > 0 ? Text(l.topologyLinks(d.links)) : null,
                    onTap: () => _open(context, d.num),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
