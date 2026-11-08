// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabHome => 'Home';

  @override
  String get tabNodes => 'Nodes';

  @override
  String get tabChats => 'Chats';

  @override
  String get tabMap => 'Map';

  @override
  String get tabTools => 'Tools';

  @override
  String get tabSettings => 'Settings';

  @override
  String get connOffline => 'Offline';

  @override
  String get connScanning => 'Scanning';

  @override
  String get connConnecting => 'Connecting';

  @override
  String get connSyncing => 'Syncing';

  @override
  String get connConnected => 'Connected';

  @override
  String get connError => 'Error';

  @override
  String radioStatus(String status) {
    return 'Radio: $status';
  }

  @override
  String radioStatusTip(String status) {
    return 'Radio: $status. Tap to manage.';
  }

  @override
  String get radioStatusHint => 'manage the radio';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get toolsSubtitle =>
      'Utilities for planning, testing and running a deployment.';

  @override
  String get toolsDoctor => 'Connection doctor';

  @override
  String get toolsDoctorSub =>
      'Find out why a radio won\'t connect or keeps dropping';

  @override
  String get toolsBeforeYouGo => 'Before you go';

  @override
  String get toolsChecklist => 'Deployment checklist';

  @override
  String get toolsBattery => 'Battery runtime';

  @override
  String get toolsBatterySub => 'Estimate hours from capacity and average draw';

  @override
  String get toolsCalculate => 'Calculate';

  @override
  String get toolsMeshTools => 'Mesh tools';

  @override
  String get toolsHealth => 'Mesh health & airtime';

  @override
  String get toolsHealthSub =>
      'How busy the channel is and how much your radio transmits';

  @override
  String get toolsLink => 'Link planner';

  @override
  String get toolsLinkSub =>
      'Check line of sight between two nodes over the terrain';

  @override
  String get toolsRange => 'Range test';

  @override
  String get toolsRangeSub =>
      'Log packets from a range test sender with signal and distance';

  @override
  String get toolsTraceroute => 'Traceroute';

  @override
  String get toolsStore => 'Store & forward';

  @override
  String get toolsStoreSub => 'Replay messages you missed from a router';

  @override
  String get toolsBeacons => 'Mesh beacons';

  @override
  String get toolsRecords => 'Records';

  @override
  String get toolsIncident => 'Incident log, templates & coverage';

  @override
  String get toolsIncidentSub => 'Saved field records and exports';

  @override
  String get toolsSignal => 'Signal';

  @override
  String get toolsTelemetry => 'Live telemetry';

  @override
  String get toolsNothingYet =>
      'Nothing received yet. Metrics appear when nodes send them.';

  @override
  String get toolsGuide => 'Bluetooth signal guide';

  @override
  String get toolsGuideSub => 'What the signal numbers (RSSI) mean';

  @override
  String get toolsScan => 'Scan for radios';

  @override
  String get toolsCheck0 => 'Radio charged';

  @override
  String get toolsCheck1 => 'Antenna attached';

  @override
  String get toolsCheck2 => 'Region configured';

  @override
  String get toolsCheck3 => 'Primary channel verified';

  @override
  String get toolsCheck4 => 'GPS / position policy checked';

  @override
  String toolsReady(int done, int total) {
    return '$done of $total ready';
  }

  @override
  String get toolsBatteryField => 'Battery (mAh)';

  @override
  String get toolsDrawField => 'Average draw (mA)';

  @override
  String toolsAboutHours(String hours) {
    return 'About $hours hours';
  }

  @override
  String get toolsTraceReady => 'Show the relay path to a node and back';

  @override
  String get toolsTraceOff => 'Connect to a radio to trace routes';

  @override
  String get toolsBeaconsSub =>
      'Hear mesh invitations nearby and send your own';

  @override
  String toolsBeaconsHeard(int count) {
    return '$count heard • send your own';
  }

  @override
  String toolsReporting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nodes reporting device metrics',
      one: '$count node reporting device metrics',
    );
    return '$_temp0';
  }

  @override
  String get toolsTelemetryOff => 'Connect to a radio to receive telemetry';

  @override
  String toolsBatteryPct(int pct) {
    return 'Battery $pct%';
  }

  @override
  String toolsChannelBusy(String pct) {
    return 'Channel busy $pct%';
  }

  @override
  String toolsTransmitting(String pct) {
    return 'Transmitting $pct%';
  }

  @override
  String get toolsSigExcellent => 'Excellent, very close';

  @override
  String get toolsSigStrong => 'Strong';

  @override
  String get toolsSigUsable => 'Usable';

  @override
  String get toolsSigWeak => 'Weak';

  @override
  String get toolsSigVeryWeak => 'Very weak, may drop';

  @override
  String get toolsScanning => 'Scanning…';

  @override
  String toolsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bluetooth devices found',
      one: '$count Bluetooth device found',
    );
    return '$_temp0';
  }
}
