import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('both iPhone builds replace the blank Flutter icon with the NOTORYX one', () {
    final config = File('tool/ios_launcher_icons.yaml').readAsStringSync();
    expect(config, contains('ios: true'));
    expect(config, contains('remove_alpha_ios: true'));
    final image = RegExp(r'image_path:\s*(\S+)').firstMatch(config)!.group(1)!;
    expect(File(image).existsSync(), isTrue, reason: image);
    for (final workflow in ['ios-build.yml', 'ios-testflight.yml']) {
      expect(
        File('.github/workflows/$workflow').readAsStringSync(),
        contains('flutter_launcher_icons -f tool/ios_launcher_icons.yaml'),
        reason: workflow,
      );
    }
  });
}
