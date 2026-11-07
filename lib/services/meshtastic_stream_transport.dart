import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'meshtastic_radio_transport.dart';

/// The Meshtastic stream framing used over TCP (Wi-Fi/Ethernet) and USB
/// serial: 0x94 0xC3, a two-byte big-endian length, then one protobuf.
///
/// Anything between frames, such as the radio's debug log text on serial,
/// is skipped.
class MeshtasticStreamFramer {
  static const start1 = 0x94;
  static const start2 = 0xC3;

  /// Firmware rejects larger packets; a bigger length means corrupt input.
  static const maxPayload = 512;

  final List<int> _buffer = [];

  /// Wraps [payload] in a frame header.
  static Uint8List frame(List<int> payload) {
    if (payload.length > maxPayload) throw ArgumentError('Packet too large: ${payload.length} bytes.');
    return Uint8List.fromList([start1, start2, payload.length >> 8, payload.length & 0xff, ...payload]);
  }

  /// Adds received [bytes] and returns every complete payload in them.
  List<Uint8List> add(List<int> bytes) {
    _buffer.addAll(bytes);
    final out = <Uint8List>[];
    while (true) {
      final at = _findStart();
      if (at < 0) {
        // Keep a trailing 0x94 in case its partner arrives next.
        final keep = _buffer.isNotEmpty && _buffer.last == start1;
        _buffer.clear();
        if (keep) _buffer.add(start1);
        return out;
      }
      if (at > 0) _buffer.removeRange(0, at);
      if (_buffer.length < 4) return out;
      final length = (_buffer[2] << 8) | _buffer[3];
      if (length > maxPayload) {
        // Not a real header; skip past this start byte and resync.
        _buffer.removeAt(0);
        continue;
      }
      if (_buffer.length < 4 + length) return out;
      out.add(Uint8List.fromList(_buffer.sublist(4, 4 + length)));
      _buffer.removeRange(0, 4 + length);
    }
  }

  int _findStart() {
    for (var i = 0; i + 1 < _buffer.length; i++) {
      if (_buffer[i] == start1 && _buffer[i + 1] == start2) return i;
    }
    return -1;
  }
}

/// Meshtastic PhoneAPI over TCP, for radios on Wi-Fi or Ethernet. The
/// firmware listens on port 4403.
class MeshtasticTcpTransport implements MeshtasticLinkTransport {
  MeshtasticTcpTransport({
    required this.host,
    this.port = defaultPort,
    Future<Socket> Function(String host, int port, {Duration? timeout})? connector,
  }) : _connector = connector ?? Socket.connect;

  static const defaultPort = 4403;

  final String host;
  final int port;
  final Future<Socket> Function(String host, int port, {Duration? timeout}) _connector;

  final StreamController<Uint8List> _incoming = StreamController<Uint8List>.broadcast();
  final StreamController<void> _linkLost = StreamController<void>.broadcast();
  final MeshtasticStreamFramer _framer = MeshtasticStreamFramer();
  Socket? _socket;
  StreamSubscription<Uint8List>? _subscription;
  bool _closing = false;

  @override
  Stream<Uint8List> get fromRadio => _incoming.stream;

  @override
  Stream<void> get linkLost => _linkLost.stream;

  @override
  bool get isConnected => _socket != null;

  @override
  Future<void> connect() async {
    if (_socket != null) return;
    _closing = false;
    final Socket socket;
    try {
      socket = await _connector(host, port, timeout: const Duration(seconds: 10));
    } catch (error) {
      throw StateError('Could not reach $host:$port over the network: $error');
    }
    socket.setOption(SocketOption.tcpNoDelay, true);
    _socket = socket;
    _subscription = socket.listen(
      (bytes) {
        for (final payload in _framer.add(bytes)) {
          _incoming.add(payload);
        }
      },
      onError: (Object _) => _dropped(),
      onDone: _dropped,
      cancelOnError: true,
    );
  }

  void _dropped() {
    final wasOpen = _socket != null;
    _socket = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (wasOpen && !_closing) _linkLost.add(null);
  }

  @override
  Future<void> sendToRadio(Uint8List envelope) async {
    final socket = _socket;
    if (socket == null) throw StateError('Network link to $host is not open.');
    socket.add(MeshtasticStreamFramer.frame(envelope));
    await socket.flush();
  }

  @override
  Future<void> disconnect() async {
    _closing = true;
    final socket = _socket;
    _socket = null;
    await _subscription?.cancel();
    _subscription = null;
    if (socket != null) {
      try {
        await socket.close();
      } catch (_) {
        socket.destroy();
      }
    }
  }
}
