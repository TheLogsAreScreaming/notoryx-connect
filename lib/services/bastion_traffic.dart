import 'dart:async';
import 'dart:collection';

import 'package:protobuf/protobuf.dart';

import '../generated/meshtastic/mesh.pb.dart' as pb;
import '../generated/meshtastic/portnums.pbenum.dart';
import 'meshtastic_node_database.dart';

/// The six colours of the live Traffic map. Meshtastic packet types are
/// grouped onto them so every app in the family shares one legend.
enum TrafficKind {
  /// Position and node info: a node telling the mesh it exists.
  advert,

  /// A text message sent to us alone.
  direct,

  /// A text message sent to everyone on a channel.
  channel,

  /// A routing packet: delivery acknowledgements and errors.
  ack,

  /// A traceroute request or reply, which carries its full route.
  trace,

  /// Everything else (telemetry, waypoints, admin and so on).
  other,
}

/// One step of a packet's route, from where it started to this radio.
sealed class TrafficStop {
  const TrafficStop();
}

/// A node whose full number is known.
final class TrafficNodeStop extends TrafficStop {
  const TrafficNodeStop(this.num);
  final int num;

  @override
  bool operator ==(Object other) => other is TrafficNodeStop && other.num == num;

  @override
  int get hashCode => num.hashCode;

  @override
  String toString() => 'node(${num.toRadixString(16)})';
}

/// The relay that handed the packet to us, known only by the last byte of
/// its node number (the firmware's relay_node field).
final class TrafficRelayStop extends TrafficStop {
  const TrafficRelayStop(this.lastByte);
  final int lastByte;

  @override
  bool operator ==(Object other) => other is TrafficRelayStop && other.lastByte == lastByte;

  @override
  int get hashCode => lastByte.hashCode;

  @override
  String toString() => 'relay(${lastByte.toRadixString(16)})';
}

/// Relays we know were there but not who they were.
final class TrafficUnknownStop extends TrafficStop {
  const TrafficUnknownStop(this.count);
  final int count;

  @override
  bool operator ==(Object other) => other is TrafficUnknownStop && other.count == count;

  @override
  int get hashCode => count.hashCode;

  @override
  String toString() => 'unknown($count)';
}

/// A packet this radio heard, reduced to what the Traffic map draws.
class TrafficPacket {
  const TrafficPacket({
    required this.id,
    required this.from,
    required this.to,
    required this.kind,
    required this.path,
    required this.heard,
    this.hopsAway,
    this.snr,
    this.rssi,
    this.viaMqtt = false,
    this.fullPath = false,
  });

  /// Meshtastic's broadcast address.
  static const broadcast = 0xffffffff;

  /// RouteDiscovery marks a relay it could not identify with this number.
  static const unknownRelay = 0xffffffff;

  final int id;
  final int from;
  final int to;
  final TrafficKind kind;

  /// From the origin to this radio, both included.
  final List<TrafficStop> path;
  final DateTime heard;

  /// hop_start − hop_limit; null when the sender's firmware does not say.
  final int? hopsAway;
  final double? snr;
  final int? rssi;
  final bool viaMqtt;

  /// True when every relay is named (traceroutes); otherwise the middle of
  /// the route is inferred from the hop count and relay byte.
  final bool fullPath;

  /// The packet type's colour group.
  static TrafficKind kindOf(PortNum port, {required int to}) => switch (port) {
        PortNum.POSITION_APP || PortNum.NODEINFO_APP => TrafficKind.advert,
        PortNum.TEXT_MESSAGE_APP ||
        PortNum.TEXT_MESSAGE_COMPRESSED_APP ||
        PortNum.ALERT_APP =>
          to == broadcast ? TrafficKind.channel : TrafficKind.direct,
        PortNum.ROUTING_APP => TrafficKind.ack,
        PortNum.TRACEROUTE_APP => TrafficKind.trace,
        _ => TrafficKind.other,
      };

  /// Origin → [unknown relays] → [relay byte] → us, from the hop count and
  /// relay byte that every Meshtastic packet carries.
  static List<TrafficStop> inferredPath({
    required int from,
    required int local,
    int? hopsAway,
    int? relayByte,
  }) {
    final hops = hopsAway ?? 0;
    // A relay byte equal to the sender's own means it reached us directly.
    final relay = relayByte != null && hops > 0 && relayByte != (from & 0xff) ? relayByte : null;
    return [
      TrafficNodeStop(from),
      if (hops > 0 && relay != null) ...[
        if (hops > 1) TrafficUnknownStop(hops - 1),
        TrafficRelayStop(relay),
      ] else if (hops > 0)
        TrafficUnknownStop(hops),
      TrafficNodeStop(local),
    ];
  }

