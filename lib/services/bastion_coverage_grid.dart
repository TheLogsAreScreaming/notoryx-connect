/// How well a place heard the mesh, for the heatmap.
enum CoverageBand { strong, fair, weak }

/// One square of the heatmap.
class CoverageCell {
  const CoverageCell({required this.south, required this.west, required this.readings, required this.meanSnr});
  final double south;
  final double west;
  final int readings;
  final double meanSnr;

  CoverageBand get band => meanSnr >= BastionCoverageGrid.strongSnr
      ? CoverageBand.strong
      : meanSnr >= BastionCoverageGrid.fairSnr
          ? CoverageBand.fair
          : CoverageBand.weak;

  /// 0 to 1: how many readings back this square up.
  double get density => (readings / BastionCoverageGrid.fullDensity).clamp(0.0, 1.0);
}

/// Groups coverage log readings into squares of about 220 m.
abstract final class BastionCoverageGrid {
  static const cellDegrees = 0.002;
  static const strongSnr = 0.0;
  static const fairSnr = -10.0;
  static const fullDensity = 10;

  /// Builds cells from coverage records for [radio]. Readings without an SNR
  /// or a usable position are left out.
  static List<CoverageCell> build(Iterable<Map<String, Object?>> records, {int? radio}) {
    final sums = <(int, int), (int, double)>{};
    for (final r in records) {
      if (r['kind'] != 'coverage' || (radio != null && r['radio'] != radio)) continue;
      final (lat, lon, snr) = (r['lat'], r['lon'], r['snr']);
      if (lat is! num || lon is! num || snr is! num || !snr.isFinite) continue;
      final key = ((lat / cellDegrees).floor(), (lon / cellDegrees).floor());
      final (count, total) = sums[key] ?? (0, 0.0);
      sums[key] = (count + 1, total + snr);
    }
    return [
      for (final e in sums.entries)
        CoverageCell(
          south: e.key.$1 * cellDegrees,
          west: e.key.$2 * cellDegrees,
          readings: e.value.$1,
          meanSnr: e.value.$2 / e.value.$1,
        ),
    ];
  }
}
