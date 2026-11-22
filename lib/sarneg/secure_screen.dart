import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keeps a screen that shows a secret out of screenshots, screen recording
/// and the recent-apps preview while it is open.
///
/// On Android this sets FLAG_SECURE on the window through the
/// `notoryx/secure_screen` channel. Other platforms have no such flag, so it
/// does nothing there. Screens can nest (a code-word screen that opens the
/// import screen): the flag stays on until the last one closes.
class SecureScreen extends StatefulWidget {
  /// Wraps [child] so it is kept out of screenshots while shown.
  const SecureScreen({super.key, required this.child});

  /// The screen to protect.
  final Widget child;

  /// The channel MainActivity listens on.
  static const channel = MethodChannel('notoryx/secure_screen');

  /// How many secure screens are open now.
  @visibleForTesting
  static int get openCount => _open;

  static int _open = 0;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> _set(bool on) async {
    if (!_supported) return;
    try {
      await channel.invokeMethod<void>('setSecure', on);
    } on MissingPluginException {
      // An engine without the activity's handler (tests, a plugin host).
    } on PlatformException catch (e, s) {
      debugPrint('SecureScreen: could not set FLAG_SECURE: $e\n$s');
    }
  }

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    if (SecureScreen._open++ == 0) SecureScreen._set(true);
  }

  @override
  void dispose() {
    if (--SecureScreen._open == 0) SecureScreen._set(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
