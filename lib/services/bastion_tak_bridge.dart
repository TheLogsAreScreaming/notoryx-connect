import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'meshtastic_node_database.dart';

/// Builds Cursor on Target (CoT) position events for mesh nodes.
abstract final class BastionCot {
  /// How long ATAK keeps showing a node without an update.
  static const staleAfter = Duration(minutes: 5);

  /// Older positions are left out, so ATAK doesn't show someone where they were hours ago.
  static const maxAge = Duration(hours: 1);
  static const _unknown = '9999999.0';

  static String uid(int node) => 'NOTORYX-${node.toRadixString(16).padLeft(8, '0')}';

  static String _time(DateTime t) => t.toUtc().toIso8601String().replaceFirst(RegExp(r'\.\d+Z$'), 'Z');
  static String _escape(String v) => const HtmlEscape(HtmlEscapeMode.attribute).convert(v);

  /// The event for [node], or null when it has no recent, usable position.
  static String? event(MeshtasticNode node, DateTime now) {
    final lat = node.latitude, lon = node.longitude, at = node.positionTime;
    if (lat == null || lon == null || at == null || !lat.isFinite || !lon.isFinite) return null;
    if (lat.abs() > 90 || lon.abs() > 180 || now.difference(at) > maxAge) return null;
    final hae = node.altitudeMeters?.toString() ?? _unknown;
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<event version="2.0" uid="${uid(node.num)}" type="a-f-G-U-C" how="m-g" '
        'time="${_time(now)}" start="${_time(now)}" stale="${_time(now.add(staleAfter))}">'
        '<point lat="${lat.toStringAsFixed(7)}" lon="${lon.toStringAsFixed(7)}" '
        'hae="$hae" ce="$_unknown" le="$_unknown"/>'
        '<detail><contact callsign="${_escape(node.displayName)}"/>'
        '<__group name="Cyan" role="Team Member"/>'
        '<remarks>Mesh node, position from ${_time(at)}</remarks></detail></event>';
  }
}

/// Which side ATAK says a marker is on, from the second part of its CoT type.
enum TakAffiliation { friendly, hostile, neutral, unknown }

/// A marker ATAK shared with this phone: a team member, a point or a contact.
class TakMarker {
  const TakMarker({
    required this.uid,
    required this.callsign,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.stale,
    required this.received,
  });

  final String uid;
  final String callsign;
  final String type;
  final double latitude;
  final double longitude;
  final DateTime stale;
  final DateTime received;

  /// Map points (b-m-p…) have no side; units (a-f/h/n/u…) do.
  bool get isPoint => type.startsWith('b-m-p');

  TakAffiliation get affiliation {
    final parts = type.split('-');
    if (parts.length < 2 || parts.first != 'a') return TakAffiliation.unknown;
    return switch (parts[1]) {
      'f' || 'a' => TakAffiliation.friendly,
      'h' || 's' || 'j' || 'k' => TakAffiliation.hostile,
      'n' => TakAffiliation.neutral,
      _ => TakAffiliation.unknown,
    };
  }
}

/// Reads CoT events that ATAK sends. Only the few fields the map needs are
/// read, and anything odd is ignored rather than guessed at.
abstract final class BastionCotReader {
  /// Larger datagrams are dropped unread.
  static const maxBytes = 64 * 1024;

  /// Markers that say they stay fresh longer than this are cut to it.
  static const maxStale = Duration(days: 1);

  static final _event = RegExp(r'<event\b([^>]*)>', dotAll: true);
  static final _point = RegExp(r'<point\b([^>]*)/?>', dotAll: true);
  static final _contact = RegExp(r'<contact\b([^>]*)/?>', dotAll: true);
  static final _attr = RegExp(r'''([A-Za-z_][\w.-]*)\s*=\s*("([^"]*)"|'([^']*)')''');

  static Map<String, String> _attrs(String s) => {
    for (final m in _attr.allMatches(s)) m.group(1)!: _unescape(m.group(3) ?? m.group(4) ?? ''),
  };

  static String _unescape(String v) => v
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&amp;', '&');

