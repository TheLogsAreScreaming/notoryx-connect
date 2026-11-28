import 'package:bastion/services/meshtastic_messaging_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const away = '{hops_emoji} Back soon. {hops} hops at {snr} dB.';

  test('fills hops, the hop emoji and SNR in the away reply', () {
    expect(MeshtasticMessagingService.botResponse('hi', away, hops: 2, snr: -7.24),
        'NOTORYX: 2️⃣ Back soon. 2 hops at -7.2 dB.');
  });

  test('heard directly is the target, ten is the ten keycap, more is the kangaroo', () {
    expect(MeshtasticMessagingService.hopEmoji(0), '\u{1F3AF}');
    expect(MeshtasticMessagingService.hopEmoji(1), '1️⃣');
    expect(MeshtasticMessagingService.hopEmoji(9), '9️⃣');
    expect(MeshtasticMessagingService.hopEmoji(10), '\u{1F51F}');
    expect(MeshtasticMessagingService.hopEmoji(11), '\u{1F998}');
  });

  test('an unknown hop count is a question, never "direct"', () {
    expect(MeshtasticMessagingService.hopEmoji(null), '❓');
    expect(MeshtasticMessagingService.botResponse('hi', away),
        'NOTORYX: ❓ Back soon. ? hops at ? dB.');
  });

  test('commands ignore the placeholders and a plain reply is unchanged', () {
    expect(MeshtasticMessagingService.botResponse('!status', away, hops: 1), 'NOTORYX: online • radio READY');
    expect(MeshtasticMessagingService.botResponse('hello?', 'Back at 6', hops: 3), 'NOTORYX: Back at 6');
  });
}
