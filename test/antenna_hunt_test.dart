import 'dart:async';

import 'package:bastion/antenna_hunt_page.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/bastion_traffic.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Radio implements HuntRadio {
  _Radio(this.nodes);
  @override
  final List<MeshtasticNode> nodes;
  @override
  int? get localNodeNum => 1;
  final _packets = StreamController<TrafficPacket>.broadcast();
  @override
  Stream<TrafficPacket> get packets => _packets.stream;
  int asks = 0;
  @override
  Future<double?> askReply(int num) async {
    asks++;
    return 4.5;
  }

  void hear(int from, double snr, {int hops = 0, bool mqtt = false}) => _packets.add(TrafficPacket(
        id: from + snr.round(),
        from: from,
        to: TrafficPacket.broadcast,
        kind: TrafficKind.other,
        path: const [],
        heard: DateTime.now(),
        hopsAway: hops,
        snr: snr,
        rssi: -90,
        viaMqtt: mqtt,
      ));
}

void main() {
  test('clicks speed up with signal, within limits', () {
    expect(clickIntervalFor(-20), const Duration(milliseconds: 1500));
    expect(clickIntervalFor(12), const Duration(milliseconds: 120));
    expect(clickIntervalFor(30), const Duration(milliseconds: 120));
    expect(clickIntervalFor(0) < clickIntervalFor(-10), isTrue);
  });

  Widget app(HuntRadio radio, DateTime Function() clock) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AntennaHuntPage(radio: radio, clock: clock, sounds: false),
      );

  testWidgets('only nodes heard directly can be hunted', (tester) async {
    final radio = _Radio([
      MeshtasticNode(num: 1, longName: 'Me', hopsAway: 0),
      MeshtasticNode(num: 0x20, longName: 'Ridge', hopsAway: 0, lastHeard: DateTime.now()),
      MeshtasticNode(num: 0x21, longName: 'Far', hopsAway: 2),
      MeshtasticNode(num: 0x22, longName: 'Internet', hopsAway: 0, viaMqtt: true),
    ]);
    await tester.pumpWidget(app(radio, DateTime.now));
    expect(find.byKey(const ValueKey('hunt-32')), findsOneWidget);
    expect(find.text('Far'), findsNothing);
    expect(find.text('Internet'), findsNothing);
    expect(find.text('Me'), findsNothing);
  });

  testWidgets('shows how well you hear the node, ignoring relayed and MQTT packets', (tester) async {
    var now = DateTime(2026, 11, 20, 12);
    final radio = _Radio([MeshtasticNode(num: 0x20, longName: 'Ridge', hopsAway: 0, lastHeard: now)]);
    await tester.pumpWidget(app(radio, () => now));
    await tester.tap(find.byKey(const ValueKey('hunt-32')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hunt-toggle')));
    await tester.pump();
    expect(find.text('Waiting for Ridge to transmit…'), findsOneWidget);

    radio.hear(0x20, 3.5);
    await tester.pump();
    expect(find.text('3.5 dB'), findsWidgets);

    radio.hear(0x20, 9, hops: 1);
    radio.hear(0x20, 9, mqtt: true);
    radio.hear(0x21, 9);
    await tester.pump();
    expect(find.text('9.0 dB'), findsNothing);

    radio.hear(0x20, -2);
    await tester.pump();
    final snr = tester.widget<Text>(find.byKey(const ValueKey('hunt-snr')));
    expect(snr.data, '-2.0 dB');
    expect(find.text('3.5 dB'), findsOneWidget, reason: 'best so far');

    now = now.add(const Duration(minutes: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Not heard for a while: clicks stopped.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hunt-toggle')));
    await tester.pump();
  });

  testWidgets('asking for replies is off by default and runs every 30 s when on', (tester) async {
    final radio = _Radio([MeshtasticNode(num: 0x20, longName: 'Ridge', hopsAway: 0)]);
    await tester.pumpWidget(app(radio, DateTime.now));
    await tester.tap(find.byKey(const ValueKey('hunt-32')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hunt-toggle')));
    await tester.pump(const Duration(seconds: 61));
    expect(radio.asks, 0);

    await tester.tap(find.byKey(const ValueKey('hunt-ping')));
    await tester.pump();
    expect(radio.asks, 1);
    await tester.pump(AntennaHuntPage.pingEvery);
    expect(radio.asks, 2);
    expect(find.text('4.5 dB'), findsOneWidget, reason: 'how well it hears you');

    await tester.tap(find.byKey(const ValueKey('hunt-toggle')));
    await tester.pump(const Duration(seconds: 90));
    expect(radio.asks, 2, reason: 'stops with the hunt');
  });
}
