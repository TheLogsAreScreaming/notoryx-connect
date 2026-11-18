import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_traffic.dart';
import 'services/meshtastic_node_database.dart';

/// Colours and names of the six Traffic map packet groups.
abstract final class TrafficStyle {
  static Color color(TrafficKind kind) => switch (kind) {
        TrafficKind.advert => const Color(0xFFFF5AA8),
        TrafficKind.direct => const Color(0xFF4C8DFF),
        TrafficKind.channel => const Color(0xFF34D27B),
        TrafficKind.ack => const Color(0xFF2FD3E3),
        TrafficKind.trace => const Color(0xFFFF9F2E),
        TrafficKind.other => const Color(0xFFB27CFF),
      };

  static String name(AppLocalizations l, TrafficKind kind) => switch (kind) {
        TrafficKind.advert => l.trafficAdvert,
        TrafficKind.direct => l.trafficDirect,
        TrafficKind.channel => l.trafficChannel,
        TrafficKind.ack => l.trafficAck,
        TrafficKind.trace => l.trafficTrace,
        TrafficKind.other => l.trafficOther,
      };
}

/// Frosted glass behind the route card and the toolbar.
class TrafficGlass extends StatelessWidget {
  const TrafficGlass({super.key, required this.child, this.radius = 22, this.padding = EdgeInsets.zero});

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Packets travelling across the map, hop by hop. Lives inside FlutterMap.
class TrafficLayer extends StatefulWidget {
  const TrafficLayer({
    super.key,
    required this.packets,
    required this.nodes,
    required this.kinds,
    required this.onRoute,
    this.labels = true,
    this.clock = DateTime.now,
  });

  final Stream<TrafficPacket> packets;

  /// The node list to resolve names and positions against, read per packet.
  final Map<int, MeshtasticNode> Function() nodes;

  /// Packet groups to draw.
  final Set<TrafficKind> kinds;

  /// Called with every shown route; the route card displays the latest.
  final ValueChanged<TrafficRoute> onRoute;
  final bool labels;
  final DateTime Function() clock;

  @override
  State<TrafficLayer> createState() => _TrafficLayerState();
}

class _TrafficLayerState extends State<TrafficLayer> with SingleTickerProviderStateMixin {
  final TrafficQueue _queue = TrafficQueue();
  late final Ticker _ticker = createTicker(_onTick);
  StreamSubscription<TrafficPacket>? _sub;

  bool get _still => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    _sub = widget.packets.listen(_onPacket);
  }

  @override
  void didUpdateWidget(TrafficLayer old) {
    super.didUpdateWidget(old);
    if (old.packets != widget.packets) {
      unawaited(_sub?.cancel());
      _sub = widget.packets.listen(_onPacket);
    }
  }

  void _onPacket(TrafficPacket packet) {
    if (!mounted || !widget.kinds.contains(packet.kind)) return;
    final route = TrafficRoute.build(packet, widget.nodes());
    widget.onRoute(route);
    if (route.placed.isEmpty) return;
    _queue.add(route, widget.clock());
    if (!_ticker.isActive) unawaited(_ticker.start());
    setState(() {});
  }

  void _onTick(Duration _) {
    if (!mounted) return;
    final busy = _queue.tick(widget.clock(), reduceMotion: _still);
    if (!busy) _ticker.stop();
    setState(() {});
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    _ticker.dispose();
    super.dispose();
  }

  static LatLng _at(TrafficRouteStop s) => LatLng(s.latitude!, s.longitude!);

  static LatLng _lerp(LatLng a, LatLng b, double t) =>
      LatLng(a.latitude + (b.latitude - a.latitude) * t, a.longitude + (b.longitude - a.longitude) * t);

