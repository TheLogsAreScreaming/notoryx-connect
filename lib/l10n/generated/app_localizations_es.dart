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

  @override
  String get deliveryReceived => 'Recibido';

  @override
  String get deliveryQueued => 'En cola';

  @override
  String get deliverySent => 'Enviado';

  @override
  String get deliveryDelivered => 'Entregado';

  @override
  String get deliveryFailed => 'No entregado';

  @override
  String get hopsDirect => 'Directo';

  @override
  String hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saltos',
      one: '$count salto',
    );
    return '$_temp0';
  }

  @override
  String get chatsNoMention =>
      'Aún no se ha escuchado ningún nodo para mencionar.';

  @override
  String get chatsMentionNode => 'Mencionar un nodo';

  @override
  String get chatsViaMqttFull => 'Llegó por MQTT (internet), no por radio';

  @override
  String get chatsPathUnknown => 'El firmware del remitente no indicó la ruta';

  @override
  String get chatsHeardDirect => 'Escuchado directamente, sin repetidores';

  @override
  String chatsLastThrough(String name) {
    return ', por último a través de $name';
  }

  @override
  String chatsLastThroughEnding(String hex) {
    return ', por último a través de un nodo que termina en $hex';
  }

  @override
  String chatsCameThrough(int hops, String via) {
    String _temp0 = intl.Intl.pluralLogic(
      hops,
      locale: localeName,
      other: 'Llegó a través de $hops repetidores$via',
      one: 'Llegó a través de $hops repetidor$via',
    );
    return '$_temp0';
  }

  @override
  String get chatsReact => 'Reaccionar';

  @override
  String chatsReactEmoji(String emoji) {
    return 'Reaccionar $emoji';
  }

  @override
  String get chatsNoSignal => 'Sin lectura de señal';

  @override
  String get chatsUnpin => 'Desfijar';

  @override
  String get chatsPin => 'Fijar';

  @override
  String get chatsCopyText => 'Copiar texto';

  @override
  String get chatsCopied => 'Mensaje copiado';

  @override
  String chatsReactionFailed(String error) {
    return 'Reacción no enviada: $error';
  }

  @override
  String chatsSendFailed(String error) {
    return 'Mensaje no enviado: $error';
  }

  @override
  String get chatsYou => 'Tú';

  @override
  String get chatsYouLower => 'ti';

  @override
  String chatsChannelN(int n) {
    return 'Canal $n';
  }

  @override
  String get chatsReactHint => 'reaccionar a este mensaje';

  @override
  String get chatsViaMqtt => 'vía MQTT';

  @override
  String get chatsPinned => 'Fijados';

  @override
  String get chatsMentionsYou => 'Te menciona';

  @override
  String chatsReactions(String list) {
    return 'Reacciones: $list';
  }

  @override
  String chatsReactionFrom(String emoji, String name) {
    return '$emoji de $name';
  }

  @override
  String get chatsConnectedSub =>
      'Conectado. Los mensajes se envían al momento.';

  @override
  String get chatsOfflineSub =>
      'Sin conexión. Los mensajes esperan en cola y se envían cuando la radio se conecte.';

  @override
  String get chatsStorageProblem => 'Problema al guardar mensajes';

  @override
  String get chatsFilterShowing =>
      'Mostrando los mensajes que coinciden con tus filtros de palabras';

  @override
  String chatsFilterHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mensajes ocultos por tus filtros de palabras',
      one: '$count mensaje oculto por tus filtros de palabras',
    );
    return '$_temp0';
  }

  @override
  String get chatsHide => 'Ocultar';

  @override
  String get chatsShow => 'Mostrar';

  @override
  String get chatsStatLink => 'Enlace';

  @override
  String get chatsOnline => 'En línea';

  @override
  String get chatsStatMessages => 'Mensajes';

  @override
  String get chatsStatQueued => 'En cola';

  @override
  String get chatsNewMessage => 'Mensaje nuevo';

  @override
  String get chatsKeyChanged => 'La clave de seguridad cambió';

  @override
  String chatsKeyChangedBody(String name) {
    return '$name muestra ahora una clave distinta. Confírmalo con su propietario antes de enviar algo privado. Abre el nodo para revisar o aceptar la clave nueva.';
  }

  @override
  String get chatsTo => 'Para';

  @override
  String get chatsEveryone => 'Todos en el canal';

  @override
  String chatsDirect(String name) {
    return 'Directo • $name';
  }

  @override
  String get chatsChannelLabel => 'Canal';

  @override
  String get chatsChannelBroadcast => 'Canal 0 • Difusión';

  @override
  String chatsChannelOffline(int n) {
    return 'Canal $n • Sin conexión';
  }

  @override
  String chatsChannelNamed(int n, String name) {
    return 'Canal $n • $name';
  }

  @override
  String get chatsDefault => 'Predeterminado';

  @override
  String chatsMessageChannel(int n) {
    return 'Mensaje al canal $n';
  }

  @override
  String chatsMessageNode(String name) {
    return 'Mensaje para $name';
  }

  @override
  String get chatsSend => 'Enviar';

  @override
  String get chatsQuickReplies => 'Respuestas rápidas';

  @override
  String get chatsMessages => 'Mensajes';

  @override
  String get chatsHoldHint => 'Mantén pulsado un mensaje para ver más';

  @override
  String get chatsSearch => 'Buscar en el historial';

  @override
  String get chatsClearSearch => 'Borrar búsqueda';

  @override
  String get chatsNoMatches => 'Sin resultados';

  @override
  String get chatsNoMatchesBody => 'Ningún mensaje coincide con tu búsqueda.';

  @override
  String get chatsEmpty => 'Aún no hay mensajes de la malla';

  @override
  String get chatsEmptyBody =>
      'Los mensajes de canal y directos aparecen aquí cuando tu radio los escucha.';

  @override
  String get chatsNewAbove => 'Mensajes nuevos arriba';

  @override
  String get chatsAutoReplies => 'Respuestas automáticas';

  @override
  String get chatsBot => 'Modo bot';

  @override
  String get chatsBotOn =>
      'Activado. Responde a mensajes directos y a !help y !status, respetando las horas de silencio y los límites de tiempo en el aire.';

  @override
  String get chatsBotOff => 'Desactivado. No se envían respuestas automáticas.';

  @override
  String get chatsBotReply => 'Mensaje de respuesta del bot';

  @override
  String get chatsBotReplyField =>
      'Mensaje que se envía con el modo bot activado';
}
