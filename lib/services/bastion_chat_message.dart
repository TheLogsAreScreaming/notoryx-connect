import 'meshtastic_text_codec.dart';

enum BastionMessageDirection { incoming, outgoing }
/// Where a message is. [held] means queued but not sent by itself: it is too
/// old to send unasked, or its send was cut off and it may already be out.
enum BastionDeliveryState { received, queued, sent, delivered, failed, held }

class BastionChatMessage {
  const BastionChatMessage({
    required this.packetId,
    required this.from,
    required this.to,
    required this.channel,
    required this.text,
    required this.timestamp,
    required this.direction,
    required this.deliveryState,
    this.rxSnr,
    this.replyId,
    this.isReaction = false,
    this.viaMqtt = false,
    this.hops,
    this.rxRssi,
    this.relayNode,
    this.replayed = false,
    this.receivedAt,
  });

  final int packetId;
  final int from;
  final int to;
  final int channel;
  final String text;
  final DateTime timestamp;
  final BastionMessageDirection direction;
  final BastionDeliveryState deliveryState;
  final double? rxSnr;

  /// The message this one reacts to, when [isReaction].
  final int? replyId;

  /// An emoji reaction to [replyId] rather than a message of its own.
  final bool isReaction;

  /// Reached the radio over MQTT (the internet), not over LoRa.
  final bool viaMqtt;

  /// Relays an incoming message passed through; 0 means heard directly.
  final int? hops;

  /// Received signal strength in dBm.
  final int? rxRssi;

  /// Last byte of the node number of the final relay.
  final int? relayNode;

  /// Came from a store-and-forward router's history, not live.
  final bool replayed;

  /// When this phone got it, when that differs from [timestamp] (the time
  /// the packet says it was first heard). Set for replays.
  final DateTime? receivedAt;

  bool get isBroadcast => to == MeshtasticTextCodec.broadcastNode;

  BastionChatMessage copyWith({BastionDeliveryState? deliveryState}) =>
      BastionChatMessage(
        packetId: packetId,
        from: from,
        to: to,
        channel: channel,
        text: text,
        timestamp: timestamp,
        direction: direction,
        deliveryState: deliveryState ?? this.deliveryState,
        rxSnr: rxSnr,
        replyId: replyId,
        isReaction: isReaction,
        viaMqtt: viaMqtt,
        hops: hops,
        rxRssi: rxRssi,
        relayNode: relayNode,
        replayed: replayed,
        receivedAt: receivedAt,
      );

  Map<String, Object?> toJson() => {
    'packetId': packetId,
    'from': from,
    'to': to,
    'channel': channel,
    'text': text,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'direction': direction.name,
    'deliveryState': deliveryState.name,
    if (rxSnr != null) 'rxSnr': rxSnr,
    if (replyId != null) 'replyId': replyId,
    if (isReaction) 'reaction': true,
    if (viaMqtt) 'viaMqtt': true,
    if (hops != null) 'hops': hops,
    if (rxRssi != null) 'rxRssi': rxRssi,
    if (relayNode != null) 'relay': relayNode,
    if (replayed) 'replayed': true,
    if (receivedAt != null) 'receivedAt': receivedAt!.toUtc().toIso8601String(),
  };

  static BastionChatMessage fromJson(Map<String, Object?> json) {
    return BastionChatMessage(
      packetId: json['packetId']! as int,
      from: json['from']! as int,
      to: json['to']! as int,
      channel: json['channel']! as int,
      text: json['text']! as String,
      timestamp: DateTime.parse(json['timestamp']! as String).toLocal(),
      direction: BastionMessageDirection.values.byName(
        json['direction']! as String,
      ),
      deliveryState: BastionDeliveryState.values.byName(
        json['deliveryState']! as String,
      ),
      rxSnr: (json['rxSnr'] as num?)?.toDouble(),
      replyId: json['replyId'] as int?,
      isReaction: json['reaction'] as bool? ?? false,
      viaMqtt: json['viaMqtt'] as bool? ?? false,
      hops: json['hops'] as int?,
      rxRssi: json['rxRssi'] as int?,
      relayNode: json['relay'] as int?,
      replayed: json['replayed'] as bool? ?? false,
      receivedAt: json['receivedAt'] is String
          ? DateTime.tryParse(json['receivedAt']! as String)?.toLocal()
          : null,
    );
  }
}

class PendingTextMessage {
  const PendingTextMessage({
    required this.text,
    required this.destination,
    required this.channel,
    required this.packetId,
    this.replyId,
    this.isReaction = false,
    this.queuedAt,
    this.handoff = false,
    this.held = false,
  });

  final String text;
  final int destination;
  final int channel;
  final int packetId;
  final int? replyId;
  final bool isReaction;

  /// When it was queued; null for messages saved by older builds, whose age
  /// is unknown, so they are held for review rather than sent.
  final DateTime? queuedAt;

  /// Saved true just before it is handed to the radio and cleared once the
  /// radio has taken it. Still true after a restart means nobody knows
  /// whether it went out.
  final bool handoff;

  /// Waiting for the user to send or delete it; never sent by itself.
  final bool held;

  PendingTextMessage copyWith({bool? handoff, bool? held, DateTime? queuedAt}) =>
      PendingTextMessage(
        text: text,
        destination: destination,
        channel: channel,
        packetId: packetId,
        replyId: replyId,
        isReaction: isReaction,
        queuedAt: queuedAt ?? this.queuedAt,
        handoff: handoff ?? this.handoff,
        held: held ?? this.held,
      );

  Map<String, Object?> toJson() => {
    'text': text,
    'destination': destination,
    'channel': channel,
    'packetId': packetId,
    if (replyId != null) 'replyId': replyId,
    if (isReaction) 'reaction': true,
    if (queuedAt != null) 'queuedAt': queuedAt!.millisecondsSinceEpoch,
    if (handoff) 'handoff': true,
    if (held) 'held': true,
  };

  static PendingTextMessage fromJson(Map<String, Object?> json) =>
      PendingTextMessage(
        text: json['text']! as String,
        destination: json['destination']! as int,
        channel: json['channel']! as int,
        packetId: json['packetId']! as int,
        replyId: json['replyId'] as int?,
        isReaction: json['reaction'] as bool? ?? false,
        queuedAt: json['queuedAt'] is int
            ? DateTime.fromMillisecondsSinceEpoch(json['queuedAt']! as int)
            : null,
        handoff: json['handoff'] as bool? ?? false,
        held: json['held'] as bool? ?? false,
      );
}
