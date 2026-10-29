/// Distance and altitude units shown in the app. Stored data and exports
/// stay in meters; only what people read changes.
enum BastionUnits { metric, imperial }

abstract final class BastionUnitFormat {
  static const _feetPerMeter = 3.28084;
  static const _metersPerMile = 1609.344;

  /// Countries that use miles and feet day to day.
  static const imperialCountries = {'US', 'LR', 'MM'};

  /// The default for a phone set to [countryCode] (e.g. "US").
  static BastionUnits defaultFor(String? countryCode) =>
      imperialCountries.contains(countryCode?.toUpperCase()) ? BastionUnits.imperial : BastionUnits.metric;

  /// "850 m" / "2.4 km", or "420 ft" / "1.5 mi" / "12 mi".
  static String distance(double meters, BastionUnits units) {
    if (units == BastionUnits.metric) {
      if (meters < 1000) return '${meters.round()} m';
      final km = meters / 1000;
      return km < 100 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
    }
    final miles = meters / _metersPerMile;
    if (miles < 0.1) return '${(meters * _feetPerMeter).round()} ft';
    return miles < 100 ? '${miles.toStringAsFixed(1)} mi' : '${miles.round()} mi';
  }

  /// "1240 m" or "4068 ft".
  static String altitude(num meters, BastionUnits units) => units == BastionUnits.metric
      ? '${meters.round()} m'
      : '${(meters * _feetPerMeter).round()} ft';
}
