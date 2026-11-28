import 'package:bastion/services/bastion_channel_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final ownKey = List<int>.generate(16, (i) => i + 1);

  test('exact position is allowed only with the channel\'s own key', () {
    expect(BastionChannelValidation.precisionError(32, ownKey), isNull);
    expect(
      BastionChannelValidation.precisionError(32, List.filled(32, 7)),
      isNull,
    );
    expect(BastionChannelValidation.precisionError(32, const [1]), isNotNull);
    expect(BastionChannelValidation.precisionError(32, const [0]), isNotNull);
    expect(BastionChannelValidation.precisionError(32, const []), isNotNull);
  });

  test('rounded positions are fine on any channel', () {
    for (final bits in [0, 10, 16, 19]) {
      expect(BastionChannelValidation.precisionError(bits, const [1]), isNull);
    }
  });

  test('validate refuses exact on the default key', () {
    expect(
      BastionChannelValidation.validate(
        index: 1,
        role: 2,
        name: 'Team',
        key: const [1],
        precisionBits: 32,
      ),
      contains('own key'),
    );
    expect(
      BastionChannelValidation.validate(
        index: 1,
        role: 2,
        name: 'Team',
        key: ownKey,
        precisionBits: 32,
      ),
      isNull,
    );
  });
}
