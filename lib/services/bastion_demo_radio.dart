import 'dart:async';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import 'bastion_chat_message.dart';
import 'bastion_geofences.dart';
import 'bastion_node_vault.dart';
import 'bastion_telemetry_codec.dart';
import 'bastion_telemetry_history.dart';
import 'bastion_trip.dart';
import 'bastion_waypoints.dart';
import 'meshtastic_ble_discovery.dart';
import 'meshtastic_connection_controller.dart';
import 'meshtastic_node_database.dart';
import 'meshtastic_radio_coordinator.dart';

/// A pretend radio and mesh for trying the app without hardware.
///
/// Everything lives in memory: nothing is sent over Bluetooth or the mesh,
/// and none of your saved messages, nodes or settings are changed. Sent
/// messages are "delivered" after a moment and some get a reply.
class BastionDemoRadio extends MeshtasticRadioCoordinator {
  BastionDemoRadio({DateTime Function()? clock, this.replyDelay = const Duration(seconds: 2)})
      : _clock = clock ?? DateTime.now {
    _connection
      ..beginConnect(demoRadioName)
      ..markConnected()
      ..beginSync()
      ..markReady();
    _seed();
  }

  /// The name the pretend radio shows in the connection status.
  static const demoRadioName = 'Demo radio';

  /// Node number of the pretend radio you are "connected" to.
  static const localNum = 0xDE300001;

  final DateTime Function() _clock;

  /// How long a sent message takes to be marked delivered.
  final Duration replyDelay;

  final MeshtasticConnectionController _connection = MeshtasticConnectionController();
  final List<MeshtasticNode> _demoNodes = [];
  final List<BastionChatMessage> _demoMessages = [];
  final Map<int, Map<TelemetryMetric, List<TelemetryPoint>>> _series = {};
  final List<Timer> _timers = [];
  int _nextPacket = 0x7000;
  bool _closed = false;

  // A trailhead area; positions are spread a few kilometres apart.
  static const _baseLat = 40.0150;
  static const _baseLon = -105.2705;

  static const _people = [
    (0xDE300002, 'Ridge Relay', 'RDG', 0.021, 0.018, 1),
    (0xDE300003, 'Mara (trail lead)', 'MARA', -0.012, 0.031, 0),
    (0xDE300004, 'Basecamp Solar', 'BASE', 0.004, -0.009, 0),
    (0xDE300005, 'Sam', 'SAM', -0.026, -0.015, 2),
    (0xDE300006, 'Weather Station', 'WX', 0.035, -0.022, 1),
  ];

