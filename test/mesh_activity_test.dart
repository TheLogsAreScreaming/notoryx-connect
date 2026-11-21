import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/mesh_activity_page.dart';
import 'package:bastion/services/bastion_mesh_watch.dart';
import 'package:bastion/services/bastion_traffic.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final _t0 = DateTime(2026, 11, 20, 12);

TrafficPacket _p(int id, int from, TrafficKind kind,
        {int to = TrafficPacket.broadcast, int? hops, double? snr, bool mqtt = false, Duration ago = Duration.zero}) =>
    TrafficPacket(
      id: id,
      from: from,
      to: to,
      kind: kind,
      path: const [],
      heard: _t0.subtract(ago),
      hopsAway: hops,
      snr: snr,
      viaMqtt: mqtt,
    );

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('field stats summarise the last hour', () {
    final s = FieldStats.of([
      _p(1, 0x20, TrafficKind.channel, hops: 0, snr: 6),
      _p(2, 0x20, TrafficKind.advert, hops: 0, snr: 2),
      _p(3, 0x21, TrafficKind.direct, hops: 2, snr: -9),
      _p(4, 0x22, TrafficKind.channel, hops: 1, mqtt: true, snr: 99),
      _p(5, 0x23, TrafficKind.channel, ago: const Duration(hours: 2)),
    ], _t0);
    expect(s.packets, 4);
    expect(s.senders, 3);
    expect(s.direct, 1);
    expect(s.averageHops, closeTo(0.75, 0.001));
    expect(s.bestSnr, 6, reason: 'MQTT packets have no real signal');
    expect(s.worstSnr, -9);
    expect(s.viaMqtt, 1);
    expect(s.byKind[TrafficKind.channel], 2);
    expect(s.busiest.first, (0x20, 2));
  });

  group('network changes', () {
    late DateTime now;
    late BastionMeshWatch watch;
    setUp(() async {
      now = _t0;
      watch = BastionMeshWatch(clock: () => now);
      await watch.load();
    });

    MeshtasticNode n(int num, String name, Duration ago) =>
        MeshtasticNode(num: num, longName: name, lastHeard: now.subtract(ago));

    test('the first list is the baseline; then new, quiet, back and renamed are recorded', () async {
      watch.checkNodes([
        n(1, 'Me', Duration.zero),
        n(0x20, 'Ridge', const Duration(minutes: 5)),
        n(0x21, 'Old', const Duration(days: 3)),
      ], self: 1);
      expect(watch.changes, isEmpty, reason: 'nothing is news on connecting, not even long-quiet nodes');

      now = now.add(const Duration(minutes: 10));
      watch.checkNodes([
        n(0x20, 'Ridge Relay', const Duration(minutes: 1)),
        n(0x21, 'Old', const Duration(days: 3)),
        n(0x30, 'Camp', Duration.zero),
      ], self: 1);
      expect(watch.changes.map((c) => c.kind), unorderedEquals([NetworkChangeKind.renamed, NetworkChangeKind.appeared]));
      expect(watch.changes.firstWhere((c) => c.kind == NetworkChangeKind.renamed).oldName, 'Ridge');

      now = now.add(const Duration(hours: 3));
      watch.checkNodes([
        MeshtasticNode(num: 0x20, longName: 'Ridge Relay', lastHeard: _t0.add(const Duration(minutes: 9))),
        n(0x30, 'Camp', Duration.zero),
      ], self: 1);
      expect(watch.changes.first.kind, NetworkChangeKind.quiet);
      expect(watch.changes.first.num, 0x20);

      now = now.add(const Duration(minutes: 1));
      watch.checkNodes([n(0x20, 'Ridge Relay', Duration.zero), n(0x30, 'Camp', Duration.zero)], self: 1);
      expect(watch.changes.first.kind, NetworkChangeKind.back);
      expect(watch.changes.where((c) => c.num == 1), isEmpty, reason: 'your own radio is never reported');

      final again = BastionMeshWatch();
      await again.load();
      expect(again.changes, hasLength(watch.changes.length));
    });

    test('a reconnect starts a new baseline', () {
      watch.checkNodes([n(0x20, 'A', Duration.zero)]);
      watch.resetBaseline();
      watch.checkNodes([n(0x20, 'A', Duration.zero), n(0x21, 'B', Duration.zero)]);
      expect(watch.changes, isEmpty);
    });

    test('keeps the newest packets only', () {
      for (var i = 0; i < BastionMeshWatch.keepPackets + 20; i++) {
        watch.addPacket(_p(i, 0x20, TrafficKind.other));
      }
      expect(watch.packets, hasLength(BastionMeshWatch.keepPackets));
      expect(watch.packets.first.id, BastionMeshWatch.keepPackets + 19);
    });
  });

  testWidgets('the page shows stats, changes and packets', (tester) async {
    final watch = BastionMeshWatch(clock: () => _t0);
    watch
      ..addPacket(_p(1, 0x20, TrafficKind.channel, hops: 0, snr: 5))
      ..addPacket(_p(2, 0x21, TrafficKind.direct, to: 0x0a, hops: 2));
    String name(int n) => {0x20: 'Ridge', 0x21: 'Camp', 0x0a: 'Me'}[n] ?? '?';
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MeshActivityPage(watch: watch, nameOf: name),
    ));
    expect(find.text('Packets heard'), findsOneWidget);
    expect(find.text('Ridge'), findsWidgets, reason: 'busiest list');

    await tester.tap(find.text('Changes'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No changes yet'), findsOneWidget);

    await tester.tap(find.text('Packets'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Camp → Me'), findsOneWidget);
    expect(find.textContaining('Ridge → everyone'), findsOneWidget);
    expect(find.textContaining('2 hops'), findsOneWidget);
  });
}
