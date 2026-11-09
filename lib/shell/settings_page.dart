part of '../main.dart';

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.radio, required this.demo, required this.onDemoChanged});
  final MeshtasticRadioCoordinator radio;

  /// Whether the pretend radio is showing.
  final bool demo;
  final ValueChanged<bool> onDemoChanged;

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: radio,
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final local = radio.localNode;
      final sent = radio.lastPhonePositionSent;
      final locationStatus = radio.locationShareProblem ??
          (!radio.sharePhoneLocation
              ? l.setOffLoc
              : !radio.isReady
                  ? l.setOnNoRadio
                  : sent == null
                      ? l.setOnNoFix
                      : l.setOnSent(sent.toLocal().toString().substring(11, 16)));
      return ListView(
    padding: NxSpace.page,
    children: [
      NxPageHeader(title: l.tabSettings,
        subtitle: l.setSubtitle),
      NxSectionLabel(l.setRadioSec),
      Card(child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.settings_input_antenna),
        title: Text(l.setRadioConfig),
        subtitle: Text(radio.canAdminister
          ? l.setCanChange
          : radio.isReady && radio.firmwareSupport == FirmwareSupport.unsupported
              ? l.setReadOnly('${radio.firmwareVersion}', '${BastionFirmware.minimum.$1}.${BastionFirmware.minimum.$2}', BastionFirmware.flasher)
              : l.setConnectToView),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(l.setIdentity),
            subtitle: Text(local == null
              ? l.setWaitingNode
              : '${local.longName ?? l.setNoLong} • ${local.shortName ?? l.setNoShort}\n'
                '${local.id ?? l.setNoId}'),
            isThreeLine: local != null,
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l.setChange),
            subtitle: Text(l.setChangeSub),
            enabled: radio.canAdminister,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, RadioSettingsPage(radio: radio)),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(l.setDeviceLora),
            subtitle: Text(radio.loraSettings.isEmpty
              ? l.setConfigWait(radio.radioConfigCount)
              : radio.loraSettings.join('\n'))),
          ListTile(
            leading: const Icon(Icons.podcasts),
            title: Text(l.setChannels),
            subtitle: Text(radio.channelSettings.isEmpty
              ? l.setChannelWait(radio.channelConfigCount)
              : radio.channelSettings.join('\n')),
          ),
          ListTile(
            leading: const Icon(Icons.extension_outlined),
            title: Text(l.setModules),
            subtitle: Text(l.setModulesSub(radio.moduleConfigCount))),
        ],
      )),
      Card(child: Column(children: [
        SwitchListTile(
          secondary: const Icon(Icons.share_location),
          title: Text(l.setShareLoc),
          subtitle: Text(l.setShareLocSub(locationStatus)),
          isThreeLine: true,
          value: radio.sharePhoneLocation,
          onChanged: (value) => radio.setSharePhoneLocation(value),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.blur_on),
          title: Text(l.setPrecision),
          subtitle: Text(l.setPrecisionSub),
          trailing: DropdownButton<int>(
            value: radio.locationPrecision,
            underline: const SizedBox.shrink(),
            items: [for (final e in BastionPhonePositionSharer.precisionChoices.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value == 0
                  ? l.setPrecise
                  : l.setAbout2(BastionUnitFormat.distance(e.value.toDouble(), BastionPreferences.instance.units))))],
            onChanged: (v) { if (v != null) radio.setLocationPrecision(v); },
          ),
        ),
      ])),
      _BackgroundCard(radio: radio),
      _MqttProxyCard(radio: radio),
      Card(child: SwitchListTile(
        secondary: const Icon(Icons.battery_saver_outlined),
        title: Text(l.setLowPower),
        subtitle: Text(l.setLowPowerSub),
        isThreeLine: true,
        value: radio.lowPowerMode,
        onChanged: (value) => radio.setLowPowerMode(value))),
      NxSectionLabel(l.setApp),
      const BastionAppearanceCard(),
      _FieldAlertsCard(radio: radio),
      const _MessagesCard(),
      _FiltersCard(radio: radio),
      const _MapCacheCard(),
      if (BastionHomeWidget.instance case final widget?)
        Card(child: StatefulBuilder(builder: (context, setLocal) => SwitchListTile(
          secondary: const Icon(Icons.widgets_outlined),
          title: Text(l.setWidget),
          subtitle: Text(l.setWidgetSub),
          isThreeLine: true,
          value: widget.showMessage,
          onChanged: (v) async {
            await widget.setShowMessage(v);
            setLocal(() {});
          },
        ))),
      NxSectionLabel(l.setYourData),
      _RadioDataCard(radio: radio),
      NxGroupCard(children: [
        ListTile(
          leading: const Icon(Icons.enhanced_encryption_outlined),
          title: Text(l.setRadioBackup),
          subtitle: Text(l.setRadioBackupSub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(context, RadioBackupPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.phone_android_outlined),
          title: Text(l.setPhoneBackup),
          subtitle: Text(l.setPhoneBackupSub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(context, PhoneBackupPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(l.setPrivacy),
          subtitle: Text(l.setPrivacySub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(context, PrivacyPage(radio: radio)),
        ),
      ]),
      Card(child: SwitchListTile(
        secondary: const Icon(Icons.play_circle_outline),
        title: Text(l.setDemo),
        subtitle: Text(l.setDemoSub),
        isThreeLine: true,
        value: demo,
        onChanged: onDemoChanged,
      )),
      NxSectionLabel(l.setAbout),
      NxGroupCard(children: [
        ListTile(
          leading: const Icon(Icons.info_outline), title: const Text('NOTORYX Connect'),
          subtitle: Text(l.setDevBuild)),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.bluetooth), title: Text(l.setConnection),
          subtitle: Text(l.setConnectionSub)),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.description_outlined), title: Text(l.setLicenses),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(context: context, applicationName: 'NOTORYX Connect'),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: Text(l.setTrademark),
          // Legal wording stays in English on purpose.
          subtitle: const Text(
            'Compatible with Meshtastic® firmware. Meshtastic® is a registered trademark of Meshtastic LLC. Meshtastic software components are released under various licenses, see GitHub for details. No warranty is provided - use at your own risk.\n\nNOTORYX Connect is independently developed and is not affiliated with, sponsored by, or endorsed by Meshtastic LLC.',
          ),
        ),
      ]),
      NxBanner(
        tone: NxTone.warning,
        icon: Icons.shield_outlined,
        message: l.setDevWarning,
      ),
    ],
  );
    },
  );
}

/// Safe channel editor preview. No channel write is attempted until authenticated
/// admin responses and verified radio readback are implemented.
class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      SizedBox(width: 80, child: Text(value,
        style: TextStyle(fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary))),
      Expanded(child: Text(label)),
    ]),
  );
}
