import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/node_journal_page.dart';
import 'package:bastion/node_mark.dart';
import 'package:bastion/services/bastion_node_journal.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final _start = DateTime.utc(2026, 11, 1, 0, 30);

JournalEntry _entry({
  DateTime? first,
  DateTime? last,
  List<int> hours = const [],
  int days = 1,
  int heard = 1,
  int internet = 0,
  int power = 0,
  List<({double lat, double lon})> places = const [],
}) => JournalEntry(
  num: 0x1234, firstHeard: first ?? _start, lastHeard: last ?? _start,
  hours: hours, days: days, heard: heard, internet: internet,
  externalPower: power, places: places,
);

int _hour(DateTime t) => t.millisecondsSinceEpoch ~/ 1000 ~/ 3600;

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  group('behaviour labels', () {
    test('a node on the air nearly every hour in one place is an always-on relay', () {
      final now = _start.add(const Duration(hours: 47));
      final hours = [for (var h = _hour(_start); h <= _hour(now); h++) if (h % 10 != 0) h];
      final labels = NodeBehaviourClassifier.classify(
        _entry(last: now, hours: hours, days: 2, heard: 300, power: 40,
            places: const [(lat: 45.0, lon: -122.0)]),
        now,
      );
      expect(labels.first.behaviour, NodeBehaviour.steadyRelay);
      expect(labels.first.band, ConfidenceBand.high);
      expect(labels.first.evidence, contains(Evidence(EvidenceKind.hoursOnAir, hours.length, 48)));
      expect(labels.first.evidence.map((e) => e.kind), contains(EvidenceKind.externalPower));
    });

    test('a node reporting far-apart places is a roamer, not a relay', () {
      final now = _start.add(const Duration(days: 2));
      final hours = [for (var h = _hour(_start); h <= _hour(now); h++) h];
      final labels = NodeBehaviourClassifier.classify(
        _entry(last: now, hours: hours, days: 3, heard: 80,
            places: const [(lat: 45.0, lon: -122.0), (lat: 45.05, lon: -122.0), (lat: 45.1, lon: -122.0)]),
        now,
      );
      final kinds = labels.map((l) => l.behaviour);
      expect(kinds, contains(NodeBehaviour.roamer));
      expect(kinds, isNot(contains(NodeBehaviour.steadyRelay)));
      final roam = labels.firstWhere((l) => l.behaviour == NodeBehaviour.roamer);
      expect(roam.evidence.single.kind, EvidenceKind.placesSpread);
      expect(roam.evidence.single.a, 3);
      expect(roam.evidence.single.b, greaterThan(10000));
    });

    test('a node heard once, days ago, is rarely heard', () {
      final now = _start.add(const Duration(days: 6));
      final labels = NodeBehaviourClassifier.classify(
          _entry(hours: [_hour(_start)], heard: 2), now);
      expect(labels.single.behaviour, NodeBehaviour.rarelyHeard);
      expect(labels.single.evidence.single, Evidence(EvidenceKind.fewHours, 1, 6));
    });

    test('a node first heard today is a newcomer and nothing more', () {
      final now = _start.add(const Duration(hours: 5));
      final labels = NodeBehaviourClassifier.classify(
          _entry(last: now, hours: [_hour(_start), _hour(now)], heard: 9), now);
      expect(labels.single.behaviour, NodeBehaviour.newcomer);
      expect(labels.single.evidence.single, Evidence(EvidenceKind.firstHeardHoursAgo, 5));
    });

    test('a regular that stops being heard has gone quiet', () {
      final last = _start.add(const Duration(days: 5));
      final now = last.add(const Duration(days: 10));
      final labels = NodeBehaviourClassifier.classify(
          _entry(last: last, hours: [for (var i = 0; i < 20; i++) _hour(_start) + i * 6], days: 5, heard: 40),
          now);
      expect(labels.first.behaviour, NodeBehaviour.goneQuiet);
      expect(labels.first.evidence.first, Evidence(EvidenceKind.silentDays, 10));
    });

    test('mostly-internet nodes are marked as such', () {
      final now = _start.add(const Duration(hours: 2));
      final labels = NodeBehaviourClassifier.classify(
          _entry(last: now, hours: [_hour(_start)], heard: 20, internet: 19), now);
      expect(labels.map((l) => l.behaviour), contains(NodeBehaviour.internetLinked));
    });

    test('labels are deterministic and confidence stays below 1', () {
      final now = _start.add(const Duration(days: 9));
      final e = _entry(last: now.subtract(const Duration(hours: 3)),
          hours: [for (var i = 0; i < 30; i++) _hour(_start) + i * 7], days: 8, heard: 60);
      final a = NodeBehaviourClassifier.classify(e, now);
      final b = NodeBehaviourClassifier.classify(e, now);
      String describe(List<BehaviourLabel> x) => [for (final l in x) '${l.behaviour} ${l.confidence} ${l.evidence}'].join(';');
      expect(describe(a), describe(b));
      expect(a.map((l) => l.behaviour), contains(NodeBehaviour.regular));
      for (final l in a) {
        expect(l.confidence, inInclusiveRange(0, 0.99));
      }
    });
  });

  group('journal', () {
    test('logs every node heard, counts hours, days and places, and saves them', () async {
      var now = DateTime(2026, 11, 3, 9);
      final store = SharedPreferencesAsync();
      final journal = BastionNodeJournal(preferences: store, clock: () => now);
      const node = MeshtasticNode(num: 7, longName: 'Ridge', hopsAway: 0,
          latitude: 45.0001, longitude: -122.0001, batteryLevel: 101);
      await journal.observe(node);
      now = now.add(const Duration(minutes: 10));
      await journal.observe(node);
      now = now.add(const Duration(days: 1));
      await journal.observe(const MeshtasticNode(num: 7, hopsAway: 2, viaMqtt: true));
      now = now.add(const Duration(minutes: 1));
      await journal.observe(const MeshtasticNode(num: 9, shortName: 'X'));
      await journal.flush();

      final e = journal.entry(7)!;
      expect(e.name, 'Ridge', reason: 'a nameless update keeps the known name');
      expect(e.heard, 3);
      expect(e.hours, hasLength(2));
      expect(e.days, 2);
      expect(e.direct, 2);
      expect(e.internet, 1);
      expect(e.externalPower, 2);
      expect(e.places, [(lat: 45.0, lon: -122.0)]);
      expect(journal.entries.map((e) => e.num), [9, 7]);

      final reloaded = BastionNodeJournal(preferences: store);
      await reloaded.load();
      expect(reloaded.entry(7)!.toJson(), e.toJson());
      expect(reloaded.entry(9)!.displayName, '!00000009');
    });

    test('tags are trimmed, de-duplicated ignoring case, and notes are saved', () async {
      final store = SharedPreferencesAsync();
      final journal = BastionNodeJournal(preferences: store);
      expect(await journal.setTags(5, ['x']), isFalse, reason: 'unknown nodes cannot be tagged');
      await journal.observe(const MeshtasticNode(num: 5));
      expect(await journal.setTags(5, [' Hilltop ', 'hilltop', '', 'Solar']), isTrue);
      expect(await journal.setNote(5, '  Fire lookout  '), isTrue);
      expect(journal.entry(5)!.tags, ['Hilltop', 'Solar']);
      expect(journal.allTags, ['Hilltop', 'Solar']);
      final reloaded = BastionNodeJournal(preferences: store);
      await reloaded.load();
      expect(reloaded.entry(5)!.note, 'Fire lookout');
      expect(reloaded.entry(5)!.tags, ['Hilltop', 'Solar']);
    });

    test('old hours fall out of the window but days are kept', () async {
      var now = DateTime(2026, 10, 1, 12);
      final journal = BastionNodeJournal(clock: () => now);
      await journal.observe(const MeshtasticNode(num: 3));
      now = now.add(const Duration(days: 20));
      await journal.observe(const MeshtasticNode(num: 3));
      expect(journal.entry(3)!.hours, hasLength(1));
      expect(journal.entry(3)!.days, 2);
    });

    test('a damaged entry does not hide the others', () async {
      final store = SharedPreferencesAsync();
      await store.setString(BastionNodeJournal.storageKey,
          '[{"num":1},{"num":2,"first":1700000000,"last":1700000000}]');
      final journal = BastionNodeJournal(preferences: store);
      await journal.load();
      expect(journal.entries.map((e) => e.num), [2]);
    });
  });

  group('mark', () {
    test('the same node always gets the same mark, and neighbours differ', () {
      expect(NodeMarkSpec.of(0xDEADBEEF), NodeMarkSpec.of(0xDEADBEEF));
      expect(NodeMarkSpec.hash(0), 0x4b95f515, reason: 'FNV-1a must not change between versions');
      final specs = {for (var n = 0x1000; n < 0x1040; n++) NodeMarkSpec.of(n)};
      expect(specs.length, greaterThan(60));
      for (final s in specs) {
        expect(s.points, inInclusiveRange(3, 7));
        expect(s.stride, inInclusiveRange(1, s.points - 1));
      }
    });
  });

  group('pages', () {
    Future<BastionNodeJournal> seeded() async {
      final journal = BastionNodeJournal(clock: () => _start);
      await journal.observe(const MeshtasticNode(num: 0xA1, longName: 'Summit relay'));
      await journal.observe(const MeshtasticNode(num: 0xB2, longName: 'Pack mule'));
      await journal.setTags(0xB2, ['Team']);
      return journal;
    }

    Widget app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

    testWidgets('lists nodes with marks hidden from screen readers and filters by tag', (tester) async {
      final journal = await seeded();
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(app(NodeJournalPage(journal: journal, clock: () => _start)));
      await tester.pumpAndSettle();
      expect(find.text('Summit relay'), findsOneWidget);
      expect(find.byType(NodeMark), findsNWidgets(2));
      expect(find.descendant(of: find.byType(NodeMark), matching: find.byType(ExcludeSemantics)), findsNWidgets(2));
      expect(find.textContaining('Newcomer ·'), findsNWidgets(2));
      await tester.enterText(find.byType(TextField), 'team');
      await tester.pump();
      expect(find.text('Summit relay'), findsNothing);
      expect(find.text('Pack mule'), findsOneWidget);
      expect(find.text('Showing 1 of 2'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('a node page shows evidence and adds and removes tags', (tester) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final journal = await seeded();
      await tester.pumpWidget(app(JournalEntryPage(journal: journal, num: 0xA1, clock: () => _start)));
      await tester.pumpAndSettle();
      expect(find.text('Newcomer'), findsOneWidget);
      expect(find.text('High confidence'), findsOneWidget);
      expect(find.text('First heard 0 hours ago'), findsOneWidget);
      await tester.tap(find.widgetWithText(ActionChip, 'Team'));
      await tester.pumpAndSettle();
      expect(journal.entry(0xA1)!.tags, ['Team']);
      expect(find.byTooltip('Remove tag Team'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Add tag'), 'Solar');
      await tester.tap(find.byTooltip('Add tag'));
      await tester.pumpAndSettle();
      expect(journal.entry(0xA1)!.tags, ['Team', 'Solar']);
      await tester.tap(find.byTooltip('Remove tag Team'));
      await tester.pumpAndSettle();
      expect(journal.entry(0xA1)!.tags, ['Solar']);
    });

    testWidgets('the journal is translated', (tester) async {
      final journal = await seeded();
      await tester.pumpWidget(app(NodeJournalPage(journal: journal, clock: () => _start),
          locale: const Locale('es')));
      await tester.pumpAndSettle();
      expect(find.text('Diario de nodos'), findsWidgets);
      expect(find.textContaining('Recién llegado ·'), findsNWidgets(2));
      expect(find.text('Node journal'), findsNothing);
    });
  });
}
