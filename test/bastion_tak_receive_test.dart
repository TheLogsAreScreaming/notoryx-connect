import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/map_page.dart';
import 'package:bastion/services/bastion_tak_bridge.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/tak_bridge_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeReceiver implements BastionTakReceiver {
  final controller = StreamController<String>();
  int? port;
  bool closed = false;
  Object? failWith;

  @override
  Future<Stream<String>> listen(int port) async {
    if (failWith case final error?) throw error;
    this.port = port;
    return controller.stream;
  }

  @override
  void close() => closed = true;
}

String cot({
  String uid = 'ANDROID-1234',
  String type = 'a-f-G-U-C',
  String callsign = 'Alpha 1',
  String lat = '35.1',
  String lon = '-80.2',
  String stale = '2026-11-13T12:05:00Z',
}) =>
    '<?xml version="1.0"?><event version="2.0" uid="$uid" type="$type" how="h-e" '
    'time="2026-11-13T12:00:00Z" start="2026-11-13T12:00:00Z" stale="$stale">'
    '<point lat="$lat" lon="$lon" hae="0" ce="9999999.0" le="9999999.0"/>'
    '<detail><contact callsign="$callsign"/></detail></event>';

void main() {
  var now = DateTime.utc(2026, 11, 13, 12);
  late FakeReceiver receiver;
  late BastionTakBridge bridge;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    now = DateTime.utc(2026, 11, 13, 12);
    receiver = FakeReceiver();
    bridge = BastionTakBridge(receiver: () => receiver, now: () => now);
  });
  tearDown(() => bridge.dispose());

  group('reading CoT from ATAK', () {
    test('reads the callsign, position, side and stale time', () {
      final m = BastionCotReader.read(cot(), now)!;
      expect((m.uid, m.callsign, m.latitude, m.longitude), ('ANDROID-1234', 'Alpha 1', 35.1, -80.2));
      expect(m.affiliation, TakAffiliation.friendly);
      expect(m.isPoint, isFalse);
      expect(m.stale.toUtc(), DateTime.utc(2026, 11, 13, 12, 5));
    });

    test('knows hostile, neutral, unknown and map points', () {
      expect(BastionCotReader.read(cot(type: 'a-h-G'), now)!.affiliation, TakAffiliation.hostile);
      expect(BastionCotReader.read(cot(type: 'a-n-G'), now)!.affiliation, TakAffiliation.neutral);
      expect(BastionCotReader.read(cot(type: 'a-u-G'), now)!.affiliation, TakAffiliation.unknown);
      expect(BastionCotReader.read(cot(type: 'b-m-p-s-m'), now)!.isPoint, isTrue);
    });

    test('decodes escaped callsigns and falls back to the UID', () {
      expect(BastionCotReader.read(cot(callsign: 'R&amp;D &lt;1&gt;'), now)!.callsign, 'R&D <1>');
      expect(BastionCotReader.read(cot(callsign: ''), now)!.callsign, 'ANDROID-1234');
    });

    test('ignores our own echoes, pings, stale, impossible and broken events', () {
      expect(BastionCotReader.read(cot(uid: 'NOTORYX-00000abc'), now), isNull);
      expect(BastionCotReader.read(cot(type: 't-x-c-t'), now), isNull);
      expect(BastionCotReader.read(cot(stale: '2026-11-13T11:59:00Z'), now), isNull);
      expect(BastionCotReader.read(cot(lat: '91'), now), isNull);
      expect(BastionCotReader.read(cot(lat: '0', lon: '0'), now), isNull);
      expect(BastionCotReader.read(cot(lat: 'NaN'), now), isNull);
      expect(BastionCotReader.read('<event uid="x" type="a-f"/>', now), isNull);
      expect(BastionCotReader.read('not xml at all', now), isNull);
      expect(BastionCotReader.read(cot() + ' ' * BastionCotReader.maxBytes, now), isNull);
    });

    test('a marker that claims to stay fresh for a year is cut to a day', () {
      final m = BastionCotReader.read(cot(stale: '2027-11-13T12:00:00Z'), now)!;
      expect(m.stale.toUtc(), DateTime.utc(2026, 11, 14, 12));
    });
  });

  group('receiving', () {
    test('is off by default and listens nowhere', () {
      expect(bridge.receive, isFalse);
      expect(receiver.port, isNull);
    });

    test('shows markers once turned on, updates them by UID and drops them when stale', () async {
      await bridge.configure(receive: true);
      expect(receiver.port, BastionTakBridge.defaultReceivePort);
      receiver.controller.add(cot());
      receiver.controller.add(cot(uid: 'B', callsign: 'Bravo'));
      receiver.controller.add(cot(lat: '35.2'));
      await pumpEventQueue();
      expect(bridge.markers.map((m) => m.callsign), unorderedEquals(['Alpha 1', 'Bravo']));
      expect(bridge.markers.firstWhere((m) => m.uid == 'ANDROID-1234').latitude, 35.2);
      now = now.add(const Duration(minutes: 6));
      expect(bridge.markers, isEmpty);
    });

    test('keeps at most the newest markers', () {
      for (var i = 0; i < BastionTakBridge.maxMarkers + 5; i++) {
        bridge.handle(cot(uid: 'U$i'));
      }
      expect(bridge.markers, hasLength(BastionTakBridge.maxMarkers));
      expect(bridge.markers.any((m) => m.uid == 'U0'), isFalse);
    });

    test('turning it off stops listening and forgets markers', () async {
      await bridge.configure(receive: true);
      bridge.handle(cot());
      await bridge.configure(receive: false);
      expect(receiver.closed, isTrue);
      expect(bridge.markers, isEmpty);
    });

    test('a port that cannot be opened is reported, not thrown', () async {
      receiver.failWith = const SocketException('in use');
      await bridge.configure(receive: true);
      expect(bridge.receiveProblem, contains('in use'));
    });

    test('settings survive a restart', () async {
      await bridge.configure(receive: true, receivePort: 5000);
      final next = BastionTakBridge(receiver: FakeReceiver.new);
      await next.load();
      expect((next.receive, next.receivePort), (true, 5000));
      next.dispose();
    });
  });

  test('the real receiver only hears this phone', () async {
    final real = BastionLoopbackTakReceiver();
    addTearDown(real.close);
    final probe = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = probe.port;
    probe.close();
    final stream = await real.listen(port);
    final got = stream.first;
    final sender = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(sender.close);
    sender.send(utf8.encode('<event/>'), InternetAddress.loopbackIPv4, port);
    expect(await got.timeout(const Duration(seconds: 5)), '<event/>');
  });

  Widget app(Widget home, {Locale? locale}) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  testWidgets('the page turns receiving on and refuses the send port', (tester) async {
    await tester.pumpWidget(app(TakBridgePage(bridge: bridge)));
    await tester.scrollUntilVisible(find.byKey(const ValueKey('tak-receive')), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('tak-receive')));
    await tester.pumpAndSettle();
    expect(bridge.receive, isTrue);
    expect(find.text('Listening. No markers yet.'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('tak-receive-port')), '${BastionTakBridge.defaultPort}');
    await tester.tap(find.text('Save').last);
    await tester.pump();
    expect(find.text('Use a different port from the one positions are sent to.'), findsOneWidget);
    expect(bridge.receivePort, BastionTakBridge.defaultReceivePort);
  });

  testWidgets('ATAK markers show on the map with their side in words', (tester) async {
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await bridge.configure(receive: true);
    bridge.handle(cot(type: 'a-h-G', callsign: 'Bandit'));
    await tester.pumpWidget(
      app(
        Scaffold(
          body: MapPage(radio: radio, tak: bridge),
        ),
        locale: const Locale('es'),
      ),
    );
    await tester.pump();
    expect(find.text('Bandit'), findsOneWidget);
    expect(find.bySemanticsLabel('ATAK Hostil: Bandit'), findsOneWidget);
    await tester.tap(find.text('Bandit'));
    await tester.pumpAndSettle();
    expect(find.textContaining('a-h-G'), findsOneWidget);
  });
}
