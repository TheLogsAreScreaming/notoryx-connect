import 'package:bastion/field_guide_page.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/main.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/bastion_trouble_guides.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_text_codec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'support/shell_nav.dart';

const _me = 0x0a;
final _now = DateTime(2026, 11, 20, 12);

BastionChatMessage _dm(int to, Duration ago) => BastionChatMessage(
      packetId: to * 7 + ago.inMinutes,
      from: _me,
      to: to,
      channel: 0,
      text: 'hi',
      timestamp: _now.subtract(ago),
      direction: BastionMessageDirection.outgoing,
      deliveryState: BastionDeliveryState.sent,
    );

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('snapshot', () {
    test('counts who you messaged this week and who has gone quiet', () {
      final s = TroubleSnapshot.of(
        connected: true,
        localNode: _me,
        nodes: [
          MeshtasticNode(num: _me, lastHeard: _now),
          MeshtasticNode(num: 0x20, lastHeard: _now.subtract(const Duration(minutes: 10))),
          MeshtasticNode(num: 0x21, lastHeard: _now.subtract(const Duration(days: 3))),
        ],
        messages: [
          _dm(0x20, const Duration(hours: 1)),
          _dm(0x21, const Duration(days: 2)),
          _dm(0x22, const Duration(days: 30)), // too old to count
          BastionChatMessage(
            packetId: 1,
            from: _me,
            to: MeshtasticTextCodec.broadcastNode,
            channel: 0,
            text: 'all',
            timestamp: _now,
            direction: BastionMessageDirection.outgoing,
            deliveryState: BastionDeliveryState.sent,
          ),
        ],
        now: _now,
      );
      expect(s.messagedNodes, 2);
      expect(s.messagedNotHeardInDay, 1);
      expect(s.heardLastHour, 1, reason: 'your own radio does not count');
    });
  });

  group('guides', () {
    test('not connected: start with connecting, radio checks are unchecked', () {
      const s = TroubleSnapshot(connected: false, messagedNodes: 0, messagedNotHeardInDay: 0, heardLastHour: 0);
      final steps = runGuide(TroubleGuide.hearNobody, s);
      expect(steps.first, (TroubleStep.connected, StepResult.problem));
      expect(steps.firstWhere((x) => x.$1 == TroubleStep.region).$2, StepResult.unchecked);
      expect(startHere(steps), TroubleStep.connected);
    });

    test('a busy channel and a quiet contact are problems', () {
      const s = TroubleSnapshot(
          connected: true, messagedNodes: 2, messagedNotHeardInDay: 1, heardLastHour: 4, channelUtilization: 55);
      final steps = runGuide(TroubleGuide.noDelivery, s);
      expect(steps.firstWhere((x) => x.$1 == TroubleStep.heardRecently).$2, StepResult.problem);
      expect(steps.firstWhere((x) => x.$1 == TroubleStep.busyChannel).$2, StepResult.problem);
      expect(startHere(steps), TroubleStep.heardRecently);
    });

    test('no region set is the problem when you hear nobody', () {
      const s = TroubleSnapshot(
          connected: true, messagedNodes: 0, messagedNotHeardInDay: 0, heardLastHour: 0, regionSet: false);
      final steps = runGuide(TroubleGuide.hearNobody, s);
      expect(startHere(steps), TroubleStep.region);
    });

    test('when everything checks out, start with the first thing it could not check', () {
      const s = TroubleSnapshot(
          connected: true, messagedNodes: 1, messagedNotHeardInDay: 0, heardLastHour: 3, channelUtilization: 10);
      expect(startHere(runGuide(TroubleGuide.noDelivery, s)), TroubleStep.sameChannel);
    });
  });

  testWidgets('the field guide has every section and works offline', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: FieldGuidePage(),
    ));
    for (final title in ['Getting on the mesh', 'Batteries in the cold', 'Solar for fixed nodes', 'Antennas and placement']) {
      await tester.scrollUntilVisible(find.text(title), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text(title), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('Meshtastic documentation: meshtastic.org/docs'), 200,
        scrollable: find.byType(Scrollable).first);
  });

  testWidgets('Tools opens the field guide, and the doctor shows both guides', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    await openTools(tester);
    await tester.tap(find.byKey(const ValueKey('tools-field-guide')));
    await tester.pumpAndSettle();
    expect(find.text('Field guide'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Connection doctor'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const ValueKey('guide-hearNobody')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('Something else wrong?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('guide-noDelivery')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('start-noDelivery-connected')), findsOneWidget,
        reason: 'with no radio, connecting comes first');
    expect(find.text('Connect your radio first: Nodes → Scan for radios.'), findsOneWidget);
    // Let the doctor's Bluetooth checks time out before the test ends.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
