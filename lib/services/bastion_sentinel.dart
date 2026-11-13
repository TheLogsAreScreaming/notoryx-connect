import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The NOTORYX Sentinel relay. It holds the moderation service's keys, so
/// this app never does. Source: TheLogsAreScreaming/notoryx-sentinel-relay.
const sentinelRelayUrl = 'https://sentinel-relay.meshmayhem.org';

/// This app's network on the relay.
const sentinelNetwork = 'meshtastic';

/// A Meshtastic node number as Sentinel's node ID, e.g. `!a1b2c3d4`.
String sentinelNodeId(int nodeNum) =>
    '!${(nodeNum & 0xffffffff).toRadixString(16).padLeft(8, '0')}';

/// One HTTP exchange with the relay. Swapped out in tests.
typedef SentinelResponse = ({int status, String body, String? retryAfter});
typedef SentinelTransport =
    Future<SentinelResponse> Function(String method, Uri url, String? body);

Future<SentinelResponse> _ioTransport(String method, Uri url, String? body) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.openUrl(method, url);
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (body != null) {
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(body));
    }
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    return (
      status: res.statusCode,
      body: text,
      retryAfter: res.headers.value('retry-after'),
    );
  } finally {
    client.close(force: true);
  }
}

String _randomRef() {
  final r = Random.secure();
  return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

/// Why a node is being reported. The wire text stays English because
/// moderators read it.
enum SentinelReason {
  spam('Spam or advertising'),
  flooding('Flooding the mesh'),
  abuse('Harassment or abuse'),
  impersonation('Impersonation'),
  other('Other');

  const SentinelReason(this.wire);
  final String wire;
}

/// A node with a moderator-approved ban. Advisory only: nothing on the mesh
/// is blocked, and the user can ignore it.
@immutable
class SentinelBan {
  const SentinelBan({
    required this.nodeId,
    required this.caseRef,
    this.bannedAt,
    this.appealPending = false,
  });

  final String nodeId;
  final String caseRef;
  final DateTime? bannedAt;
  final bool appealPending;

  static SentinelBan? fromJson(Object? json) {
    if (json is! Map) return null;
    final nodeId = json['nodeId'];
    final caseRef = json['caseRef'];
    if (nodeId is! String || caseRef is! String) return null;
    if (nodeId.isEmpty || caseRef.isEmpty) return null;
    final at = json['bannedAt'];
    return SentinelBan(
      nodeId: nodeId.toLowerCase(),
      caseRef: caseRef,
      bannedAt: at is String ? DateTime.tryParse(at) : null,
      appealPending: json['appealPending'] == true,
    );
  }

  Map<String, Object?> toJson() => {
    'nodeId': nodeId,
    'caseRef': caseRef,
    'bannedAt': bannedAt?.toUtc().toIso8601String(),
    'appealPending': appealPending,
  };
}

/// A report waiting to be sent. [externalRef] makes resending safe: the
/// relay returns the same case instead of opening a second one.
@immutable
class SentinelReport {
  const SentinelReport({
    required this.nodeId,
    required this.reason,
    required this.externalRef,
    required this.createdAt,
    this.nodeName,
    this.messageExcerpt,
  });

  final String nodeId;
  final String? nodeName;
  final String reason;
  final String? messageExcerpt;
  final String externalRef;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'nodeId': nodeId,
    if (nodeName != null) 'nodeName': nodeName,
    'reason': reason,
    if (messageExcerpt != null) 'messageExcerpt': messageExcerpt,
    'externalRef': externalRef,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  Map<String, Object?> toWire() => toJson()..remove('createdAt');

  static SentinelReport? fromJson(Object? json) {
    if (json is! Map) return null;
    final nodeId = json['nodeId'];
    final reason = json['reason'];
    final ref = json['externalRef'];
    if (nodeId is! String || reason is! String || ref is! String) return null;
    final name = json['nodeName'];
    final excerpt = json['messageExcerpt'];
    final at = json['createdAt'];
    return SentinelReport(
      nodeId: nodeId,
      nodeName: name is String ? name : null,
      reason: reason,
      messageExcerpt: excerpt is String ? excerpt : null,
      externalRef: ref,
      createdAt:
          (at is String ? DateTime.tryParse(at) : null) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

/// What happened to a report.
sealed class SentinelReportOutcome {
  const SentinelReportOutcome();
}

/// The relay accepted it; moderators will see case [caseRef].
class SentinelReportSent extends SentinelReportOutcome {
  const SentinelReportSent(this.caseRef);
  final String caseRef;
}

/// No connection (or the service is busy); kept and sent later.
class SentinelReportQueued extends SentinelReportOutcome {
  const SentinelReportQueued();
}

/// The relay refused it and resending won't help.
class SentinelReportRejected extends SentinelReportOutcome {
  const SentinelReportRejected(this.message);
  final String message;
}

/// What happened to an appeal.
enum SentinelAppealOutcome {
  received,
  unknownCase,
  notAppealable,
  tooMany,
  failed,
}

/// Opt-in link to NOTORYX Sentinel, the human-reviewed moderation service:
/// files spam reports (queued while offline), keeps the advisory list of
/// banned nodes, and relays appeals.
///
/// Off by default. While off it makes no network requests at all.
class SentinelService extends ChangeNotifier {
  SentinelService({
    SentinelTransport? transport,
    String baseUrl = sentinelRelayUrl,
    DateTime Function()? now,
    String Function()? newRef,
  }) : _transport = transport ?? _ioTransport,
       _base = baseUrl,
       _now = now ?? DateTime.now,
       _newRef = newRef ?? _randomRef;

  /// The app-wide service. Connect has no dependency injection.
  static SentinelService instance = SentinelService();

  final SentinelTransport _transport;
  final String _base;
  final DateTime Function() _now;
  final String Function() _newRef;

  static const prefEnabled = 'sentinel_enabled_v1';
  static const prefHide = 'sentinel_hide_flagged_v1';
  static const prefBans = 'sentinel_bans_v1';
  static const prefSynced = 'sentinel_synced_at_v1';
  static const prefQueue = 'sentinel_queue_v1';
  static const prefSent = 'sentinel_sent_v1';

  static const _timeout = Duration(seconds: 15);
  static const syncEvery = Duration(hours: 6);
  static const _minSyncGap = Duration(minutes: 5);
  static const maxQueue = 50;
  static const maxSentHistory = 20;
  static const maxExcerpt = 280;
  static const maxNote = 200;

  bool _enabled = false;
  bool _hideFlagged = false;
  Map<String, SentinelBan> _bans = const {};
  DateTime? _syncedAt;
  List<SentinelReport> _queue = const [];
  List<({String caseRef, String? nodeName, DateTime at})> _sent = const [];
  Timer? _timer;
  bool _syncing = false;
  Future<bool>? _inflight;
  bool _flushing = false;
  bool _disposed = false;
  String? lastError;

  bool get enabled => _enabled;

  /// Whether channel messages from flagged senders are hidden.
  bool get hideFlagged => _hideFlagged;
  DateTime? get syncedAt => _syncedAt;
  int get flaggedCount => _bans.length;
  int get queuedCount => _queue.length;
  List<({String caseRef, String? nodeName, DateTime at})> get sentReports =>
      List.unmodifiable(_sent);
  bool get syncing => _syncing;

  /// The ban on this node, if any.
  SentinelBan? banFor(int nodeNum) =>
      _enabled ? _bans[sentinelNodeId(nodeNum)] : null;

  final Map<String, Object?> _stored = {};

  String? _get(String name) => _stored[name] as String?;
  bool? _getBool(String name) => _stored[name] as bool?;

  Future<void> _load() async {
    try {
      final p = SharedPreferencesAsync();
      for (final n in [prefEnabled, prefHide]) {
        _stored[n] = await p.getBool(n);
      }
      for (final n in [prefBans, prefSynced, prefQueue, prefSent]) {
        _stored[n] = await p.getString(n);
      }
    } on Object {
      // Storage unavailable; start empty.
    }
  }

  Future<void> _set(String name, Object value) async {
    _stored[name] = value;
    try {
      final p = SharedPreferencesAsync();
      if (value is bool) {
        await p.setBool(name, value);
      } else {
        await p.setString(name, value as String);
      }
    } on Object {
      // Storage unavailable; kept for this session only.
    }
  }

  /// Loads saved state; if the user has opted in, syncs now and every six
  /// hours and sends any queued reports.
  Future<void> start() async {
    await _load();
    _enabled = _getBool(prefEnabled) ?? false;
    _hideFlagged = _getBool(prefHide) ?? false;
    _loadBans();
    _loadQueue();
    _loadSent();
    _notify();
    if (_enabled) _schedule();
  }

  void _loadBans() {
    final raw = _get(prefBans);
    final at = _get(prefSynced);
    _syncedAt = at == null ? null : DateTime.tryParse(at);
    if (raw == null) return;
    try {
      _bans = _indexBans(jsonDecode(raw));
    } on FormatException {
      _bans = const {};
    }
  }

  void _loadQueue() {
    final raw = _get(prefQueue);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        _queue = [for (final j in list) ?SentinelReport.fromJson(j)];
      }
    } on FormatException {
      _queue = const [];
    }
  }

  void _loadSent() {
    final raw = _get(prefSent);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw);
      if (list is! List) return;
      _sent = [
        for (final j in list)
          if (j is Map &&
              j['caseRef'] is String &&
              DateTime.tryParse('${j['at']}') != null)
            (
              caseRef: j['caseRef'] as String,
              nodeName: j['nodeName'] is String
                  ? j['nodeName'] as String
                  : null,
              at: DateTime.parse('${j['at']}'),
            ),
      ];
    } on FormatException {
      _sent = const [];
    }
  }

  static Map<String, SentinelBan> _indexBans(Object? list) {
    if (list is! List) return const {};
    final out = <String, SentinelBan>{};
    for (final j in list) {
      final b = SentinelBan.fromJson(j);
      if (b != null) out[b.nodeId] = b;
    }
    return out;
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(syncEvery, (_) => unawaited(refresh()));
    unawaited(refresh());
  }

  /// Turns the feature on or off. Turning it off forgets the ban list and
  /// any unsent reports.
  Future<void> setEnabled(bool on) async {
    if (on == _enabled) return;
    _enabled = on;
    await _set(prefEnabled, on);
    if (on) {
      _schedule();
    } else {
      _timer?.cancel();
      _timer = null;
      _bans = const {};
      _queue = const [];
      _syncedAt = null;
      await _set(prefBans, '[]');
      await _set(prefQueue, '[]');
    }
    _notify();
  }

  Future<void> setHideFlagged(bool on) async {
    _hideFlagged = on;
    await _set(prefHide, on);
    _notify();
  }

  /// Syncs the ban list and sends queued reports.
  Future<void> refresh({bool force = false}) async {
    if (!_enabled) return;
    await syncDecisions(force: force);
    await flushQueue();
  }

  Uri _uri(String route) => Uri.parse('$_base/v1/$sentinelNetwork/$route');

  /// Fetches the advisory ban list (at most once every five minutes unless
  /// [force]d). Keeps the last good list when offline.
  Future<bool> syncDecisions({bool force = false}) {
    if (!_enabled) return Future.value(false);
    // Join a download already under way rather than starting a second.
    final running = _inflight;
    if (running != null) return running;
    final last = _syncedAt;
    if (!force && last != null && _now().difference(last) < _minSyncGap) {
      return Future.value(true);
    }
    final f = _download().whenComplete(() => _inflight = null);
    _inflight = f;
    return f;
  }

  Future<bool> _download() async {
    _syncing = true;
    _notify();
    try {
      final res = await _transport('GET', _uri('decisions'), null).timeout(_timeout);
      if (res.status != 200) {
        lastError = 'HTTP ${res.status}';
        return false;
      }
      final body = jsonDecode(res.body);
      if (body is! Map || body['bans'] is! List) {
        lastError = 'Unexpected response';
        return false;
      }
      _bans = _indexBans(body['bans']);
      _syncedAt = _now();
      lastError = null;
      await _set(
        prefBans,
        jsonEncode([for (final b in _bans.values) b.toJson()]),
      );
      await _set(prefSynced, _syncedAt!.toUtc().toIso8601String());
      return true;
    } on Object catch (e) {
      lastError = e is TimeoutException ? 'Timed out' : 'Offline';
      return false;
    } finally {
      _syncing = false;
      _notify();
    }
  }

  /// Builds the reason moderators read: the category, then the user's note.
  static String reasonText(SentinelReason reason, String? note) {
    final n = note?.trim() ?? '';
    if (n.isEmpty) return reason.wire;
    final cut = n.length > maxNote ? n.substring(0, maxNote) : n;
    return '${reason.wire}: $cut';
  }

  /// Reports a node. Sends now if possible; otherwise queues it for later.
  Future<SentinelReportOutcome> report({
    required String nodeId,
    required SentinelReason reason,
    String? nodeName,
    String? note,
    String? messageExcerpt,
  }) async {
    if (!_enabled) {
      return const SentinelReportRejected('Community moderation is off');
    }
    final excerpt = messageExcerpt?.trim();
    final name = nodeName?.trim();
    final r = SentinelReport(
      nodeId: nodeId.trim(),
      nodeName: name == null || name.isEmpty
          ? null
          : (name.length > 64 ? name.substring(0, 64) : name),
      reason: reasonText(reason, note),
      messageExcerpt: excerpt == null || excerpt.isEmpty
          ? null
          : (excerpt.length > maxExcerpt
                ? excerpt.substring(0, maxExcerpt)
                : excerpt),
      externalRef: _newRef(),
      createdAt: _now(),
    );
    final outcome = await _send(r);
    if (outcome is SentinelReportQueued) await _enqueue(r);
    return outcome;
  }

  Future<SentinelReportOutcome> _send(SentinelReport r) async {
    try {
      final res = await _transport('POST', _uri('reports'), jsonEncode(r.toWire())).timeout(_timeout);
      if (res.status == 200 || res.status == 201) {
        final body = jsonDecode(res.body);
        final ref = body is Map ? body['caseRef'] : null;
        if (ref is String) {
          await _remember(ref, r.nodeName);
          return SentinelReportSent(ref);
        }
        return const SentinelReportQueued();
      }
      if (res.status == 400 ||
          res.status == 404 ||
          res.status == 413 ||
          res.status == 415) {
        String message = 'Rejected (HTTP ${res.status})';
        try {
          final body = jsonDecode(res.body);
          if (body is Map && body['error'] is String) {
            message = body['error'] as String;
          }
        } on FormatException {
          // keep the generic message
        }
        return SentinelReportRejected(message);
      }
      // 429, 5xx: try again later.
      return const SentinelReportQueued();
    } on Object {
      return const SentinelReportQueued();
    }
  }

  Future<void> _remember(String caseRef, String? nodeName) async {
    if (_sent.any((s) => s.caseRef == caseRef)) return;
    _sent = [
      (caseRef: caseRef, nodeName: nodeName, at: _now()),
      ..._sent,
    ].take(maxSentHistory).toList();
    await _set(
      prefSent,
      jsonEncode([
        for (final s in _sent)
          {
            'caseRef': s.caseRef,
            'nodeName': s.nodeName,
            'at': s.at.toUtc().toIso8601String(),
          },
      ]),
    );
    _notify();
  }

  Future<void> _enqueue(SentinelReport r) async {
    final next = [..._queue, r];
    _queue = next.length > maxQueue
        ? next.sublist(next.length - maxQueue)
        : next;
    await _saveQueue();
    _notify();
  }

  Future<void> _saveQueue() =>
      _set(prefQueue, jsonEncode([for (final r in _queue) r.toJson()]));

  /// Sends queued reports, oldest first. Stops at the first one that still
  /// can't go, so order is kept; drops ones the relay rejects outright.
  Future<int> flushQueue() async {
    if (!_enabled || _flushing || _queue.isEmpty) return 0;
    _flushing = true;
    var sent = 0;
    try {
      while (_queue.isNotEmpty && _enabled) {
        final outcome = await _send(_queue.first);
        if (outcome is SentinelReportQueued) break;
        _queue = _queue.sublist(1);
        await _saveQueue();
        if (outcome is SentinelReportSent) sent++;
      }
    } finally {
      _flushing = false;
      _notify();
    }
    return sent;
  }

  /// Appeals a ban on the user's own node.
  Future<SentinelAppealOutcome> appeal({
    required String caseRef,
    required String statement,
    String? contact,
  }) async {
    if (!_enabled) return SentinelAppealOutcome.failed;
    final c = contact?.trim();
    try {
      final res = await _transport(
        'POST',
        _uri('appeals'),
        jsonEncode({
          'caseRef': caseRef.trim().toUpperCase(),
          'statement': statement.trim(),
          if (c != null && c.isNotEmpty) 'contact': c,
        }),
      ).timeout(_timeout);
      switch (res.status) {
        case 200 || 201:
          unawaited(syncDecisions(force: true));
          return SentinelAppealOutcome.received;
        case 404:
          return SentinelAppealOutcome.unknownCase;
        case 409:
          return SentinelAppealOutcome.notAppealable;
        case 429:
          return SentinelAppealOutcome.tooMany;
        default:
          return SentinelAppealOutcome.failed;
      }
    } on Object {
      return SentinelAppealOutcome.failed;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
