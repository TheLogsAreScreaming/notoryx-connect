import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';

import 'meshtastic_radio_transport.dart';
import 'meshtastic_stream_transport.dart';

/// A USB device that may be a radio, as listed by the phone.
class UsbRadioInfo {
  const UsbRadioInfo({required this.deviceId, required this.name, this.vendorId, this.productId});
  final int deviceId;
  final String name;
  final int? vendorId;
  final int? productId;

  /// USB-serial chips and boards that Meshtastic radios commonly use.
  static const _knownVendors = {
    0x10C4: 'Silicon Labs CP210x',
    0x1A86: 'WCH CH34x',
    0x303A: 'Espressif',
    0x239A: 'Adafruit / nRF52',
    0x2886: 'Seeed',
    0x0403: 'FTDI',
    0x1915: 'Nordic',
  };

  /// Whether this looks like a radio rather than some other USB gadget.
  bool get likelyRadio => _knownVendors.containsKey(vendorId);

  String? get chip => _knownVendors[vendorId];
}

/// An open serial port.
abstract interface class UsbSerialPortHandle {
  Stream<Uint8List> get input;
  Future<void> write(Uint8List data);
  Future<void> close();
}

/// The phone's USB host, behind an interface so it can be faked in tests.
abstract interface class UsbSerialGateway {
  Future<List<UsbRadioInfo>> list();

  /// Opens [deviceId] at Meshtastic's 115200 baud. Android asks the person
  /// for permission the first time.
  Future<UsbSerialPortHandle> open(int deviceId);

  /// Device IDs that are unplugged.
  Stream<int> get detached;
}

/// The gateway the app uses: the usb_serial plugin on Android, nothing
/// elsewhere. Tests may replace it.
abstract final class BastionUsb {
  static UsbSerialGateway? _override;
  static UsbSerialGateway get gateway => _override ?? (_plugin ??= PluginUsbSerialGateway());
  static UsbSerialGateway? _plugin;

  @visibleForTesting
  static set gateway(UsbSerialGateway? value) => _override = value;

  /// Whether this phone can use USB radios at all.
  static bool get supported => _override != null || (!kIsWeb && Platform.isAndroid);
}

class PluginUsbSerialGateway implements UsbSerialGateway {
  @override
  Future<List<UsbRadioInfo>> list() async => [
        for (final d in await UsbSerial.listDevices())
          if (d.deviceId != null)
            UsbRadioInfo(
              deviceId: d.deviceId!,
              name: [d.manufacturerName, d.productName].whereType<String>().where((s) => s.isNotEmpty).join(' ').trim().isEmpty
                  ? 'USB device ${d.deviceId}'
                  : [d.manufacturerName, d.productName].whereType<String>().where((s) => s.isNotEmpty).join(' '),
              vendorId: d.vid,
              productId: d.pid,
            ),
      ];

  @override
  Future<UsbSerialPortHandle> open(int deviceId) async {
    final port = await UsbSerial.createFromDeviceId(deviceId);
    if (port == null) throw StateError('This USB device is not a serial port the app can use.');
    if (!await port.open()) {
      throw StateError('USB permission was not granted, or the port could not be opened.');
    }
    await port.setDTR(true);
    await port.setRTS(true);
    await port.setPortParameters(115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
    final input = port.inputStream;
    if (input == null) {
      await port.close();
      throw StateError('The USB port opened without a data stream.');
    }
    return _PluginPort(port, input);
  }

  @override
  Stream<int> get detached => (UsbSerial.usbEventStream ?? const Stream<UsbEvent>.empty())
      .where((e) => e.event == UsbEvent.ACTION_USB_DETACHED && e.device?.deviceId != null)
      .map((e) => e.device!.deviceId!);
}

class _PluginPort implements UsbSerialPortHandle {
  _PluginPort(this._port, this.input);
  final UsbPort _port;
  @override
  final Stream<Uint8List> input;
  @override
  Future<void> write(Uint8List data) => _port.write(data);
  @override
  Future<void> close() => _port.close();
}

/// Meshtastic PhoneAPI over a USB serial cable, using the same framing as
/// TCP. Radios print debug text on the same line; the framer skips it.
class MeshtasticUsbTransport implements MeshtasticLinkTransport {
  MeshtasticUsbTransport({required this.deviceId, UsbSerialGateway? gateway, this.wakeDelay = const Duration(milliseconds: 100)})
      : _gateway = gateway ?? BastionUsb.gateway;

  final int deviceId;
  final UsbSerialGateway _gateway;

  /// Pause after the wake-up bytes before the first packet.
  final Duration wakeDelay;

  /// Meshtastic firmware wakes its serial API on a run of 0xC3 bytes.
  static final wakeBytes = Uint8List.fromList(List.filled(32, MeshtasticStreamFramer.start2));

  final StreamController<Uint8List> _incoming = StreamController<Uint8List>.broadcast();
  final StreamController<void> _linkLost = StreamController<void>.broadcast();
  final MeshtasticStreamFramer _framer = MeshtasticStreamFramer();
  UsbSerialPortHandle? _port;
  StreamSubscription<Uint8List>? _input;
  StreamSubscription<int>? _detach;
  bool _closing = false;

  @override
  Stream<Uint8List> get fromRadio => _incoming.stream;
  @override
  Stream<void> get linkLost => _linkLost.stream;
  @override
  bool get isConnected => _port != null;

  @override
  Future<void> connect() async {
    if (_port != null) return;
    _closing = false;
    final port = await _gateway.open(deviceId);
    _port = port;
    _input = port.input.listen(
      (bytes) {
        for (final payload in _framer.add(bytes)) {
          _incoming.add(payload);
        }
      },
      onError: (Object _) => _dropped(),
      onDone: _dropped,
    );
    _detach = _gateway.detached.where((id) => id == deviceId).listen((_) => _dropped());
    await port.write(wakeBytes);
    if (wakeDelay > Duration.zero) await Future<void>.delayed(wakeDelay);
  }

  void _dropped() {
    final port = _port;
    if (port == null) return;
    _port = null;
    unawaited(_input?.cancel());
    unawaited(_detach?.cancel());
    unawaited(port.close().catchError((Object _) {}));
    if (!_closing) _linkLost.add(null);
  }

  @override
  Future<void> sendToRadio(Uint8List envelope) async {
    final port = _port;
    if (port == null) throw StateError('USB link is not open.');
    await port.write(MeshtasticStreamFramer.frame(envelope));
  }

  @override
  Future<void> disconnect() async {
    _closing = true;
    final port = _port;
    _port = null;
    await _input?.cancel();
    await _detach?.cancel();
    if (port != null) {
      try {
        await port.close();
      } catch (_) {
        // Already unplugged.
      }
    }
  }
}
