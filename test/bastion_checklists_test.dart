import 'dart:convert';

import 'package:bastion/checklists_page.dart';
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/services/bastion_checklists.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('store', () {
    test('a run copies the steps, records tick times and is saved as a record', () async {
      var now = DateTime.utc(2026, 11, 13, 14, 0);
      final store = SharedPreferencesAsync();
      final lists = BastionChecklists(preferences: store, clock: () => now);
      final t = (await lists.saveTemplate(title: ' Radio check ', items: ['Battery', '  ', 'Channel']))!;
      expect(t.title, 'Radio check');
      expect(t.items, ['Battery', 'Channel']);

      final run = (await lists.startRun(t.id))!;
      now = now.add(const Duration(minutes: 2));
      await lists.setDone(run.id, 1, true);
      now = now.add(const Duration(minutes: 1));
      await lists.setDone(run.id, 1, true); // already ticked: keeps the first time
      await lists.saveTemplate(id: t.id, title: 'Renamed', items: ['Other']);
      await lists.setNote(run.id, ' Ridge was quiet ');
      expect(lists.activeRuns.single.doneCount, 1);
      now = now.add(const Duration(minutes: 5));
      expect(await lists.finish(run.id), isTrue);
      expect(await lists.setDone(run.id, 0, true), isFalse, reason: 'records are read-only');

      final reloaded = BastionChecklists(preferences: store);
      await reloaded.load();
      final record = reloaded.finishedRuns.single;
      expect(record.title, 'Radio check');
      expect(record.items.map((i) => i.text), ['Battery', 'Channel']);
      expect(record.items[1].doneAt, DateTime.utc(2026, 11, 13, 14, 2));
      expect(record.items[0].done, isFalse);
      expect(record.finishedAt, DateTime.utc(2026, 11, 13, 14, 8));
      expect(record.note, 'Ridge was quiet');
      expect(reloaded.templates.single.title, 'Renamed');
      expect(reloaded.activeRuns, isEmpty);
    });

    test('blank checklists are refused and deleting one keeps its records', () async {
      final lists = BastionChecklists();
      expect(await lists.saveTemplate(title: '', items: ['a']), isNull);
      expect(await lists.saveTemplate(title: 'x', items: [' ']), isNull);
      final t = (await lists.saveTemplate(title: 'x', items: ['a']))!;
      final run = (await lists.startRun(t.id))!;
      await lists.finish(run.id);
      await lists.deleteTemplate(t.id);
      expect(lists.templates, isEmpty);
      expect(lists.finishedRuns, hasLength(1));
    });

    test('a damaged record does not hide the others, and unreadable storage is never overwritten', () async {
      final store = SharedPreferencesAsync();
      await store.setString(BastionChecklists.templatesKey, '[{"id":"a"},{"id":"b","title":"B","items":["1"]}]');
      final lists = BastionChecklists(preferences: store);
      await lists.load();
      expect(lists.templates.map((t) => t.id), ['b']);
      expect(lists.storageProblem, isFalse);
    });
  });

  group('export', () {
    final run = ChecklistRun(
      id: 'r', templateId: 't', title: 'Trip "start"',
      startedAt: DateTime.utc(2026, 11, 13, 9),
      finishedAt: DateTime.utc(2026, 11, 13, 9, 30),
      note: '=cmd()',
      items: [RunItem('Battery, full', doneAt: DateTime.utc(2026, 11, 13, 9, 5)), const RunItem('+ antenna')],
    );

    test('CSV quotes text, escapes formulas and uses UTC times', () {
      final lines = ChecklistExport.csv(run).split('\r\n');
      expect(lines.first, '"checklist","started_utc","finished_utc","step","item","done","done_utc","note"');
      expect(lines[1], '"Trip ""start""","2026-11-13T09:00:00.000Z","2026-11-13T09:30:00.000Z","1",'
          '"Battery, full","yes","2026-11-13T09:05:00.000Z","\'=cmd()"');
      expect(lines[2], contains('"\'+ antenna","no",""'));
      expect(lines.last, '');
    });

    test('JSON is versioned and round-trips', () {
      final decoded = jsonDecode(ChecklistExport.json(run)) as Map<String, Object?>;
      expect(decoded['format'], 'notoryx.checklist-run');
      expect(decoded['formatVersion'], 1);
      final back = ChecklistRun.fromJson(Map<String, Object?>.from(decoded['run']! as Map));
      expect(jsonEncode(back.toJson()), jsonEncode(run.toJson()));
    });

    test('file names are safe and timestamped', () {
      final name = ChecklistExport.fileName(run, 'csv');
      expect(name, matches(RegExp(r'^checklist-trip-start-20261113-\d{4}\.csv$')));
    });
  });

  group('pages', () {
    Widget app(Widget home, [Locale locale = const Locale('en')]) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

    void tall(WidgetTester tester) {
      tester.view.physicalSize = const Size(400, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('start from a starter list, tick, finish early and export', (tester) async {
      tall(tester);
      final lists = BastionChecklists();
      final shared = <(String, String, String)>[];
      await tester.pumpWidget(app(ChecklistsPage(
          store: lists, shareFile: (n, m, t) async => shared.add((n, m, t)))));
      await tester.pumpAndSettle();
      expect(find.text('No checklists yet'), findsOneWidget);
      await tester.tap(find.text('Add starter checklists'));
      await tester.pumpAndSettle();
      expect(find.text('Radio check'), findsOneWidget);

      await tester.tap(find.byTooltip('Start Radio check'));
      await tester.pumpAndSettle();
      expect(find.text('0 of 5 done'), findsOneWidget);
      await tester.tap(find.text('Test message delivered'));
      await tester.pumpAndSettle();
      expect(find.text('1 of 5 done'), findsOneWidget);
      expect(find.textContaining('Done '), findsOneWidget);

      await tester.tap(find.text('Finish and save record'));
      await tester.pumpAndSettle();
      expect(find.text('4 steps are not done. They are saved as not done.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Finish and save record').last);
      await tester.pumpAndSettle();
      expect(lists.finishedRuns.single.doneCount, 1);

      await tester.tap(find.text('Spreadsheet (CSV)'));
      await tester.tap(find.text('Data file (JSON)'));
      await tester.pumpAndSettle();
      expect(shared.map((s) => s.$2), ['text/csv', 'application/json']);
      expect(shared.first.$1, startsWith('checklist-radio-check-'));
      expect(shared.first.$3, contains('"Test message delivered","yes"'));
      expect(find.byType(CheckboxListTile), findsNWidgets(5));
      expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile).first).onChanged, isNull);
    });

    testWidgets('edit a checklist: steps can be reordered and removed with labelled buttons', (tester) async {
      tall(tester);
      final lists = BastionChecklists();
      await tester.pumpWidget(app(ChecklistEditPage(store: lists)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save checklist'));
      await tester.pumpAndSettle();
      expect(find.text('Give the checklist a name and at least one step.'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Camp');
      await tester.enterText(find.widgetWithText(TextField, 'Step 1'), 'Water');
      await tester.tap(find.text('Add step'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Step 2'), 'Tent');
      await tester.tap(find.text('Add step'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Step 3'), 'Stove');
      await tester.tap(find.byTooltip('Move step 2 up'));
      await tester.tap(find.byTooltip('Remove step 3'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save checklist'));
      await tester.pumpAndSettle();
      expect(lists.templates.single.items, ['Tent', 'Water']);
    });

    testWidgets('checklists are translated', (tester) async {
      await tester.pumpWidget(app(ChecklistsPage(store: BastionChecklists()), const Locale('de')));
      await tester.pumpAndSettle();
      expect(find.text('Noch keine Checklisten'), findsOneWidget);
      expect(find.text('Neue Checkliste'), findsOneWidget);
    });
  });
}