  void _seed() {
    final now = _clock();
    _demoNodes.add(MeshtasticNode(
      num: localNum, id: _id(localNum), longName: 'Demo Base', shortName: 'DEMO',
      latitude: _baseLat, longitude: _baseLon, altitudeMeters: 1655,
      positionTime: now, lastHeard: now, batteryLevel: 87,
    ));
    for (final (i, p) in _people.indexed) {
      final (num, long, short, dLat, dLon, hops) = p;
      _demoNodes.add(MeshtasticNode(
        num: num, id: _id(num), longName: long, shortName: short,
        latitude: _baseLat + dLat, longitude: _baseLon + dLon,
        altitudeMeters: 1700 + i * 140,
        positionTime: now.subtract(Duration(minutes: 3 + i * 4)),
        lastHeard: now.subtract(Duration(minutes: 1 + i * 6)),
        snr: 9.5 - i * 3.25, hopsAway: hops, batteryLevel: num == 0xDE300004 ? 101 : 92 - i * 13,
      ));
    }

    BastionChatMessage incoming(int from, String text, Duration ago, {int channel = 0, bool direct = false}) =>
        BastionChatMessage(
          packetId: _nextPacket++, from: from, to: direct ? localNum : 0xffffffff,
          channel: channel, text: text, timestamp: now.subtract(ago),
          direction: BastionMessageDirection.incoming,
          deliveryState: BastionDeliveryState.received, rxSnr: 6.5, rxRssi: -97,
          hops: from == 0xDE300005 ? 2 : from == 0xDE300002 ? 0 : 1, relayNode: 0x02,
        );
    BastionChatMessage outgoing(int to, String text, Duration ago) => BastionChatMessage(
          packetId: _nextPacket++, from: localNum, to: to, channel: 0, text: text,
          timestamp: now.subtract(ago), direction: BastionMessageDirection.outgoing,
          deliveryState: BastionDeliveryState.delivered,
        );
    final first = incoming(0xDE300003, 'Group is at the lower lot. Starting up the trail at 7.',
        const Duration(hours: 26));
    _demoMessages.addAll([
      first,
      outgoing(0xffffffff, 'Copy. Base is set up at the trailhead.', const Duration(hours: 25, minutes: 50)),
      incoming(0xDE300006, 'WX: 4°C, wind 12 km/h NW, clear.', const Duration(hours: 20)),
      incoming(0xDE300005, 'Made the saddle. Slow going in the snow.', const Duration(hours: 3)),
      incoming(0xDE300003, '@Demo Base can you check the forecast for this afternoon?',
          const Duration(minutes: 42)),
      outgoing(0xDE300003, 'Clear until 3, clouds building after.', const Duration(minutes: 40)),
      incoming(0xDE300002, 'Relay battery at 71%. All good.', const Duration(minutes: 18)),
      incoming(0xDE300005, 'Heading back now, ETA 90 min.', const Duration(minutes: 6), direct: true),
    ]);
    _demoMessages.add(BastionChatMessage(
      packetId: _nextPacket++, from: 0xDE300003, to: 0xffffffff, channel: 0, text: '👍',
      timestamp: now.subtract(const Duration(hours: 25, minutes: 49)),
      direction: BastionMessageDirection.incoming, deliveryState: BastionDeliveryState.received,
      replyId: _demoMessages[1].packetId, isReaction: true,
    ));

    // Two days of readings, one every 30 minutes.
    final rng = math.Random(7);
    for (final node in _demoNodes) {
      final battery = <TelemetryPoint>[];
      final volts = <TelemetryPoint>[];
      final util = <TelemetryPoint>[];
      for (var i = 96; i >= 0; i--) {
        final t = now.subtract(Duration(minutes: 30 * i));
        final level = ((node.batteryLevel ?? 80).clamp(0, 100) + i * 0.25 + rng.nextDouble() * 2).clamp(0, 100).toDouble();
        battery.add(TelemetryPoint(t, level));
        volts.add(TelemetryPoint(t, 3.4 + level / 100 * 0.8));
        util.add(TelemetryPoint(t, 4 + rng.nextDouble() * 9 + (i % 48 < 24 ? 6 : 0)));
      }
      _series[node.num] = {
        TelemetryMetric.battery: battery,
        TelemetryMetric.voltage: volts,
        TelemetryMetric.channelUtilization: util,
      };
    }
    final temps = <TelemetryPoint>[];
    final humidity = <TelemetryPoint>[];
    for (var i = 96; i >= 0; i--) {
      final t = now.subtract(Duration(minutes: 30 * i));
      final dayCurve = math.sin((t.hour + t.minute / 60 - 9) / 24 * 2 * math.pi);
      temps.add(TelemetryPoint(t, 6 + dayCurve * 7 + rng.nextDouble()));
      humidity.add(TelemetryPoint(t, 55 - dayCurve * 18 + rng.nextDouble() * 3));
    }
    _series[0xDE300006]!
      ..[TelemetryMetric.temperature] = temps
      ..[TelemetryMetric.humidity] = humidity;
  }

  static String _id(int num) => '!${num.toRadixString(16).padLeft(8, '0')}';

  @override
  MeshtasticConnectionController get connection => _connection;
  @override
  int? get localNodeNum => localNum;
  @override
  MeshtasticNode? get localNode => _demoNodes.first;
  @override
  List<MeshtasticNode> get nodes => List.unmodifiable(_demoNodes);
  @override
  List<MeshtasticNode> get allNodes => List.unmodifiable(_demoNodes);
  @override
  List<BastionChatMessage> get messages => List.unmodifiable(_demoMessages);
  @override
  List<BastionChatMessage> get allMessages => List.unmodifiable(_demoMessages);
  @override
  int get pendingMessageCount => 0;
  @override
  int get filteredMessageCount => 0;
  @override
  String? get messageStorageProblem => null;
  @override
  String? get backgroundProblem => null;
  @override
  List<BastionNodeRecord> get nodeVault => const [];
  @override
  bool get canAdminister => false;
  @override
  bool get canTraceroute => false;
  @override
  bool get isReconnecting => false;
  @override
  List<String?> get ownNames => const ['Demo Base', 'DEMO'];
  @override
  int get unreadCount => 0;
  @override
  int get receivedTextPackets => _demoMessages.where((m) => m.direction == BastionMessageDirection.incoming).length;
  @override
  List<double> get snrHistory => const [6.5, 7.0, 4.25, 8.5, 2.0, 5.75, 9.0, 6.25, 3.5, 7.75];
  @override
  double? get latestSnr => 7.75;

  @override
  Map<int, BastionDeviceTelemetry> get deviceTelemetry => {
        for (final n in _demoNodes)
          n.num: BastionDeviceTelemetry(
            from: n.num,
            batteryLevel: n.batteryLevel,
            voltage: _series[n.num]![TelemetryMetric.voltage]!.last.value,
            channelUtilization: _series[n.num]![TelemetryMetric.channelUtilization]!.last.value,
            airUtilTx: 1.2,
          ),
      };

  @override
  List<TelemetryMetric> telemetryMetricsOf(int num) => [...?_series[num]?.keys];

  @override
  List<TelemetryPoint> telemetrySeries(int num, TelemetryMetric metric) => [...?_series[num]?[metric]];