  @override
  Widget build(BuildContext context) {
    if (_queue.active.isEmpty) return const SizedBox.shrink();
    final now = widget.clock();
    final still = _still;
    final lines = <Polyline>[];
    final marks = <Marker>[];
    for (final a in _queue.active) {
      final elapsed = now.difference(a.started);
      final route = a.route;
      final stops = route.placed;
      final pts = [for (final s in stops) _at(s)];
      final f = TrafficTiming.frame(elapsed, route.legs, reduceMotion: still);
      if (f.done) continue;
      final color = TrafficStyle.color(route.packet.kind);
      final pulse = (elapsed.inMilliseconds % 1100) / 1100;
      for (var i = 0; i < route.legs; i++) {
        if (i < f.leg) {
          lines.add(Polyline(points: [pts[i], pts[i + 1]], strokeWidth: 3.5,
              color: color.withValues(alpha: 0.9 * f.opacity)));
        } else if (i == f.leg) {
          final dot = _lerp(pts[i], pts[i + 1], f.t);
          lines
            ..add(Polyline(points: [pts[i], dot], strokeWidth: 3.5, color: color.withValues(alpha: 0.95)))
            ..add(Polyline(points: [dot, pts[i + 1]], strokeWidth: 2.5,
                color: color.withValues(alpha: 0.55), pattern: const StrokePattern.dotted()));
          if (!still) {
            marks.add(Marker(point: dot, width: 22, height: 22, child: _Dot(color: color)));
          }
        } else {
          lines.add(Polyline(points: [pts[i], pts[i + 1]], strokeWidth: 2.5,
              color: color.withValues(alpha: 0.55 * f.opacity), pattern: const StrokePattern.dotted()));
        }
      }
      // Origin rings while the packet sets off; ours once it arrives.
      if (f.leg == 0 && f.opacity >= 1 || route.legs == 0) {
        marks.add(Marker(point: pts.first, width: 64, height: 64,
            child: _Ring(color: color, pulse: still ? 0.5 : pulse, opacity: f.opacity)));
      }
      if (route.legs > 0 && f.leg >= route.legs) {
        marks.add(Marker(point: pts.last, width: 64, height: 64,
            child: _Ring(color: color, pulse: still ? 0.5 : pulse, opacity: f.opacity)));
      }
      if (widget.labels) {
        for (final (i, s) in stops.indexed) {
          // Skip our own end; the node pin already names it.
          if (i == stops.length - 1 && stops.length > 1) continue;
          marks.add(Marker(
            point: pts[i],
            width: 120,
            height: 22,
            alignment: const Alignment(0, 2.4),
            child: IgnorePointer(child: Opacity(opacity: f.opacity, child: _HopLabel(text: s.label, color: color))),
          ));
        }
      }
    }
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(children: [
          PolylineLayer(polylines: lines),
          MarkerLayer(markers: marks),
        ]),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color, blurRadius: 10, spreadRadius: 3),
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 6),
            ],
          ),
        ),
      );
}

class _Ring extends StatelessWidget {
  const _Ring({required this.color, required this.pulse, required this.opacity});
  final Color color;
  final double pulse;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final size = 20 + 40 * pulse;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12 * (1 - pulse) * opacity),
          border: Border.all(color: color.withValues(alpha: 0.8 * (1 - pulse) * opacity), width: 2),
        ),
      ),
    );
  }
}

class _HopLabel extends StatelessWidget {
  const _HopLabel({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.7)),
          ),
          child: Text(text, maxLines: 1, overflow: TextOverflow.fade, softWrap: false,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      );
}

/// A coloured dot and name for each packet group.
class TrafficLegend extends StatelessWidget {
  const TrafficLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodySmall;
    return Wrap(spacing: 14, runSpacing: 4, children: [
      for (final kind in TrafficKind.values)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 14, height: 4,
              decoration: BoxDecoration(color: TrafficStyle.color(kind), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(TrafficStyle.name(l, kind), style: style),
        ]),
    ]);
  }
}

/// A packet group's name on its colour.
class TrafficPill extends StatelessWidget {
  const TrafficPill({super.key, required this.kind});
  final TrafficKind kind;

