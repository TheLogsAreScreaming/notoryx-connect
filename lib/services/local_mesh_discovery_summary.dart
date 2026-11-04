import 'local_mesh_discovery_observation.dart';

/// Summary of already observed nodes; never communicates with the radio.
class LocalMeshDiscoverySummary {
  const LocalMeshDiscoverySummary({required this.totalNodes, required this.withSignal, required this.withName});

  final int totalNodes;
  final int withSignal;
  final int withName;

  factory LocalMeshDiscoverySummary.fromObservations(Iterable<DiscoveryObservation> observations) {
    final nodes = latestDiscoveryObservations(observations);
    return LocalMeshDiscoverySummary(
      totalNodes: nodes.length,
      withSignal: nodes.where((n) => n.rssi != null || n.snr != null).length,
      withName: nodes.where((n) => n.name?.trim().isNotEmpty == true).length,
    );
  }
}
