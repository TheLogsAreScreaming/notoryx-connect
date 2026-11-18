import 'dart:typed_data';

import 'package:bastion/generated/meshtastic/mesh.pb.dart';
import 'package:bastion/services/bastion_radio_notice.dart';
import 'package:flutter_test/flutter_test.dart';

final _at = DateTime.utc(2026, 11, 18, 12);

RadioNotice? _decode(ClientNotification n) =>
    RadioNotice.fromPayload(Uint8List.fromList(n.writeToBuffer()), _at);

void main() {
  test('a duplicated or weak key is a key-security notice', () {
    for (final type in [
      ClientNotification_NotificationType.DUPLICATED_PUBLIC_KEY,
      ClientNotification_NotificationType.LOW_ENTROPY_KEY_REGENERATED,
      ClientNotification_NotificationType.LOW_ENTROPY_KEY_RESTORE_REJECTED,
    ]) {
      final notice = _decode(ClientNotification(type: type, message: 'x'))!;
      expect(notice.kind, RadioNoticeKind.keySecurity, reason: '$type');
      expect(notice.isWarning, isTrue);
    }
  });

  test('older firmware without a type is still recognised by its payload', () {
    final notice = _decode(
      ClientNotification(
        message: 'Remote device is using your public key',
        duplicatedPublicKey: DuplicatedPublicKey(),
      ),
    )!;
    expect(notice.kind, RadioNoticeKind.keySecurity);
    expect(
      _decode(ClientNotification(lowEntropyKey: LowEntropyKey()))!.kind,
      RadioNoticeKind.keySecurity,
    );
  });

  test('a refused unsigned identity update and the airtime limit', () {
    expect(
      _decode(
        ClientNotification(
          type: ClientNotification_NotificationType
              .UNSIGNED_IDENTITY_UPDATE_IGNORED,
        ),
      )!.kind,
      RadioNoticeKind.identityRefused,
    );
    final airtime = _decode(
      ClientNotification(
        type: ClientNotification_NotificationType.DUTY_CYCLE_LIMIT_EXCEEDED,
        message: 'Duty cycle limit exceeded. You can send again in 12 mins.',
      ),
    )!;
    expect(airtime.kind, RadioNoticeKind.airtime);
    expect(airtime.message, contains('12 mins'));
    expect(airtime.receivedAt, _at);
  });

  test('other notices keep the firmware text and level', () {
    final info = _decode(
      ClientNotification(
        type: ClientNotification_NotificationType.TRACEROUTE_RATE_LIMITED,
        level: LogRecord_Level.INFO,
        message: '  Traceroute is rate limited.  ',
      ),
    )!;
    expect(info.kind, RadioNoticeKind.general);
    expect(info.message, 'Traceroute is rate limited.');
    expect(info.isWarning, isFalse);
    final warn = _decode(
      ClientNotification(
        level: LogRecord_Level.WARNING,
        message: 'Rebroadcast NONE is not allowed for a router.',
      ),
    )!;
    expect(warn.isWarning, isTrue);
  });

  test('key-verification steps, empty notices and junk are not shown', () {
    expect(
      _decode(
        ClientNotification(
          type: ClientNotification_NotificationType
              .KEY_VERIFICATION_NUMBER_REQUEST,
          message: 'Enter the number',
        ),
      ),
      isNull,
    );
    expect(
      _decode(
        ClientNotification(
          keyVerificationNumberInform: KeyVerificationNumberInform(),
        ),
      ),
      isNull,
    );
    expect(_decode(ClientNotification(message: '   ')), isNull);
    expect(
      RadioNotice.fromPayload(Uint8List.fromList([0xff, 0xff, 0xff]), _at),
      isNull,
    );
  });
}
