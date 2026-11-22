import 'package:bastion/services/bastion_send_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps each firmware routing error to a cause', () {
    for (final (code, cause) in [
      (1, BastionSendFailure.noRoute),
      (2, BastionSendFailure.rejected),
      (3, BastionSendFailure.noReply),
      (4, BastionSendFailure.radioError),
      (5, BastionSendFailure.noReply),
      (6, BastionSendFailure.noChannel),
      (7, BastionSendFailure.tooLong),
      (8, BastionSendFailure.noReply),
      (9, BastionSendFailure.airtimeLimit),
      (32, BastionSendFailure.rejected),
      (33, BastionSendFailure.rejected),
      (34, BastionSendFailure.keyMismatch),
      (35, BastionSendFailure.theyLackYourKey),
      (36, BastionSendFailure.rejected),
      (37, BastionSendFailure.rejected),
      (38, BastionSendFailure.rateLimited),
      (39, BastionSendFailure.noKey),
    ]) {
      expect(BastionSendFailure.fromCode(code), cause, reason: 'code $code');
    }
  });

  test('codes from newer firmware read as unknown', () {
    expect(BastionSendFailure.fromCode(40), BastionSendFailure.unknown);
    expect(BastionSendFailure.fromCode(0), BastionSendFailure.unknown);
  });
}
