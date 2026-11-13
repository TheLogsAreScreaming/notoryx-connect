import '../l10n/bastion_text.dart';
import 'bastion_firmware.dart';
import 'meshtastic_connection_controller.dart';

/// How a radio is (or was last) linked.
enum DoctorLink { none, bluetooth, usb, network }

/// One fix the doctor can offer.
enum DoctorFix {
  turnOnBluetooth,
  grantPermission,
  batterySettings,
  reconnect,
  scan,
  updateFirmware,
  none;

  /// The button text, in the phone's language.
  String get label {
    final l = BastionText.l;
    return switch (this) {
      turnOnBluetooth => l.cdFixBluetooth,
      grantPermission => l.cdFixPermission,
      batterySettings => l.cdFixBattery,
      reconnect => l.cdFixRetry,
      scan => l.cdFixScan,
      updateFirmware => l.cdFixFirmware,
      none => '',
    };
  }
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
    final l = BastionText.l;
    final name = f.radioName ?? l.cdTheRadio;
    return switch (cause) {
      FailureCause.bluetoothOff => (detail: l.cdBluetoothOffDetail, fix: DoctorFix.turnOnBluetooth),
      FailureCause.permission => (detail: l.cdPermissionDetail, fix: DoctorFix.grantPermission),
      FailureCause.pairedElsewhere => (detail: l.cdPairedDetail(name), fix: DoctorFix.reconnect),
      FailureCause.timeout => (detail: l.cdTimeoutDetail(name), fix: DoctorFix.reconnect),
      FailureCause.network => (detail: l.cdNetworkDetail, fix: DoctorFix.reconnect),
      FailureCause.usb => (detail: l.cdUsbDetail, fix: DoctorFix.reconnect),
      FailureCause.gaveUp => (detail: l.cdGaveUpDetail(name), fix: DoctorFix.reconnect),
      FailureCause.notMeshtastic => (detail: l.cdNotMeshtasticDetail, fix: DoctorFix.scan),
      FailureCause.unknown => (detail: f.error ?? l.cdUnknownProblem, fix: DoctorFix.reconnect),
    };
  }

  static List<DoctorCheck> diagnose(DoctorFacts f) {
    final l = BastionText.l;
    final checks = <DoctorCheck>[];

    if (f.usesBluetooth) {
      checks.add(switch (f.bluetoothOn) {
        true => DoctorCheck('bluetooth', l.cdBluetooth, DoctorStatus.ok, l.cdOn),
        false => DoctorCheck(
          'bluetooth',
          l.cdBluetooth,
          DoctorStatus.problem,
          l.cdBluetoothOff,
          DoctorFix.turnOnBluetooth,
        ),
        null => DoctorCheck('bluetooth', l.cdBluetooth, DoctorStatus.unknown, l.cdCouldntCheck),
      });
      checks.add(switch (f.permissionsGranted) {
        true => DoctorCheck('permission', l.cdAccess, DoctorStatus.ok, l.cdAllowed),
        false => DoctorCheck('permission', l.cdAccess, DoctorStatus.problem, l.cdNotAllowed, DoctorFix.grantPermission),
        null => DoctorCheck('permission', l.cdAccess, DoctorStatus.unknown, l.cdCouldntCheck),
      });
    }

    final linkCheck = switch (f.state) {
      MeshtasticConnectionState.ready => DoctorCheck(
        'link',
        l.cdLink,
        DoctorStatus.ok,
        l.cdConnectedTo(f.radioName ?? l.cdYourRadio),
      ),
      MeshtasticConnectionState.connecting ||
      MeshtasticConnectionState.connected ||
      MeshtasticConnectionState.synchronizing => DoctorCheck(
        'link',
        l.cdLink,
        DoctorStatus.unknown,
        l.cdConnectingTo(f.radioName ?? l.cdYourRadio),
      ),
      MeshtasticConnectionState.error => () {
        final e = _explain(classify(f.error), f);
        return DoctorCheck('link', l.cdLink, DoctorStatus.problem, e.detail, e.fix);
      }(),
      _ when f.scanError != null => DoctorCheck(
        'link',
        l.cdLink,
        DoctorStatus.problem,
        _explain(classify(f.scanError), f).detail,
        _explain(classify(f.scanError), f).fix,
      ),
      _ when f.scanned && f.radiosFound == 0 => DoctorCheck(
        'link',
        l.cdLink,
        DoctorStatus.problem,
        l.cdNoneFound,
        DoctorFix.scan,
      ),
      _ => DoctorCheck('link', l.cdLink, DoctorStatus.unknown, l.cdNotConnected, DoctorFix.scan),
    };
    checks.add(linkCheck);

    if (f.batteryOptimized == true) {
      checks.add(
        DoctorCheck(
          'background',
          l.cdBackground,
          DoctorStatus.problem,
          l.cdBatteryOptimised,
          DoctorFix.batterySettings,
        ),
      );
    } else if (f.backgroundProblem != null) {
      checks.add(DoctorCheck('background', l.cdBackground, DoctorStatus.problem, f.backgroundProblem!));
    } else if (f.batteryOptimized == false) {
      checks.add(DoctorCheck('background', l.cdBackground, DoctorStatus.ok, l.cdBackgroundOk));
    }

    if (f.ready) {
      final support = BastionFirmware.supportOf(f.firmwareVersion);
      final advice = BastionFirmware.advice(f.firmwareVersion);
      if (support == FirmwareSupport.unsupported) {
        checks.add(
          DoctorCheck(
            'firmware',
            l.cdFirmware,
            DoctorStatus.problem,
            advice ?? l.cdFirmwareTooOld,
            DoctorFix.updateFirmware,
          ),
        );
      } else if (advice != null) {
        checks.add(DoctorCheck('firmware', l.cdFirmware, DoctorStatus.unknown, advice, DoctorFix.updateFirmware));
      } else {
        checks.add(DoctorCheck('firmware', l.cdFirmware, DoctorStatus.ok, f.firmwareVersion ?? l.cdSupported));
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
      ..writeln(
        'Firmware: ${facts.firmwareVersion ?? '-'}  Bluetooth on: ${facts.bluetoothOn ?? '?'}  '
        'Permission: ${facts.permissionsGranted ?? '?'}  Battery optimised: ${facts.batteryOptimized ?? '?'}',
      )
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
