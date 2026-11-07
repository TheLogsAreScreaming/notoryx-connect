import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'services/bastion_route_map.dart';
import 'services/meshtastic_node_database.dart';
import 'theme/notoryx_tokens.dart';

/// A small map of a traceroute: the route there as a solid line, the route
/// back as a dashed one, and each node numbered in order.
class TracerouteMap extends StatelessWidget {
  const TracerouteMap({super.key, required this.path, required this.nodes, required this.name});

  final RouteMapPath path;

  /// Known nodes, used for positions.
  final List<MeshtasticNode> nodes;
  final String Function(int node) name;

  LatLng? _at(int num) {
    for (final n in nodes) {
      if (n.num == num && n.latitude != null && n.longitude != null) return LatLng(n.latitude!, n.longitude!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final there = [for (final n in path.towards) ?_at(n)];
    final back = [for (final n in path.back) ?_at(n)];
    final all = [...there, ...back];
    final order = <int>[...path.towards, for (final n in path.back) if (!path.towards.contains(n)) n];
    final bounds = LatLngBounds.fromPoints(all);
    final single = all.toSet().length < 2;
    final summary = 'Map of the route through ${[for (final n in path.towards) name(n)].join(', ')}'
        '${path.back.isEmpty ? '' : ', returning through ${[for (final n in path.back) name(n)].join(', ')}'}.';
    return Card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 240,
        child: Semantics(
          label: summary,
          excludeSemantics: true,
          child: FlutterMap(
            options: MapOptions(
              initialCameraFit: single
                  ? null
                  : CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(36)),
              initialCenter: all.first,
              initialZoom: 13,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.bastionmesh.connect',
                maxNativeZoom: 19,
              ),
              PolylineLayer(polylines: [
                if (there.length >= 2)
                  Polyline(points: there, strokeWidth: 4, color: scheme.primary),
                if (back.length >= 2)
                  Polyline(points: back, strokeWidth: 3, color: scheme.tertiary,
                    pattern: StrokePattern.dashed(segments: const [10, 6])),
              ]),
              MarkerLayer(markers: [
                for (final (i, n) in order.indexed)
                  if (_at(n) case final point?)
                    Marker(
                      point: point,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: scheme.surface, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text('${i + 1}', style: TextStyle(
                            color: scheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ),
              ]),
            ],
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(NxSpace.sm),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: NxSpace.md, runSpacing: NxSpace.xxs, children: [
            _Legend(color: scheme.primary, label: 'Route there', dashed: false),
            if (back.length >= 2) _Legend(color: scheme.tertiary, label: 'Route back', dashed: true),
          ]),
          const SizedBox(height: NxSpace.xs),
          for (final (i, n) in order.indexed)
            Text('${i + 1}. ${name(n)}', style: Theme.of(context).textTheme.bodyMedium),
          if (path.unplaced.isNotEmpty) ...[
            const SizedBox(height: NxSpace.xs),
            Text(
              'No position for ${[for (final n in path.unplaced) name(n)].join(', ')}, '
              'so the line goes straight past ${path.unplaced.length == 1 ? 'it' : 'them'}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: NxSpace.xxs),
          Text('Map © OpenStreetMap contributors', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    ]));
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.dashed});
  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 24, child: Row(children: [
          for (var i = 0; i < (dashed ? 2 : 1); i++) ...[
            Expanded(child: Container(height: 3, color: color)),
            if (dashed && i == 0) const SizedBox(width: 4),
          ],
        ])),
        const SizedBox(width: NxSpace.xxs),
        Text('$label${dashed ? ' (dashed)' : ' (solid)'}', style: Theme.of(context).textTheme.labelMedium),
      ]);
}
