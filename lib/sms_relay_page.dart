import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';

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
          if (mounted) setState(() => _status = AppLocalizations.of(context).smsAllowFirst);
          return;
        }
      } catch (_) {
        if (mounted) setState(() => _status = AppLocalizations.of(context).smsUnsupported);
        return;
      }
    }
    await widget.relay.setEnabled(value);
  }

  Future<void> _add() async {
    final saved = await widget.relay.saveContact(_alias.text, _number.text);
    if (!mounted) return;
    setState(() => _status = saved ? null : AppLocalizations.of(context).smsBadContact);
    if (saved) {
      _alias.clear();
      _number.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final relay = widget.relay;
    return Scaffold(
      appBar: AppBar(title: Text(l.smsTitle)),
      body: SafeArea(top: false, child: AnimatedBuilder(
        animation: Listenable.merge([relay, widget.radio]),
        builder: (context, _) {
          final nodes = [for (final n in widget.radio.nodes) if (n.num != widget.radio.localNodeNum) n];
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(l.smsHelp),
            if (_status != null) Semantics(liveRegion: true, child: Padding(padding: const EdgeInsets.only(top: 8), child: Text(_status!))),
            SwitchListTile(key: const ValueKey('sms-enabled'), contentPadding: EdgeInsets.zero,
              title: Text(l.smsEnable), value: relay.enabled, onChanged: _toggle),
            Text(l.smsContacts, style: Theme.of(context).textTheme.titleMedium),
            for (final c in relay.contacts.entries)
              ListTile(contentPadding: EdgeInsets.zero, title: Text(c.key), subtitle: Text(c.value),
                trailing: IconButton(tooltip: l.smsRemove(c.key), icon: const Icon(Icons.delete_outline),
                  onPressed: () => relay.removeContact(c.key))),
            TextField(key: const ValueKey('sms-alias'), controller: _alias, decoration: InputDecoration(labelText: l.smsAlias)),
            TextField(key: const ValueKey('sms-number'), controller: _number, keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l.smsNumber)),
            Align(alignment: AlignmentDirectional.centerStart, child: TextButton(onPressed: _add, child: Text(l.smsAdd))),
            Text(l.smsAllowedNodes, style: Theme.of(context).textTheme.titleMedium),
            if (nodes.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l.smsNoNodes)),
            for (final n in nodes)
              CheckboxListTile(contentPadding: EdgeInsets.zero, title: Text(n.displayName), value: relay.allowedNodes.contains(n.num),
                onChanged: (v) => relay.setNodeAllowed(n.num, v ?? false)),
          ]);
        },
      )),
    );
  }
}
