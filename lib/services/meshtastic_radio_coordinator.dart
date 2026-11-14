import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:protobuf/protobuf.dart';

import '../generated/meshtastic/admin.pb.dart';
import '../generated/meshtastic/apponly.pb.dart';
import '../generated/meshtastic/channel.pb.dart';
import '../generated/meshtastic/config.pb.dart';
import '../generated/meshtastic/mesh.pb.dart'
    as pb
    show Data, FromRadio, MeshPacket, Position, ToRadio, DeviceMetadata;
import '../generated/meshtastic/mesh.pb.dart' show User;
import '../generated/meshtastic/mesh_beacon.pb.dart';
import '../generated/meshtastic/module_config.pb.dart';
import '../generated/meshtastic/portnums.pbenum.dart';
import '../generated/meshtastic/telemetry.pb.dart';
import 'bastion_admin_packet_codec.dart';
import 'bastion_radio_backup.dart';
import 'bastion_background_service.dart';
import 'bastion_channel_import.dart';
import 'bastion_bluetooth_state.dart';
import 'bastion_message_alerts.dart';
import 'bastion_phone_position.dart';
import 'bastion_field_alerts.dart';
import 'bastion_field_log.dart';
import 'bastion_filters.dart';
import 'bastion_settings_evidence.dart';
import 'bastion_waypoints.dart';
import 'bastion_beacons.dart';
import 'bastion_radio_data.dart';
import 'bastion_chat_marks.dart';
import 'bastion_chat_store.dart';
import 'bastion_connection_log.dart';
import 'bastion_firmware.dart';
import 'bastion_mqtt_proxy.dart';
import 'bastion_geofences.dart';
import 'bastion_node_keys.dart';
import 'bastion_telemetry_history.dart';
import 'bastion_trails.dart';
import 'bastion_trip.dart';
import 'bastion_preferences.dart';
import 'bastion_speech.dart';
import 'bastion_owner_codec.dart';
import 'bastion_owner_readback.dart';
import 'bastion_history_limit.dart';
import 'bastion_message_archive.dart';
import 'bastion_radio_config_codec.dart';
import 'bastion_radio_history.dart';
import 'bastion_reconnect_policy.dart';
import 'bastion_reconnect_supervisor.dart';
import 'bastion_telemetry_codec.dart';
import 'bastion_radio_policy.dart';
import 'bastion_node_vault.dart';
import 'bastion_day_tracks.dart';
import 'bastion_node_journal.dart';
import 'bastion_sms_relay.dart';
import 'meshtastic_ble_discovery.dart';
import 'meshtastic_connection_controller.dart';
import 'meshtastic_admin_session.dart';
import 'meshtastic_handshake.dart';
import 'meshtastic_mesh_tools.dart';
import 'meshtastic_messaging_service.dart';
import 'meshtastic_node_database.dart';
import 'meshtastic_phoneapi_codec.dart';
import 'meshtastic_radio_session.dart';
import 'meshtastic_radio_transport.dart';
import 'meshtastic_stream_transport.dart';
import 'meshtastic_usb_transport.dart';
import 'meshtastic_text_codec.dart';
import 'meshtastic_traceroute.dart';
import 'bastion_lookalike.dart';

