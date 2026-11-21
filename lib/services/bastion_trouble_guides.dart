import 'package:flutter/foundation.dart';

import 'bastion_chat_message.dart';
import 'meshtastic_node_database.dart';
import 'meshtastic_text_codec.dart';

/// A step's live check.
enum StepResult { ok, problem, unchecked }

/// The guides beyond "can't connect", which the doctor's checks above
/// already cover.
enum TroubleGuide { noDelivery, hearNobody }

/// Every step a guide uses.
enum TroubleStep { connected, heardRecently, neighbours, sameChannel, hops, region, busyChannel, preset, antenna }

/// What the live checks look at.
@immutable
class TroubleSnapshot {
  const TroubleSnapshot({
    required this.connected,
    required this.messagedNodes,
    required this.messagedNotHeardInDay,
    required this.heardLastHour,
    this.regionSet,
    this.channelUtilization,
  });

  final bool connected;

  /// Nodes you sent a direct message to in the last week.
  final int messagedNodes;

  /// Of those, how many weren't heard in the last day.
  final int messagedNotHeardInDay;

  /// Other nodes heard in the last hour.
  final int heardLastHour;

  /// Whether the radio has a LoRa region set; null when unknown.
  final bool? regionSet;

  /// The radio's last channel utilization, in percent; null when unknown.
  final double? channelUtilization;

  /// Above this, the channel is too busy for messages to get through
  /// reliably.
  static const busyPercent = 40.0;

  /// Builds a snapshot from what the app knows about the mesh.
  static TroubleSnapshot of({
    required bool connected,
    required int? localNode,
    required List<MeshtasticNode> nodes,
    required List<BastionChatMessage> messages,
    required DateTime now,
    bool? regionSet,
    double? channelUtilization,
  }) {
    final week = now.subtract(const Duration(days: 7));
    final messaged = {
      for (final m in messages)
        if (m.direction == BastionMessageDirection.outgoing &&
            m.to != MeshtasticTextCodec.broadcastNode &&
            m.timestamp.isAfter(week))
          m.to,
    };
    final heard = {for (final n in nodes) n.num: n.lastHeard};
    final day = now.subtract(const Duration(days: 1));
    final hour = now.subtract(const Duration(hours: 1));
    return TroubleSnapshot(
      connected: connected,
      messagedNodes: messaged.length,
      messagedNotHeardInDay: messaged.where((n) => !(heard[n]?.isAfter(day) ?? false)).length,
      heardLastHour: nodes.where((n) => n.num != localNode && (n.lastHeard?.isAfter(hour) ?? false)).length,
      regionSet: regionSet,
      channelUtilization: channelUtilization,
    );
  }
}

/// A guide's steps, in order, with their checks.
List<(TroubleStep, StepResult)> runGuide(TroubleGuide guide, TroubleSnapshot s) {
  StepResult check(bool ok) => ok ? StepResult.ok : StepResult.problem;
  // Without a connection, radio-side checks can't run.
  StepResult whenConnected(bool? ok) => !s.connected || ok == null ? StepResult.unchecked : check(ok);
  final connected = check(s.connected);
  final busy = s.channelUtilization == null ? null : s.channelUtilization! < TroubleSnapshot.busyPercent;
  return switch (guide) {
    TroubleGuide.noDelivery => [
        (TroubleStep.connected, connected),
        (
          TroubleStep.heardRecently,
          s.messagedNodes == 0 ? StepResult.unchecked : check(s.messagedNotHeardInDay == 0),
        ),
        (TroubleStep.neighbours, whenConnected(s.heardLastHour > 0)),
        (TroubleStep.busyChannel, whenConnected(busy)),
        (TroubleStep.sameChannel, StepResult.unchecked),
        (TroubleStep.hops, StepResult.unchecked),
      ],
    TroubleGuide.hearNobody => [
        (TroubleStep.connected, connected),
        (TroubleStep.region, whenConnected(s.regionSet)),
        (TroubleStep.neighbours, whenConnected(s.heardLastHour > 0)),
        (TroubleStep.preset, StepResult.unchecked),
        (TroubleStep.antenna, StepResult.unchecked),
      ],
  };
}

/// The step to start with: the first problem, else the first step that
/// couldn't be checked; null when every check passed.
TroubleStep? startHere(List<(TroubleStep, StepResult)> steps) {
  for (final (step, result) in steps) {
    if (result == StepResult.problem) return step;
  }
  for (final (step, result) in steps) {
    if (result == StepResult.unchecked) return step;
  }
  return null;
}
