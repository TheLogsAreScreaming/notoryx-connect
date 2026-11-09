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
  BastionTakBridge({BastionTakSender Function(int port)? sender, DateTime Function()? now})
      : _makeSender = sender ?? BastionLoopbackTakSender.new,
        _now = now ?? DateTime.now;

  static final instance = BastionTakBridge();
  static const defaultPort = 4242;
  static const interval = Duration(seconds: 30);
  static const _settingsName = 'bastion.tak_bridge.v1';

  final BastionTakSender Function(int port) _makeSender;
  final DateTime Function() _now;
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

  Future<void> load() async {
    try {
      final raw = await SharedPreferencesAsync().getString(_settingsName);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _enabled = json['enabled'] == true;
      final port = json['port'];
      _port = port is int && validPort(port) ? port : defaultPort;
    } catch (_) {
      _enabled = false;
    }
    _restart();
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

  Future<void> configure({bool? enabled, int? port}) async {
    if (port != null && !validPort(port)) return;
    _enabled = enabled ?? _enabled;
    _port = port ?? _port;
    _restart();
    notifyListeners();
    await SharedPreferencesAsync().setString(_settingsName, jsonEncode({'enabled': _enabled, 'port': _port}));
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
    super.dispose();
  }
}
