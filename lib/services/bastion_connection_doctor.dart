import 'bastion_firmware.dart';
import 'meshtastic_connection_controller.dart';

/// How a radio is (or was last) linked.
enum DoctorLink { none, bluetooth, usb, network }

/// One fix the doctor can offer.
enum DoctorFix {
  turnOnBluetooth('Turn on Bluetooth'),
  grantPermission('Allow Bluetooth access'),
  batterySettings('Open battery settings'),
  reconnect('Try again'),
  scan('Scan for radios'),
  updateFirmware('How to update'),
  none('');

  const DoctorFix(this.label);
  final String label;
}

enum DoctorStatus { ok, problem, unknown }

/// One line of the diagnosis.
class DoctorCheck {
  const DoctorCheck(this.id, this.title, this.status, this.detail, [this.fix = DoctorFix.none]);
  final String id;
  final String title;
  final DoctorStatus status;
  final String detail;
  final DoctorFix fix;
}

/// Everything the doctor looks at. Null means the app couldn't tell.
class DoctorFacts {
  const DoctorFacts({
    required this.state,
    this.link = DoctorLink.none,
    this.radioName,
    this.error,
    this.bluetoothOn,
    this.permissionsGranted,
    this.batteryOptimized,
    this.backgroundProblem,
    this.scanned = false,
    this.radiosFound = 0,
    this.scanError,
    this.firmwareVersion,
  });

  final MeshtasticConnectionState state;
  final DoctorLink link;
  final String? radioName;
  final String? error;
  final bool? bluetoothOn;
  final bool? permissionsGranted;
  final bool? batteryOptimized;
  final String? backgroundProblem;
  final bool scanned;
  final int radiosFound;
  final String? scanError;
  final String? firmwareVersion;

  bool get ready => state == MeshtasticConnectionState.ready;
  bool get usesBluetooth => link == DoctorLink.none || link == DoctorLink.bluetooth;
}

/// Why a connection failed, read from its error text.
enum FailureCause { bluetoothOff, permission, pairedElsewhere, timeout, network, usb, gaveUp, notMeshtastic, unknown }

/// Explains connection trouble in plain words, with one fix for each
/// problem. Pure: give it [DoctorFacts], get [DoctorCheck]s.
abstract final class BastionConnectionDoctor {
  static FailureCause classify(String? error) {
    final e = (error ?? '').toLowerCase();
    if (e.isEmpty) return FailureCause.unknown;
    bool any(List<String> words) => words.any(e.contains);
    if (any(['bluetooth is off', 'bluetooth off', 'poweredoff', 'adapter is off'])) return FailureCause.bluetoothOff;
    if (any(['permission', 'not authorized', 'unauthorized', 'denied'])) return FailureCause.permission;
    if (any(['usb'])) return FailureCause.usb;
    if (any(['socketexception', 'connection refused', 'host lookup', 'network is unreachable', 'no route to host'])) {
      return FailureCause.network;
    }
    if (any(['gatt 133', 'gatt_error', 'status 133', 'bond', 'pair', 'already connected', 'another device'])) {
      return FailureCause.pairedElsewhere;
    }
    if (any(['gave up'])) return FailureCause.gaveUp;
    if (any(['timeout', 'timed out', 'no response', 'handshake'])) return FailureCause.timeout;
    if (any(['not a meshtastic', 'service not found', 'characteristic'])) return FailureCause.notMeshtastic;
    return FailureCause.unknown;
  }

  static ({String detail, DoctorFix fix}) _explain(FailureCause cause, DoctorFacts f) {
    final name = f.radioName ?? 'the radio';
    return switch (cause) {
      FailureCause.bluetoothOff => (detail: 'Bluetooth is off. Turn it on and the app reconnects by itself.', fix: DoctorFix.turnOnBluetooth),
      FailureCause.permission => (
          detail: 'The app isn\'t allowed to use Bluetooth. Allow "Nearby devices" when asked, or in Android '
              'Settings → Apps → NOTORYX Connect → Permissions.',
          fix: DoctorFix.grantPermission),
      FailureCause.pairedElsewhere => (
          detail: '$name may be connected to another phone or app. A radio talks to one phone at a time: close '
              'the other app or turn off Bluetooth on the other phone, then try again. If it keeps failing, '
              'forget the radio in Android Bluetooth settings and pair again.',
          fix: DoctorFix.reconnect),
      FailureCause.timeout => (
          detail: '$name didn\'t answer in time. Move closer, check it\'s switched on, or restart it, then try again.',
          fix: DoctorFix.reconnect),
      FailureCause.network => (
          detail: 'Couldn\'t reach the radio over the network. Check the phone and radio are on the same Wi-Fi, '
              'and that the address and port (usually 4403) are right.',
          fix: DoctorFix.reconnect),
      FailureCause.usb => (
          detail: 'The USB link failed. Unplug and plug the cable back in, and allow USB access when Android asks.',
          fix: DoctorFix.reconnect),
      FailureCause.gaveUp => (
          detail: 'The link dropped and reconnecting didn\'t work. Check $name is on and in range, then try again.',
          fix: DoctorFix.reconnect),
      FailureCause.notMeshtastic => (
          detail: 'The device answered but doesn\'t look like a Meshtastic radio, or its firmware is too old.',
          fix: DoctorFix.scan),
      FailureCause.unknown => (detail: f.error ?? 'Unknown problem.', fix: DoctorFix.reconnect),
    };
  }

