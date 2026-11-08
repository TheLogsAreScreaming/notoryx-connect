import 'dart:async';
import 'dart:typed_data';

import 'package:bastion/generated/meshtastic/channel.pb.dart';
import 'package:bastion/generated/meshtastic/config.pb.dart';
import 'package:bastion/generated/meshtastic/mesh.pb.dart' as pb;
import 'package:bastion/generated/meshtastic/module_config.pb.dart';
import 'package:bastion/services/bastion_mqtt_proxy.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLink implements MqttLink {
  final incoming = StreamController<MqttIncoming>.broadcast();
  final subscribed = <String>[];
  final published = <({String topic, Uint8List data, bool retained})>[];
  bool connected = false;
  Object? failWith;

  @override
  Future<void> connect(MqttProxyConfig config, String clientId) async {
    if (failWith != null) throw failWith!;
    connected = true;
  }

  @override
  void subscribe(String topic) => subscribed.add(topic);
  @override
  void publish(String topic, Uint8List data, {required bool retained}) =>
      published.add((topic: topic, data: data, retained: retained));
  @override
  Stream<MqttIncoming> get messages => incoming.stream;
  @override
  Future<void> disconnect() async => connected = false;
}

const _config = MqttProxyConfig(host: 'broker', port: 1883, tls: false, root: 'msh', topics: ['msh/2/e/LongFast/+']);

void main() {
  group('config from the radio', () {
    final channels = [
      ChannelSettings(name: '', downlinkEnabled: true),
      ChannelSettings(name: 'Trail', downlinkEnabled: true),
      ChannelSettings(name: 'Quiet', downlinkEnabled: false),
    ];

    test('needs both MQTT and proxy to client', () {
      expect(MqttProxyConfig.from(ModuleConfig_MQTTConfig(enabled: true), channels: channels, presetName: 'LongFast'), isNull);
      expect(MqttProxyConfig.from(ModuleConfig_MQTTConfig(proxyToClientEnabled: true), channels: channels, presetName: 'LongFast'), isNull);
    });

    test('default broker and downlink topics', () {
      final c = MqttProxyConfig.from(ModuleConfig_MQTTConfig(enabled: true, proxyToClientEnabled: true),
          channels: channels, presetName: 'LongFast')!;
      expect(c.host, MqttProxyConfig.defaultHost);
      expect(c.port, 1883);
      expect(c.username, 'meshdev');
      expect(c.topics, ['msh/2/e/LongFast/+', 'msh/2/e/Trail/+']);
    });

    test('custom broker with port, TLS and root; no default login', () {
      final c = MqttProxyConfig.from(
          ModuleConfig_MQTTConfig(enabled: true, proxyToClientEnabled: true, address: 'mqtt.example.org:8884', tlsEnabled: true, root: 'msh/US'),
          channels: [ChannelSettings(name: 'A', downlinkEnabled: true)],
          presetName: 'LongFast')!;
      expect((c.host, c.port, c.tls), ('mqtt.example.org', 8884, true));
      expect(c.username, isNull);
      expect(c.topics, ['msh/US/2/e/A/+']);
    });

    test('preset names', () {
      expect(MqttProxyConfig.presetChannelName(Config_LoRaConfig_ModemPreset.MEDIUM_FAST), 'MediumFast');
      expect(MqttProxyConfig.presetChannelName(Config_LoRaConfig_ModemPreset.LONG_FAST), 'LongFast');
    });
  });

  group('proxy', () {
    late FakeLink link;
    late List<Uint8List> toRadio;
    late BastionMqttProxy proxy;

    setUp(() {
      link = FakeLink();
      toRadio = [];
      proxy = BastionMqttProxy(sendToRadio: (b) async => toRadio.add(b), link: () => link);
    });

    test('radio messages go to the broker', () async {
      await proxy.start(_config, clientId: 'x');
      expect(proxy.state, MqttProxyState.connected);
      expect(link.subscribed, _config.topics);
      proxy.fromRadio(pb.MqttClientProxyMessage(topic: 'msh/2/e/LongFast/!a', data: [1, 2], retained: true).writeToBuffer());
      expect(link.published.single.topic, 'msh/2/e/LongFast/!a');
      expect(link.published.single.data, [1, 2]);
      expect(link.published.single.retained, isTrue);
      expect(proxy.uplinked, 1);
    });

    test('broker messages go to the radio', () async {
      await proxy.start(_config, clientId: 'x');
      link.incoming.add((topic: 'msh/2/e/LongFast/!b', data: Uint8List.fromList([9]), retained: false));
      await Future<void>.delayed(Duration.zero);
      final m = pb.ToRadio.fromBuffer(toRadio.single).mqttClientProxyMessage;
      expect(m.topic, 'msh/2/e/LongFast/!b');
      expect(m.data, [9]);
      expect(proxy.downlinked, 1);
    });

    test('a failed connection reports the problem and sends nothing', () async {
      link.failWith = StateError('refused');
      await proxy.start(_config, clientId: 'x');
      expect(proxy.state, MqttProxyState.error);
      expect(proxy.error, contains('broker'));
      expect(proxy.running, isFalse);
      proxy.fromRadio(pb.MqttClientProxyMessage(topic: 't', data: [1]).writeToBuffer());
      expect(link.published, isEmpty);
    });

    test('stop disconnects and ignores later radio messages', () async {
      await proxy.start(_config, clientId: 'x');
      await proxy.stop();
      expect(link.connected, isFalse);
      expect(proxy.state, MqttProxyState.off);
      proxy.fromRadio(pb.MqttClientProxyMessage(topic: 't', data: [1]).writeToBuffer());
      expect(link.published, isEmpty);
    });
  });
}
