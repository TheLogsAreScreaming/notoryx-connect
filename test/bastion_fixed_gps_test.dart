// ignore_for_file: deprecated_member_use_from_same_package
import 'package:bastion/generated/meshtastic/config.pb.dart';
import 'package:bastion/generated/meshtastic/config.pbjson.dart';
import 'package:bastion/generated/meshtastic/mesh.pbjson.dart';
import 'package:bastion/proto_form.dart';
import 'package:bastion/services/bastion_hardware.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fixed-GPS boards match the boards carrying options in the definitions', () {
    // Only oem_fixed_gps is set on HardwareModel values; protoc keeps an
    // empty options map ('3') on exactly those values.
    final flagged = {
      for (final v in (HardwareModel$json['2']! as List).cast<Map<String, Object?>>())
        if (v.containsKey('3')) v['2']! as int,
    };
    expect(BastionHardware.fixedGps, flagged);
  });

  test('DIY GPS fields are the GPS pin numbers', () {
    final position = (Config$json['3']! as List)
        .cast<Map<String, Object?>>()
        .firstWhere((m) => m['1'] == 'PositionConfig');
    final byTag = {
      for (final f in (position['2']! as List).cast<Map<String, Object?>>())
        f['3']! as int: f['1']! as String,
    };
    expect({for (final t in BastionHardware.diyGpsFields) byTag[t]},
        {'rx_gpio', 'tx_gpio', 'gps_en_gpio'});
  });

  test('unknown boards keep their GPS pins', () {
    expect(BastionHardware.hasFixedGps(71), isTrue);
    expect(BastionHardware.hasFixedGps(43), isFalse);
    expect(BastionHardware.hasFixedGps(null), isFalse);
  });

  testWidgets('hidden fields are not shown and keep their values', (tester) async {
    final draft = Config_PositionConfig(rxGpio: 34, txGpio: 12, gpsEnGpio: 4);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: ProtoFieldList(
        message: draft,
        writable: () => draft,
        changed: () {},
        hiddenFields: BastionHardware.diyGpsFields,
        notice: 'GPS pins are hidden',
      ),
    ))));
    expect(find.text('GPS pins are hidden'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Rx gpio'), findsNothing);
    expect(find.widgetWithText(TextField, 'Tx gpio'), findsNothing);
    expect(find.widgetWithText(TextField, 'Gps en gpio'), findsNothing);
    expect(find.widgetWithText(TextField, 'Position broadcast secs'), findsOneWidget);
    expect([draft.rxGpio, draft.txGpio, draft.gpsEnGpio], [34, 12, 4]);
  });

  testWidgets('without hidden fields the GPS pins are shown', (tester) async {
    final draft = Config_PositionConfig();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: ProtoFieldList(message: draft, writable: () => draft, changed: () {}),
    ))));
    expect(find.widgetWithText(TextField, 'Rx gpio'), findsOneWidget);
  });
}
