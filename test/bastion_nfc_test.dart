import 'package:bastion/services/bastion_nfc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isAvailable returns false outside Android', () async {
    // Tests run on the host platform (not Android), so NFC is never available.
    expect(await BastionNfc.isAvailable(), isFalse);
  });

  test('writeUri calls onError when NFC is unavailable', () async {
    String? error;
    bool done = false;
    await BastionNfc.writeUri(
      'https://meshtastic.org/e/#test',
      onError: (r) => error = r,
      onDone: () => done = true,
    );
    expect(error, 'unavailable');
    expect(done, isFalse);
  });

  test('cancel completes without throwing outside Android', () async {
    await expectLater(BastionNfc.cancel(), completes);
  });
}