  /// The marker in [xml], or null for our own echoes, pings, stale or broken events.
  static TakMarker? read(String xml, DateTime now) {
    if (xml.length > maxBytes) return null;
    final event = _event.firstMatch(xml);
    final point = _point.firstMatch(xml);
    if (event == null || point == null) return null;
    final e = _attrs(event.group(1)!);
    final p = _attrs(point.group(1)!);
    final uid = e['uid']?.trim() ?? '';
    final type = e['type']?.trim() ?? '';
    if (uid.isEmpty || uid.length > 200 || uid.startsWith('NOTORYX-')) return null;
    if (!(type.startsWith('a-') || type.startsWith('b-m-p'))) return null;
    final lat = double.tryParse(p['lat'] ?? '');
    final lon = double.tryParse(p['lon'] ?? '');
    if (lat == null || lon == null || !lat.isFinite || !lon.isFinite) return null;
    if (lat.abs() > 90 || lon.abs() > 180 || (lat == 0 && lon == 0)) return null;
    var stale = DateTime.tryParse(e['stale'] ?? '') ?? now.add(BastionCot.staleAfter);
    if (!stale.isAfter(now)) return null;
    if (stale.difference(now) > maxStale) stale = now.add(maxStale);
    final contact = _contact.firstMatch(xml);
    var callsign = contact == null ? '' : (_attrs(contact.group(1)!)['callsign'] ?? '').trim();
    if (callsign.isEmpty) callsign = uid;
    if (callsign.length > 60) callsign = callsign.substring(0, 60);
    return TakMarker(
      uid: uid,
      callsign: callsign,
      type: type,
      latitude: lat,
      longitude: lon,
      stale: stale.toLocal(),
      received: now,
    );
  }
}

/// Listens for datagrams from ATAK. Separate so tests avoid the network.
abstract interface class BastionTakReceiver {
  Future<Stream<String>> listen(int port);
  void close();
}

/// Listens on this phone only, so only apps on the phone can send markers.
class BastionLoopbackTakReceiver implements BastionTakReceiver {
  RawDatagramSocket? _socket;

  @override
  Future<Stream<String>> listen(int port) async {
    close();
    final socket = _socket = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, port);
    return socket.where((e) => e == RawSocketEvent.read).expand((_) sync* {
      final d = socket.receive();
      if (d != null && d.data.length <= BastionCotReader.maxBytes) {
        yield utf8.decode(d.data, allowMalformed: true);
      }
    });
  }

  @override
  void close() {
    _socket?.close();
    _socket = null;
  }
}

/// Sends one datagram. Separate so tests avoid the network.
abstract interface class BastionTakSender {
  Future<void> send(String xml);
  void close();
}

/// Sends to this phone only; positions never leave it over the network here.
class BastionLoopbackTakSender implements BastionTakSender {
  BastionLoopbackTakSender(this.port);
  final int port;
  RawDatagramSocket? _socket;

  @override
  Future<void> send(String xml) async {
    final socket = _socket ??= await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    socket.send(utf8.encode(xml), InternetAddress.loopbackIPv4, port);
  }

  @override
  void close() {
    _socket?.close();
    _socket = null;
  }
}

/// Opt-in feed of mesh node positions to ATAK on the same phone.
class BastionTakBridge extends ChangeNotifier {
  BastionTakBridge({
    BastionTakSender Function(int port)? sender,
    BastionTakReceiver Function()? receiver,
    DateTime Function()? now,
  }) : _makeSender = sender ?? BastionLoopbackTakSender.new,
       _makeReceiver = receiver ?? BastionLoopbackTakReceiver.new,
       _now = now ?? DateTime.now;

  static final instance = BastionTakBridge();
  static const defaultPort = 4242;

  /// Where ATAK's output is sent; separate from the port ATAK itself listens on.
  static const defaultReceivePort = 4243;

  /// More markers than this and the oldest are dropped.
  static const maxMarkers = 200;
  static const interval = Duration(seconds: 30);
  static const _settingsName = 'bastion.tak_bridge.v1';

  final BastionTakSender Function(int port) _makeSender;
  final BastionTakReceiver Function() _makeReceiver;
  final DateTime Function() _now;
  bool _receive = false;
  int _receivePort = defaultReceivePort;
  String? _receiveProblem;
  BastionTakReceiver? _receiver;
  StreamSubscription<String>? _incoming;
  final Map<String, TakMarker> _markers = {};
  bool _enabled = false;
  int _port = defaultPort;
  int _lastCount = 0;
  String? _problem;
  Iterable<MeshtasticNode> Function()? _nodes;
  BastionTakSender? _sender;
  Timer? _timer;

  bool get enabled => _enabled;
  int get port => _port;
  int get lastCount => _lastCount;
  String? get problem => _problem;

