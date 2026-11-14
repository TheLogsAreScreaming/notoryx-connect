import 'package:bastion/services/bastion_background_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 14, 18);

  test('the service keeps running while the app keeps beating', () {
    final watch = BastionHeartbeatWatch(t0);
    var now = t0;
    for (var i = 0; i < 20; i++) {
      now = now.add(BastionHeartbeatWatch.beatEvery);
      watch.heard(BastionHeartbeatWatch.beat, now);
      expect(watch.appGone(now.add(BastionHeartbeatWatch.checkEvery)), isFalse);
    }
  });

  test('the service stops once the app goes quiet', () {
    final watch = BastionHeartbeatWatch(t0);
    expect(watch.appGone(t0.add(BastionHeartbeatWatch.giveUpAfter)), isFalse);
    expect(
      watch.appGone(
        t0.add(BastionHeartbeatWatch.giveUpAfter + const Duration(seconds: 1)),
      ),
      isTrue,
    );
  });

  test('other messages do not count as a beat', () {
    final watch = BastionHeartbeatWatch(t0);
    watch.heard('something else', t0.add(const Duration(minutes: 1)));
    expect(watch.appGone(t0.add(const Duration(minutes: 2))), isTrue);
  });

  test('a few missed beats are tolerated', () {
    expect(
      BastionHeartbeatWatch.giveUpAfter,
      greaterThan(BastionHeartbeatWatch.beatEvery * 3),
    );
    expect(
      BastionHeartbeatWatch.checkEvery,
      lessThan(BastionHeartbeatWatch.giveUpAfter),
    );
  });
}
