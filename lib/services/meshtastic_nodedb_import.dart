import 'dart:convert';

import '../generated/meshtastic/mesh.pbenum.dart' as pb;

/// One node from a Meshtastic app node database export.
class ImportedNode {
  const ImportedNode({
    required this.num,
    this.id,
    this.longName,
    this.shortName,
    this.hardwareModel,
    this.lastHeard,
    this.favorite = false,
    this.latitude,
    this.longitude,
    this.positionTime,
    this.publicKey,
    this.internetOnly = false,
  });

  final int num;
  final String? id;
  final String? longName;
  final String? shortName;
  final int? hardwareModel;
  final DateTime? lastHeard;
  final bool favorite;
  final double? latitude;
  final double? longitude;
  final DateTime? positionTime;

  /// Base64, as the Meshtastic app writes it.
  final String? publicKey;

  /// Last heard over MQTT (the internet), not by a radio.
  final bool internetOnly;

  bool get hasPosition => latitude != null && longitude != null;
}

/// A `Meshtastic_nodedb_*.json` file saved by the Meshtastic app.
///
/// Only reading is supported. Nothing from it is sent to a radio.
class MeshtasticNodeDbExport {
  const MeshtasticNodeDbExport({
    required this.nodes,
    this.myNodeNum,
    this.exportedAt,
    this.exportedFromName,
  });

  /// Files larger than this are refused before reading.
  static const maxFileBytes = 64 * 1024 * 1024;

  /// At most this many internet (MQTT) nodes are added, newest first. A busy
  /// MQTT export holds tens of thousands, which would slow the app down.
  static const internetLimit = 2000;

  /// The radio the file was saved from.
  final int? myNodeNum;
  final DateTime? exportedAt;

  /// Every node in the file except the radio it was saved from.
  final List<ImportedNode> nodes;

  /// The name of the radio the file was saved from, when the file has it.
  final String? exportedFromName;

  List<ImportedNode> get heardByRadio => [
    for (final n in nodes)
      if (!n.internetOnly) n,
  ];
  List<ImportedNode> get internetOnly => [
    for (final n in nodes)
      if (n.internetOnly) n,
  ];
  int get favoriteCount => nodes.where((n) => n.favorite).length;

  /// The nodes to add: everything heard by radio, every favorite, and with
  /// [includeInternet] the newest [internetLimit] internet-only nodes.
  List<ImportedNode> pick({required bool includeInternet}) {
    final internet = [
      for (final n in nodes)
        if (n.internetOnly && !n.favorite) n,
    ]..sort((a, b) => (b.lastHeard ?? _epoch).compareTo(a.lastHeard ?? _epoch));
    return [
      for (final n in nodes)
        if (!n.internetOnly || n.favorite) n,
      if (includeInternet) ...internet.take(internetLimit),
    ];
  }

  static final _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  /// Reads [text]. Throws [FormatException] when it isn't a node database
  /// export. Single damaged nodes are skipped.
  static MeshtasticNodeDbExport parse(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const FormatException('notJson');
    }
    if (decoded is! Map || decoded['nodes'] is! List) {
      throw const FormatException('notNodeDb');
    }
    final version = decoded['schemaVersion'];
    if (version is int && version > 1) {
      throw const FormatException('newerVersion');
    }
    final me = _int(decoded['myNodeNum']);
    final nodes = <int, ImportedNode>{};
    String? fromName;
    for (final item in decoded['nodes'] as List) {
      if (item is! Map) continue;
      final node = _node(item);
      if (node == null) continue;
      if (node.num == me) {
        fromName = node.longName;
        continue;
      }
      nodes[node.num] = node;
    }
    return MeshtasticNodeDbExport(
      nodes: List.unmodifiable(nodes.values),
      myNodeNum: me,
      exportedAt: decoded['exportedAt'] is String
          ? DateTime.tryParse(decoded['exportedAt'] as String)
          : null,
      exportedFromName: fromName,
    );
  }
}

ImportedNode? _node(Map<Object?, Object?> json) {
  final num = _int(json['num']);
  // 0 and the broadcast address are never real nodes.
  if (num == null || num <= 0 || num >= 0xffffffff) return null;
  final position = json['position'];
  double? lat;
  double? lon;
  DateTime? positionTime;
  if (position is Map) {
    lat = _coordinate(position['latitude'], 90);
    lon = _coordinate(position['longitude'], 180);
    // Meshtastic sends 0,0 when it has no fix.
    if (lat == null || lon == null || (lat == 0 && lon == 0)) {
      lat = null;
      lon = null;
    } else {
      positionTime = _time(position['time']);
    }
  }
  final transport = json['lastTransport'];
  return ImportedNode(
    num: num,
    id: _text(json['id']) ?? '!${num.toRadixString(16).padLeft(8, '0')}',
    longName: _text(json['longName']),
    shortName: _text(json['shortName']),
    hardwareModel: _hardware(json['hwModel']),
    lastHeard: _time(json['lastHeard']),
    favorite: json['isFavorite'] == true,
    latitude: lat,
    longitude: lon,
    positionTime: positionTime,
    publicKey: _publicKey(json['publicKey']),
    internetOnly: transport is String
        ? transport == 'TRANSPORT_MQTT'
        : json['viaMqtt'] == true,
  );
}

int? _int(Object? v) => switch (v) {
  final int i => i,
  final String s => int.tryParse(s),
  _ => null,
};

String? _text(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty ? null : t;
}

double? _coordinate(Object? v, double limit) {
  if (v is! num) return null;
  final d = v.toDouble();
  return d.isFinite && d.abs() <= limit ? d : null;
}

/// Seconds since 1970; 0 means never.
DateTime? _time(Object? v) {
  final s = _int(v);
  if (s == null || s <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true);
}

int? _hardware(Object? v) {
  if (v is int) return v;
  if (v is! String) return null;
  for (final model in pb.HardwareModel.values) {
    if (model.name == v) return model.value;
  }
  return null;
}

/// A 32-byte key in base64, or null.
String? _publicKey(Object? v) {
  if (v is! String) return null;
  try {
    final bytes = base64Decode(v);
    return bytes.length == 32 ? base64Encode(bytes) : null;
  } on FormatException {
    return null;
  }
}
