/// Read-only record of a previously heard node. Never changes radio settings.
class DiscoveryObservation {
  const DiscoveryObservation({required this.nodeNumber, required this.lastHeard, this.name, this.snr, this.rssi});
  final int nodeNumber;
  final DateTime lastHeard;
  final String? name;
  final double? snr;
  final int? rssi;
}

/// Deduplicate by node ID and retain the most recent reception.
List<DiscoveryObservation> latestDiscoveryObservations(Iterable<DiscoveryObservation> observations) {
  final byNode = <int, DiscoveryObservation>{};
  for (final observation in observations) {
    final old = byNode[observation.nodeNumber];
    if (old == null || observation.lastHeard.isAfter(old.lastHeard)) {
      byNode[observation.nodeNumber] = observation;
    }
  }
  return List.unmodifiable(byNode.values.toList()..sort((a, b) {
    final time = b.lastHeard.compareTo(a.lastHeard);
    return time != 0 ? time : a.nodeNumber.compareTo(b.nodeNumber);
  }));
}

/// Filter observations to a non-negative recent time window.
/// Future timestamps are excluded rather than shown as recently heard.
List<DiscoveryObservation> recentDiscoveryObservations(
  Iterable<DiscoveryObservation> observations, {
  required DateTime now,
  required Duration maxAge,
}) {
  if (maxAge.isNegative) {
    throw ArgumentError.value(maxAge, 'maxAge', 'Must not be negative');
  }
  final earliest = now.subtract(maxAge);
  return latestDiscoveryObservations(observations.where((observation) =>
      !observation.lastHeard.isBefore(earliest) &&
      !observation.lastHeard.isAfter(now)));
}
