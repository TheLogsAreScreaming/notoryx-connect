import 'dart:convert';

/// One blank in a structured report.
class BastionReportField {
  const BastionReportField(this.code, this.label, this.hint);

  /// Short tag sent on the air, such as `S` or `3`.
  final String code;
  final String label;
  final String hint;
}

/// A structured field report that fits in one mesh text message.
///
/// The sent text stays English, like every other message that goes on air.
class BastionReportTemplate {
  const BastionReportTemplate({required this.tag, required this.title, required this.fields});

  final String tag;
  final String title;
  final List<BastionReportField> fields;

  /// The longest text the Field records page will send.
  static const maxBytes = 220;

  static const salute = BastionReportTemplate(tag: 'SALUTE', title: 'SALUTE report', fields: [
    BastionReportField('S', 'Size', 'How many people or vehicles'),
    BastionReportField('A', 'Activity', 'What they are doing'),
    BastionReportField('L', 'Location', 'Where they are'),
    BastionReportField('U', 'Unit', 'Who they are, uniform or markings'),
    BastionReportField('T', 'Time', 'When you saw them'),
    BastionReportField('E', 'Equipment', 'What they have with them'),
  ]);

  static const nineLine = BastionReportTemplate(tag: '9LINE', title: '9-Line medical evacuation', fields: [
    BastionReportField('1', 'Pickup location', 'Coordinates or landmark'),
    BastionReportField('2', 'Radio frequency and callsign', 'How to reach you'),
    BastionReportField('3', 'Patients by urgency', 'For example 1 urgent, 2 routine'),
    BastionReportField('4', 'Special equipment', 'None, hoist, extraction, ventilator'),
    BastionReportField('5', 'Patients by type', 'Litter or walking'),
    BastionReportField('6', 'Security at pickup', 'No threat, possible, or armed escort'),
    BastionReportField('7', 'How the site is marked', 'Panel, smoke, light, or none'),
    BastionReportField('8', 'Patient status', 'Who the patients are'),
    BastionReportField('9', 'Hazards and terrain', 'Slope, wires, contamination'),
  ]);

  static const all = [salute, nineLine];

  /// Builds the text to send. Blank fields are left out to save airtime; each
  /// part keeps its code, so the receiver still knows which line it is.
  String compose(Map<String, String> values) {
    final parts = <String>[
      for (final field in fields)
        if ((values[field.code] ?? '').trim().isNotEmpty) '${field.code}: ${_clean(values[field.code]!)}',
    ];
    return parts.isEmpty ? '' : '$tag | ${parts.join(' | ')}';
  }

  /// Size on the air, in UTF-8 bytes.
  static int bytesOf(String text) => utf8.encode(text).length;

  // A line break or a separator typed into a field would blur the parts.
  static String _clean(String value) =>
      value.trim().replaceAll(RegExp(r'\s*\|\s*'), ' / ').replaceAll(RegExp(r'\s+'), ' ');
}
