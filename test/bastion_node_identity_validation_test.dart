import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/services/bastion_node_identity_validation.dart';

void main() {
  test('node identity validates required and maximum lengths', () {
    expect(BastionNodeIdentityValidation.longNameError(''), isNotNull);
    expect(BastionNodeIdentityValidation.longNameError('Field Radio'), isNull);
    expect(BastionNodeIdentityValidation.longNameError('a' * 40), isNotNull);
    expect(BastionNodeIdentityValidation.shortNameError('BCS'), isNull);
    expect(BastionNodeIdentityValidation.shortNameError('ABCDE'), isNotNull);
    expect(BastionNodeIdentityValidation.shortNameError('A\nB'), isNotNull);
  });

  group('long-name limit follows the radio firmware', () {
    test('firmware 2.8.0 and newer keeps 24 bytes', () {
      for (final v in ['2.8.0', '2.8.2.d5f1619', 'v2.8.1', '2.9.0', '3.0.0']) {
        expect(
          BastionNodeIdentityValidation.maxLongNameBytes(v),
          24,
          reason: v,
        );
      }
    });

    test('older or unknown firmware keeps 39 bytes', () {
      for (final v in [null, '', 'garbage', '2.7.26.54e0d8d', '2.5.0']) {
        expect(
          BastionNodeIdentityValidation.maxLongNameBytes(v),
          39,
          reason: '$v',
        );
      }
    });

    test('a 25-byte name is refused on 2.8 and allowed on 2.7', () {
      final name = 'a' * 25;
      expect(
        BastionNodeIdentityValidation.longNameError(
          name,
          firmwareVersion: '2.8.2',
        ),
        isNotNull,
      );
      expect(
        BastionNodeIdentityValidation.longNameError(
          name,
          firmwareVersion: '2.7.26',
        ),
        isNull,
      );
      expect(
        BastionNodeIdentityValidation.longNameError(
          'a' * 24,
          firmwareVersion: '2.8.2',
        ),
        isNull,
      );
    });

    test('counts UTF-8 bytes, not characters', () {
      // 12 characters, 24 bytes: fits exactly.
      expect(
        BastionNodeIdentityValidation.longNameError(
          'é' * 12,
          firmwareVersion: '2.8.0',
        ),
        isNull,
      );
      // 13 characters, 26 bytes: over.
      expect(
        BastionNodeIdentityValidation.longNameError(
          'é' * 13,
          firmwareVersion: '2.8.0',
        ),
        isNotNull,
      );
      // Emoji are four bytes each: six fit, seven don't.
      expect(
        BastionNodeIdentityValidation.longNameError(
          '📡' * 6,
          firmwareVersion: '2.8.0',
        ),
        isNull,
      );
      expect(
        BastionNodeIdentityValidation.longNameError(
          '📡' * 7,
          firmwareVersion: '2.8.0',
        ),
        isNotNull,
      );
    });
  });
}
