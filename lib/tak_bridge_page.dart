import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_tak_bridge.dart';

/// Setup for the feed of mesh positions to ATAK on this phone.
class TakBridgePage extends StatefulWidget {
  const TakBridgePage({super.key, required this.bridge});
  final BastionTakBridge bridge;
  @override
  State<TakBridgePage> createState() => _TakBridgePageState();
}

class _TakBridgePageState extends State<TakBridgePage> {
  late final _port = TextEditingController(text: '${widget.bridge.port}');
  bool _badPort = false;

  @override
  void dispose() {
    _port.dispose();
    super.dispose();
  }

  void _savePort() {
    final port = int.tryParse(_port.text.trim());
    final ok = port != null && BastionTakBridge.validPort(port);
    setState(() => _badPort = !ok);
    if (ok) widget.bridge.configure(port: port);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bridge = widget.bridge;
    return Scaffold(
      appBar: AppBar(title: Text(l.takTitle)),
      body: SafeArea(top: false, child: AnimatedBuilder(animation: bridge, builder: (context, _) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.takIntro),
          SwitchListTile(key: const ValueKey('tak-enabled'), contentPadding: EdgeInsets.zero,
            title: Text(l.takSwitch), value: bridge.enabled,
            onChanged: (v) => bridge.configure(enabled: v)),
          TextField(key: const ValueKey('tak-port'), controller: _port, keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l.takPort, errorText: _badPort ? l.takBadPort : null),
            onSubmitted: (_) => _savePort()),
          Align(alignment: AlignmentDirectional.centerStart,
            child: TextButton(onPressed: _savePort, child: Text(l.commonSave))),
          if (bridge.enabled) Semantics(liveRegion: true, child: Text(bridge.problem == null
              ? l.takStatus(bridge.lastCount)
              : l.takProblem(bridge.problem!))),
          const SizedBox(height: 16),
          Text(l.takHowTo),
        ],
      ))),
    );
  }
}
