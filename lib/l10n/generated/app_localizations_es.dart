// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabNodes => 'Nodos';

  @override
  String get tabChats => 'Chats';

  @override
  String get tabMap => 'Mapa';

  @override
  String get tabTools => 'Herramientas';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String get connOffline => 'Sin conexión';

  @override
  String get connScanning => 'Buscando';

  @override
  String get connConnecting => 'Conectando';

  @override
  String get connSyncing => 'Sincronizando';

  @override
  String get connConnected => 'Conectado';

  @override
  String get connError => 'Error';

  @override
  String radioStatus(String status) {
    return 'Radio: $status';
  }

  @override
  String radioStatusTip(String status) {
    return 'Radio: $status. Toca para gestionar.';
  }

  @override
  String get radioStatusHint => 'gestionar la radio';
}
