/// What a Meshtastic connect link asks for.
enum ConnectLinkKind { bluetooth, network, serial, disconnect }

/// A Meshtastic connect link, the shared format the official apps use in
/// QR codes and NFC tags:
///
/// `meshtastic://meshtastic/connections?address=<prefixed address>&pin=<pin>`
/// (also `https://meshtastic.org/connections?...`).
///
/// The address carries a one-letter transport prefix: `x` Bluetooth
/// (`xAA:BB:CC:DD:EE:FF`), `t` TCP (`t192.168.1.20` or `t192.168.1.20:4403`),
/// `s` serial (`s/dev/ttyUSB0`), and `n` alone means disconnect. A [pin] is
/// kept only for Bluetooth, and only when it is exactly six digits that don't
/// start with 0 (firmware can't use one that does).
class ConnectLink {
  const ConnectLink._(this.kind, {this.address = '', this.port, this.pin});

  final ConnectLinkKind kind;

  /// Bluetooth MAC (upper case), network host, or serial path.
  final String address;

  /// TCP port, for [ConnectLinkKind.network].
  final int? port;

  /// The radio's fixed Bluetooth pairing PIN, when the link carries one.
  final String? pin;

  static const defaultTcpPort = 4403;

  static final _mac = RegExp(r'^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}$');
  static final _pin = RegExp(r'^[1-9][0-9]{5}$');

  /// Reads [text] as a connect link, or null when it isn't one (or names an
  /// address this app can't use).
  static ConnectLink? parse(String text) {
    final Uri uri;
    try {
      uri = Uri.parse(text.trim());
    } on FormatException {
      return null;
    }
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();
    final ok =
        (scheme == 'meshtastic' && host == 'meshtastic') ||
        ((scheme == 'https' || scheme == 'http') &&
            (host == 'meshtastic.org' || host == 'www.meshtastic.org'));
    if (!ok) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 1 || segments.single != 'connections') return null;
    final String? address;
    try {
      address = uri.queryParameters['address'];
    } on FormatException {
      return null;
    }
    if (address == null || address.length < 2 && address != 'n') return null;
    final rest = address.substring(1);
    switch (address[0]) {
      case 'n':
        return rest.isEmpty
            ? const ConnectLink._(ConnectLinkKind.disconnect)
            : null;
      case 'x':
        if (!_mac.hasMatch(rest)) return null;
        final pin = uri.queryParameters['pin'];
        return ConnectLink._(
          ConnectLinkKind.bluetooth,
          address: rest.toUpperCase(),
          pin: pin != null && _pin.hasMatch(pin) ? pin : null,
        );
      case 't':
        return _network(rest);
      case 's':
        return ConnectLink._(ConnectLinkKind.serial, address: rest);
      default:
        return null;
    }
  }

  static ConnectLink? _network(String hostPort) {
    var host = hostPort;
    int? port;
    final bracketed = RegExp(r'^\[([^\]]+)\](?::(\d+))?$').firstMatch(hostPort);
    if (bracketed != null) {
      host = bracketed.group(1)!;
      port = bracketed.group(2) == null ? null : int.parse(bracketed.group(2)!);
    } else if (':'.allMatches(hostPort).length == 1) {
      final i = hostPort.indexOf(':');
      host = hostPort.substring(0, i);
      port = int.tryParse(hostPort.substring(i + 1));
      if (port == null) return null;
    }
    if (host.isEmpty || host.contains(RegExp(r'[\s/?#]'))) return null;
    port ??= defaultTcpPort;
    if (port < 1 || port > 65535) return null;
    return ConnectLink._(ConnectLinkKind.network, address: host, port: port);
  }

  /// The link for a radio, in the official format.
  static String forBluetooth(String mac, {String? pin}) => Uri(
    scheme: 'meshtastic',
    host: 'meshtastic',
    path: '/connections',
    queryParameters: {
      'address': 'x${mac.toUpperCase()}',
      if (pin != null) 'pin': pin,
    },
  ).toString();
}