  /// Whether markers from ATAK are shown on the map.
  bool get receive => _receive;
  int get receivePort => _receivePort;
  String? get receiveProblem => _receiveProblem;

  /// Markers from ATAK that haven't gone stale, newest first.
  List<TakMarker> get markers {
    final now = _now();
    _markers.removeWhere((_, m) => !m.stale.isAfter(now));
    return _markers.values.toList()..sort((a, b) => b.received.compareTo(a.received));
  }

  /// Handles one datagram from ATAK. Public for tests.
  void handle(String xml) {
    final marker = BastionCotReader.read(xml, _now());
    if (marker == null) return;
    _markers.remove(marker.uid);
    _markers[marker.uid] = marker;
    while (_markers.length > maxMarkers) {
      _markers.remove(_markers.keys.first);
    }
    notifyListeners();
  }

  /// Forgets every marker from ATAK.
  void clearMarkers() {
    if (_markers.isEmpty) return;
    _markers.clear();
    notifyListeners();
  }

  Future<void> _startReceiving() async {
    _stopReceiving();
    if (!_receive) return;
    final receiver = _receiver = _makeReceiver();
    try {
      final stream = await receiver.listen(_receivePort);
      if (!identical(receiver, _receiver)) return;
      _incoming = stream.listen(
        handle,
        onError: (Object error) {
          _receiveProblem = '$error';
          notifyListeners();
        },
      );
      _receiveProblem = null;
    } catch (error) {
      _receiveProblem = '$error';
    }
    notifyListeners();
  }

  void _stopReceiving() {
    unawaited(_incoming?.cancel());
    _incoming = null;
    _receiver?.close();
    _receiver = null;
  }

  Future<void> load() async {
    try {
      final raw = await SharedPreferencesAsync().getString(_settingsName);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _enabled = json['enabled'] == true;
      final port = json['port'];
      _port = port is int && validPort(port) ? port : defaultPort;
      _receive = json['receive'] == true;
      final receivePort = json['receivePort'];
      _receivePort = receivePort is int && validPort(receivePort) ? receivePort : defaultReceivePort;
    } catch (_) {
      _enabled = false;
      _receive = false;
    }
    _restart();
    await _startReceiving();
    notifyListeners();
  }

  static bool validPort(int port) => port >= 1024 && port <= 65535;

  /// Gives the bridge its node list. It only sends while enabled.
  void attach(Iterable<MeshtasticNode> Function() nodes) {
    _nodes = nodes;
    _restart();
  }

  void detach() {
    _nodes = null;
    _stop();
  }

  Future<void> configure({bool? enabled, int? port, bool? receive, int? receivePort}) async {
    if (port != null && !validPort(port)) return;
    if (receivePort != null && !validPort(receivePort)) return;
    final receiveChanged =
        (receive != null && receive != _receive) || (receivePort != null && receivePort != _receivePort);
    _enabled = enabled ?? _enabled;
    _port = port ?? _port;
    _receive = receive ?? _receive;
    _receivePort = receivePort ?? _receivePort;
    if (enabled != null || port != null) _restart();
    if (receiveChanged) {
      if (!_receive) {
        _markers.clear();
        _receiveProblem = null;
      }
      await _startReceiving();
    }
    notifyListeners();
    await SharedPreferencesAsync().setString(
      _settingsName,
      jsonEncode({'enabled': _enabled, 'port': _port, 'receive': _receive, 'receivePort': _receivePort}),
    );
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _sender?.close();
    _sender = null;
    _lastCount = 0;
  }

  void _restart() {
    _stop();
    if (!_enabled || _nodes == null) return;
    _sender = _makeSender(_port);
    _timer = Timer.periodic(interval, (_) => unawaited(publish()));
    unawaited(publish());
  }

  /// Sends every node with a recent position once.
  Future<void> publish() async {
    final sender = _sender, nodes = _nodes;
    if (sender == null || nodes == null) return;
    final now = _now();
    var count = 0;
    String? problem;
    for (final node in nodes()) {
      final xml = BastionCot.event(node, now);
      if (xml == null) continue;
      try {
        await sender.send(xml);
        count++;
      } catch (error) {
        problem = '$error';
        break;
      }
    }
    if (count != _lastCount || problem != _problem) {
      _lastCount = count;
      _problem = problem;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stop();
    _stopReceiving();
    super.dispose();
  }
}
