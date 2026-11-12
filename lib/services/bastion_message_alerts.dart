import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/bastion_text.dart';

import 'bastion_field_alerts.dart';

/// Shows a phone notification for an incoming mesh message.
const _replyActionId = 'reply';
const _replyPortName = 'bastion.notification_reply';

/// A reply typed on a notification, on the phone or on a paired watch.
class BastionNotificationReply {
  const BastionNotificationReply({required this.destination, required this.channel, required this.text});
  final int destination;
  final int channel;
  final String text;

  static String payload(int destination, int channel) => '$destination:$channel';

  /// Null unless this is a non-empty reply with a valid target.
  static BastionNotificationReply? parse(String? actionId, String? payload, String? input) {
    final text = input?.trim() ?? '';
    if (actionId != _replyActionId || text.isEmpty || payload == null) return null;
    final parts = payload.split(':');
    if (parts.length != 2) return null;
    final destination = int.tryParse(parts[0]), channel = int.tryParse(parts[1]);
    if (destination == null || channel == null) return null;
    return BastionNotificationReply(destination: destination, channel: channel, text: text);
  }
}

/// Runs in a background isolate, so it hands the reply to the app's isolate,
/// which owns the radio link. If the app isn't running, there's nothing to send it.
@pragma('vm:entry-point')
void bastionNotificationReplyInBackground(NotificationResponse response) {
  IsolateNameServer.lookupPortByName(_replyPortName)
      ?.send([response.actionId, response.payload, response.input]);
}

abstract interface class BastionMessageAlerts {
  Future<void> show({
    required int packetId,
    required String sender,
    required String text,
    required bool isDirect,
    required int channel,
    int? replyDestination,
  });

  /// Shows a local field alert (battery, new node, quiet favorite).
  Future<void> showFieldAlert(BastionFieldAlert alert);
}

/// Android and iOS notifications for messages that arrive while Bastion is not in
/// the foreground. Direct messages and channel messages use separate
/// channels so people can mute one without the other in Android settings.
class BastionLocalMessageAlerts implements BastionMessageAlerts {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  static bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static const _ios = DarwinNotificationDetails(presentAlert: true, presentSound: true);

  // Replying works from the phone and from a paired Wear OS watch, which
  // mirrors this action. The text goes out over the mesh as typed.
  static AndroidNotificationAction get _replyAction => AndroidNotificationAction(
    _replyActionId,
    BastionText.l.svcReply,
    allowGeneratedReplies: true,
    inputs: [AndroidNotificationActionInput(label: BastionText.l.svcReply)],
  );

  // Names and descriptions show in Android's notification settings.
  static AndroidNotificationDetails get _direct => AndroidNotificationDetails(
    'bastion_direct_messages',
    BastionText.l.svcDirectChannel,
    channelDescription: BastionText.l.svcDirectChannelSub,
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.message,
    actions: [_replyAction],
  );

  static AndroidNotificationDetails get _channel => AndroidNotificationDetails(
    'bastion_channel_messages',
    BastionText.l.svcChannelChannel,
    channelDescription: BastionText.l.svcChannelChannelSub,
    importance: Importance.defaultImportance,
    category: AndroidNotificationCategory.message,
    actions: [_replyAction],
  );

  static AndroidNotificationDetails get _field => AndroidNotificationDetails(
    'bastion_field_alerts',
    BastionText.l.svcFieldChannel,
    channelDescription: BastionText.l.svcFieldChannelSub,
    importance: Importance.high,
    priority: Priority.high,
    category: AndroidNotificationCategory.status,
  );

  @override
  Future<void> showFieldAlert(BastionFieldAlert alert) async {
    if (!_supported) return;
    if (!await (_ready ??= _initialize())) return;
    try {
      await _plugin.show(
        id: alert.notificationId,
        title: alert.title,
        body: alert.body,
        notificationDetails: NotificationDetails(android: _field, iOS: _ios),
      );
    } catch (error) {
      debugPrint('Field alert failed: $error');
    }
  }

  ReceivePort? _replyPort;
  void Function(BastionNotificationReply)? _onReply;

  void _handle(String? actionId, String? payload, String? input) {
    final reply = BastionNotificationReply.parse(actionId, payload, input);
    if (reply != null) _onReply?.call(reply);
  }

  /// Starts accepting notification replies; [onReply] sends them on the mesh.
  void listenForReplies(void Function(BastionNotificationReply) onReply) {
    _onReply = onReply;
    if (_replyPort != null || kIsWeb || !Platform.isAndroid) return;
    final port = ReceivePort()
      ..listen((m) {
        final parts = m as List;
        _handle(parts[0] as String?, parts[1] as String?, parts[2] as String?);
      });
    IsolateNameServer.removePortNameMapping(_replyPortName);
    IsolateNameServer.registerPortWithName(port.sendPort, _replyPortName);
    _replyPort = port;
  }

  void stopListeningForReplies() {
    IsolateNameServer.removePortNameMapping(_replyPortName);
    _replyPort?.close();
    _replyPort = null;
    _onReply = null;
  }

  /// Tells the person a reply couldn't be handed to the radio.
  Future<void> showReplyFailed(String text) async {
    if (!_supported || !await (_ready ??= _initialize())) return;
    try {
      await _plugin.show(
        id: text.hashCode & 0x7fffffff,
        title: 'Reply not sent',
        body: text,
        notificationDetails: NotificationDetails(android: _field, iOS: _ios),
      );
    } catch (error) {
      debugPrint('Reply failure alert failed: $error');
    }
  }

  /// Asks for notification permission while the app is on screen. iOS can't
  /// show that prompt from the background, when the first alert would arrive.
  Future<void> prepare() async {
    if (!kIsWeb && Platform.isIOS) await (_ready ??= _initialize());
  }

  Future<bool> _initialize() async {
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // iOS shows its permission prompt here, so this runs at launch there.
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (r) => _handle(r.actionId, r.payload, r.input),
        onDidReceiveBackgroundNotificationResponse: bastionNotificationReplyInBackground,
      );
      return ok ?? false;
    } catch (error) {
      debugPrint('Bastion message alerts unavailable: $error');
      return false;
    }
  }

  @override
  Future<void> show({
    required int packetId,
    required String sender,
    required String text,
    required bool isDirect,
    required int channel,
    int? replyDestination,
  }) async {
    if (!_supported) return;
    if (!await (_ready ??= _initialize())) return;
    try {
      await _plugin.show(
        id: packetId & 0x7fffffff,
        title: isDirect ? sender : BastionText.l.svcFromChannel(sender, channel),
        body: text,
        notificationDetails: NotificationDetails(android: isDirect ? _direct : _channel, iOS: _ios),
        payload: replyDestination == null ? null : BastionNotificationReply.payload(replyDestination, channel),
      );
    } catch (error) {
      debugPrint('Bastion message alert failed: $error');
    }
  }
}
