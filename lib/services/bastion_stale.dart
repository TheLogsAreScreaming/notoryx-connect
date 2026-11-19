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

/// Times before this come from radios whose clock was never set (they count
/// from 1970), so they are not real last-heard times.
final earliestHeardTime = DateTime.utc(2020);

/// How far ahead of the phone a last-heard time may be before it is treated
/// as a wrong radio clock rather than ordinary clock drift.
const futureHeardSlack = Duration(days: 1);

/// [lastHeard] when it is a believable time at [now], else null: null, the
/// epoch, anything before 2020, or more than a day in the future count as
/// unknown, so no age is shown for them.
DateTime? knownHeardTime(DateTime? lastHeard, DateTime now) {
  if (lastHeard == null) return null;
  if (lastHeard.isBefore(earliestHeardTime)) return null;
  if (lastHeard.isAfter(now.add(futureHeardSlack))) return null;
  return lastHeard;
}

/// Whether a node last heard at [lastHeard] has been quiet for longer than
/// [after] at [now].
///
/// A node with no believable last-heard time (see [knownHeardTime]) is never
/// stale, as there is no age to show, and a null [after] turns marking off.
bool isStale(DateTime? lastHeard, DateTime now, Duration? after) {
  final heard = knownHeardTime(lastHeard, now);
  if (heard == null || after == null) return false;
  return now.difference(heard) > after;
}
