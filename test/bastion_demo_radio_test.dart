import 'package:bastion/main.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/bastion_demo_radio.dart';
import 'package:bastion/services/meshtastic_ble_discovery.dart';
import 'package:bastion/services/bastion_telemetry_history.dart';
import 'package:bastion/services/bastion_trip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('the demo radio is ready with nodes, messages and sensor history', () {
    final radio = BastionDemoRadio();
    addTearDown(radio.dispose);
    expect(radio.isReady, isTrue);
    expect(radio.connection.deviceName, BastionDemoRadio.demoRadioName);
    expect(radio.localNode?.longName, 'Demo Base');
    expect(radio.nodes.length, greaterThanOrEqualTo(5));
    expect(radio.nodes.where((n) => n.latitude != null), hasLength(radio.nodes.length),
        reason: 'every demo node shows on the map');
    expect(radio.messages.where((m) => !m.isReaction), isNotEmpty);
    expect(radio.messages.any((m) => radio.mentionsMe(m.text)), isTrue,
        reason: 'a sample message mentions you');
    const wx = 0xDE300006;
    expect(radio.telemetryMetricsOf(wx), contains(TelemetryMetric.temperature));
    expect(radio.telemetrySeries(wx, TelemetryMetric.temperature).length, greaterThan(50));
  });

  test('a real radio cannot be connected during the demo', () async {
    final radio = BastionDemoRadio();
    addTearDown(radio.dispose);
    await expectLater(radio.connect(MeshtasticBleDevice.network('192.168.1.2')),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('Exit demo'))));
  });

  testWidgets('sent messages are delivered and answered, without touching storage', (tester) async {
    final radio = BastionDemoRadio(replyDelay: const Duration(seconds: 1));
    addTearDown(radio.dispose);
    final before = radio.messages.length;
    await radio.sendText(text: 'What is your position?', destination: 0xffffffff, channel: 0);
    final sent = radio.messages.last;
    expect(sent.deliveryState, BastionDeliveryState.sent);
    await tester.pump(const Duration(seconds: 2));
    expect(radio.messages.firstWhere((m) => m.packetId == sent.packetId).deliveryState,
        BastionDeliveryState.delivered);
    expect(radio.messages.length, before + 2);
    expect(radio.messages.last.direction, BastionMessageDirection.incoming);

    // A demo check-in stays in the demo.
    await radio.trip.updatePlan(const TripPlan(members: [0xDE300003]));
    await radio.trip.checkIn(checkInLabels.first);
    await tester.pump(const Duration(seconds: 2));
    expect(await SharedPreferencesAsync().getKeys(), isEmpty,
        reason: 'nothing from the demo is saved on the phone');
  });

  testWidgets('the demo can be started from Home and ended from the banner', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const BastionApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try the demo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo mode: pretend radio'), findsOneWidget);
    expect(find.text('Radio connected'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.hub_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Ridge Relay'), findsOneWidget);
    await tester.tap(find.text('Exit demo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo mode: pretend radio'), findsNothing);
    expect(find.text('No radio connected'), findsOneWidget);
    expect(find.text('Ridge Relay'), findsNothing);
  });
}