  /// Origin → every relay → us for a traceroute addressed to this radio.
  ///
  /// A reply lists the relays it came back through in route_back; older
  /// firmware only fills route (the way out), which is reversed instead.
  /// A request someone else sent us lists its relays so far in route.
  static List<TrafficStop> tracePath({
    required int from,
    required int local,
    required pb.RouteDiscovery route,
    required bool isReply,
  }) {
    final relays = !isReply
        ? route.route
        : route.routeBack.isNotEmpty
            ? route.routeBack
            : route.route.reversed.toList();
    final stops = <TrafficStop>[TrafficNodeStop(from)];
    for (final relay in relays) {
      if (relay == unknownRelay || relay == 0) {
        final last = stops.last;
        if (last is TrafficUnknownStop) {
          stops[stops.length - 1] = TrafficUnknownStop(last.count + 1);
        } else {
          stops.add(const TrafficUnknownStop(1));
        }
      } else if (relay != from && relay != local) {
        stops.add(TrafficNodeStop(relay));
      }
    }
    stops.add(TrafficNodeStop(local));
    return stops;
  }

  /// Reads one packet from the radio. Returns null for our own packets and
  /// for packets the radio could not decrypt for us.
  static TrafficPacket? fromMeshPacket(pb.MeshPacket packet, {required int local, required DateTime heard}) {
    if (packet.from == 0 || packet.from == local || !packet.hasDecoded()) return null;
    final data = packet.decoded;
    final hopsAway = packet.hopStart > 0 && packet.hopStart >= packet.hopLimit ? packet.hopStart - packet.hopLimit : null;
    final kind = kindOf(data.portnum, to: packet.to);
    var path = inferredPath(
      from: packet.from,
      local: local,
      hopsAway: hopsAway,
      relayByte: packet.relayNode == 0 ? null : packet.relayNode & 0xff,
    );
    var full = false;
    if (kind == TrafficKind.trace && packet.to == local) {
      try {
        path = tracePath(
          from: packet.from,
          local: local,
          route: pb.RouteDiscovery.fromBuffer(data.payload),
          isReply: data.requestId != 0,
        );
        full = true;
      } on InvalidProtocolBufferException {
        // Keep the inferred path.
      }
    }
    return TrafficPacket(
      id: packet.id,
      from: packet.from,
      to: packet.to,
      kind: kind,
      path: path,
      heard: heard,
      hopsAway: hopsAway,
      snr: packet.rxSnr == 0 || !packet.rxSnr.isFinite ? null : packet.rxSnr,
      rssi: packet.rxRssi == 0 ? null : packet.rxRssi,
      viaMqtt: packet.viaMqtt,
      fullPath: full,
    );
  }
}

/// One stop of a [TrafficRoute] with what the map needs to draw it.
class TrafficRouteStop {
  const TrafficRouteStop({required this.label, this.num, this.latitude, this.longitude, this.unknownCount = 0});

  /// Name, short name, or short hex ID; "+n" for unnamed relays.
  final String label;

  /// Null for relays known only by count or by an unmatched relay byte.
  final int? num;
  final double? latitude;
  final double? longitude;

  /// How many unnamed relays this stop stands for.
  final int unknownCount;

  bool get placed => latitude != null && longitude != null;
}

/// A packet's route resolved against the node list.
class TrafficRoute {
  const TrafficRoute({required this.packet, required this.stops});

  final TrafficPacket packet;
  final List<TrafficRouteStop> stops;

  /// Stops that have a position, in route order; the map draws only these.
  List<TrafficRouteStop> get placed => [for (final s in stops) if (s.placed) s];

  /// Named stops with no position (the card's "not on map" line).
  List<TrafficRouteStop> get notOnMap => [for (final s in stops) if (!s.placed && s.unknownCount == 0) s];

  /// Relays the packet passed through that nobody can name.
  int get unknownRelays => stops.fold(0, (sum, s) => sum + s.unknownCount);

  /// How many legs the map animates.
  int get legs => placed.length < 2 ? 0 : placed.length - 1;

  /// The stop that handed the packet to us.
  TrafficRouteStop? get lastHop => stops.length < 2 ? null : stops[stops.length - 2];

  /// "Origin → hop → … → us".
  String get summary => [for (final s in stops) s.label].join(' → ');

  /// A short ID like Meshtastic's default short name: the last four hex digits.
  static String shortId(int num) => (num & 0xffff).toRadixString(16).padLeft(4, '0').toUpperCase();

  static String _label(MeshtasticNode? node, int num) {
    final short = node?.shortName?.trim();
    final long = node?.longName?.trim();
    if (long != null && long.isNotEmpty) return long;
    if (short != null && short.isNotEmpty) return short;
    return shortId(num);
  }

  /// Resolves names and positions. A relay byte becomes a node only when
  /// exactly one known node (other than the sender and us) ends in it.
  static TrafficRoute build(TrafficPacket packet, Map<int, MeshtasticNode> nodes) {
    TrafficRouteStop node(int num) {
      final n = nodes[num];
      return TrafficRouteStop(
        num: num,
        label: _label(n, num),
        latitude: n?.hasPosition ?? false ? n!.latitude : null,
        longitude: n?.hasPosition ?? false ? n!.longitude : null,
      );
    }

    final ends = {packet.from, if (packet.path.last case TrafficNodeStop(:final num)) num};
    return TrafficRoute(packet: packet, stops: [
      for (final stop in packet.path)
        switch (stop) {
          TrafficNodeStop(:final num) => node(num),
          TrafficRelayStop(:final lastByte) => switch ([
              for (final n in nodes.keys)
                if ((n & 0xff) == lastByte && !ends.contains(n)) n
            ]) {
              [final only] => node(only),
              _ => TrafficRouteStop(label: '··${lastByte.toRadixString(16).padLeft(2, '0').toUpperCase()}'),
            },
          TrafficUnknownStop(:final count) => TrafficRouteStop(label: '+$count', unknownCount: count),
        },
    ]);
  }
}

