import 'dart:convert';

import 'bastion_firmware.dart';

/// Validates user-entered Meshtastic node names before a radio write.
abstract final class BastionNodeIdentityValidation {
  /// Long-name bytes firmware below 2.8.0 keeps (User.long_name holds 39).
  static const legacyLongNameBytes = 39;

  /// Long-name bytes firmware 2.8.0 and newer keeps. It cuts anything longer
  /// when it stores or sends the name, without saying so.
  static const longNameBytes28 = 24;

  /// Short-name bytes every firmware keeps.
  static const shortNameBytes = 4;

  /// The long-name limit, in UTF-8 bytes, for a radio on [firmwareVersion].
  ///
  /// Unknown or unreadable versions get the older 39-byte limit, so a name
  /// that fits is never refused because the radio has not reported yet.
  static int maxLongNameBytes(String? firmwareVersion) {
    final v = BastionFirmware.parse(firmwareVersion);
    if (v == null) return legacyLongNameBytes;
    final atLeast28 = v.$1 > 2 || (v.$1 == 2 && v.$2 >= 8);
    return atLeast28 ? longNameBytes28 : legacyLongNameBytes;
  }

  /// Why [value] can't be the long name of a radio on [firmwareVersion], or
  /// null when it can.
  static String? longNameError(String value, {String? firmwareVersion}) {
    final name = value.trim();
    if (name.isEmpty) return 'Long name cannot be empty';
    if (name.contains('\n') || name.contains('\r'))
      return 'Long name must be one line';
    final max = maxLongNameBytes(firmwareVersion);
    if (utf8.encode(name).length > max) {
      return max == longNameBytes28
          ? 'Long name must be at most $max bytes on firmware 2.8 and newer '
                '(emoji and accented letters use more than one)'
          : 'Long name must be at most $max bytes';
    }
    return null;
  }

  static String? shortNameError(String value) {
    final name = value.trim();
    if (name.isEmpty) return 'Short name cannot be empty';
    if (name.runes.length > 4) return 'Short name must be at most 4 characters';
    if (name.contains('\n') || name.contains('\r'))
      return 'Short name must be one line';
    return null;
  }
}
