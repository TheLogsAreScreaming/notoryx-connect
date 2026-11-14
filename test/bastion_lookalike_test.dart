import 'package:bastion/services/bastion_lookalike.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('folds case, symbols and look-alike letters', () {
    expect(BastionLookalike.fold('Base Camp-1'), 'basecampl');
    expect(BastionLookalike.fold('Ваsе Саmр'), 'basecamp'); // Cyrillic В, а, е, С, р
    expect(BastionLookalike.fold('B0B'), 'bob');
  });

  test('flags same name, homoglyphs and one-character changes', () {
    expect(BastionLookalike.looksLike('Base Camp', 'base camp'), isTrue);
    expect(BastionLookalike.looksLike('Bаse Camp', 'Base Camp'), isTrue);
    expect(BastionLookalike.looksLike('Base Canp', 'Base Camp'), isTrue);
    expect(BastionLookalike.looksLike('Base Camps', 'Base Camp'), isTrue);
    expect(BastionLookalike.looksLike('rnike', 'mike'), isTrue);
  });

  test('leaves different and short names alone', () {
    expect(BastionLookalike.looksLike('Ridge Relay', 'Base Camp'), isFalse);
    expect(BastionLookalike.looksLike('Tom', 'Tim'), isFalse);
    expect(BastionLookalike.looksLike('', 'Base'), isFalse);
    expect(BastionLookalike.looksLike('Base Camp 2', 'Base Camp'), isFalse);
  });

  test('finds whom a node imitates, never itself', () {
    const trusted = {1: 'Sam Ortiz', 2: 'Base Camp'};
    expect(BastionLookalike.imitates(9, 'Sam 0rtiz', trusted), 1);
    expect(BastionLookalike.imitates(2, 'Base Camp', trusted), isNull);
    expect(BastionLookalike.imitates(9, 'Weather bot', trusted), isNull);
  });
}
