import 'package:bastion/services/bastion_plus_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('matches published Open Location Code values', () {
    expect(BastionPlusCode.encode(47.365590, 8.524997), '8FVC9G8F+6X');
    expect(BastionPlusCode.encode(20.3700625, 2.7821875), '7FG49QCJ+2V');
  });

  test('handles the poles and the date line', () {
    expect(BastionPlusCode.encode(90, 0), startsWith('CFX'));
    expect(BastionPlusCode.encode(0, 180), BastionPlusCode.encode(0, -180));
  });

  test('is 11 bytes', () => expect(BastionPlusCode.encode(35.2, -80.8).length, 11));
}
