import 'package:flutter/foundation.dart';

/// One line of the connection log.
@immutable
class ConnectionLogEntry {
  const ConnectionLogEntry(this.time, this.text);
  final DateTime time;
  final String text;

  @override
  String toString() => '${time.toIso8601String()}  $text';
}

/// The last [capacity] connection events, kept in memory only, so a user
/// can copy them into a bug report. Never saved and never sent anywhere.
class BastionConnectionLog extends ChangeNotifier {
  BastionConnectionLog({this.capacity = 100, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final int capacity;
  final DateTime Function() _clock;
  final List<ConnectionLogEntry> _entries = [];

  List<ConnectionLogEntry> get entries => List.unmodifiable(_entries);

  void add(String text) {
    _entries.add(ConnectionLogEntry(_clock(), text));
    if (_entries.length > capacity) _entries.removeRange(0, _entries.length - capacity);
    notifyListeners();
  }
}
