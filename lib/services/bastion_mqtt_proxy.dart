import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart' show Uint8Buffer;

import '../generated/meshtastic/channel.pb.dart';
import '../generated/meshtastic/config.pb.dart';
import '../generated/meshtastic/mesh.pb.dart' as pb;
import '../generated/meshtastic/module_config.pb.dart';

/// One message off the broker.
typedef MqttIncoming = ({String topic, Uint8List data, bool retained});

/// The broker connection, behind an interface so the proxy can be tested
/// without a network.
abstract interface class MqttLink {
  Future<void> connect(MqttProxyConfig config, String clientId);
  void subscribe(String topic);
  void publish(String topic, Uint8List data, {required bool retained});
  Stream<MqttIncoming> get messages;
  Future<void> disconnect();
}

/// Where the radio wants its MQTT traffic to go, from its own settings.
@immutable
class MqttProxyConfig {
  const MqttProxyConfig({
    required this.host,
    required this.port,
    required this.tls,
    required this.root,
    required this.topics,
    this.username,
    this.password,
  });

  static const defaultHost = 'mqtt.meshtastic.org';

  final String host;
  final int port;
  final bool tls;
  final String root;
  final String? username;
  final String? password;

  /// Topics to subscribe to, one per downlink-enabled channel.
  final List<String> topics;

  /// The config to use, or null unless the radio has both MQTT and
  /// "proxy to client" turned on. [presetName] names unnamed channels.
  static MqttProxyConfig? from(
    ModuleConfig_MQTTConfig mqtt, {
    required Iterable<ChannelSettings> channels,
    required String presetName,
  }) {
    if (!mqtt.enabled || !mqtt.proxyToClientEnabled) return null;
    final isDefault = mqtt.address.trim().isEmpty;
    final address = isDefault ? defaultHost : mqtt.address.trim();
    final colon = address.lastIndexOf(':');
    final parsedPort = colon > 0 ? int.tryParse(address.substring(colon + 1)) : null;
    final tls = mqtt.tlsEnabled;
    final root = mqtt.root.trim().isEmpty ? 'msh' : mqtt.root.trim();
    return MqttProxyConfig(
      host: parsedPort == null ? address : address.substring(0, colon),
      port: parsedPort ?? (tls ? 8883 : 1883),
      tls: tls,
      root: root,
      // The firmware's public defaults, used only for its default broker.
      username: mqtt.username.isNotEmpty ? mqtt.username : (isDefault ? 'meshdev' : null),
      password: mqtt.password.isNotEmpty ? mqtt.password : (isDefault ? 'large4cats' : null),
      topics: [
        for (final c in channels)
          if (c.downlinkEnabled) '$root/2/e/${c.name.isEmpty ? presetName : c.name}/+',
      ],
    );
  }

  /// A modem preset's channel name, such as "LongFast".
  static String presetChannelName(Config_LoRaConfig_ModemPreset preset) => switch (preset) {
        Config_LoRaConfig_ModemPreset.LONG_SLOW => 'LongSlow',
        Config_LoRaConfig_ModemPreset.VERY_LONG_SLOW => 'VLongSlow',
        Config_LoRaConfig_ModemPreset.MEDIUM_SLOW => 'MediumSlow',
        Config_LoRaConfig_ModemPreset.MEDIUM_FAST => 'MediumFast',
        Config_LoRaConfig_ModemPreset.SHORT_SLOW => 'ShortSlow',
        Config_LoRaConfig_ModemPreset.SHORT_FAST => 'ShortFast',
        Config_LoRaConfig_ModemPreset.SHORT_TURBO => 'ShortTurbo',
        Config_LoRaConfig_ModemPreset.LONG_MODERATE => 'LongMod',
        Config_LoRaConfig_ModemPreset.LONG_TURBO => 'LongTurbo',
        _ => 'LongFast',
      };
}

enum MqttProxyState { off, connecting, connected, error }

/// Carries a radio's MQTT traffic through the phone's internet connection,
/// for radios without Wi-Fi. Off unless both the radio's "proxy to client"
/// and the app's own setting are on. Credentials come from the radio and
/// are held only in memory.
class BastionMqttProxy extends ChangeNotifier {
  BastionMqttProxy({required this.sendToRadio, MqttLink Function()? link}) : _newLink = link ?? ServerMqttLink.new;

  final Future<void> Function(Uint8List toRadio) sendToRadio;
  final MqttLink Function() _newLink;

  MqttLink? _link;
  StreamSubscription<MqttIncoming>? _subscription;
  MqttProxyState _state = MqttProxyState.off;
  String? _error;
  int _up = 0, _down = 0, _bytes = 0;
  String? _host;

