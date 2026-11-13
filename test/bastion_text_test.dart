import 'package:bastion/l10n/bastion_text.dart';
import 'package:bastion/services/bastion_chat_marks.dart';
import 'package:bastion/services/bastion_connection_doctor.dart';
import 'package:bastion/services/bastion_trip_readiness.dart';
import 'package:bastion/services/meshtastic_connection_controller.dart';
import 'package:bastion/services/bastion_firmware.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  tearDown(() => BastionText.use(const Locale('en')));
  final now = DateTime(2026, 11, 12, 12);

  test('services speak English by default', () {
    expect(BastionChatDays.label(now, now), 'Today');
    expect(BastionChatDays.label(now.subtract(const Duration(days: 1)), now), 'Yesterday');
    expect(BastionChatDays.label(DateTime(2026, 11, 9), now), 'Monday');
    expect(BastionChatDays.label(DateTime(2026, 3, 5), now), 'Mar 5');
    expect(BastionChatDays.label(DateTime(2025, 3, 5), now), 'Mar 5, 2025');
  });

  test('services follow the phone language', () async {
    await initializeDateFormatting('es');
    BastionText.use(const Locale('es'));
    expect(BastionChatDays.label(now, now), 'Hoy');
    expect(BastionChatDays.label(now.subtract(const Duration(days: 1)), now), 'Ayer');
    expect(BastionChatDays.label(DateTime(2026, 11, 9), now), 'lunes');
    expect(BastionFirmware.advice('2.3.0'), contains('Tu radio tiene el firmware'));
  });

  test('Connection doctor and Trip readiness follow the phone language', () {
    BastionText.use(const Locale('es'));
    final checks = BastionConnectionDoctor.diagnose(
      const DoctorFacts(
        state: MeshtasticConnectionState.ready,
        link: DoctorLink.bluetooth,
        radioName: 'T1000',
        bluetoothOn: false,
        permissionsGranted: true,
      ),
    );
    expect(checks.first.title, 'Bluetooth');
    expect(checks.first.detail, 'El Bluetooth está apagado.');
    expect(checks.first.fix.label, 'Activar Bluetooth');
    expect(checks.firstWhere((c) => c.id == 'link').detail, 'Conectado a T1000.');
    final items = BastionTripReadiness.check(ReadinessFacts(radioReady: true, now: now, batteryPercent: 101));
    expect(items.firstWhere((i) => i.id == 'battery').title, 'Batería de la radio');
  });

  test('an unsupported language falls back to English', () {
    BastionText.use(const Locale('xx'));
    expect(BastionChatDays.label(now, now), 'Today');
  });
}
