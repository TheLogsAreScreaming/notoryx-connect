import '../l10n/generated/app_localizations.dart';
import 'bastion_trip.dart';

/// A plain-text trip plan for someone who stays home: who is going, which
/// radios to ask about, when to worry and what to do. Built only from
/// what's on the phone; nothing is sent over the mesh.
abstract final class BastionTripSheet {
  static String build({
    required AppLocalizations l,
    required TripPlan plan,
    required String myName,
    required int? myNum,
    required List<({int num, String name})> contacts,
    required String Function(DateTime) formatTime,
    CheckInRecord? lastCheckIn,
    double? latitude,
    double? longitude,
    String returnBy = '',
  }) {
    String id(int n) => '!${n.toRadixString(16).padLeft(8, '0')}';
    final lines = <String>[
      l.tsTitle(plan.name),
      '',
      if (myNum != null) l.tsMyRadio(myName, id(myNum)) else l.tsMyRadioUnknown,
      plan.startedAt == null ? l.tsNotStarted : l.tsStarted(formatTime(plan.startedAt!)),
      if (returnBy.trim().isNotEmpty) l.tsReturnBy(returnBy.trim()),
      if (lastCheckIn != null) l.tsLastCheckIn(lastCheckIn.label, formatTime(lastCheckIn.at)),
      if (latitude != null && longitude != null)
        l.tsLastPosition('${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}'),
      '',
      l.tsContacts,
      if (contacts.isEmpty) '  ${l.tsNoContacts}',
      for (final c in contacts) '  • ${c.name} (${id(c.num)})',
      '',
      if (plan.overdueMinutes > 0) l.tsOverdueRule(plan.overdueMinutes),
      l.tsIfNoContact,
      '',
      l.tsFooter,
    ];
    return lines.join('\n');
  }
}
