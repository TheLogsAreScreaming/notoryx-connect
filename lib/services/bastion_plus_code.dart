/// Open Location Code ("Plus Code") encoding.
///
/// A 10-digit code pins a spot to about 14 m in 11 bytes; decimal coordinates
/// at similar precision take about 19, which matters on a 60-byte beacon.
abstract final class BastionPlusCode {
  static const _alphabet = '23456789CFGHJMPQRVWX';
  static const _cellsPerDegree = 8000;
  static const _pairs = 5;

  static String encode(double latitude, double longitude) {
    var lat = ((latitude.clamp(-90.0, 90.0) + 90) * _cellsPerDegree).floor();
    // The top edge belongs to the last cell, since no cell starts at 90.
    lat = lat.clamp(0, 180 * _cellsPerDegree - 1);
    var lon = (((longitude + 180) % 360) * _cellsPerDegree).floor();
    final digits = List<String>.filled(_pairs * 2, '');
    for (var i = _pairs - 1; i >= 0; i--) {
      digits[i * 2] = _alphabet[lat % 20];
      digits[i * 2 + 1] = _alphabet[lon % 20];
      lat ~/= 20;
      lon ~/= 20;
    }
    return '${digits.sublist(0, 8).join()}+${digits.sublist(8).join()}';
  }
}
