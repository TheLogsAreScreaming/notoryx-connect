import '../generated/meshtastic/mesh.pbenum.dart';

/// Names for the `HardwareModel` a node reports in its user info.
class BastionHardware {
  /// Names that read better than the enum, e.g. TRACKER_T1000_E.
  static const _names = {
    'TBEAM': 'LilyGO T-Beam',
    'T_ECHO': 'LilyGO T-Echo',
    'T_ECHO_PLUS': 'LilyGO T-Echo Plus',
    'T_DECK': 'LilyGO T-Deck',
    'T_DECK_PRO': 'LilyGO T-Deck Pro',
    'T_LORA_PAGER': 'LilyGO T-LoRa Pager',
    'LILYGO_TBEAM_S3_CORE': 'LilyGO T-Beam Supreme',
    'TBEAM_1_WATT': 'LilyGO T-Beam 1W',
    'TRACKER_T1000_E': 'Seeed T1000-E',
    'SEEED_WIO_TRACKER_L1': 'Seeed Wio Tracker L1',
    'SEEED_WIO_TRACKER_L1_EINK': 'Seeed Wio Tracker L1 E-Ink',
    'WIO_WM1110': 'Seeed Wio-WM1110',
    'SEEED_XIAO_S3': 'Seeed XIAO ESP32-S3',
    'MESHPAGER_X2': 'Seeed MeshPager X2',
    'NODARA': 'Radioddity Nodara',
    'HELTEC_V3': 'Heltec V3',
    'HELTEC_V4': 'Heltec V4',
    'HELTEC_WSL_V3': 'Heltec Wireless Stick Lite V3',
    'HELTEC_WIRELESS_TRACKER': 'Heltec Wireless Tracker',
    'HELTEC_WIRELESS_TRACKER_V2': 'Heltec Wireless Tracker V2',
    'HELTEC_MESH_POCKET': 'Heltec MeshPocket',
    'HELTEC_MESH_POCKET_V2': 'Heltec MeshPocket V2',
    'RAK4631': 'RAK WisBlock 4631',
    'WISMESH_TAP': 'RAK WisMesh Tap',
    'WISMESH_TAG': 'RAK WisMesh Tag',
    'THINKNODE_M1': 'Elecrow ThinkNode M1',
    'STATION_G2': 'Station G2',
    'PRIVATE_HW': 'Custom hardware',
    'UNSET': 'Unknown hardware',
  };

  /// Boards whose maker wires the GPS, marked `oem_fixed_gps` in
  /// meshtastic/protobufs 2.8.2. Their GPS pin settings do nothing.
  static const fixedGps = {
    4, 7, 12, 21, 29, 33, 48, 71, 89, 99, 100, 102, 103, 105, 113, 122, 124,
    128,
  };

  /// Whether [model]'s GPS pins are set by the board maker; false when
  /// the board is unknown, so DIY builds keep their pin settings.
  static bool hasFixedGps(int? model) =>
      model != null && fixedGps.contains(model);

  /// Position settings for DIY GPS wiring (`diy_only` in config.proto):
  /// rx_gpio, tx_gpio and gps_en_gpio.
  static const diyGpsFields = {8, 9, 12};

  /// A readable name for [model], or "Model n" for a number newer than the
  /// app's definitions.
  static String name(int model) {
    final value = HardwareModel.valueOf(model);
    if (value == null) return 'Model $model';
    return _names[value.name] ??
        value.name
            .split('_')
            .map((w) => w.isEmpty ? w : w[0] + w.substring(1).toLowerCase())
            .join(' ');
  }
}
