import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bastion_traffic.dart';
import 'meshtastic_node_database.dart';

/// A summary of what the radio heard over a window, as on NOTORYX Core's
/// field stats.
@immutable
class FieldStats {
  const FieldStats({
    required this.packets,
    required this.senders,
    required this.direct,
    required this.byKind,
    required this.busiest,
    this.averageHops,
    this.bestSnr,
    this.worstSnr,
    this.viaMqtt = 0,
  });

  final int packets;

  /// Different nodes that sent something.
  final int senders;

  /// Senders heard with no relay in between.
  final int direct;
  final Map<TrafficKind, int> byKind;

  /// The nodes heard most, with their packet counts, most first.
  final List<(int, int)> busiest;
  final double? averageHops;
  final double? bestSnr;
  final double? worstSnr;
  final int viaMqtt;

  static FieldStats of(Iterable<TrafficPacket> heard, DateTime now, {Duration window = const Duration(hours: 1)}) {
    final from = now.subtract(window);
    final pts = [for (final p in heard) if (p.heard.isAfter(from)) p];
    final counts = <int, int>{};
    final direct = <int>{};
    final byKind = <TrafficKind, int>{};
    var hops = 0, withHops = 0, mqtt = 0;
    double? best, worst;
    for (final p in pts) {
      counts[p.from] = (counts[p.from] ?? 0) + 1;
      byKind[p.kind] = (byKind[p.kind] ?? 0) + 1;
      if (p.viaMqtt) mqtt++;
      if (p.hopsAway case final h?) {
        hops += h;
        withHops++;
        if (h == 0 && !p.viaMqtt) direct.add(p.from);
      }
      if (p.snr case final s? when !p.viaMqtt) {
        best = best == null || s > best ? s : best;
        worst = worst == null || s < worst ? s : worst;
      }
    }
    final busiest = [for (final e in counts.entries) (e.key, e.value)]..sort((a, b) => b.$2.compareTo(a.$2));
    return FieldStats(
      packets: pts.length,
      senders: counts.length,
      direct: direct.length,
      byKind: byKind,
      busiest: busiest.take(5).toList(),
      averageHops: withHops == 0 ? null : hops / withHops,
      bestSnr: best,
      worstSnr: worst,
      viaMqtt: mqtt,
    );
  }
}

/// What changed about a node.
enum NetworkChangeKind { appeared, quiet, back, renamed }

@immutable
class NetworkChange {
  const NetworkChange(this.kind, this.num, this.name, this.time, {this.oldName});
  final NetworkChangeKind kind;
  final int num;
  final String name;
  final DateTime time;
  final String? oldName;

  Map<String, Object> toJson() => {
        'k': kind.name,
        'n': num,
        'name': name,
        't': time.toUtc().millisecondsSinceEpoch,
        'old': ?oldName,
      };

  static NetworkChange? fromJson(Object? j) {
    if (j is! Map) return null;
    final kind = NetworkChangeKind.values.where((k) => k.name == j['k']).firstOrNull;
    final num = j['n'], name = j['name'], t = j['t'], old = j['old'];
    if (kind == null || num is! int || name is! String || t is! int) return null;
    return NetworkChange(kind, num, name, DateTime.fromMillisecondsSinceEpoch(t, isUtc: true).toLocal(),
        oldName: old is String ? old : null);
  }
}

/// Watches the mesh for the packet log, field stats and network changes.
/// Everything stays on this phone; nothing is sent.
class BastionMeshWatch extends ChangeNotifier {
  BastionMeshWatch({SharedPreferencesAsync? prefs, DateTime Function()? clock})
      : _prefs = prefs,
        _clock = clock ?? DateTime.now;

  static BastionMeshWatch instance = BastionMeshWatch();

  /// Packets kept for the live log.
  static const keepPackets = 500;

  /// Changes kept on the phone.
  static const keepChanges = 200;

  /// A node not heard for this long, after being heard, has gone quiet.
  static const quietAfter = Duration(hours: 2);

  static const prefsKey = 'bastion.network_changes.v1';

  final SharedPreferencesAsync? _prefs;
  final DateTime Function() _clock;
  final List<TrafficPacket> _packets = [];
  final List<NetworkChange> _changes = [];
  StreamSubscription<TrafficPacket>? _sub;

  /// What each node looked like at the last check; null until the first
  /// node list after connecting, which only sets the baseline.
  Map<int, ({String? name, DateTime? heard})>? _known;
  final Set<int> _quiet = {};

  SharedPreferencesAsync get _store => _prefs ?? SharedPreferencesAsync();

  /// Newest first.
  List<TrafficPacket> get packets => List.unmodifiable(_packets.reversed);

