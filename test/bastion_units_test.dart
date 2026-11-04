import 'package:bastion/services/bastion_preferences.dart';
import 'package:bastion/services/bastion_units.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  const metric = BastionUnits.metric, imperial = BastionUnits.imperial;

  test('metric distances', () {
    expect(BastionUnitFormat.distance(850.4, metric), '850 m');
    expect(BastionUnitFormat.distance(999.6, metric), '1000 m');
    expect(BastionUnitFormat.distance(2440, metric), '2.4 km');
    expect(BastionUnitFormat.distance(123456, metric), '123 km');
  });

  test('imperial distances use feet under 0.1 mi, then miles', () {
    expect(BastionUnitFormat.distance(100, imperial), '328 ft');
    expect(BastionUnitFormat.distance(160, imperial), '525 ft');
    expect(BastionUnitFormat.distance(161, imperial), '0.1 mi');
    expect(BastionUnitFormat.distance(2440, imperial), '1.5 mi');
    expect(BastionUnitFormat.distance(200000, imperial), '124 mi');
  });

  test('altitude', () {
    expect(BastionUnitFormat.altitude(1240, metric), '1240 m');
    expect(BastionUnitFormat.altitude(1240, imperial), '4068 ft');
  });

  test('default follows the phone region', () {
    expect(BastionUnitFormat.defaultFor('US'), imperial);
    expect(BastionUnitFormat.defaultFor('us'), imperial);
    expect(BastionUnitFormat.defaultFor('GB'), metric);
    expect(BastionUnitFormat.defaultFor(null), metric);
  });

  testWidgets('the choice is saved and restored', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    tester.platformDispatcher.localeTestValue = const Locale('en', 'DE');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final prefs = BastionPreferences();
    await prefs.load();
    expect(prefs.units, metric, reason: 'Germany defaults to metric');
    await prefs.update(unitSystem: imperial);
    expect(await SharedPreferencesAsync().getString('bastion.units'), 'imperial');
    final reloaded = BastionPreferences();
    await reloaded.load();
    expect(reloaded.units, imperial);
  });

  testWidgets('a US phone defaults to miles', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    tester.platformDispatcher.localeTestValue = const Locale('en', 'US');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    final prefs = BastionPreferences();
    await prefs.load();
    expect(prefs.units, imperial);
  });
}
