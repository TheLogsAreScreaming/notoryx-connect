import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'services/bastion_chat_message.dart';
import 'services/bastion_trip.dart';
import 'services/meshtastic_node_database.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// One contact's delivery status, in words, icon and tone.
({String word, IconData icon, NxTone tone}) deliveryLook(BastionDeliveryState state) => switch (state) {
      BastionDeliveryState.delivered => (word: 'Delivered', icon: Icons.check_circle, tone: NxTone.success),
      BastionDeliveryState.failed => (word: 'Not delivered', icon: Icons.cancel, tone: NxTone.danger),
      BastionDeliveryState.sent => (word: 'Sent, no reply yet', icon: Icons.schedule, tone: NxTone.warning),
      _ => (word: 'Waiting to send', icon: Icons.hourglass_empty, tone: NxTone.neutral),
    };

/// Who got a check-in, and where each contact was last known to be.
class CheckInDeliveryPage extends StatelessWidget {
  const CheckInDeliveryPage({super.key, required this.radio, required this.record});

  final MeshtasticRadioCoordinator radio;
  final CheckInRecord record;

  static String _age(DateTime? t) {
    if (t == null) return 'time unknown';
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Check-in delivery')),
        body: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: radio,
            builder: (context, _) {
              final delivery = radio.trip.delivery(record);
              final status = NxStatusColors.of(context);
              final scheme = Theme.of(context).colorScheme;
              final byNum = {for (final n in radio.nodes) n.num: n};
              final placed = <(int, MeshtasticNode, BastionDeliveryState)>[
                for (final e in delivery.entries)
                  if (byNum[e.key] case final n? when n.hasPosition) (e.key, n, e.value),
              ];
              final points = [for (final p in placed) LatLng(p.$2.latitude!, p.$2.longitude!)];
              final delivered = delivery.values.where((s) => s == BastionDeliveryState.delivered).length;
              final summary = '${record.label}: delivered to $delivered of ${delivery.length}';
              return ListView(padding: NxSpace.page, children: [
                NxBanner(
                  tone: delivered == delivery.length ? NxTone.success : NxTone.warning,
                  title: summary,
                  message: 'Delivered means the contact\'s radio confirmed it, not that they have read it.',
                ),
                if (points.isNotEmpty)
                  Card(
                    child: SizedBox(
                      height: 260,
                      child: Semantics(
                        label: 'Map of ${points.length} trip contacts. The list below has the same details.',
                        excludeSemantics: true,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: points.first,
                            initialZoom: 12,
                            initialCameraFit: points.length > 1
                                ? CameraFit.bounds(
                                    bounds: LatLngBounds.fromPoints(points), padding: const EdgeInsets.all(48))
                                : null,
                            interactionOptions:
                                const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.bastionmesh.connect',
                              maxNativeZoom: 19,
                            ),
                            MarkerLayer(markers: [
                              for (final (i, p) in placed.indexed)
                                Marker(
                                  point: points[i],
                                  width: 120,
                                  height: 56,
                                  child: _Pin(name: p.$2.shortName ?? p.$2.displayName, state: p.$3),
                                ),
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                const NxSectionLabel('Trip contacts'),
                Card(
                  child: Column(children: [
                    for (final e in delivery.entries)
                      Builder(builder: (context) {
                        final look = deliveryLook(e.value);
                        final node = byNum[e.key];
                        return ListTile(
                          leading: Icon(look.icon, color: status.strong(look.tone, scheme)),
                          title: Text(radio.nodeName(e.key)),
                          subtitle: Text([
                            look.word,
                            node != null && node.hasPosition
                                ? 'last known position ${_age(node.positionTime)}'
                                : 'no position known',
                          ].join(' • ')),
                        );
                      }),
                  ]),
                ),
                if (delivery.values.contains(BastionDeliveryState.failed))
                  Padding(
                    padding: const EdgeInsets.only(top: NxSpace.sm),
                    child: FilledButton.icon(
                      onPressed: radio.trip.resendFailed,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Resend to those not reached'),
                    ),
                  ),
              ]);
            },
          ),
        ),
      );
}

class _Pin extends StatelessWidget {
  const _Pin({required this.name, required this.state});
  final String name;
  final BastionDeliveryState state;

  @override
  Widget build(BuildContext context) {
    // Fixed colors: pins sit on map tiles, whatever the theme. The icon
    // shape also differs, so color isn't the only signal.
    final look = deliveryLook(state);
    final color = switch (look.tone) {
      NxTone.success => const Color(0xFF1C7442),
      NxTone.danger => const Color(0xFFB3261E),
      NxTone.warning => const Color(0xFF835500),
      _ => const Color(0xFF3A3E36),
    };
    return Column(mainAxisSize: MainAxisSize.min, children: [
      DecoratedBox(
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
        child: Padding(padding: const EdgeInsets.all(2), child: Icon(look.icon, color: color, size: 22)),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4)),
        child: Text(name,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ),
    ]);
  }
}
