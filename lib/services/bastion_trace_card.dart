import 'dart:math' as math;

import 'bastion_geo.dart';
import 'meshtastic_node_database.dart';
import 'meshtastic_traceroute.dart';

/// One node on a traceroute, as the trace card shows it.
class TraceCardHop {
  const TraceCardHop({required this.num, required this.name, this.snrDb, this.latitude, this.longitude});

  final int num;
  final String name;

  /// SNR (dB) this node heard the previous one at; null when not recorded.
  final double? snrDb;
  final double? latitude;
  final double? longitude;

  bool get hasPosition => latitude != null && longitude != null;
  String get nodeId => '!${num.toRadixString(16).padLeft(8, '0')}';
}

/// Everything a shareable trace card shows: who traced, to whom, when, how
/// long the round trip took and every hop there and back.
class TraceCard {
  const TraceCard({
    required this.sender,
    required this.target,
    required this.sentAt,
    required this.roundTrip,
    required this.towards,
    required this.back,
    this.senderLatitude,
    this.senderLongitude,
  });

  /// Builds a card from a finished [result], naming and placing nodes from
  /// [nodes]. [local] is this radio, [destination] the traced node.
  factory TraceCard.from(
    TracerouteResult result, {
    required int local,
    required int destination,
    required List<MeshtasticNode> nodes,
    required String Function(int num) name,
    required DateTime sentAt,
    required Duration roundTrip,
  }) {
    MeshtasticNode? find(int num) {
      for (final n in nodes) {
        if (n.num == num) return n;
      }
      return null;
    }

    TraceCardHop hop(TracerouteHop h) {
      final node = find(h.nodeNum);
      return TraceCardHop(
        num: h.nodeNum,
        name: name(h.nodeNum),
        snrDb: h.snrDb,
        latitude: node?.latitude,
        longitude: node?.longitude,
      );
    }

    final me = find(local);
    return TraceCard(
      sender: name(local),
      target: name(destination),
      sentAt: sentAt,
      roundTrip: roundTrip,
      towards: [for (final h in result.towards) hop(h)],
      back: [for (final h in result.back) hop(h)],
      senderLatitude: me?.latitude,
      senderLongitude: me?.longitude,
    );
  }

  final String sender;
  final String target;
  final DateTime sentAt;
  final Duration roundTrip;

  /// From the first relay to the destination.
  final List<TraceCardHop> towards;

  /// From the destination's first relay back to this radio; empty when the
  /// firmware didn't report the way back.
  final List<TraceCardHop> back;
  final double? senderLatitude;
  final double? senderLongitude;

  bool get senderHasPosition => senderLatitude != null && senderLongitude != null;

  /// Relays between this radio and the destination, excluding both.
  int get relays => math.max(0, towards.length - 1);

  /// The round trip in map order: this radio, every placed node there, every
  /// placed node back, and this radio again. Empty without two places.
  List<({double lat, double lon})> get routePoints {
    final home = senderHasPosition ? (lat: senderLatitude!, lon: senderLongitude!) : null;
    // Without a reported way back, draw it back the way it went.
    final returning = back.isNotEmpty ? back : towards.reversed.skip(1);
    final points = <({double lat, double lon})>[
      ?home,
      for (final h in [...towards, ...returning])
        if (h.hasPosition) (lat: h.latitude!, lon: h.longitude!),
    ];
    if (home != null && points.last != home) points.add(home);
    final distinct = {for (final p in points) '${p.lat},${p.lon}'};
    return distinct.length < 2 ? const [] : points;
  }

  /// Straight-line length of [routePoints] in metres.
  double get routeMeters {
    final p = routePoints;
    var total = 0.0;
    for (var i = 1; i < p.length; i++) {
      total += BastionGeo.distanceMeters(p[i - 1].lat, p[i - 1].lon, p[i].lat, p[i].lon);
    }
    return total;
  }

  /// The weakest SNR along the trace, the link most likely to fail.
  double? get weakestSnr {
    final all = [
      for (final h in [...towards, ...back])
        ?h.snrDb,
    ];
    return all.isEmpty ? null : all.reduce(math.min);
  }

  /// Names of nodes on the route with no known position, each once.
  List<String> get unplaced => {
        for (final h in [...towards, ...back])
          if (!h.hasPosition) h.name,
      }.toList();
}

/// Places [points] in a [width] x [height] box with [padding], keeping the
/// map's proportions (longitude shrinks with latitude). Pure, so the card
/// draws the same route on every phone and in a shared image.
List<({double x, double y})> projectRoute(
  List<({double lat, double lon})> points, {
  required double width,
  required double height,
  double padding = 16,
}) {
  if (points.isEmpty) return const [];
  final midLat = points.map((p) => p.lat).reduce((a, b) => a + b) / points.length;
  final k = math.cos(midLat * math.pi / 180).abs().clamp(0.01, 1.0);
  final xs = [for (final p in points) p.lon * k];
  final ys = [for (final p in points) p.lat];
  final minX = xs.reduce(math.min), maxX = xs.reduce(math.max);
  final minY = ys.reduce(math.min), maxY = ys.reduce(math.max);
  final spanX = math.max(maxX - minX, 1e-9);
  final spanY = math.max(maxY - minY, 1e-9);
  final innerW = width - 2 * padding, innerH = height - 2 * padding;
  final scale = math.min(innerW / spanX, innerH / spanY);
  final offX = padding + (innerW - spanX * scale) / 2;
  final offY = padding + (innerH - spanY * scale) / 2;
  return [
    for (var i = 0; i < points.length; i++) (x: offX + (xs[i] - minX) * scale, y: offY + (maxY - ys[i]) * scale),
  ];
}