  @override
  Widget build(BuildContext context) {
    final color = TrafficStyle.color(kind);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(TrafficStyle.name(AppLocalizations.of(context), kind),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

/// The latest packet's route, signal and the legend, in frosted glass.
class TrafficRouteCard extends StatefulWidget {
  const TrafficRouteCard({super.key, required this.route, this.clock = DateTime.now, this.onTap});

  /// Null until the first packet arrives.
  final TrafficRoute? route;
  final DateTime Function() clock;
  final VoidCallback? onTap;

  @override
  State<TrafficRouteCard> createState() => _TrafficRouteCardState();
}

class _TrafficRouteCardState extends State<TrafficRouteCard> {
  Timer? _age;

  @override
  void initState() {
    super.initState();
    _age = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.route != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _age?.cancel();
    super.dispose();
  }

  /// "2 hops · −97 dBm · SNR 6.5 · 1 not on map · 3s".
  static String stats(AppLocalizations l, TrafficRoute route, DateTime now) {
    final p = route.packet;
    final age = now.difference(p.heard).inSeconds.clamp(0, 359999);
    return [
      switch (p.hopsAway) {
        null => l.trafficHopsUnknown,
        0 => l.trafficDirectHop,
        final h => l.trafficHops(h),
      },
      if (p.rssi case final r?) '$r dBm',
      if (p.snr case final s?) 'SNR ${_num(s)}',
      if (route.notOnMap.isNotEmpty) l.trafficNotOnMapCount(route.notOnMap.length),
      if (p.viaMqtt) 'MQTT',
      l.trafficAge(age),
    ].join(' · ');
  }

  static String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');

  static String heardFrom(AppLocalizations l, TrafficRoute route) {
    final hop = route.lastHop;
    final name = hop == null || hop.unknownCount > 0 ? l.trafficUnnamedRelay : hop.label;
    final snr = route.packet.snr;
    return snr == null ? l.trafficHeardFrom(name) : l.trafficHeardFromSnr(name, _num(snr));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final route = widget.route;
    final small = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
      if (route == null)
        Text(l.trafficListening, style: theme.textTheme.bodyMedium)
      else ...[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: false,
          child: Text(route.summary, key: const ValueKey('traffic-route'), maxLines: 1,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 4),
        Row(children: [
          TrafficPill(kind: route.packet.kind),
          const SizedBox(width: 8),
          Expanded(child: Text(heardFrom(l, route), maxLines: 1, overflow: TextOverflow.ellipsis, style: small)),
        ]),
        const SizedBox(height: 2),
        Text(stats(l, route, widget.clock()), style: small),
        if (route.notOnMap.isNotEmpty)
          Text(l.trafficNotOnMap(route.notOnMap.map((s) => s.label).join(', ')), style: small),
        if (route.unknownRelays > 0 && !route.packet.fullPath)
          Text(l.trafficUnnamed(route.unknownRelays), style: small),
      ],
      const SizedBox(height: 8),
      const TrafficLegend(),
    ]);
    return Semantics(
      container: true,
      liveRegion: true,
      button: widget.onTap != null && route != null,
      child: TrafficGlass(
        child: InkWell(
          key: const ValueKey('traffic-card'),
          onTap: route == null ? null : widget.onTap,
          child: Padding(padding: const EdgeInsets.fromLTRB(14, 10, 14, 10), child: body),
        ),
      ),
    );
  }
}

/// One button of the right-hand toolbar.
class TrafficToolButton {
  const TrafficToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selected = false,
    this.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool selected;
  final Key? key;
}

/// The frosted vertical pill on the right of the map.
class TrafficToolbar extends StatelessWidget {
  const TrafficToolbar({super.key, required this.buttons});

  final List<TrafficToolButton> buttons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    return TrafficGlass(
      radius: 28,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final b in buttons)
          Semantics(
            key: b.key,
            button: true,
            selected: b.selected,
            label: b.label,
            onTap: b.onPressed,
            excludeSemantics: true,
            child: InkWell(
              onTap: b.onPressed,
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 64, minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(b.icon, color: b.selected ? accent : theme.colorScheme.onSurface),
                    const SizedBox(height: 2),
                    Text(b.label,
                        maxLines: 1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: b.selected ? accent : theme.colorScheme.onSurface,
                          fontWeight: b.selected ? FontWeight.w700 : null,
                        )),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
