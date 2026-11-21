import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the More tab and its Tools side.
Future<void> openTools(WidgetTester tester) => _openMore(tester, Icons.build_outlined);

/// Opens the More tab and its Settings side.
Future<void> openSettings(WidgetTester tester) => _openMore(tester, Icons.settings_outlined);

Future<void> _openMore(WidgetTester tester, IconData side) async {
  await tester.tap(find.byIcon(Icons.more_horiz).last);
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byKey(const ValueKey('more-switch')), matching: find.byIcon(side)));
  await tester.pumpAndSettle();
}
