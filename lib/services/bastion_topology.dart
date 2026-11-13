import 'dart:collection';

import 'meshtastic_node_database.dart';

/// One dot in the network diagram.
typedef TopologyDot = ({int num, String name, int ring, int links});

/// The mesh as your radio knows it: rings of hops around your radio, and
/// the links Neighbor Info reports and direct hearing reveal.
class BastionTopology {
  const BastionTopology({required this.dots, required this.links});

  final Map<int, TopologyDot> dots;

  /// Pairs (smaller number first) with the best SNR reported for the link,
  /// or null when the link is only known from hearing a node directly.
  final Map<(int, int), double?> links;

  int get rings => dots.values.fold(0, (m, d) => d.ring > m ? d.ring : m);

  /// Builds the diagram. A node's ring is its distance from your radio
  /// through known links, else its reported hops + 1; nodes with neither
  /// are left out. Up to [maxNodes] are kept, those with most links first.
  factory BastionTopology.build({
    required int? local,
    required List<MeshtasticNode> nodes,
    required Map<int, MeshNeighborReport> reports,
    int maxNodes = 60,
  }) {
    final names = {for (final n in nodes) n.num: n.displayName};
    final links = <(int, int), double?>{};
    void link(int a, int b, double? snr) {
      if (a == b) return;
      final k = a < b ? (a, b) : (b, a);
      final old = links[k];
      links[k] = old == null ? snr : (snr == null ? old : (snr > old ? snr : old));
    }

    for (final r in reports.values) {
      for (final n in r.neighbors) {
        link(r.nodeNum, n.nodeNum, n.snr);
      }
    }
    if (local != null) {
      for (final n in nodes) {
        if (n.hopsAway == 0 && n.num != local) link(local, n.num, null);
      }
    }

    // Distance through links from your radio.
    final ring = <int, int>{};
    if (local != null) {
      final adjacent = <int, Set<int>>{};
      for (final (a, b) in links.keys) {
        (adjacent[a] ??= {}).add(b);
        (adjacent[b] ??= {}).add(a);
      }
      ring[local] = 0;
      final queue = Queue<int>()..add(local);
      while (queue.isNotEmpty) {
        final at = queue.removeFirst();
        for (final next in adjacent[at] ?? const <int>{}) {
          if (ring.containsKey(next)) continue;
          ring[next] = ring[at]! + 1;
          queue.add(next);
        }
      }
    }
    for (final n in nodes) {
      if (ring.containsKey(n.num)) continue;
      if (n.hopsAway case final h?) ring[n.num] = h + 1;
    }

    final count = <int, int>{};
    for (final (a, b) in links.keys) {
      count[a] = (count[a] ?? 0) + 1;
      count[b] = (count[b] ?? 0) + 1;
    }
    final keep = (ring.keys.where((n) => n != local).toList()
          ..sort((a, b) {
            final c = (count[b] ?? 0).compareTo(count[a] ?? 0);
            return c != 0 ? c : ring[a]!.compareTo(ring[b]!);
          }))
        .take(maxNodes)
        .toSet();
    if (local != null) keep.add(local);
    return BastionTopology(
      dots: {
        for (final n in keep)
          n: (
            num: n,
            name: names[n] ?? '!${n.toRadixString(16).padLeft(8, '0')}',
            ring: ring[n]!,
            links: count[n] ?? 0,
          ),
      },
      links: {
        for (final e in links.entries)
          if (keep.contains(e.key.$1) && keep.contains(e.key.$2)) e.key: e.value,
      },
    );
  }
}
