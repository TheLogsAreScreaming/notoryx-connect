import 'checkin_delivery_page.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import 'generated/meshtastic/config.pbenum.dart';
import 'l10n/generated/app_localizations.dart';

import 'radio_settings_page.dart';
import 'region_setup_page.dart';
import 'services/bastion_chat_message.dart';
import 'services/bastion_firmware.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_radio_policy.dart';
import 'services/bastion_telemetry_history.dart';
import 'services/bastion_radio_notice.dart';
import 'services/bastion_trip.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';
import 'theme/nx_glass.dart';
import 'trip_page.dart';

/// A shortcut on Home's Field tools list.
typedef HomeTool = ({IconData icon, Color? color, String title, String subtitle, VoidCallback onTap});

/// HOME: the Field Console, with the trip, check-ins and SOS up front.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.radio, required this.onConnect, this.onTryDemo, this.fieldTools = const []});
  final MeshtasticRadioCoordinator radio;

  /// Shortcuts to the tools used most outdoors, as on NOTORYX Core's Home.
  final List<HomeTool> fieldTools;

  /// Starts demo mode; null while it is already on.
  final VoidCallback? onTryDemo;

  /// Opens the NODES tab to connect a radio.
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: radio,
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final trip = radio.trip;
      final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant);
      return ListView(padding: NxSpace.page, children: [
        if (trip.sos.active) ...[_SosBanner(trip: trip), const SizedBox(height: NxSpace.sm)],
        _ConsoleCard(radio: radio, onConnect: onConnect, onTryDemo: onTryDemo),
        if (radio.isReady)
          if (BastionFirmware.advice(radio.firmwareVersion) case final advice?)
            NxBanner(
              tone: radio.firmwareSupport == FirmwareSupport.unsupported ? NxTone.warning : NxTone.info,
              icon: Icons.system_update_alt,
              title: l.homeFirmwareTitle,
              message: advice,
            ),
        if (radio.radioNotice case final notice?)
          _RadioNoticeBanner(notice: notice, onDismiss: radio.dismissRadioNotice),
        if (radio.isReady &&
            radio.canAdminister &&
            radio.loraConfig?.region == Config_LoRaConfig_RegionCode.UNSET)
          NxBanner(
            key: const ValueKey('home-no-region'),
            tone: NxTone.warning,
            icon: Icons.public_off,
            title: l.regionSetupBannerTitle,
            message: l.regionSetupBannerBody,
            action: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => RegionSetupPage(radio: radio)),
              ),
              child: Text(l.regionSetupBannerAction),
            ),
          ),
        if (radio.isReady &&
            radio.canAdminister &&
            BastionRadioPolicy.firmwareAtLeast28(radio.firmwareVersion) &&
            (radio.positionConfig?.positionBroadcastSecs ?? 0) == 0)
          NxBanner(
            key: const ValueKey('home-position-off'),
            tone: NxTone.info,
            icon: Icons.location_off_outlined,
            title: l.homePosOffTitle,
            message: l.homePosOffBody,
            action: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RadioSettingsPage(radio: radio),
                ),
              ),
              child: Text(l.homePosOffAction),
            ),
          ),
        _TripCard(radio: radio),
        NxSectionLabel(l.homeCheckIn),
        _CheckInButtons(radio: radio),
        NxSectionLabel(l.homeEmergency),
        _SosButton(trip: trip),
        const SizedBox(height: NxSpace.xs),
        Text(trip.sosBlocked ??
            (trip.plan.sosChannel >= 0 ? l.homeSosHintChannel(trip.plan.sosChannel) : l.homeSosHint),
          style: muted),
        if (trip.problem != null)
          NxBanner(tone: NxTone.danger, message: trip.problem!),
        if (fieldTools.isNotEmpty) ...[
          NxGlassLabel(l.homeFieldTools),
          for (final t in fieldTools)
            NxGlassRow(icon: t.icon, iconColor: t.color, title: t.title, subtitle: t.subtitle, onTap: t.onTap),
        ],
        const SizedBox(height: NxSpace.md),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: NxSpace.xs),
          Expanded(child: Text(l.homeNotReceived,
            style: Theme.of(context).textTheme.bodySmall)),
        ]),
      ]);
    },
  );
}

