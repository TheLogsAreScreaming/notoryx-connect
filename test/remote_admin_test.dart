import 'dart:async';
import 'dart:typed_data';

import 'package:bastion/generated/meshtastic/admin.pb.dart';
import 'package:bastion/generated/meshtastic/config.pb.dart';
import 'package:bastion/generated/meshtastic/mesh.pb.dart';
import 'package:bastion/generated/meshtastic/portnums.pbenum.dart';
import 'package:bastion/remote_admin_page.dart';
import 'package:bastion/services/bastion_demo_radio.dart';
import 'package:bastion/services/meshtastic_admin_session.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const local = 0x1111;
const remote = 0x2222;
final remoteKey = List<int>.generate(32, (i) => i + 1);

/// A remote node reached through the local radio.
class FakeMesh {
  final incoming = StreamController<Uint8List>.broadcast();
  final sent = <MeshPacket>[];
  final received = <AdminMessage>[];

  /// The node accepts this radio as an admin.
  bool authorized = true;

  /// The local radio fails to deliver with this error instead.
  Routing_Error? localFailure;
  User owner = User(longName: 'Ridge Relay', shortName: 'RDG');
  Config device = Config(device: Config_DeviceConfig(role: Config_DeviceConfig_Role.ROUTER));

  Future<void> send(Uint8List bytes) async {
    final packet = ToRadio.fromBuffer(bytes).packet;
    sent.add(packet);
    final admin = AdminMessage.fromBuffer(packet.decoded.payload);
    received.add(admin);
    scheduleMicrotask(() => _answer(packet.id, admin));
  }

  void _answer(int id, AdminMessage admin) {
    if (localFailure case final error?) {
      return _routing(id, error, from: local);
    }
    if (!authorized) return _routing(id, Routing_Error.NOT_AUTHORIZED);
    const passkey = [7, 7, 7, 7];
    switch (admin.whichPayloadVariant()) {
      case AdminMessage_PayloadVariant.getDeviceMetadataRequest:
        _reply(id, AdminMessage(
          getDeviceMetadataResponse: DeviceMetadata(firmwareVersion: '2.7.4', role: Config_DeviceConfig_Role.ROUTER),
          sessionPasskey: passkey,
        ));
      case AdminMessage_PayloadVariant.getOwnerRequest:
        _reply(id, AdminMessage(getOwnerResponse: owner, sessionPasskey: passkey));
      case AdminMessage_PayloadVariant.getConfigRequest:
        _reply(id, AdminMessage(getConfigResponse: device, sessionPasskey: passkey));
      case AdminMessage_PayloadVariant.setOwner:
        owner = admin.setOwner;
        _routing(id, Routing_Error.NONE);
      default:
        _routing(id, Routing_Error.NONE);
    }
  }

  void _reply(int requestId, AdminMessage admin) => _emit(remote, Data(
        portnum: PortNum.ADMIN_APP, payload: admin.writeToBuffer(), requestId: requestId));

  void _routing(int requestId, Routing_Error error, {int from = remote}) => _emit(from, Data(
        portnum: PortNum.ROUTING_APP,
        payload: Routing(errorReason: error).writeToBuffer(),
        requestId: requestId,
      ));

  void _emit(int from, Data data) => incoming.add(FromRadio(
        packet: MeshPacket(from: from, to: local, decoded: data),
      ).writeToBuffer());
}

MeshtasticAdminSession remoteSession(FakeMesh mesh, {Duration? timeout, Future<void> Function(Duration)? delay}) => MeshtasticAdminSession(
      delay: delay,
      incoming: mesh.incoming.stream,
      send: mesh.send,
      localNodeNum: local,
      targetNodeNum: remote,
      targetPublicKey: remoteKey,
      timeout: timeout,
    );