/// Where a route's animation is at a moment in time.
class TrafficFrame {
  const TrafficFrame({required this.leg, required this.t, required this.opacity, required this.done});

  /// The leg the dot is on; equal to the leg count once it has arrived.
  final int leg;

  /// 0..1 along [leg].
  final double t;

  /// 1 while travelling, falling to 0 as the route fades.
  final double opacity;
  final bool done;

  bool get arrived => t >= 1 || opacity < 1;
}

/// Timing for the travelling dot and the fade that follows.
abstract final class TrafficTiming {
  static const leg = Duration(milliseconds: 700);
  static const fade = Duration(milliseconds: 2400);

  /// Reduce motion: the whole route shows at once and fades over this long.
  static const still = Duration(milliseconds: 3200);

  static Duration total(int legs, {bool reduceMotion = false}) =>
      reduceMotion ? still : leg * (legs < 1 ? 1 : legs) + fade;

  static TrafficFrame frame(Duration elapsed, int legs, {bool reduceMotion = false}) {
    final n = legs < 1 ? 1 : legs;
    if (reduceMotion) {
      final f = elapsed.inMicroseconds / still.inMicroseconds;
      return TrafficFrame(leg: n, t: 1, opacity: (1 - f).clamp(0, 1).toDouble(), done: f >= 1);
    }
    final travel = leg * n;
    if (elapsed < travel) {
      final legIndex = elapsed.inMicroseconds ~/ leg.inMicroseconds;
      final t = (elapsed.inMicroseconds % leg.inMicroseconds) / leg.inMicroseconds;
      return TrafficFrame(leg: legIndex, t: t, opacity: 1, done: false);
    }
    final f = (elapsed - travel).inMicroseconds / fade.inMicroseconds;
    return TrafficFrame(leg: n, t: 1, opacity: (1 - f).clamp(0, 1).toDouble(), done: f >= 1);
  }
}

/// A route on screen and when its animation started.
class ActiveTrafficRoute {
  ActiveTrafficRoute(this.route, this.started);
  final TrafficRoute route;
  final DateTime started;
}

/// Keeps at most [maxActive] routes animating and queues the rest.
class TrafficQueue {
  TrafficQueue({this.maxActive = 3, this.maxWaiting = 12});

  final int maxActive;

  /// Oldest waiting routes are dropped beyond this so the map stays live.
  final int maxWaiting;

  final List<ActiveTrafficRoute> active = [];
  final Queue<TrafficRoute> waiting = Queue();

  void add(TrafficRoute route, DateTime now) {
    if (active.length < maxActive) {
      active.add(ActiveTrafficRoute(route, now));
      return;
    }
    waiting.add(route);
    while (waiting.length > maxWaiting) {
      waiting.removeFirst();
    }
  }

  /// Drops finished routes and starts waiting ones. Returns true while
  /// anything is still on screen or waiting.
  bool tick(DateTime now, {bool reduceMotion = false}) {
    active.removeWhere((a) =>
        now.difference(a.started) >= TrafficTiming.total(a.route.legs, reduceMotion: reduceMotion));
    while (active.length < maxActive && waiting.isNotEmpty) {
      active.add(ActiveTrafficRoute(waiting.removeFirst(), now));
    }
    return active.isNotEmpty || waiting.isNotEmpty;
  }

  void clear() {
    active.clear();
    waiting.clear();
  }
}

/// Packets heard on this radio, for the live Traffic map.
class BastionTrafficLog {
  BastionTrafficLog() {
    _packets = StreamController.broadcast(
      onListen: () => onWatching?.call(true),
      onCancel: () => onWatching?.call(false),
    );
  }

  static const keep = 50;

  late final StreamController<TrafficPacket> _packets;

  /// Told when the map starts and stops watching; the demo radio uses it to
  /// make pretend traffic only while someone is looking.
  void Function(bool watching)? onWatching;
  final List<TrafficPacket> _recent = [];

  /// New packets as they are heard.
  Stream<TrafficPacket> get packets => _packets.stream;

  /// The last [keep] packets, newest last.
  List<TrafficPacket> get recent => List.unmodifiable(_recent);

  void add(TrafficPacket packet) {
    // The same packet heard again through another relay is drawn again on
    // purpose: it took another route.
    _recent.add(packet);
    if (_recent.length > keep) _recent.removeAt(0);
    if (!_packets.isClosed) _packets.add(packet);
  }

  void clear() => _recent.clear();

  Future<void> close() => _packets.close();
}
