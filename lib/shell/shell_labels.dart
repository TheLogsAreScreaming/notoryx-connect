part of '../main.dart';

/// One or two letters for a node's avatar.
String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.characters.take(trimmed.length >= 2 ? 2 : 1).toString().toUpperCase();
}

IconData _signalIcon(int rssi) {
  if (rssi >= -60) return Icons.signal_cellular_alt;
  if (rssi >= -75) return Icons.signal_cellular_alt_2_bar;
  return Icons.signal_cellular_alt_1_bar;
}

/// "just now", "5 min ago", "3 h ago", or a date, for last-seen times.
String _ago(BuildContext context, DateTime time) {
  final s = AppLocalizations.of(context);
  final d = DateTime.now().difference(time);
  if (d.inMinutes < 1) return s.agoNow;
  if (d.inHours < 1) return s.agoMin(d.inMinutes);
  if (d.inDays < 1) return s.agoHours(d.inHours);
  if (d.inDays < 7) return s.agoDays(d.inDays);
  final l = time.toLocal();
  return '${l.year}-${l.month.toString().padLeft(2, '0')}-${l.day.toString().padLeft(2, '0')}';
}

/// The time of day as HH:mm, for message timestamps.
String _clock(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

IconData _deliveryIcon(BastionDeliveryState state) => switch (state) {
  BastionDeliveryState.received => Icons.call_received,
  BastionDeliveryState.queued => Icons.schedule,
  BastionDeliveryState.sent => Icons.check,
  BastionDeliveryState.delivered => Icons.done_all,
  BastionDeliveryState.failed => Icons.error_outline,
};

String _deliveryLabel(BuildContext context, BastionDeliveryState state) {
  final l = AppLocalizations.of(context);
  return switch (state) {
    BastionDeliveryState.received => l.deliveryReceived,
    BastionDeliveryState.queued => l.deliveryQueued,
    BastionDeliveryState.sent => l.deliverySent,
    BastionDeliveryState.delivered => l.deliveryDelivered,
    BastionDeliveryState.failed => l.deliveryFailed,
  };
}

String _rssiLabel(BuildContext context, int rssi) {
  final l = AppLocalizations.of(context);
  if (rssi >= -60) return l.rssiStrong;
  if (rssi >= -75) return l.rssiUsable;
  if (rssi >= -90) return l.rssiWeak;
  return l.rssiVeryWeak;
}

String _heardLabel(BuildContext context, BastionHeardWithin value) {
  final l = AppLocalizations.of(context);
  return switch (value) {
    BastionHeardWithin.any => l.heardAny,
    BastionHeardWithin.hour => l.heardHour,
    BastionHeardWithin.day => l.heardDay,
    BastionHeardWithin.week => l.heardWeek,
  };
}

String _connectionLabel(BuildContext context, MeshtasticConnectionState state) {
  final l = AppLocalizations.of(context);
  return switch (state) {
    MeshtasticConnectionState.disconnected => l.connOffline,
    MeshtasticConnectionState.discovering => l.connScanning,
    MeshtasticConnectionState.connecting => l.connConnecting,
    MeshtasticConnectionState.connected => l.connSyncing,
    MeshtasticConnectionState.synchronizing => l.connSyncing,
    MeshtasticConnectionState.ready => l.connConnected,
    MeshtasticConnectionState.error => l.connError,
  };
}

NxTone _connectionTone(MeshtasticConnectionState state) => switch (state) {
  MeshtasticConnectionState.disconnected => NxTone.neutral,
  MeshtasticConnectionState.discovering ||
  MeshtasticConnectionState.connecting ||
  MeshtasticConnectionState.connected ||
  MeshtasticConnectionState.synchronizing => NxTone.info,
  MeshtasticConnectionState.ready => NxTone.success,
  MeshtasticConnectionState.error => NxTone.danger,
};

bool _connectionBusy(MeshtasticConnectionState state) => switch (state) {
  MeshtasticConnectionState.discovering ||
  MeshtasticConnectionState.connecting ||
  MeshtasticConnectionState.connected ||
  MeshtasticConnectionState.synchronizing => true,
  _ => false,
};

/// "Direct" or "2 hops", or null when the hop count is unknown.
String? _hopsLabel(BuildContext context, int? hops) => switch (hops) {
  null => null,
  0 => AppLocalizations.of(context).hopsDirect,
  final n => AppLocalizations.of(context).hopsCount(n),
};