class _ConsoleCard extends StatelessWidget {
  const _ConsoleCard({required this.radio, required this.onConnect, this.onTryDemo});
  final MeshtasticRadioCoordinator radio;
  final VoidCallback onConnect;
  final VoidCallback? onTryDemo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final status = NxStatusColors.of(context);
    final node = radio.localNode;
    final battery = node?.batteryLevel;
    final ready = radio.isReady;
    final self = radio.localNodeNum;
    double? latest(TelemetryMetric m) => self == null
        ? null
        : switch (radio.telemetrySeries(self, m)) { [..., final p] => p.value, _ => null };
    final volts = ready ? latest(TelemetryMetric.voltage) : null;
    final chUse = ready ? latest(TelemetryMetric.channelUtilization) : null;
    // NOTORYX Core's instrument face: live numbers in one glass panel.
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      NxGlassLabel(ready
          ? '${l.homeConnected} · ${node == null ? l.homeYourRadio : node.longName ?? node.shortName ?? l.homeYourRadio}'
          : l.homeNotConnected),
      NxGlassPanel(
        key: const ValueKey('home-readouts'),
        padding: const EdgeInsets.symmetric(vertical: NxSpace.xs, horizontal: NxSpace.xxs),
        child: NxReadoutStrip([
          NxReadout(
            !ready || battery == null ? '–' : battery > 100 ? l.homePluggedIn : '$battery%',
            l.homeBattery,
            color: battery != null && battery <= 20 ? status.warning : null,
            // "Plugged in" breaks mid-word in the narrow tile; show a plug.
            icon: ready && battery != null && battery > 100 ? Icons.power : null,
          ),
          NxReadout(volts == null ? '–' : volts.toStringAsFixed(2), TelemetryMetric.voltage.label),
          NxReadout(chUse == null ? '–' : '${chUse.toStringAsFixed(0)}%', TelemetryMetric.channelUtilization.label),
          NxReadout(ready ? '${radio.knownNodeCount}' : '0', l.homeNodes, color: scheme.secondary),
        ]),
      ),
      const SizedBox(height: NxSpace.sm),
      if (ready) _SensorsPanel(radio: radio),
      if (!ready) ...[
        NxGlassRow(
          key: const ValueKey('home-connect'),
          icon: Icons.bluetooth_searching,
          iconColor: scheme.primary,
          title: l.homeConnectRadio,
          titleColor: scheme.primary,
          subtitle: l.homeConnectHint,
          onTap: onConnect,
        ),
        if (onTryDemo != null)
          NxGlassRow(
            icon: Icons.play_circle_outline,
            iconColor: scheme.tertiary,
            title: l.homeTryDemo,
            onTap: onTryDemo,
          ),
      ],
    ]);
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.radio});
  final MeshtasticRadioCoordinator radio;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final trip = radio.trip;
    final plan = trip.plan;
    final overdue = trip.overdue;
    final status = [
      plan.active ? l.homeTripRunning : l.homeTripNotStarted,
      l.homeContacts(plan.members.length),
    ].join(' • ');
    final scheme = Theme.of(context).colorScheme;
    return Card(child: ListTile(
      leading: Icon(Icons.hiking, color: overdue.isEmpty ? scheme.primary : scheme.error),
      title: Text(plan.active ? l.homeTripNamed(plan.name) : l.homePlanTrip),
      subtitle: Text(overdue.isEmpty
          ? status
          : '$status\n${l.homeOverdue(overdue.map(radio.nodeName).join(', '))}'),
      isThreeLine: overdue.isNotEmpty,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => TripPage(radio: radio))),
    ));
  }
}

class _CheckInButtons extends StatefulWidget {
  const _CheckInButtons({required this.radio});
  final MeshtasticRadioCoordinator radio;
  @override
  State<_CheckInButtons> createState() => _CheckInButtonsState();
}

class _CheckInButtonsState extends State<_CheckInButtons> {
  bool _sending = false;
  String? _error;

