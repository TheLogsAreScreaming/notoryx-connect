import 'package:bastion/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  testWidgets('Nodes offers a Wi-Fi connection with address checks', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.hub_outlined).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Connect over Wi-Fi'));
    await tester.pumpAndSettle();

    FilledButton connect() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Connect'));
    expect(connect().onPressed, isNull, reason: 'no address yet');
    await tester.enterText(find.widgetWithText(TextField, 'Radio address'), 'http://radio');
    await tester.pump();
    expect(connect().onPressed, isNull, reason: 'a URL is not a host');
    await tester.enterText(find.widgetWithText(TextField, 'Radio address'), '192.168.1.42');
    await tester.pump();
    expect(connect().onPressed, isNotNull);
    await tester.enterText(find.widgetWithText(TextField, 'Port'), '70000');
    await tester.pump();
    expect(connect().onPressed, isNull, reason: 'port out of range');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
