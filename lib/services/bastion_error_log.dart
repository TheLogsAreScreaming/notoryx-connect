import 'package:flutter/foundation.dart';

/// One app error, kept for the support report.
@immutable
class AppErrorEntry {
  const AppErrorEntry(this.time, this.summary);
  final DateTime time;

  /// The error's first line, with anything sensitive removed later by the
  /// support report.
  final String summary;

  @override
  String toString() => '${time.toIso8601String()}  $summary';
}

/// The last [capacity] uncaught app errors, kept in memory only so a person
/// can include them in a support report. Never saved and never sent.
class BastionErrorLog extends ChangeNotifier {
  BastionErrorLog({this.capacity = 30, DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  static final instance = BastionErrorLog();

  final int capacity;
  final DateTime Function() _clock;
  final List<AppErrorEntry> _entries = [];

  List<AppErrorEntry> get entries => List.unmodifiable(_entries);

  void add(Object error) {
    final first = '$error'.split('\n').first.trim();
    _entries.add(AppErrorEntry(_clock(), first.length > 300 ? '${first.substring(0, 300)}…' : first));
    if (_entries.length > capacity) _entries.removeRange(0, _entries.length - capacity);
    notifyListeners();
  }

  /// Records Flutter and uncaught async errors here as well, keeping any
  /// handler that was already in place.
  void install() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      add(details.exception);
      (previous ?? FlutterError.presentError)(details);
    };
    final platformPrevious = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      add(error);
      return platformPrevious?.call(error, stack) ?? false;
    };
  }
}