  Future<void> _checkIn(String label) async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.radio.trip.checkIn(label);
    } catch (e) {
      if (mounted) setState(() => _error = e is StateError ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final trip = widget.radio.trip;
    final blocked = trip.checkInBlocked;
    final enabled = blocked == null && !_sending;
    final last = trip.lastCheckIn;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(NxTouch.large),
          // Glass while it can't be used, as on NOTORYX Core, instead of a
          // flat grey block.
          disabledBackgroundColor: Colors.white.withValues(alpha: _glassFill(context)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NxRadius.lg),
            side: enabled ? BorderSide.none : BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
        ),
        onPressed: enabled ? () => _checkIn(checkInLabels.first) : null,
        icon: _sending
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
            : const Icon(Icons.check_circle_outline),
        label: Text(l.homeCheckInLabel(checkInLabels.first),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: NxSpace.xs),
      Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
        for (final label in checkInLabels.skip(1))
          OutlinedButton(onPressed: enabled ? () => _checkIn(label) : null, child: Text(label)),
      ]),
      const SizedBox(height: NxSpace.xs),
      if (blocked != null)
        Text(blocked, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant))
      else if (last != null)
        _Delivery(radio: widget.radio, record: last),
      if (_error != null)
        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    ]);
  }
}

class _Delivery extends StatelessWidget {
  const _Delivery({required this.radio, required this.record});
  final MeshtasticRadioCoordinator radio;
  final CheckInRecord record;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final delivery = radio.trip.delivery(record);
    final delivered = delivery.values.where((s) => s == BastionDeliveryState.delivered).length;
    final failed = [for (final e in delivery.entries) if (e.value == BastionDeliveryState.failed) e.key];
    final waiting = delivery.length - delivered - failed.length;
    final parts = [
      l.homeDelivered(record.label, _time(record.at), delivered, delivery.length),
      if (failed.isNotEmpty) l.homeNotDelivered(failed.map(radio.nodeName).join(', ')),
      if (waiting > 0) l.homeWaiting(waiting),
    ];
    return Row(children: [
      Expanded(child: Text(parts.join(' • '))),
      TextButton(
        key: const ValueKey('checkin-details'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => CheckInDeliveryPage(radio: radio, record: record))),
        child: Text(l.homeDetails),
      ),
      if (failed.isNotEmpty)
        TextButton(onPressed: radio.trip.resendFailed, child: Text(l.homeResend)),
    ]);
  }
}

/// Hold for 2 seconds to start an SOS, so it can't be sent by accident.
class _SosButton extends StatefulWidget {
  const _SosButton({required this.trip});
  final BastionTripController trip;
  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton> with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _hold.reset();
        unawaited(_start());
      }
    });
  String? _error;

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      await widget.trip.startSos();
    } catch (e) {
      if (mounted) setState(() => _error = e is StateError ? e.message : '$e');
    }
  }

  /// Screen readers can't hold, so they confirm in a dialog instead.
  Future<void> _confirm() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(l.homeSendSosQ),
      content: Text(l.homeSosRepeats),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.homeSendSos)),
      ],
    ));
    if (ok == true) await _start();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.trip.sosBlocked == null && !widget.trip.sos.active;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Semantics(
        button: true,
        enabled: enabled,
        label: l.homeHoldSos,
        onTap: enabled ? _confirm : null,
        excludeSemantics: true,
        child: GestureDetector(
          onTapDown: enabled ? (_) => _hold.forward() : null,
          onTapUp: (_) => _hold.reverse(),
          onTapCancel: () => _hold.reverse(),
          child: AnimatedBuilder(
            animation: _hold,
            builder: (context, _) => Container(
              height: NxTouch.large,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(NxRadius.lg),
                border: Border.all(color: enabled ? scheme.error : scheme.outlineVariant, width: enabled ? 1.5 : 1),
                color: enabled ? scheme.errorContainer : Colors.white.withValues(alpha: _glassFill(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(children: [
                FractionallySizedBox(widthFactor: _hold.value,
                  child: Container(color: scheme.error.withValues(alpha: .45))),
                Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.sos, color: enabled ? scheme.onErrorContainer : scheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Text(l.homeHoldSos, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: enabled ? scheme.onErrorContainer : scheme.onSurfaceVariant)),
                ])),
              ]),
            ),
          ),
        ),
      ),
      if (_error != null)
        Padding(padding: const EdgeInsets.only(top: 6),
          child: Text(_error!, style: TextStyle(color: scheme.error))),
    ]);
  }
}