  /// Newest first.
  List<NetworkChange> get changes => List.unmodifiable(_changes.reversed);

  FieldStats stats({Duration window = const Duration(hours: 1)}) => FieldStats.of(_packets, _clock(), window: window);

  Future<void> load() async {
    _changes.clear();
    try {
      final raw = await _store.getString(prefsKey);
      if (raw != null) {
        for (final c in jsonDecode(raw) as List) {
          if (NetworkChange.fromJson(c) case final change?) _changes.add(change);
        }
      }
    } catch (e) {
      debugPrint('Network changes unreadable, starting fresh: $e');
    }
    notifyListeners();
  }

  /// Follows [traffic]'s packets until [detach].
  void attach(BastionTrafficLog traffic) {
    unawaited(_sub?.cancel());
    _sub = traffic.packets.listen(addPacket);
  }

  void detach() {
    unawaited(_sub?.cancel());
    _sub = null;
  }

  void addPacket(TrafficPacket p) {
    _packets.add(p);
    if (_packets.length > keepPackets) _packets.removeRange(0, _packets.length - keepPackets);
    notifyListeners();
  }

  /// Starts afresh after a (re)connect: the next node list is the baseline.
  void resetBaseline() {
    _known = null;
    _quiet.clear();
  }

  /// Compares [nodes] with the last check and records what changed.
  /// [self] is this radio, which is never reported.
  void checkNodes(List<MeshtasticNode> nodes, {int? self}) {
    final now = _clock();
    final known = _known;
    final next = <int, ({String? name, DateTime? heard})>{
      for (final n in nodes)
        if (n.num != self) n.num: (name: n.longName, heard: n.lastHeard),
    };
    if (known == null) {
      _known = next;
      // Nodes already quiet when we connect aren't news.
      _quiet
        ..clear()
        ..addAll([
          for (final e in next.entries)
            if (e.value.heard == null || now.difference(e.value.heard!) >= quietAfter) e.key,
        ]);
      return;
    }
    final found = <NetworkChange>[];
    for (final n in nodes) {
      if (n.num == self) continue;
      final before = known[n.num];
      final heard = n.lastHeard;
      if (before == null) {
        found.add(NetworkChange(NetworkChangeKind.appeared, n.num, n.displayName, now));
        continue;
      }
      if (before.name != null && n.longName != null && before.name != n.longName) {
        found.add(NetworkChange(NetworkChangeKind.renamed, n.num, n.displayName, now, oldName: before.name));
      }
      final fresh = heard != null && now.difference(heard) < quietAfter;
      if (_quiet.contains(n.num) && fresh && heard != before.heard) {
        _quiet.remove(n.num);
        found.add(NetworkChange(NetworkChangeKind.back, n.num, n.displayName, now));
      } else if (!_quiet.contains(n.num) && heard != null && !fresh) {
        _quiet.add(n.num);
        found.add(NetworkChange(NetworkChangeKind.quiet, n.num, n.displayName, now));
      }
    }
    _known = next;
    if (found.isEmpty) return;
    _changes.addAll(found);
    if (_changes.length > keepChanges) _changes.removeRange(0, _changes.length - keepChanges);
    notifyListeners();
    unawaited(_save());
  }

  Future<void> _save() async {
    try {
      await _store.setString(prefsKey, jsonEncode([for (final c in _changes) c.toJson()]));
    } catch (e) {
      debugPrint('Could not save network changes: $e');
    }
  }

  Future<void> clearChanges() async {
    _changes.clear();
    notifyListeners();
    await _save();
  }
}

/// Feeds [BastionMeshWatch] from the real radio: its packets, and its node
/// list at most every [every] plus on a timer so quiet nodes are noticed.
class MeshWatchFeed {
  MeshWatchFeed({required this.watch, required this.nodes, required this.self, required this.ready});

  final BastionMeshWatch watch;
  final List<MeshtasticNode> Function() nodes;
  final int? Function() self;
  final bool Function() ready;

  static const every = Duration(seconds: 10);
  DateTime? _last;
  bool _wasReady = false;
  Timer? _timer;

  void start() {
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => check(force: true));
  }

  /// Call when the radio changes.
  void check({bool force = false}) {
    final isReady = ready();
    if (!isReady) {
      if (_wasReady) watch.resetBaseline();
      _wasReady = false;
      return;
    }
    _wasReady = true;
    final now = DateTime.now();
    if (!force && _last != null && now.difference(_last!) < every) return;
    _last = now;
    watch.checkNodes(nodes(), self: self());
  }

  void dispose() => _timer?.cancel();
}
