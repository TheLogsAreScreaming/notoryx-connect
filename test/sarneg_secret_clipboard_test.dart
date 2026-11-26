// The SARNEG clipboard is cleared after a minute even when the app can't
// read it, but text the person copied since is left alone.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bastion/sarneg/secret_clipboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// What the fake clipboard holds; [readable] false acts like Android 10+
  /// with the app in the background, where reads come back empty.
  String? clip;
  var readable = true;

  setUp(() {
    clip = null;
    readable = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clip = (call.arguments as Map)['text'] as String?;
          } else if (call.method == 'Clipboard.getData') {
            return readable ? <String, dynamic>{'text': clip} : null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('our text still on the clipboard is cleared', () async {
    await copySecretText('[SARNEG] LRs KSAC');
    await clearClipboardIfStill('[SARNEG] LRs KSAC');
    expect(clip, '');
  });

  test('text copied since is left alone', () async {
    await copySecretText('[SARNEG] LRs KSAC');
    clip = 'meet at the trailhead';
    await clearClipboardIfStill('[SARNEG] LRs KSAC');
    expect(clip, 'meet at the trailhead');
  });

  test('a clipboard the app cannot read is cleared anyway', () async {
    await copySecretText('[SARNEG] LRs KSAC');
    readable = false;
    await clearClipboardIfStill('[SARNEG] LRs KSAC');
    expect(clip, '');
  });

  group('on Android', () {
    final calls = <String>[];
    setUp(() {
      calls.clear();
      debugSecretClipboardAndroid = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('notoryx/clipboard'), (call) async {
        calls.add('${call.method}:${call.method == 'copySensitive' ? 'text' : call.arguments}');
        if (call.method == 'copySensitive') clip = call.arguments as String;
        if (call.method == 'clear') clip = '';
        return null;
      });
    });
    tearDown(() {
      debugSecretClipboardAndroid = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('notoryx/clipboard'), null);
    });

    test('a system clear is scheduled, so it survives the app being killed', () async {
      await copySecretText('[SARNEG] FETH');
      expect(await scheduleClipboardClear(const Duration(minutes: 1)), isTrue);
      expect(calls, ['copySensitive:text', 'scheduleClear:60000']);
    });

    test('text copied since keeps the system clear from wiping it', () async {
      await copySecretText('[SARNEG] FETH');
      clip = 'meet at the trailhead';
      await clearClipboardIfStill('[SARNEG] FETH');
      expect(clip, 'meet at the trailhead');
      expect(calls.last, 'cancelClear:null');
    });

    test('our text, or a clipboard that cannot be read, is cleared natively', () async {
      await copySecretText('[SARNEG] FETH');
      readable = false;
      await clearClipboardIfStill('[SARNEG] FETH');
      expect(calls.last, 'clear:null');
      expect(clip, '');
    });
  });
}
