import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Links the app was opened with: a scanned QR code's link, a web link or
/// an NFC tag (Android). Delivers each one once, even when the platform
/// reports the same link twice.
class BastionLinkIntake {
  BastionLinkIntake({MethodChannel? channel, DateTime Function()? clock})
    : _channel = channel ?? const MethodChannel('notoryx/links'),
      _clock = clock ?? DateTime.now;

  final MethodChannel _channel;
  final DateTime Function() _clock;
  final _links = StreamController<String>.broadcast();
  String? _last;
  DateTime? _lastAt;

  /// Every new link.
  Stream<String> get links => _links.stream;

  /// Starts listening, then delivers the link the app was started with.
  Future<void> start() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'link' && call.arguments is String) {
        deliver(call.arguments as String);
      }
    });
    try {
      final initial = await _channel.invokeMethod<String>('getInitialLink');
      if (initial != null) deliver(initial);
    } on MissingPluginException {
      // Built without the native side (tests, other platforms).
    } on PlatformException {
      // No link to hand over.
    }
  }

  /// Hands [link] on, unless it's the same link seen in the last 5 s.
  void deliver(String link) {
    final now = _clock();
    if (link == _last &&
        _lastAt != null &&
        now.difference(_lastAt!) < const Duration(seconds: 5)) {
      return;
    }
    _last = link;
    _lastAt = now;
    if (!_links.isClosed) _links.add(link);
  }

  Future<void> dispose() => _links.close();
}
