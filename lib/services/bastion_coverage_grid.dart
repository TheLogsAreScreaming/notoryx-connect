import 'bastion_drive_log.dart';

/// How well a place heard the mesh, for the heatmap.
enum CoverageBand { strong, fair, weak }

/// Square sizes the heatmap can use.
enum CoverageSquare {
  m100(100),
  m300(300);

  const CoverageSquare(this.meters);
  final double meters;
}

/// One square of the heatmap.
class CoverageCell {
  const CoverageCell({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.readings,
    required this.meanSnr,
    this.latest,
  });
  final double south;
  final double west;
  final double north;
  final double east;
  final int readings;
  final double meanSnr;

  /// When the newest reading in this square was taken; null if unknown.
  final DateTime? latest;

  double get centreLatitude => (south + north) / 2;
  double get centreLongitude => (west + east) / 2;

  CoverageBand get band => meanSnr >= BastionCoverageGrid.strongSnr
      ? CoverageBand.strong
      : meanSnr >= BastionCoverageGrid.fairSnr
          ? CoverageBand.fair
          : CoverageBand.weak;

  /// 0 to 1: how many readings back this square up.
  double get density => (readings / BastionCoverageGrid.fullDensity).clamp(0.0, 1.0);
}

/// Groups drive samples into squares of a fixed size in metres.
abstract final class BastionCoverageGrid {
  static const strongSnr = 0.0;
  static const fairSnr = -10.0;
  static const fullDensity = 10;

  /// Classes counted by default. A relayed packet proves coverage only to
  /// the relayer, so it is left out unless asked for. Readings from before
  /// hop counts were saved are kept.
  static const defaultClasses = {HopClass.direct, HopClass.unknown};

  /// Builds squares from [samples], counting only [classes] and, when
  /// [trips] is given, only those trips. Readings without an SNR are left
  /// out.
  static List<CoverageCell> build(
    Iterable<DriveSample> samples, {
    CoverageSquare size = CoverageSquare.m300,
    Set<HopClass> classes = defaultClasses,
    Set<int>? trips,
  }) {
    final sums = <(int, int), (int, double)>{};
    final newest = <(int, int), DateTime>{};
    for (final s in samples) {
      final snr = s.snr;
      if (snr == null || !snr.isFinite || !classes.contains(s.hops)) continue;
      if (trips != null && !trips.contains(s.trip)) continue;
      final key = BastionDriveLog.squareOf(s.latitude, s.longitude, size.meters);
      final (count, total) = sums[key] ?? (0, 0.0);
      sums[key] = (count + 1, total + snr);
      final seen = newest[key];
      if (seen == null || s.time.isAfter(seen)) newest[key] = s.time;
    }
    return [
      for (final e in sums.entries)
        () {
          final b = BastionDriveLog.squareBounds(e.key.$1, e.key.$2, size.meters);
          return CoverageCell(
            south: b.south,
            north: b.north,
            west: b.west,
            east: b.east,
            readings: e.value.$1,
            meanSnr: e.value.$2 / e.value.$1,
            latest: newest[e.key],
          );
        }(),
    ];
  }
}
