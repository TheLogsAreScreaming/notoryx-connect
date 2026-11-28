import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bastion_chat_message.dart';
import 'meshtastic_radio_coordinator.dart';

/// What the home-screen widget shows. Pure, so it can be tested.
@immutable
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.title,
    required this.detail,
    required this.messages,
    required this.alert,
    required this.updated,
    this.tracked = '',
  });

  final String title;
  final String detail;
  final String messages;

  /// Shown in red at the top; empty when nothing needs attention.
  final String alert;
  final String updated;

  /// Status line for the node the user chose to track; empty when none.
  final String tracked;

  /// Builds the widget text. Message text appears only when [showMessage],
  /// since the home screen is visible to anyone holding the phone.
  static WidgetSnapshot of(
    MeshtasticRadioCoordinator radio,
    DateTime now, {
    required bool showMessage,
    int? trackedNum,
  }) {
    final ready = radio.isReady;
    final local = radio.localNode;
    final battery = local?.batteryLevel;
    final unread = radio.unreadCount;
    final incoming = [
      for (final m in radio.messages)
        if (m.direction == BastionMessageDirection.incoming && !m.isReaction) m,
    ];
    final last = incoming.isEmpty ? null : incoming.last;
    final sos = radio.trip.sos;
    final overdue = radio.trip.overdue;
    String clock(DateTime t) =>
        '${t.toLocal().hour.toString().padLeft(2, '0')}:${t.toLocal().minute.toString().padLeft(2, '0')}';
    String _ago(DateTime lh) {
      final d = now.difference(lh);
      if (d.inMinutes < 60) return '${d.inMinutes} min ago';
      if (d.inHours < 24) return '${d.inHours} h ago';
      return '${d.inDays} d ago';
    }
    String tracked = '';
    if (trackedNum != null) {
      final node = radio.nodes.where((n) => n.num == trackedNum).firstOrNull;
      if (node != null) {
        final parts = <String>[node.displayName];
        final bat = node.batteryLevel;
        if (bat != null) parts.add(bat > 100 ? 'plugged in' : '$bat%');
        final lh = node.lastHeard;
        if (lh != null) parts.add(_ago(lh));
        tracked = parts.join(' • ');
      }
    }
    return WidgetSnapshot(
      title: ready
          ? 'Connected${local?.displayName == null ? '' : ' • ${local!.displayName}'}'
          : radio.isReconnecting
              ? 'Reconnecting…'
              : 'No radio connected',
      detail: ready
          ? [
              '${radio.nodes.length} node${radio.nodes.length == 1 ? '' : 's'}',
              if (battery != null) battery > 100 ? 'plugged in' : 'battery $battery%',
            ].join(' • ')
          : 'Open the app to connect',
      messages: unread == 0
          ? 'No unread messages'
          : '$unread unread${showMessage && last != null ? ' • ${radio.nodeName(last.from)}: ${last.text}' : ''}',
      alert: sos.active
          ? 'SOS active'
          : overdue.isNotEmpty
              ? 'Overdue: ${overdue.map(radio.nodeName).join(', ')}'
              : '',
      updated: 'Updated ${clock(now)}',
      tracked: tracked,
    );
  }

  Map<String, String> toMap() => {
        'widget_title': title,
        'widget_detail': detail,
        'widget_messages': messages,
        'widget_alert': alert,
        'widget_updated': updated,
        'widget_tracked': tracked,
      };

  /// Same content, ignoring the time stamp.
  bool sameAs(WidgetSnapshot? other) =>
      other != null && title == other.title && detail == other.detail &&
      messages == other.messages && alert == other.alert &&
      tracked == other.tracked;
}

/// Sends widget updates when what it shows changes, at most every
/// [minGap], and never more often than needed to keep it current.
class BastionHomeWidget {
  BastionHomeWidget(this._radio, {Future<void> Function(Map<String, String>)? push, this.minGap = const Duration(seconds: 30), DateTime Function()? clock})
      : _push = push ?? _pushToAndroid,
        _clock = clock ?? DateTime.now;

  static const providerName = 'com.bastionmesh.bastion.StatusWidgetProvider';

  /// Whether message text may appear on the widget (off by default).
  static const showMessageKey = 'bastion.widget.show_message';

  /// The node num to track on the widget, or null for none.
  static const trackedNodeKey = 'bastion.widget.tracked_node';

  /// Whether this platform has a home-screen widget.
  static bool get supported => !kIsWeb && Platform.isAndroid;

  final MeshtasticRadioCoordinator _radio;
  final Future<void> Function(Map<String, String>) _push;
  final DateTime Function() _clock;
  final Duration minGap;

  /// The updater the app is running, for the Settings switch.
  static BastionHomeWidget? instance;

  bool showMessage = false;
  int? trackedNodeNum;
  WidgetSnapshot? _sent;
  DateTime? _sentAt;
  Timer? _later;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      final prefs = SharedPreferencesAsync();
      showMessage = await prefs.getBool(showMessageKey) ?? false;
      trackedNodeNum = await prefs.getInt(trackedNodeKey);
    } catch (_) {
      // Defaults stay.
    }
    _radio.addListener(_changed);
    _changed();
  }

  Future<void> setShowMessage(bool value) async {
    showMessage = value;
    try {
      await SharedPreferencesAsync().setBool(showMessageKey, value);
    } catch (_) {
      // Applies this session.
    }
    _sent = null;
    _changed();
  }

  Future<void> setTrackedNode(int? num) async {
    trackedNodeNum = num;
    try {
      final prefs = SharedPreferencesAsync();
      if (num == null) {
        await prefs.remove(trackedNodeKey);
      } else {
        await prefs.setInt(trackedNodeKey, num);
      }
    } catch (_) {
      // Applies this session.
    }
    _sent = null;
    _changed();
  }

  void _changed() {
    final snap = WidgetSnapshot.of(
      _radio,
      _clock(),
      showMessage: showMessage,
      trackedNum: trackedNodeNum,
    );
    if (snap.sameAs(_sent)) return;
    final wait = _sentAt == null ? Duration.zero : minGap - _clock().difference(_sentAt!);
    if (wait > Duration.zero) {
      _later ??= Timer(wait, () {
        _later = null;
        _changed();
      });
      return;
    }
    _sent = snap;
    _sentAt = _clock();
    unawaited(_push(snap.toMap()).catchError((Object e) => debugPrint('Widget update failed: $e')));
  }

  void dispose() {
    _radio.removeListener(_changed);
    _later?.cancel();
  }

  static Future<void> _pushToAndroid(Map<String, String> values) async {
    if (!supported) return;
    for (final e in values.entries) {
      await HomeWidget.saveWidgetData<String>(e.key, e.value);
    }
    await HomeWidget.updateWidget(qualifiedAndroidName: providerName);
  }
}
