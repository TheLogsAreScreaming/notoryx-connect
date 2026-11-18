import 'dart:typed_data';

import 'package:protobuf/protobuf.dart';

import '../generated/meshtastic/mesh.pb.dart';

/// What a firmware notice is about, which sets how loudly it is shown.
enum RadioNoticeKind {
  /// The radio's own key may be compromised, or was replaced.
  keySecurity,

  /// The radio refused an unsigned change to a known node's identity.
  identityRefused,

  /// A send was stopped by the airtime (duty cycle) limit.
  airtime,

  /// Anything else the firmware wants the person to see.
  general,
}

/// A notice the radio sent the app (FromRadio.clientNotification).
///
/// The firmware sends these for things the person should know but that
/// aren't messages: a duplicated or weak key, a send refused by the airtime
/// limit, a setting it changed back. Interactive key-verification steps are
/// not notices; [fromPayload] returns null for them.
class RadioNotice {
  const RadioNotice({
    required this.kind,
    required this.type,
    required this.level,
    required this.message,
    required this.receivedAt,
  });

  final RadioNoticeKind kind;

  /// The firmware's notice type (UNSET on firmware before 2.8.2).
  final ClientNotification_NotificationType type;
  final LogRecord_Level level;

  /// The firmware's own English text. May be empty.
  final String message;
  final DateTime receivedAt;

  /// Whether the notice is serious enough to show as a warning.
  bool get isWarning =>
      kind != RadioNoticeKind.general ||
      level == LogRecord_Level.CRITICAL ||
      level == LogRecord_Level.ERROR ||
      level == LogRecord_Level.WARNING;

  static const _verificationTypes = {
    ClientNotification_NotificationType.KEY_VERIFICATION_NUMBER_INFORM,
    ClientNotification_NotificationType.KEY_VERIFICATION_NUMBER_REQUEST,
    ClientNotification_NotificationType.KEY_VERIFICATION_FINAL_INCOMING,
    ClientNotification_NotificationType.KEY_VERIFICATION_FINAL_OUTGOING,
  };

  /// Decodes a ClientNotification payload, or null when it is malformed,
  /// empty, or a key-verification step this app does not run.
  static RadioNotice? fromPayload(Uint8List payload, DateTime receivedAt) {
    final ClientNotification n;
    try {
      n = ClientNotification.fromBuffer(payload);
    } on InvalidProtocolBufferException {
      return null;
    }
    final variant = n.whichPayloadVariant();
    if (_verificationTypes.contains(n.type) ||
        variant ==
            ClientNotification_PayloadVariant.keyVerificationNumberInform ||
        variant ==
            ClientNotification_PayloadVariant.keyVerificationNumberRequest ||
        variant == ClientNotification_PayloadVariant.keyVerificationFinal) {
      return null;
    }
    final kind = switch (n.type) {
      ClientNotification_NotificationType.DUPLICATED_PUBLIC_KEY ||
      ClientNotification_NotificationType.LOW_ENTROPY_KEY_REGENERATED ||
      ClientNotification_NotificationType.LOW_ENTROPY_KEY_RESTORE_REJECTED =>
        RadioNoticeKind.keySecurity,
      ClientNotification_NotificationType.UNSIGNED_IDENTITY_UPDATE_IGNORED =>
        RadioNoticeKind.identityRefused,
      ClientNotification_NotificationType.DUTY_CYCLE_LIMIT_EXCEEDED =>
        RadioNoticeKind.airtime,
      // Firmware before 2.8.2 sends no type; its payload still says what it is.
      _
          when variant ==
                  ClientNotification_PayloadVariant.duplicatedPublicKey ||
              variant == ClientNotification_PayloadVariant.lowEntropyKey =>
        RadioNoticeKind.keySecurity,
      _ => RadioNoticeKind.general,
    };
    final message = n.message.trim();
    if (kind == RadioNoticeKind.general && message.isEmpty) return null;
    return RadioNotice(
      kind: kind,
      type: n.type,
      level: n.level,
      message: message,
      receivedAt: receivedAt,
    );
  }
}
