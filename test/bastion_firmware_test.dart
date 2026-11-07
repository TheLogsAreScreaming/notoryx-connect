import 'package:bastion/services/bastion_firmware.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('versions parse with or without a build suffix', () {
    expect(BastionFirmware.parse('2.7.15.567b8ea'), (2, 7, 15));
    expect(BastionFirmware.parse('v2.5'), (2, 5, 0));
    expect(BastionFirmware.parse('unknown'), isNull);
    expect(BastionFirmware.parse(null), isNull);
  });

  test('support levels follow the minimum and recommended versions', () {
    expect(BastionFirmware.supportOf('2.3.2.abc'), FirmwareSupport.unsupported);
    expect(BastionFirmware.supportOf('2.4.99'), FirmwareSupport.unsupported);
    expect(BastionFirmware.supportOf('2.5.0'), FirmwareSupport.outdated);
    expect(BastionFirmware.supportOf('2.6.11.60ec05e'), FirmwareSupport.outdated);
    expect(BastionFirmware.supportOf('2.7.0'), FirmwareSupport.supported);
    expect(BastionFirmware.supportOf('2.8.2.abcdef'), FirmwareSupport.supported);
    expect(BastionFirmware.supportOf('3.0.0'), FirmwareSupport.supported);
    expect(BastionFirmware.supportOf(null), FirmwareSupport.unknown);
  });

  test('advice names the version and where to update, only when needed', () {
    expect(BastionFirmware.advice('2.3.2.abc'), allOf(contains('2.3.2'), contains('read-only'),
        contains(BastionFirmware.flasher)));
    expect(BastionFirmware.advice('2.6.1'), contains('2.7 or newer'));
    expect(BastionFirmware.advice('2.8.2'), isNull);
    expect(BastionFirmware.advice(null), isNull);
  });
}
