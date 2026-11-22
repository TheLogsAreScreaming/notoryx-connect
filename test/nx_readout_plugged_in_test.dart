import 'package:bastion/theme/nx_glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget strip(double textScale) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: const Size(360, 640), textScaler: TextScaler.linear(textScale)),
          child: const Scaffold(
            body: SizedBox(
              width: 360,
              child: NxReadoutStrip([
                NxReadout('Plugged in', 'Battery', icon: Icons.power),
                NxReadout('3.98', 'Voltage'),
                NxReadout('0%', 'Channel use'),
                NxReadout('2052', 'Nodes'),
              ]),
            ),
          ),
        ),
      );

  for (final scale in [1.0, 2.0]) {
    testWidgets('plugged-in battery shows a plug, not a broken word (x$scale)', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(strip(scale));
      expect(find.byIcon(Icons.power), findsOneWidget);
      expect(find.text('Plugged in'), findsNothing);
      expect(find.bySemanticsLabel('Battery: Plugged in'), findsOneWidget);
      expect(find.text('3.98'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
