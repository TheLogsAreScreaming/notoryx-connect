import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/bastion_text.dart';

import 'bastion_chat_message.dart';

/// Labels for the date dividers in the message timeline.
abstract final class BastionChatDays {
  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  /// The calendar day [time] falls on, in local time.
  static DateTime dayOf(DateTime time) {
    final local = time.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// "Today", "Yesterday", a weekday within the last week, else a date.
  static String label(DateTime time, DateTime now) {
    final day = dayOf(time);
    final today = dayOf(now);
    // Calendar days, so a daylight-saving change doesn't skew the count.
    final days = DateTime.utc(today.year, today.month, today.day)
        .difference(DateTime.utc(day.year, day.month, day.day))
        .inDays;
    final l = BastionText.l;
    if (days == 0) return l.svcToday;
    if (days == 1) return l.svcYesterday;
    final weekday = days > 1 && days < 7;
    try {
      return DateFormat(weekday ? 'EEEE' : day.year == today.year ? 'MMMd' : 'yMMMd', l.localeName).format(day);
    } on Exception {
      // Date names load with the app's localizations; outside it (some
      // tests) they aren't there, so fall back to English.
      if (weekday) return _weekdays[day.weekday - 1];
      final date = '${_months[day.month - 1]} ${day.day}';
      return day.year == today.year ? date : '$date, ${day.year}';
    }
  }
}

/// Finds @mentions of your own node in message text.
abstract final class BastionMentions {
  /// Whether [text] mentions any of [names] as `@name`, ignoring case. The
  /// name must end at a word boundary, so `@Bob` doesn't match `@Bobby`.
  static bool mentions(String text, Iterable<String?> names) {
    final lower = text.toLowerCase();
    for (final raw in names) {
      final name = raw?.trim().toLowerCase() ?? '';
      if (name.isEmpty) continue;
      final needle = '@$name';
      var at = lower.indexOf(needle);
      while (at >= 0) {
        final end = at + needle.length;
        if (end >= lower.length || !_isWordChar(lower.codeUnitAt(end))) return true;
        at = lower.indexOf(needle, at + 1);
      }
    }
    return false;
  }

  static bool _isWordChar(int c) =>
      (c >= 0x30 && c <= 0x39) || (c >= 0x61 && c <= 0x7a) || c == 0x5f || c > 0x7f;
}

/// Pinned messages and the read marker, kept on the phone.
///
/// A message is pinned by sender and packet ID, so pins survive history
/// reloads. Unreadable storage is never overwritten.
class BastionChatMarks {
  BastionChatMarks({SharedPreferencesAsync? preferences}) : _preferences = preferences;

  static const key = 'bastion.chat.marks.v1';
  static const maxPins = 50;

  SharedPreferencesAsync? _preferences;
  SharedPreferencesAsync get _store => _preferences ??= SharedPreferencesAsync();
  final List<String> _pins = [];
  DateTime? _lastRead;
  bool _loadFailed = false;

  /// When you last looked at Chats, or null if never.
  DateTime? get lastRead => _lastRead;

  static String idOf(BastionChatMessage m) => '${m.from}:${m.packetId}';

  bool isPinned(BastionChatMessage m) => _pins.contains(idOf(m));

  /// Pinned messages in [messages], most recently pinned first.
  List<BastionChatMessage> pinnedIn(List<BastionChatMessage> messages) {
    final byId = {for (final m in messages) idOf(m): m};
    return [for (final id in _pins.reversed) if (byId[id] case final m?) m];
  }

  /// Incoming messages newer than [lastRead]. Before the first visit every
  /// message counts as read, so a fresh install doesn't show a huge count.
  int unreadIn(List<BastionChatMessage> messages) {
    final since = _lastRead;
    if (since == null) return 0;
    return messages.where((m) => isUnread(m, since)).length;
  }

  static bool isUnread(BastionChatMessage m, DateTime since) =>
      !m.isReaction &&
      m.direction == BastionMessageDirection.incoming &&
      m.timestamp.isAfter(since);

  Future<void> load() async {
    _pins.clear();
    _lastRead = null;
    try {
      final raw = await _store.getString(key);
      if (raw == null) return;
      final json = jsonDecode(raw);
      if (json is! Map) return;
      if (json['pins'] case final List pins) _pins.addAll(pins.whereType<String>());
      if (json['lastRead'] case final String t) _lastRead = DateTime.tryParse(t)?.toLocal();
    } on FormatException {
      // Damaged marks are replaced by the next change.
    } catch (_) {
      _loadFailed = true;
    }
  }

  /// Pins or unpins [m]. Returns a problem for the user, or null.
  Future<String?> togglePin(BastionChatMessage m) async {
    if (_loadFailed) return 'Pins could not be read from phone storage, so changes are not saved.';
    final id = idOf(m);
    if (!_pins.remove(id)) {
      if (_pins.length >= maxPins) return 'You can pin up to $maxPins messages.';
      _pins.add(id);
    }
    return _save();
  }

  /// Records that everything up to [time] has been seen.
  Future<void> markRead(DateTime time) async {
    if (_lastRead != null && !time.isAfter(_lastRead!)) return;
    _lastRead = time;
    if (_loadFailed) return;
    await _save();
  }

  Future<String?> _save() async {
    try {
      await _store.setString(key, jsonEncode({
        'pins': _pins,
        if (_lastRead != null) 'lastRead': _lastRead!.toUtc().toIso8601String(),
      }));
      return null;
    } catch (_) {
      return 'The change applies now but could not be saved.';
    }
  }
}
