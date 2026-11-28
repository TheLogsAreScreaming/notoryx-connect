import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_tak_bridge.dart';

/// Setup for the feed of mesh positions to ATAK on this phone or local network.
class TakBridgePage extends StatefulWidget {
  const TakBridgePage({super.key, required this.bridge});
  final BastionTakBridge bridge;
  @override
  State<TakBridgePage> createState() => _TakBridgePageState();
}

class _TakBridgePageState extends State<TakBridgePage> {
  late final _port = TextEditingController(text: '${widget.bridge.port}');
  late final _receivePort = TextEditingController(
    text: '${widget.bridge.receivePort}',
  );
  bool _badPort = false;
  String? _receivePortError;

  @override
  void dispose() {
    _port.dispose();
    _receivePort.dispose();
    super.dispose();
  }

  void _saveReceivePort() {
    final port = int.tryParse(_receivePort.text.trim());
    final l = AppLocalizations.of(context);
    final error = port == null || !BastionTakBridge.validPort(port)
        ? l.takBadPort
        : port == widget.bridge.port
        ? l.takSamePort
        : null;
    setState(() => _receivePortError = error);
    if (error == null) widget.bridge.configure(receivePort: port);
  }

  /// Asks before anything is shared; nothing is sent unless the user accepts.
  Future<bool> _confirmSharing() async {
    final l = AppLocalizations.of(context);
    final bridge = widget.bridge;
    final body = bridge.mode == TakMode.localNetwork
        ? l.takLanConsentBody(bridge.port)
        : l.takConsentBody(bridge.port);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('tak-consent'),
        title: Text(l.takConsentTitle),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            key: const ValueKey('tak-consent-accept'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.takConsentAccept),
          ),
        ],
      ),
    );
    return ok == true && mounted;
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
      body: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: bridge,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l.takIntro),
              const SizedBox(height: 12),
              Semantics(
                label: l.takModeLabel,
                child: SegmentedButton<TakMode>(
                  segments: [
                    ButtonSegment<TakMode>(
                      value: TakMode.thisPhone,
                      label: Text(l.takModePhone),
                      icon: const Icon(Icons.smartphone_outlined),
                    ),
                    ButtonSegment<TakMode>(
                      value: TakMode.localNetwork,
                      label: Text(l.takModeNetwork),
                      icon: const Icon(Icons.wifi_outlined),
                    ),
                  ],
                  selected: {bridge.mode},
                  onSelectionChanged: (v) =>
                      bridge.configure(mode: v.first),
                ),
              ),
              SwitchListTile(
                key: const ValueKey('tak-enabled'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.takSwitch),
                value: bridge.enabled,
                onChanged: (v) async {
                  if (v && !await _confirmSharing()) return;
                  await bridge.configure(enabled: v);
                },
              ),
              TextField(
                key: const ValueKey('tak-port'),
                controller: _port,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.takPort,
                  errorText: _badPort ? l.takBadPort : null,
                ),
                onSubmitted: (_) => _savePort(),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _savePort,
                  child: Text(l.commonSave),
                ),
              ),
              if (bridge.enabled)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    bridge.problem == null
                        ? l.takStatus(bridge.lastCount)
                        : l.takProblem(bridge.problem!),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                bridge.mode == TakMode.localNetwork
                    ? l.takLanHowTo
                    : l.takHowTo,
              ),
              const Divider(height: 32),
              Semantics(
                header: true,
                child: Text(
                  l.takReceiveTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bridge.mode == TakMode.localNetwork
                    ? l.takLanReceiveIntro
                    : l.takReceiveIntro,
              ),
              SwitchListTile(
                key: const ValueKey('tak-receive'),
                contentPadding: EdgeInsets.zero,
                title: Text(l.takReceiveSwitch),
                value: bridge.receive,
                onChanged: (v) => bridge.configure(receive: v),
              ),
              TextField(
                key: const ValueKey('tak-receive-port'),
                controller: _receivePort,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l.takReceivePort,
                  errorText: _receivePortError,
                ),
                onSubmitted: (_) => _saveReceivePort(),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: _saveReceivePort,
                  child: Text(l.commonSave),
                ),
              ),
              if (bridge.receive)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    bridge.receiveProblem == null
                        ? l.takReceiveStatus(bridge.markers.length)
                        : l.takReceiveProblem(bridge.receiveProblem!),
                  ),
                ),
              if (bridge.receive && bridge.markers.isNotEmpty)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const ValueKey('tak-clear'),
                    onPressed: bridge.clearMarkers,
                    icon: const Icon(Icons.layers_clear_outlined),
                    label: Text(l.takClear),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                bridge.mode == TakMode.localNetwork
                    ? l.takLanReceiveHowTo
                    : l.takReceiveHowTo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
