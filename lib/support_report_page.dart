import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'app_version.dart';
import 'generated/meshtastic/mesh.pbenum.dart' as pbe;
import 'l10n/generated/app_localizations.dart';
import 'services/bastion_error_log.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_support_bundle.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// Builds a plain-text report someone can send when asking for help: app
/// and radio facts, settings, recent errors and the connection log, with
/// keys, messages, positions and names left out. Nothing is sent by the app.
class SupportReportPage extends StatelessWidget {
  const SupportReportPage({super.key, required this.radio, this.errors, this.now});

  final MeshtasticRadioCoordinator radio;
  final BastionErrorLog? errors;
  final DateTime? now;

  static SupportFacts factsFor(MeshtasticRadioCoordinator radio, Locale locale) {
    final prefs = BastionPreferences.instance;
    final local = radio.localNode;
    final model = local?.hardwareModel;
    final lora = radio.loraConfig;
    String onOff(bool v) => v ? 'on' : 'off';
    var platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    if (!kIsWeb) {
      try {
        platform = '$platform ${Platform.operatingSystemVersion}';
      } catch (_) {}
    }
    return SupportFacts(
      appVersion: bastionAppVersion,
      platform: platform,
      locale: locale.toLanguageTag(),
      connection: radio.connection.state.name,
      link: !radio.hasLastRadio
          ? 'none'
          : radio.usesUsbLink
              ? 'usb'
              : radio.usesNetworkLink
                  ? 'network'
                  : 'bluetooth',
      radioModel: model == null ? null : (pbe.HardwareModel.valueOf(model)?.name ?? '$model'),
      firmware: radio.firmwareVersion,
      region: lora?.region.name,
      preset: lora?.modemPreset.name,
      nodesHeard: radio.nodes.length,
      nodesKnown: radio.knownNodes.length,
      channelsInUse: radio.channelMetadata.where((c) => c.role != 0).length,
      settings: {
        'Share phone location': onOff(radio.sharePhoneLocation),
        'MQTT proxy': onOff(prefs.mqttProxy),
        'Store and forward catch-up': onOff(prefs.storeForwardCatchUp),
        'Link previews': onOff(prefs.linkPreviews),
        'Statistics': onOff(prefs.statistics),
        'Mesh health': onOff(prefs.meshHealth),
        'Encounters': onOff(prefs.encounters),
        'Read aloud': onOff(prefs.readAloud),
        'Units': prefs.units.name,
        'History limit': '${prefs.historyLimit}',
        'Channel retention days': '${prefs.channelRetentionDays}',
        'Theme': prefs.appTheme,
      },
    );
  }

  String _report(BuildContext context) {
    final local = radio.localNode;
    return BastionSupportBundle.build(
      facts: factsFor(radio, Localizations.localeOf(context)),
      connectionLog: radio.connectionLog.entries,
      errors: (errors ?? BastionErrorLog.instance).entries,
      radioNames: [
        ?radio.connection.deviceName,
        ?radio.linkName,
        ?local?.longName,
        ?local?.shortName,
      ],
      now: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final text = _report(context);
    final mono = Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'JetBrains Mono');
    return Scaffold(
      appBar: AppBar(title: Text(l.srTitle)),
      body: ListView(padding: NxSpace.page, children: [
        Text(l.srIntro),
        const SizedBox(height: 12),
        NxBanner(tone: NxTone.info, icon: Icons.lock_outline, message: l.srLeftOut),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            key: const ValueKey('support-copy'),
            icon: const Icon(Icons.copy),
            label: Text(l.srCopy),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: text));
              messenger.showSnackBar(SnackBar(content: Text(l.srCopied)));
            },
          ),
          OutlinedButton.icon(
            key: const ValueKey('support-share'),
            icon: const Icon(Icons.share_outlined),
            label: Text(l.srShare),
            onPressed: () => SharePlus.instance.share(ShareParams(text: text, subject: l.srTitle)),
          ),
        ]),
        NxSectionLabel(l.srPreview),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(text, key: const ValueKey('support-preview'), style: mono),
          ),
        ),
      ]),
    );
  }
}
