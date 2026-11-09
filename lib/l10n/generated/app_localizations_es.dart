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

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonConnect => 'Conectar';

  @override
  String get commonDisconnect => 'Desconectar';

  @override
  String get agoNow => 'ahora mismo';

  @override
  String agoMin(int n) {
    return 'hace $n min';
  }

  @override
  String agoHours(int n) {
    return 'hace $n h';
  }

  @override
  String agoDays(int n) {
    return 'hace $n d';
  }

  @override
  String get rssiStrong => 'Señal Bluetooth fuerte';

  @override
  String get rssiUsable => 'Señal Bluetooth utilizable';

  @override
  String get rssiWeak => 'Señal Bluetooth débil';

  @override
  String get rssiVeryWeak => 'Señal Bluetooth muy débil';

  @override
  String get heardAny => 'Cualquier momento';

  @override
  String get heardHour => '1 hora';

  @override
  String get heardDay => '24 horas';

  @override
  String get heardWeek => '7 días';

  @override
  String nodesConnectFailed(String error) {
    return 'No se pudo conectar: $error';
  }

  @override
  String nodesUsbFailed(String error) {
    return 'No se pudo conectar por USB: $error';
  }

  @override
  String nodesNotesFor(String name) {
    return 'Notas de $name';
  }

  @override
  String get nodesNotesHint => 'Ubicación, antena, observaciones…';

  @override
  String nodesConnectedTo(String name) {
    return 'Conectado a $name.';
  }

  @override
  String get nodesYourRadio => 'tu radio';

  @override
  String get nodesFindRadio =>
      'Busca tu radio cerca y conéctate por Bluetooth.';

  @override
  String get nodesRadiosFound => 'Radios encontradas';

  @override
  String get nodesMeshNodes => 'Nodos de la malla';

  @override
  String get nodesStatus => 'Estado';

  @override
  String get nodesConnProblem => 'Problema de conexión';

  @override
  String get nodesDiagnose => 'Diagnosticar';

  @override
  String get nodesNearby => 'Radios cercanas';

  @override
  String get nodesLooking => 'Buscando radios…';

  @override
  String get nodesStopScan => 'Detener búsqueda';

  @override
  String get nodesRadio => 'Radio';

  @override
  String get nodesOverUsb => 'Por USB';

  @override
  String get nodesOverWifi => 'Por Wi-Fi';

  @override
  String get nodesConnectWifi => 'Conectar por Wi-Fi';

  @override
  String get nodesConnectUsb => 'Conectar por USB';

  @override
  String get nodesNoRadios => 'Aún no se han encontrado radios';

  @override
  String get nodesNoRadiosBody =>
      'Enciende la radio, mantenla cerca y toca Buscar radios.';

  @override
  String get nodesTryDemo => '¿Sin radio? Prueba la demostración';

  @override
  String get nodesMeshtasticRadio => 'Radio Meshtastic';

  @override
  String get nodesBluetoothDevice => 'Dispositivo Bluetooth';

  @override
  String nodesCount(int count) {
    return 'Nodos de la malla ($count)';
  }

  @override
  String nodesCountOf(int shown, int total) {
    return 'Nodos de la malla ($shown de $total)';
  }

  @override
  String nodesNoneHeard(String window) {
    return 'Ningún nodo escuchado en: $window';
  }

  @override
  String get nodesPickLonger =>
      'Elige un periodo más largo para ver nodos anteriores.';

  @override
  String get nodesShowAll => 'Mostrar todos los nodos';

  @override
  String get nodesHealth => 'Estado de la malla';

  @override
  String get nodesDetails => 'Detalles';

  @override
  String get nodesKnown => 'Nodos conocidos';

  @override
  String get nodesWaiting => 'Pendientes de envío';

  @override
  String get nodesSignalQuality => 'Calidad de la señal';

  @override
  String nodesSignalSummary(int count, String snr) {
    return '$count mensajes escuchados • última relación señal/ruido: $snr';
  }

  @override
  String get nodesNotMeasured => 'aún sin medir';

  @override
  String nodesSignalHistory(int count) {
    return 'Historial de señal de los últimos $count mensajes';
  }

  @override
  String get nodesSignalStarts =>
      'El historial de señal empieza cuando otro nodo envía un mensaje.';

  @override
  String get nodesMeasuredFrom =>
      'Medido solo con los mensajes de texto recibidos.';

  @override
  String get nodesEncounters => 'Encuentros guardados';

  @override
  String nodesSeen(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Visto $count veces • última: $when',
      one: 'Visto $count vez • última: $when',
    );
    return '$_temp0';
  }

  @override
  String get nodesTapNotes => 'Toca para añadir notas';

  @override
  String get nodesRemoveFav => 'Quitar de favoritos';

  @override
  String get nodesAddFav => 'Añadir a favoritos';

  @override
  String get nodesMore => 'Más';

  @override
  String get nodesFieldTools => 'Herramientas de campo';

  @override
  String get nodesFieldToolsSub =>
      'Referencia de señal, listas, copias de seguridad y más';

  @override
  String get nodesReadyBanner =>
      'Tu radio está conectada. Los nodos se actualizan en directo al escucharlos.';

  @override
  String get nodesHelpBanner =>
      'Toca Buscar radios y luego Conectar. La aplicación comprueba que sea una radio Meshtastic y descarga su lista de nodos antes de estar lista.';

  @override
  String get nodesHeardWithin => 'Mostrar nodos escuchados en';

  @override
  String get nodesWifiHelp =>
      'Para radios con Wi-Fi o Ethernet activado. El teléfono debe estar en la misma red.';

  @override
  String get nodesAddress => 'Dirección de la radio';

  @override
  String get nodesAddressHint => 'p. ej., 192.168.1.42 o meshtastic.local';

  @override
  String get nodesPort => 'Puerto';

  @override
  String get nodesPortHelp => 'Meshtastic usa el 4403';

  @override
  String get nodesUsbHelp =>
      'Conecta la radio al teléfono con un cable USB de datos (puede hacer falta un adaptador OTG). Android pedirá permiso la primera vez.';

  @override
  String nodesUsbListFailed(String error) {
    return 'No se pudieron listar los dispositivos USB: $error';
  }

  @override
  String get nodesNoUsb => 'No se encontraron dispositivos USB';

  @override
  String get nodesNoUsbBody =>
      'Comprueba que el cable transmita datos y no solo carga, y actualiza.';

  @override
  String nodesLikelyRadio(String chip) {
    return 'Probablemente una radio • $chip';
  }

  @override
  String get nodesOtherUsb => 'Otro dispositivo USB';

  @override
  String get nodesRefresh => 'Actualizar';

  @override
  String get setRadioSec => 'Radio';

  @override
  String get setRadioConfig => 'Configuración de la radio';

  @override
  String get setIdentity => 'Identidad del nodo';

  @override
  String get setChange => 'Cambiar ajustes de la radio';

  @override
  String get setChangeSub =>
      'Propietario, LoRa, canales, función del dispositivo y posición';

  @override
  String get setDeviceLora => 'Dispositivo y LoRa';

  @override
  String get setChannels => 'Canales';

  @override
  String get setModules => 'Módulos';

  @override
  String get setShareLoc => 'Compartir la ubicación del teléfono con la malla';

  @override
  String get setPrecision => 'Precisión de la ubicación';

  @override
  String get setPrecisionSub =>
      'Se redondea en este teléfono antes de enviarla';

  @override
  String get setLowPower => 'Modo de campo de bajo consumo';

  @override
  String get setApp => 'Aplicación';

  @override
  String get setWidget => 'Mostrar mensajes en el widget de inicio';

  @override
  String get setYourData => 'Tus datos';

  @override
  String get setRadioBackup => 'Copia cifrada de la radio';

  @override
  String get setRadioBackupSub =>
      'Guarda o restaura ajustes y claves de canal, protegidos con contraseña';

  @override
  String get setPhoneBackup => 'Copia de datos del teléfono';

  @override
  String get setPhoneBackupSub =>
      'Chats, nodos, puntos, registros y ajustes, para pasar a un teléfono nuevo';

  @override
  String get setPrivacy => 'Privacidad y datos';

  @override
  String get setPrivacySub =>
      'Qué se guarda y se envía; borra el historial o todos los datos del teléfono';

  @override
  String get setDemo => 'Modo de demostración';

  @override
  String get setAbout => 'Acerca de';

  @override
  String get setLicenses => 'Licencias de terceros';

  @override
  String get setReadAloud => 'Leer mensajes en voz alta';

  @override
  String get setReadSub =>
      'Usa la voz del teléfono, también con la pantalla apagada';

  @override
  String get setMqttTitle => 'Llevar MQTT a través de este teléfono';

  @override
  String get setBackground => 'Conexión en segundo plano';

  @override
  String get setOpenSettings => 'Abrir ajustes';

  @override
  String get setOfflineTiles => 'Mapas sin conexión';

  @override
  String get setClear => 'Borrar';

  @override
  String get setAlerts => 'Alertas de campo';

  @override
  String get setAlertsSub =>
      'Solo avisos en el teléfono; no se envía nada por la malla';

  @override
  String get setLowBattery => 'Batería baja';

  @override
  String get setThreshold => 'Umbral de batería';

  @override
  String get setNewNode => 'Nodo nuevo';

  @override
  String get setNewNodeSub => 'Tu radio escucha un nodo por primera vez';

  @override
  String get setFavQuiet => 'Un favorito deja de oírse';

  @override
  String get setMeshQuiet => 'La malla deja de oírse';

  @override
  String get setMeshQuietSub =>
      'Dejan de oírse la mitad o más de los nodos que escuchabas';

  @override
  String get setQuietAfter => 'Silencio tras';

  @override
  String get setRadioData => 'Datos de radios';

  @override
  String get setRadioDataSub =>
      '¿Perdiste o cambiaste una radio? Pasa sus mensajes, nodos e historial a la nueva';

  @override
  String get setMoveToConnected => 'Mover a la conectada';

  @override
  String get setDataUnreadable => 'No se pudieron leer los datos de radios.';

  @override
  String get setNoData => 'Aún no hay datos de radios en este teléfono.';

  @override
  String get setFilters => 'Filtros';

  @override
  String get setFilterHelp =>
      'Los mensajes con estas palabras se ocultan, no se borran.';

  @override
  String get setShowFiltered => 'Mostrar mensajes filtrados';

  @override
  String get setIgnored => 'Ignorado';

  @override
  String get setUnignore => 'Dejar de ignorar';

  @override
  String get setMuted => 'Silenciado';

  @override
  String get setUnmute => 'Reactivar';

  @override
  String get setOffLoc =>
      'Desactivado. La ubicación del teléfono nunca se envía.';

  @override
  String get setOnNoRadio => 'Activado. Empieza al conectar una radio.';

  @override
  String get setOnNoFix => 'Activado. Esperando señal GPS.';

  @override
  String setOnSent(String time) {
    return 'Activado. Último envío: $time.';
  }

  @override
  String get setSubtitle =>
      'Tu radio, el funcionamiento de la aplicación y tus datos.';

  @override
  String get setCanChange => 'Conectada • se pueden cambiar los ajustes';

  @override
  String setReadOnly(String version, String minimum, String url) {
    return 'Solo lectura: el firmware $version es anterior a $minimum. Actualízalo en $url.';
  }

  @override
  String get setConnectToView =>
      'Conecta una radio para ver y cambiar sus ajustes';

  @override
  String get setWaitingNode => 'Esperando la información de nodo de esta radio';

  @override
  String get setNoLong => 'Sin nombre largo';

  @override
  String get setNoShort => 'Sin nombre corto';

  @override
  String get setNoId => 'ID no indicado';

  @override
  String setConfigWait(int count) {
    return 'Aún no recibido ($count mensajes de configuración)';
  }

  @override
  String setChannelWait(int count) {
    return 'Aún no recibido ($count mensajes de canal)';
  }

  @override
  String setModulesSub(int count) {
    return '$count mensajes de módulos recibidos. Cámbialos en los ajustes de la radio.';
  }

  @override
  String setShareLocSub(String status) {
    return '$status\nSe usa cuando la radio no tiene GPS propio. Se actualiza cada 5 min, o antes si te mueves.';
  }

  @override
  String get setPrecise => 'Exacta';

  @override
  String setAbout2(String distance) {
    return 'Unos $distance';
  }

  @override
  String get setLowPowerSub =>
      'La ubicación compartida usa GPS equilibrado y se actualiza cada 15 min o tras moverte 200 m. El enlace de radio y el registro de cobertura no cambian.';

  @override
  String get setWidgetSub =>
      'Desactivado: el widget solo muestra cuántos mensajes hay sin leer. Activado: también muestra el remitente y el texto, visibles para quien tenga el teléfono.';

  @override
  String get setDemoSub =>
      'Explora la aplicación con una radio y una malla simuladas. No se envía nada y tus mensajes y ajustes no se tocan.';

  @override
  String get setDevBuild =>
      'Versión de desarrollo • Compañero independiente para mallas';

  @override
  String get setConnection => 'Conexión';

  @override
  String get setConnectionSub =>
      'Bluetooth LE • Modo seguro activado: ningún dispositivo sin verificar se trata como nodo';

  @override
  String get setTrademark => 'Marca registrada y compatibilidad';

  @override
  String get setDevWarning =>
      'No dependas de esta versión de desarrollo como único medio para pedir ayuda.';

  @override
  String get setChannelsKept => 'Mensajes de canal conservados';

  @override
  String setChannelsDeleted(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Mensajes de canal borrados tras $days días',
      one: 'Mensajes de canal borrados tras $days día',
    );
    return '$_temp0';
  }

  @override
  String setNewestPer(String count) {
    return 'los $count más recientes por conversación';
  }

  @override
  String get setReadOn => 'lectura en voz alta activada';

  @override
  String get setDeleteOld => 'Borrar mensajes de canal antiguos';

  @override
  String get setDirectKept => 'Los mensajes directos siempre se conservan';

  @override
  String get setNever => 'Nunca';

  @override
  String setAfterDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Tras $days días',
      one: 'Tras $days día',
    );
    return '$_temp0';
  }

  @override
  String get setHistory => 'Historial de mensajes';

  @override
  String get setHistoryHelp =>
      'Por canal o conversación directa. Un límite menor borra los mensajes antiguos.';

  @override
  String setKeepNewest(String count) {
    return 'Conservar los $count más recientes';
  }

  @override
  String get setMqttOff =>
      'Desactivado. Al activarlo usa los datos del teléfono.';

  @override
  String get setMqttWait => 'Activado. Espera a tu radio.';

  @override
  String get setMqttNoConfig =>
      'Tu radio no está configurada para esto. Activa MQTT y \"Proxy to client\" en sus ajustes.';

  @override
  String setMqttConnected(String host, int up, int down, String kb) {
    return 'Conectado a $host. $up enviados, $down recibidos, unos $kb KB de datos.';
  }

  @override
  String setMqttConnecting(String host) {
    return 'Conectando a $host…';
  }

  @override
  String get setMqttFailed => 'No se pudo conectar.';

  @override
  String get setMqttStarting => 'Iniciando…';

  @override
  String get setBgOptimized =>
      'La optimización de batería puede pausar NOTORYX Connect cuando no está en pantalla y cortar el enlace de radio. Configura su uso de batería como Sin restricciones para seguir conectado.';

  @override
  String get setBgAllowed =>
      'Puede funcionar en segundo plano. Se muestra un aviso mientras haya una radio conectada.';

  @override
  String get setSizeUnknown => 'Tamaño desconocido';

  @override
  String setMbSaved(String mb) {
    return '$mb MB guardados';
  }

  @override
  String get setTilesHelp =>
      'Las zonas del mapa que veas en línea siguen disponibles sin conexión durante un año (hasta 500 MB).';

  @override
  String get setAlertSaveFailed =>
      'Los ajustes de alertas se aplican ahora, pero no se pudieron guardar.';

  @override
  String setLowBatterySub(int pct) {
    return 'Tu radio o un favorito indica $pct% o menos';
  }

  @override
  String setFavQuietSub(String time) {
    return 'Un favorito no se oye durante $time mientras estás conectado';
  }

  @override
  String get setTheConnected => 'la radio conectada';

  @override
  String setMoveTitle(String label) {
    return '¿Mover $label?';
  }

  @override
  String setMoveBody(String to, String id) {
    return 'Sus mensajes, cola sin conexión, historial de NodeDex, rutas y telemetría pasan a $to. Lo que $to ya tenga se conserva, así que no se sobrescribe nada. Después, $id ya no tendrá entrada propia.\n\nPor seguridad, haz antes una copia de los datos del teléfono.';
  }

  @override
  String get setMove => 'Mover';

  @override
  String setMoved(String label, String to) {
    return '$label se movió a $to.';
  }

  @override
  String setDataCounts(int messages, int nodes, int trails) {
    return '$messages mensajes • $nodes nodos • $trails rutas';
  }

  @override
  String get setConnectNew =>
      'Conecta la radio nueva para pasarle los datos de la antigua.';

  @override
  String setFilterCounts(int ignored, int muted, int words) {
    return '$ignored ignorados • $muted silenciados • $words palabras filtradas';
  }

  @override
  String get setFilteredWords => 'Palabras filtradas';

  @override
  String get setWordField => 'Palabra o frase';

  @override
  String get setAddWord => 'Añadir palabra filtrada';

  @override
  String setRemoveWord(String word) {
    return 'Quitar $word';
  }

  @override
  String get setIgnoredMuted => 'Nodos ignorados y silenciados';

  @override
  String get setNoneIgnored =>
      'Ninguno. Abre un nodo para ignorarlo o silenciarlo.';

  @override
  String get mapNoPositions => 'Ningún nodo ha informado su posición todavía';

  @override
  String get mapConnectForPositions =>
      'Conecta una radio para ver las posiciones de los nodos';

  @override
  String mapPlaced(int placed, int total) {
    return '$placed de $total nodos ubicados';
  }

  @override
  String mapWaypointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puntos de ruta',
      one: '$count punto de ruta',
    );
    return '$_temp0';
  }

  @override
  String get mapLongPressHint =>
      'Mantén pulsado el mapa para colocar un punto de ruta';

  @override
  String get mapHeardWithin => 'Mostrar nodos oídos en';

  @override
  String get mapHeardAny => 'Oídos en cualquier momento';

  @override
  String get mapHeardHour => 'Oídos en la última hora';

  @override
  String get mapHeardDay => 'Oídos en las últimas 24 horas';

  @override
  String get mapHeardWeek => 'Oídos en los últimos 7 días';

  @override
  String get mapShowStreet => 'Mostrar mapa de calles';

  @override
  String get mapShowTopo => 'Mostrar mapa topográfico';

  @override
  String get mapLinkPlanner => 'Planificador de enlaces';

  @override
  String get mapRallyRoutes => 'Puntos de reunión y rutas';

  @override
  String get mapTeam => 'Equipo';

  @override
  String get mapZones => 'Zonas';

  @override
  String get mapExportGpx => 'Exportar GPX';

  @override
  String get mapHideTrails => 'Ocultar recorridos';

  @override
  String get mapShowTrails => 'Mostrar recorridos';

  @override
  String get mapHideLinks => 'Ocultar enlaces de radio';

  @override
  String get mapShowLinks => 'Mostrar enlaces de radio';

  @override
  String get mapShowAll => 'Mostrar todos los nodos';

  @override
  String mapPlanHint(int max) {
    return 'Toca el mapa para añadir paradas, en orden. Hasta $max.';
  }

  @override
  String mapPlanProgress(int count, int max, String distance) {
    return '$count de $max paradas • $distance';
  }

  @override
  String get mapUndo => 'Deshacer';

  @override
  String get mapShareRoute => 'Compartir ruta';

  @override
  String get mapRallyIntro =>
      'Los puntos de reunión son donde todos deben encontrarse. Coloca uno manteniendo pulsado el mapa y elige \"Punto de reunión\". Las rutas se comparten como puntos de ruta numerados, así que otras aplicaciones Meshtastic también ven las paradas.';

  @override
  String get mapRallyPoints => 'Puntos de reunión';

  @override
  String get mapNoneYet => 'Ninguno todavía.';

  @override
  String mapDistanceOfYou(String distance, String direction) {
    return 'A $distance al $direction de ti';
  }

  @override
  String get mapNoOwnPosition => 'Tu radio aún no tiene posición';

  @override
  String get mapShowOnMap => 'Mostrar en el mapa';

  @override
  String get mapRoutes => 'Rutas';

  @override
  String mapStops(int count) {
    return '$count paradas';
  }

  @override
  String mapStopsHeard(int heard, int count) {
    return '$heard de $count paradas oídas';
  }

  @override
  String get mapFromYou => 'de ti';

  @override
  String mapFromNode(String name) {
    return 'de $name';
  }

  @override
  String get mapPlanRoute => 'Planificar una ruta';

  @override
  String get mapConnectForRoutes => 'Conecta una radio para compartir rutas';

  @override
  String mapRouteShared(int count) {
    return 'Ruta compartida: $count paradas en el canal 0.';
  }

  @override
  String mapRouteStopped(int sent, int count, String error) {
    return 'La ruta se detuvo tras $sent de $count paradas: $error';
  }

  @override
  String mapGpxExported(int waypoints, int trails) {
    return 'Se exportaron $waypoints puntos de ruta y $trails recorridos como GPX.';
  }

  @override
  String mapGpxFailed(String error) {
    return 'No se pudo exportar GPX: $error';
  }

  @override
  String get mapWatchTrip => 'Contactos del viaje';

  @override
  String get mapWatchFavorites => 'Favoritos';

  @override
  String get mapWatchAll => 'Todos los nodos';

  @override
  String get mapAlertArrive => 'lleguen';

  @override
  String get mapAlertLeave => 'se vayan';

  @override
  String get mapAlertBoth => 'lleguen o se vayan';

  @override
  String get mapZonesIntro =>
      'Recibe un aviso en el teléfono cuando alguien llegue a un lugar o se vaya, como el campamento o el inicio del sendero. Los avisos necesitan la radio conectada; no se envía nada por la malla.';

  @override
  String get mapNoZones => 'Aún no hay zonas.';

  @override
  String mapZoneSummary(String radius, String watch, String alert) {
    return 'Radio de $radius • $watch • avisar cuando $alert';
  }

  @override
  String mapDeleteZone(String name) {
    return 'Eliminar $name';
  }

  @override
  String get mapAddZone => 'Añadir zona en el centro del mapa';

  @override
  String get mapTeamIntro =>
      'Tus contactos del viaje. Toca uno para encontrarlo en el mapa.';

  @override
  String get mapNoTeam => 'Aún no hay contactos del viaje';

  @override
  String get mapNoTeamHint =>
      'Añade hasta 6 personas en INICIO → Viaje. Aparecen aquí y destacan en el mapa.';

  @override
  String get mapFreshOk => 'BIEN';

  @override
  String get mapFreshQuiet => 'SILENCIO';

  @override
  String get mapFreshLost => 'PERDIDO';

  @override
  String get mapConnectForWaypoints =>
      'Conecta una radio para compartir puntos de ruta.';

  @override
  String mapWaypointShared(String name) {
    return 'Punto de ruta \"$name\" compartido en el canal 0.';
  }

  @override
  String mapWaypointFailed(String error) {
    return 'No se pudo compartir el punto de ruta: $error';
  }

  @override
  String get mapNeverExpires => 'No caduca nunca';

  @override
  String mapExpires(String time) {
    return 'Caduca $time';
  }

  @override
  String mapSharedBy(String name) {
    return 'Compartido por $name';
  }

  @override
  String get mapLocked => 'Bloqueado para su creador';

  @override
  String get mapDeleteEveryone => 'Eliminar para todos';

  @override
  String mapDeleted(String name) {
    return 'Se eliminó \"$name\".';
  }

  @override
  String mapDeleteFailed(String error) {
    return 'No se pudo eliminar: $error';
  }

  @override
  String get mapUnknown => 'desconocido';

  @override
  String mapFromThisRadio(String distance) {
    return 'A $distance de esta radio';
  }

  @override
  String mapPositionHeard(String position, String heard) {
    return 'Posición: $position • Oído: $heard';
  }

  @override
  String get mapDirect => 'directo';

  @override
  String get mapBatteryExternal => 'Batería: alimentación externa';

  @override
  String mapBattery(int level) {
    return 'Batería: $level%';
  }

  @override
  String get mapOpenDetails => 'Abrir detalles';

  @override
  String get mapThisRadioSuffix => ', esta radio';

  @override
  String mapTripContactSuffix(String summary) {
    return ', contacto del viaje, $summary';
  }

  @override
  String get mapRallyPoint => 'Punto de reunión';

  @override
  String get mapWaypoint => 'Punto de ruta';

  @override
  String get mapExpireHour => '1 hora';

  @override
  String get mapExpireDay => '1 día';

  @override
  String get mapExpireWeek => '1 semana';

  @override
  String get mapExpireNever => 'Nunca';

  @override
  String get mapNewWaypoint => 'Nuevo punto de ruta';

  @override
  String get mapName => 'Nombre';

  @override
  String get mapDescription => 'Descripción (opcional)';

  @override
  String get mapRallySub => 'Donde todos deben encontrarse';

  @override
  String get mapExpiresAfter => 'Caduca después de';

  @override
  String get mapOnlyMe => 'Solo yo puedo editar o eliminar';

  @override
  String get mapSharedChannel0 => 'Se comparte con todos en el canal 0.';

  @override
  String get mapShare => 'Compartir';

  @override
  String get mapNewZone => 'Nueva zona';

  @override
  String mapCenteredOn(String lat, String lon) {
    return 'Centrada en $lat, $lon';
  }

  @override
  String get mapZoneName => 'Nombre, p. ej. Campamento';

  @override
  String get mapRadius => 'Radio de alcance';

  @override
  String get mapWatch => 'Vigilar';

  @override
  String get mapAlertWhen => 'Avisar cuando';

  @override
  String get mapAdd => 'Añadir';

  @override
  String get mapRouteName => 'Nombre de la ruta';

  @override
  String mapRouteSends(int count) {
    return 'Envía $count puntos de ruta en el canal 0, con unos 3 segundos de separación. Caducan al cabo de un día.';
  }
}
