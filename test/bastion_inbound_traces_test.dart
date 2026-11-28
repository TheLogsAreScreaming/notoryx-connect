import 'dart:async';
import 'dart:typed_data';

import 'package:bastion/generated/meshtastic/mesh.pb.dart';
import 'package:bastion/generated/meshtastic/portnums.pbenum.dart';
import 'package:bastion/services/bastion_inbound_traces.dart';
import 'package:bastion/services/meshtastic_traceroute.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const local = 0x1;

void main() {
  late StreamController<Uint8List> incoming;
  late List<InboundTraceroute> seen;
  late MeshtasticTraceroute traceroute;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    incoming = StreamController<Uint8List>.broadcast();
    seen = [];
    traceroute = MeshtasticTraceroute(
      incoming: incoming.stream,
      send: (_) async {},
      localNodeNum: local,
      onInbound: seen.add,
      clock: () => DateTime(2026, 11, 27, 9),
    );
  });

  tearDown(() async {
    await traceroute.dispose();
    await incoming.close();
  });

  void packet({
    int from = 0x9,
    int to = local,
    bool wantResponse = true,
    PortNum port = PortNum.TRACEROUTE_APP,
  }) => incoming.add(FromRadio(
    packet: MeshPacket(
      from: from,
      to: to,
      decoded: Data(
        portnum: port,
        wantResponse: wantResponse,
        payload: RouteDiscovery(
          route: [0x5, 0x6],
          snrTowards: [24, -128, 10],
        ).writeToBuffer(),
      ),
    ),
  ).writeToBuffer());

  test('a traceroute another node runs to us is recorded with its relays', () async {
    packet();
    await Future<void>.delayed(Duration.zero);
    final t = seen.single;
    expect(t.from, 0x9);
    expect(t.hops.map((h) => h.nodeNum), [0x5, 0x6, local]);
    expect(t.hops.map((h) => h.snrDb), [6.0, null, 2.5]);
  });

  test('replies, other destinations and other ports are not recorded', () async {
    packet(wantResponse: false);
    packet(to: 0x7);
    packet(from: local);
    packet(port: PortNum.TEXT_MESSAGE_APP);
    await Future<void>.delayed(Duration.zero);
    expect(seen, isEmpty);
  });

  test('history keeps the newest first, survives a reload, and is capped', () async {
    final store = BastionInboundTraces();
    await store.load();
    for (var i = 0; i < BastionInboundTraces.maxKept + 5; i++) {
      await store.add(InboundTraceroute(
        from: i,
        at: DateTime(2026, 1, 1).add(Duration(minutes: i)),
        hops: const [TracerouteHop(local, 4.5)],
      ));
    }
    final reloaded = BastionInboundTraces();
    await reloaded.load();
    expect(reloaded.traces, hasLength(BastionInboundTraces.maxKept));
    expect(reloaded.traces.first.from, BastionInboundTraces.maxKept + 4);
    expect(reloaded.traces.first.hops.single.snrDb, 4.5);
    expect(BastionInboundTraces.storageName, startsWith('bastion.'));
  });
}
