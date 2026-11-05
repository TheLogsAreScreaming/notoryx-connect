import 'package:bastion/services/bastion_hardware.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('known boards get their maker name', () {
    expect(BastionHardware.name(71), 'Seeed T1000-E');
    expect(BastionHardware.name(4), 'LilyGO T-Beam');
    expect(BastionHardware.name(146), 'Seeed MeshPager X2');
  });

  test('boards added in protobufs 2.8.2 have names', () {
    expect(BastionHardware.name(151), 'Radioddity Nodara');
    expect(BastionHardware.name(152), 'Heltec MeshPocket V2');
  });

  test('other boards fall back to the enum name', () {
    expect(BastionHardware.name(43), 'Heltec V3');
    expect(BastionHardware.name(255), 'Custom hardware');
  });

  test('a number newer than the definitions stays a number', () {
    expect(BastionHardware.name(9999), 'Model 9999');
  });
}