  /// A trip kept in memory only, so a demo check-in or SOS never reaches
  /// the real trip on this phone.
  @override
  late final BastionTripController trip =
      BastionTripController(radio: tripRadioFor(this), preferences: _MemoryPreferences());

  static const _notInDemo = 'Not available in demo mode.';

  @override
  Future<void> markChatsRead() async {}

  @override
  Future<String?> saveGeofence(BastionGeofence zone) async => 'Zones are not saved in demo mode.';
  @override
  Future<String?> removeGeofence(String id) async => 'Zones are not saved in demo mode.';
  @override
  Future<void> setNodeFavorite(int num, bool value) async {}
  @override
  Future<void> setNodeNote(int num, String note) async {}
  @override
  Future<void> setCoverageRecording(bool enabled) async => throw StateError(_notInDemo);
  @override
  Future<void> sendWaypoint(MeshWaypoint waypoint, {int channel = 0}) async => throw StateError(_notInDemo);
  @override
  Future<void> deleteWaypoint(MeshWaypoint waypoint, {int channel = 0}) async => throw StateError(_notInDemo);
  @override
  Future<void> sendBeacon(String message, {bool offerPrimaryChannel = false}) async => throw StateError(_notInDemo);
  @override
  Future<void> clearBeacons() async {}
  @override
  Future<void> setSharePhoneLocation(bool enabled) async => throw StateError(_notInDemo);

  @override
  Future<String?> togglePin(BastionChatMessage message) async =>
      'Pins are not saved in demo mode.';

  @override
  Future<void> requestPosition(int nodeNum) async {}
  @override
  Future<void> requestTelemetry(int nodeNum) async {}
  @override
  Future<void> requestEnvironmentTelemetry(int nodeNum) async {}

  /// Demo mode ends from the app, not by disconnecting the pretend radio.
  @override
  Future<void> disconnect() async {}

  /// A real radio can't be connected while the pretend one is showing.
  @override
  Future<void> connect(MeshtasticBleDevice device) async =>
      throw StateError('Exit demo mode to connect a radio.');

  @override
  Future<int> sendText({
    required String text,
    int destination = 0xffffffff,
    int channel = 0,
  }) => _send(text: text, destination: destination, channel: channel);

  Future<int> _send({
    required String text,
    required int destination,
    required int channel,
    int? replyId,
    bool isReaction = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw ArgumentError('Message is empty.');
    final id = _nextPacket++;
    _demoMessages.add(BastionChatMessage(
      packetId: id, from: localNum, to: destination, channel: channel, text: trimmed,
      timestamp: _clock(), direction: BastionMessageDirection.outgoing,
      deliveryState: BastionDeliveryState.sent, replyId: replyId, isReaction: isReaction,
    ));
    notifyListeners();
    _later(() {
      final i = _demoMessages.indexWhere((m) => m.packetId == id);
      if (i >= 0) {
        _demoMessages[i] = _demoMessages[i].copyWith(deliveryState: BastionDeliveryState.delivered);
      }
      if (!isReaction) {
        final from = destination == 0xffffffff ? 0xDE300003 : destination;
        _demoMessages.add(BastionChatMessage(
          packetId: _nextPacket++, from: from, to: destination == 0xffffffff ? 0xffffffff : localNum,
          channel: channel, text: _replyTo(trimmed), timestamp: _clock(),
          direction: BastionMessageDirection.incoming, deliveryState: BastionDeliveryState.received,
          rxSnr: 5.5,
        ));
      }
      notifyListeners();
    });
    return id;
  }

  @override
  Future<void> sendReaction(BastionChatMessage target, String emoji) async {
    await _send(text: emoji, destination: target.isBroadcast ? 0xffffffff : target.from,
        channel: target.channel, replyId: target.packetId, isReaction: true);
  }

  static String _replyTo(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('position') || lower.contains('where')) return 'About 2 km up the east trail.';
    if (lower.contains('assist') || lower.contains('help')) return 'On our way to you now.';
    if (lower.startsWith('ok') || lower.contains("i'm ok") || lower.contains('copy')) return 'Thanks, noted.';
    return 'Got it 👍 (demo reply)';
  }

  void _later(void Function() action) {
    late final Timer timer;
    timer = Timer(replyDelay, () {
      _timers.remove(timer);
      if (!_closed) action();
    });
    _timers.add(timer);
  }

  @override
  void dispose() {
    _closed = true;
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    // The connection is left undisposed: the base class's shutdown finishes
    // asynchronously and marks it disconnected afterwards. It holds no
    // resources beyond its listeners.
    super.dispose();
  }
}

/// Phone storage that lives only in memory, for the demo trip.
class _MemoryPreferences implements SharedPreferencesAsync {
  final Map<String, Object> _values = {};

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<void> setString(String key, String value) async => _values[key] = value;

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => Future<Object?>.value();
}
