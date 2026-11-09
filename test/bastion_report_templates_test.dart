import 'package:bastion/field_tools_page.dart';
import 'package:bastion/services/bastion_report_templates.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  test('SALUTE keeps its letters and leaves out blanks', () {
    expect(BastionReportTemplate.salute.compose({'S': ' 3 people ', 'A': '', 'T': '14:05'}),
        'SALUTE | S: 3 people | T: 14:05');
  });

  test('9-Line has nine numbered lines', () {
    final t = BastionReportTemplate.nineLine;
    expect(t.fields.map((f) => f.code), ['1', '2', '3', '4', '5', '6', '7', '8', '9']);
    expect(t.compose({'1': 'Camp', '5': '1 litter'}), '9LINE | 1: Camp | 5: 1 litter');
  });

  test('nothing filled in composes to nothing', () {
    expect(BastionReportTemplate.salute.compose({'S': '   '}), '');
  });

  test('line breaks and separators cannot blur the parts', () {
    expect(BastionReportTemplate.salute.compose({'S': 'a | b\nc'}), 'SALUTE | S: a / b c');
  });

  test('size is counted in bytes, not characters', () {
    expect(BastionReportTemplate.bytesOf('ñ'), 2);
  });

  Future<void> open(WidgetTester tester, String tag) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(home: FieldToolsPage(radio: radio)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('message-templates')).first);
    await tester.tap(find.text('Emergency & check-in templates'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('report-$tag')));
    await tester.pumpAndSettle();
  }

  testWidgets('a filled report lands in the message box for review', (tester) async {
    await open(tester, 'SALUTE');
    await tester.enterText(find.byKey(const ValueKey('report-field-S')), '3 people');
    await tester.pump();
    await tester.tap(find.text('Use report'));
    await tester.pumpAndSettle();
    expect(find.textContaining('SALUTE | S: 3 people'), findsOneWidget);
  });

  testWidgets('a report too long to send cannot be used', (tester) async {
    await open(tester, '9LINE');
    await tester.enterText(find.byKey(const ValueKey('report-field-1')), 'x' * 300);
    await tester.pump();
    expect(find.textContaining('Too long to send'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Use report')).onPressed, isNull);
  });
}
