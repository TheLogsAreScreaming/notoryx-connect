import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A message waiting for its send time.
class BastionScheduledMessage {
  const BastionScheduledMessage({
    required this.id,
    required this.text,
    required this.destination,
    required this.channel,
    required this.dueAt,
  });

  factory BastionScheduledMessage.fromJson(Map<String, dynamic> json) => BastionScheduledMessage(
        id: json['id'] as int,
        text: json['text'] as String,
        destination: json['destination'] as int,
        channel: json['channel'] as int,
        dueAt: DateTime.fromMillisecondsSinceEpoch(json['dueAt'] as int),
      );

  final int id;
  final String text;
  final int destination;
  final int channel;
  final DateTime dueAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'destination': destination,
        'channel': channel,
        'dueAt': dueAt.millisecondsSinceEpoch,
      };
}

/// Messages saved on this phone to send later.
///
/// They go out only while the app is running and the radio is connected. A
/// message more than [grace] late is held as missed instead of sent, so old
/// news like "on my way" can't go out hours after it stopped being true.
class BastionScheduledMessages extends ChangeNotifier {
  static final instance = BastionScheduledMessages();
  static const maxItems = 20;
  static const grace = Duration(hours: 1);
  static const _key = 'bastion.scheduled_messages';

  final List<BastionScheduledMessage> _items = [];
  bool _flushing = false;

  List<BastionScheduledMessage> get items => List.unmodifiable(_items);

  /// Whether [item] is too late to send.
  static bool isMissed(BastionScheduledMessage item, DateTime now) => now.isAfter(item.dueAt.add(grace));

  Future<void> load() async {
    try {
      final raw = await SharedPreferencesAsync().getString(_key);
      if (raw == null) return;
      _items
        ..clear()
        ..addAll((jsonDecode(raw) as List).map((e) => BastionScheduledMessage.fromJson((e as Map).cast<String, dynamic>())));
      _sort();
      notifyListeners();
    } catch (_) {
      // A damaged list must not stop the app from opening.
      _items.clear();
    }
  }

  /// Saves a message for later. Returns false when the list is full.
  Future<bool> add({required String text, required int destination, required int channel, required DateTime dueAt}) async {
    if (_items.length >= maxItems) return false;
    var id = dueAt.microsecondsSinceEpoch;
    while (_items.any((i) => i.id == id)) {
      id++;
    }
    _items.add(BastionScheduledMessage(id: id, text: text, destination: destination, channel: channel, dueAt: dueAt));
    await _changed();
    return true;
  }

  Future<void> cancel(int id) async {
    _items.removeWhere((i) => i.id == id);
    await _changed();
  }

  /// Sends what is due. A failed send stays listed and is retried next time.
  Future<void> flushDue(DateTime now, Future<void> Function(BastionScheduledMessage) send) async {
    if (_flushing) return;
    _flushing = true;
    try {
      final due = [for (final i in _items) if (!i.dueAt.isAfter(now) && !isMissed(i, now)) i];
      for (final item in due) {
        try {
          await send(item);
        } catch (_) {
          continue;
        }
        _items.removeWhere((i) => i.id == item.id);
        await _changed();
      }
    } finally {
      _flushing = false;
    }
  }

  void _sort() => _items.sort((a, b) => a.dueAt.compareTo(b.dueAt));

  Future<void> _changed() async {
    _sort();
    notifyListeners();
    await SharedPreferencesAsync().setString(_key, jsonEncode([for (final i in _items) i.toJson()]));
  }
}
