import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';

import 'services/bastion_background_service.dart';
import 'services/bastion_trip_readiness.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// One screen to check before leaving. Reading it sends nothing over the
/// mesh; a route test runs only when the user taps Test on a contact.
class TripReadinessPage extends StatefulWidget {
  const TripReadinessPage({super.key, required this.radio, this.backgroundRestricted, this.routeTest});

  final MeshtasticRadioCoordinator radio;

  /// Overrides for tests.
  final Future<bool?> Function()? backgroundRestricted;
  final Future<void> Function(int nodeNum)? routeTest;

  @override
  State<TripReadinessPage> createState() => _TripReadinessPageState();
}

class _TripReadinessPageState extends State<TripReadinessPage> {
  bool? _restricted;
  final Map<int, bool> _tested = {};
  final Set<int> _testing = {};

  @override
  void initState() {
    super.initState();
    (widget.backgroundRestricted ?? BastionForegroundService.batteryOptimized)().then((v) {
      if (mounted) setState(() => _restricted = v);
    });
  }

  Future<void> _test(int num) async {
    setState(() => _testing.add(num));
    var reached = true;
    try {
      await (widget.routeTest ?? widget.radio.traceroute)(num);
    } catch (_) {
      reached = false;
    }
    if (!mounted) return;
    setState(() {
      _testing.remove(num);
      _tested[num] = reached;
    });
  }

  ReadinessFacts _facts() {
    final r = widget.radio;
    final plan = r.trip.plan;
    final local = r.localNode;
    final channels = r.channelMetadata.where((c) => c.role != 0).toList();
    final battery = local?.batteryLevel ?? r.deviceTelemetry[r.localNodeNum]?.batteryLevel;
    return ReadinessFacts(
      radioReady: r.isReady,
      now: DateTime.now(),
      batteryPercent: battery,
      firmwareVersion: r.firmwareVersion,
      channelCount: channels.length,
      sosChannel: plan.sosChannel,
      sosChannelExists: channels.any((c) => c.index == plan.sosChannel),
      contacts: [
        for (final m in plan.members)
          ReadinessContact(num: m, name: r.nodeName(m), lastHeard: r.nodes.where((n) => n.num == m).firstOrNull?.lastHeard, testReached: _tested[m]),
      ],
      positionTime: local?.positionTime,
      sharesPhoneLocation: r.sharePhoneLocation,
      backgroundRestricted: _restricted,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).rpTitle)),
        body: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: widget.radio,
            builder: (context, _) {
              final facts = _facts();
              final items = BastionTripReadiness.check(facts);
              final overall = BastionTripReadiness.overall(items);
              final (tone, title) = switch (overall) {
                ReadinessStatus.ready => (NxTone.success, AppLocalizations.of(context).rpReady),
                ReadinessStatus.warning => (NxTone.warning, AppLocalizations.of(context).rpCheck),
                ReadinessStatus.blocked => (NxTone.danger, AppLocalizations.of(context).rpNotReady),
                ReadinessStatus.unknown => (NxTone.neutral, AppLocalizations.of(context).rpNeedRadio),
              };
              return ListView(padding: NxSpace.page, children: [
                NxBanner(tone: tone, title: title, message: AppLocalizations.of(context).rpNotReceived),
                for (final item in items) _ItemCard(item: item),
                if (facts.contacts.isNotEmpty && widget.radio.isReady) ...[
                  NxSectionLabel(AppLocalizations.of(context).rpTestRoute),
                  Text(AppLocalizations.of(context).rpTestHint),
                  const SizedBox(height: NxSpace.xs),
                  Card(
                    child: Column(children: [
                      for (final c in facts.contacts)
                        ListTile(
                          title: Text(c.name),
                          subtitle: Text(switch (c.testReached) {
                            true => AppLocalizations.of(context).rpRouteFound,
                            false => AppLocalizations.of(context).rpNoRoute,
                            null => AppLocalizations.of(context).rpNotTested,
                          }),
                          trailing: _testing.contains(c.num)
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                              : OutlinedButton(
                                  key: ValueKey('test-${c.num}'),
                                  onPressed: _testing.isEmpty ? () => _test(c.num) : null,
                                  child: Text(AppLocalizations.of(context).rpTest),
                                ),
                        ),
                    ]),
                  ),
                ],
              ]);
            },
          ),
        ),
      );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});
  final ReadinessItem item;

  @override
  Widget build(BuildContext context) {
    final (icon, tone, word) = switch (item.status) {
      ReadinessStatus.ready => (Icons.check_circle_outline, NxTone.success, AppLocalizations.of(context).rpStatusReady),
      ReadinessStatus.warning => (Icons.warning_amber_rounded, NxTone.warning, AppLocalizations.of(context).rpStatusCheck),
      ReadinessStatus.blocked => (Icons.error_outline, NxTone.danger, AppLocalizations.of(context).rpStatusFix),
      ReadinessStatus.unknown => (Icons.help_outline, NxTone.neutral, AppLocalizations.of(context).rpStatusUnknown),
    };
    final color = NxStatusColors.of(context).strong(tone, Theme.of(context).colorScheme);
    final type = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(NxSpace.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: NxSpace.sm),
            Expanded(child: Text(item.title, style: type.titleSmall)),
            Text(word, style: type.labelMedium?.copyWith(color: color)),
          ]),
          const SizedBox(height: NxSpace.xxs),
          Text(item.detail),
        ]),
      ),
    );
  }
}
