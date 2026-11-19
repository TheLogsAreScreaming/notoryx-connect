import 'package:bastion/main.dart';
import 'package:bastion/services/bastion_preferences.dart';
import 'package:bastion/services/bastion_stale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  final now = DateTime.utc(2026, 11, 18, 12);

  group('isStale', () {
    test('a node never heard is never stale', () {
      expect(isStale(null, now, const Duration(hours: 1)), isFalse);
    });

    test('off never marks a node', () {
      expect(
        isStale(now.subtract(const Duration(days: 365)), now, null),
        isFalse,
      );
    });

    test('stale only once quiet for longer than the threshold', () {
      const after = Duration(hours: 24);
      expect(
        isStale(now.subtract(const Duration(hours: 23)), now, after),
        isFalse,
      );
      expect(
        isStale(now.subtract(after), now, after),
        isFalse,
        reason: 'exactly at the threshold is not yet stale',
      );
      expect(
        isStale(
          now.subtract(const Duration(hours: 24, seconds: 1)),
          now,
          after,
        ),
        isTrue,
      );
    });

    test('a last-heard time in the future (clock skew) is not stale', () {
      expect(
        isStale(
          now.add(const Duration(hours: 5)),
          now,
          const Duration(hours: 1),
        ),
        isFalse,
      );
    });
  });

  group('BastionStaleAfter', () {
    test(
      'offers Off, 1 h, 6 h, 24 h, 3 days and 7 days, defaulting to 24 h',
      () {
        expect(BastionStaleAfter.values.map((v) => v.after), [
          null,
          const Duration(hours: 1),
          const Duration(hours: 6),
          const Duration(hours: 24),
          const Duration(days: 3),
          const Duration(days: 7),
        ]);
        expect(BastionStaleAfter.standard, BastionStaleAfter.day);
      },
    );

    test('reads a saved name back and falls back to the default', () {
      expect(
        BastionStaleAfter.fromName('threeDays'),
        BastionStaleAfter.threeDays,
      );
      expect(BastionStaleAfter.fromName('off'), BastionStaleAfter.off);
      expect(BastionStaleAfter.fromName(null), BastionStaleAfter.day);
      expect(BastionStaleAfter.fromName('fortnight'), BastionStaleAfter.day);
    });

    test('marks uses the chosen threshold', () {
      final heard = now.subtract(const Duration(hours: 7));
      expect(BastionStaleAfter.sixHours.marks(heard, now), isTrue);
      expect(BastionStaleAfter.day.marks(heard, now), isFalse);
      expect(BastionStaleAfter.off.marks(heard, now), isFalse);
    });
  });

  testWidgets('Settings saves the stale threshold on the phone', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    addTearDown(
      () =>
          BastionPreferences.instance.update(stale: BastionStaleAfter.standard),
    );
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BastionApp());
    await tester.tap(find.byIcon(Icons.settings_outlined).last);
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('settings-stale-after'));
    await tester.scrollUntilVisible(
      field,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mark nodes stale after'), findsOneWidget);
    expect(
      find.descendant(of: field, matching: find.text('24 hours')),
      findsOneWidget,
      reason: 'default',
    );
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text('6 hours').last);
    await tester.pumpAndSettle();
    expect(BastionPreferences.instance.staleAfter, BastionStaleAfter.sixHours);
    expect(
      await SharedPreferencesAsync().getString('bastion.nodes.stale_after'),
      'sixHours',
    );
  });
}