void main() {
  group('remote admin session', () {
    test('requests go to the node, encrypted to its key', () async {
      final mesh = FakeMesh();
      final admin = remoteSession(mesh);
      addTearDown(admin.dispose);
      final metadata = await admin.getMetadata();
      expect(metadata.firmwareVersion, '2.7.4');
      final packet = mesh.sent.single;
      expect(packet.to, remote);
      expect(packet.pkiEncrypted, isTrue);
      expect(packet.publicKey, remoteKey);
      expect(admin.hasFreshPasskey, isTrue);
      expect(admin.timeout, MeshtasticAdminSession.remoteTimeout);
    });

    test('a write carries the passkey the node gave', () async {
      final mesh = FakeMesh();
      final admin = remoteSession(mesh);
      addTearDown(admin.dispose);
      await admin.setOwner(User(longName: 'Ridge', shortName: 'RG'));
      expect(mesh.received.last.sessionPasskey, [7, 7, 7, 7]);
      expect(mesh.owner.longName, 'Ridge');
    });

    test('a node without our admin key says so plainly', () async {
      final mesh = FakeMesh()..authorized = false;
      final admin = remoteSession(mesh);
      addTearDown(admin.dispose);
      await expectLater(admin.getOwner(), throwsA(isA<MeshtasticAdminException>()
          .having((e) => e.routingError, 'routingError', Routing_Error.NOT_AUTHORIZED)
          .having((e) => e.plainReason, 'plainReason', contains('admin key'))));
    });

    test('the local radio reports delivery failures', () async {
      final mesh = FakeMesh()..localFailure = Routing_Error.MAX_RETRANSMIT;
      final admin = remoteSession(mesh);
      addTearDown(admin.dispose);
      await expectLater(admin.reboot(), throwsA(isA<MeshtasticAdminException>()
          .having((e) => e.plainReason, 'plainReason', contains('didn\'t answer'))));
    });

    test('only the node itself can confirm a write', () async {
      final mesh = FakeMesh()..localFailure = Routing_Error.NONE;
      final admin = remoteSession(mesh, timeout: const Duration(milliseconds: 50));
      addTearDown(admin.dispose);
      await expectLater(admin.getOwner(), throwsA(isA<MeshtasticAdminException>()
          .having((e) => e.message, 'message', contains('The node did not answer'))));
    });

    test('a remote session needs the node\'s public key', () {
      expect(() => MeshtasticAdminSession(
            incoming: const Stream.empty(),
            send: (_) async {},
            localNodeNum: local,
            targetNodeNum: remote,
          ), throwsArgumentError);
    });
  });

  group('airtime', () {
    test('writes in a batch are spaced out', () async {
      final mesh = FakeMesh();
      final waits = <Duration>[];
      final session = remoteSession(mesh, delay: (d) async => waits.add(d));
      await session.setOwner(User(longName: 'One'));
      await session.setOwner(User(longName: 'Two'));
      expect(waits, hasLength(1));
      expect(waits.single, greaterThan(const Duration(seconds: 4)));
    });

    test('an airtime refusal waits and retries once', () async {
      final mesh = FakeMesh();
      final waits = <Duration>[];
      final session = remoteSession(mesh, delay: (d) async {
        waits.add(d);
        if (d == MeshtasticAdminSession.airtimeBackoff) mesh.localFailure = null;
      });
      await session.getOwner();
      mesh.localFailure = Routing_Error.DUTY_CYCLE_LIMIT;
      await session.setOwner(User(longName: 'Later'));
      expect(waits, contains(MeshtasticAdminSession.airtimeBackoff));
      expect(mesh.owner.longName, 'Later');
    });

    test('a second airtime refusal is reported', () async {
      final mesh = FakeMesh();
      final session = remoteSession(mesh, delay: (_) async {});
      await session.getOwner();
      mesh.localFailure = Routing_Error.RATE_LIMIT_EXCEEDED;
      await expectLater(session.setOwner(User(longName: 'No')), throwsA(isA<MeshtasticAdminException>()));
    });
  });

  group('remote admin page', () {
    setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

    test('a disconnected radio explains why remote admin is unavailable', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      final radio = MeshtasticRadioCoordinator();
      addTearDown(radio.dispose);
      expect(radio.remoteAdminProblem(remote), 'Connect to a radio first.');
      expect(() => radio.openRemoteAdmin(remote), throwsStateError);
    });

    testWidgets('shows the reason when it cannot open', (tester) async {
      final radio = BastionDemoRadio();
      addTearDown(radio.dispose);
      await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: RemoteAdminPage(radio: radio, nodeNum: 0xDE300002)));
      expect(find.text('Remote admin isn\'t available'), findsOneWidget);
      expect(find.text('Ridge Relay'), findsOneWidget);
      expect(find.text('Check access'), findsNothing);
    });

    testWidgets('checks access, then renames the node', (tester) async {
      final radio = BastionDemoRadio();
      addTearDown(radio.dispose);
      final mesh = FakeMesh();
      await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: RemoteAdminPage(
        radio: radio, nodeNum: 0xDE300002, openSession: () => remoteSession(mesh))));

      await tester.tap(find.text('Check access'));
      await tester.pumpAndSettle();
      expect(find.text('Access confirmed'), findsOneWidget);
      expect(find.textContaining('2.7.4'), findsOneWidget);
      expect(find.text('Ridge Relay'), findsWidgets);

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Long name'), 'Ridge North');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(mesh.owner.longName, 'Ridge North');
      expect(mesh.owner.shortName, 'RDG');
      expect(find.text('Name sent to the node.'), findsOneWidget);
    });

    testWidgets('a refused node shows a plain error', (tester) async {
      final radio = BastionDemoRadio();
      addTearDown(radio.dispose);
      final mesh = FakeMesh()..authorized = false;
      await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: RemoteAdminPage(
        radio: radio, nodeNum: 0xDE300002, openSession: () => remoteSession(mesh))));
      await tester.tap(find.text('Check access'));
      await tester.pumpAndSettle();
      expect(find.textContaining('hasn\'t added your radio\'s admin key'), findsOneWidget);
      expect(find.text('Access confirmed'), findsNothing);
    });

    testWidgets('opens a settings section and sends edits', (tester) async {
      final radio = BastionDemoRadio();
      addTearDown(radio.dispose);
      final mesh = FakeMesh();
      await tester.pumpWidget(MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: RemoteAdminPage(
        radio: radio, nodeNum: 0xDE300002, openSession: () => remoteSession(mesh))));
      await tester.tap(find.text('Check access'));
      await tester.pumpAndSettle();
      final chip = find.widgetWithText(ChoiceChip, 'Device');
      await tester.scrollUntilVisible(chip, 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(mesh.received.last.getConfigRequest, AdminMessage_ConfigType.DEVICE_CONFIG);
      final send = find.widgetWithText(FilledButton, 'Send Device settings');
      await tester.scrollUntilVisible(send, 300, scrollable: find.byType(Scrollable).first);
      expect(tester.widget<FilledButton>(send).onPressed, isNull, reason: 'nothing edited yet');
    });
  });
}
