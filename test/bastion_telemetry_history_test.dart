import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bastion/generated/meshtastic/mesh.pb.dart';
import 'package:bastion/generated/meshtastic/portnums.pbenum.dart';
import 'package:bastion/generated/meshtastic/telemetry.pb.dart';
import 'package:bastion/main.dart';
import 'package:bastion/services/bastion_telemetry_codec.dart';
import 'package:bastion/services/bastion_telemetry_history.dart';
import 'package:bastion/services/bastion_units.dart';
import 'package:bastion/telemetry_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const radio = 0xA1A1A1A1;
const other = 0xB2B2B2B2;

Uint8List packet(int from, Telemetry telemetry) => MeshPacket(
      from: from,
      decoded: Data(portnum: PortNum.TELEMETRY_APP, payload: telemetry.writeToBuffer()),
    ).writeToBuffer();

void main() {
  final now = DateTime.utc(2026, 11, 6, 12);
  int secs(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('reads device and environment metrics; external power is not a level', () {
    final readings = TelemetryMetric.readingsOf(Telemetry(
      deviceMetrics: DeviceMetrics(batteryLevel: 101, voltage: 4.9, channelUtilization: 12.5),
    ));
    expect(readings.keys, [TelemetryMetric.voltage, TelemetryMetric.channelUtilization]);

    final env = BastionTelemetryCodec.decodeReadings(packet(0x77, Telemetry(
      time: secs(now),
      environmentMetrics: EnvironmentMetrics(temperature: 21.5, relativeHumidity: 40, barometricPressure: 1013.2, iaq: 50),
    )))!;
    expect(env.from, 0x77);
    expect(env.time, secs(now));
    expect(env.readings, {
      TelemetryMetric.temperature: 21.5,
      TelemetryMetric.humidity: 40,
      TelemetryMetric.pressure: closeTo(1013.2, 0.01),
      TelemetryMetric.iaq: 50,
    });
  });

  test('other ports and malformed payloads are not telemetry', () {
    final text = MeshPacket(from: 1, decoded: Data(portnum: PortNum.TEXT_MESSAGE_APP, payload: [104, 105])).writeToBuffer();
    expect(BastionTelemetryCodec.decodeReadings(text), isNull);
    final bad = MeshPacket(from: 1, decoded: Data(portnum: PortNum.TELEMETRY_APP, payload: [0xff, 0xff])).writeToBuffer();
    expect(BastionTelemetryCodec.decodeReadings(bad), isNull);
  });

  test('formats values and temperature follows the units setting', () {
    expect(TelemetryMetric.temperature.format(20, BastionUnits.metric), '20.0 °C');
    expect(TelemetryMetric.temperature.format(20, BastionUnits.imperial), '68.0 °F');
    expect(TelemetryMetric.battery.format(87, BastionUnits.metric), '87%');
    expect(TelemetryMetric.voltage.format(4.123, BastionUnits.metric), '4.12 V');
    expect(TelemetryMetric.iaq.format(50, BastionUnits.metric), '50');
  });

  test('records readings by node and metric, saved per radio', () async {
    var clock = now;
    final history = BastionTelemetryHistory(clock: () => clock);
    await history.useRadio(radio);
    history.record(7, {TelemetryMetric.battery: 90, TelemetryMetric.temperature: 20},
        sampleTime: secs(now.subtract(const Duration(hours: 1))));
    clock = now.add(const Duration(minutes: 30));
    history.record(7, {TelemetryMetric.battery: 85});
    // The same sample again (a replay) is not added twice.
    history.record(7, {TelemetryMetric.battery: 90}, sampleTime: secs(now.subtract(const Duration(hours: 1))));
    expect(history.metricsOf(7), [TelemetryMetric.battery, TelemetryMetric.temperature]);
    expect([for (final p in history.seriesOf(7, TelemetryMetric.battery)) p.value], [90, 85]);
    await history.flush();

    final reloaded = BastionTelemetryHistory(clock: () => clock);
    await reloaded.useRadio(radio);
    expect(reloaded.seriesOf(7, TelemetryMetric.battery), hasLength(2));
    await reloaded.useRadio(other);
    expect(reloaded.metricsOf(7), isEmpty);
  });

  test('implausible sender clocks use the time received', () async {
    final history = BastionTelemetryHistory(clock: () => now);
    await history.useRadio(radio);
    history.record(7, {TelemetryMetric.battery: 50}, sampleTime: 12);
    history.record(8, {TelemetryMetric.battery: 50}, sampleTime: secs(now.add(const Duration(days: 2))));
    expect(history.seriesOf(7, TelemetryMetric.battery).single.time, now);
    expect(history.seriesOf(8, TelemetryMetric.battery).single.time, now);
  });

  test('keeps 7 days and at most 300 readings per metric', () async {
    var clock = now;
    final history = BastionTelemetryHistory(clock: () => clock);
    await history.useRadio(radio);
    for (var i = 0; i < 350; i++) {
      clock = now.add(Duration(minutes: i));
      history.record(7, {TelemetryMetric.voltage: 4 + i / 1000});
    }
    expect(history.seriesOf(7, TelemetryMetric.voltage), hasLength(BastionTelemetryHistory.maxPoints));
    clock = now.add(const Duration(days: 8));
    history.record(7, {TelemetryMetric.battery: 50});
    expect(history.seriesOf(7, TelemetryMetric.voltage), isEmpty);
  });

  test('a replaced radio\'s history merges into the new one', () async {
    final first = BastionTelemetryHistory(clock: () => now);
    await first.useRadio(other);
    first.record(7, {TelemetryMetric.temperature: 18}, sampleTime: secs(now.subtract(const Duration(hours: 2))));
    await first.flush();

    final history = BastionTelemetryHistory(clock: () => now);
    await history.useRadio(radio);
    history.record(7, {TelemetryMetric.temperature: 21});
    expect(await history.importRadio(other), isTrue);
    expect([for (final p in history.seriesOf(7, TelemetryMetric.temperature)) p.value], [18, 21]);
    expect(await SharedPreferencesAsync().getString(BastionTelemetryHistory.key(radio)), contains('temperature'));
  });

  testWidgets('the card says when nothing is saved yet', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TelemetryHistoryCard(metrics: const [], series: (_) => const []))));
    expect(find.textContaining('No readings saved yet'), findsOneWidget);
  });

  testWidgets('the card charts the chosen metric and speaks a summary', (tester) async {
    final battery = [for (var i = 0; i < 12; i++) TelemetryPoint(now.add(Duration(minutes: 30 * i)), 95.0 - i * 2)];
    final temperature = [TelemetryPoint(now, 18), TelemetryPoint(now.add(const Duration(hours: 1)), 21)];
    final boundary = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(390, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(RepaintBoundary(key: boundary, child: MaterialApp(
      theme: BastionApp.appearance(Brightness.dark),
      home: Scaffold(body: TelemetryHistoryCard(
        metrics: const [TelemetryMetric.battery, TelemetryMetric.temperature],
        series: (m) => m == TelemetryMetric.battery ? battery : temperature,
      )),
    )));
    expect(find.text('73% now'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Battery: latest 73%, 12 readings over 5 h 30 min, from 73% to 95%')), findsOneWidget);
    await tester.tap(find.text('Temperature'));
    await tester.pump();
    expect(find.text('21.0 °C now'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    final out = Platform.environment['PREVIEW_OUT'];
    if (out != null) {
      await tester.tap(find.text('Battery'));
      await tester.pump();
      await tester.runAsync(() async {
        final ro = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await ro.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$out/telemetry_chart.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
  });
}
