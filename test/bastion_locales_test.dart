import 'dart:io';

import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS and macOS are told about every translated language', () {
    final codes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
    expect(codes, containsAll(['en', 'es', 'fr', 'de']));
    for (final script in ['scripts/prepare_ios.py', 'scripts/prepare_macos.py']) {
      final line = File(script).readAsLinesSync().firstWhere((l) => l.contains('CFBundleLocalizations'));
      final listed = RegExp(r"'([a-z]{2})'").allMatches(line).map((m) => m.group(1)).toSet();
      expect(listed, codes, reason: script);
    }
  });
}
