import 'package:bastion/sarneg/secure_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<Object?> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SecureScreen.channel, (call) async {
          calls.add('${call.method}:${call.arguments}');
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SecureScreen.channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Widget stack(int open) => MaterialApp(
    home: Stack(
      children: [
        for (var i = 0; i < open; i++) const SecureScreen(child: SizedBox()),
      ],
    ),
  );

  testWidgets('on Android the flag is on while any secure screen is open', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(stack(1));
    expect(calls, ['setSecure:true']);

    await tester.pumpWidget(stack(2));
    expect(calls, [
      'setSecure:true',
    ], reason: 'a nested screen does not set it again');
    expect(SecureScreen.openCount, 2);

    await tester.pumpWidget(stack(1));
    expect(calls, ['setSecure:true'], reason: 'still one open');

    await tester.pumpWidget(stack(0));
    expect(calls, ['setSecure:true', 'setSecure:false']);
    expect(SecureScreen.openCount, 0);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('other platforms are left alone', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(stack(1));
    await tester.pumpWidget(stack(0));
    expect(calls, isEmpty);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a missing handler is not an error', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SecureScreen.channel, null);
    await tester.pumpWidget(stack(1));
    await tester.pumpWidget(stack(0));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
