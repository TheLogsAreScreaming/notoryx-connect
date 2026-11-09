import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:protobuf/protobuf.dart';

import '../generated/meshtastic/admin.pb.dart';
import '../generated/meshtastic/channel.pb.dart';
import '../generated/meshtastic/config.pb.dart';
import '../generated/meshtastic/mesh.pb.dart';
import '../generated/meshtastic/module_config.pb.dart';
import '../generated/meshtastic/portnums.pbenum.dart';

class MeshtasticSettingsUnavailable implements Exception {
  const MeshtasticSettingsUnavailable(this.section);
  final String section;
  @override
  String toString() => '$section settings are unavailable through this radio’s firmware API.';
}

class MeshtasticAdminException implements Exception {
  MeshtasticAdminException(this.message, {this.routingError});

  final String message;

  /// The mesh routing error behind this failure, when there was one.
  final Routing_Error? routingError;

  /// A plain-language reason for showing to people.
  String get plainReason => switch (routingError) {
        Routing_Error.NOT_AUTHORIZED || Routing_Error.ADMIN_PUBLIC_KEY_UNAUTHORIZED =>
          'The node refused: it hasn\'t added your radio\'s admin key.',
        Routing_Error.PKI_FAILED || Routing_Error.PKI_UNKNOWN_PUBKEY ||
        Routing_Error.PKI_SEND_FAIL_PUBLIC_KEY =>
          'Your radio couldn\'t encrypt for this node. Wait until it has heard the node\'s key, then try again.',
        Routing_Error.ADMIN_BAD_SESSION_KEY =>
          'The node\'s admin session expired. Try again.',
        Routing_Error.MAX_RETRANSMIT || Routing_Error.TIMEOUT ||
        Routing_Error.NO_RESPONSE || Routing_Error.NO_ROUTE || Routing_Error.GOT_NAK =>
          'The node didn\'t answer. It may be out of range or asleep.',
        Routing_Error.DUTY_CYCLE_LIMIT || Routing_Error.RATE_LIMIT_EXCEEDED =>
          'The radio is over its airtime limit. Wait a minute and try again.',
        _ => message,
      };

  @override
  String toString() => 'MeshtasticAdminException: $message';
}

/// Request/response admin channel to the locally connected radio, or to
/// another node over the mesh when [targetNodeNum] is set.
///
/// Remote requests are sent encrypted to the target's public key (firmware
/// 2.5+). The target answers only if this radio's public key is in its
/// security admin keys; otherwise it replies NOT_AUTHORIZED.
///
/// Reads return the radio's answer. Writes wait for the radio's routing ACK
/// and fail on a negative acknowledgement or timeout. Firmware 2.5+ rejects
/// writes without the session passkey it returns on any admin read, so every
/// write first makes sure a fresh passkey is held.
///
/// Many config writes make the radio reboot; the BLE link then drops and the
/// coordinator's reconnect supervisor takes over.
class MeshtasticAdminSession {
  MeshtasticAdminSession({
    required Stream<Uint8List> incoming,
    required Future<void> Function(Uint8List toRadio) send,
    required this.localNodeNum,
    this.targetNodeNum,
    List<int>? targetPublicKey,
    Duration? timeout,
    DateTime Function()? clock,
    Random? random,
    Future<void> Function(Duration)? delay,
  })  : _send = send,
        _delay = delay ?? Future<void>.delayed,
        targetPublicKey = targetPublicKey == null ? null : List.unmodifiable(targetPublicKey),
        timeout = timeout ??
            (targetNodeNum == null || targetNodeNum == localNodeNum
                ? const Duration(seconds: 15)
                : remoteTimeout),
        _clock = clock ?? DateTime.now,
        _random = random ?? Random.secure() {
    if (isRemote && (this.targetPublicKey?.length ?? 0) != 32) {
      throw ArgumentError.value(targetPublicKey, 'targetPublicKey',
          'a remote node needs its 32-byte public key');
    }
    _subscription = incoming.listen(_handleEnvelope);
  }

  /// Firmware expires the passkey after 300 s; renew early.
  static const passkeyLifetime = Duration(seconds: 240);

  /// A mesh round trip can take several retries over multiple hops.
  static const remoteTimeout = Duration(seconds: 60);

  /// Gap between writes sent over the air, so a batch doesn't flood the mesh.
  static const remoteWriteSpacing = Duration(seconds: 5);

  /// Wait before the one retry after the radio reports its airtime limit.
  static const airtimeBackoff = Duration(seconds: 60);

  final int localNodeNum;

  /// The node being administered; null means the local radio.
  final int? targetNodeNum;

  /// The remote node's public key, required when [isRemote].
  final List<int>? targetPublicKey;
  final Duration timeout;

