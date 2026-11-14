import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/mesh_health_page.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/bastion_mesh_health.dart';
import 'package:bastion/services/bastion_telemetry_codec.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final _now = DateTime(2026, 11, 7, 12);

BastionChatMessage _msg(int id, Duration ago) => BastionChatMessage(
      packetId: id, from: 2, to: 0xffffffff, channel: 0, text: 'hi $id',
      timestamp: _now.subtract(ago), direction: BastionMessageDirection.incoming,
      deliveryState: BastionDeliveryState.received,
    );

final _nodes = [
  const MeshtasticNode(num: 1, longName: 'Me'),
  MeshtasticNode(num: 2, longName: 'Near', hopsAway: 0, snr: 8, lastHeard: _now.subtract(const Duration(minutes: 5))),
  MeshtasticNode(num: 3, longName: 'Far', hopsAway: 2, snr: -9, lastHeard: _now.subtract(const Duration(hours: 5))),
  const MeshtasticNode(num: 4, longName: 'Unknown'),
];

void main() {
  test('levels follow the busy and overloaded thresholds', () {
    expect(MeshHealthSummary.levelOf(null, 25, 40), HealthLevel.unknown);
    expect(MeshHealthSummary.levelOf(10, 25, 40), HealthLevel.good);
    expect(MeshHealthSummary.levelOf(25, 25, 40), HealthLevel.busy);
    expect(MeshHealthSummary.levelOf(41, 25, 40), HealthLevel.overloaded);
  });

  test('summary counts nodes, hops, signal and traffic, excluding this radio', () {
    final h = MeshHealthSummary.of(
      nodes: _nodes,
      telemetry: const {
        1: BastionDeviceTelemetry(from: 1, channelUtilization: 31, airUtilTx: 4),
        2: BastionDeviceTelemetry(from: 2, channelUtilization: 10, airUtilTx: 9),
      },
      messages: [_msg(1, const Duration(minutes: 10)), _msg(2, const Duration(hours: 5)), _msg(3, const Duration(days: 2))],
      local: 1,
      now: _now,
    );
    expect(h.channelUtilization, 31, reason: 'own radio reading wins');
    expect(h.channelLevel, HealthLevel.busy);
    expect(h.airtimeLevel, HealthLevel.good);
    expect(h.activeNodes, 1);
    expect(h.quietNodes, 2);
    expect(h.hops, {0: 1, 2: 1, -1: 1});
    expect(h.signal, {SignalBucket.strong: 1, SignalBucket.weak: 1, SignalBucket.unknown: 1});
    expect(h.messagesLastHour, 1);
    expect(h.messagesLastDay, 2);
    expect(h.busiest.first.node, 2);
    expect(h.advice, contains('getting busy'));
  });

  test('without own telemetry the mesh average is used', () {
    final h = MeshHealthSummary.of(
      nodes: _nodes,
      telemetry: const {
        2: BastionDeviceTelemetry(from: 2, channelUtilization: 40),
        3: BastionDeviceTelemetry(from: 3, channelUtilization: 50),
      },
      messages: const [], local: 1, now: _now,
    );
    expect(h.channelUtilization, 45);
    expect(h.channelLevel, HealthLevel.overloaded);
    expect(h.airtimeLevel, HealthLevel.unknown);
    expect(h.advice, contains('very busy'));
  });

  testWidgets('the page explains state without a radio and lays out at large text', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: MeshHealthPage(radio: radio, clock: () => _now)));
    await tester.pumpAndSettle();
    expect(find.textContaining('Connect to a radio to see live readings'), findsOneWidget);
    expect(find.text('Channel busy'), findsOneWidget);
    expect(find.text('Not reported'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
