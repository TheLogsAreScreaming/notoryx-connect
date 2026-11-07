import 'bastion_chat_message.dart';
import 'bastion_telemetry_codec.dart';
import 'meshtastic_node_database.dart';

/// How a measure compares with what keeps a mesh working well.
enum HealthLevel { good, busy, overloaded, unknown }

/// A snapshot of how the mesh around this radio is doing, for the Mesh
/// health screen. Pure: built from nodes, telemetry and messages.
class MeshHealthSummary {
  const MeshHealthSummary({
    required this.channelUtilization,
    required this.airUtilTx,
    required this.channelLevel,
    required this.airtimeLevel,
    required this.activeNodes,
    required this.quietNodes,
    required this.hops,
    required this.signal,
    required this.messagesLastHour,
    required this.messagesLastDay,
    required this.busiest,
  });

  /// How busy the channel is, in percent, as this radio hears it (or the
  /// mesh average when this radio has not reported). Null when unknown.
  final double? channelUtilization;

  /// Share of the last hour this radio spent transmitting, in percent.
  final double? airUtilTx;

  final HealthLevel channelLevel;
  final HealthLevel airtimeLevel;

  /// Nodes heard in the last two hours, and those not heard for longer.
  final int activeNodes;
  final int quietNodes;

  /// Node counts by hop distance: 0 = heard directly. Key -1 = unknown.
  final Map<int, int> hops;

  /// Node counts by signal quality bucket of their last packet.
  final Map<SignalBucket, int> signal;

  final int messagesLastHour;
  final int messagesLastDay;

  /// Nodes reporting the highest transmit airtime, highest first.
  final List<({int node, double airUtilTx})> busiest;

  /// Firmware starts delaying its own messages near 25% channel use.
  static const busyChannel = 25.0;
  static const overloadedChannel = 40.0;

  /// Many regions limit a radio to about 10% transmit time per hour.
  static const busyAirtime = 7.0;
  static const overloadedAirtime = 10.0;

  static const quietAfter = Duration(hours: 2);

  static HealthLevel levelOf(double? value, double busy, double overloaded) => value == null
      ? HealthLevel.unknown
      : value >= overloaded
          ? HealthLevel.overloaded
          : value >= busy
              ? HealthLevel.busy
              : HealthLevel.good;

  static MeshHealthSummary of({
    required List<MeshtasticNode> nodes,
    required Map<int, BastionDeviceTelemetry> telemetry,
    required List<BastionChatMessage> messages,
    required int? local,
    required DateTime now,
  }) {
    final own = local == null ? null : telemetry[local];
    final others = [for (final t in telemetry.values) if (t.channelUtilization != null) t.channelUtilization!];
    final channel = own?.channelUtilization ??
        (others.isEmpty ? null : others.reduce((a, b) => a + b) / others.length);
    final air = own?.airUtilTx;

    var active = 0, quiet = 0;
    final hops = <int, int>{};
    final signal = <SignalBucket, int>{};
    for (final n in nodes) {
      if (n.num == local) continue;
      final heard = n.lastHeard;
      if (heard != null && now.difference(heard) <= quietAfter) {
        active++;
      } else {
        quiet++;
      }
      final h = n.hopsAway ?? -1;
      hops[h] = (hops[h] ?? 0) + 1;
      final b = SignalBucket.of(n.snr);
      signal[b] = (signal[b] ?? 0) + 1;
    }
    final real = [for (final m in messages) if (!m.isReaction) m];
    final busiest = [
      for (final MapEntry(:key, :value) in telemetry.entries)
        if (value.airUtilTx != null) (node: key, airUtilTx: value.airUtilTx!),
    ]..sort((a, b) => b.airUtilTx.compareTo(a.airUtilTx));
    return MeshHealthSummary(
      channelUtilization: channel,
      airUtilTx: air,
      channelLevel: levelOf(channel, busyChannel, overloadedChannel),
      airtimeLevel: levelOf(air, busyAirtime, overloadedAirtime),
      activeNodes: active,
      quietNodes: quiet,
      hops: hops,
      signal: signal,
      messagesLastHour: real.where((m) => now.difference(m.timestamp) <= const Duration(hours: 1)).length,
      messagesLastDay: real.where((m) => now.difference(m.timestamp) <= const Duration(days: 1)).length,
      busiest: busiest.take(5).toList(),
    );
  }

  /// Plain advice for the worst problem, or null when all is well.
  String? get advice {
    if (channelLevel == HealthLevel.overloaded) {
      return 'The channel is very busy. Messages may be delayed or lost. '
          'Send less often, avoid repeated traceroutes, and consider a faster preset if everyone can change.';
    }
    if (airtimeLevel == HealthLevel.overloaded) {
      return 'Your radio has used about its hourly transmit limit. It may hold messages back until the hour rolls over.';
    }
    if (channelLevel == HealthLevel.busy) {
      return 'The channel is getting busy. Keep messages short and avoid automatic or repeated sends.';
    }
    if (airtimeLevel == HealthLevel.busy) {
      return 'Your radio is close to its hourly transmit limit.';
    }
    return null;
  }
}

/// Signal quality from SNR, in the words the app uses elsewhere.
enum SignalBucket {
  strong('Strong', 'SNR 5 dB or better'),
  usable('Usable', 'SNR −5 to 5 dB'),
  weak('Weak', 'SNR below −5 dB'),
  unknown('Not measured', 'No signal reading');

  const SignalBucket(this.label, this.detail);
  final String label;
  final String detail;

  static SignalBucket of(double? snr) => snr == null
      ? unknown
      : snr >= 5
          ? strong
          : snr >= -5
              ? usable
              : weak;
}
