import 'package:bastion/theme/nx_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a word value in a wide stat tile stays on one line on a phone', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: NxStatRow(children: [
            NxStatTile(label: 'Radios found', value: '10'),
            NxStatTile(label: 'Mesh nodes', value: '12'),
            NxStatTile(flex: 2, label: 'Status', value: 'Connected'),
          ]),
        ),
      ),
    ));
    final value = tester.renderObject<RenderParagraph>(find.text('Connected'));
    final boxes = value.getBoxesForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 'Connected'.length));
    expect(boxes.map((b) => b.top).toSet(), hasLength(1), reason: 'the word was broken across lines');
  });
}