  MqttProxyState get state => _state;
  String? get error => _error;
  String? get host => _host;

  /// Messages sent from the radio to the broker since it started.
  int get uplinked => _up;

  /// Messages sent from the broker to the radio since it started.
  int get downlinked => _down;

  /// Message bytes carried over the phone's connection since it started,
  /// not counting MQTT and TCP overhead.
  int get bytesCarried => _bytes;
  bool get running => _link != null;

  Future<void> start(MqttProxyConfig config, {required String clientId}) async {
    if (_link != null) return;
    final link = _newLink();
    _link = link;
    _host = config.host;
    _up = _down = _bytes = 0;
    _error = null;
    _state = MqttProxyState.connecting;
    notifyListeners();
    try {
      await link.connect(config, clientId);
      if (_link != link) return;
      _subscription = link.messages.listen(_fromBroker);
      for (final topic in config.topics) {
        link.subscribe(topic);
      }
      _state = MqttProxyState.connected;
    } catch (error) {
      if (_link != link) return;
      _link = null;
      _error = 'Couldn\'t reach ${config.host}: $error';
      _state = MqttProxyState.error;
      unawaited(link.disconnect().catchError((Object _) {}));
    }
    notifyListeners();
  }

  Future<void> stop() async {
    final link = _link;
    _link = null;
    await _subscription?.cancel();
    _subscription = null;
    _state = MqttProxyState.off;
    _error = null;
    notifyListeners();
    try {
      await link?.disconnect();
    } catch (_) {
      // Already gone.
    }
  }

  /// Handles a MqttClientProxyMessage payload from the radio.
  void fromRadio(Uint8List payload) {
    final link = _link;
    if (link == null || _state != MqttProxyState.connected) return;
    try {
      final m = pb.MqttClientProxyMessage.fromBuffer(payload);
      final data = m.hasText() ? Uint8List.fromList(utf8.encode(m.text)) : Uint8List.fromList(m.data);
      link.publish(m.topic, data, retained: m.retained);
      _up++;
      _bytes += data.length;
      notifyListeners();
    } catch (error) {
      _error = 'A message couldn\'t be sent to the broker: $error';
      notifyListeners();
    }
  }

  void _fromBroker(MqttIncoming m) {
    _down++;
    _bytes += m.data.length;
    notifyListeners();
    final envelope = pb.ToRadio(
      mqttClientProxyMessage: pb.MqttClientProxyMessage(topic: m.topic, data: m.data, retained: m.retained),
    ).writeToBuffer();
    unawaited(sendToRadio(Uint8List.fromList(envelope)).catchError((Object error) {
      _error = 'A message couldn\'t be passed to the radio: $error';
      notifyListeners();
    }));
  }

  @override
  void dispose() {
    unawaited(stop());
    super.dispose();
  }
}

/// [MqttLink] over a real socket.
class ServerMqttLink implements MqttLink {
  MqttServerClient? _client;
  final StreamController<MqttIncoming> _incoming = StreamController.broadcast();
  StreamSubscription<Object?>? _updates;

  @override
  Stream<MqttIncoming> get messages => _incoming.stream;

  @override
  Future<void> connect(MqttProxyConfig config, String clientId) async {
    final client = MqttServerClient.withPort(config.host, clientId, config.port)
      ..secure = config.tls
      ..keepAlivePeriod = 30
      ..autoReconnect = true
      ..logging(on: false)
      ..setProtocolV311()
      ..connectionMessage = MqttConnectMessage().withClientIdentifier(clientId).startClean();
    _client = client;
    final status = await client.connect(config.username, config.password);
    if (status?.state != MqttConnectionState.connected) {
      client.disconnect();
      throw StateError(status?.returnCode?.name ?? 'connection refused');
    }
    _updates = client.updates?.listen((events) {
      for (final event in events) {
        final message = event.payload;
        if (message is MqttPublishMessage) {
          _incoming.add((
            topic: event.topic,
            data: Uint8List.fromList(message.payload.message.toList()),
            retained: message.header?.retain == true,
          ));
        }
      }
    });
  }

  @override
  void subscribe(String topic) => _client?.subscribe(topic, MqttQos.atLeastOnce);

  @override
  void publish(String topic, Uint8List data, {required bool retained}) {
    final buffer = Uint8Buffer()..addAll(data);
    _client?.publishMessage(topic, MqttQos.atLeastOnce, buffer, retain: retained);
  }

  @override
  Future<void> disconnect() async {
    await _updates?.cancel();
    _client?.disconnect();
    _client = null;
    await _incoming.close();
  }
}
