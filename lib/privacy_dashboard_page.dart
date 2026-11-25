import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_privacy.dart';
import 'services/bastion_sentinel.dart';
import 'services/bastion_sms_relay.dart';
import 'services/bastion_tak_bridge.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/nx_components.dart';

/// Everything that can leave this phone, where it goes, and whether it's on
/// right now. Simple on/off items can be switched here; the rest only happen
/// when you press their button.
class PrivacyDashboardPage extends StatefulWidget {
  const PrivacyDashboardPage({super.key, required this.radio});

  final MeshtasticRadioCoordinator radio;

  @override
  State<PrivacyDashboardPage> createState() => _PrivacyDashboardPageState();
}

class _PrivacyDashboardPageState extends State<PrivacyDashboardPage> {
  Future<void> _set(PrivacyThing thing, bool on) async {
    switch (thing) {
      case PrivacyThing.linkPreviews:
        await BastionPreferences.instance.update(previews: on);
      case PrivacyThing.mqttProxy:
        await BastionPreferences.instance.update(proxyMqtt: on);
      case PrivacyThing.moderation:
        await SentinelService.instance.setEnabled(on);
      case PrivacyThing.location:
        await widget.radio.setSharePhoneLocation(on);
      case PrivacyThing.sms:
        await BastionSmsRelay.instance.setEnabled(on);
      default:
        return;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final prefs = BastionPreferences.instance;
    final items = privacyItems(
      shareLocation: widget.radio.sharePhoneLocation,
      mqttProxy: prefs.mqttProxy,
      linkPreviews: prefs.linkPreviews,
      moderation: SentinelService.instance.enabled,
      tak: BastionTakBridge.instance.enabled,
      sms: BastionSmsRelay.available ? BastionSmsRelay.instance.enabled : null,
    );

    String title(PrivacyThing t) => switch (t) {
          PrivacyThing.mapTiles => l.pdMapTiles,
          PrivacyThing.placeSearch => l.pdPlaceSearch,
          PrivacyThing.terrain => l.pdTerrain,
          PrivacyThing.trails => l.pdTrails,
          PrivacyThing.linkPreviews => l.lnkPrevTitle,
          PrivacyThing.mqttProxy => l.pdMqtt,
          PrivacyThing.moderation => l.pdModeration,
          PrivacyThing.webhooks => l.pdWebhooks,
          PrivacyThing.location => l.pdLocation,
          PrivacyThing.tak => l.pdTak,
          PrivacyThing.sms => l.pdSms,
        };
    String what(PrivacyThing t) => switch (t) {
          PrivacyThing.mapTiles => l.pdMapTilesSub,
          PrivacyThing.placeSearch => l.pdPlaceSearchSub,
          PrivacyThing.terrain => l.pdTerrainSub,
          PrivacyThing.trails => l.pdTrailsSub,
          PrivacyThing.linkPreviews => l.pdLinkPreviewsSub,
          PrivacyThing.mqttProxy => l.pdMqttSub,
          PrivacyThing.moderation => l.pdModerationSub,
          PrivacyThing.webhooks => l.pdWebhooksSub,
          PrivacyThing.location => l.pdLocationSub,
          PrivacyThing.tak => l.pdTakSub,
          PrivacyThing.sms => l.pdSmsSub,
        };
    String state(PrivacyState s) => switch (s) {
          PrivacyState.on => l.pdOn,
          PrivacyState.off => l.pdOff,
          PrivacyState.whenAsked => l.pdWhenAsked,
        };
    String routeTitle(PrivacyRoute r) => switch (r) {
          PrivacyRoute.internet => l.pdInternet,
          PrivacyRoute.mesh => l.pdMesh,
          PrivacyRoute.otherApps => l.pdOtherApps,
        };

    Widget row(PrivacyItem i) {
      // The state is spoken and shown as a word, not only by the switch.
      final subtitle = Text('${state(i.state)} • ${what(i.thing)}');
      return i.canSwitch
          ? SwitchListTile(
              key: ValueKey('privacy-${i.thing.name}'),
              title: Text(title(i.thing)),
              subtitle: subtitle,
              isThreeLine: true,
              value: i.state == PrivacyState.on,
              onChanged: (v) => _set(i.thing, v),
            )
          : ListTile(
              key: ValueKey('privacy-${i.thing.name}'),
              title: Text(title(i.thing)),
              subtitle: subtitle,
              isThreeLine: true,
            );
    }

    final on = items.where((i) => i.state == PrivacyState.on).length;
    return Scaffold(
      appBar: AppBar(title: Text(l.pdTitle)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(l.pdIntro),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(l.pdSummary(on), key: const ValueKey('privacy-summary'),
              style: Theme.of(context).textTheme.titleSmall),
        ),
        for (final route in PrivacyRoute.values)
          if (items.any((i) => i.route == route)) ...[
            NxSectionLabel(routeTitle(route)),
            Card(child: Column(children: [for (final i in items) if (i.route == route) row(i)])),
          ],
        const SizedBox(height: 12),
        Text(l.pdNeverSent),
      ]),
    );
  }
}