  static List<DoctorCheck> diagnose(DoctorFacts f) {
    final checks = <DoctorCheck>[];

    if (f.usesBluetooth) {
      checks.add(switch (f.bluetoothOn) {
        true => const DoctorCheck('bluetooth', 'Bluetooth', DoctorStatus.ok, 'On.'),
        false => const DoctorCheck('bluetooth', 'Bluetooth', DoctorStatus.problem,
            'Bluetooth is off.', DoctorFix.turnOnBluetooth),
        null => const DoctorCheck('bluetooth', 'Bluetooth', DoctorStatus.unknown, 'Couldn\'t check.'),
      });
      checks.add(switch (f.permissionsGranted) {
        true => const DoctorCheck('permission', 'Bluetooth access', DoctorStatus.ok, 'Allowed.'),
        false => const DoctorCheck('permission', 'Bluetooth access', DoctorStatus.problem,
            'The app isn\'t allowed to find and connect to radios.', DoctorFix.grantPermission),
        null => const DoctorCheck('permission', 'Bluetooth access', DoctorStatus.unknown, 'Couldn\'t check.'),
      });
    }

    final linkCheck = switch (f.state) {
      MeshtasticConnectionState.ready =>
        DoctorCheck('link', 'Radio link', DoctorStatus.ok, 'Connected to ${f.radioName ?? 'your radio'}.'),
      MeshtasticConnectionState.connecting || MeshtasticConnectionState.connected || MeshtasticConnectionState.synchronizing =>
        DoctorCheck('link', 'Radio link', DoctorStatus.unknown, 'Connecting to ${f.radioName ?? 'your radio'}…'),
      MeshtasticConnectionState.error => () {
          final e = _explain(classify(f.error), f);
          return DoctorCheck('link', 'Radio link', DoctorStatus.problem, e.detail, e.fix);
        }(),
      _ when f.scanError != null => DoctorCheck('link', 'Radio link', DoctorStatus.problem,
          _explain(classify(f.scanError), f).detail, _explain(classify(f.scanError), f).fix),
      _ when f.scanned && f.radiosFound == 0 => const DoctorCheck('link', 'Radio link', DoctorStatus.problem,
          'No radios found. Check the radio is on and within a few metres, that Bluetooth is enabled in its '
              'settings, and that it isn\'t connected to another phone.',
          DoctorFix.scan),
      _ => const DoctorCheck('link', 'Radio link', DoctorStatus.unknown, 'Not connected.', DoctorFix.scan),
    };
    checks.add(linkCheck);

    if (f.batteryOptimized == true) {
      checks.add(const DoctorCheck('background', 'Background', DoctorStatus.problem,
          'Battery optimisation can cut the radio link when the screen is off. Set NOTORYX Connect to '
              '"Unrestricted".',
          DoctorFix.batterySettings));
    } else if (f.backgroundProblem != null) {
      checks.add(DoctorCheck('background', 'Background', DoctorStatus.problem, f.backgroundProblem!));
    } else if (f.batteryOptimized == false) {
      checks.add(const DoctorCheck('background', 'Background', DoctorStatus.ok, 'The link can stay open with the screen off.'));
    }

    if (f.ready) {
      final support = BastionFirmware.supportOf(f.firmwareVersion);
      final advice = BastionFirmware.advice(f.firmwareVersion);
      if (support == FirmwareSupport.unsupported) {
        checks.add(DoctorCheck('firmware', 'Firmware', DoctorStatus.problem, advice ?? 'Firmware too old.',
            DoctorFix.updateFirmware));
      } else if (advice != null) {
        checks.add(DoctorCheck('firmware', 'Firmware', DoctorStatus.unknown, advice, DoctorFix.updateFirmware));
      } else {
        checks.add(DoctorCheck('firmware', 'Firmware', DoctorStatus.ok, f.firmwareVersion ?? 'Supported.'));
      }
    }
    return checks;
  }

  /// A plain-text report for a bug report: checks, facts and the log.
  /// Holds no keys, messages or positions.
  static String report({
    required DoctorFacts facts,
    required List<DoctorCheck> checks,
    required Iterable<Object> log,
    required String appVersion,
    DateTime? now,
  }) {
    final b = StringBuffer()
      ..writeln('NOTORYX Connect $appVersion connection report')
      ..writeln('Time: ${(now ?? DateTime.now()).toIso8601String()}')
      ..writeln('State: ${facts.state.name}  Link: ${facts.link.name}  Radio: ${facts.radioName ?? '-'}')
      ..writeln('Firmware: ${facts.firmwareVersion ?? '-'}  Bluetooth on: ${facts.bluetoothOn ?? '?'}  '
          'Permission: ${facts.permissionsGranted ?? '?'}  Battery optimised: ${facts.batteryOptimized ?? '?'}')
      ..writeln('Last error: ${facts.error ?? '-'}')
      ..writeln()
      ..writeln('Checks:');
    for (final c in checks) {
      b.writeln('- [${c.status.name}] ${c.title}: ${c.detail}');
    }
    b
      ..writeln()
      ..writeln('Log:');
    for (final line in log) {
      b.writeln(line);
    }
    return b.toString();
  }
}
