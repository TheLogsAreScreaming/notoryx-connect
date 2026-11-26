import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A key used twice in an ARB file silently keeps only the last text, so a
/// screen shows another feature's words. Fail loudly instead.
void main() {
  for (final file in Directory('lib/l10n').listSync().whereType<File>().where((f) => f.path.endsWith('.arb'))) {
    test('${file.uri.pathSegments.last} has no key twice', () {
      final seen = <String>{};
      final twice = <String>[];
      final keyAtLineStart = RegExp(r'^  "([^"]+)":', multiLine: true);
      for (final m in keyAtLineStart.allMatches(file.readAsStringSync())) {
        if (!seen.add(m.group(1)!)) twice.add(m.group(1)!);
      }
      expect(twice, isEmpty, reason: 'Used more than once: ${twice.join(', ')}');
      // And it is still valid JSON.
      expect(() => jsonDecode(file.readAsStringSync()), returnsNormally);
    });
  }
}
