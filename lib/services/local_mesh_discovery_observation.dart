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
