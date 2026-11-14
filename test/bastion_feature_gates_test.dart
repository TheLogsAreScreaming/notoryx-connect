import 'package:bastion/generated/meshtastic/admin.pbenum.dart';
import 'package:bastion/generated/meshtastic/config.pb.dart';
import 'package:bastion/generated/meshtastic/mesh.pb.dart' as pb;
import 'package:bastion/generated/meshtastic/mesh.pbenum.dart' as pbe;
import 'package:bastion/l10n/generated/app_localizations.dart';
import 'package:bastion/proto_form.dart';
import 'package:bastion/services/bastion_feature_gates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

pb.DeviceMetadata meta(String version,
        {int excluded = 0, bool bt = true, bool wifi = false, bool eth = false, bool pkc = true}) =>
    pb.DeviceMetadata(
      firmwareVersion: version,
      excludedModules: excluded,
      hasBluetooth: bt,
      hasWifi: wifi,
      hasEthernet: eth,
      hasPKC: pkc,
    );

void main() {
  group('gates', () {
    test('no device info yet means unknown, never unavailable', () {
      expect(BastionFeatureGates.module('MQTT_CONFIG', null).status, GateStatus.unknown);
      expect(BastionFeatureGates.config('BLUETOOTH_CONFIG', null).status, GateStatus.unknown);
      expect(BastionFeatureGates.pki(null).status, GateStatus.unknown);
    });

    test('a module the build left out is unavailable, whatever the version', () {
      final m = meta('2.8.2.abc', excluded: pbe.ExcludedModules.MQTT_CONFIG.value |
          pbe.ExcludedModules.TAK_CONFIG.value);
      expect(BastionFeatureGates.module('MQTT_CONFIG', m).reason, GateReason.excludedFromBuild);
      expect(BastionFeatureGates.module('TAK_CONFIG', m).unavailable, isTrue);
      expect(BastionFeatureGates.module('SERIAL_CONFIG', m).status, GateStatus.available);
    });

    test('hardware the radio lacks hides its settings', () {
      final noRadios = meta('2.7.15', bt: false);
      expect(BastionFeatureGates.config('BLUETOOTH_CONFIG', noRadios).reason, GateReason.noHardware);
      expect(BastionFeatureGates.config('NETWORK_CONFIG', noRadios).unavailable, isTrue);
      expect(BastionFeatureGates.config('NETWORK_CONFIG', meta('2.7.15', eth: true)).status,
          GateStatus.available);
      expect(BastionFeatureGates.config('LORA_CONFIG', noRadios).status, GateStatus.available);
    });

    test('PKI follows what the radio reports', () {
      expect(BastionFeatureGates.pki(meta('2.5.0', pkc: true)).status, GateStatus.available);
      expect(BastionFeatureGates.pki(meta('2.8.2', pkc: false)).unavailable, isTrue);
    });

    test('2.5, 2.7 and 2.8 radios are judged by what they report, not the number', () {
      for (final v in ['2.5.20.abc', '2.7.15.567b8ea', '2.8.2.d5f1619']) {
        final m = meta(v, excluded: pbe.ExcludedModules.PAXCOUNTER_CONFIG.value);
        expect(BastionFeatureGates.module('PAXCOUNTER_CONFIG', m).unavailable, isTrue, reason: v);
        expect(BastionFeatureGates.module('TELEMETRY_CONFIG', m).status, GateStatus.available, reason: v);
      }
    });

    test('every module settings type with an exclusion bit is matched by name', () {
      final bits = {for (final b in pbe.ExcludedModules.values) b.name};
      final matched = [
        for (final t in AdminMessage_ModuleConfigType.values)
          if (bits.contains(t.name)) t.name,
      ];
      // If the schema renames one side, this catches it.
      expect(matched, containsAll(['MQTT_CONFIG', 'SERIAL_CONFIG', 'TAK_CONFIG', 'TELEMETRY_CONFIG']));
      for (final name in matched) {
        final bit = pbe.ExcludedModules.values.firstWhere((b) => b.name == name).value;
        expect(BastionFeatureGates.module(name, meta('2.8.2', excluded: bit)).unavailable, isTrue,
            reason: name);
      }
    });
  });

  group('settings form', () {
    // Config_DeviceConfig.role (field 1) set to 99: a role this build doesn't know.
    Config_DeviceConfig fromNewerFirmware() => Config_DeviceConfig.fromBuffer([0x08, 99]);

    testWidgets('shows a value from newer firmware instead of the default', (tester) async {
      final message = fromNewerFirmware();
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SingleChildScrollView(child: ProtoFieldList(
          message: message,
          writable: () => message,
          changed: () {},
        ))),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('proto-newer-1')), findsOneWidget);
      expect(find.textContaining('value 99'), findsOneWidget);
    });

    test('an untouched unknown value is written back unchanged', () {
      final copy = fromNewerFirmware().deepCopy();
      expect(Config_DeviceConfig.fromBuffer(copy.writeToBuffer()).unknownFields.hasField(1), isTrue);
      expect(copy.writeToBuffer(), containsAllInOrder([0x08, 99]));
    });
  });
}
