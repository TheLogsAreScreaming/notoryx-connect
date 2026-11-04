import 'bastion_geo.dart';
import 'bastion_units.dart';
import 'meshtastic_node_database.dart';

/// How recently a trip contact was heard.
enum TeamFreshness { fresh, stale, lost, unknown }

/// What the team list shows for one trip contact.
class TeamMemberStatus {
  const TeamMemberStatus({
    required this.num,
    required this.name,
    required this.freshness,
    this.heardAgo,
    this.positionAgo,
    this.distanceMeters,
    this.bearing,
    this.battery,
    this.hasPosition = false,
  });

  /// Heard within this long: fresh. Within [lostAfter]: stale. Older: lost.
  static const freshFor = Duration(minutes: 15);
  static const lostAfter = Duration(hours: 1);

  final int num;
  final String name;
  final TeamFreshness freshness;
  final Duration? heardAgo;
  final Duration? positionAgo;
  final double? distanceMeters;
  final double? bearing;
  final int? battery;
  final bool hasPosition;

  /// Builds the status of contact [num]. [me] is this radio's node, used for
  /// distance and bearing; [battery] overrides the node's reported level
  /// with fresher telemetry when known.
  static TeamMemberStatus of(int num, MeshtasticNode? node,
      {MeshtasticNode? me, int? battery, required DateTime now}) {
    Duration? since(DateTime? t) {
      if (t == null) return null;
      final d = now.difference(t);
      return d.isNegative ? Duration.zero : d;
    }
    final heard = since(node?.lastHeard);
    final freshness = heard == null
        ? TeamFreshness.unknown
        : heard <= freshFor
            ? TeamFreshness.fresh
            : heard <= lostAfter
                ? TeamFreshness.stale
                : TeamFreshness.lost;
    double? distance, bearing;
    if (node != null && node.hasPosition && me != null && me.hasPosition) {
      distance = BastionGeo.distanceMeters(me.latitude!, me.longitude!, node.latitude!, node.longitude!);
      bearing = BastionGeo.bearingDegrees(me.latitude!, me.longitude!, node.latitude!, node.longitude!);
    }
    final level = battery ?? node?.batteryLevel;
    return TeamMemberStatus(
      num: num,
      name: node?.displayName ?? '!${num.toRadixString(16).padLeft(8, '0')}',
      freshness: freshness,
      heardAgo: heard,
      positionAgo: node?.hasPosition ?? false ? since(node!.positionTime ?? node.lastHeard) : null,
      distanceMeters: distance,
      bearing: bearing,
      battery: level != null && level >= 0 && level <= 100 ? level : null,
      hasPosition: node?.hasPosition ?? false,
    );
  }

  /// "just now", "4 min", "2 h", "3 d".
  static String ageLabel(Duration d) => d.inMinutes < 1
      ? 'just now'
      : d.inHours < 1
          ? '${d.inMinutes} min'
          : d.inDays < 1
              ? '${d.inHours} h'
              : '${d.inDays} d';

  /// "850 m" / "2.4 km", or feet and miles in [units].
  static String distanceLabel(double meters, [BastionUnits units = BastionUnits.metric]) =>
      BastionUnitFormat.distance(meters, units);

  /// One plain-language line for the team list and screen readers.
  String summaryIn(BastionUnits units) => [
        heardAgo == null ? 'Not heard yet' : 'Heard ${heardAgo!.inMinutes < 1 ? 'just now' : '${ageLabel(heardAgo!)} ago'}',
        if (!hasPosition) 'no position' else if (positionAgo != null) 'position ${ageLabel(positionAgo!)} old',
        if (distanceMeters != null) '${distanceLabel(distanceMeters!, units)} ${BastionGeo.compassPoint(bearing!)}',
        if (battery != null) 'battery $battery%',
      ].join(' • ');
}
