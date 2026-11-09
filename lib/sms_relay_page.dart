import 'package:flutter/material.dart';

import 'services/bastion_sms_relay.dart';
import 'services/meshtastic_radio_coordinator.dart';

/// Setup for the opt-in SMS relay on a base-camp phone.
class SmsRelayPage extends StatefulWidget {
  const SmsRelayPage({super.key, required this.radio, required this.relay});
  final MeshtasticRadioCoordinator radio;
  final BastionSmsRelay relay;
  @override
  State<SmsRelayPage> createState() => _SmsRelayPageState();
}

class _SmsRelayPageState extends State<SmsRelayPage> {
  final _alias = TextEditingController();
  final _number = TextEditingController();
  String? _status;

  @override
  void dispose() {
    _alias.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      try {
        if (!await widget.relay.gateway.hasPermission()) {
          await widget.relay.gateway.requestPermission();
          if (mounted) setState(() => _status = 'Allow SMS when asked, then turn the relay on again.');
          return;
        }
      } catch (_) {
        if (mounted) setState(() => _status = 'This phone cannot send SMS.');
        return;
      }
    }
    await widget.relay.setEnabled(value);
  }

  Future<void> _add() async {
    final saved = await widget.relay.saveContact(_alias.text, _number.text);
    if (!mounted) return;
    setState(() => _status = saved ? null : 'Use a short name (letters, numbers, - or _) and a phone number.');
    if (saved) {
      _alias.clear();
      _number.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final relay = widget.relay;
    return Scaffold(
      appBar: AppBar(title: const Text('SMS relay')),
      body: SafeArea(top: false, child: AnimatedBuilder(
        animation: Listenable.merge([relay, widget.radio]),
        builder: (context, _) {
          final nodes = [for (final n in widget.radio.nodes) if (n.num != widget.radio.localNodeNum) n];
          return ListView(padding: const EdgeInsets.all(16), children: [
            const Text('Lets the nodes you choose send a text message through this phone. They send a direct '
                'message like "SMS base: on our way". Your carrier\'s normal SMS charges apply. '
                'This is not an emergency service, and only hand-off to the phone network is confirmed.'),
            if (_status != null) Semantics(liveRegion: true, child: Padding(padding: const EdgeInsets.only(top: 8), child: Text(_status!))),
            SwitchListTile(key: const ValueKey('sms-enabled'), contentPadding: EdgeInsets.zero,
              title: const Text('Relay messages by SMS'), value: relay.enabled, onChanged: _toggle),
            Text('Contacts', style: Theme.of(context).textTheme.titleMedium),
            for (final c in relay.contacts.entries)
              ListTile(contentPadding: EdgeInsets.zero, title: Text(c.key), subtitle: Text(c.value),
                trailing: IconButton(tooltip: 'Remove ${c.key}', icon: const Icon(Icons.delete_outline),
                  onPressed: () => relay.removeContact(c.key))),
            TextField(key: const ValueKey('sms-alias'), controller: _alias, decoration: const InputDecoration(labelText: 'Short name, e.g. base')),
            TextField(key: const ValueKey('sms-number'), controller: _number, keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number')),
            Align(alignment: AlignmentDirectional.centerStart, child: TextButton(onPressed: _add, child: const Text('Add contact'))),
            Text('Nodes allowed to send', style: Theme.of(context).textTheme.titleMedium),
            if (nodes.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No nodes heard yet.')),
            for (final n in nodes)
              CheckboxListTile(contentPadding: EdgeInsets.zero, title: Text(n.displayName), value: relay.allowedNodes.contains(n.num),
                onChanged: (v) => relay.setNodeAllowed(n.num, v ?? false)),
          ]);
        },
      )),
    );
  }
}
