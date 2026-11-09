import 'package:flutter/material.dart';

import 'services/app_exit.dart';
import 'services/bastion_app_lock.dart';
import 'services/bastion_phone_backup.dart';
import 'services/bastion_tile_cache.dart';
import 'services/meshtastic_connection_controller.dart';
import 'services/meshtastic_radio_coordinator.dart';

/// What the app stores and sends, and controls to delete phone data.
class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key, required this.radio});
  final MeshtasticRadioCoordinator radio;
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool _busy = false;
  String? _status;
  bool _lockAvailable = false;

  @override
  void initState() {
    super.initState();
    BastionAppLock.instance.isAvailable().then((v) {
      if (mounted) setState(() => _lockAvailable = v);
    });
  }

  Future<void> _setLock(bool value) async {
    final changed = await BastionAppLock.instance.setEnabled(value, value ? 'Turn on app lock' : 'Turn off app lock');
    if (!mounted) return;
    setState(() => _status = changed ? null : 'App lock was not changed.');
  }

  static const _stored = [
    'Chat history and offline queues for each radio (newest 500 messages per radio)',
    'NodeDex: nodes your radios have heard, plus your favorites and notes',
    'Waypoints received from the mesh',
    'Incident log and coverage records, only if you create them',
    'Field alert, bot, location and appearance settings',
    'Map tiles for areas you have viewed',
  ];

  static const _sent = [
    'Messages you send go to your radio, which transmits them on the mesh using the channel\'s encryption key',
    'Your phone location, only while "Share phone location" is on, at the precision you choose',
    'Position, telemetry and traceroute requests that you start',
    'Map tile requests to OpenStreetMap servers when you view the map; they see your IP address',
    'Topographic map tile requests to OpenTopoMap servers, only while the topo map is shown; they see your IP address',
    'Points along a link to the Open-Meteo elevation service, only when you check a link in the Link planner',
  ];

  Future<void> _erase({required bool everything}) async {
    if (widget.radio.connection.state != MeshtasticConnectionState.disconnected) {
      setState(() => _status = 'Disconnect the radio before deleting phone data.');
      return;
    }
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: Text(everything ? 'Delete all phone data?' : 'Delete chat history?'),
      content: Text(everything
          ? 'Deletes chats and offline queues for every radio, NodeDex, favorites and notes, '
            'waypoints, field records, cached map tiles and all app settings from this phone. '
            'Radio settings are not changed. This cannot be undone; make a phone data backup first '
            'if you may need it.\n\nThe app closes afterwards.'
          : 'Deletes chat history and queued messages for every radio from this phone. '
            'Messages already sent on the mesh are not affected. This cannot be undone.\n\n'
            'The app closes afterwards.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ));
    if (confirmed != true || !mounted) return;
    setState(() { _busy = true; _status = null; });
    try {
      await BastionPhoneBackup().erase(everything: everything);
      if (everything) await BastionTileCache.clear();
    } catch (error) {
      if (mounted) setState(() { _busy = false; _status = 'Delete failed: $error'; });
      return;
    }
    if (!mounted) return;
    await showDialog<void>(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      title: const Text('Deleted'),
      content: const Text('NOTORYX Connect will close now so nothing still in memory is saved again.'),
      actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Close app'))],
    ));
    await closeApp();
  }

  Widget _list(String title, List<String> items) => Card(child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final item in items)
        Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const Text('•  '), Expanded(child: Text(item))],
        )),
    ]),
  ));

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Privacy & data')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('NOTORYX Connect has no account, analytics, ads or servers of its own. '
            'Everything it keeps stays in this app\'s private storage on your phone and is '
            'removed if you uninstall it.'),
        const SizedBox(height: 12),
        Card(child: SwitchListTile(
          key: const ValueKey('app-lock-switch'),
          secondary: const Icon(Icons.lock_outline),
          title: const Text('App lock'),
          subtitle: Text(_lockAvailable
              ? 'Ask for your fingerprint, face or screen lock when opening the app, and after a minute away. You will also need it to reach SOS. The radio stays connected.'
              : 'Set a screen lock on this phone to use app lock.'),
          value: BastionAppLock.instance.enabled,
          onChanged: _busy || !_lockAvailable ? null : _setLock,
        )),
        _list('Stored on this phone', _stored),
        _list('Sent off this phone', _sent),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _busy ? null : () => _erase(everything: false),
            icon: const Icon(Icons.delete_sweep_outlined), label: const Text('Delete chat history')),
        const SizedBox(height: 8),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: _busy ? null : () => _erase(everything: true),
          icon: const Icon(Icons.delete_forever_outlined), label: const Text('Delete all phone data')),
        if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        if (_status != null) Padding(padding: const EdgeInsets.all(16), child: Text(_status!)),
      ]),
    ),
  );
}
