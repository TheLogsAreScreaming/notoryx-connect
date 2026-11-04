import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/local_mesh_discovery_page.dart';

void main() {
  testWidgets('discovery shows empty observed state without a radio', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LocalMeshDiscoveryPage()));
    await tester.scrollUntilVisible(
      find.text('Already heard on connected radio'), 200,
    );
    expect(find.text('Already heard on connected radio'), findsOneWidget);
    expect(
      find.text('0 observed nodes — existing radio data only; no scan has started.'),
      findsOneWidget,
    );
  });

  testWidgets('scan stays disabled after changing dwell time', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LocalMeshDiscoveryPage()));
    await tester.scrollUntilVisible(find.byType(Slider), 200);
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Start scan (not yet available)'), 200,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}
