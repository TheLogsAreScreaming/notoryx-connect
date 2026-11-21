import 'dart:convert';

import 'package:flutter/widgets.dart';

import '../generated/meshtastic/apponly.pb.dart';
import 'bastion_trip.dart';
import 'meshtastic_channel_url.dart';

/// A trip contact carried in a team setup.
typedef TeamMember = ({int num, String name});

/// Everything one team member hands another in a single QR code, as on
/// NOTORYX Core: the radio's channels and LoRa settings (as a standard
/// Meshtastic channel link) plus the trip contacts and check-in settings.
@immutable
class TeamSetup {
  const TeamSetup({
    required this.channelLink,
    this.tripName = '',
    this.members = const [],
    this.overdueMinutes = 0,
    this.sosChannel = -1,
  });

  /// The standard Meshtastic channel link (channels + LoRa settings).
  final String channelLink;
  final String tripName;
  final List<TeamMember> members;

  /// Warn when a trip contact is silent this long; 0 is off.
  final int overdueMinutes;

  /// Channel an SOS is also broadcast on, or -1 for trip contacts only.
  final int sosChannel;

  static const prefix = 'notoryx-team:1:';

  /// The most text a phone camera reliably reads from one QR code.
  static const maxLength = 1800;

  /// Longest name kept per contact.
  static const maxName = 24;

  ChannelSet get channels => MeshtasticChannelUrl.decode(channelLink);

  /// Builds a setup from this radio's channels and trip plan, including
  /// [self] (this radio) as a contact so the others can reach you.
  static TeamSetup from({
    required ChannelSet channels,
    required TripPlan plan,
    required String Function(int num) nameOf,
    int? self,
  }) {
    final nums = <int>{?self, ...plan.members}.take(TripPlan.maxMembers);
    return TeamSetup(
      channelLink: MeshtasticChannelUrl.encode(channels),
      tripName: plan.name,
      members: [for (final n in nums) (num: n, name: nameOf(n))],
      overdueMinutes: plan.overdueMinutes,
      sosChannel: plan.sosChannel,
    );
  }

  /// The text for the QR code. Names are shortened, then dropped, if the
  /// whole would not fit in one code.
  String encode() {
    String build(bool names) {
      final json = jsonEncode({
        'c': channelLink,
        if (tripName.isNotEmpty) 't': tripName,
        'm': [
          for (final m in members)
            if (names) [m.num, m.name.characters.take(maxName).toString()] else [m.num],
        ],
        'o': overdueMinutes,
        's': sosChannel,
      });
      return '$prefix${base64Url.encode(utf8.encode(json))}';
    }

    final full = build(true);
    return full.length <= maxLength ? full : build(false);
  }

  static bool looksLike(String text) => text.trim().startsWith(prefix);

  /// Reads a team setup; throws [FormatException] for anything else or a
  /// damaged code.
  static TeamSetup decode(String text) {
    final t = text.trim();
    if (!t.startsWith(prefix)) throw const FormatException('Not a team setup');
    final Object? j;
    try {
      j = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(t.substring(prefix.length)))));
    } on Object {
      throw const FormatException('This team code is damaged');
    }
    if (j is! Map || j['c'] is! String) throw const FormatException('This team code is damaged');
    final link = j['c'] as String;
    MeshtasticChannelUrl.decode(link); // Throws for a bad channel link.
    final members = <TeamMember>[];
    for (final m in (j['m'] as List? ?? const [])) {
      if (m is List && m.isNotEmpty && m[0] is int && m[0] > 0 && m[0] < 0xffffffff) {
        final name = m.length > 1 && m[1] is String ? (m[1] as String) : '';
        members.add((num: m[0] as int, name: name.characters.take(maxName).toString()));
      }
    }
    final o = j['o'], s = j['s'];
    return TeamSetup(
      channelLink: link,
      tripName: j['t'] is String ? j['t'] as String : '',
      members: members.take(TripPlan.maxMembers).toList(),
      overdueMinutes: o is int && o >= 0 && o <= 24 * 60 ? o : 0,
      sosChannel: s is int && s >= -1 && s <= 7 ? s : -1,
    );
  }

  /// [plan] with these contacts added (not ones it has, not [self]), up to
  /// the trip's limit. The overdue and SOS settings come along only for a
  /// trip with no contacts yet, so they never overwrite your own choices.
  TripPlan mergeInto(TripPlan plan, {int? self}) {
    final merged = [...plan.members];
    for (final m in members) {
      if (m.num == self || merged.contains(m.num)) continue;
      if (merged.length >= TripPlan.maxMembers) break;
      merged.add(m.num);
    }
    final fresh = plan.members.isEmpty;
    return plan.copyWith(
      members: merged,
      overdueMinutes: fresh ? overdueMinutes : null,
      sosChannel: fresh ? sosChannel : null,
    );
  }

  /// How many of these contacts [mergeInto] would add.
  int newMembers(TripPlan plan, {int? self}) => mergeInto(plan, self: self).members.length - plan.members.length;
}
