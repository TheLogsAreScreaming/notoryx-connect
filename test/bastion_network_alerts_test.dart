import 'package:bastion/services/bastion_field_alerts.dart';
import 'package:bastion/services/meshtastic_mesh_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mesh goes quiet', () {
    late DateTime now;
    late BastionFieldAlertEngine engine;
    const on = BastionAlertSettings(meshDrop: true);
    List<DateTime?> heard(int active, [int stale = 0]) => [
          for (var i = 0; i < active; i++) now,
          for (var i = 0; i < stale; i++) now.subtract(const Duration(hours: 3)),
        ];

    setUp(() {
      now = DateTime(2026, 11, 8, 12);
      engine = BastionFieldAlertEngine(clock: () => now)..startSession(1);
    });

    test('off by default, and old saved settings stay off', () {
      expect(const BastionAlertSettings().meshDrop, isFalse);
      expect(BastionAlertSettings.fromJson({'newNode': true}).meshDrop, isFalse);
      expect(engine.checkMeshDrop(heard(10), const BastionAlertSettings()), isNull);
      expect(BastionAlertSettings.fromJson(on.toJson()).meshDrop, isTrue);
    });

    test('alerts once at half the peak, then rearms when most return', () {
      engine.checkMeshDrop(heard(10), on);
      now = now.add(const Duration(hours: 2));
      final alert = engine.checkMeshDrop(heard(5, 5), on);
      expect(alert?.kind, BastionAlertKind.meshDrop);
      expect(alert?.body, contains('down from 10'));
      expect(engine.checkMeshDrop(heard(4, 6), on), isNull, reason: 'only once');
      expect(engine.checkMeshDrop(heard(9, 1), on), isNull, reason: 'recovered');
      expect(engine.checkMeshDrop(heard(4, 6), on), isNotNull, reason: 'rearmed');
    });

    test('a small mesh never alerts', () {
      engine.checkMeshDrop(heard(5), on);
      now = now.add(const Duration(hours: 2));
      expect(engine.checkMeshDrop(heard(1, 4), on), isNull);
    });

    test('waits an hour into the session', () {
      engine.checkMeshDrop(heard(10), on);
      now = now.add(const Duration(minutes: 30));
      expect(engine.checkMeshDrop(heard(2, 8), on), isNull);
    });
  });

  group('store and forward catch-up window', () {
    final now = DateTime(2026, 11, 8, 12);
    test('unknown or short gaps ask for nothing', () {
      expect(BastionStoreForwardCatchUp.windowFor(null, now), isNull);
      expect(BastionStoreForwardCatchUp.windowFor(now.subtract(const Duration(minutes: 14)), now), isNull);
    });
    test('the gap is requested, up to a day', () {
      expect(BastionStoreForwardCatchUp.windowFor(now.subtract(const Duration(hours: 3)), now), const Duration(hours: 3));
      expect(BastionStoreForwardCatchUp.windowFor(now.subtract(const Duration(days: 4)), now), const Duration(hours: 24));
    });
  });
}
