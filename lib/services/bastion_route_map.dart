import 'meshtastic_traceroute.dart';

/// A traceroute laid out for the map: the points to draw each way, and
/// which nodes along it have no known position.
class RouteMapPath {
  const RouteMapPath({required this.towards, required this.back, required this.unplaced});

  /// Node numbers from this radio to the destination that have a position,
  /// in order. Relays without a position are skipped.
  final List<int> towards;

  /// The same for the return path, from the destination back to this radio.
  final List<int> back;

  /// Nodes on either path that could not be placed on the map.
  final Set<int> unplaced;

  /// Whether at least one leg can be drawn.
  bool get drawable => towards.length >= 2 || back.length >= 2;

  /// Builds the path for [result], where [hasPosition] says whether a node
  /// can be placed on the map.
  static RouteMapPath of(TracerouteResult result, {
    required int local,
    required int destination,
    required bool Function(int node) hasPosition,
  }) {
    final unplaced = <int>{};
    List<int> placed(List<int> nodes) {
      final out = <int>[];
      for (final n in nodes) {
        if (!hasPosition(n)) {
          unplaced.add(n);
        } else if (out.isEmpty || out.last != n) {
          out.add(n);
        }
      }
      return out;
    }

    final there = [local, for (final h in result.towards) h.nodeNum];
    if (there.last != destination) there.add(destination);
    final backNodes = result.back.isEmpty
        ? <int>[]
        : [destination, for (final h in result.back) h.nodeNum];
    if (backNodes.isNotEmpty && backNodes.last != local) backNodes.add(local);
    return RouteMapPath(towards: placed(there), back: placed(backNodes), unplaced: unplaced);
  }
}