  int get target => targetNodeNum ?? localNodeNum;

  bool get isRemote => target != localNodeNum;
  final Future<void> Function(Uint8List) _send;
  final DateTime Function() _clock;
  final Random _random;
  final Future<void> Function(Duration) _delay;
  DateTime? _lastRemoteWrite;
  final Map<int, _PendingRequest> _pending = {};
  late final StreamSubscription<Uint8List> _subscription;

  List<int>? _passkey;
  DateTime? _passkeyReceivedAt;

  bool get hasFreshPasskey =>
      _passkey != null &&
      _clock().difference(_passkeyReceivedAt!) < passkeyLifetime;

  Future<DeviceMetadata> getMetadata() async =>
      (await _request(AdminMessage(getDeviceMetadataRequest: true), 'device info',
          expected: AdminMessage_PayloadVariant.getDeviceMetadataResponse))
          .getDeviceMetadataResponse;

  /// Asks the node to restart after [seconds].
  Future<void> reboot({int seconds = 5}) =>
      _write(AdminMessage(rebootSeconds: seconds), 'reboot');

  Future<User> getOwner() async =>
      (await _request(AdminMessage(getOwnerRequest: true), 'owner',
          expected: AdminMessage_PayloadVariant.getOwnerResponse)).getOwnerResponse;

  Future<Config> getConfig(AdminMessage_ConfigType type) async {
    final reply = await _request(AdminMessage(getConfigRequest: type), type.name,
        expected: AdminMessage_PayloadVariant.getConfigResponse);
    final config = reply.getConfigResponse;
    if (config.whichPayloadVariant() == Config_PayloadVariant.notSet) {
      throw MeshtasticSettingsUnavailable(type.name);
    }
    if (config.whichPayloadVariant().index != type.value) {
      throw MeshtasticAdminException('Radio returned a different configuration section.');
    }
    return config;
  }

  Future<ModuleConfig> getModuleConfig(AdminMessage_ModuleConfigType type) async {
    final reply = await _request(AdminMessage(getModuleConfigRequest: type), type.name,
        expected: AdminMessage_PayloadVariant.getModuleConfigResponse);
    final config = reply.getModuleConfigResponse;
    if (config.whichPayloadVariant() == ModuleConfig_PayloadVariant.notSet) {
      throw MeshtasticSettingsUnavailable(type.name);
    }
    // Enum order follows the pinned protocol schema, including Ambient Lighting
    // before Detection Sensor (their oneof tags have the opposite order).
    if (config.whichPayloadVariant().index != type.value) {
      throw MeshtasticAdminException('Radio returned a different module section.');
    }
    return config;
  }

  /// [index] is the 0-based channel slot; the protocol sends index + 1.
  Future<Channel> getChannel(int index) async {
    if (index < 0 || index > 7) throw RangeError.range(index, 0, 7, 'index');
    final reply = await _request(AdminMessage(getChannelRequest: index + 1),
        'channel $index', expected: AdminMessage_PayloadVariant.getChannelResponse);
    if (reply.getChannelResponse.index != index) {
      throw MeshtasticAdminException('Radio returned a different channel slot.');
    }
    return reply.getChannelResponse;
  }

  Future<void> setOwner(User owner) =>
      _write(AdminMessage(setOwner: owner), 'owner');

  Future<void> setConfig(Config config) =>
      _write(AdminMessage(setConfig: config), config.whichPayloadVariant().name);

  Future<void> setModuleConfig(ModuleConfig config) => _write(
        AdminMessage(setModuleConfig: config),
        config.whichPayloadVariant().name,
      );

  Future<void> setChannel(Channel channel) =>
      _write(AdminMessage(setChannel: channel), 'channel ${channel.index}');

  /// Groups several writes so the radio saves and reboots once at the end.
  Future<void> editTransaction(Future<void> Function() edits) async {
    await _write(AdminMessage(beginEditSettings: true), 'begin edit');
    await edits();
    await _write(AdminMessage(commitEditSettings: true), 'commit edit');
  }

  Future<void> ensureAuthorized() async {
    if (hasFreshPasskey) return;
    await getOwner();
    // Firmware older than 2.5 sends no passkey and does not require one.
  }

  Future<void> _write(AdminMessage message, String what) async {
    await ensureAuthorized();
    await _paceRemoteWrite();
    try {
      await _sendWrite(message, what);
    } on MeshtasticAdminException catch (error) {
      // Only writes to another node use airtime, and this write was refused
      // before it went out, so sending it again is safe.
      if (!isRemote || !_isAirtimeLimit(error.routingError)) rethrow;
      await _delay(airtimeBackoff);
      await ensureAuthorized();
      await _sendWrite(message, what);
    }
  }

