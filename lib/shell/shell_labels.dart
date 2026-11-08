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
String _ago(DateTime time) {
  final d = DateTime.now().difference(time);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} h ago';
  if (d.inDays < 7) return '${d.inDays} d ago';
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

String _deliveryLabel(BastionDeliveryState state) => switch (state) {
  BastionDeliveryState.received => 'Received',
  BastionDeliveryState.queued => 'Queued',
  BastionDeliveryState.sent => 'Sent',
  BastionDeliveryState.delivered => 'Delivered',
  BastionDeliveryState.failed => 'Not delivered',
};

String _rssiLabel(int rssi) {
  if (rssi >= -60) return 'Strong Bluetooth signal';
  if (rssi >= -75) return 'Usable Bluetooth signal';
  if (rssi >= -90) return 'Weak Bluetooth signal';
  return 'Very weak Bluetooth signal';
}

String _connectionLabel(MeshtasticConnectionState state) => switch (state) {
  MeshtasticConnectionState.disconnected => 'Offline',
  MeshtasticConnectionState.discovering => 'Scanning',
  MeshtasticConnectionState.connecting => 'Connecting',
  MeshtasticConnectionState.connected => 'Syncing',
  MeshtasticConnectionState.synchronizing => 'Syncing',
  MeshtasticConnectionState.ready => 'Connected',
  MeshtasticConnectionState.error => 'Error',
};

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
String? _hopsLabel(int? hops) => switch (hops) {
  null => null,
  0 => 'Direct',
  1 => '1 hop',
  final n => '$n hops',
};
