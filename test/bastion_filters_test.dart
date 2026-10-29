import 'package:bastion/main.dart';
import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/bastion_filters.dart';
import 'package:bastion/services/bastion_message_archive.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class FlakyStore extends InMemorySharedPreferencesAsync {
  FlakyStore() : super.empty();
  bool failReads = false;
  int writes = 0;
  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) async {
    if (failReads) throw StateError('read failed');
    return super.getString(key, options);
  }
  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) async {
    writes++;
    return super.setString(key, value, options);
  }
}

BastionChatMessage msg(int id, int from, String text, {bool outgoing = false}) => BastionChatMessage(
    packetId: id, from: from, to: 0xffffffff, channel: 0, text: text,
    timestamp: DateTime.utc(2026, 10, 29, 12, id),
    direction: outgoing ? BastionMessageDirection.outgoing : BastionMessageDirection.incoming,
    deliveryState: BastionDeliveryState.delivered);

void main() {
  late FlakyStore store;
  setUp(() {
    store = FlakyStore();
    SharedPreferencesAsyncPlatform.instance = store;
  });

  test('word filters match whole words in any case, including phrases and accents', () async {
    final f = BastionFilters();
    await f.load();
    expect(await f.addWord('spam'), isNull);
    expect(await f.addWord('buy now'), isNull);
    expect(await f.addWord('café'), isNull);
    expect(f.matchesWord('This is SPAM!'), isTrue);
    expect(f.matchesWord('spammer here'), isFalse, reason: 'whole words only');
    expect(f.matchesWord('please Buy Now'), isTrue);
    expect(f.matchesWord('meet at the café'), isTrue);
    expect(f.matchesWord('all clear'), isFalse);
    expect(await f.addWord(' SPAM '), 'That word is already filtered.');
    expect(await f.addWord('  '), 'Enter a word or phrase.');
  });

  test('choices are saved and restored', () async {
    final f = BastionFilters();
    await f.load();
    await f.setIgnored(7, true);
    await f.setMuted(8, true);
    await f.addWord('spam');
    await f.setShowFiltered(true);
    final g = BastionFilters();
    await g.load();
    expect(g.isIgnored(7), isTrue);
    expect(g.isSilenced(8), isTrue);
    expect(g.isIgnored(8), isFalse, reason: 'muted is not ignored');
    expect(g.words, ['spam']);
    expect(g.showFiltered, isTrue);
  });

  test('unreadable storage is never overwritten', () async {
    store.failReads = true;
    final f = BastionFilters();
    await f.load();
    await f.setIgnored(7, true);
    expect(f.isIgnored(7), isTrue, reason: 'still applies this session');
    expect(store.writes, 0);
    expect(f.problem, isNotNull);
  });

  test('the coordinator hides ignored and filtered messages, but trip safety sees all', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await BastionMessageArchive().save(messages: [
      msg(1, 7, 'hello from 7'),
      msg(2, 9, 'cheap SPAM offer'),
      msg(3, 9, 'all clear'),
      msg(4, 1, 'my own spam', outgoing: true),
    ], pending: []);
    final radio = MeshtasticRadioCoordinator();
    addTearDown(radio.dispose);
    await pumpEventQueue();
    await radio.filters.setIgnored(7, true);
    await radio.filters.addWord('spam');
    expect([for (final m in radio.messages) m.packetId], [3, 4], reason: 'own messages are never hidden');
    expect(radio.filteredMessageCount, 1);
    expect(radio.allMessages, hasLength(4));
    await radio.filters.setShowFiltered(true);
    expect([for (final m in radio.messages) m.packetId], [2, 3, 4], reason: 'ignored stays hidden');
  });

  testWidgets('Settings lets you add and remove filtered words', (tester) async {
    await tester.pumpWidget(const BastionApp());
    await tester.tap(find.byIcon(Icons.settings_outlined).last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Filters'), 250, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Word or phrase'), 'spam');
    await tester.tap(find.byTooltip('Add filtered word'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(InputChip, 'spam'), findsOneWidget);
    expect((await SharedPreferencesAsync().getString(BastionFilters.key)), contains('spam'));
  });
}
