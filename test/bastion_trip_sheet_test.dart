import 'package:bastion/l10n/generated/app_localizations_en.dart';
import 'package:bastion/services/bastion_trip.dart';
import 'package:bastion/services/bastion_trip_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l = AppLocalizationsEn();
  String time(DateTime t) => t.toUtc().toIso8601String();

  test('lists the plan, radios, rule and what to do', () {
    final text = BastionTripSheet.build(
      l: l,
      plan: TripPlan(name: 'Ridge loop', members: const [0xa1b2c3d4], startedAt: DateTime.utc(2026, 11, 14, 8), overdueMinutes: 90),
      myName: 'Base',
      myNum: 0x12,
      contacts: const [(num: 0xa1b2c3d4, name: 'Sam')],
      formatTime: time,
      latitude: 45.123456,
      longitude: -110.5,
      returnBy: 'Sunday 6 pm',
    );
    expect(text, startsWith('Trip plan: Ridge loop'));
    expect(text, contains('My radio: Base (!00000012)'));
    expect(text, contains('Trip started: 2026-11-14T08:00:00.000Z'));
    expect(text, contains('Expected back: Sunday 6 pm'));
    expect(text, contains('• Sam (!a1b2c3d4)'));
    expect(text, contains('45.12346, -110.50000'));
    expect(text, contains('silent for 90 minutes'));
    expect(text, contains('emergency number'));
  });

  test('says what is unknown instead of leaving gaps', () {
    final text = BastionTripSheet.build(
      l: l,
      plan: const TripPlan(overdueMinutes: 0),
      myName: '',
      myNum: null,
      contacts: const [],
      formatTime: time,
    );
    expect(text, contains(l.tsMyRadioUnknown));
    expect(text, contains(l.tsNotStarted));
    expect(text, contains(l.tsNoContacts));
    expect(text, isNot(contains('silent for')));
    expect(text, isNot(contains('Expected back')));
  });
}
