import '../generated/meshtastic/config.pbenum.dart';

/// The LoRa region a radio most likely needs in a country, from the phone's
/// locale. Only a suggestion: the person always confirms it, and countries
/// with more than one legal plan or none known here get null.
abstract final class BastionRegionSuggest {
  static const _eu868 = {
    'AT',
    'BE',
    'BG',
    'CH',
    'CY',
    'CZ',
    'DE',
    'DK',
    'EE',
    'ES',
    'FI',
    'FR',
    'GB',
    'GR',
    'HR',
    'HU',
    'IE',
    'IS',
    'IT',
    'LI',
    'LT',
    'LU',
    'LV',
    'MT',
    'NL',
    'NO',
    'PL',
    'PT',
    'RO',
    'SE',
    'SI',
    'SK',
  };

  static Config_LoRaConfig_RegionCode? forCountry(String? countryCode) {
    final c = countryCode?.toUpperCase();
    if (c == null || c.isEmpty) return null;
    if (_eu868.contains(c)) return Config_LoRaConfig_RegionCode.EU_868;
    return switch (c) {
      'US' || 'CA' || 'MX' || 'PR' => Config_LoRaConfig_RegionCode.US,
      'AU' => Config_LoRaConfig_RegionCode.ANZ,
      'NZ' => Config_LoRaConfig_RegionCode.ANZ,
      'BR' => Config_LoRaConfig_RegionCode.BR_902,
      'JP' => Config_LoRaConfig_RegionCode.JP,
      'KR' => Config_LoRaConfig_RegionCode.KR,
      'TW' => Config_LoRaConfig_RegionCode.TW,
      'CN' => Config_LoRaConfig_RegionCode.CN,
      'IN' => Config_LoRaConfig_RegionCode.IN,
      'RU' => Config_LoRaConfig_RegionCode.RU,
      'UA' => Config_LoRaConfig_RegionCode.UA_868,
      'TH' => Config_LoRaConfig_RegionCode.TH,
      'MY' => Config_LoRaConfig_RegionCode.MY_919,
      'SG' => Config_LoRaConfig_RegionCode.SG_923,
      'PH' => Config_LoRaConfig_RegionCode.PH_915,
      'KZ' => Config_LoRaConfig_RegionCode.KZ_863,
      'NP' => Config_LoRaConfig_RegionCode.NP_865,
      _ => null,
    };
  }
}
