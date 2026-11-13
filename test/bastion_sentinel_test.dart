import 'dart:convert';

import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/sentinel_page.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/bastion_sentinel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

typedef _Req = ({String method, Uri url, String? body});

void main() {
  late List<_Req> requests;
  late SentinelResponse Function(_Req) respond;
  late DateTime now;
  var refs = 0;

  SentinelResponse json(int status, Object body, {String? retryAfter}) =>
      (status: status, body: jsonEncode(body), retryAfter: retryAfter);
  Map<String, Object?> decisions(List<Object?> bans) =>
      {'network': 'meshtastic', 'advisory': true, 'bans': bans};

  SentinelService make() => SentinelService(
        baseUrl: 'https://relay.test',
        now: () => now,
        newRef: () => 'ref-${++refs}',
        transport: (method, url, body) async {
          final r = (method: method, url: url, body: body);
          requests.add(r);
          return respond(r);
        },
      );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    requests = [];
    refs = 0;
    now = DateTime.utc(2026, 11, 13, 12);
    respond = (_) => json(200, decisions(const []));
  });

  test('node ids use the Meshtastic !hex form', () {
    expect(sentinelNodeId(0xa1b2c3d4), '!a1b2c3d4');
    expect(sentinelNodeId(0x1234), '!00001234');
  });

  test('off by default and makes no requests', () async {
    final s = make();
    await s.start();
    await s.refresh(force: true);
    expect(s.enabled, isFalse);
    expect(requests, isEmpty);
    expect(await s.report(nodeId: '!00000001', reason: SentinelReason.spam), isA<SentinelReportRejected>());
    expect(requests, isEmpty);
    s.dispose();
  });

  test('turning on downloads the ban list, which survives a restart offline', () async {
    respond = (_) => json(200, decisions([
          {'nodeId': '!A1B2C3D4', 'caseRef': 'SNT-1', 'appealPending': true},
          {'nodeId': '', 'caseRef': 'SNT-2'},
          'junk',
        ]));
    final s = make();
    await s.start();
    await s.setEnabled(true);
    await s.syncDecisions(force: true);
    expect(requests.first.url.toString(), 'https://relay.test/v1/meshtastic/decisions');
    expect(s.flaggedCount, 1);
    expect(s.banFor(0xa1b2c3d4)?.appealPending, isTrue);
    expect(s.banFor(0x1), isNull);
    await s.setEnabled(true); // no-op
    s.dispose();

    respond = (_) => throw Exception('offline');
    final again = make();
    await again.start();
    expect(again.banFor(0xa1b2c3d4)?.caseRef, 'SNT-1');
    await again.setEnabled(false);
    again.dispose();
  });

  test('a report sends only the chosen fields; offline ones queue and resend in order', () async {
    var online = true;
    respond = (r) {
      if (!online) throw Exception('offline');
      if (r.url.path.endsWith('/reports')) {
        final ref = (jsonDecode(r.body!) as Map)['externalRef'];
        return json(201, {'caseRef': 'SNT-$ref'});
      }
      return json(200, decisions(const []));
    };
    final s = make();
    await s.start();
    await s.setEnabled(true);
    final sent = await s.report(
        nodeId: '!a1b2c3d4', nodeName: 'Bob', reason: SentinelReason.abuse, note: ' rude ', messageExcerpt: 'x' * 300);
    expect(sent, isA<SentinelReportSent>().having((r) => r.caseRef, 'caseRef', 'SNT-ref-1'));
    final body = jsonDecode(requests.lastWhere((r) => r.url.path.endsWith('/reports')).body!) as Map;
    expect(body['reason'], 'Harassment or abuse: rude');
    expect((body['messageExcerpt'] as String).length, 280);
    expect(body.containsKey('createdAt'), isFalse);

    online = false;
    expect(await s.report(nodeId: '!00000002', reason: SentinelReason.spam), isA<SentinelReportQueued>());
    expect(await s.report(nodeId: '!00000003', reason: SentinelReason.spam), isA<SentinelReportQueued>());
    s.dispose();

    online = true;
    requests.clear();
    final again = make();
    await again.start();
    expect(again.queuedCount, 2);
    expect(await again.flushQueue(), 2);
    expect([for (final r in requests.where((r) => r.url.path.endsWith('/reports'))) (jsonDecode(r.body!) as Map)['externalRef']],
        ['ref-2', 'ref-3']);
    await again.setEnabled(false);
    again.dispose();
  });

  test('400 is dropped, 429 and 5xx are queued', () async {
    var status = 400;
    respond = (r) => r.url.path.endsWith('/reports') ? json(status, {'error': 'Invalid report'}) : json(200, decisions(const []));
    final s = make();
    await s.start();
    await s.setEnabled(true);
    expect(await s.report(nodeId: '!1', reason: SentinelReason.spam),
        isA<SentinelReportRejected>().having((r) => r.message, 'message', 'Invalid report'));
    status = 429;
    expect(await s.report(nodeId: '!1', reason: SentinelReason.spam), isA<SentinelReportQueued>());
    status = 502;
    expect(await s.report(nodeId: '!1', reason: SentinelReason.spam), isA<SentinelReportQueued>());
    expect(s.queuedCount, 2);
    await s.setEnabled(false);
    expect(s.queuedCount, 0);
    s.dispose();
  });

  test('appeal outcomes follow relay status codes', () async {
    var status = 201;
    respond = (r) => r.url.path.endsWith('/appeals') ? json(status, {}) : json(200, decisions(const []));
    final s = make();
    await s.start();
    await s.setEnabled(true);
    Future<SentinelAppealOutcome> go() => s.appeal(caseRef: 'snt-5', statement: 'my beacon');
    expect(await go(), SentinelAppealOutcome.received);
    expect(jsonDecode(requests.lastWhere((r) => r.url.path.endsWith('/appeals')).body!),
        {'caseRef': 'SNT-5', 'statement': 'my beacon'});
    for (final (code, want) in [
      (404, SentinelAppealOutcome.unknownCase),
      (409, SentinelAppealOutcome.notAppealable),
      (429, SentinelAppealOutcome.tooMany),
      (500, SentinelAppealOutcome.failed),
    ]) {
      status = code;
      expect(await go(), want);
    }
    await s.setEnabled(false);
    s.dispose();
  });

  test('hiding flagged senders is opt-in and never hides your own messages', () async {
    respond = (_) => json(200, decisions([{'nodeId': '!00000009', 'caseRef': 'SNT-9'}]));
    final s = make();
    await s.start();
    await s.setEnabled(true);
    await s.syncDecisions(force: true);
    BastionChatMessage msg(BastionMessageDirection d) => BastionChatMessage(
        packetId: 1, from: 9, to: 0xffffffff, channel: 0, text: 'buy',
        timestamp: now, direction: d, deliveryState: BastionDeliveryState.received);
    expect(sentinelHides(s, msg(BastionMessageDirection.incoming)), isFalse);
    await s.setHideFlagged(true);
    expect(sentinelHides(s, msg(BastionMessageDirection.incoming)), isTrue);
    expect(sentinelHides(s, msg(BastionMessageDirection.outgoing)), isFalse);
    await s.setEnabled(false);
    s.dispose();
  });

  testWidgets('report flow: opt-in prompt, then sends the chosen report in Spanish UI', (tester) async {
    final reports = <String>[];
    final s = SentinelService(
      baseUrl: 'https://relay.test',
      transport: (method, url, body) async {
        if (url.path.endsWith('/reports')) {
          reports.add(body!);
          return (status: 201, body: jsonEncode({'caseRef': 'SNT-42'}), retryAfter: null);
        }
        return (status: 200, body: jsonEncode({'bans': []}), retryAfter: null);
      },
    );
    await tester.runAsync(s.start);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Builder(builder: (context) => TextButton(
        onPressed: () => showSentinelReportSheet(context,
            nodeNum: 0xa1b2c3d4, nodeName: 'Spammer', messageExcerpt: 'COMPRA YA', service: s),
        child: const Text('open'),
      ))),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('¿Activar la moderación comunitaria?'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('sentinel-turn-on')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Denunciar a Spammer'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sentinel-reason-flooding')));
    await tester.tap(find.byKey(const ValueKey('sentinel-include-message')));
    await tester.ensureVisible(find.byKey(const ValueKey('sentinel-send-report')));
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey('sentinel-send-report')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Denuncia enviada (SNT-42)'), findsOneWidget);
    final body = jsonDecode(reports.single) as Map;
    expect(body['nodeId'], '!a1b2c3d4');
    expect(body['reason'], 'Flooding the mesh');
    expect(body.containsKey('messageExcerpt'), isFalse);
    await tester.runAsync(() => s.setEnabled(false));
    s.dispose();
  });
}
