import 'package:bastion/services/bastion_node_groups.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 11, 17, 12);

MeshtasticNode node(int num, String name, {Duration? ago, String? short}) =>
    MeshtasticNode(num: num, longName: name, shortName: short, lastHeard: ago == null ? null : now.subtract(ago));

void main() {
  final nodes = [
    node(1, 'My radio', ago: Duration.zero),
    node(2, 'Rav4 KC1TCD', ago: const Duration(minutes: 2), short: 'RV'),
    node(3, 'Xitiomet Router', ago: const Duration(minutes: 50)),
    node(4, 'Meshxor', ago: const Duration(hours: 3)),
    node(5, 'Old timer', ago: const Duration(days: 3)),
    node(6, 'Never heard'),
  ];

  test('nodes are grouped by when they were heard, newest first, without your own radio', () {
    final g = BastionNodeGroups.of(nodes, now: now, localNum: 1);
    expect([for (final n in g.active) n.num], [2, 3]);
    expect([for (final n in g.today) n.num], [4]);
    expect([for (final n in g.older) n.num], [5, 6], reason: 'never heard goes last');
    expect(g.total, 5);
  });

  test('search matches name, short name or node ID, ignoring case', () {
    expect([for (final n in BastionNodeGroups.of(nodes, now: now, query: 'mesh').today) n.num], [4]);
    expect(BastionNodeGroups.of(nodes, now: now, query: 'rv').active.single.num, 2);
    expect(BastionNodeGroups.of(nodes, now: now, query: '00000005').older.single.num, 5);
    expect(BastionNodeGroups.of(nodes, now: now, query: 'nothing like this').total, 0);
  });

  test('favorites only keeps favorites', () {
    final g = BastionNodeGroups.of(nodes, now: now, favoritesOnly: true, favorites: {4, 6});
    expect([...g.active, ...g.today, ...g.older].map((n) => n.num), [4, 6]);
  });

  test('signal bars from SNR', () {
    expect(BastionNodeGroups.bars(null), isNull);
    expect(BastionNodeGroups.bars(8), 3);
    expect(BastionNodeGroups.bars(0), 2);
    expect(BastionNodeGroups.bars(-10), 1);
    expect(BastionNodeGroups.bars(-17), 0);
  });
}
