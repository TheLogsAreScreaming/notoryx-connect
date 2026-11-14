import 'dart:typed_data';

import 'package:bastion/generated/meshtastic/config.pb.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/radio_backup_page.dart';
import 'package:bastion/services/bastion_app_lock.dart';
import 'package:bastion/services/bastion_identity_key.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(Uint8List, Uint8List)> keyPair(int seed) async {
  final priv = Uint8List.fromList(List.generate(32, (i) => (i * 7 + seed) & 0xff));
  final pair = await X25519().newKeyPairFromSeed(priv);
  final pub = Uint8List.fromList((await pair.extractPublicKey()).bytes);
  return (priv, pub);
}

class FakeRadio implements IdentityKeyGateway {
  FakeRadio(this.security, {this.node = 0x1234});
  Config_SecurityConfig security;
  final int node;
  bool ignoreWrites = false;
  int writes = 0;
  int reads = 0;
  final others = <int, Uint8List>{};

  @override
  int get identityNodeNum => node;
  @override
  String? get firmwareVersion => '2.7.15.567b8ea';
  @override
  Future<Config_SecurityConfig> readSecurity() async {
    reads++;
    return security.deepCopy();
  }

  @override
  Future<void> writeSecurity(Config_SecurityConfig s) async {
    writes++;
    if (!ignoreWrites) security = s.deepCopy();
  }

  @override
  Future<void> waitForIdentityRadio(int nodeNum) async {}
  @override
  Iterable<int> nodesUsing(Uint8List publicKey) => [
    for (final e in others.entries)
      if (e.value.length == publicKey.length &&
          List.generate(32, (i) => e.value[i] == publicKey[i]).every((x) => x))
        e.key,
  ];
}

class FakeAuth implements BastionDeviceAuth {
  FakeAuth({this.available = true, this.allow = true});
  final bool available, allow;
  int asked = 0;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<bool> authenticate(String reason) async {
    asked++;
    return allow;
  }
}

void main() {
  group('service', () {
    test('backs up a whole key pair and never prints the private key', () async {
      final (priv, pub) = await keyPair(1);
      final radio = FakeRadio(Config_SecurityConfig(privateKey: priv, publicKey: pub));
      final backup = await BastionIdentityKey.capture(radio, clock: () => DateTime.utc(2026, 11, 14));
      expect(backup.nodeNum, 0x1234);
      expect(backup.toString(), isNot(contains(backup.privateKey.first.toRadixString(16).padLeft(2, '0') * 2)));
      expect(backup.toString(), contains('private key hidden'));
      final again = IdentityKeyBackup.decode(backup.encode());
      expect(again.privateKey, priv);
      expect(again.publicKey, pub);
      expect(again.fingerprint, backup.fingerprint);
    });

    test('refuses a radio with no key or a mismatched pair', () async {
      final (priv, _) = await keyPair(1);
      final (_, otherPub) = await keyPair(2);
      expect(
        () => BastionIdentityKey.capture(FakeRadio(Config_SecurityConfig())),
        throwsA(isA<IdentityKeyException>().having((e) => e.problem, 'problem', IdentityKeyProblem.noKey)),
      );
      expect(
        () => BastionIdentityKey.capture(
            FakeRadio(Config_SecurityConfig(privateKey: priv, publicKey: otherPub))),
        throwsA(isA<IdentityKeyException>().having((e) => e.problem, 'problem', IdentityKeyProblem.mismatch)),
      );
    });

    test('rejects text that is not a key backup', () {
      for (final text in ['', 'hello', '{"format":"other"}', '{"format":"notoryx-identity-key","version":1}']) {
        expect(() => IdentityKeyBackup.decode(text), throwsA(isA<IdentityKeyException>()), reason: text);
      }
    });

    test('restore keeps other security settings and confirms by reading back', () async {
      final (oldPriv, oldPub) = await keyPair(3);
      final (priv, pub) = await keyPair(4);
      final radio = FakeRadio(Config_SecurityConfig(
          privateKey: oldPriv, publicKey: oldPub, isManaged: true, serialEnabled: true));
      final backup = IdentityKeyBackup(nodeNum: 0x99, publicKey: pub, privateKey: priv, createdAt: DateTime(2026));
      await BastionIdentityKey.restore(radio, backup);
      expect(radio.security.privateKey, priv);
      expect(radio.security.publicKey, pub);
      expect(radio.security.isManaged, isTrue);
      expect(radio.security.serialEnabled, isTrue);
    });

    test('a radio that ignores the write is reported, not assumed', () async {
      final (oldPriv, oldPub) = await keyPair(3);
      final (priv, pub) = await keyPair(4);
      final radio = FakeRadio(Config_SecurityConfig(privateKey: oldPriv, publicKey: oldPub))..ignoreWrites = true;
      final backup = IdentityKeyBackup(nodeNum: 0x99, publicKey: pub, privateKey: priv, createdAt: DateTime(2026));
      expect(
        () => BastionIdentityKey.restore(radio, backup),
        throwsA(isA<IdentityKeyException>().having((e) => e.problem, 'problem', IdentityKeyProblem.notApplied)),
      );
    });

    test('a damaged backup is never written', () async {
      final (priv, _) = await keyPair(5);
      final (_, otherPub) = await keyPair(6);
      final radio = FakeRadio(Config_SecurityConfig());
      final bad = IdentityKeyBackup(nodeNum: 1, publicKey: otherPub, privateKey: priv, createdAt: DateTime(2026));
      await expectLater(BastionIdentityKey.restore(radio, bad), throwsA(isA<IdentityKeyException>()));
      expect(radio.writes, 0);
    });

    test('warns about another node already using the key', () async {
      final (priv, pub) = await keyPair(7);
      final radio = FakeRadio(Config_SecurityConfig())
        ..others[0xabc] = pub
        ..others[0x1234] = pub;
      final backup = IdentityKeyBackup(nodeNum: 0xabc, publicKey: pub, privateKey: priv, createdAt: DateTime(2026));
      expect(BastionIdentityKey.duplicates(radio, backup), [0xabc]);
    });
  });

  group('page', () {
    Future<void> open(WidgetTester tester, FakeRadio identity, FakeAuth auth) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final radio = MeshtasticRadioCoordinator();
      addTearDown(radio.dispose);
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RadioBackupPage(radio: radio, identity: identity, deviceAuth: auth),
      ));
      await tester.enterText(find.widgetWithText(TextField, 'Backup password (at least 12 characters)'),
          'correct horse battery');
      await tester.tap(find.text('Identity key (separate backup)'));
      await tester.pumpAndSettle();
    }

    testWidgets('without a screen lock the key is never read', (tester) async {
      final identity = FakeRadio(Config_SecurityConfig());
      await open(tester, identity, FakeAuth(available: false));
      await tester.tap(find.byKey(const ValueKey('identity-backup')));
      await tester.pumpAndSettle();
      expect(identity.reads, 0);
      expect(find.textContaining('Set a screen lock'), findsOneWidget);
    });

    testWidgets('a refused confirmation reads nothing', (tester) async {
      final identity = FakeRadio(Config_SecurityConfig());
      final auth = FakeAuth(allow: false);
      await open(tester, identity, auth);
      await tester.tap(find.byKey(const ValueKey('identity-backup')));
      await tester.pumpAndSettle();
      expect(auth.asked, 1);
      expect(identity.reads, 0);
      expect(find.textContaining('Not confirmed'), findsOneWidget);
    });
  });
}
