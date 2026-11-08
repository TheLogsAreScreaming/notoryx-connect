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
      final local = radio.localNode;
      final sent = radio.lastPhonePositionSent;
      final locationStatus = radio.locationShareProblem ??
          (!radio.sharePhoneLocation
              ? 'Off. Your phone location is never sent.'
              : !radio.isReady
                  ? 'On. Starts when a radio is connected.'
                  : sent == null
                      ? 'On. Waiting for a GPS fix.'
                      : 'On. Last sent ${sent.toLocal().toString().substring(11, 16)}.');
      return ListView(
    padding: NxSpace.page,
    children: [
      const NxPageHeader(title: 'Settings',
        subtitle: 'Your radio, how the app behaves, and your data.'),
      const NxSectionLabel('Radio'),
      Card(child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.settings_input_antenna),
        title: const Text('Radio configuration'),
        subtitle: Text(radio.canAdminister
          ? 'Connected • settings can be changed'
          : radio.isReady && radio.firmwareSupport == FirmwareSupport.unsupported
              ? 'Read-only: firmware ${radio.firmwareVersion} is older than '
                '${BastionFirmware.minimum.$1}.${BastionFirmware.minimum.$2}. Update at ${BastionFirmware.flasher}.'
              : 'Connect to a radio to view and change its settings'),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Node identity'),
            subtitle: Text(local == null
              ? 'Waiting for this radio\'s node information'
              : '${local.longName ?? 'No long name'} • ${local.shortName ?? 'No short name'}\n'
                '${local.id ?? 'ID not reported'}'),
            isThreeLine: local != null,
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Change radio settings'),
            subtitle: const Text('Owner, LoRa, channels, device role and position'),
            enabled: radio.canAdminister,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(context, RadioSettingsPage(radio: radio)),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Device & LoRa'),
            subtitle: Text(radio.loraSettings.isEmpty
              ? 'Not received yet (${radio.radioConfigCount} configuration messages)'
              : radio.loraSettings.join('\n'))),
          ListTile(
            leading: const Icon(Icons.podcasts),
            title: const Text('Channels'),
            subtitle: Text(radio.channelSettings.isEmpty
              ? 'Not received yet (${radio.channelConfigCount} channel messages)'
              : radio.channelSettings.join('\n')),
          ),
          ListTile(
            leading: const Icon(Icons.extension_outlined),
            title: const Text('Modules'),
            subtitle: Text('${radio.moduleConfigCount} module messages received. Change them in radio settings.')),
        ],
      )),
      Card(child: Column(children: [
        SwitchListTile(
          secondary: const Icon(Icons.share_location),
          title: const Text('Share phone location with mesh'),
          subtitle: Text('$locationStatus\nUsed when the radio has no GPS of its own. '
              'Updates every 5 min, or sooner when you move.'),
          isThreeLine: true,
          value: radio.sharePhoneLocation,
          onChanged: (value) => radio.setSharePhoneLocation(value),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.blur_on),
          title: const Text('Location precision'),
          subtitle: const Text('Rounded on this phone before it is sent'),
          trailing: DropdownButton<int>(
            value: radio.locationPrecision,
            underline: const SizedBox.shrink(),
            items: [for (final e in BastionPhonePositionSharer.precisionChoices.entries)
              DropdownMenuItem(value: e.key, child: Text(e.value == 0
                  ? 'Precise'
                  : 'About ${BastionUnitFormat.distance(e.value.toDouble(), BastionPreferences.instance.units)}'))],
            onChanged: (v) { if (v != null) radio.setLocationPrecision(v); },
          ),
        ),
      ])),
      _BackgroundCard(radio: radio),
      _MqttProxyCard(radio: radio),
      Card(child: SwitchListTile(
        secondary: const Icon(Icons.battery_saver_outlined),
        title: const Text('Low-power field mode'),
        subtitle: const Text('Shared location uses balanced GPS and updates every 15 min, '
            'or after 200 m of movement. The radio link and coverage recording are unchanged.'),
        isThreeLine: true,
        value: radio.lowPowerMode,
        onChanged: (value) => radio.setLowPowerMode(value))),
      const NxSectionLabel('App'),
      const BastionAppearanceCard(),
      _FieldAlertsCard(radio: radio),
      const _MessagesCard(),
      _FiltersCard(radio: radio),
      const _MapCacheCard(),
      if (BastionHomeWidget.instance case final widget?)
        Card(child: StatefulBuilder(builder: (context, setLocal) => SwitchListTile(
          secondary: const Icon(Icons.widgets_outlined),
          title: const Text('Show messages on the home-screen widget'),
          subtitle: const Text('Off: the widget shows only how many messages are unread. '
              'On: it also shows the sender and text, which anyone holding the phone can see.'),
          isThreeLine: true,
          value: widget.showMessage,
          onChanged: (v) async {
            await widget.setShowMessage(v);
            setLocal(() {});
          },
        ))),
      const NxSectionLabel('Your data'),
      _RadioDataCard(radio: radio),
      NxGroupCard(children: [
        ListTile(
          leading: const Icon(Icons.enhanced_encryption_outlined),
          title: const Text('Encrypted radio backup'),
          subtitle: const Text('Save or restore settings and channel keys, protected by a password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(context, RadioBackupPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.phone_android_outlined),
          title: const Text('Phone data backup'),
          subtitle: const Text('Chats, nodes, waypoints, records and settings, for moving to a new phone'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(context, PhoneBackupPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy & data'),
          subtitle: const Text('What is stored and sent; delete chat history or all phone data'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(context, PrivacyPage(radio: radio)),
        ),
      ]),
      Card(child: SwitchListTile(
        secondary: const Icon(Icons.play_circle_outline),
        title: const Text('Demo mode'),
        subtitle: const Text('Explore the app with a pretend radio and mesh. Nothing is sent, '
            'and your own messages and settings are left alone.'),
        isThreeLine: true,
        value: demo,
        onChanged: onDemoChanged,
      )),
      const NxSectionLabel('About'),
      NxGroupCard(children: [
        const ListTile(
          leading: Icon(Icons.info_outline), title: Text('NOTORYX Connect'),
          subtitle: Text('Development build • Independent mesh companion')),
        const Divider(indent: 56),
        const ListTile(
          leading: Icon(Icons.bluetooth), title: Text('Connection'),
          subtitle: Text('Bluetooth LE • Safety mode on: no unverified device is treated as a mesh node')),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.description_outlined), title: const Text('Third-party licenses'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(context: context, applicationName: 'NOTORYX Connect'),
        ),
        const Divider(indent: 56),
        const ListTile(
          leading: Icon(Icons.gavel_outlined),
          title: Text('Trademark & compatibility'),
          subtitle: Text(
            'Compatible with Meshtastic® firmware. Meshtastic® is a registered trademark of Meshtastic LLC. Meshtastic software components are released under various licenses, see GitHub for details. No warranty is provided - use at your own risk.\n\nNOTORYX Connect is independently developed and is not affiliated with, sponsored by, or endorsed by Meshtastic LLC.',
          ),
        ),
      ]),
      const NxBanner(
        tone: NxTone.warning,
        icon: Icons.shield_outlined,
        message: 'Do not rely on this development build as your only way to call for help.',
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
