import 'package:bastion/drive_page.dart';
import 'package:bastion/generated/meshtastic/mesh.pb.dart' as pb;
import 'package:bastion/generated/meshtastic/mesh.pbenum.dart'
    show Routing_Error;
import 'package:bastion/generated/meshtastic/portnums.pbenum.dart';
import 'package:bastion/services/bastion_drive_check.dart';
import 'package:bastion/services/bastion_drive_log.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/bastion_phone_position.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/theme/notoryx_theme.dart';
import 'package:flutter/material.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final t0 = DateTime.utc(2026, 11, 22, 15);
const target = 0x1234abcd;

PhoneFix fix(double lat, {DateTime? at}) => PhoneFix(
  latitude: lat,
  longitude: -80.8,
  time: at ?? t0,
  accuracyMeters: 8,
);

pb.MeshPacket heard(int from, {int hopLimit = 3, DateTime? at}) =>
    pb.MeshPacket(
      from: from,
      id: 7,
      rxTime: (at ?? t0).millisecondsSinceEpoch ~/ 1000,
      rxSnr: -3,
      rxRssi: -100,
      hopStart: 3,
      hopLimit: hopLimit,
    );

pb.MeshPacket answer(
  int from,
  int requestId, {
  int hopLimit = 3,
  Routing_Error error = Routing_Error.NONE,
}) => pb.MeshPacket(
  from: from,
  hopStart: 3,
  hopLimit: hopLimit,
  rxSnr: 4.5,
  decoded: pb.Data(
    portnum: PortNum.ROUTING_APP,
    requestId: requestId,
    payload: pb.Routing(errorReason: error).writeToBuffer(),
  ),
);

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  /// A drive that has heard [target] directly far away (so the check's own
  /// squares have no recent direct reading), with the check on.
  Future<(BastionDriveCheck, List<pb.MeshPacket>)> ready({
    bool enable = true,
  }) async {
    final log = BastionDriveLog();
    await log.load(useDatabase: false);
    await log.start(42, now: t0);
    await log.observe(heard(target), fix(36.0), t0);
    final sent = <pb.MeshPacket>[];
    final check = BastionDriveCheck(log: log)
      ..send = (frame) async => sent.add(pb.ToRadio.fromBuffer(frame).packet);
    if (enable) {
      check
        ..setEnabled(true)
        ..setTarget(target);
    }
    return (check, sent);
  }

  test('is off by default and sends nothing', () async {
    final (check, sent) = await ready(enable: false);
    check.setTarget(target);
    expect(check.enabled, isFalse);
    expect(await check.onFix(fix(35.2), now: t0), isFalse);
    expect(sent, isEmpty);
  });

  test(
    'sends one direct packet with hop limit 0 and an ACK request, never a broadcast',
    () async {
      final (check, sent) = await ready();
      expect(await check.onFix(fix(35.2), now: t0), isTrue);
      final p = sent.single;
      expect(p.to, target);
      expect(p.hopLimit, 0);
      expect(p.wantAck, isTrue);
      expect(p.decoded.portnum, PortNum.PRIVATE_APP);
      expect(check.waiting, isTrue);
    },
  );

  test('only nodes heard directly on this drive can be checked', () async {
    final (check, sent) = await ready();
    check.setTarget(0x55);
    expect(check.candidates, [target]);
    expect(await check.onFix(fix(35.2), now: t0), isFalse);
    expect(check.pause, DriveCheckPause.noTarget);
    expect(sent, isEmpty);
  });

  test('waits 30 s and 25 m between checks', () async {
    final (check, sent) = await ready();
    await check.onFix(fix(35.2), now: t0);
    check.onPacket(answer(target, sent.last.id));
    expect(
      await check.onFix(fix(35.21), now: t0.add(const Duration(seconds: 10))),
      isFalse,
      reason: 'too soon',
    );
    expect(
      await check.onFix(
        fix(35.20001),
        now: t0.add(const Duration(seconds: 40)),
      ),
      isFalse,
      reason: 'about 1 m',
    );
    expect(
      await check.onFix(fix(35.21), now: t0.add(const Duration(seconds: 40))),
      isTrue,
    );
    expect(sent, hasLength(2));
  });

  test('skips a square with a direct reading in the last 7 days', () async {
    final (check, sent) = await ready();
    expect(await check.onFix(fix(36.0), now: t0), isFalse);
    expect(sent, isEmpty);
  });

  test('pauses while the channel is over 25% busy', () async {
    final (check, sent) = await ready();
    expect(
      await check.onFix(fix(35.2), now: t0, channelUtilization: 31),
      isFalse,
    );
    expect(check.pause, DriveCheckPause.busyChannel);
    expect(
      await check.onFix(fix(35.2), now: t0, channelUtilization: 12),
      isTrue,
    );
    expect(check.pause, isNull);
    expect(sent, hasLength(1));
  });

  test(
    'a direct answer from the node is two-way; a relayed one is not',
    () async {
      final (check, sent) = await ready();
      await check.onFix(fix(35.2), now: t0);
      check.onPacket(answer(target, sent.last.id));
      await check.onFix(fix(35.21), now: t0.add(const Duration(minutes: 1)));
      check.onPacket(answer(target, sent.last.id, hopLimit: 1));
      expect(
        [for (final r in check.results) r.outcome],
        [DriveCheckOutcome.twoWay, DriveCheckOutcome.answeredRelayed],
      );
      expect(check.results.first.snr, 4.5);
      expect(check.results.first.latitude, 35.2);
    },
  );

  test(
    "the local radio's own OK is ignored; its failure means no answer",
    () async {
      final (check, sent) = await ready();
      await check.onFix(fix(35.2), now: t0);
      check.onPacket(answer(42, sent.last.id));
      expect(check.waiting, isTrue);
      check.onPacket(
        answer(42, sent.last.id, error: Routing_Error.MAX_RETRANSMIT),
      );
      expect(check.results.single.outcome, DriveCheckOutcome.noAnswer);
    },
  );

  test('answers to other packets are ignored', () async {
    final (check, sent) = await ready();
    await check.onFix(fix(35.2), now: t0);
    check.onPacket(answer(target, sent.last.id + 1));
    expect(check.waiting, isTrue);
    expect(check.results, isEmpty);
  });

  test('no answer within the timeout is recorded', () {
    fakeAsync((async) {
      late BastionDriveCheck check;
      ready().then((r) => check = r.$1);
      async.flushMicrotasks();
      check.onFix(fix(35.2), now: t0);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 31));
      expect(check.results.single.outcome, DriveCheckOutcome.noAnswer);
      expect(check.waiting, isFalse);
    });
  });

  test('reset turns it off and forgets results', () async {
    final (check, sent) = await ready();
    await check.onFix(fix(35.2), now: t0);
    check.onPacket(answer(target, sent.last.id));
    check.reset();
    expect(check.enabled, isFalse);
    expect(check.target, isNull);
    expect(check.results, isEmpty);
  });

  testWidgets(
    'the drive screen shows the check off, and lists only direct nodes once on',
    (tester) async {
      final log = BastionDriveLog.instance;
      log.useStore(MemoryDriveLogStore());
      addTearDown(() => log.useStore(MemoryDriveLogStore()));
      await log.load(useDatabase: false);
      await log.start(42, now: t0);
      await log.observe(heard(target), fix(36.0), t0);
      await log.observe(heard(0x99, hopLimit: 1), fix(36.0), t0);
      tester.view.physicalSize = const Size(600, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final radio = MeshtasticRadioCoordinator();
      addTearDown(radio.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: NotoryxTheme.build(Brightness.dark),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DrivePage(radio: radio, tiles: false),
        ),
      );
      await tester.pump();
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('drive-check-switch')),
            )
            .value,
        isFalse,
      );
      expect(find.byKey(const ValueKey('drive-check-target')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('drive-check-switch')));
      await tester.pump();
      expect(radio.driveCheck.enabled, isTrue);
      expect(radio.driveCheck.candidates, [target]);
      expect(find.text('Pick a node to start checking.'), findsOneWidget);
      await log.stop(now: t0);
    },
  );
}
