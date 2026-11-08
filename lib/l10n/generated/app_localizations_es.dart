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

  @override
  String get toolsTitle => 'Herramientas';

  @override
  String get toolsSubtitle =>
      'Utilidades para planificar, probar y gestionar un despliegue.';

  @override
  String get toolsDoctor => 'Doctor de conexión';

  @override
  String get toolsDoctorSub =>
      'Averigua por qué una radio no conecta o se desconecta';

  @override
  String get toolsBeforeYouGo => 'Antes de salir';

  @override
  String get toolsChecklist => 'Lista de despliegue';

  @override
  String get toolsBattery => 'Autonomía de la batería';

  @override
  String get toolsBatterySub =>
      'Calcula las horas según la capacidad y el consumo medio';

  @override
  String get toolsCalculate => 'Calcular';

  @override
  String get toolsMeshTools => 'Herramientas de malla';

  @override
  String get toolsHealth => 'Estado de la malla y tiempo en el aire';

  @override
  String get toolsHealthSub =>
      'Cuánto se usa el canal y cuánto transmite tu radio';

  @override
  String get toolsLink => 'Planificador de enlaces';

  @override
  String get toolsLinkSub =>
      'Comprueba la línea de visión entre dos nodos según el terreno';

  @override
  String get toolsRange => 'Prueba de alcance';

  @override
  String get toolsRangeSub =>
      'Registra paquetes de un emisor de prueba con señal y distancia';

  @override
  String get toolsTraceroute => 'Traza de ruta';

  @override
  String get toolsStore => 'Almacenar y reenviar';

  @override
  String get toolsStoreSub =>
      'Recupera de un router los mensajes que te perdiste';

  @override
  String get toolsBeacons => 'Balizas de malla';

  @override
  String get toolsRecords => 'Registros';

  @override
  String get toolsIncident => 'Incidentes, plantillas y cobertura';

  @override
  String get toolsIncidentSub => 'Registros de campo guardados y exportaciones';

  @override
  String get toolsSignal => 'Señal';

  @override
  String get toolsTelemetry => 'Telemetría en directo';

  @override
  String get toolsNothingYet =>
      'Aún no se ha recibido nada. Los datos aparecen cuando los nodos los envían.';

  @override
  String get toolsGuide => 'Guía de señal Bluetooth';

  @override
  String get toolsGuideSub => 'Qué significan los valores de señal (RSSI)';

  @override
  String get toolsScan => 'Buscar radios';

  @override
  String get toolsCheck0 => 'Radio cargada';

  @override
  String get toolsCheck1 => 'Antena conectada';

  @override
  String get toolsCheck2 => 'Región configurada';

  @override
  String get toolsCheck3 => 'Canal principal verificado';

  @override
  String get toolsCheck4 => 'GPS y política de posición revisados';

  @override
  String toolsReady(int done, int total) {
    return '$done de $total listos';
  }

  @override
  String get toolsBatteryField => 'Batería (mAh)';

  @override
  String get toolsDrawField => 'Consumo medio (mA)';

  @override
  String toolsAboutHours(String hours) {
    return 'Unas $hours horas';
  }

  @override
  String get toolsTraceReady => 'Muestra la ruta de ida y vuelta hasta un nodo';

  @override
  String get toolsTraceOff => 'Conecta una radio para trazar rutas';

  @override
  String get toolsBeaconsSub =>
      'Escucha invitaciones de mallas cercanas y envía la tuya';

  @override
  String toolsBeaconsHeard(int count) {
    return '$count escuchadas • envía la tuya';
  }

  @override
  String toolsReporting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nodos envían datos del dispositivo',
      one: '$count nodo envía datos del dispositivo',
    );
    return '$_temp0';
  }

  @override
  String get toolsTelemetryOff => 'Conecta una radio para recibir telemetría';

  @override
  String toolsBatteryPct(int pct) {
    return 'Batería $pct%';
  }

  @override
  String toolsChannelBusy(String pct) {
    return 'Canal ocupado $pct%';
  }

  @override
  String toolsTransmitting(String pct) {
    return 'Transmitiendo $pct%';
  }

  @override
  String get toolsSigExcellent => 'Excelente, muy cerca';

  @override
  String get toolsSigStrong => 'Fuerte';

  @override
  String get toolsSigUsable => 'Utilizable';

  @override
  String get toolsSigWeak => 'Débil';

  @override
  String get toolsSigVeryWeak => 'Muy débil, puede cortarse';

  @override
  String get toolsScanning => 'Buscando…';

  @override
  String toolsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dispositivos Bluetooth encontrados',
      one: '$count dispositivo Bluetooth encontrado',
    );
    return '$_temp0';
  }
}
