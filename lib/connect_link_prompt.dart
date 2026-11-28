import 'dart:async';

import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'sarneg/secret_clipboard.dart';
import 'services/bastion_connect_link.dart';
import 'services/meshtastic_ble_discovery.dart';
import 'services/meshtastic_radio_coordinator.dart';

/// Asks before acting on a connect link (any web page or tag can fire one),
/// then connects, or disconnects for an `address=n` link. A link this app
/// can't use says so. Returns whether it acted.
Future<bool> handleConnectLink(
  BuildContext context,
  MeshtasticRadioCoordinator radio,
  String text,
) async {
  final l = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final link = ConnectLink.parse(text);
  if (link == null) {
    messenger.showSnackBar(SnackBar(content: Text(l.linkNotConnect)));
    return false;
  }
  if (link.kind == ConnectLinkKind.serial) {
    messenger.showSnackBar(SnackBar(content: Text(l.linkSerialUnsupported)));
    return false;
  }
  final target = switch (link.kind) {
    ConnectLinkKind.bluetooth => l.linkTargetBluetooth(link.address),
    ConnectLinkKind.network => l.linkTargetNetwork('${link.address}:${link.port}'),
    _ => '',
  };
  final disconnect = link.kind == ConnectLinkKind.disconnect;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(disconnect ? l.linkDisconnectTitle : l.linkConnectTitle),
      content: Text(
        disconnect
            ? l.linkDisconnectBody
            : link.pin != null
            ? '$target\n\n${l.linkPinBody(link.pin!)}'
            : target,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l.commonCancel),
        ),
        FilledButton(
          key: const ValueKey('link-confirm'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(disconnect ? l.linkDisconnect : l.linkConnect),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  if (disconnect) {
    await radio.disconnect();
    return true;
  }
  if (link.pin != null) {
    // Marked sensitive on Android, so it stays out of clipboard history and
    // keyboard previews; the pairing prompt takes a paste.
    await copySecretText(link.pin!);
    messenger.showSnackBar(SnackBar(content: Text(l.linkPinCopied)));
  }
  final device = link.kind == ConnectLinkKind.network
      ? MeshtasticBleDevice.network(link.address, port: link.port!)
      : MeshtasticBleDevice(
          id: link.address,
          name: link.address,
          rssi: 0,
          advertisedServices: const [],
        );
  try {
    await radio.connect(device);
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text(l.nodesConnectFailed('$error'))),
    );
    return false;
  }
  return true;
}
