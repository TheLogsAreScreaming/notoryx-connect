import 'meshtastic_node_database.dart';

/// The node list split by when each node was last heard.
class BastionNodeGroups {
  const BastionNodeGroups({required this.active, required this.today, required this.older});

  /// Heard within [activeWindow].
  final List<MeshtasticNode> active;

  /// Heard within a day, but not in the last [activeWindow].
  final List<MeshtasticNode> today;

  /// Heard longer ago, or never.
  final List<MeshtasticNode> older;

  static const activeWindow = Duration(hours: 1);
  static const todayWindow = Duration(hours: 24);

  int get total => active.length + today.length + older.length;

  /// Groups [nodes], leaving out [localNum] (your own radio has its own bar),
  /// keeping only names, short names or IDs that contain [query], and only
  /// [favorites] when [favoritesOnly]. Each group is newest first.
  static BastionNodeGroups of(
    Iterable<MeshtasticNode> nodes, {
    required DateTime now,
    int? localNum,
    String query = '',
    bool favoritesOnly = false,
    Set<int> favorites = const {},
  }) {
    final q = query.trim().toLowerCase();
    final active = <MeshtasticNode>[];
    final today = <MeshtasticNode>[];
    final older = <MeshtasticNode>[];
    for (final n in nodes) {
      if (n.num == localNum) continue;
      if (favoritesOnly && !favorites.contains(n.num)) continue;
      if (q.isNotEmpty && !matches(n, q)) continue;
      final heard = n.lastHeard;
      final age = heard == null ? null : now.difference(heard);
      if (age != null && age <= activeWindow) {
        active.add(n);
      } else if (age != null && age <= todayWindow) {
        today.add(n);
      } else {
        older.add(n);
      }
    }
    int newestFirst(MeshtasticNode a, MeshtasticNode b) {
      final x = a.lastHeard, y = b.lastHeard;
      if (x == null && y == null) return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    }

    return BastionNodeGroups(
      active: active..sort(newestFirst),
      today: today..sort(newestFirst),
      older: older..sort(newestFirst),
    );
  }

  /// Whether [n]'s name, short name or ID contains [lowerQuery].
  static bool matches(MeshtasticNode n, String lowerQuery) => [
    n.displayName,
    n.shortName ?? '',
    n.id ?? '',
    n.num.toRadixString(16).padLeft(8, '0'),
  ].any((s) => s.toLowerCase().contains(lowerQuery));

  /// Signal bars, 0 to 3, from the last signal-to-noise ratio in dB;
  /// null when the node hasn't been heard directly.
  static int? bars(double? snr) => switch (snr) {
    null => null,
    >= 5 => 3,
    >= -5 => 2,
    >= -12 => 1,
    _ => 0,
  };
}
