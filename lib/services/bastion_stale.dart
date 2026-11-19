/// How long a node may go unheard before Nodes and Map mark it stale.
///
/// This only changes how a node is shown; it never hides one (that is
/// [BastionHeardWithin]'s job) and never touches the radio.
enum BastionStaleAfter {
  off(null),
  hour(Duration(hours: 1)),
  sixHours(Duration(hours: 6)),
  day(Duration(hours: 24)),
  threeDays(Duration(days: 3)),
  week(Duration(days: 7));

  const BastionStaleAfter(this.after);

  /// The threshold, or null when nodes are never marked stale.
  final Duration? after;

  /// The choice used until the person picks one.
  static const standard = day;

  /// The saved choice named [name], or [standard] when unknown.
  static BastionStaleAfter fromName(String? name) =>
      values.where((v) => v.name == name).firstOrNull ?? standard;

  /// Whether a node last heard at [lastHeard] is stale at [now].
  bool marks(DateTime? lastHeard, DateTime now) =>
      isStale(lastHeard, now, after);
}

/// Whether a node last heard at [lastHeard] has been quiet for longer than
/// [after] at [now].
///
/// A node with no last-heard time is never stale (there is no age to show),
/// and a null [after] turns marking off.
bool isStale(DateTime? lastHeard, DateTime now, Duration? after) {
  if (lastHeard == null || after == null) return false;
  return now.difference(lastHeard) > after;
}
