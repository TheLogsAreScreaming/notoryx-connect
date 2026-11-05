import 'package:bastion/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget home) => MaterialApp(
      theme: BastionApp.appearance(Brightness.dark),
      scrollBehavior: const BastionScrollBehavior(),
      home: home,
    );

void main() {
  testWidgets('long lists get a scroll bar on phones', (tester) async {
    await tester.pumpWidget(_app(Scaffold(
      body: ListView(children: [for (var i = 0; i < 300; i++) ListTile(title: Text('Node $i'))]),
    )));
    expect(find.byType(Scrollbar), findsOneWidget);
    expect(tester.widget<Scrollbar>(find.byType(Scrollbar)).interactive, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('dragging the thumb moves through the list in one go', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(Scaffold(
      body: ListView(
        controller: controller,
        children: [for (var i = 0; i < 300; i++) ListTile(title: Text('Node $i'))],
      ),
    )));
    // Show the thumb, then drag it from the top to the bottom edge.
    controller.jumpTo(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final gesture = await tester.startGesture(const Offset(396, 30));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 760));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.offset, greaterThan(controller.position.maxScrollExtent * 0.9));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('horizontal lists are left alone', (tester) async {
    await tester.pumpWidget(_app(Scaffold(
      body: ListView(
        scrollDirection: Axis.horizontal,
        children: [for (var i = 0; i < 50; i++) const SizedBox(width: 100)],
      ),
    )));
    expect(find.byType(Scrollbar), findsNothing);
  });
}