class _SosBanner extends StatelessWidget {
  const _SosBanner({required this.trip});
  final BastionTripController trip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final sos = trip.sos;
    final next = sos.nextSendAt;
    final detail = sos.acknowledgedBy != null
        ? l.homeSosReplied(sos.acknowledgedBy!)
        : next != null
            ? l.homeSosNext(sos.sends, sosMaxSends, _time(next)) + (sos.intervalScale > 1 ? l.homeSosBusy : '')
            : l.homeSosDone(sosMaxSends);
    return Semantics(liveRegion: true, child: Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(Icons.sos, color: scheme.onErrorContainer),
            const SizedBox(width: 10),
            Text(l.homeSosActive, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onErrorContainer)),
          ]),
          const SizedBox(height: 6),
          Text(detail, style: TextStyle(color: scheme.onErrorContainer)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton(onPressed: () => trip.stopSos(allClear: true), child: Text(l.homeImSafe)),
            OutlinedButton(onPressed: trip.stopSos, child: Text(l.homeStopNoMessage)),
          ]),
        ]),
      ),
    ));
  }
}

String _time(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// A notice the radio sent: a key problem, a refused unsigned identity
/// change, the airtime limit, or the firmware's own text.
class _RadioNoticeBanner extends StatelessWidget {
  const _RadioNoticeBanner({required this.notice, required this.onDismiss});

  final RadioNotice notice;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final (title, body, tone, icon) = switch (notice.kind) {
      RadioNoticeKind.keySecurity =>
        (l.noticeKeyTitle, l.noticeKeyBody, NxTone.danger, Icons.key_off),
      RadioNoticeKind.identityRefused =>
        (l.noticeIdentityTitle, l.noticeIdentityBody, NxTone.warning, Icons.gpp_maybe_outlined),
      RadioNoticeKind.airtime =>
        (l.noticeAirtimeTitle, l.noticeAirtimeBody, NxTone.warning, Icons.timer_outlined),
      RadioNoticeKind.general => (
          l.noticeGeneralTitle,
          null,
          notice.isWarning ? NxTone.warning : NxTone.info,
          Icons.campaign_outlined,
        ),
    };
    final radioWords = notice.message.isEmpty ? null : l.noticeRadioSays(notice.message);
    return NxBanner(
      tone: tone,
      icon: icon,
      title: title,
      message: [?body, ?radioWords].join('\n'),
      action: TextButton(onPressed: onDismiss, child: Text(l.noticeDismiss)),
    );
  }
}

/// The connected radio's own latest readings as chips, as on NOTORYX Core's
/// Home. Battery is left out: the tile above already shows it.
/// Readings the instrument panel already shows.
const _onReadouts = {TelemetryMetric.battery, TelemetryMetric.voltage, TelemetryMetric.channelUtilization};

/// The white a glass surface adds: a little on dark themes, more on light.
double _glassFill(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? .07 : .5;

class _SensorsPanel extends StatelessWidget {
  const _SensorsPanel({required this.radio});
  final MeshtasticRadioCoordinator radio;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final self = radio.localNodeNum;
    final units = BastionPreferences.instance.units;
    final chips = <String>[
      if (self != null)
        for (final metric in radio.telemetryMetricsOf(self))
          if (!_onReadouts.contains(metric))
            if (radio.telemetrySeries(self, metric) case [..., final latest])
              '${metric.label} ${metric.format(latest.value, units)}',
    ];
    // Nothing beyond the readouts above: no panel at all.
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      key: const ValueKey('home-sensors'),
      padding: const EdgeInsets.only(top: NxSpace.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l.snsTitle, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: NxSpace.xs),
        Wrap(spacing: NxSpace.xs, runSpacing: NxSpace.xs, children: [
            for (final c in chips) Chip(label: Text(c), visualDensity: VisualDensity.compact),
          ]),
      ]),
    );
  }
}
