import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/bastion_error_log.dart';
import 'package:bastion/services/bastion_support_bundle.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:bastion/support_report_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const facts = SupportFacts(
  appVersion: '1.0.0+99',
  platform: 'android 15',
  locale: 'en',
  connection: 'connected',
  link: 'bluetooth',
  radioModel: 'TBEAM',
  firmware: '2.7.15',
  region: 'US',
  preset: 'LONG_FAST',
  nodesHeard: 4,
  nodesKnown: 2000,
  channelsInUse: 2,
  settings: {'MQTT proxy': 'off', 'Units': 'imperial'},
);

void main() {
  test('keys, positions, e-mail, node IDs and the radio name are removed', () {
    final out = BastionSupportBundle.redact(
      'Connected to Ridge_ab12 !1234abcd psk=1PG7OiApB1nwvP+rz05pAQ== at 35.21234, -80.84321 mail a@b.org '
      'key 00112233445566778899aabbccddeeff00112233',
      ['Ridge_ab12'],
    );
    expect(out, isNot(contains('Ridge_ab12')));
    expect(out, isNot(contains('1234abcd')));
    expect(out, isNot(contains('1PG7OiApB1nwvP')));
    expect(out, isNot(contains('35.21234')));
    expect(out, isNot(contains('a@b.org')));
    expect(out, isNot(contains('00112233445566778899')));
    expect(out, contains('[radio name]'));
    expect(out, contains('[position removed]'));
  });

  test('the report lists facts, settings, errors and the log', () {
    final text = BastionSupportBundle.build(
      facts: facts,
      connectionLog: ['2026-11-25T10:00:00  Connected to Ridge_ab12'],
      errors: ['2026-11-25T10:01:00  StateError: radio not ready'],
      radioNames: ['Ridge_ab12'],
      now: DateTime.utc(2026, 11, 25, 10, 2),
    );
    expect(text, contains('Version: 1.0.0+99'));
    expect(text, contains('Model: TBEAM'));
    expect(text, contains('Region / preset: US / LONG_FAST'));
    expect(text, contains('Nodes heard / known: 4 / 2000'));
    expect(text, contains('- MQTT proxy: off'));
    expect(text, contains('StateError: radio not ready'));
    expect(text, contains('Connected to [radio name]'));
    expect(text, isNot(contains('Ridge_ab12')));
  });

  test('empty error and connection logs say so', () {
    final text = BastionSupportBundle.build(facts: facts, connectionLog: const [], errors: const []);
    expect(text, contains('Recent app errors\n- none'));
    expect(text, contains('Connection log\n- empty'));
  });

  test('the error log keeps only the newest entries, first line only', () {
    final log = BastionErrorLog(capacity: 2);
    log.add('one');
    log.add('two\nstack');
    log.add('three');
    expect(log.entries.map((e) => e.summary), ['two', 'three']);
  });

  testWidgets('the page previews the report and copies it', (tester) async {
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final errors = BastionErrorLog()..add('FormatException: bad backup');
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SupportReportPage(radio: radio, errors: errors, now: DateTime.utc(2026, 11, 25)),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Left out: keys, messages'), findsOneWidget);
    final preview = tester.widget<SelectableText>(find.byKey(const ValueKey('support-preview'))).data!;
    expect(preview, contains('NOTORYX Connect support report'));
    expect(preview, contains('FormatException: bad backup'));
    await tester.tap(find.byKey(const ValueKey('support-copy')));
    await tester.pumpAndSettle();
    expect(copied.single, preview);
    expect(find.text('Support report copied.'), findsOneWidget);
  });
}
