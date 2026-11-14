import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../generated/meshtastic/config.pb.dart';

/// Why an identity key backup or restore stopped.
enum IdentityKeyProblem {
  /// The radio has no 32-byte key pair to back up (PKI off or old firmware).
  noKey,

  /// The private key doesn't produce the public key stored with it: the
  /// backup is damaged or not a key backup.
  mismatch,

  /// After writing, the radio reported a different public key.
  notApplied,

  /// The text isn't an identity key backup.
  badFormat,
}

class IdentityKeyException implements Exception {
  const IdentityKeyException(this.problem);
  final IdentityKeyProblem problem;
  @override
  String toString() => 'IdentityKeyException(${problem.name})';
}

/// A radio's identity: the key pair that makes it the same node to
/// everyone on the mesh. Kept apart from settings backups on purpose: two
/// radios with one key confuse the mesh and break direct messages.
///
/// [toString] never shows the private key, so it can't end up in logs.
class IdentityKeyBackup {
  IdentityKeyBackup({
    required this.nodeNum,
    required this.publicKey,
    required Uint8List privateKey,
    required this.createdAt,
    this.firmware,
  }) : _privateKey = privateKey;

  static const format = 'notoryx-identity-key';
  static const version = 1;

  final int nodeNum;
  final Uint8List publicKey;
  final Uint8List _privateKey;
  final DateTime createdAt;
  final String? firmware;

  Uint8List get privateKey => _privateKey;

  /// The first bytes of the public key in hex, for people to compare.
  String get fingerprint => publicKey
      .take(8)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join(':');

  /// Plain text to encrypt with a password before it leaves the app.
  String encode() => jsonEncode({
    'format': format,
    'version': version,
    'node': nodeNum,
    'public': base64Encode(publicKey),
    'private': base64Encode(_privateKey),
    'createdAt': createdAt.toUtc().toIso8601String(),
    if (firmware != null) 'firmware': firmware,
  });

  static IdentityKeyBackup decode(String text) {
    try {
      final j = jsonDecode(text);
      if (j is! Map || j['format'] != format || j['version'] != version) {
        throw const IdentityKeyException(IdentityKeyProblem.badFormat);
      }
      final pub = base64Decode(j['public'] as String);
      final priv = base64Decode(j['private'] as String);
      if (pub.length != 32 || priv.length != 32) {
        throw const IdentityKeyException(IdentityKeyProblem.badFormat);
      }
      return IdentityKeyBackup(
        nodeNum: j['node'] as int,
        publicKey: pub,
        privateKey: priv,
        createdAt: DateTime.parse(j['createdAt'] as String),
        firmware: j['firmware'] as String?,
      );
    } on IdentityKeyException {
      rethrow;
    } catch (_) {
      throw const IdentityKeyException(IdentityKeyProblem.badFormat);
    }
  }

  @override
  String toString() =>
      'IdentityKeyBackup(!${nodeNum.toRadixString(16)}, $fingerprint, private key hidden)';
}

/// What the identity key flow needs from the radio connection.
abstract interface class IdentityKeyGateway {
  /// The connected radio's node number.
  int get identityNodeNum;
  String? get firmwareVersion;

  /// Reads the security settings straight from the radio, without keeping
  /// a copy in the app.
  Future<Config_SecurityConfig> readSecurity();
  Future<void> writeSecurity(Config_SecurityConfig security);

  /// Waits for [nodeNum] to come back after a write makes it reboot.
  Future<void> waitForIdentityRadio(int nodeNum);

  /// Node numbers on the mesh that announce [publicKey].
  Iterable<int> nodesUsing(Uint8List publicKey);
}

abstract final class BastionIdentityKey {
  /// Whether [privateKey] produces [publicKey] (Curve25519, as the radio
  /// uses for direct messages).
  static Future<bool> matches(Uint8List privateKey, Uint8List publicKey) async {
    final pair = await X25519().newKeyPairFromSeed(privateKey);
    final derived = (await pair.extractPublicKey()).bytes;
    if (derived.length != publicKey.length) return false;
    var same = true;
    for (var i = 0; i < derived.length; i++) {
      same &= derived[i] == publicKey[i];
    }
    return same;
  }

  /// Reads the radio's key pair and checks it is whole.
  static Future<IdentityKeyBackup> capture(
    IdentityKeyGateway radio, {
    DateTime Function()? clock,
  }) async {
    final security = await radio.readSecurity();
    final pub = Uint8List.fromList(security.publicKey);
    final priv = Uint8List.fromList(security.privateKey);
    if (pub.length != 32 || priv.length != 32) {
      throw const IdentityKeyException(IdentityKeyProblem.noKey);
    }
    if (!await matches(priv, pub)) {
      throw const IdentityKeyException(IdentityKeyProblem.mismatch);
    }
    return IdentityKeyBackup(
      nodeNum: radio.identityNodeNum,
      publicKey: pub,
      privateKey: priv,
      createdAt: (clock ?? DateTime.now)(),
      firmware: radio.firmwareVersion,
    );
  }

  /// Other nodes on the mesh already announcing the backup's key. Restoring
  /// it to this radio while one of them is on the air makes two radios
  /// share an identity.
  static List<int> duplicates(IdentityKeyGateway radio, IdentityKeyBackup backup) => [
    for (final n in radio.nodesUsing(backup.publicKey))
      if (n != radio.identityNodeNum) n,
  ];

  /// Puts the backup's key pair on the connected radio, keeping its other
  /// security settings, then reads it back to confirm.
  static Future<void> restore(IdentityKeyGateway radio, IdentityKeyBackup backup) async {
    if (!await matches(backup.privateKey, backup.publicKey)) {
      throw const IdentityKeyException(IdentityKeyProblem.mismatch);
    }
    final node = radio.identityNodeNum;
    final current = await radio.readSecurity();
    final updated = current.deepCopy()
      ..privateKey = backup.privateKey
      ..publicKey = backup.publicKey;
    await radio.writeSecurity(updated);
    await radio.waitForIdentityRadio(node);
    final after = await radio.readSecurity();
    final pub = after.publicKey;
    var same = pub.length == 32;
    for (var i = 0; same && i < 32; i++) {
      same = pub[i] == backup.publicKey[i];
    }
    if (!same) throw const IdentityKeyException(IdentityKeyProblem.notApplied);
  }
}