  static bool _isAirtimeLimit(Routing_Error? error) =>
      error == Routing_Error.DUTY_CYCLE_LIMIT || error == Routing_Error.RATE_LIMIT_EXCEEDED;

  Future<void> _paceRemoteWrite() async {
    if (!isRemote) return;
    final last = _lastRemoteWrite;
    if (last != null) {
      final wait = remoteWriteSpacing - _clock().difference(last);
      if (wait > Duration.zero) await _delay(wait);
    }
    _lastRemoteWrite = _clock();
  }

  Future<void> _sendWrite(AdminMessage message, String what) async {
    final passkey = _passkey;
    if (passkey != null) message.sessionPasskey = passkey;
    await _exchange(message, what, expectsResponse: false);
  }

  Future<AdminMessage> _request(AdminMessage message, String what, {
    required AdminMessage_PayloadVariant expected,
  }) async {
    final reply = (await _exchange(message, what, expectsResponse: true))!;
    if (reply.whichPayloadVariant() != expected) {
      throw MeshtasticAdminException('Radio returned an unexpected response for $what.');
    }
    return reply;
  }

  Future<AdminMessage?> _exchange(
    AdminMessage message,
    String what, {
    required bool expectsResponse,
  }) async {
    final id = _nextPacketId();
    final pending = _PendingRequest(expectsResponse);
    _pending[id] = pending;
    final envelope = ToRadio(
      packet: MeshPacket(
        to: target,
        id: id,
        wantAck: true,
        pkiEncrypted: isRemote ? true : null,
        publicKey: isRemote ? targetPublicKey : null,
        decoded: Data(
          portnum: PortNum.ADMIN_APP,
          payload: message.writeToBuffer(),
          wantResponse: expectsResponse,
        ),
      ),
    );
    try {
      await _send(envelope.writeToBuffer());
      return await pending.completer.future.timeout(
        timeout,
        onTimeout: () => throw MeshtasticAdminException(
          '${isRemote ? 'The node' : 'Radio'} did not answer $what within ${timeout.inSeconds} s.',
        ),
      );
    } finally {
      _pending.remove(id);
    }
  }

  void _handleEnvelope(Uint8List bytes) {
    final FromRadio envelope;
    try {
      envelope = FromRadio.fromBuffer(bytes);
    } on InvalidProtocolBufferException {
      return;
    }
    if (!envelope.hasPacket() || !envelope.packet.hasDecoded()) return;
    final packet = envelope.packet;
    final fromTarget = packet.from == target;
    // The local radio reports its own send failures for remote requests.
    final fromLocalRadio = isRemote && packet.from == localNodeNum;
    if (!fromTarget && !fromLocalRadio) return;
    final data = packet.decoded;
    final pending = _pending[data.requestId];

    if (data.portnum == PortNum.ADMIN_APP) {
      if (!fromTarget) return;
      final AdminMessage admin;
      try {
        admin = AdminMessage.fromBuffer(data.payload);
      } on InvalidProtocolBufferException {
        return;
      }
      if (admin.sessionPasskey.isNotEmpty) {
        _passkey = List.unmodifiable(admin.sessionPasskey);
        _passkeyReceivedAt = _clock();
      }
      if (pending != null && pending.expectsResponse) {
        pending.complete(admin);
      }
    } else if (data.portnum == PortNum.ROUTING_APP && pending != null) {
      final Routing routing;
      try {
        routing = Routing.fromBuffer(data.payload);
      } on InvalidProtocolBufferException {
        return;
      }
      if (routing.whichVariant() != Routing_Variant.errorReason) return;
      // Only the target itself can confirm delivery.
      if (routing.errorReason == Routing_Error.NONE && !fromTarget) return;
      if (routing.errorReason != Routing_Error.NONE) {
        if (routing.errorReason == Routing_Error.ADMIN_BAD_SESSION_KEY) {
          _passkey = null;
        }
        pending.fail(MeshtasticAdminException(
          'Radio rejected the request: ${routing.errorReason.name}.',
          routingError: routing.errorReason,
        ));
      } else if (!pending.expectsResponse) {
        pending.complete(null);
      }
    }
  }

  int _nextPacketId() {
    int id;
    do {
      id = _random.nextInt(0x7fffffff) + 1;
    } while (_pending.containsKey(id));
    return id;
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    for (final pending in _pending.values) {
      pending.fail(MeshtasticAdminException('Admin session closed.'));
    }
    _pending.clear();
  }
}

class _PendingRequest {
  _PendingRequest(this.expectsResponse);

  final bool expectsResponse;
  final Completer<AdminMessage?> completer = Completer<AdminMessage?>();

  void complete(AdminMessage? value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  void fail(Object error) {
    if (!completer.isCompleted) completer.completeError(error);
  }
}
