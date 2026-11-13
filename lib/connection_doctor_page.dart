import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_ble/universal_ble.dart';

import 'app_version.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/bastion_background_service.dart';
import 'services/bastion_bluetooth_state.dart';
import 'services/bastion_connection_doctor.dart';
import 'services/meshtastic_ble_discovery.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// Explains why a radio won't connect or stay connected, with one fix for
/// each problem and a report the user can copy into a bug report.
class ConnectionDoctorPage extends StatefulWidget {
  const ConnectionDoctorPage({
    super.key,
    required this.radio,
    required this.discovery,
    this.bluetooth,
    this.permissions,
    this.batteryOptimized,
  });

  final MeshtasticRadioCoordinator radio;
  final MeshtasticBleDiscovery discovery;

  /// Overrides for tests; the real checks are used when null.
  final BluetoothAvailability? bluetooth;
  final Future<bool?> Function()? permissions;
  final Future<bool?> Function()? batteryOptimized;

  @override
  State<ConnectionDoctorPage> createState() => _ConnectionDoctorPageState();
}

class _ConnectionDoctorPageState extends State<ConnectionDoctorPage> {
  bool? _bluetoothOn;
  bool? _permissions;
  bool? _battery;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  static Future<bool?> _realPermissions() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return null;
    try {
      return await UniversalBle.hasPermissions();
    } catch (_) {
      return null;
    }
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final bt = widget.bluetooth ?? UniversalBleAvailability();
    bool? on;
    try {
      on = await bt.isOn();
    } catch (_) {}
    final perm = await (widget.permissions ?? _realPermissions)();
    final battery = await (widget.batteryOptimized ?? BastionForegroundService.batteryOptimized)();
    if (!mounted) return;
    setState(() {
      _bluetoothOn = on;
      _permissions = perm;
      _battery = battery;
      _checking = false;
    });
  }

  DoctorFacts _facts() {
    final r = widget.radio;
    final d = widget.discovery;
    return DoctorFacts(
      state: r.connection.state,
      link: !r.hasLastRadio
          ? DoctorLink.none
          : r.usesUsbLink
          ? DoctorLink.usb
          : r.usesNetworkLink
          ? DoctorLink.network
          : DoctorLink.bluetooth,
      radioName: r.connection.deviceName ?? r.linkName,
      error: r.connection.error,
      bluetoothOn: _bluetoothOn,
      permissionsGranted: _permissions,
      batteryOptimized: _battery,
      backgroundProblem: r.backgroundProblem,
      scanned: d.results.isNotEmpty || d.error != null,
      radiosFound: d.results.length,
      scanError: d.error,
      firmwareVersion: r.firmwareVersion,
    );
  }

  Future<void> _fix(DoctorFix fix) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    try {
      switch (fix) {
        case DoctorFix.turnOnBluetooth:
          await UniversalBle.enableBluetooth();
        case DoctorFix.grantPermission:
          await UniversalBle.requestPermissions();
        case DoctorFix.batterySettings:
          await BastionForegroundService.openBatterySettings();
        case DoctorFix.reconnect:
          if (widget.radio.hasLastRadio) {
            await widget.radio.retryLastRadio();
          } else {
            await widget.discovery.scan();
          }
        case DoctorFix.scan:
          await widget.discovery.scan();
        case DoctorFix.updateFirmware:
          await Clipboard.setData(const ClipboardData(text: 'https://flasher.meshtastic.org'));
          messenger.showSnackBar(SnackBar(content: Text(l.cpFlasherCopied)));
        case DoctorFix.none:
          break;
      }
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(l.cpFixFailed('$error'))));
    }
    await _check();
  }

  Future<void> _copyReport(List<DoctorCheck> checks, DoctorFacts facts) async {
    final text = BastionConnectionDoctor.report(
      facts: facts,
      checks: checks,
      log: widget.radio.connectionLog.entries,
      appVersion: bastionAppVersion,
    );
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l.cpReportCopied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.cpTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge([widget.radio, widget.discovery, widget.radio.connectionLog]),
        builder: (context, _) {
          final facts = _facts();
          final checks = BastionConnectionDoctor.diagnose(facts);
          final problems = checks.where((c) => c.status == DoctorStatus.problem).length;
          final log = widget.radio.connectionLog.entries;
          return ListView(
            padding: NxSpace.page,
            children: [
              NxBanner(
                tone: _checking
                    ? NxTone.neutral
                    : problems == 0
                    ? NxTone.success
                    : NxTone.warning,
                title: _checking
                    ? l.cpChecking
                    : problems == 0
                    ? l.cpNoProblems
                    : l.cpProblems(problems),
                message: problems == 0 ? l.cpStillFails : l.cpFixFirst,
              ),
              for (final c in checks) _CheckTile(check: c, onFix: () => _fix(c.fix)),
              const SizedBox(height: NxSpace.sm),
              Wrap(
                spacing: NxSpace.xs,
                runSpacing: NxSpace.xs,
                children: [
                  FilledButton.icon(
                    onPressed: _checking ? null : _check,
                    icon: const Icon(Icons.refresh),
                    label: Text(l.cpCheckAgain),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('copy-report'),
                    onPressed: () => _copyReport(checks, facts),
                    icon: const Icon(Icons.copy),
                    label: Text(l.cpCopyReport),
                  ),
                ],
              ),
              NxSectionLabel(l.cpRecentEvents),
              if (log.isEmpty)
                Text(l.cpNoEvents)
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(NxSpace.md),
                    child: SelectableText(
                      log.reversed
                          .take(30)
                          .map((e) => '${TimeOfDay.fromDateTime(e.time).format(context)}  ${e.text}')
                          .join('\n'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({required this.check, required this.onFix});
  final DoctorCheck check;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = NxStatusColors.of(context);
    final l = AppLocalizations.of(context);
    final (icon, tone, word) = switch (check.status) {
      DoctorStatus.ok => (Icons.check_circle_outline, NxTone.success, l.cpOk),
      DoctorStatus.problem => (Icons.error_outline, NxTone.danger, l.cpProblem),
      DoctorStatus.unknown => (Icons.help_outline, NxTone.neutral, l.cpUnknown),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(NxSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: status.strong(tone, scheme), semanticLabel: word),
                const SizedBox(width: NxSpace.sm),
                Expanded(child: Text(check.title, style: Theme.of(context).textTheme.titleSmall)),
                Text(
                  word,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: status.strong(tone, scheme)),
                ),
              ],
            ),
            const SizedBox(height: NxSpace.xxs),
            Text(check.detail),
            if (check.fix != DoctorFix.none && check.status != DoctorStatus.ok) ...[
              const SizedBox(height: NxSpace.xs),
              OutlinedButton(key: ValueKey('fix-${check.id}'), onPressed: onFix, child: Text(check.fix.label)),
            ],
          ],
        ),
      ),
    );
  }
}
