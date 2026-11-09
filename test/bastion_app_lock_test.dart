import 'package:bastion/app_lock_gate.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/bastion_app_lock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeAuth implements BastionDeviceAuth {
  bool available = true, answer = true;
  Object? error;
  int asked = 0;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<bool> authenticate(String reason) async {
    asked++;
    if (error != null) throw error!;
    return answer;
  }
}

void main() {
  late FakeAuth auth;
  late DateTime clock;
  BastionAppLock make() => BastionAppLock(auth: auth, now: () => clock);
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    auth = FakeAuth();
    clock = DateTime(2026, 11, 8, 12);
  });

  test('off by default, and a fresh start stays open', () async {
    final lock = make();
    await lock.load();
    expect((lock.enabled, lock.locked), (false, false));
  });

  test('turning on needs the owner and locks the next start', () async {
    final lock = make();
    auth.answer = false;
    expect(await lock.setEnabled(true, 'r'), isFalse);
    expect(lock.enabled, isFalse);
    auth.answer = true;
    expect(await lock.setEnabled(true, 'r'), isTrue);
    expect(lock.locked, isFalse);
    final next = make();
    await next.load();
    expect((next.enabled, next.locked), (true, true));
  });

  test('locks after a minute away, not before', () async {
    final lock = make();
    await lock.setEnabled(true, 'r');
    lock.onBackground();
    clock = clock.add(const Duration(seconds: 59));
    lock.onForeground();
    expect(lock.locked, isFalse);
    lock.onBackground();
    clock = clock.add(BastionAppLock.grace);
    lock.onForeground();
    expect(lock.locked, isTrue);
  });

  test('a failed or broken prompt stays locked', () async {
    final lock = make();
    await lock.setEnabled(true, 'r');
    final next = make();
    await next.load();
    auth.answer = false;
    await next.unlock('r');
    expect(next.locked, isTrue);
    auth.error = PlatformException(code: 'x');
    await next.unlock('r');
    expect(next.locked, isTrue);
  });

  test('a phone with no screen lock left opens instead of trapping data', () async {
    final lock = make();
    await lock.setEnabled(true, 'r');
    final next = make();
    await next.load();
    auth.available = false;
    await next.unlock('r');
    expect(next.locked, isFalse);
  });

  testWidgets('the gate hides the app and opens after unlock', (tester) async {
    final lock = make();
    await lock.setEnabled(true, 'r');
    final next = make();
    await next.load();
    auth.answer = false;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => BastionAppLockGate(lock: next, child: child!),
      home: const Text('secret'),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-lock-screen')), findsOneWidget);
    expect(find.bySemanticsLabel('secret'), findsNothing);
    auth.answer = true;
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-lock-screen')), findsNothing);
    expect(find.text('secret'), findsOneWidget);
  });
}
