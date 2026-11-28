import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// What [openCheckedDatabase] did.
class CheckedOpen<T> {
  const CheckedOpen(this.value, {this.setAsidePath});

  final T value;

  /// Where a damaged file was moved, when one was; null when the database
  /// opened cleanly.
  final String? setAsidePath;
}

/// Opens the database at [path] with [open], then asks SQLite whether the
/// file is sound (`PRAGMA quick_check`). A file that won't open or isn't
/// sound is moved aside (with its -wal/-shm journals) to
/// `<path>.damaged-<time>`, never deleted, and a fresh database is opened in
/// its place, so a damaged file can't keep the app from starting and can
/// still be recovered by hand.
Future<CheckedOpen<T>> openCheckedDatabase<T>({
  required DatabaseFactory factory,
  required String path,
  required Future<T> Function(DatabaseFactory factory, String path) open,
  required Database Function(T opened) databaseOf,
  DateTime Function()? clock,
}) async {
  Object? problem;
  try {
    final opened = await open(factory, path);
    final db = databaseOf(opened);
    try {
      final rows = await db.rawQuery('PRAGMA quick_check');
      final verdict = rows.isEmpty ? null : rows.first.values.first;
      if (verdict == 'ok') return CheckedOpen(opened);
      problem = 'quick_check: $verdict';
    } catch (e) {
      problem = e;
    }
    try {
      await db.close();
    } catch (_) {}
  } catch (e) {
    problem = e;
  }
  debugPrint('Database $path is damaged ($problem); setting it aside');
  final stamp = (clock ?? DateTime.now)().millisecondsSinceEpoch;
  final aside = '$path.damaged-$stamp';
  await _moveIfExists(path, aside);
  await _moveIfExists('$path-wal', '$aside-wal');
  await _moveIfExists('$path-shm', '$aside-shm');
  await _moveIfExists('$path-journal', '$aside-journal');
  return CheckedOpen(await open(factory, path), setAsidePath: aside);
}

Future<void> _moveIfExists(String from, String to) async {
  if (kIsWeb) return;
  final file = File(from);
  if (await file.exists()) await file.rename(to);
}
