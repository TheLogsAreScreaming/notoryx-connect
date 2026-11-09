import 'dart:convert';
import 'dart:io';

import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/bastion_tak_bridge.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/tak_bridge_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:xml/xml.dart';

class FakeSender implements BastionTakSender {
  final sent = <String>[];
  bool closed = false, broken = false;
  @override
  Future<void> send(String xml) async {
    if (broken) throw const SocketException('down');
    sent.add(xml);
  }
  @override
  void close() => closed = true;
}

void main() {
  final now = DateTime.utc(2026, 11, 9, 12);
  MeshtasticNode node({int num = 0xabc, String? name = 'Ridge', double? lat = 35.25, DateTime? at}) => MeshtasticNode(
      num: num, longName: name, latitude: lat, longitude: -80.5, altitudeMeters: 200,
      positionTime: at ?? now.subtract(const Duration(minutes: 2)));
  late FakeSender sender;
  late List<MeshtasticNode> nodes;
  late BastionTakBridge bridge;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    sender = FakeSender();
    nodes = [node()];
    bridge = BastionTakBridge(sender: (_) => sender, now: () => now);
  });
  tearDown(() => bridge.detach());

  group('CoT event', () {
    test('is well-formed with the position, callsign and a five minute stale time', () {
      final event = XmlDocument.parse(BastionCot.event(node(), now)!).rootElement;
      expect(event.getAttribute('uid'), 'NOTORYX-00000abc');
      expect(event.getAttribute('type'), 'a-f-G-U-C');
      expect(event.getAttribute('time'), '2026-11-09T12:00:00Z');
      expect(event.getAttribute('stale'), '2026-11-09T12:05:00Z');
      final point = event.getElement('point')!;
      expect((point.getAttribute('lat'), point.getAttribute('lon'), point.getAttribute('hae')),
          ('35.2500000', '-80.5000000', '200'));
      expect(event.getElement('detail')!.getElement('contact')!.getAttribute('callsign'), 'Ridge');
    });

    test('a hostile node name cannot break out of the XML', () {
      final event = XmlDocument.parse(BastionCot.event(node(name: 'a"/><evil x="<&'), now)!).rootElement;
      expect(event.findAllElements('evil'), isEmpty);
      expect(event.getElement('detail')!.getElement('contact')!.getAttribute('callsign'), 'a"/><evil x="<&');
    });

    test('leaves out missing, old and impossible positions', () {
      expect(BastionCot.event(node(lat: null), now), isNull);
      expect(BastionCot.event(node(at: now.subtract(const Duration(hours: 2))), now), isNull);
      expect(BastionCot.event(node(lat: 91), now), isNull);
      expect(BastionCot.event(MeshtasticNode(num: 1, latitude: 1, longitude: 1), now), isNull);
    });
  });

  group('bridge', () {
    test('is off by default and sends nothing', () async {
      bridge.attach(() => nodes);
      await bridge.publish();
      expect(sender.sent, isEmpty);
    });

    test('sends usable nodes once enabled, and stops when turned off', () async {
      nodes.add(node(num: 2, lat: null));
      bridge.attach(() => nodes);
      await bridge.configure(enabled: true);
      await pumpEventQueue();
      expect(sender.sent, hasLength(1));
      expect(bridge.lastCount, 1);
      await bridge.configure(enabled: false);
      expect(sender.closed, isTrue);
      await bridge.publish();
      expect(sender.sent, hasLength(1));
    });

    test('a send failure is reported, not thrown', () async {
      bridge.attach(() => nodes);
      await bridge.configure(enabled: true);
      await pumpEventQueue();
      sender.broken = true;
      await bridge.publish();
      expect(bridge.problem, contains('down'));
    });

    test('settings survive a restart; a bad port is refused', () async {
      await bridge.configure(enabled: true, port: 6000);
      await bridge.configure(port: 80);
      final next = BastionTakBridge(sender: (_) => sender);
      await next.load();
      expect((next.enabled, next.port), (true, 6000));
      next.detach();
    });
  });

  test('the real sender only talks to this phone', () async {
    final listener = await RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(listener.close);
    final real = BastionLoopbackTakSender(listener.port);
    addTearDown(real.close);
    final got = listener.where((e) => e == RawSocketEvent.read).map((_) => listener.receive()).first;
    await real.send('<event/>');
    final datagram = (await got.timeout(const Duration(seconds: 5)))!;
    expect(utf8.decode(datagram.data), '<event/>');
    expect(datagram.address.isLoopback, isTrue);
  });

  testWidgets('the page turns the feed on and refuses a bad port', (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TakBridgePage(bridge: bridge),
    ));
    await tester.enterText(find.byKey(const ValueKey('tak-port')), '80');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.textContaining('1024'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tak-enabled')));
    await tester.pump();
    expect(bridge.enabled, isTrue);
    expect(bridge.port, BastionTakBridge.defaultPort);
    bridge.detach();
  });
}