/// Owns one verified Meshtastic radio session and exposes it to the UI.
class MeshtasticRadioCoordinator extends ChangeNotifier
    implements RadioBackupGateway, ChannelImportGateway {
  MeshtasticRadioCoordinator({
    BastionBackgroundKeeper? background,
    BastionMessageAlerts? alerts,
    PhoneLocationSource? location,
    BluetoothAvailability? bluetooth,
    BastionSpeaker? speaker,
  }) : _speaker = speaker ?? TtsSpeaker(),
       _background = background ?? BastionForegroundService(),
       _bluetooth = bluetooth ?? UniversalBleAvailability(),
       _alerts = alerts ?? BastionLocalMessageAlerts(),
       _location = location ?? GeolocatorLocationSource() {
    unawaited(_loadSharePreference());
    _bluetoothSubscription = _bluetooth.changes.listen(_handleBluetoothChange);
    unawaited(_waypoints.load().then((_) => notifyListeners()));
    unawaited(_beacons.load().then((_) => notifyListeners()));
    trip.addListener(notifyListeners);
    BastionPreferences.instance.addListener(_applyRetention);
    unawaited(trip.load());
    filters.addListener(notifyListeners);
    unawaited(filters.load());
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) =>
          _inForeground = state == AppLifecycleState.resumed,
    );
    connection.addListener(_relayConnectionChange);
    connection.addListener(_syncMqttProxy);
    BastionPreferences.instance.addListener(_syncMqttProxy);
    mqttProxy.addListener(notifyListeners);
    connection.addListener(_logConnection);
    if (_background case BastionForegroundService(:final problem)) {
      problem.addListener(notifyListeners);
    }
    _archive.addListener(notifyListeners);
    _archiveLoaded = _loadArchive();
    unawaited(BastionAlertSettings.load().then((s) {
      _alertSettings = s;
      notifyListeners();
    }));
    unawaited(_geofenceStore.load().then((_) => notifyListeners()));
    unawaited(_routeWatchStore.load().then((_) => notifyListeners()));
    unawaited(_chatMarks.load().then((_) => notifyListeners()));
    unawaited(_nodeKeys.load().then((_) => notifyListeners()));
  }

  final BastionFieldAlertEngine _fieldAlerts = BastionFieldAlertEngine();
  Timer? _silenceTimer;
  BastionAlertSettings _alertSettings = const BastionAlertSettings();

  /// Local alerts for low battery, new nodes and favorites that go quiet.
  BastionAlertSettings get alertSettings => _alertSettings;

  /// Applies [settings] now; returns false if they could not be saved.
  Future<bool> setAlertSettings(BastionAlertSettings settings) async {
    _alertSettings = settings;
    notifyListeners();
    return settings.save();
  }

  /// The best known name for node [num].
  String nodeName(int num) => _nodeName(num);

  String _nodeName(int num) {
    for (final node in _nodes) {
      if (node.num == num) return node.displayName;
    }
    for (final record in _nodeVault.records) {
      if (record.num == num) return record.displayName;
    }
    return '!${num.toRadixString(16).padLeft(8, '0')}';
  }

  bool _isFavorite(int num) => _nodeVault.records.any((r) => r.num == num && r.favorite);

  /// The favourite or trip contact whose name [num]'s name imitates, or
  /// null. A hint to check with the owner, not proof of anything.
  int? lookalikeOf(int num) {
    final node = _nodes.where((n) => n.num == num).firstOrNull;
    if (node == null) return null;
    final trusted = <int, String>{
      for (final r in _nodeVault.records)
        if (r.favorite) r.num: _nodeName(r.num),
      for (final m in trip.plan.members) m: _nodeName(m),
    };
    return BastionLookalike.imitates(num, node.displayName, trusted);
  }

  void _raise(BastionFieldAlert? alert) {
    if (alert != null && !filters.isSilenced(alert.nodeNum)) unawaited(_alerts.showFieldAlert(alert));
  }

  /// Shows [alert] as a local notification, e.g. for an automation. Nothing
  /// is transmitted.
  Future<void> showLocalAlert(BastionFieldAlert alert) => _alerts.showFieldAlert(alert);

  void _startFieldAlerts(int localNode) {
    _fieldAlerts.startSession(localNode);
    _geofenceEngine.startSession();
    _routeWatchEngine.startSession();
    for (final t in _deviceTelemetry.values) {
      _raise(_fieldAlerts.battery(t.from, t.batteryLevel, _nodeName(t.from),
          favorite: _isFavorite(t.from), settings: _alertSettings));
    }
    _silenceTimer?.cancel();
    _silenceTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!isReady) return;
      final favorites = [
        for (final r in _nodeVault.records)
          if (r.favorite)
            (num: r.num, name: _nodeName(r.num),
              lastHeard: _nodes.where((n) => n.num == r.num).firstOrNull?.lastHeard),
      ];
      _fieldAlerts.checkSilence(favorites, _alertSettings).forEach(_raise);
      _raise(_fieldAlerts.checkMeshDrop(
          _nodes.where((n) => n.num != _localNodeNum).map((n) => n.lastHeard), _alertSettings));
      if (++_onlineTicks % 5 == 0) unawaited(_saveLastOnline());
    });
    _catchUpAsked = false;
    _lastOnline = null;
    unawaited(_loadLastOnline());
  }

  static const _lastOnlineKey = 'bastion.store_forward.last_online';
  int _onlineTicks = 0;
  DateTime? _lastOnline;
  bool _catchUpAsked = false;

  Future<void> _loadLastOnline() async {
    try {
      final ms = await SharedPreferencesAsync().getInt(_lastOnlineKey);
      _lastOnline = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      // Without it, catch-up just doesn't run this session.
    }
    _maybeCatchUp();
  }

  Future<void> _saveLastOnline() async {
    try {
      await SharedPreferencesAsync().setInt(_lastOnlineKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // Best effort.
    }
  }

  /// Once per session, asks the most recently heard router for what was
  /// missed. Runs only with the setting on and a known offline gap.
  void _maybeCatchUp() {
    if (_catchUpAsked || !BastionPreferences.instance.storeForwardCatchUp || !isReady) return;
    final routers = _meshTools.routers;
    if (routers.isEmpty) return;
    final window = BastionStoreForwardCatchUp.windowFor(_lastOnline, DateTime.now());
    if (window == null) return;
    _catchUpAsked = true;
    final router = routers.reduce((a, b) => a.lastHeard.isAfter(b.lastHeard) ? a : b);
    unawaited(requestStoredMessages(router.nodeNum, window).catchError((Object _) {
      _catchUpAsked = false;
    }));
  }

  void _stopFieldAlerts() {
    if (_silenceTimer != null) unawaited(_saveLastOnline());
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _fieldAlerts.endSession();
    _geofenceEngine.endSession();
    _routeWatchEngine.endSession();
  }

  final BastionNodeKeys _nodeKeys = BastionNodeKeys();

  /// Remembered public keys and nodes whose key has changed.
  BastionNodeKeys get nodeKeys => _nodeKeys;

  /// Accepts [num]'s new key, ending the warning.
  Future<void> trustNodeKey(int num) async {
    await _nodeKeys.trust(num);
    notifyListeners();
  }

  /// Checks [node]'s key against the remembered one and alerts on a change.
  Future<void> _checkNodeKey(MeshtasticNode node) async {
    final key = node.publicKey;
    if (key == null || node.num == _localNodeNum) return;
    final wasChanged = _nodeKeys.hasChanged(node.num);
    if (await _nodeKeys.check(node.num, key) == KeyCheck.changed && !wasChanged) {
      _raise(BastionFieldAlert(BastionAlertKind.keyChanged, node.num,
          'Security key changed: ${node.displayName}',
          'This node now uses a different key. Check with its owner before trusting it with direct messages.'));
    }
    notifyListeners();
  }

  final BastionChatMarks _chatMarks = BastionChatMarks();

  /// Pinned messages and when you last looked at Chats.
  BastionChatMarks get chatMarks => _chatMarks;

  /// Pins or unpins [message]. Returns a problem for the user, or null.
  Future<String?> togglePin(BastionChatMessage message) async {
    final problem = await _chatMarks.togglePin(message);
    notifyListeners();
    return problem;
  }

  /// Records that every message up to now has been seen.
  Future<void> markChatsRead() async {
    await _chatMarks.markRead(DateTime.now());
    notifyListeners();
  }

  /// Incoming messages you haven't seen yet.
  int get unreadCount => _chatMarks.unreadIn(messages);

  /// Your own node's long and short names, used to spot @mentions.
  List<String?> get ownNames {
    for (final n in _nodes) {
      if (n.num == _localNodeNum) return [n.longName, n.shortName];
    }
    return const [];
  }

  /// Whether [text] mentions your node as @name.
  bool mentionsMe(String text) => BastionMentions.mentions(text, ownNames);

  final BastionGeofenceStore _geofenceStore = BastionGeofenceStore();
  final BastionRouteWatchStore _routeWatchStore = BastionRouteWatchStore();
  final BastionRouteWatchEngine _routeWatchEngine = BastionRouteWatchEngine();

  /// The shared route watched for people wandering off it, if any.
  BastionRouteWatch? get routeWatch => _routeWatchStore.watch;

  /// Starts watching [route], or stops when null. Returns a problem, or null.
  Future<String?> setRouteWatch(BastionRouteWatch? route) async {
    final problem = await _routeWatchStore.set(route);
    notifyListeners();
    return problem;
  }
  final BastionGeofenceEngine _geofenceEngine = BastionGeofenceEngine();

  /// Map zones that alert when watched nodes arrive or leave.
  List<BastionGeofence> get geofences => _geofenceStore.zones;

  /// Adds or replaces a zone. Returns a problem for the user, or null.
  Future<String?> saveGeofence(BastionGeofence zone) async {
    final problem = await _geofenceStore.put(zone);
    notifyListeners();
    return problem;
  }

  Future<String?> removeGeofence(String id) async {
    final problem = await _geofenceStore.remove(id);
    notifyListeners();
    return problem;
  }

  /// Nodes starred as favourites.
  Set<int> get favoriteNums => {for (final r in _nodeVault.records) if (r.favorite) r.num};

  /// Phone alerts for watched nodes crossing a zone's edge. This radio's
  /// own position never alerts.
  void _checkGeofences(List<MeshtasticNode> nodes) {
    final zones = _geofenceStore.zones;
    final route = _routeWatchStore.watch;
    if (zones.isEmpty && route == null) return;
    final favorites = favoriteNums;
    final everyone = {for (final n in nodes) n.num};
    Set<int> watched(GeofenceWatch watch) => switch (watch) {
      GeofenceWatch.tripContacts => trip.plan.members.toSet(),
      GeofenceWatch.favorites => favorites,
      GeofenceWatch.allNodes => everyone,
    };
    final positions = [
      for (final n in nodes)
        if (n.hasPosition && n.num != _localNodeNum)
          (num: n.num, name: n.displayName, latitude: n.latitude!, longitude: n.longitude!),
    ];
    _geofenceEngine.check(zones, positions, watched).forEach(_raise);
    if (route != null) {
      _routeWatchEngine.check(route, positions, watched(route.watch)).forEach(_raise);
    }
  }

  final MeshtasticConnectionController connection =
      MeshtasticConnectionController();

  /// Recent connection events for the connection doctor's report.
  final BastionConnectionLog connectionLog = BastionConnectionLog();
  MeshtasticConnectionState? _loggedState;
  String? _loggedError;

  void _logConnection() {
    final state = connection.state, error = connection.error;
    if (state == _loggedState && error == _loggedError) return;
    _loggedState = state;
    _loggedError = error;
    final via = _lastDevice == null
        ? ''
        : ' (${_lastDevice!.isUsb ? 'USB' : _lastDevice!.isNetwork ? 'Wi-Fi' : 'Bluetooth'})';
    connectionLog.add('${state.name}$via${error == null ? '' : ': $error'}');
  }

  /// Whether there is a radio to try again with.
  bool get hasLastRadio => _lastDevice != null;

  /// Connects again to the last radio, for the connection doctor.
  Future<void> retryLastRadio() async {
    final device = _lastDevice;
    if (device == null || _busy) return;
    await connect(device);
  }
  final BastionRadioHistory _history = BastionRadioHistory();

  /// History of the connected radio, or of the last one while disconnected.
  BastionMessageArchive _archive = BastionMessageArchive();

  /// Completes once stored history is in [_archivedMessages]; offline sends
  /// wait for it so their save can't replace history that hasn't loaded yet.
  late final Future<void> _archiveLoaded;

  /// Why chat history or the offline queue may not be stored; null when fine.
  String? get messageStorageProblem => _archive.problem ?? BastionChatStorage.migrationProblem;

  /// Why the background connection service is not running; null when fine.
  String? get backgroundProblem => switch (_background) {
    BastionForegroundService(:final problem) => problem.value,
    _ => null,
  };
  final BastionNodeVault _nodeVault = BastionNodeVault();
  final BastionNodeJournal _journal = BastionNodeJournal();
  final BastionBackgroundKeeper _background;
  final BastionMessageAlerts _alerts;
  final PhoneLocationSource _location;
  final BluetoothAvailability _bluetooth;
  late final StreamSubscription<bool> _bluetoothSubscription;
  bool _bluetoothOn = true;

  /// A link was lost while Bluetooth was off; reconnect when it returns.
  bool _waitingForBluetooth = false;
  final BastionWaypointStore _waypoints = BastionWaypointStore();
  final BastionBeaconLog _beacons = BastionBeaconLog();

  /// Trip contacts, check-ins, SOS, reminders and overdue alerts.
  late final BastionTripController trip = BastionTripController(radio: _CoordinatorTripRadio(this));
  final MeshtasticMeshTools _meshTools = MeshtasticMeshTools();
  StreamSubscription<Uint8List>? _meshToolsSubscription;
  StreamSubscription<Uint8List>? _waypointSubscription;
  static const _sharePreferenceKey = 'bastion.share_phone_location';
  static const _precisionPreferenceKey = 'bastion.share_location_precision';
  int _locationPrecision = BastionPhonePositionSharer.precise;
  static const _lowPowerPreferenceKey = 'bastion.low_power_mode';
  bool _sharePhoneLocation = false;
  bool _lowPowerMode = false;
  BastionPhonePositionSharer? _sharer;
  String? _locationShareProblem;
  late final AppLifecycleListener _lifecycle;
  bool _inForeground = true;
  final BastionSpeaker _speaker;
  late final BastionReconnectSupervisor _reconnect = BastionReconnectSupervisor(
    reconnect: _reconnectLastDevice,
    mayReconnect: () =>
        _lastDevice != null &&
        BastionReconnectPolicy.shouldReconnect(
          userDisconnected: _userDisconnected,
          // Network and USB radios don't need Bluetooth.
          bluetoothEnabled: _bluetoothOn || !(_lastDevice?.usesBluetooth ?? true),
        ),
  );

  MeshtasticRadioSession? _session;
  MeshtasticHandshake? _handshake;
  MeshtasticNodeDatabase? _nodeDatabase;
  MeshtasticMessagingService? _messaging;
  MeshtasticAdminSession? _admin;
  MeshtasticTraceroute? _traceroute;
  StreamSubscription<List<MeshtasticNode>>? _nodeSubscription;
  StreamSubscription<MeshtasticNode>? _nodeVaultSubscription;
  StreamSubscription<void>? _messageSubscription;
  StreamSubscription<Uint8List>? _identitySubscription;
  StreamSubscription<void>? _linkLossSubscription;
  StreamSubscription<MeshtasticTextMessage>? _incomingSubscription;
  MeshtasticBleDevice? _lastDevice;
  bool _userDisconnected = false;
  List<MeshtasticNode> _nodes = const [];
  List<BastionChatMessage> _archivedMessages = const [];
  List<PendingTextMessage> _archivedPending = const [];
  bool _busy = false;
  bool _disposed = false;
  bool _botEnabled = false;
  String _botReply = MeshtasticMessagingService.defaultAwayReply;
  int? _localNodeNum;
  String? _firmwareVersion;
  DateTime _connectedAt = DateTime.now();
  String? get firmwareVersion => _firmwareVersion;
  final List<double> _snrHistory = [];
  int _receivedTextPackets = 0;
  final Map<int, BastionDeviceTelemetry> _deviceTelemetry = {};
  /// Evidence belongs to this connection, never to a hardware name/version.
  final Map<String, String> settingsAvailability = {};
  bool checkingSettings = false;
  bool _cancelSettingsCheck = false;
  void cancelSettingsCheck() { _cancelSettingsCheck = true; notifyListeners(); }

  String availability(String key) => settingsAvailability[key] ?? 'Not checked';

  Future<T> _readSection<T>(String key, Future<T> Function() read) async {
    final admin = _admin;
    try {
      final value = await read();
      if (admin == _admin) settingsAvailability[key] = 'Available';
      return value;
    } on MeshtasticSettingsUnavailable {
      if (admin == _admin) settingsAvailability[key] = 'Not returned by this radio';
      rethrow;
    } catch (_) {
      if (admin == _admin) settingsAvailability[key] = 'Read failed — retry';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> checkSettingsAvailability() async {
    if (checkingSettings || !canAdminister) return;
    final admin = _admin;
    checkingSettings = true;
    _cancelSettingsCheck = false;
    notifyListeners();
    try {
      for (final type in AdminMessage_ConfigType.values) {
        if (_cancelSettingsCheck || admin != _admin || !canAdminister) break;
        if (type == AdminMessage_ConfigType.SESSIONKEY_CONFIG) continue;
        try { await readConfig(type); } catch (_) { /* Recorded by _readSection. */ }
      }
      for (final type in AdminMessage_ModuleConfigType.values) {
        if (_cancelSettingsCheck || admin != _admin || !canAdminister) break;
        try { await readModuleConfig(type); } catch (_) { /* Recorded by _readSection. */ }
      }
    } finally {
      checkingSettings = false;
      notifyListeners();
    }
  }

  StreamSubscription<PhoneFix>? _coverageLocation;
  PhoneFix? _coverageFix;
  String? coverageProblem;
  bool get recordingCoverage => BastionFieldLog.instance.recording;

  Future<void> setCoverageRecording(bool enabled) async {
    await _coverageLocation?.cancel();
    _coverageLocation = null;
    _coverageFix = null;
    BastionFieldLog.instance.stop();
    coverageProblem = null;
    if (enabled) {
      final session = _session;
      if (!isReady || _localNodeNum == null) throw StateError('Connect to a radio first.');
      final problem = await _location.ensureAccess();
      if (session != _session || !isReady) throw StateError('Radio disconnected while requesting location.');
      if (problem != null) { coverageProblem = problem; notifyListeners(); throw StateError(problem); }
      BastionFieldLog.instance.start(_localNodeNum!);
      try {
      _coverageLocation = _location.watch().listen((fix) => _coverageFix = fix,
        onError: (Object error) {
          BastionFieldLog.instance.stop();
          coverageProblem = 'Location stopped: $error';
          notifyListeners();
        }, onDone: () { BastionFieldLog.instance.stop(); notifyListeners(); });
      } catch (error) {
        BastionFieldLog.instance.stop();
        coverageProblem = 'Location could not start: $error';
        notifyListeners();
        rethrow;
      }
    }
    notifyListeners();
  }

  final List<Uint8List> _radioConfigSnapshots = [];
  final List<Uint8List> _channelSnapshots = [];
  final List<Uint8List> _moduleConfigSnapshots = [];

  /// Ignored and muted nodes and word filters.
  final BastionFilters filters = BastionFilters();

  /// Nodes to show: every known node except ignored ones.
  List<MeshtasticNode> get nodes =>
      filters.ignored.isEmpty ? _nodes : [for (final n in _nodes) if (!filters.isIgnored(n.num)) n];

  /// Every known node, including ignored ones (for unignoring and safety logic).
  List<MeshtasticNode> get allNodes => _nodes;

  /// The connected radio's history, without messages from ignored nodes and,
  /// unless shown, incoming messages that contain a filtered word. Until the
  /// radio identifies itself, the last radio's history plus anything new.
  List<BastionChatMessage> get messages =>
      [for (final m in _allMessages) if (!_hidden(m, includeWords: !filters.showFiltered)) m];

  /// Incoming messages currently hidden only by word filters.
  int get filteredMessageCount => filters.words.isEmpty
      ? 0
      : _allMessages.where((m) => !_hidden(m, includeWords: false) && _hidden(m, includeWords: true)).length;

  bool _hidden(BastionChatMessage m, {required bool includeWords}) =>
      m.direction == BastionMessageDirection.incoming &&
      (filters.isIgnored(m.from) || (includeWords && filters.matchesWord(m.text)));

  /// Every message, including hidden ones (for trip and SOS safety logic).
  List<BastionChatMessage> get allMessages => _allMessages;

  List<BastionChatMessage> get _allMessages {
    final messaging = _messaging;
    if (messaging == null) return _archivedMessages;
    if (messaging.archive != null) return messaging.messages;
    return BastionRadioHistory.mergeMessages(_archivedMessages, messaging.messages);
  }

  String? get botProblem => _messaging?.botProblem;
  int get pendingMessageCount {
    final messaging = _messaging;
    if (messaging == null) return _archivedPending.length;
    if (messaging.archive != null) return messaging.pending.length;
    return _archivedPending.length + messaging.pending.length;
  }
  bool get busy => _busy;
  bool get isReady => connection.isReady;
  bool get isReconnecting => _reconnect.isRunning || _waitingForBluetooth;

  /// The last radio was reached over Wi-Fi or Ethernet rather than Bluetooth.
  bool get usesNetworkLink => _lastDevice?.isNetwork ?? false;

  /// The last radio was on a USB cable.
  bool get usesUsbLink => _lastDevice?.isUsb ?? false;

  /// Name of the last radio, for USB and network links.
  String? get linkName => _lastDevice?.name;

  /// Host of the network radio, when [usesNetworkLink].
  String? get networkHost => _lastDevice?.networkAddress?.host;
  bool get bluetoothOn => _bluetoothOn;
  int? get localNodeNum => _localNodeNum;

  /// Whether radio settings can be read and written right now.
  bool get canAdminister =>
      !_busy && connection.isReady && _admin != null && firmwareSupport != FirmwareSupport.unsupported;

  /// How well the radio's firmware suits the app; unknown until it reports.
  FirmwareSupport get firmwareSupport => BastionFirmware.supportOf(_firmwareVersion);

  /// Whether the phone's location is sent to the radio for broadcasting.
  bool get sharePhoneLocation => _sharePhoneLocation;

  /// Why sharing is not running, e.g. permission denied; null when fine.
  String? get locationShareProblem => _locationShareProblem;
  DateTime? get lastPhonePositionSent => _sharer?.lastSentAt;

  /// Whether phone location sharing uses balanced accuracy and fewer updates.
  bool get lowPowerMode => _lowPowerMode;

  Future<void> setLowPowerMode(bool enabled) async {
    if (enabled == _lowPowerMode) return;
    _lowPowerMode = enabled;
    notifyListeners();
    try {
      await SharedPreferencesAsync().setBool(_lowPowerPreferenceKey, enabled);
    } catch (_) {
      // Preference storage is best effort.
    }
    await _restartSharing();
  }

  /// Restarts a running share so it picks up the current power mode.
  Future<void> _restartSharing() async {
    if (_sharer == null) return;
    await _sharer?.stop();
    _sharer = null;
    await _startSharing();
  }

  /// Position precision bits for shared phone location; see
  /// [BastionPhonePositionSharer.precisionChoices].
  int get locationPrecision => _locationPrecision;

  Future<void> setLocationPrecision(int bits) async {
    if (!BastionPhonePositionSharer.precisionChoices.containsKey(bits) || bits == _locationPrecision) return;
    _locationPrecision = bits;
    notifyListeners();
    try {
      await SharedPreferencesAsync().setInt(_precisionPreferenceKey, bits);
    } catch (_) {
      // Preference storage is best effort.
    }
    await _restartSharing();
  }

  Future<void> setSharePhoneLocation(bool enabled) async {
    _sharePhoneLocation = enabled;
    _locationShareProblem = null;
    notifyListeners();
    try {
      await SharedPreferencesAsync().setBool(_sharePreferenceKey, enabled);
    } catch (_) {
      // Preference storage is best effort.
    }
    if (enabled) {
      await _startSharing();
    } else {
      await _sharer?.stop();
      _sharer = null;
      notifyListeners();
    }
  }

  Future<void> _loadSharePreference() async {
    try {
      final preferences = SharedPreferencesAsync();
      _sharePhoneLocation =
          await preferences.getBool(_sharePreferenceKey) ?? false;
      final lowPower =
          await preferences.getBool(_lowPowerPreferenceKey) ?? false;
      final precision = await preferences.getInt(_precisionPreferenceKey);
      if (precision != null &&
          BastionPhonePositionSharer.precisionChoices.containsKey(precision) &&
          precision != _locationPrecision) {
        _locationPrecision = precision;
        await _restartSharing();
      }
      notifyListeners();
      if (lowPower != _lowPowerMode) {
        _lowPowerMode = lowPower;
        notifyListeners();
        await _restartSharing();
      }
    } catch (_) {
      // Default stays off.
    }
  }

  Future<void> _startSharing() async {
    final session = _session;
    final nodeNum = _localNodeNum;
    if (!_sharePhoneLocation ||
        session == null ||
        nodeNum == null ||
        !connection.isReady) {
      return;
    }
    if (_sharer?.isRunning ?? false) return;
    final sharer = BastionPhonePositionSharer(
      source: _location,
      send: session.send,
      localNodeNum: nodeNum,
      lowPower: _lowPowerMode,
      precisionBits: _locationPrecision,
    );
    _sharer = sharer;
    _locationShareProblem = await sharer.start();
    if (_locationShareProblem != null) _sharer = null;
    notifyListeners();
  }

  /// Latest neighbor report per node, for nodes running the Neighbor Info
  /// module. Cleared when the radio disconnects.
  Map<int, MeshNeighborReport> get neighborReports =>
      _nodeDatabase?.neighborReports ?? const {};

  bool get canTraceroute =>
      !_busy &&
      connection.isReady &&
      _traceroute != null &&
      !_traceroute!.isRunning;
  MeshtasticNode? get localNode {
    final num = _localNodeNum;
    if (num == null) return null;
    for (final node in _nodes) {
      if (node.num == num) return node;
    }
    return null;
  }

  List<BastionNodeRecord> get nodeVault => _nodeVault.records;

  /// Every node this phone has heard on any radio, with behaviour, tags and notes.
  BastionNodeJournal get nodeJournal => _journal;
  List<double> get snrHistory => List.unmodifiable(_snrHistory);
  double? get latestSnr => _snrHistory.isEmpty ? null : _snrHistory.last;
  int get receivedTextPackets => _receivedTextPackets;
  Map<int, BastionDeviceTelemetry> get deviceTelemetry =>
      Map.unmodifiable(_deviceTelemetry);
  List<String> get loraSettings {
    String? latest;
    for (final payload in _radioConfigSnapshots) {
      try {
        final summary = BastionRadioConfigCodec.loraSummary(payload);
        if (summary != null) latest = summary;
      } on FormatException {
        // Ignore malformed configuration frames.
      }
    }
    return List.unmodifiable([if (latest != null) latest]);
  }

  List<String> get channelSettings =>
      BastionRadioConfigCodec.channelSummaries(_channelSnapshots);

  /// Latest valid metadata for each channel slot, without exposing PSKs.
  List<({int index, int role, String name})> get channelMetadata {
    final bySlot = <int, ({int index, int role, String name})>{};
    for (final payload in _channelSnapshots) {
      try {
        final metadata = BastionRadioConfigCodec.channelMetadata(payload);
        bySlot[metadata.index] = metadata;
      } on FormatException {
        // Ignore malformed frames without hiding valid channel snapshots.
      }
    }
    final sorted = bySlot.values.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    return List.unmodifiable(sorted);
  }

  /// The radio's current LoRa settings, from the latest config it sent.
  Config_LoRaConfig? get loraConfig {
    Config_LoRaConfig? latest;
    for (final bytes in _radioConfigSnapshots) {
      try {
        final c = Config.fromBuffer(bytes);
        if (c.hasLora()) latest = c.lora;
      } catch (_) {
        // Ignore malformed configuration frames.
      }
    }
    return latest;
  }

  int get radioConfigCount => _radioConfigSnapshots.length;
  int get channelConfigCount => _channelSnapshots.length;
  int get moduleConfigCount => _moduleConfigSnapshots.length;

  Future<void> setNodeFavorite(int num, bool value) async {
    await _nodeVault.setFavorite(num, value);
    notifyListeners();
  }

  Future<void> setNodeNote(int num, String note) async {
    await _nodeVault.setNote(num, note);
    notifyListeners();
  }

  /// Shows the last connected radio's history until a radio connects.
  final BastionTrails _trails = BastionTrails();

  final BastionDayTracks _dayTracks = BastionDayTracks();

  /// Team positions kept by day for Day replay.
  BastionDayTracks get dayTracks => _dayTracks;

  /// Recent movement of a trip contact or this radio, oldest first.
  List<TrailPoint> trailOf(int num) => _trails.trailOf(num);

  final BastionTelemetryHistory _telemetryHistory = BastionTelemetryHistory();

  /// Metrics with saved readings for [num], for charts.
  List<TelemetryMetric> telemetryMetricsOf(int num) => _telemetryHistory.metricsOf(num);

  /// Saved readings of [metric] from [num], oldest first.
  List<TelemetryPoint> telemetrySeries(int num, TelemetryMetric metric) =>
      _telemetryHistory.seriesOf(num, metric);

  final BastionRadioData _radioData = BastionRadioData();

  /// Radios with messages, NodeVault history or trails on this phone.
  Future<List<StoredRadio>> storedRadios() => _radioData.list();

  /// Hands [from]'s messages, offline queue, NodeVault history, trails and telemetry to
  /// the connected radio (after a radio is lost or replaced). The connected
  /// radio's own data is kept, merged with it, and also copied aside first.
  /// [from]'s copy is deleted only when everything was saved. Returns a
  /// problem for the user, or null when done.
  Future<String?> moveRadioData(int from) async {
    final messaging = _messaging;
    final to = _localNodeNum;
    if (!isReady || messaging == null || to == null || messaging.archive?.radio != to) {
      return 'Connect to the new radio first.';
    }
    if (from == to) return 'That is the connected radio.';
    final old = BastionMessageArchive(radio: from);
    final snapshot = await old.load();
    if (!old.canSave || old.problem != null) {
      return "The old radio's messages could not be fully read, so nothing was moved.";
    }
    try {
      await _radioData.keepBeforeMove(to);
    } catch (_) {
      return "This radio's data could not be copied aside first, so nothing was moved.";
    }
    final messagesSaved = await messaging.importHistory(snapshot);
    final nodesSaved = await _nodeVault.importRadio(from);
    final trailsSaved = await _trails.importRadio(from) &&
        await _telemetryHistory.importRadio(from);
    _syncMessageSnapshot(messaging);
    notifyListeners();
    if (!messagesSaved || !nodesSaved || !trailsSaved) {
      return "Some of it could not be saved, so the old radio's copy was kept.";
    }
    try {
      await _radioData.remove(from);
    } catch (_) {
      return "Moved, but the old radio's copy could not be deleted.";
    }
    return null;
  }

  Future<void> _loadArchive() async {
    final last = await _history.lastRadio();
    if (last != null) _setArchive(BastionMessageArchive(radio: last));
    await _nodeVault.useRadio(last);
    if (last != null) await _trails.useRadio(last);
    if (last != null) await _telemetryHistory.useRadio(last);
    final snapshot = await _archive.load();
    _archivedMessages = snapshot.messages;
    _archivedPending = snapshot.pending;
    notifyListeners();
  }

  void _setArchive(BastionMessageArchive archive) {
    _archive.removeListener(notifyListeners);
    _archive = archive;
    _archive.addListener(notifyListeners);
  }

  /// Switches chat history, the offline queue and NodeVault to the radio that
  /// just identified itself, moving unassigned history to radios first.
  Future<void> _useRadioHistory(MeshtasticMessagingService messaging, int nodeNum) async {
    await _archiveLoaded;
    if (_messaging != messaging || messaging.archive?.radio == nodeNum) return;
    final archive = await _history.open(nodeNum);
    if (_messaging != messaging) return;
    _setArchive(archive);
    await messaging.attachArchive(archive);
    await _nodeVault.useRadio(nodeNum);
    await _trails.useRadio(nodeNum);
    await _telemetryHistory.useRadio(nodeNum);
    if (_messaging == messaging) _syncMessageSnapshot(messaging);
    notifyListeners();
  }

  void configureBot({required bool enabled, required String reply}) {
    _botEnabled = enabled;
    _botReply = reply;
    _messaging?.configureBot(
      enabled: enabled,
      reply: reply,
      nodeNum: _localNodeNum,
    );
    notifyListeners();
  }

  Future<void> connect(MeshtasticBleDevice device) async {
    if (_busy) return;
    _reconnect.cancel();
    _userDisconnected = false;
    _lastDevice = device;
    try {
      await _open(device);
    } catch (_) {
      await _background.release();
      rethrow;
    }
  }

  Future<void> _open(MeshtasticBleDevice device) async {
    if (_busy) throw StateError('Radio connection is already in progress.');
    _busy = true;
    notifyListeners();

    try {
      await _shutdownSession(resetConnection: false);
      _snrHistory.clear();
      _receivedTextPackets = 0;
      _deviceTelemetry.clear();
      _firmwareVersion = null;
      _connectedAt = DateTime.now();
      settingsAvailability.clear();
    _radioConfigSnapshots.clear();
      _channelSnapshots.clear();
      _moduleConfigSnapshots.clear();

      final MeshtasticLinkTransport transport = switch ((device.networkAddress, device.usbDeviceId)) {
        (final address?, _) => MeshtasticTcpTransport(host: address.host, port: address.port),
        (_, final usb?) => MeshtasticUsbTransport(deviceId: usb),
        _ => MeshtasticUniversalBleTransport(deviceId: device.id),
      };
      final session = MeshtasticRadioSession(
        transport: transport,
        connection: connection,
      );
      final nodeDatabase = MeshtasticNodeDatabase(session);
      // History is attached once the radio reports its node number.
      final messaging = MeshtasticMessagingService(
        session: session,
        connection: connection,
      )
        ..channelMessageMaxAge = _channelMaxAge
        ..historyLimit = BastionPreferences.instance.historyLimit
        ..isIgnoredSender = filters.isIgnored;
      _nodeVault.detach();
      final handshake = MeshtasticHandshake(
        session: session,
        connection: connection,
      );

      _session = session;
      _nodeDatabase = nodeDatabase;
      _messaging = messaging;
      _handshake = handshake;
      _linkLossSubscription = transport.linkLost.listen(
        (_) => unawaited(_handleLinkLoss()),
      );
      _meshToolsSubscription = session.incomingEnvelopes.listen((bytes) {
        if (recordingCoverage) {
          try {
            final envelope = pb.FromRadio.fromBuffer(bytes);
            if (envelope.hasPacket()) {
              unawaited(BastionFieldLog.instance.observe(envelope.packet, _coverageFix, DateTime.now())
                .catchError((Object _) { coverageProblem = BastionFieldLog.instance.error; notifyListeners(); }));
            }
          } on InvalidProtocolBufferException { /* Ignore malformed frames. */ }
        }
        if (_meshTools.handleEnvelope(bytes)) {
          _maybeCatchUp();
          notifyListeners();
        }
      });
      _waypointSubscription = session.incomingEnvelopes.listen((bytes) async {
        try {
          final envelope = pb.FromRadio.fromBuffer(bytes);
          if (envelope.hasPacket() &&
              (await _waypoints.handlePacket(envelope.packet) ||
                  await _beacons.handlePacket(envelope.packet))) {
            notifyListeners();
          }
        } catch (_) {
          // Malformed frames are handled by the other decoders.
        }
      });

      _identitySubscription = session.incomingEnvelopes.listen((bytes) {
        final envelope = MeshtasticPhoneApiCodec.decodeFromRadio(bytes);
        if (envelope.kind == FromRadioPayloadKind.metadata &&
            envelope.payload != null) {
          try {
            _firmwareVersion = pb.DeviceMetadata.fromBuffer(envelope.payload!)
                .firmwareVersion;
            if (BastionRadioPolicy.firmwareAtLeast28(_firmwareVersion)) {
              _deviceTelemetry.removeWhere(
                (_, value) => !value.batteryIsFreshSince(_connectedAt),
              );
            }
            notifyListeners();
          } on InvalidProtocolBufferException {
            // Ignore malformed metadata; never infer a firmware version.
          }
        }
        if (envelope.payload != null) {
          final target = switch (envelope.kind) {
            FromRadioPayloadKind.config => _radioConfigSnapshots,
            FromRadioPayloadKind.channel => _channelSnapshots,
            FromRadioPayloadKind.moduleConfig => _moduleConfigSnapshots,
            _ => null,
          };
          if (target != null) {
            target.add(Uint8List.fromList(envelope.payload!));
            if (envelope.kind == FromRadioPayloadKind.config || envelope.kind == FromRadioPayloadKind.moduleConfig) {
              final key = BastionSettingsEvidence.advertisedKey(envelope.payload!, module: envelope.kind == FromRadioPayloadKind.moduleConfig);
              if (key != null) settingsAvailability[key] = 'Available';
            }
            notifyListeners();
          }
        }
        if (envelope.kind == FromRadioPayloadKind.mqttClientProxyMessage && envelope.payload != null) {
          mqttProxy.fromRadio(envelope.payload!);
        }
        if (envelope.kind == FromRadioPayloadKind.packet &&
            envelope.payload != null) {
          try {
            final telemetry = BastionTelemetryCodec.decodeMeshPacket(
              envelope.payload!,
            );
            if (telemetry != null &&
                (!BastionRadioPolicy.firmwareAtLeast28(_firmwareVersion) ||
                    telemetry.batteryIsFreshSince(_connectedAt))) {
              _deviceTelemetry[telemetry.from] = telemetry;
              _raise(_fieldAlerts.battery(telemetry.from, telemetry.batteryLevel,
                  _nodeName(telemetry.from), favorite: _isFavorite(telemetry.from),
                  settings: _alertSettings));
              notifyListeners();
            }
            final reading = BastionTelemetryCodec.decodeReadings(envelope.payload!);
            if (reading != null) {
              _telemetryHistory.record(reading.from, reading.readings, sampleTime: reading.time);
              notifyListeners();
            }
            final packet = MeshtasticTextCodec.decodeMeshPacket(
              envelope.payload!,
            );
            if (packet != null) {
              _receivedTextPackets++;
              if (packet.rxSnr != null && packet.rxSnr!.isFinite) {
                _snrHistory.add(packet.rxSnr!);
                if (_snrHistory.length > 60) _snrHistory.removeAt(0);
              }
              notifyListeners();
            }
          } on FormatException {
            // Non-text or malformed packets must not disrupt the BLE session.
          }
        }
        if (envelope.kind == FromRadioPayloadKind.myInfo &&
            envelope.payload != null) {
          final nodeNum = MeshtasticPhoneApiCodec.decodeMyNodeNum(
            envelope.payload!,
          );
          if (nodeNum != null) {
            _localNodeNum = nodeNum;
            unawaited(_useRadioHistory(messaging, nodeNum));
            messaging.configureBot(
              enabled: _botEnabled,
              reply: _botReply,
              nodeNum: nodeNum,
            );
            notifyListeners();
          }
        }
      });

      await nodeDatabase.start();
      await messaging.start();
      messaging.configureBot(
        enabled: _botEnabled,
        reply: _botReply,
        nodeNum: _localNodeNum,
      );
      _syncMessageSnapshot(messaging);
      _nodeSubscription = nodeDatabase.changes.listen((nodes) {
        _nodes = nodes;
        for (final n in nodes) {
          if (n.publicKey != null) unawaited(_checkNodeKey(n));
        }
        _trails.record(nodes, {...trip.plan.members, ?_localNodeNum});
        unawaited(_dayTracks.record(nodes, {...trip.plan.members, ?_localNodeNum}));
        _checkGeofences(nodes);
        unawaited(_nodeVault.rememberPositions(nodes));
        notifyListeners();
      });
      _nodeVaultSubscription = nodeDatabase.nodeUpdates.listen((node) {
        if (connection.isReady) {
          _raise(_fieldAlerts.nodeHeard(node.num, node.displayName,
              knownBefore: _nodeVault.records.any((r) => r.num == node.num),
              settings: _alertSettings));
        }
        unawaited(_nodeVault.observe(node).then((_) => notifyListeners()));
        unawaited(_journal.observe(node));
      });
      _messageSubscription = messaging.changes.listen((_) {
        _syncMessageSnapshot(messaging);
        notifyListeners();
      });
      _incomingSubscription = messaging.incoming.listen(
        _alertIncoming,
        onError: (Object _) {},
      );

      await session.connect(deviceName: device.name);
      await handshake.synchronize();
      final nodeNum = _localNodeNum;
      if (nodeNum != null && nodeNum != 0) {
        _admin = MeshtasticAdminSession(
          incoming: session.incomingEnvelopes,
          send: session.send,
          localNodeNum: nodeNum,
        );
        _traceroute = MeshtasticTraceroute(
          incoming: session.incomingEnvelopes,
          send: session.send,
          localNodeNum: nodeNum,
        );
      }
      await messaging.flush();
      unawaited(_startSharing());
      if (nodeNum != null && nodeNum != 0) _startFieldAlerts(nodeNum);

      _nodes = nodeDatabase.nodes;
      _syncMessageSnapshot(messaging);
      notifyListeners();
      unawaited(
        _background.keepAlive(radioName: device.name, reconnecting: false),
      );
    } catch (_) {
      await _shutdownSession(resetConnection: false);
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Prepares a local owner update without sending it to the radio.
  ///
  /// This separates user input validation from the authenticated admin write.
  Uint8List prepareNodeIdentityUpdate({
    required String longName,
    required String shortName,
  }) => BastionOwnerCodec.encodeAdminSetOwner(
    longName: longName,
    shortName: shortName,
  );

  /// Observes a fresh local NodeInfo update after an authorized owner write.
  /// Call before transmitting to avoid missing a fast radio response.
  Future<MeshtasticNode> verifyNodeIdentityUpdate({
    required String longName,
    required String shortName,
    Duration timeout = const Duration(seconds: 20),
  }) {
    final local = _localNodeNum;
    final database = _nodeDatabase;
    if (!connection.isReady || local == null || database == null) {
      throw StateError('Connected radio node database is unavailable.');
    }
    return BastionOwnerReadback.waitForMatchingUpdate(
      updates: database.nodeUpdates,
      localNodeNum: local,
      longName: longName,
      shortName: shortName,
      timeout: timeout,
    );
  }

  /// Sends a pre-encoded, authorized AdminMessage to the connected local radio.
  ///
  /// This is a low-level transport operation, not a completed settings save.
  /// Callers must obtain user confirmation, perform any firmware-required admin
  /// authentication, await the admin response, and verify a fresh readback.
  /// It deliberately does not queue admin writes while offline.
  Future<int> sendAuthorizedAdminMessage({
    required Uint8List adminMessage,
    required bool userConfirmed,
    int channel = 0,
  }) async {
    if (!userConfirmed) {
      throw StateError('Radio configuration changes require confirmation.');
    }
    if (_busy || !connection.isReady) {
      throw StateError('Radio must be connected and ready for administration.');
    }
    final session = _session;
    final nodeNum = _localNodeNum;
    if (session == null || nodeNum == null || nodeNum == 0) {
      throw StateError('Connected radio identity is not available.');
    }
    var packetId = DateTime.now().microsecondsSinceEpoch & 0xffffffff;
    if (packetId == 0) packetId = 1;
    final envelope = BastionAdminPacketCodec.toRadio(
      adminMessage: adminMessage,
      localNode: nodeNum,
      packetId: packetId,
      channel: channel,
    );
    await session.send(envelope);
    return packetId;
  }

  MeshtasticAdminSession _requireAdmin() {
    final admin = _admin;
    if (!canAdminister || admin == null) {
      throw StateError('Radio must be connected and ready to change settings.');
    }
    return admin;
  }

  @override
  int get backupNodeNum => canAdminister && _localNodeNum != null
      ? _localNodeNum! : throw StateError('Connect to a ready radio first.');
  @override
  String get backupFirmware => _firmwareVersion ?? 'unknown';
  @override
  List<AdminMessage_ConfigType> get backupConfigTypes => _radioConfigSnapshots
      .map(Config.fromBuffer)
      .where((c) => !c.hasSecurity() && !c.hasSessionkey() && c.whichPayloadVariant() != Config_PayloadVariant.notSet)
      .map(RadioBackupSnapshot.configType).toSet().toList();
  @override
  List<AdminMessage_ModuleConfigType> get backupModuleTypes => _moduleConfigSnapshots
      .map(ModuleConfig.fromBuffer)
      .where((m) => m.whichPayloadVariant() != ModuleConfig_PayloadVariant.notSet)
      .map(RadioBackupSnapshot.moduleType).toSet().toList();

  @override
  Future<void> writeBackup(RadioBackupSnapshot snapshot) async {
    final admin = _requireAdmin();
    await admin.editTransaction(() async {
      await admin.setOwner(snapshot.owner);
      for (final c in snapshot.channels) { await admin.setChannel(c); }
      for (final m in snapshot.modules) { await admin.setModuleConfig(m); }
      for (final c in snapshot.configs) { await admin.setConfig(c); }
    });
  }

  @override
  Future<void> waitForBackupRadio(int nodeNum) => waitForSettingsRadio(nodeNum);

  /// Waits for the same local radio before a fresh settings read.
  Future<void> waitForSettingsRadio(int nodeNum) async {
    // Allow a commit-triggered reboot to start before accepting a ready link.
    await Future<void>.delayed(const Duration(seconds: 3));
    final deadline = DateTime.now().add(const Duration(seconds: 90));
    while (DateTime.now().isBefore(deadline)) {
      if (_localNodeNum != null && _localNodeNum != nodeNum) {
        throw StateError('Connected radio changed while verifying settings.');
      }
      if (canAdminister && _localNodeNum == nodeNum) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw TimeoutException('Reconnect to the same radio, then verify its settings.');
  }

  Future<User> readOwner() => _requireAdmin().getOwner();

  Future<Config> readConfig(AdminMessage_ConfigType type) async {
    final admin = _requireAdmin();
    final config = await _readSection('config:${type.value}', () => admin.getConfig(type));
    if (_admin == admin) {
      _radioConfigSnapshots.removeWhere((bytes) {
        try { return Config.fromBuffer(bytes).whichPayloadVariant() == config.whichPayloadVariant(); }
        on InvalidProtocolBufferException { return false; }
      });
      _radioConfigSnapshots.add(config.writeToBuffer());
      notifyListeners();
    }
    return config;
  }

  Future<Channel> readChannel(int index) async {
    final admin = _requireAdmin();
    final channel = await admin.getChannel(index);
    if (_admin == admin) {
      _channelSnapshots.removeWhere((bytes) {
        try { return BastionRadioConfigCodec.channelMetadata(bytes).index == index; }
        on FormatException { return false; }
      });
      _channelSnapshots.add(channel.writeToBuffer());
      notifyListeners();
    }
    return channel;
  }

  Future<ModuleConfig> readModuleConfig(AdminMessage_ModuleConfigType type) async {
    final admin = _requireAdmin();
    final config = await _readSection('module:${type.value}', () => admin.getModuleConfig(type));
    if (_admin == admin) {
      _moduleConfigSnapshots.removeWhere((bytes) {
        try { return ModuleConfig.fromBuffer(bytes).whichPayloadVariant() == config.whichPayloadVariant(); }
        on InvalidProtocolBufferException { return false; }
      });
      _moduleConfigSnapshots.add(config.writeToBuffer());
      notifyListeners();
    }
    return config;
  }

  /// Writes are acknowledged by the radio; many make it reboot, after which
  /// the reconnect supervisor restores the link.
  Future<void> writeOwner(User owner) => _requireAdmin().setOwner(owner);

  Future<void> writeConfig(Config config) => _requireAdmin().setConfig(config);

  Future<void> writeChannel(Channel channel) =>
      _requireAdmin().setChannel(channel);

  Future<void> writeModuleConfig(ModuleConfig config) =>
      _requireAdmin().setModuleConfig(config);

  /// The radio's enabled channels in slot order plus its LoRa config, as
  /// shared in a channel link.
  Future<ChannelSet> readChannelSet() async {
    final admin = _requireAdmin();
    final settings = [
      for (var i = 0; i < 8; i++)
        if (await admin.getChannel(i) case final channel
            when channel.role != Channel_Role.DISABLED)
          channel.settings,
    ];
    final lora = (await admin.getConfig(AdminMessage_ConfigType.LORA_CONFIG))
        .lora;
    return ChannelSet(settings: settings, loraConfig: lora);
  }

  /// Applies a shared channel set and confirms it with a fresh read from
  /// the same radio; see [BastionChannelImport.apply].
  Future<int> applyChannelSet(ChannelSet set, {required bool replace}) =>
      BastionChannelImport(this).apply(set, replace: replace);

  @override
  Future<void> writeChannelImport(List<Channel> channels, Config? lora) async {
    final admin = _requireAdmin();
    await admin.editTransaction(() async {
      for (final channel in channels) {
        await admin.setChannel(channel);
      }
      if (lora != null) await admin.setConfig(lora);
    });
  }

  /// Asks [nodeNum] to send its position. The reply updates [nodes].
  ///
  /// Like the official apps, the request carries this radio's own position
  /// when one is known, so the other node learns where we are too.
  Future<void> requestPosition(int nodeNum) {
    final own = localNode;
    return _requestFrom(
      nodeNum,
      PortNum.POSITION_APP,
      (own != null && own.hasPosition
              ? pb.Position(
                  latitudeI: (own.latitude! * 1e7).round(),
                  longitudeI: (own.longitude! * 1e7).round(),
                )
              : pb.Position())
          .writeToBuffer(),
    );
  }

  /// Asks [nodeNum] for device telemetry. The reply updates [deviceTelemetry].
  Future<void> requestTelemetry(int nodeNum) => _requestFrom(
    nodeNum,
    PortNum.TELEMETRY_APP,
    Telemetry(deviceMetrics: DeviceMetrics()).writeToBuffer(),
  );

  /// Asks [nodeNum] for environment sensor readings (temperature, humidity
  /// and so on); nodes without sensors don't answer.
  Future<void> requestEnvironmentTelemetry(int nodeNum) => _requestFrom(
    nodeNum,
    PortNum.TELEMETRY_APP,
    Telemetry(environmentMetrics: EnvironmentMetrics()).writeToBuffer(),
  );

  Future<void> _requestFrom(
    int nodeNum,
    PortNum port,
    List<int> payload,
  ) async {
    final session = _session;
    if (_busy || !connection.isReady || session == null) {
      throw StateError('Radio must be connected and ready.');
    }
    if (nodeNum == _localNodeNum) {
      throw ArgumentError.value(nodeNum, 'nodeNum', 'is this radio');
    }
    var id = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    if (id == 0) id = 1;
    await session.send(
      pb.ToRadio(
        packet: pb.MeshPacket(
          to: nodeNum,
          id: id,
          wantAck: true,
          decoded: pb.Data(portnum: port, payload: payload, wantResponse: true),
        ),
      ).writeToBuffer(),
    );
  }

  List<MeshWaypoint> get waypoints => _waypoints.waypoints;

  /// Range test packets heard this app session, oldest first.
  List<RangeTestEntry> get rangeTest => _meshTools.rangeTest;

  void clearRangeTest() {
    _meshTools.clearRangeTest();
    notifyListeners();
  }

  /// Store & Forward servers heard via their heartbeats.
  List<StoreForwardRouter> get storeForwardRouters => _meshTools.routers;
  String? get lastStoreForwardReply => _meshTools.lastRouterReply;

  /// Asks [router] to replay messages from the last [window]. Replayed
  /// messages arrive in Chats like any other message.
  Future<void> requestStoredMessages(int router, Duration window) async {
    final session = _session;
    if (_busy || !connection.isReady || session == null) {
      throw StateError('Radio must be connected and ready.');
    }
    _meshTools.lastRouterReply = null;
    await session.send(
      MeshtasticMeshTools.encodeHistoryRequest(router, window),
    );
    notifyListeners();
  }

  /// Broadcasts [waypoint] on [channel] and keeps it locally.
  Future<void> sendWaypoint(MeshWaypoint waypoint, {int channel = 0}) async {
    final session = _session;
    if (_busy || !connection.isReady || session == null) {
      throw StateError('Radio must be connected and ready.');
    }
    await session.send(BastionWaypointStore.encode(waypoint, channel: channel));
    await _waypoints.apply(waypoint);
    notifyListeners();
  }

  Duration? get _channelMaxAge {
    final days = BastionPreferences.instance.channelRetentionDays;
    return days > 0 ? Duration(days: days) : null;
  }

  /// Carries MQTT for a radio without Wi-Fi; see [BastionMqttProxy].
  late final BastionMqttProxy mqttProxy = BastionMqttProxy(sendToRadio: (bytes) async {
    final session = _session;
    if (session != null) await session.send(bytes);
  });

  /// The radio's proxy settings, or null unless it asks for the proxy.
  MqttProxyConfig? get mqttProxyConfig {
    ModuleConfig_MQTTConfig? mqtt;
    for (final bytes in _moduleConfigSnapshots) {
      try {
        final m = ModuleConfig.fromBuffer(bytes);
        if (m.hasMqtt()) mqtt = m.mqtt;
      } catch (_) {}
    }
    if (mqtt == null) return null;
    var preset = Config_LoRaConfig_ModemPreset.LONG_FAST;
    for (final bytes in _radioConfigSnapshots) {
      try {
        final c = Config.fromBuffer(bytes);
        if (c.hasLora()) preset = c.lora.modemPreset;
      } catch (_) {}
    }
    final channels = <int, ChannelSettings>{};
    for (final bytes in _channelSnapshots) {
      try {
        final c = Channel.fromBuffer(bytes);
        if (c.role != Channel_Role.DISABLED) channels[c.index] = c.settings;
      } catch (_) {}
    }
    return MqttProxyConfig.from(mqtt,
        channels: channels.values, presetName: MqttProxyConfig.presetChannelName(preset));
  }

  void _syncMqttProxy() {
    final config = connection.isReady && BastionPreferences.instance.mqttProxy ? mqttProxyConfig : null;
    if (config == null) {
      if (mqttProxy.running) unawaited(mqttProxy.stop());
    } else if (!mqttProxy.running && mqttProxy.state != MqttProxyState.error) {
      unawaited(mqttProxy.start(config, clientId: 'notoryx-${(_localNodeNum ?? 0).toRadixString(16)}'));
    }
  }

  void _applyRetention() {
    final messaging = _messaging;
    if (messaging == null) return;
    messaging
      ..channelMessageMaxAge = _channelMaxAge
      ..historyLimit = BastionPreferences.instance.historyLimit
      ..pruneChannelMessages();
    _syncMessageSnapshot(messaging);
    notifyListeners();
  }

  /// Reacts to [target] with [emoji] (a Meshtastic tapback). Needs a ready
  /// radio; reactions are not queued.
  Future<void> sendReaction(BastionChatMessage target, String emoji) async {
    final messaging = _messaging;
    if (messaging == null || !connection.isReady) {
      throw StateError('Connect to a radio to react.');
    }
    final destination = target.isBroadcast
        ? MeshtasticTextCodec.broadcastNode
        : target.direction == BastionMessageDirection.incoming ? target.from : target.to;
    await messaging.sendText(text: emoji, destination: destination, channel: target.channel,
        replyId: target.packetId, reaction: true);
    _syncMessageSnapshot(messaging);
    notifyListeners();
  }

  /// Mesh Beacons heard on the mesh, newest first.
  List<HeardBeacon> get beacons => _beacons.beacons;

  /// When the next beacon may be sent; null when one may be sent now.
  DateTime? get nextBeaconAllowed => _beacons.nextSendAllowed;

  Future<void> clearBeacons() async {
    await _beacons.clear();
    notifyListeners();
  }

  /// Broadcasts a Mesh Beacon with [message] on the primary channel, at most
  /// once per [BastionBeaconLog.sendInterval]. With [offerPrimaryChannel] it
  /// also advertises the primary channel's name and key and this radio's
  /// region and modem preset, so listeners can join; that shares the key with
  /// anyone in range.
  Future<void> sendBeacon(String message, {bool offerPrimaryChannel = false}) async {
    BastionBeaconLog.checkMessage(message);
    if (_beacons.nextSendAllowed case final next?) {
      throw StateError('Beacons are limited to one an hour; the next can be sent at '
          '${next.toLocal().toString().substring(11, 16)}.');
    }
    final session = _session;
    if (_busy || !connection.isReady || session == null) {
      throw StateError('Radio must be connected and ready.');
    }
    final beacon = MeshBeacon(message: message.trim());
    if (offerPrimaryChannel) {
      final set = await readChannelSet();
      if (set.settings.isEmpty) throw StateError('This radio has no primary channel to offer.');
      beacon
        ..offerChannel = set.settings.first
        ..offerRegion = set.loraConfig.region;
      if (set.loraConfig.usePreset) beacon.offerPreset = set.loraConfig.modemPreset;
    }
    await session.send(BastionBeaconLog.encode(beacon));
    await _beacons.recordSent();
    notifyListeners();
  }

  /// Whether this radio may change or delete [waypoint].
  bool canEditWaypoint(MeshWaypoint waypoint) =>
      waypoint.lockedTo == 0 || waypoint.lockedTo == _localNodeNum;

  /// Removes [waypoint] for everyone by broadcasting it as expired.
  Future<void> deleteWaypoint(MeshWaypoint waypoint, {int channel = 0}) async {
    if (!canEditWaypoint(waypoint)) {
      throw StateError('This waypoint is locked to another node.');
    }
    await sendWaypoint(
      BastionWaypointStore.deletion(waypoint),
      channel: channel,
    );
  }

  /// Why [nodeNum] can't be administered over the mesh, or null if it can.
  String? remoteAdminProblem(int nodeNum) {
    // canAdminister already rules out firmware older than 2.5 (no PKI admin).
    if (!canAdminister || _session == null) return 'Connect to a radio first.';
    if (nodeNum == _localNodeNum) return 'This is your own radio. Use Radio settings.';
    final node = nodes.where((n) => n.num == nodeNum).firstOrNull;
    if (node?.publicKey == null) {
      return 'This node hasn\'t shared its security key yet. Wait for it to send its node info.';
    }
    if (_nodeKeys.hasChanged(nodeNum)) {
      return 'This node\'s key changed. Check it with the owner and trust the new key first.';
    }
    return null;
  }

  /// Opens an admin session to [nodeNum] over the mesh. The caller disposes it.
  MeshtasticAdminSession openRemoteAdmin(int nodeNum) {
    final problem = remoteAdminProblem(nodeNum);
    if (problem != null) throw StateError(problem);
    final session = _session!;
    return MeshtasticAdminSession(
      incoming: session.incomingEnvelopes,
      send: session.send,
      localNodeNum: _localNodeNum!,
      targetNodeNum: nodeNum,
      targetPublicKey: nodes.firstWhere((n) => n.num == nodeNum).publicKey,
    );
  }

  /// This radio's public key, which a remote node must add as an admin key.
  Uint8List? get localPublicKey => localNode?.publicKey;

  /// Traces the mesh route to [nodeNum]. Only one trace runs at a time.
  Future<TracerouteResult> traceroute(int nodeNum) async {
    final traceroute = _traceroute;
    if (!canTraceroute || traceroute == null) {
      throw StateError('Radio must be ready and idle to run a traceroute.');
    }
    final result = traceroute.trace(nodeNum);
    notifyListeners();
    try {
      return await result;
    } finally {
      notifyListeners();
    }
  }

  Future<int> sendText({
    required String text,
    int destination = MeshtasticTextCodec.broadcastNode,
    int channel = 0,
  }) async {
    final messaging = _messaging;
    if (messaging != null) {
      final id = await messaging.sendText(
        text: text,
        destination: destination,
        channel: channel,
      );
      _syncMessageSnapshot(messaging);
      notifyListeners();
      return id;
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(text, 'text', 'must not be empty');
    }
    var packetId = DateTime.now().microsecondsSinceEpoch & 0xffffffff;
    if (packetId == 0) packetId = 1;
    final pending = PendingTextMessage(
      text: trimmed,
      destination: destination,
      channel: channel,
      packetId: packetId,
    );
    await _archiveLoaded;
    _archivedPending = [..._archivedPending, pending];
    _archivedMessages = [
      ..._archivedMessages,
      BastionChatMessage(
        packetId: packetId,
        from: _localNodeNum ?? 0,
        to: destination,
        channel: channel,
        text: trimmed,
        timestamp: DateTime.now(),
        direction: BastionMessageDirection.outgoing,
        deliveryState: BastionDeliveryState.queued,
      ),
    ];
    _archivedMessages = BastionHistoryLimit.trim(
      _archivedMessages,
      BastionPreferences.instance.historyLimit,
    );
    await _archive.save(messages: _archivedMessages, pending: _archivedPending);
    notifyListeners();
    return packetId;
  }

  /// Notifies about a message that arrives while the app is backgrounded.
  Future<void> _sendNotificationReply(BastionLocalMessageAlerts alerts, BastionNotificationReply reply) async {
    try {
      await sendText(text: reply.text, destination: reply.destination, channel: reply.channel);
    } catch (_) {
      await alerts.showReplyFailed(reply.text);
    }
  }

  /// Asks for notification permission while the app is on screen (iOS).
  Future<void> prepareAlerts() async {
    final alerts = _alerts;
    if (alerts is! BastionLocalMessageAlerts) return;
    alerts.listenForReplies((reply) => unawaited(_sendNotificationReply(alerts, reply)));
    await alerts.prepare();
  }

  Future<void> _relaySms(MeshtasticTextMessage message) async {
    final reply = await BastionSmsRelay.instance.handle(
        from: message.from, text: message.text, isBroadcast: message.isBroadcast, packetId: message.packetId);
    if (reply == null || !isReady) return;
    try {
      await sendText(text: reply, destination: message.from, channel: message.channel);
    } catch (_) {
      // The reply is a courtesy; the SMS itself has already been handled.
    }
  }

  void _alertIncoming(MeshtasticTextMessage message) {
    if (filters.isSilenced(message.from) || filters.matchesWord(message.text)) return;
    if (BastionSmsRelay.available && !message.isReaction) unawaited(_relaySms(message));
    String sender = '!${message.from.toRadixString(16).padLeft(8, '0')}';
    for (final node in _nodes) {
      if (node.num == message.from) sender = node.displayName;
    }
    if (BastionPreferences.instance.readAloud && !message.isReaction) {
      unawaited(_speaker.speak(
          '${message.isBroadcast ? 'Channel message' : 'Message'} from $sender. ${message.text}'));
    }
    if (_inForeground) return;
    unawaited(
      _alerts.show(
        packetId: message.packetId,
        sender: sender,
        text: message.text,
        // A mention gets the same urgent alert as a direct message.
        isDirect: !message.isBroadcast || mentionsMe(message.text),
        channel: message.channel,
        replyDestination: message.isBroadcast ? MeshtasticTextCodec.broadcastNode : message.from,
      ),
    );
  }

  @visibleForTesting
  set inForeground(bool value) => _inForeground = value;

  /// Starts link recovery for [device] as if its link had just dropped.
  @visibleForTesting
  Future<void> recoverLinkForTest(MeshtasticBleDevice device) {
    _lastDevice = device;
    _userDisconnected = false;
    return _recoverLink(device);
  }

  @visibleForTesting
  void alertIncomingForTest(MeshtasticTextMessage message) =>
      _alertIncoming(message);

  /// Tears down a dropped session and retries the last radio with backoff.
  Future<void> _handleLinkLoss() async {
    final device = _lastDevice;
    if (_busy || _userDisconnected || device == null) return;
    await _shutdownSession(resetConnection: false);
    await _recoverLink(device);
  }

  void _handleBluetoothChange(bool on) {
    _bluetoothOn = on;
    final device = _lastDevice;
    if (on &&
        _waitingForBluetooth &&
        device != null &&
        !_userDisconnected &&
        !_busy &&
        _session == null &&
        !_reconnect.isRunning) {
      unawaited(_recoverLink(device));
    }
    notifyListeners();
  }

  Future<void> _recoverLink(MeshtasticBleDevice device) async {
    // Checked here rather than at startup: the change stream can miss a
    // state flip made while the app was suspended.
    _bluetoothOn = await _bluetooth.isOn();
    if (_userDisconnected) return;
    if (!_bluetoothOn && device.usesBluetooth) {
      _waitingForBluetooth = true;
      unawaited(
        _background.keepAlive(radioName: device.name, reconnecting: true),
      );
      connection.fail(
        StateError(
          'Bluetooth is off. NOTORYX Connect will reconnect to ${device.name} when it is turned back on.',
        ),
      );
      notifyListeners();
      return;
    }
    _waitingForBluetooth = false;
    connection.beginConnect(device.name);
    unawaited(
      _background.keepAlive(radioName: device.name, reconnecting: true),
    );
    final recovery = _reconnect.recover();
    notifyListeners();
    final recovered = await recovery;
    if (!recovered && !_bluetoothOn && device.usesBluetooth && !_userDisconnected) {
      // Bluetooth went off mid-recovery; wait for it instead of giving up.
      await _recoverLink(device);
      return;
    }
    if (!recovered && !_userDisconnected && !_busy && _session == null) {
      unawaited(_background.release());
      connection.fail(
        StateError(
          'Radio link lost; reconnect gave up after ${_reconnect.attempts} '
          'attempts. Last error: ${_reconnect.lastError}',
        ),
      );
    }
  }

  Future<void> _reconnectLastDevice() async {
    final device = _lastDevice;
    if (device == null) throw StateError('No radio to reconnect.');
    await _open(device);
    // The user may have pressed disconnect while this attempt was in flight.
    if (_userDisconnected) await _shutdownSession(resetConnection: true);
  }

  Future<void> disconnect() async {
    _userDisconnected = true;
    _waitingForBluetooth = false;
    _reconnect.cancel();
    unawaited(_background.release());
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      await _shutdownSession(resetConnection: true);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Copies the radio's history for offline display. Skipped until the
  /// radio's history is attached, so the last radio's stays visible.
  void _syncMessageSnapshot(MeshtasticMessagingService messaging) {
    if (messaging.archive == null) return;
    _archivedMessages = List.of(messaging.messages);
    _archivedPending = List.of(messaging.pending);
  }

  Future<void> _shutdownSession({required bool resetConnection}) async {
    _stopFieldAlerts();
    unawaited(_trails.flush());
    unawaited(_dayTracks.flush());
    unawaited(_journal.flush());
    unawaited(_telemetryHistory.flush());
    await _coverageLocation?.cancel();
    _coverageLocation = null;
    _coverageFix = null;
    BastionFieldLog.instance.stop();
    final messaging = _messaging;
    if (messaging != null) _syncMessageSnapshot(messaging);
    await _nodeSubscription?.cancel();
    _nodeSubscription = null;
    await _nodeVaultSubscription?.cancel();
    _nodeVaultSubscription = null;
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    await _incomingSubscription?.cancel();
    _incomingSubscription = null;
    await _identitySubscription?.cancel();
    _identitySubscription = null;
    await _linkLossSubscription?.cancel();
    _linkLossSubscription = null;
    await _waypointSubscription?.cancel();
    _waypointSubscription = null;
    await _meshToolsSubscription?.cancel();
    _meshToolsSubscription = null;
    await _sharer?.stop();
    _sharer = null;
    await _admin?.dispose();
    _admin = null;
    await _traceroute?.dispose();
    _traceroute = null;
    await _handshake?.dispose();
    _handshake = null;
    await _messaging?.dispose();
    _messaging = null;
    await _nodeDatabase?.dispose();
    _nodeDatabase = null;
    await _session?.dispose();
    _session = null;
    _nodes = const [];
    _deviceTelemetry.clear();
    settingsAvailability.clear();
    _radioConfigSnapshots.clear();
    _channelSnapshots.clear();
    _moduleConfigSnapshots.clear();
    _localNodeNum = null;
    _firmwareVersion = null;
    if (resetConnection) connection.disconnect();
  }

  void _relayConnectionChange() => notifyListeners();

  @override
  void notifyListeners() { if (!_disposed) super.notifyListeners(); }

  @override
  void dispose() {
    final alerts = _alerts;
    if (alerts is BastionLocalMessageAlerts) alerts.stopListeningForReplies();
    _disposed = true;
    _lifecycle.dispose();
    unawaited(_bluetoothSubscription.cancel());
    _userDisconnected = true;
    _reconnect.cancel();
    unawaited(_background.release());
    connection.removeListener(_relayConnectionChange);
    _archive.removeListener(notifyListeners);
    trip
      ..removeListener(notifyListeners)
      ..dispose();
    BastionPreferences.instance.removeListener(_applyRetention);
    unawaited(_shutdownSession(resetConnection: true));
    super.dispose();
  }
}

class _CoordinatorTripRadio implements TripRadio {
  _CoordinatorTripRadio(this._radio);
  final MeshtasticRadioCoordinator _radio;

  @override
  bool get isReady => _radio.isReady;

  @override
  int? get localNodeNum => _radio.localNodeNum;

  @override
  ({double? latitude, double? longitude, int? battery}) get localStatus {
    final node = _radio.localNode;
    return (latitude: node?.latitude, longitude: node?.longitude, battery: node?.batteryLevel);
  }

  @override
  // Unfiltered: an ignored or word-filtered contact's SOS acknowledgment still counts.
  List<BastionChatMessage> get messages => _radio.allMessages;

  @override
  double? get channelUtilization => _radio.deviceTelemetry[_radio.localNodeNum]?.channelUtilization;

  @override
  DateTime? lastHeard(int node) {
    for (final n in _radio.allNodes) {
      if (n.num == node) return n.lastHeard;
    }
    return null;
  }

  @override
  String nodeName(int node) => _radio.nodeName(node);

  @override
  Future<int> sendText({required String text, required int destination, required int channel}) =>
      _radio.sendText(text: text, destination: destination, channel: channel);

  @override
  void alert(BastionFieldAlert alert) => _radio._raise(alert);
}

/// The trip's view of [radio], for a coordinator that keeps its own trip.
TripRadio tripRadioFor(MeshtasticRadioCoordinator radio) => _CoordinatorTripRadio(radio);
