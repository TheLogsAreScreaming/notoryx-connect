import 'package:bastion/node_detail_page.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unknown node shows its id with actions disabled offline', (tester) async {
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: NodeDetailPage(radio: radio, nodeNum: 0xabcdef01)));
    await tester.pump();

    expect(find.text('!abcdef01'), findsWidgets);
    for (final label in ['Traceroute', 'Request position', 'Request telemetry']) {
      final button = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is OutlinedButton)),
      );
      expect(button.onPressed, isNull, reason: label);
    }
    await tester.scrollUntilVisible(find.text('No direct messages with this node yet.'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('No direct messages with this node yet.'), findsOneWidget);
    expect(find.text('Ignore this node'), findsOneWidget);
  });

  test('node requests refuse to send without a ready radio', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final radio = MeshtasticRadioCoordinator();
    await expectLater(radio.requestPosition(7), throwsStateError);
    await expectLater(radio.requestTelemetry(7), throwsStateError);
    radio.dispose();
  });
}
