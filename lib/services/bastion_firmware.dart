import '../l10n/bastion_text.dart';

/// How well the connected radio's firmware suits this app.
enum FirmwareSupport {
  /// Recent enough for everything the app does.
  supported,

  /// Works, but some features (newer telemetry, key checks) may be missing.
  outdated,

  /// Too old: messages may still work, but changing radio settings is
  /// turned off because older firmware reads settings differently.
  unsupported,

  /// The radio has not reported its version yet.
  unknown,
}

/// Firmware version checks. Version strings look like "2.7.15.567b8ea".
abstract final class BastionFirmware {
  /// Below this, radio settings are not changed from the app. 2.5 added the
  /// public-key direct messages and settings layout this app expects.
  static const minimum = (2, 5, 0);

  /// Below this, the app shows an update suggestion.
  static const recommended = (2, 7, 0);

  /// Where people can update their radio.
  static const flasher = 'flasher.meshtastic.org';

  /// Major, minor and patch numbers, or null when unreadable.
  static (int, int, int)? parse(String? version) {
    final m = RegExp(r'^v?(\d+)\.(\d+)(?:\.(\d+))?').firstMatch(version?.trim() ?? '');
    if (m == null) return null;
    return (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3] ?? '0'));
  }

  static bool _atLeast((int, int, int) v, (int, int, int) min) =>
      v.$1 != min.$1 ? v.$1 > min.$1 : v.$2 != min.$2 ? v.$2 > min.$2 : v.$3 >= min.$3;

  static FirmwareSupport supportOf(String? version) {
    final v = parse(version);
    if (v == null) return FirmwareSupport.unknown;
    if (!_atLeast(v, minimum)) return FirmwareSupport.unsupported;
    if (!_atLeast(v, recommended)) return FirmwareSupport.outdated;
    return FirmwareSupport.supported;
  }

  static String _label((int, int, int) v) => '${v.$1}.${v.$2}';

  /// What to tell the person about [version], or null when nothing is needed.
  static String? advice(String? version) {
    final shown = parse(version) == null ? version : version!.split('.').take(3).join('.');
    return switch (supportOf(version)) {
      FirmwareSupport.unsupported =>
        BastionText.l.svcFirmwareUnsupported('$shown', _label(minimum), '$flasher'),
      FirmwareSupport.outdated =>
        BastionText.l.svcFirmwareOutdated('$shown', _label(recommended), '$flasher'),
      FirmwareSupport.supported || FirmwareSupport.unknown => null,
    };
  }
}
