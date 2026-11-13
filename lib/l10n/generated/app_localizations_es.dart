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
  String get chatsForward => 'Reenviar';

  @override
  String get chatsForwardTo => 'Reenviar a';

  @override
  String get chatsForwardReview => 'Revisa el mensaje y toca Enviar.';

  @override
  String chatsChannelNumbered(int index, String name) {
    return 'Canal $index: $name';
  }

  @override
  String get chatsSchedule => 'Enviar más tarde';

  @override
  String get chatsSchedule15 => 'En 15 minutos';

  @override
  String get chatsSchedule60 => 'En 1 hora';

  @override
  String get chatsSchedule240 => 'En 4 horas';

  @override
  String get chatsScheduleTomorrow => 'Mañana a las 8:00';

  @override
  String get chatsSchedulePick => 'Elegir fecha y hora';

  @override
  String get chatsScheduleNote =>
      'Solo se envía mientras la aplicación está abierta y la radio conectada.';

  @override
  String chatsScheduleFull(int max) {
    return 'Puedes programar hasta $max mensajes.';
  }

  @override
  String get chatsScheduled => 'Programados';

  @override
  String chatsScheduledFor(String day, String time) {
    return '$day a las $time';
  }

  @override
  String get chatsScheduleMissed =>
      'No enviado: la radio no estaba conectada a tiempo';

  @override
  String get chatsScheduleCancel => 'Cancelar mensaje programado';

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

  @override
  String get mapShowHeatmap => 'Mostrar mapa de cobertura';

  @override
  String get mapHideHeatmap => 'Ocultar mapa de cobertura';

  @override
  String get mapHeatmapEmpty =>
      'Aún no hay lecturas de cobertura. Activa Registrar cobertura en Registros de campo.';

  @override
  String mapHeatmapSummary(int readings) {
    return 'Cobertura: $readings lecturas. Los números son la SNR media en dB.';
  }

  @override
  String get mapHeatStrong => 'Fuerte';

  @override
  String get mapHeatFair => 'Regular';

  @override
  String get mapHeatWeak => 'Débil';

  @override
  String get mapShowRemembered => 'Mostrar nodos recordados';

  @override
  String get mapHideRemembered => 'Ocultar nodos recordados';

  @override
  String get mapRememberedNone =>
      'No hay nodos recordados con posición guardada.';

  @override
  String mapRememberedPin(String name, String when) {
    return '$name, recordado, visto por última vez $when';
  }

  @override
  String get mapRememberedNote =>
      'Tu radio ya no muestra este nodo. Aquí fue donde informó por última vez.';

  @override
  String mapLastSeen(String when) {
    return 'Visto por última vez $when';
  }

  @override
  String get lockTitle => 'NOTORYX Connect está bloqueado';

  @override
  String get lockBody =>
      'Tu radio sigue conectada mientras la aplicación está bloqueada.';

  @override
  String get lockUnlock => 'Desbloquear';

  @override
  String get lockReason => 'Desbloquear NOTORYX Connect';

  @override
  String get takTitle => 'Envío a ATAK';

  @override
  String get toolsTakSub =>
      'Mostrar nodos de la malla en ATAK en este teléfono';

  @override
  String get takIntro =>
      'Envía la posición de cada nodo de la malla a ATAK en este teléfono, cada 30 segundos. Nada sale del teléfono y no se envía nada por la malla.';

  @override
  String get takSwitch => 'Enviar posiciones de la malla a ATAK';

  @override
  String get takPort => 'Puerto UDP';

  @override
  String get takBadPort => 'Usa un número del 1024 al 65535.';

  @override
  String takStatus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enviando $count nodos',
      one: 'Enviando $count nodo',
    );
    return '$_temp0';
  }

  @override
  String takProblem(String error) {
    return 'No se pudo enviar: $error';
  }

  @override
  String get takHowTo =>
      'En ATAK, abre Ajustes, luego Preferencias de red, luego Administrar entradas, y añade una entrada UDP en este puerto. Se omiten los nodos sin posición en la última hora.';

  @override
  String ndFailed(String error) {
    return 'Falló: $error';
  }

  @override
  String ndSendFailed(String error) {
    return 'No se pudo enviar: $error';
  }

  @override
  String get ndFieldNote => 'Nota de campo';

  @override
  String get ndRemoveFavorite => 'Quitar de favoritos';

  @override
  String get ndAddFavorite => 'Añadir a favoritos';

  @override
  String get ndShortName => 'Nombre corto';

  @override
  String get ndHardware => 'Hardware';

  @override
  String get ndThisRadio => 'Esta radio';

  @override
  String get ndYes => 'Sí';

  @override
  String get ndLastHeard => 'Oído por última vez';

  @override
  String get ndSignal => 'Señal';

  @override
  String get ndHopsAway => 'Saltos de distancia';

  @override
  String get ndDirect => 'Directo';

  @override
  String get ndBattery => 'Batería';

  @override
  String get ndExternalPower => 'Alimentación externa';

  @override
  String get ndVoltage => 'Voltaje';

  @override
  String get ndChannelUse => 'Uso del canal';

  @override
  String get ndPosition => 'Posición';

  @override
  String get ndAltitude => 'Altitud';

  @override
  String get ndPositionAge => 'Antigüedad de la posición';

  @override
  String get ndDistance => 'Distancia';

  @override
  String get ndEncounters => 'Encuentros';

  @override
  String get ndTraceroute => 'Traceroute';

  @override
  String get ndRequestPosition => 'Pedir posición';

  @override
  String get ndPositionRequested =>
      'Posición pedida. Se actualiza cuando el nodo responda.';

  @override
  String get ndRequestTelemetry => 'Pedir telemetría';

  @override
  String get ndTelemetryRequested =>
      'Telemetría pedida. Se actualiza cuando el nodo responda.';

  @override
  String get ndRemoteAdmin => 'Administración remota';

  @override
  String get ndRequestSensors => 'Pedir sensores';

  @override
  String get ndSensorsRequested =>
      'Lecturas de sensores pedidas. Los nodos sin sensores no responden.';

  @override
  String get ndMute => 'Silenciar notificaciones';

  @override
  String get ndMuteSub =>
      'Los mensajes se siguen viendo; sin avisos ni lectura en voz alta';

  @override
  String get ndIgnore => 'Ignorar este nodo';

  @override
  String get ndIgnoreSub =>
      'Oculto en nodos, mapa y chats; nunca avisa ni recibe respuestas del bot. Deshazlo aquí o en Ajustes.';

  @override
  String get ndAddNote => 'Toca para añadir una nota';

  @override
  String get ndDirectMessages => 'MENSAJES DIRECTOS';

  @override
  String get ndNoDirect => 'Aún no hay mensajes directos con este nodo.';

  @override
  String get ndDirectMessage => 'Mensaje directo';

  @override
  String get ndSend => 'Enviar';

  @override
  String get ndRadioLinks => 'ENLACES DE RADIO DIRECTOS';

  @override
  String get ndNoNeighbors =>
      'Aún no hay informes de vecinos. Los nodos los comparten cuando el módulo Neighbor Info está activado (Ajustes → Cambiar ajustes de la radio → Neighborinfo).';

  @override
  String ndHears(int count) {
    return 'Oye directamente ($count):';
  }

  @override
  String get ndNoneReported => '  No se informaron vecinos';

  @override
  String ndHeardBy(int count) {
    return 'Lo oyen directamente ($count):';
  }

  @override
  String get ndTrustQ => '¿Confiar en la nueva clave?';

  @override
  String ndTrustBody(String name) {
    return 'Hazlo solo si confirmaste con el dueño de $name que reinició o cambió su radio. Si no, alguien podría estar haciéndose pasar por este nodo.';
  }

  @override
  String get ndTrust => 'Confiar en la nueva clave';

  @override
  String get ndKeyChanged => 'La clave de seguridad cambió';

  @override
  String ndKeyChangedBody(String newCode, String oldCode) {
    return 'Este nodo muestra ahora una clave distinta ($newCode) de la que se vio primero ($oldCode). Puede que su radio se haya reiniciado o cambiado, o que alguien se esté haciendo pasar por él. Confírmalo con su dueño antes de enviar mensajes privados.';
  }

  @override
  String get ndSecurityKey => 'Clave de seguridad';

  @override
  String get ndKeyNotShared =>
      'Aún no se ha compartido. Los nodos con firmware 2.5 o posterior comparten una clave para mensajes directos privados.';

  @override
  String ndSafetyCode(String code) {
    return 'Código de seguridad $code\nCompáralo con la radio del dueño para asegurarte de que es esa persona.';
  }

  @override
  String get homeFirmwareTitle =>
      'Se recomienda actualizar el firmware de la radio';

  @override
  String get homeCheckIn => 'Reportarse';

  @override
  String get homeEmergency => 'Emergencia';

  @override
  String get homeSosHint =>
      'Mantén pulsado 2 segundos. Se envía a tus contactos del viaje y se repite cada 5 minutos hasta que alguien responda.';

  @override
  String homeSosHintChannel(int channel) {
    return 'Mantén pulsado 2 segundos. Se envía a tus contactos del viaje y al canal $channel, y se repite cada 5 minutos hasta que alguien responda.';
  }

  @override
  String get homeNotReceived =>
      'Enviado o en cola no significa recibido. Confírmalo con una respuesta o una llamada.';

  @override
  String get homeConnected => 'Radio conectada';

  @override
  String get homeNotConnected => 'Ninguna radio conectada';

  @override
  String get homeYourRadio => 'Tu radio';

  @override
  String get homeConnectHint =>
      'Conéctate para reportarte, enviar un SOS y ver la malla.';

  @override
  String get homeNodes => 'Nodos';

  @override
  String get homeBattery => 'Batería';

  @override
  String get homeUnknown => 'Desconocida';

  @override
  String get homePluggedIn => 'Enchufada';

  @override
  String get homeConnectRadio => 'Conectar radio';

  @override
  String get homeTryDemo => 'Probar la demostración';

  @override
  String get homeTripRunning => 'Viaje en curso';

  @override
  String get homeTripNotStarted => 'Viaje sin empezar';

  @override
  String homeContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contactos',
      one: '$count contacto',
    );
    return '$_temp0';
  }

  @override
  String homeTripNamed(String name) {
    return 'Viaje: $name';
  }

  @override
  String get homePlanTrip => 'Planifica tu viaje';

  @override
  String homeOverdue(String names) {
    return 'Con retraso: $names';
  }

  @override
  String homeCheckInLabel(String label) {
    return 'Reportarse: $label';
  }

  @override
  String homeDelivered(String label, String time, int delivered, int total) {
    return '$label a las $time: entregado a $delivered de $total';
  }

  @override
  String homeNotDelivered(String names) {
    return 'no entregado a $names';
  }

  @override
  String homeWaiting(int count) {
    return '$count en espera';
  }

  @override
  String get homeDetails => 'Detalles';

  @override
  String get homeResend => 'Reenviar';

  @override
  String get homeSendSosQ => '¿Enviar SOS?';

  @override
  String get homeSosRepeats =>
      'Tu SOS se repite cada 5 minutos hasta que alguien responda o lo detengas.';

  @override
  String get homeSendSos => 'Enviar SOS';

  @override
  String get homeHoldSos => 'Mantén para SOS';

  @override
  String homeSosReplied(String name) {
    return '$name respondió. Se detuvieron las repeticiones.';
  }

  @override
  String homeSosNext(int sends, int max, String time) {
    return 'Enviado $sends de $max. Próximo a las $time.';
  }

  @override
  String get homeSosBusy =>
      ' El canal está ocupado, así que las repeticiones se espacian para que lleguen.';

  @override
  String homeSosDone(int max) {
    return 'Enviado $max veces. Terminaron las repeticiones; el SOS sigue visible hasta que lo detengas.';
  }

  @override
  String get homeSosActive => 'SOS activo';

  @override
  String get homeImSafe => 'Estoy a salvo';

  @override
  String get homeStopNoMessage => 'Detener sin mensaje';

  @override
  String get frTitle => 'Registros de campo';

  @override
  String get frTplAssistance => 'Ayuda';

  @override
  String get frTplCheckIn => 'Reporte';

  @override
  String get frTplAllClear => 'Todo en orden';

  @override
  String get frTooLong => 'Escribe un mensaje de 1 a 220 bytes UTF-8.';

  @override
  String frBroadcastQ(int channel) {
    return '¿Enviar al canal $channel?';
  }

  @override
  String get frNoProof =>
      'Enviar no demuestra que se haya recibido. Confírmalo con una respuesta o por voz.';

  @override
  String get frSendMessage => 'Enviar mensaje';

  @override
  String get frChanged =>
      'La radio o el canal cambió. Vuelve a conectar y revisa el mensaje.';

  @override
  String get frSubmitted =>
      'Entregado a la radio. Mira Chats para ver el estado del envío y las respuestas.';

  @override
  String get frIncidentLog => 'Registro de incidentes';

  @override
  String get frIncidentLogSub => 'Notas privadas guardadas en este teléfono';

  @override
  String get frIncidentField => 'Incidente u observación';

  @override
  String get frIncidentSaved => 'Incidente guardado.';

  @override
  String get frSaveIncident => 'Guardar incidente';

  @override
  String get frIncidentCopied =>
      'CSV de incidentes copiado. Pégalo en un archivo o una hoja de cálculo.';

  @override
  String get frCopyIncident => 'Copiar CSV de incidentes';

  @override
  String frRadioOf(String time, String radio) {
    return '$time • Radio $radio';
  }

  @override
  String get frUnassigned => 'sin asignar';

  @override
  String get frRemoveIncident => 'Eliminar incidente';

  @override
  String get frRemoveIncidentQ => '¿Eliminar este incidente?';

  @override
  String get frKeep => 'Conservar';

  @override
  String get frRemove => 'Eliminar';

  @override
  String get frIncidentRemoved => 'Incidente eliminado.';

  @override
  String get frTemplates => 'Plantillas de emergencia y reporte';

  @override
  String get frTemplatesSub =>
      'Edita los detalles, elige un canal y revisa antes de enviar';

  @override
  String get frMessageField => 'Mensaje: completa los datos en blanco';

  @override
  String get frBroadcastChannel => 'Canal de envío';

  @override
  String frChannelItem(int index, String name) {
    return 'Canal $index • $name';
  }

  @override
  String get frReview => 'Revisar mensaje';

  @override
  String get frNotEmergency =>
      'Una plantilla es texto normal de la malla. No contacta con los servicios de emergencia.';

  @override
  String get frCoverage => 'Historial de cobertura';

  @override
  String get frCoverageSub =>
      'Ubicación del receptor con la señal RF recibida • solo se guarda en el teléfono';

  @override
  String get frRecord => 'Registrar cobertura';

  @override
  String get frRecordSub =>
      'Pide el GPS del teléfono. Se detiene al desconectar. No envía tu ubicación.';

  @override
  String get frRecordOn =>
      'Registro de cobertura activado; esperando una posición GPS precisa y paquetes RF.';

  @override
  String get frRecordOff => 'Registro de cobertura detenido.';

  @override
  String frReadings(int count) {
    return '$count lecturas • máximo 2000 lecturas de cobertura • la cobertura caduca a los 30 días';
  }

  @override
  String get frCoverageCopied =>
      'CSV de cobertura copiado. Pégalo en un archivo o una hoja de cálculo.';

  @override
  String get frCopyCoverage => 'Copiar CSV de cobertura';

  @override
  String get frBot => 'Protecciones del bot y horas de silencio';

  @override
  String get frBotSub =>
      '6 respuestas/hora • 30 segundos entre respuestas • 5 minutos de espera por nodo';

  @override
  String get frBotEnable => 'Activa el modo bot en Chats para esta sesión.';

  @override
  String get frBotRules =>
      'Solo cuentan los mensajes nuevos del canal elegido. Se ignoran las repeticiones y las respuestas de bots (NOTORYX: o Bastion:). Las horas de silencio usan la hora local del teléfono.';

  @override
  String get frQuiet => 'Horas de silencio';

  @override
  String get frQuietStart => 'Inicio de las horas de silencio';

  @override
  String get frQuietEnd => 'Fin de las horas de silencio';

  @override
  String get frBotChannel => 'Canal del bot';

  @override
  String frChannelN(int index) {
    return 'Canal $index';
  }

  @override
  String frBytes(int bytes, int max) {
    return '$bytes de $max bytes. Las líneas en blanco no se envían.';
  }

  @override
  String frBytesOver(int bytes, int max) {
    return '$bytes de $max bytes. Demasiado largo para enviar: acorta un campo.';
  }

  @override
  String get frUseReport => 'Usar informe';

  @override
  String get rsTitle => 'Ajustes de la radio';

  @override
  String get rsNotReady => 'Radio no preparada';

  @override
  String get rsNotReadySub =>
      'Conéctate a una radio y espera a READY para cambiar los ajustes.';

  @override
  String get rsAvailability => 'Disponibilidad de ajustes';

  @override
  String get rsAvailabilitySub =>
      'Comprueba las lecturas antes de editar. Que falten ajustes al inicio no demuestra que un módulo no sea compatible. Los resultados se reinician al reconectar.';

  @override
  String get rsStopChecking => 'Dejar de comprobar';

  @override
  String get rsOwner => 'Propietario';

  @override
  String get rsOwnerSub => 'Nombres largo y corto del nodo';

  @override
  String get rsLoraSub =>
      'Región, preajuste de módem, límite de saltos, transmisión';

  @override
  String get rsChannels => 'Canales';

  @override
  String get rsChannelsSub => 'Nombres, funciones y claves de cifrado';

  @override
  String get rsDevice => 'Dispositivo';

  @override
  String get rsDeviceSub => 'Función del dispositivo y modo de retransmisión';

  @override
  String get rsPosition => 'Posición';

  @override
  String get rsPositionSub =>
      'Intervalo de emisión, modo GPS, posición inteligente';

  @override
  String get rsAllSettings => 'TODOS LOS AJUSTES DE LA RADIO';

  @override
  String get rsModules => 'MÓDULOS';

  @override
  String get rsRadioChanged =>
      'La radio conectada cambió durante la carga. Vuelve a intentar la lectura.';

  @override
  String rsSaveQ(String section) {
    return '¿Guardar $section?';
  }

  @override
  String get rsSaveWarning =>
      'Esto escribe el cambio en la radio conectada. La radio puede reiniciarse y volver a conectarse.';

  @override
  String get rsIdentityChanged =>
      'La identidad de la radio cambió o no está disponible. Recarga antes de guardar.';

  @override
  String rsSaved(String section) {
    return '$section guardado y verificado desde la radio.';
  }

  @override
  String rsNotVerified(String error) {
    return 'Guardado sin verificar: $error\nEs posible que la radio haya aplicado el cambio. Recarga para ver su valor actual; no se reenviará nada automáticamente.';
  }

  @override
  String get rsSaveButton => 'GUARDAR';

  @override
  String rsUnavailable(String section) {
    return 'Los ajustes de $section no están disponibles en la API del firmware de esta radio.';
  }

  @override
  String rsReadFailed(String error) {
    return 'No se pudo leer de la radio: $error';
  }

  @override
  String get rsRetry => 'Reintentar';

  @override
  String get rsWaitingReconnect =>
      'Esperando la reconexión y una nueva lectura de ajustes…';

  @override
  String get rsReload => 'Recargar desde la radio';

  @override
  String get rsLongName => 'Nombre largo';

  @override
  String get rsShortName => 'Nombre corto';

  @override
  String get rsChooseRegion =>
      'Elige una región antes de guardar; la radio no transmitirá sin una.';

  @override
  String get rsCustomInvalid =>
      'Los ajustes personalizados requieren un ancho de banda positivo, factor de dispersión 5–12 y denominador de tasa de codificación 5–8. Comprueba los valores que admite tu radio.';

  @override
  String get rsRegionWarning =>
      'Cambiar la región o el preajuste de módem desconecta esta radio de los nodos que mantengan los ajustes anteriores.';

  @override
  String get rsRegion => 'Región';

  @override
  String get rsUsePreset => 'Usar preajuste de módem';

  @override
  String get rsModemPreset => 'Preajuste de módem';

  @override
  String get rsBandwidth => 'Ancho de banda (kHz)';

  @override
  String get rsSpreadFactor => 'Factor de dispersión';

  @override
  String get rsCodingRate => 'Denominador de tasa de codificación (5–8)';

  @override
  String get rsRxBoost => 'Ganancia de recepción ampliada';

  @override
  String get rsRxBoostSub =>
      'Ganancia interna del receptor SX126x; distinta del LNA externo';

  @override
  String get rsLna => 'LNA externo';

  @override
  String get rsLnaReported =>
      'Amplificador de recepción externo informado por esta radio';

  @override
  String get rsLnaNone =>
      'Esta radio no ha informado de un LNA externo controlable';

  @override
  String rsHopLimit(int hops) {
    return 'Límite de saltos: $hops';
  }

  @override
  String get rsTransmit => 'Transmisión activada';

  @override
  String get rsTransmitSub => 'Desactivada, la radio solo recibe';

  @override
  String rsInfraWarning(String role) {
    return '$role es para infraestructura fija con buena cobertura. En un equipo portátil desperdicia tiempo de aire y batería.';
  }

  @override
  String get rsRole => 'Función';

  @override
  String get rsRebroadcast => 'Modo de retransmisión';

  @override
  String get rsIntervalInvalid =>
      'El intervalo de emisión debe ser 0 (valor del firmware) o al menos 30 segundos.';

  @override
  String get rsGpsMode => 'Modo GPS';

  @override
  String get rsInterval =>
      'Intervalo de emisión (segundos, 0 = predeterminado)';

  @override
  String get rsSmart => 'Emisión inteligente de posición';

  @override
  String get rsSmartSub =>
      'Envía actualizaciones extra cuando el nodo se mueve';

  @override
  String get rsFixed => 'Posición fija';

  @override
  String get rsFixedSub =>
      'Informa la última posición conocida en lugar del GPS';

  @override
  String get rsShareQr => 'Compartir como código QR';

  @override
  String get rsImportLink => 'Importar enlace de canal';

  @override
  String get rsDisabled => 'Desactivado';

  @override
  String get rsDefaultName => '(nombre predeterminado)';

  @override
  String rsChannelsFailed(String error) {
    return 'No se pudieron leer los canales: $error';
  }

  @override
  String get rsNoEncryption => 'Sin cifrado';

  @override
  String get rsDefaultKey => 'Clave predeterminada';

  @override
  String get rsAes128 => 'Clave AES-128';

  @override
  String get rsAes256 => 'Clave AES-256';

  @override
  String get rsUnknownKey => 'Clave no reconocida';

  @override
  String rsChannelN(int index) {
    return 'Canal $index';
  }

  @override
  String get rsKeyWarning =>
      'La clave de cifrado cambia. Los nodos sin la nueva clave ya no podrán leer este canal. Compártela desde el código QR del canal.';

  @override
  String get rsChannelName => 'Nombre (en blanco usa el nombre del preajuste)';

  @override
  String rsEncryption(String key) {
    return 'Cifrado: $key';
  }

  @override
  String get rsNewAes256 => 'Nueva AES-256 aleatoria';

  @override
  String rsGpsHidden(String model) {
    return 'Los pines GPS están ocultos: $model tiene el GPS conectado de fábrica, así que no hacen nada.';
  }

  @override
  String get bcShareQ => '¿Compartir tu canal principal?';

  @override
  String get bcShareBody =>
      'La baliza incluirá el nombre y la clave de tu canal principal. Cualquiera dentro del alcance podrá unirse y leer sus mensajes.';

  @override
  String get bcShare => 'Compartir';

  @override
  String get bcSent => 'Baliza enviada.';

  @override
  String bcNotSent(String error) {
    return 'No se envió la baliza: $error';
  }

  @override
  String get bcTitle => 'Balizas de la malla';

  @override
  String get bcClear => 'Borrar balizas oídas';

  @override
  String get bcIntro =>
      'Una baliza es un aviso corto que indica a las radios cercanas que hay una malla y puede invitarlas a un canal. Las radios con el firmware Meshtastic más reciente la muestran; NOTORYX Connect muestra las balizas que oye con cualquier firmware.';

  @override
  String get bcSendTitle => 'Enviar una baliza';

  @override
  String get bcMessage => 'Mensaje de la baliza';

  @override
  String get bcMessageHelp =>
      'Se envía en tu canal principal. Como máximo una baliza por hora.';

  @override
  String bcBytes(int used, int max) {
    return '$used/$max bytes';
  }

  @override
  String get bcTooLong => 'Demasiado largo';

  @override
  String get bcAddLocationNone => 'Añadir mi ubicación (aún sin posición)';

  @override
  String get bcAddLocation => 'Añadir mi ubicación como Plus Code';

  @override
  String get bcInvite => 'Invitar a mi canal principal';

  @override
  String get bcInviteSub =>
      'Incluye el nombre y la clave del canal, y tu región y preajuste';

  @override
  String get bcSending => 'Enviando…';

  @override
  String get bcSend => 'Enviar baliza';

  @override
  String get bcConnect => 'Conéctate a una radio para enviar una baliza.';

  @override
  String bcNext(String time) {
    return 'La próxima baliza se puede enviar a las $time.';
  }

  @override
  String get bcHeard => 'Balizas oídas';

  @override
  String get bcNoneHeard => 'Aún no se han oído balizas';

  @override
  String get bcNoneHeardSub =>
      'Aquí aparecen las balizas de las radios a tu alcance en tus canales.';

  @override
  String bcFrom(String name) {
    return 'De $name';
  }

  @override
  String bcHeardAt(String time) {
    return 'oída $time';
  }

  @override
  String bcChannel(String name) {
    return 'Canal \"$name\"';
  }

  @override
  String get bcDefault => 'Predeterminado';

  @override
  String bcRegion(String name) {
    return 'región $name';
  }

  @override
  String bcPreset(String name) {
    return 'preajuste $name';
  }

  @override
  String bcSlot(int slot) {
    return 'ranura $slot';
  }

  @override
  String get bcNoMessage => '(sin mensaje)';

  @override
  String bcInvitesTo(String offer) {
    return 'Invita a: $offer';
  }

  @override
  String get bcJoin => 'Revisar y unirse al canal';

  @override
  String get csShareTitle => 'Compartir canales';

  @override
  String csReadFailed(String error) {
    return 'No se pudieron leer los canales: $error';
  }

  @override
  String get csRetry => 'Reintentar';

  @override
  String csPrimary(String name) {
    return 'Principal: $name';
  }

  @override
  String csSecondary(String name) {
    return 'Secundario: $name';
  }

  @override
  String get csDefaultName => '(nombre predeterminado)';

  @override
  String get csCopyLink => 'Copiar enlace';

  @override
  String get csCopied => 'Enlace del canal copiado.';

  @override
  String get csKeysWarning =>
      'Este código contiene las claves de cifrado de tus canales. Cualquiera que lo escanee podrá leer y enviar en estos canales.';

  @override
  String get csReplaceQ => '¿Reemplazar todos los canales?';

  @override
  String get csAddQ => '¿Añadir canales?';

  @override
  String get csReplaceBody =>
      'Se sobrescribirán las 8 ranuras de canal. Perderás el acceso a los canales actuales a menos que tengas su enlace. La radio se reiniciará.';

  @override
  String get csReplaceLoraBody =>
      'Se sobrescribirán las 8 ranuras de canal y los ajustes LoRa. Perderás el acceso a los canales actuales a menos que tengas su enlace. La radio se reiniciará.';

  @override
  String get csAddBody =>
      'Los canales nuevos del enlace van a ranuras libres. Los canales existentes y los ajustes LoRa no cambian.';

  @override
  String get csApply => 'Aplicar';

  @override
  String get csAlreadyThere =>
      'Todos los canales del enlace ya están en la radio.';

  @override
  String csWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canales escritos y verificados desde la radio.',
      one: '$count canal escrito y verificado desde la radio.',
    );
    return '$_temp0';
  }

  @override
  String csNotVerified(String error) {
    return 'Importación sin verificar: $error\nNo se reenviará nada automáticamente.';
  }

  @override
  String csRefused(String error) {
    return 'Importación rechazada: $error';
  }

  @override
  String csFailed(String error) {
    return 'La importación falló: $error';
  }

  @override
  String get csImportTitle => 'Importar canales';

  @override
  String get csScan => 'Escanear código QR del canal';

  @override
  String get csScanTitle => 'Escanear QR del canal';

  @override
  String get csLinkLabel => 'Enlace de canal de Meshtastic';

  @override
  String get csPaste => 'Pegar';

  @override
  String csLora(String region, String modem) {
    return 'LoRa: $region, $modem';
  }

  @override
  String get csCustomModem => 'módem personalizado';

  @override
  String get csAdd => 'Añadir a la radio';

  @override
  String get csReplaceAll => 'Reemplazar todo';

  @override
  String get csApplyRadio => 'Aplicar a la radio';

  @override
  String get trTitle => 'Planifica tu viaje';

  @override
  String get trName => 'Nombre del viaje';

  @override
  String trContacts(int count, int max) {
    return 'CONTACTOS DEL VIAJE ($count/$max)';
  }

  @override
  String get trContactsSub =>
      'Los reportes y el SOS les llegan a cada uno como mensaje directo.';

  @override
  String get trNoNodes => 'Aún no hay nodos';

  @override
  String get trNoNodesSub =>
      'Conéctate a tu radio para que aparezcan aquí los nodos cercanos y tus favoritos.';

  @override
  String get trOverdue => 'Aviso de retraso';

  @override
  String get trOverdueHelp =>
      'Te avisa cuando no se ha oído a un contacto del viaje durante este tiempo';

  @override
  String get trOff => 'Desactivado';

  @override
  String trMinutes(int count) {
    return '$count min';
  }

  @override
  String trHours(int count) {
    return '$count h';
  }

  @override
  String get trReminder => 'Recordatorio de reporte';

  @override
  String get trReminderHelp =>
      'Te recuerda reportarte este tiempo después de tu último reporte';

  @override
  String trEvery(String time) {
    return 'Cada $time';
  }

  @override
  String get trSosChannel => 'Enviar también el SOS a un canal';

  @override
  String get trSosChannelHelp =>
      'Todos los de ese canal ven tu SOS, no solo los contactos del viaje';

  @override
  String get trContactsOnly => 'No, solo contactos del viaje';

  @override
  String trChannelItem(int index, String name) {
    return 'Canal $index • $name';
  }

  @override
  String get trDefault => 'Predeterminado';

  @override
  String get trReadiness => 'Comprobación previa';

  @override
  String get trEnd => 'Terminar viaje';

  @override
  String get trStart => 'Empezar viaje';

  @override
  String trRunning(String time) {
    return 'Viaje en curso desde las $time. Los avisos de retraso y los recordatorios están activados.';
  }

  @override
  String get trNotRunning =>
      'Al empezar el viaje se activan los avisos de retraso y los recordatorios de reporte. Los reportes y el SOS funcionan en cualquier momento.';

  @override
  String get pvEncryptedOn => 'El historial de chat ahora está cifrado.';

  @override
  String get pvEncryptedOff => 'El historial de chat ya no está cifrado.';

  @override
  String get pvLockOnReason => 'Activar el bloqueo de la aplicación';

  @override
  String get pvLockOffReason => 'Desactivar el bloqueo de la aplicación';

  @override
  String get pvLockUnchanged => 'No se cambió el bloqueo de la aplicación.';

  @override
  String get pvStored1 =>
      'Historial de chat y colas sin conexión de cada radio (los 500 mensajes más recientes por radio)';

  @override
  String get pvStored2 =>
      'NodeDex: los nodos que oyeron tus radios, más tus favoritos y notas';

  @override
  String get pvStored3 => 'Puntos de ruta recibidos de la malla';

  @override
  String get pvStored4 =>
      'Registro de incidentes y de cobertura, solo si los creas';

  @override
  String get pvStored5 =>
      'Ajustes de avisos de campo, bot, ubicación y apariencia';

  @override
  String get pvStored6 => 'Teselas de mapa de las zonas que has visto';

  @override
  String get pvSent1 =>
      'Los mensajes que envías van a tu radio, que los transmite por la malla con la clave de cifrado del canal';

  @override
  String get pvSent2 =>
      'La ubicación de tu teléfono, solo mientras \"Compartir ubicación del teléfono\" esté activado, con la precisión que elijas';

  @override
  String get pvSent3 =>
      'Las peticiones de posición, telemetría y traceroute que inicies';

  @override
  String get pvSent4 =>
      'Peticiones de teselas a los servidores de OpenStreetMap cuando ves el mapa; ven tu dirección IP';

  @override
  String get pvSent5 =>
      'Peticiones de teselas topográficas a los servidores de OpenTopoMap, solo mientras se muestra el mapa topográfico; ven tu dirección IP';

  @override
  String get pvSent6 =>
      'Puntos de un enlace al servicio de elevación Open-Meteo, solo cuando compruebas un enlace en el planificador';

  @override
  String get pvDisconnectFirst =>
      'Desconecta la radio antes de borrar los datos del teléfono.';

  @override
  String get pvDeleteAllQ => '¿Borrar todos los datos del teléfono?';

  @override
  String get pvDeleteChatsQ => '¿Borrar el historial de chat?';

  @override
  String get pvDeleteAllBody =>
      'Borra de este teléfono los chats y colas sin conexión de todas las radios, NodeDex, favoritos y notas, puntos de ruta, registros de campo, teselas de mapa guardadas y todos los ajustes de la aplicación. Los ajustes de la radio no cambian. No se puede deshacer; haz antes una copia de seguridad de los datos del teléfono si puedes necesitarlos.\n\nLa aplicación se cierra después.';

  @override
  String get pvDeleteChatsBody =>
      'Borra de este teléfono el historial de chat y los mensajes en cola de todas las radios. Los mensajes ya enviados por la malla no se ven afectados. No se puede deshacer.\n\nLa aplicación se cierra después.';

  @override
  String get pvDelete => 'Borrar';

  @override
  String pvDeleteFailed(String error) {
    return 'No se pudo borrar: $error';
  }

  @override
  String get pvDeleted => 'Borrado';

  @override
  String get pvDeletedBody =>
      'NOTORYX Connect se cerrará ahora para que no se vuelva a guardar nada que siga en memoria.';

  @override
  String get pvCloseApp => 'Cerrar la aplicación';

  @override
  String get pvTitle => 'Privacidad y datos';

  @override
  String get pvIntro =>
      'NOTORYX Connect no tiene cuenta, analíticas, anuncios ni servidores propios. Todo lo que guarda se queda en el almacenamiento privado de la aplicación en tu teléfono y se elimina si la desinstalas.';

  @override
  String get pvAppLock => 'Bloqueo de la aplicación';

  @override
  String get pvAppLockSub =>
      'Pide tu huella, cara o bloqueo de pantalla al abrir la aplicación y tras un minuto fuera. También lo necesitarás para llegar al SOS. La radio sigue conectada.';

  @override
  String get pvAppLockNone =>
      'Configura un bloqueo de pantalla en este teléfono para usar el bloqueo de la aplicación.';

  @override
  String get pvEncrypt => 'Cifrar el historial de chat';

  @override
  String get pvEncryptSub =>
      'Cifra los mensajes guardados con una clave que se guarda en el almacenamiento seguro del teléfono. Si se pierde esa clave, por ejemplo al cambiar de teléfono, el historial guardado no se podrá leer. Exporta antes lo que necesites.';

  @override
  String get pvStored => 'Guardado en este teléfono';

  @override
  String get pvSent => 'Enviado fuera de este teléfono';

  @override
  String get pvDeleteChats => 'Borrar el historial de chat';

  @override
  String get pvDeleteAll => 'Borrar todos los datos del teléfono';

  @override
  String pbFailed(String error) {
    return 'La operación falló: $error';
  }

  @override
  String get pbShortPassword =>
      'Usa al menos 12 caracteres para la contraseña de la copia.';

  @override
  String get pbCreated =>
      'Copia creada. Guarda el archivo fuera de este teléfono. Guarda la contraseña aparte; no se puede recuperar.';

  @override
  String get pbDisconnectFirst =>
      'Desconecta la radio antes de restaurar los datos del teléfono.';

  @override
  String get pbReplaceQ => '¿Reemplazar todos los datos del teléfono?';

  @override
  String pbSummary(
    String date,
    String version,
    int radios,
    int messages,
    int items,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      radios,
      locale: localeName,
      other: '$radios radios',
      one: '$radios radio',
    );
    return 'Copia creada el $date con la versión $version.\n\nTiene historial de chat de $_temp0 ($messages mensajes) y $items elementos guardados en total.\n\nSe reemplaza todo lo que NOTORYX Connect guarda en este teléfono (chats, colas sin conexión, NodeDex, puntos de ruta, registros de campo y ajustes). Los ajustes de la radio no cambian. La aplicación se cierra al terminar la restauración; vuelve a abrirla para continuar.';
  }

  @override
  String get pbReplace => 'Reemplazar datos del teléfono';

  @override
  String get pbRestored => 'Restauración completada';

  @override
  String get pbRestoredBody =>
      'NOTORYX Connect se cerrará ahora para que nada que siga en memoria sobrescriba los datos restaurados. Vuelve a abrirla para continuar.';

  @override
  String get pbTitle => 'Copia de seguridad del teléfono';

  @override
  String get pbIntro =>
      'Guarda una copia de todo lo que NOTORYX Connect almacena en este teléfono: historial de chat y colas sin conexión de todas las radios, favoritos y notas de NodeDex, puntos de ruta, registros de campo y ajustes. Sirve para cambiar de teléfono. El archivo se cifra con tu contraseña. Los ajustes de la radio tienen su propia copia.';

  @override
  String get pbPassword => 'Contraseña de la copia (al menos 12 caracteres)';

  @override
  String get pbCreate => 'Crear archivo de copia';

  @override
  String get pbRestore => 'Restaurar desde archivo';

  @override
  String get rbFailed =>
      'La operación falló. Si había empezado una restauración, los ajustes pueden haber cambiado en parte. Vuelve a conectar y revisa la radio antes de reintentar.';

  @override
  String get rbReady =>
      'Copia cifrada lista. Cópiala y guárdala en un archivo de texto. Guarda la contraseña aparte; no se puede recuperar.';

  @override
  String get rbReplaceQ => '¿Reemplazar los ajustes de la radio?';

  @override
  String rbSummary(
    String source,
    String firmware,
    String date,
    String target,
    int configs,
    int modules,
  ) {
    return 'Copia de la radio $source (firmware $firmware), creada el $date.\n\nDestino: $target. Reemplaza los nombres del propietario, las 8 ranuras de canal con sus claves secretas, $configs secciones de configuración y $modules módulos. No se restauran las claves de identidad y seguridad del dispositivo, las credenciales de sesión, los chats del teléfono ni los mapas (usa la copia de datos del teléfono para eso).\n\nHaz antes una copia del destino. La radio puede reiniciarse o perder la conexión con la malla. Una escritura en la radio no garantiza poder deshacerla tras un fallo de corriente o de conexión.';
  }

  @override
  String get rbReplace => 'Reemplazar ajustes';

  @override
  String get rbRadioChanged => 'La radio conectada cambió.';

  @override
  String get rbRestored =>
      'Restauración completada. La nueva lectura de la radio coincide con la copia.';

  @override
  String get rbTitle => 'Copia cifrada de la radio';

  @override
  String get rbIntro =>
      'Guarda una copia de la configuración y los módulos que informa el firmware, todas las ranuras de canal y los nombres del propietario. Las claves de canal y las credenciales de red o módulos se cifran con contraseña. Se excluyen las claves de identidad del dispositivo y las credenciales de sesión.';

  @override
  String get rbCreate => 'Crear copia cifrada';

  @override
  String get rbText => 'Texto de la copia cifrada';

  @override
  String get rbTextHint => 'Pega una copia cifrada guardada para restaurarla';

  @override
  String get rbCopied =>
      'Copia cifrada copiada. Guárdala en un archivo de texto.';

  @override
  String get rbCopy => 'Copiar copia cifrada';

  @override
  String get rbReview => 'Revisar y restaurar';

  @override
  String get raPower => 'Energía';

  @override
  String get raDisplay => 'Pantalla';

  @override
  String get raLoraQ => '¿Cambiar los ajustes LoRa a distancia?';

  @override
  String get raLoraBody =>
      'Si el nodo queda en una región, preajuste o frecuencia distinta del resto de la malla, ya no se podrá contactar y alguien tendrá que arreglarlo en persona.';

  @override
  String get raSaveAnyway => 'Guardar de todos modos';

  @override
  String raSent(String section) {
    return 'Ajustes de $section enviados. El nodo puede reiniciarse para aplicarlos.';
  }

  @override
  String get raNameSent => 'Nombre enviado al nodo.';

  @override
  String raRestartQ(String name) {
    return '¿Reiniciar $name?';
  }

  @override
  String get raRestartBody =>
      'El nodo sale de la malla un rato mientras se reinicia.';

  @override
  String get raRestart => 'Reiniciar';

  @override
  String get raRestartRequested => 'Reinicio solicitado.';

  @override
  String get raDiscardQ => '¿Descartar los cambios?';

  @override
  String get raDiscardBody => 'Tus cambios no se han enviado al nodo.';

  @override
  String get raDiscard => 'Descartar';

  @override
  String get raTitle => 'Administración remota';

  @override
  String get raIntro =>
      'Cambia los ajustes de este nodo a través de la malla. Cada petición usa tiempo de aire y puede tardar hasta un minuto.';

  @override
  String get raUnavailable => 'La administración remota no está disponible';

  @override
  String get raWaiting => 'Esperando al nodo';

  @override
  String get raAccess => 'Acceso';

  @override
  String get raAccessHint =>
      'Pide sus datos al nodo. Si responde, tu radio puede administrarlo.';

  @override
  String get raCheckAccess => 'Comprobar acceso';

  @override
  String get raAccessConfirmed => 'Acceso confirmado';

  @override
  String raFirmware(String version, String role) {
    return 'Firmware $version · $role';
  }

  @override
  String get raUnknown => 'desconocido';

  @override
  String get raNoName => 'Sin nombre';

  @override
  String raShortName(String name) {
    return 'Nombre corto $name';
  }

  @override
  String get raRename => 'Cambiar nombre';

  @override
  String get raRestartNode => 'Reiniciar nodo';

  @override
  String get raSettings => 'Ajustes';

  @override
  String get raLoraWarning =>
      'Un ajuste LoRa incorrecto puede dejar este nodo fuera de la malla. Cámbialo solo si puedes llegar al nodo en persona.';

  @override
  String raSend(String section) {
    return 'Enviar ajustes de $section';
  }

  @override
  String get raUndo => 'Deshacer';

  @override
  String get raKeyTitle => 'Clave de administración de tu radio';

  @override
  String raKeyBody(String name) {
    return 'Para que $name acepte cambios, su dueño debe añadir esta clave en Ajustes de la radio → Seguridad → Clave de administración, con cualquier aplicación de Meshtastic.';
  }

  @override
  String get raNoKey => 'Tu radio aún no ha informado su clave.';

  @override
  String get raCopyKey => 'Copiar clave de administración';

  @override
  String get raKeyCopied => 'Clave de administración copiada.';

  @override
  String get raRenameTitle => 'Cambiar el nombre del nodo';

  @override
  String get raSendButton => 'Enviar';

  @override
  String get frSaluteTitle => 'Informe SALUTE';

  @override
  String get frNineTitle => 'Evacuación médica de 9 líneas';

  @override
  String get frSaluteS => 'Tamaño';

  @override
  String get frSaluteSHint => 'Cuántas personas o vehículos';

  @override
  String get frSaluteA => 'Actividad';

  @override
  String get frSaluteAHint => 'Qué están haciendo';

  @override
  String get frSaluteL => 'Ubicación';

  @override
  String get frSaluteLHint => 'Dónde están';

  @override
  String get frSaluteU => 'Unidad';

  @override
  String get frSaluteUHint => 'Quiénes son, uniforme o distintivos';

  @override
  String get frSaluteT => 'Hora';

  @override
  String get frSaluteTHint => 'Cuándo los viste';

  @override
  String get frSaluteE => 'Equipo';

  @override
  String get frSaluteEHint => 'Qué llevan consigo';

  @override
  String get frNine1 => 'Lugar de recogida';

  @override
  String get frNine1Hint => 'Coordenadas o punto de referencia';

  @override
  String get frNine2 => 'Frecuencia de radio e indicativo';

  @override
  String get frNine2Hint => 'Cómo contactarte';

  @override
  String get frNine3 => 'Pacientes por urgencia';

  @override
  String get frNine3Hint => 'Por ejemplo 1 urgente, 2 de rutina';

  @override
  String get frNine4 => 'Equipo especial';

  @override
  String get frNine4Hint => 'Ninguno, grúa, extracción, respirador';

  @override
  String get frNine5 => 'Pacientes por tipo';

  @override
  String get frNine5Hint => 'En camilla o caminando';

  @override
  String get frNine6 => 'Seguridad en la recogida';

  @override
  String get frNine6Hint => 'Sin amenaza, posible o escolta armada';

  @override
  String get frNine7 => 'Cómo está señalizado el lugar';

  @override
  String get frNine7Hint => 'Panel, humo, luz o nada';

  @override
  String get frNine8 => 'Estado del paciente';

  @override
  String get frNine8Hint => 'Quiénes son los pacientes';

  @override
  String get frNine9 => 'Peligros y terreno';

  @override
  String get frNine9Hint => 'Pendiente, cables, contaminación';

  @override
  String get svcConnectToCheckIn => 'Conéctate a una radio para reportarte.';

  @override
  String get svcChooseContacts => 'Elige primero los contactos del viaje.';

  @override
  String get svcConnectToSos => 'Conéctate a una radio para enviar un SOS.';

  @override
  String get svcChooseSosTargets =>
      'Elige primero contactos del viaje o un canal para el SOS.';

  @override
  String svcFirmwareUnsupported(String version, String minimum, String url) {
    return 'Tu radio tiene el firmware $version. NOTORYX Connect necesita $minimum o posterior para cambiar los ajustes de la radio, así que los ajustes son de solo lectura. Los mensajes siguen funcionando. Actualízalo en $url.';
  }

  @override
  String svcFirmwareOutdated(String version, String recommended, String url) {
    return 'Tu radio tiene el firmware $version. Al actualizar a $recommended o posterior en $url se activan funciones nuevas, como las lecturas de sensores y la comprobación de claves de seguridad.';
  }

  @override
  String get svcToday => 'Hoy';

  @override
  String get svcYesterday => 'Ayer';

  @override
  String get svcLowBatteryOwn => 'La batería de tu radio está baja';

  @override
  String svcLowBattery(String name) {
    return 'La batería de $name está baja';
  }

  @override
  String svcLowBatteryOwnBody(int level) {
    return 'Tu radio informa de un $level% de batería.';
  }

  @override
  String svcLowBatteryBody(String name, int level) {
    return '$name informa de un $level% de batería.';
  }

  @override
  String svcNewNode(String name) {
    return 'Nodo nuevo: $name';
  }

  @override
  String svcNewNodeBody(String name) {
    return 'Tu radio oyó a $name por primera vez.';
  }

  @override
  String get svcMeshQuieter => 'La malla está más silenciosa';

  @override
  String svcMeshQuieterBody(int active, int peak) {
    return 'Se oyeron $active nodos en la última hora, frente a $peak. Puede que un repetidor haya caído o que te hayas alejado del alcance.';
  }

  @override
  String svcQuiet(String name) {
    return '$name está en silencio';
  }

  @override
  String svcQuietBody(String time) {
    return 'Sin noticias desde hace $time.';
  }

  @override
  String svcHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String svcMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get svcReply => 'Responder';

  @override
  String get svcDirectChannel => 'Mensajes directos';

  @override
  String get svcDirectChannelSub => 'Mensajes que te envían por la malla.';

  @override
  String get svcChannelChannel => 'Mensajes de canal';

  @override
  String get svcChannelChannelSub => 'Mensajes en tus canales de la malla.';

  @override
  String get svcFieldChannel => 'Avisos de campo';

  @override
  String get svcFieldChannelSub =>
      'Batería baja, nodos nuevos y favoritos que quedan en silencio.';

  @override
  String svcFromChannel(String sender, int channel) {
    return '$sender • canal $channel';
  }

  @override
  String mapHeatSummary(int strong, int fair, int weak, int readings) {
    return 'Mapa de cobertura: $strong zonas fuertes, $fair regulares y $weak débiles, de $readings lecturas.';
  }

  @override
  String get nrTitle => 'Pasar a una radio nueva';

  @override
  String nrSub(int done, int total) {
    return '$done de $total hechos';
  }

  @override
  String get nrStep1 =>
      'Con la radio antigua conectada, crea aquí una copia cifrada y guarda el texto en un lugar seguro.';

  @override
  String get nrStep2 =>
      'Anota la región y el preajuste de módem de la radio antigua (Ajustes de la radio → LoRa).';

  @override
  String get nrStep3 =>
      'Actualiza el firmware de la radio nueva a la misma versión o a una posterior.';

  @override
  String get nrStep4 =>
      'Conecta la radio nueva y configura primero su región, para que pueda transmitir.';

  @override
  String get nrStep5 =>
      'Pega la copia, revísala y restaura. Usa la misma contraseña.';

  @override
  String get nrStep6 =>
      'Revisa los canales: los nombres y las claves deben coincidir; envía un mensaje de prueba a alguien en cada canal.';

  @override
  String get nrStep7 =>
      'La radio nueva tiene su propio ID de nodo y su clave de seguridad. Avisa a tus contactos y vuelve a añadirla como administradora en los nodos que gestionas a distancia.';

  @override
  String get nrReset => 'Empezar de nuevo';

  @override
  String get cpLabel => 'Posición compartida en este canal';

  @override
  String get cpHelp =>
      'Qué tan exacta es la posición de tu radio al enviarse en este canal. Los demás canales tienen su propio ajuste.';

  @override
  String get cpNotSet => 'Sin configurar: decide el firmware';

  @override
  String get cpNone => 'No compartir la posición';

  @override
  String get cpExact => 'Posición exacta';

  @override
  String cpWithin(String distance) {
    return 'A unos $distance';
  }

  @override
  String get rdBattery => 'Batería de la radio';

  @override
  String get rdNotReported => 'Aún no informado.';

  @override
  String get rdExternal => 'Con alimentación externa.';

  @override
  String rdChargeNow(int level) {
    return '$level%. Carga la radio antes de salir.';
  }

  @override
  String rdChargeSoon(int level) {
    return '$level%. Plantéate cargarla o llevar una batería externa.';
  }

  @override
  String rdLevel(int level) {
    return '$level%.';
  }

  @override
  String get rdFirmware => 'Firmware';

  @override
  String get rdConnectToCheck => 'Conecta tu radio para comprobarlo.';

  @override
  String get rdTooOld => 'Demasiado antiguo.';

  @override
  String get rdUpdateRecommended => 'Se recomienda actualizar.';

  @override
  String get rdVersionUnknown => 'Versión no informada.';

  @override
  String get rdSupported => 'Compatible.';

  @override
  String get rdChannels => 'Canales';

  @override
  String get rdNoChannels => 'Esta radio no tiene canales.';

  @override
  String rdSosChannelGone(int channel) {
    return 'El canal de SOS $channel ya no existe. Elige otro en tu plan de viaje.';
  }

  @override
  String rdChannelsSet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canales configurados.',
      one: '$count canal configurado.',
    );
    return '$_temp0';
  }

  @override
  String get rdContacts => 'Contactos del viaje';

  @override
  String get rdChooseContacts => 'Elige quién recibe tus reportes y tu SOS.';

  @override
  String rdNoRoute(String names) {
    return 'No hay ruta hasta $names.';
  }

  @override
  String rdNotHeard(String names) {
    return 'Sin oír en las últimas 2 horas: $names. Haz una prueba de ruta o comprueba que estén encendidos.';
  }

  @override
  String rdAllHeard(int count) {
    return 'Los $count se oyeron hace poco.';
  }

  @override
  String get rdPosition => 'Posición';

  @override
  String get rdRecentPosition => 'Tu radio tiene una posición reciente.';

  @override
  String get rdWaitingPhone =>
      'Esperando una posición de este teléfono. Comprueba que la ubicación esté activada.';

  @override
  String get rdNoPosition =>
      'No hay una posición reciente, así que los demás no ven dónde estás. Activa el GPS de la radio o comparte la ubicación de este teléfono.';

  @override
  String get rdBackground => 'Segundo plano';

  @override
  String get rdBackgroundRestricted =>
      'La optimización de batería puede cortar la conexión con la pantalla apagada. Configura NOTORYX Connect como \"Sin restricciones\".';

  @override
  String get rdBackgroundOk =>
      'La aplicación puede seguir conectada con la pantalla apagada.';

  @override
  String get rdCouldntCheck => 'No se pudo comprobar.';

  @override
  String get rpTitle => 'Comprobación previa';

  @override
  String get rpReady => 'Listo para salir';

  @override
  String get rpCheck => 'Revisa esto antes de salir';

  @override
  String get rpNotReady => 'Aún no está listo';

  @override
  String get rpNeedRadio => 'Algunas comprobaciones necesitan tu radio';

  @override
  String get rpNotReceived =>
      'Enviado o en cola no significa recibido. Acordad un plan alternativo.';

  @override
  String get rpTestRoute => 'Probar una ruta';

  @override
  String get rpTestHint =>
      'Envía una petición de ruta a ese contacto. Úsalo con moderación en mallas con mucho tráfico.';

  @override
  String get rpRouteFound => 'Ruta encontrada';

  @override
  String get rpNoRoute => 'No se encontró ruta';

  @override
  String get rpNotTested => 'Sin probar';

  @override
  String get rpTest => 'Probar';

  @override
  String get rpStatusReady => 'Listo';

  @override
  String get rpStatusCheck => 'Revisar';

  @override
  String get rpStatusFix => 'Corregir antes';

  @override
  String get rpStatusUnknown => 'Desconocido';

  @override
  String get cdFixBluetooth => 'Activar Bluetooth';

  @override
  String get cdFixPermission => 'Permitir el acceso a Bluetooth';

  @override
  String get cdFixBattery => 'Abrir ajustes de batería';

  @override
  String get cdFixRetry => 'Reintentar';

  @override
  String get cdFixScan => 'Buscar radios';

  @override
  String get cdFixFirmware => 'Cómo actualizar';

  @override
  String get cdTheRadio => 'la radio';

  @override
  String get cdYourRadio => 'tu radio';

  @override
  String get cdBluetoothOffDetail =>
      'El Bluetooth está apagado. Actívalo y la aplicación se volverá a conectar sola.';

  @override
  String get cdPermissionDetail =>
      'La aplicación no tiene permiso para usar Bluetooth. Permite \"Dispositivos cercanos\" cuando se te pida, o en Ajustes de Android → Aplicaciones → NOTORYX Connect → Permisos.';

  @override
  String cdPairedDetail(String name) {
    return 'Puede que $name esté conectada a otro teléfono o aplicación. Una radio solo habla con un teléfono a la vez: cierra la otra aplicación o apaga el Bluetooth del otro teléfono y vuelve a intentarlo. Si sigue fallando, olvida la radio en los ajustes de Bluetooth de Android y vuelve a emparejarla.';
  }

  @override
  String cdTimeoutDetail(String name) {
    return '$name no respondió a tiempo. Acércate, comprueba que esté encendida o reiníciala y vuelve a intentarlo.';
  }

  @override
  String get cdNetworkDetail =>
      'No se pudo contactar con la radio por la red. Comprueba que el teléfono y la radio estén en la misma Wi-Fi y que la dirección y el puerto (normalmente 4403) sean correctos.';

  @override
  String get cdUsbDetail =>
      'Falló la conexión USB. Desconecta y vuelve a conectar el cable, y permite el acceso USB cuando Android lo pida.';

  @override
  String cdGaveUpDetail(String name) {
    return 'La conexión se cortó y no se pudo reconectar. Comprueba que $name esté encendida y al alcance y vuelve a intentarlo.';
  }

  @override
  String get cdNotMeshtasticDetail =>
      'El dispositivo respondió, pero no parece una radio Meshtastic o su firmware es demasiado antiguo.';

  @override
  String get cdUnknownProblem => 'Problema desconocido.';

  @override
  String get cdBluetooth => 'Bluetooth';

  @override
  String get cdOn => 'Activado.';

  @override
  String get cdBluetoothOff => 'El Bluetooth está apagado.';

  @override
  String get cdCouldntCheck => 'No se pudo comprobar.';

  @override
  String get cdAccess => 'Acceso a Bluetooth';

  @override
  String get cdAllowed => 'Permitido.';

  @override
  String get cdNotAllowed =>
      'La aplicación no tiene permiso para buscar radios y conectarse a ellas.';

  @override
  String get cdLink => 'Conexión con la radio';

  @override
  String cdConnectedTo(String name) {
    return 'Conectado a $name.';
  }

  @override
  String cdConnectingTo(String name) {
    return 'Conectando con $name…';
  }

  @override
  String get cdNoneFound =>
      'No se encontraron radios. Comprueba que la radio esté encendida y a pocos metros, que tenga el Bluetooth activado en sus ajustes y que no esté conectada a otro teléfono.';

  @override
  String get cdNotConnected => 'Sin conexión.';

  @override
  String get cdBackground => 'Segundo plano';

  @override
  String get cdBatteryOptimised =>
      'La optimización de batería puede cortar la conexión con la radio cuando la pantalla está apagada. Configura NOTORYX Connect como \"Sin restricciones\".';

  @override
  String get cdBackgroundOk =>
      'La conexión puede seguir abierta con la pantalla apagada.';

  @override
  String get cdFirmware => 'Firmware';

  @override
  String get cdFirmwareTooOld => 'Firmware demasiado antiguo.';

  @override
  String get cdSupported => 'Compatible.';

  @override
  String get cpFlasherCopied =>
      'Se copió flasher.meshtastic.org. Ábrelo en un ordenador con la radio conectada.';

  @override
  String cpFixFailed(String error) {
    return 'No funcionó: $error';
  }

  @override
  String get cpReportCopied =>
      'Informe copiado. Solo contiene datos de conexión: ni mensajes, ni claves, ni posiciones.';

  @override
  String get cpTitle => 'Diagnóstico de conexión';

  @override
  String get cpChecking => 'Comprobando…';

  @override
  String get cpNoProblems => 'No se encontraron problemas';

  @override
  String cpProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se encontraron $count problemas',
      one: 'Se encontró 1 problema',
    );
    return '$_temp0';
  }

  @override
  String get cpStillFails =>
      'Si la radio sigue sin conectarse, copia el informe de abajo y compártelo.';

  @override
  String get cpFixFirst => 'Soluciona el primer problema y vuelve a comprobar.';

  @override
  String get cpCheckAgain => 'Volver a comprobar';

  @override
  String get cpCopyReport => 'Copiar informe';

  @override
  String get cpRecentEvents => 'Eventos de conexión recientes';

  @override
  String get cpNoEvents =>
      'Nada todavía. Los eventos aparecen aquí a medida que la aplicación se conecta.';

  @override
  String get cpOk => 'Correcto';

  @override
  String get cpProblem => 'Problema';

  @override
  String get cpUnknown => 'Desconocido';

  @override
  String get sntTitle => 'Moderación comunitaria';

  @override
  String get sntToolSubtitle =>
      'Denuncia spam a los moderadores de NOTORYX y ve nodos marcados';

  @override
  String get sntIntro =>
      'Las denuncias llegan a los moderadores de NOTORYX, que revisan cada una a mano. Los bloqueos aprobados vuelven como lista orientativa: los nodos marcados llevan una etiqueta y nada se bloquea en la malla.';

  @override
  String get sntEnable => 'Usar moderación comunitaria';

  @override
  String get sntEnableSub =>
      'Desactivada por defecto. Mientras esté desactivada, NOTORYX nunca contacta con el servicio de moderación.';

  @override
  String get sntHide => 'Ocultar mensajes de remitentes marcados';

  @override
  String get sntHideSub =>
      'Solo mensajes de canal. Puedes desactivarlo cuando quieras.';

  @override
  String sntSynced(String time) {
    return 'Lista de bloqueos actualizada $time';
  }

  @override
  String get sntNeverSynced => 'Lista de bloqueos aún no descargada';

  @override
  String sntFlaggedCount(int count) {
    return 'Nodos marcados: $count';
  }

  @override
  String sntQueued(int count) {
    return 'Denuncias pendientes de envío: $count';
  }

  @override
  String get sntRefresh => 'Actualizar ahora';

  @override
  String get sntYourNode => 'Tu nodo';

  @override
  String get sntYourNodeClear => 'Tu nodo no está marcado.';

  @override
  String sntYourNodeFlagged(String caseRef) {
    return 'Tu nodo está marcado (caso $caseRef). Si es un error, puedes apelar.';
  }

  @override
  String get sntYourNodeUnknown => 'Conecta una radio para comprobar tu nodo.';

  @override
  String get sntAppealPending => 'Tu apelación está en revisión.';

  @override
  String get sntAppeal => 'Apelar';

  @override
  String get sntAppealOther => 'Apelar un caso por número';

  @override
  String get sntYourReports => 'Tus denuncias recientes';

  @override
  String get sntReport => 'Denunciar a los moderadores';

  @override
  String sntReportTitle(String name) {
    return 'Denunciar a $name';
  }

  @override
  String get sntReasonSpam => 'Spam o publicidad';

  @override
  String get sntReasonFlooding => 'Saturar la malla';

  @override
  String get sntReasonAbuse => 'Acoso o abuso';

  @override
  String get sntReasonImpersonation => 'Suplantación';

  @override
  String get sntReasonOther => 'Otro';

  @override
  String get sntNote => 'Detalles (opcional)';

  @override
  String get sntIncludeMessage => 'Incluir este mensaje';

  @override
  String get sntSends =>
      'Envía el ID y el nombre del nodo, tu motivo y, si está marcado, este mensaje. No tu nombre, clave ni ubicación.';

  @override
  String get sntSend => 'Enviar denuncia';

  @override
  String sntSent(String caseRef) {
    return 'Denuncia enviada ($caseRef)';
  }

  @override
  String get sntQueuedOne => 'Sin conexión. La denuncia se enviará más tarde.';

  @override
  String sntRejected(String message) {
    return 'Denuncia no aceptada: $message';
  }

  @override
  String get sntOffPrompt => '¿Activar la moderación comunitaria?';

  @override
  String get sntTurnOn => 'Activar';

  @override
  String get sntFlagged => 'Marcado';

  @override
  String sntFlaggedHint(String caseRef) {
    return 'Marcado por los moderadores de NOTORYX (caso $caseRef). Solo orientativo.';
  }

  @override
  String get sntCaseRef => 'Número de caso (SNT-1234)';

  @override
  String get sntStatement => '¿Por qué debería levantarse el bloqueo?';

  @override
  String get sntContact => 'Contacto (opcional, solo lo ven los moderadores)';

  @override
  String get sntAppealSend => 'Enviar apelación';

  @override
  String get sntAppealReceived =>
      'Apelación enviada. Un moderador la revisará.';

  @override
  String get sntAppealUnknown => 'Ningún caso de Meshtastic tiene ese número.';

  @override
  String get sntAppealNotOpen =>
      'Ese caso no tiene un bloqueo activo o ya hay una apelación pendiente.';

  @override
  String get sntAppealTooMany =>
      'Demasiadas apelaciones. Inténtalo de nuevo en un minuto.';

  @override
  String get sntFailed =>
      'No se pudo contactar con el servicio de moderación. Inténtalo más tarde.';

  @override
  String get pvSent7 =>
      'Denuncias, apelaciones y consultas de la lista de bloqueos a los moderadores de NOTORYX a través de sentinel-relay.meshmayhem.org, solo si activas la moderación comunitaria';

  @override
  String get psTitle => 'Buscar un lugar';

  @override
  String get psHint => 'Nodo, punto de ruta o lugar';

  @override
  String get psNoLocal =>
      'Ningún nodo ni punto de ruta coincide. Prueba a buscar en línea.';

  @override
  String get psOnlineNote =>
      'La búsqueda en línea envía lo que escribiste al servicio Nominatim de OpenStreetMap, que también ve tu dirección IP. Necesita acceso a internet.';

  @override
  String get psSearchOnline => 'Buscar en línea';

  @override
  String get psTooSoon =>
      'Espera un segundo antes de volver a buscar en línea.';

  @override
  String get psOnlineFailed =>
      'No se pudo buscar en línea. Comprueba que el teléfono tenga acceso a internet y vuelve a intentarlo.';

  @override
  String get psNoOnline => 'No se encontraron lugares en línea.';

  @override
  String get psAttribution =>
      'Datos de lugares © colaboradores de OpenStreetMap';

  @override
  String get psKindNode => 'Nodo';

  @override
  String get psKindWaypoint => 'Punto de ruta';

  @override
  String get psKindOnline => 'Lugar';

  @override
  String get mapFindPlace => 'Buscar un lugar';

  @override
  String mapFoundPin(String name) {
    return 'Encontrado: $name';
  }

  @override
  String get pvSent8 =>
      'Lo que escribes en Buscar un lugar, al servicio Nominatim de OpenStreetMap, solo cuando pulsas Buscar en línea; ve tu dirección IP';

  @override
  String get nodesFavoritesOnly => 'Solo favoritos';

  @override
  String get nodesNoFavorites => 'Aún no hay favoritos';

  @override
  String get nodesNoFavoritesHint =>
      'Abre un nodo y toca su estrella para confiar en él. Solo favoritos mostrará únicamente a las personas de confianza.';

  @override
  String get mapShowAllNodes => 'Mostrar todos los nodos';
}
