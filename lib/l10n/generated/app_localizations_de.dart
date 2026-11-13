// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get tabHome => 'Start';

  @override
  String get tabNodes => 'Knoten';

  @override
  String get tabChats => 'Chats';

  @override
  String get tabMap => 'Karte';

  @override
  String get tabTools => 'Werkzeuge';

  @override
  String get tabSettings => 'Einstellungen';

  @override
  String get connOffline => 'Offline';

  @override
  String get connScanning => 'Suche';

  @override
  String get connConnecting => 'Verbinden';

  @override
  String get connSyncing => 'Synchronisieren';

  @override
  String get connConnected => 'Verbunden';

  @override
  String get connError => 'Fehler';

  @override
  String radioStatus(String status) {
    return 'Funkgerät: $status';
  }

  @override
  String radioStatusTip(String status) {
    return 'Funkgerät: $status. Tippen zum Verwalten.';
  }

  @override
  String get radioStatusHint => 'Funkgerät verwalten';

  @override
  String get toolsTitle => 'Werkzeuge';

  @override
  String get toolsSubtitle =>
      'Hilfsmittel zum Planen, Testen und Durchführen eines Einsatzes.';

  @override
  String get toolsDoctor => 'Verbindungsdiagnose';

  @override
  String get toolsDoctorSub =>
      'Herausfinden, warum ein Funkgerät keine Verbindung herstellt oder sie verliert';

  @override
  String get toolsBeforeYouGo => 'Vor dem Aufbruch';

  @override
  String get toolsChecklist => 'Einsatz-Checkliste';

  @override
  String get toolsBattery => 'Akkulaufzeit';

  @override
  String get toolsBatterySub =>
      'Stunden aus Kapazität und durchschnittlichem Verbrauch schätzen';

  @override
  String get toolsCalculate => 'Berechnen';

  @override
  String get toolsMeshTools => 'Mesh-Werkzeuge';

  @override
  String get toolsHealth => 'Mesh-Zustand und Sendezeit';

  @override
  String get toolsHealthSub =>
      'Wie ausgelastet der Kanal ist und wie viel Ihr Funkgerät sendet';

  @override
  String get toolsLink => 'Verbindungsplaner';

  @override
  String get toolsLinkSub =>
      'Sichtverbindung zwischen zwei Knoten über das Gelände prüfen';

  @override
  String get toolsRange => 'Reichweitentest';

  @override
  String get toolsRangeSub =>
      'Pakete eines Reichweitentest-Senders mit Signal und Entfernung protokollieren';

  @override
  String get toolsTraceroute => 'Traceroute';

  @override
  String get toolsStore => 'Speichern und Weiterleiten';

  @override
  String get toolsStoreSub =>
      'Verpasste Nachrichten von einem Router erneut abspielen';

  @override
  String get toolsBeacons => 'Mesh-Baken';

  @override
  String get toolsRecords => 'Aufzeichnungen';

  @override
  String get toolsIncident => 'Einsatzprotokoll, Vorlagen und Abdeckung';

  @override
  String get toolsIncidentSub => 'Gespeicherte Feldaufzeichnungen und Exporte';

  @override
  String get toolsSignal => 'Signal';

  @override
  String get toolsTelemetry => 'Live-Telemetrie';

  @override
  String get toolsNothingYet =>
      'Noch nichts empfangen. Messwerte erscheinen, sobald Knoten sie senden.';

  @override
  String get toolsGuide => 'Leitfaden zum Bluetooth-Signal';

  @override
  String get toolsGuideSub => 'Was die Signalwerte (RSSI) bedeuten';

  @override
  String get toolsScan => 'Nach Funkgeräten suchen';

  @override
  String get toolsCheck0 => 'Funkgerät geladen';

  @override
  String get toolsCheck1 => 'Antenne angeschlossen';

  @override
  String get toolsCheck2 => 'Region eingestellt';

  @override
  String get toolsCheck3 => 'Primärkanal geprüft';

  @override
  String get toolsCheck4 => 'GPS / Positionsregeln geprüft';

  @override
  String toolsReady(int done, int total) {
    return '$done von $total bereit';
  }

  @override
  String get toolsBatteryField => 'Akku (mAh)';

  @override
  String get toolsDrawField => 'Durchschnittlicher Verbrauch (mA)';

  @override
  String toolsAboutHours(String hours) {
    return 'Etwa $hours Stunden';
  }

  @override
  String get toolsTraceReady =>
      'Den Relaisweg zu einem Knoten und zurück anzeigen';

  @override
  String get toolsTraceOff =>
      'Verbinden Sie ein Funkgerät, um Routen zu verfolgen';

  @override
  String get toolsBeaconsSub =>
      'Mesh-Einladungen in der Nähe hören und eigene senden';

  @override
  String toolsBeaconsHeard(int count) {
    return '$count gehört • eigene senden';
  }

  @override
  String toolsReporting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Knoten melden Gerätewerte',
      one: '$count Knoten meldet Gerätewerte',
    );
    return '$_temp0';
  }

  @override
  String get toolsTelemetryOff =>
      'Verbinden Sie ein Funkgerät, um Telemetrie zu empfangen';

  @override
  String toolsBatteryPct(int pct) {
    return 'Akku $pct %';
  }

  @override
  String toolsChannelBusy(String pct) {
    return 'Kanal belegt $pct %';
  }

  @override
  String toolsTransmitting(String pct) {
    return 'Senden $pct %';
  }

  @override
  String get toolsSigExcellent => 'Ausgezeichnet, sehr nah';

  @override
  String get toolsSigStrong => 'Stark';

  @override
  String get toolsSigUsable => 'Brauchbar';

  @override
  String get toolsSigWeak => 'Schwach';

  @override
  String get toolsSigVeryWeak => 'Sehr schwach, kann abbrechen';

  @override
  String get toolsScanning => 'Suche…';

  @override
  String toolsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bluetooth-Geräte gefunden',
      one: '$count Bluetooth-Gerät gefunden',
    );
    return '$_temp0';
  }

  @override
  String get deliveryReceived => 'Empfangen';

  @override
  String get deliveryQueued => 'In Warteschlange';

  @override
  String get deliverySent => 'Gesendet';

  @override
  String get deliveryDelivered => 'Zugestellt';

  @override
  String get deliveryFailed => 'Nicht zugestellt';

  @override
  String get hopsDirect => 'Direkt';

  @override
  String hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sprünge',
      one: '$count Sprung',
    );
    return '$_temp0';
  }

  @override
  String get chatsNoMention =>
      'Noch keine Knoten gehört, die erwähnt werden können.';

  @override
  String get chatsMentionNode => 'Einen Knoten erwähnen';

  @override
  String get chatsViaMqttFull =>
      'Über MQTT (das Internet) angekommen, nicht über Funk';

  @override
  String get chatsPathUnknown =>
      'Weg von der Firmware des Absenders nicht gemeldet';

  @override
  String get chatsHeardDirect => 'Direkt gehört, ohne Relais';

  @override
  String chatsLastThrough(String name) {
    return ', zuletzt über $name';
  }

  @override
  String chatsLastThroughEnding(String hex) {
    return ', zuletzt über einen Knoten, der auf $hex endet';
  }

  @override
  String chatsCameThrough(int hops, String via) {
    String _temp0 = intl.Intl.pluralLogic(
      hops,
      locale: localeName,
      other: 'Über $hops Relais gekommen$via',
      one: 'Über $hops Relais gekommen$via',
    );
    return '$_temp0';
  }

  @override
  String get chatsReact => 'Reagieren';

  @override
  String chatsReactEmoji(String emoji) {
    return 'Mit $emoji reagieren';
  }

  @override
  String get chatsNoSignal => 'Kein Signalwert';

  @override
  String get chatsUnpin => 'Lösen';

  @override
  String get chatsPin => 'Anheften';

  @override
  String get chatsCopyText => 'Text kopieren';

  @override
  String get chatsCopied => 'Nachricht kopiert';

  @override
  String chatsReactionFailed(String error) {
    return 'Reaktion nicht gesendet: $error';
  }

  @override
  String chatsSendFailed(String error) {
    return 'Nachricht nicht gesendet: $error';
  }

  @override
  String get chatsYou => 'Sie';

  @override
  String get chatsYouLower => 'Sie';

  @override
  String chatsChannelN(int n) {
    return 'Kanal $n';
  }

  @override
  String get chatsReactHint => 'auf diese Nachricht reagieren';

  @override
  String get chatsViaMqtt => 'über MQTT';

  @override
  String get chatsPinned => 'Angeheftet';

  @override
  String get chatsMentionsYou => 'Erwähnt Sie';

  @override
  String chatsReactions(String list) {
    return 'Reaktionen: $list';
  }

  @override
  String chatsReactionFrom(String emoji, String name) {
    return '$emoji von $name';
  }

  @override
  String get chatsConnectedSub =>
      'Verbunden. Nachrichten werden sofort gesendet.';

  @override
  String get chatsOfflineSub =>
      'Offline. Nachrichten warten in einer Warteschlange und werden gesendet, sobald Ihr Funkgerät verbunden ist.';

  @override
  String get chatsStorageProblem => 'Problem beim Speichern der Nachrichten';

  @override
  String get chatsFilterShowing =>
      'Nachrichten, die Ihren Wortfiltern entsprechen, werden angezeigt';

  @override
  String chatsFilterHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Nachrichten durch Ihre Wortfilter ausgeblendet',
      one: '$count Nachricht durch Ihre Wortfilter ausgeblendet',
    );
    return '$_temp0';
  }

  @override
  String get chatsHide => 'Ausblenden';

  @override
  String get chatsShow => 'Anzeigen';

  @override
  String get chatsStatLink => 'Verbindung';

  @override
  String get chatsOnline => 'Online';

  @override
  String get chatsStatMessages => 'Nachrichten';

  @override
  String get chatsStatQueued => 'Wartend';

  @override
  String get chatsNewMessage => 'Neue Nachricht';

  @override
  String get chatsKeyChanged => 'Sicherheitsschlüssel geändert';

  @override
  String chatsKeyChangedBody(String name) {
    return '$name zeigt jetzt einen anderen Schlüssel. Fragen Sie beim Besitzer nach, bevor Sie etwas Privates senden. Öffnen Sie den Knoten, um den neuen Schlüssel zu prüfen oder ihm zu vertrauen.';
  }

  @override
  String get chatsTo => 'An';

  @override
  String get chatsEveryone => 'Alle auf dem Kanal';

  @override
  String chatsDirect(String name) {
    return 'Direkt • $name';
  }

  @override
  String get chatsChannelLabel => 'Kanal';

  @override
  String get chatsChannelBroadcast => 'Kanal 0 • Rundruf';

  @override
  String chatsChannelOffline(int n) {
    return 'Kanal $n • Offline';
  }

  @override
  String chatsChannelNamed(int n, String name) {
    return 'Kanal $n • $name';
  }

  @override
  String get chatsDefault => 'Standard';

  @override
  String chatsMessageChannel(int n) {
    return 'Nachricht an Kanal $n';
  }

  @override
  String chatsMessageNode(String name) {
    return 'Nachricht an $name';
  }

  @override
  String get chatsSend => 'Senden';

  @override
  String get chatsQuickReplies => 'Schnellantworten';

  @override
  String get chatsMessages => 'Nachrichten';

  @override
  String get chatsHoldHint => 'Nachricht gedrückt halten für mehr';

  @override
  String get chatsSearch => 'Nachrichtenverlauf durchsuchen';

  @override
  String get chatsClearSearch => 'Suche löschen';

  @override
  String get chatsNoMatches => 'Keine Treffer';

  @override
  String get chatsNoMatchesBody => 'Keine Nachricht entspricht Ihrer Suche.';

  @override
  String get chatsEmpty => 'Noch keine Mesh-Nachrichten';

  @override
  String get chatsEmptyBody =>
      'Kanal- und Direktnachrichten erscheinen hier, sobald Ihr Funkgerät sie hört.';

  @override
  String get chatsNewAbove => 'Neue Nachrichten oben';

  @override
  String get chatsAutoReplies => 'Automatische Antworten';

  @override
  String get chatsBot => 'Bot-Modus';

  @override
  String get chatsBotOn =>
      'An. Beantwortet Direktnachrichten sowie !help und !status, innerhalb der Ruhezeiten und Sendezeitgrenzen.';

  @override
  String get chatsBotOff =>
      'Aus. Es werden keine automatischen Antworten gesendet.';

  @override
  String get chatsBotReply => 'Bot-Antwortnachricht';

  @override
  String get chatsBotReplyField => 'Nachricht, die im Bot-Modus gesendet wird';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonConnect => 'Verbinden';

  @override
  String get commonDisconnect => 'Trennen';

  @override
  String get agoNow => 'gerade eben';

  @override
  String agoMin(int n) {
    return 'vor $n Min.';
  }

  @override
  String agoHours(int n) {
    return 'vor $n Std.';
  }

  @override
  String agoDays(int n) {
    return 'vor $n T.';
  }

  @override
  String get rssiStrong => 'Starkes Bluetooth-Signal';

  @override
  String get rssiUsable => 'Brauchbares Bluetooth-Signal';

  @override
  String get rssiWeak => 'Schwaches Bluetooth-Signal';

  @override
  String get rssiVeryWeak => 'Sehr schwaches Bluetooth-Signal';

  @override
  String get heardAny => 'Jederzeit';

  @override
  String get heardHour => '1 Stunde';

  @override
  String get heardDay => '24 Stunden';

  @override
  String get heardWeek => '7 Tage';

  @override
  String nodesConnectFailed(String error) {
    return 'Verbindung fehlgeschlagen: $error';
  }

  @override
  String nodesUsbFailed(String error) {
    return 'USB-Verbindung fehlgeschlagen: $error';
  }

  @override
  String nodesNotesFor(String name) {
    return 'Notizen zu $name';
  }

  @override
  String get nodesNotesHint => 'Standort, Antenne, Beobachtungen…';

  @override
  String nodesConnectedTo(String name) {
    return 'Verbunden mit $name.';
  }

  @override
  String get nodesYourRadio => 'Ihr Funkgerät';

  @override
  String get nodesFindRadio =>
      'Finden Sie Ihr Funkgerät in der Nähe und verbinden Sie sich per Bluetooth.';

  @override
  String get nodesRadiosFound => 'Gefundene Funkgeräte';

  @override
  String get nodesMeshNodes => 'Mesh-Knoten';

  @override
  String get nodesStatus => 'Status';

  @override
  String get nodesConnProblem => 'Verbindungsproblem';

  @override
  String get nodesDiagnose => 'Diagnose';

  @override
  String get nodesNearby => 'Funkgeräte in der Nähe';

  @override
  String get nodesLooking => 'Suche nach Funkgeräten…';

  @override
  String get nodesStopScan => 'Suche beenden';

  @override
  String get nodesRadio => 'Funkgerät';

  @override
  String get nodesOverUsb => 'Über USB';

  @override
  String get nodesOverWifi => 'Über WLAN';

  @override
  String get nodesConnectWifi => 'Über WLAN verbinden';

  @override
  String get nodesConnectUsb => 'Über USB verbinden';

  @override
  String get nodesNoRadios => 'Noch keine Funkgeräte gefunden';

  @override
  String get nodesNoRadiosBody =>
      'Schalten Sie Ihr Funkgerät ein, halten Sie es in der Nähe und tippen Sie dann auf Nach Funkgeräten suchen.';

  @override
  String get nodesTryDemo => 'Kein Funkgerät? Demo ausprobieren';

  @override
  String get nodesMeshtasticRadio => 'Meshtastic-Funkgerät';

  @override
  String get nodesBluetoothDevice => 'Bluetooth-Gerät';

  @override
  String nodesCount(int count) {
    return 'Mesh-Knoten ($count)';
  }

  @override
  String nodesCountOf(int shown, int total) {
    return 'Mesh-Knoten ($shown von $total)';
  }

  @override
  String nodesNoneHeard(String window) {
    return 'Keine Knoten gehört in den letzten $window';
  }

  @override
  String get nodesPickLonger =>
      'Wählen Sie einen längeren Zeitraum, um ältere Knoten zu sehen.';

  @override
  String get nodesShowAll => 'Alle Knoten anzeigen';

  @override
  String get nodesHealth => 'Mesh-Zustand';

  @override
  String get nodesDetails => 'Details';

  @override
  String get nodesKnown => 'Bekannte Knoten';

  @override
  String get nodesWaiting => 'Wartet auf Senden';

  @override
  String get nodesSignalQuality => 'Signalqualität';

  @override
  String nodesSignalSummary(int count, String snr) {
    return '$count Nachrichten gehört • letzter Signal-Rausch-Abstand $snr';
  }

  @override
  String get nodesNotMeasured => 'noch nicht gemessen';

  @override
  String nodesSignalHistory(int count) {
    return 'Signalverlauf der letzten $count Nachrichten';
  }

  @override
  String get nodesSignalStarts =>
      'Der Signalverlauf beginnt, wenn ein anderer Knoten eine Nachricht sendet.';

  @override
  String get nodesMeasuredFrom =>
      'Nur aus empfangenen Textnachrichten gemessen.';

  @override
  String get nodesEncounters => 'Gespeicherte Begegnungen';

  @override
  String nodesSeen(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count-mal gesehen • zuletzt $when',
      one: '$count-mal gesehen • zuletzt $when',
    );
    return '$_temp0';
  }

  @override
  String get nodesTapNotes => 'Tippen, um Notizen hinzuzufügen';

  @override
  String get nodesRemoveFav => 'Aus Favoriten entfernen';

  @override
  String get nodesAddFav => 'Zu Favoriten hinzufügen';

  @override
  String get nodesMore => 'Mehr';

  @override
  String get nodesFieldTools => 'Feldwerkzeuge';

  @override
  String get nodesFieldToolsSub =>
      'Signalreferenz, Checklisten, Sicherungen und mehr';

  @override
  String get nodesReadyBanner =>
      'Ihr Funkgerät ist verbunden. Knoten werden live aktualisiert, sobald sie gehört werden.';

  @override
  String get nodesHelpBanner =>
      'Tippen Sie auf Nach Funkgeräten suchen und dann auf Verbinden. Die App prüft, ob es ein Meshtastic-Funkgerät ist, und lädt seine Knotenliste, bevor es bereit ist.';

  @override
  String get nodesHeardWithin =>
      'Knoten anzeigen, die gehört wurden innerhalb von';

  @override
  String get nodesWifiHelp =>
      'Für Funkgeräte mit eingeschaltetem WLAN oder Ethernet. Ihr Telefon muss im selben Netzwerk sein.';

  @override
  String get nodesAddress => 'Adresse des Funkgeräts';

  @override
  String get nodesAddressHint => 'z. B. 192.168.1.42 oder meshtastic.local';

  @override
  String get nodesPort => 'Port';

  @override
  String get nodesPortHelp => 'Meshtastic verwendet 4403';

  @override
  String get nodesUsbHelp =>
      'Schließen Sie das Funkgerät mit einem USB-Datenkabel an das Telefon an (eventuell ist ein OTG-Adapter nötig). Android fragt beim ersten Mal nach der Erlaubnis.';

  @override
  String nodesUsbListFailed(String error) {
    return 'USB-Geräte konnten nicht aufgelistet werden: $error';
  }

  @override
  String get nodesNoUsb => 'Keine USB-Geräte gefunden';

  @override
  String get nodesNoUsbBody =>
      'Prüfen Sie, ob das Kabel Daten überträgt und nicht nur Strom, und aktualisieren Sie dann.';

  @override
  String nodesLikelyRadio(String chip) {
    return 'Wahrscheinlich ein Funkgerät • $chip';
  }

  @override
  String get nodesOtherUsb => 'Anderes USB-Gerät';

  @override
  String get nodesRefresh => 'Aktualisieren';

  @override
  String get setRadioSec => 'Funkgerät';

  @override
  String get setRadioConfig => 'Funkgerätekonfiguration';

  @override
  String get setIdentity => 'Knotenidentität';

  @override
  String get setChange => 'Funkgeräteeinstellungen ändern';

  @override
  String get setChangeSub => 'Besitzer, LoRa, Kanäle, Geräterolle und Position';

  @override
  String get setDeviceLora => 'Gerät und LoRa';

  @override
  String get setChannels => 'Kanäle';

  @override
  String get setModules => 'Module';

  @override
  String get setShareLoc => 'Telefonstandort mit dem Mesh teilen';

  @override
  String get setPrecision => 'Standortgenauigkeit';

  @override
  String get setPrecisionSub =>
      'Wird auf diesem Telefon vor dem Senden gerundet';

  @override
  String get setLowPower => 'Stromsparender Feldmodus';

  @override
  String get setApp => 'App';

  @override
  String get setWidget => 'Nachrichten im Startbildschirm-Widget anzeigen';

  @override
  String get setYourData => 'Ihre Daten';

  @override
  String get setRadioBackup => 'Verschlüsselte Funkgerätesicherung';

  @override
  String get setRadioBackupSub =>
      'Einstellungen und Kanalschlüssel speichern oder wiederherstellen, durch ein Passwort geschützt';

  @override
  String get setPhoneBackup => 'Sicherung der Telefondaten';

  @override
  String get setPhoneBackupSub =>
      'Chats, Knoten, Wegpunkte, Aufzeichnungen und Einstellungen, für den Umzug auf ein neues Telefon';

  @override
  String get setPrivacy => 'Datenschutz und Daten';

  @override
  String get setPrivacySub =>
      'Was gespeichert und gesendet wird; Chatverlauf oder alle Telefondaten löschen';

  @override
  String get setDemo => 'Demomodus';

  @override
  String get setAbout => 'Über';

  @override
  String get setLicenses => 'Lizenzen von Drittanbietern';

  @override
  String get setReadAloud => 'Nachrichten vorlesen';

  @override
  String get setReadSub =>
      'Nutzt die Sprachausgabe des Telefons, auch bei ausgeschaltetem Bildschirm';

  @override
  String get setMqttTitle => 'MQTT über dieses Telefon leiten';

  @override
  String get setBackground => 'Verbindung im Hintergrund';

  @override
  String get setOpenSettings => 'Einstellungen öffnen';

  @override
  String get setOfflineTiles => 'Offline-Kartenkacheln';

  @override
  String get setClear => 'Löschen';

  @override
  String get setAlerts => 'Feldwarnungen';

  @override
  String get setAlertsSub =>
      'Nur Telefonbenachrichtigungen; nichts wird über das Mesh gesendet';

  @override
  String get setLowBattery => 'Akku schwach';

  @override
  String get setThreshold => 'Akkuschwelle';

  @override
  String get setNewNode => 'Neuer Knoten';

  @override
  String get setNewNodeSub => 'Ihr Funkgerät hört einen Knoten zum ersten Mal';

  @override
  String get setFavQuiet => 'Ein Favorit verstummt';

  @override
  String get setMeshQuiet => 'Das Mesh verstummt';

  @override
  String get setMeshQuietSub =>
      'Die Hälfte oder mehr der gehörten Knoten sind nicht mehr zu hören';

  @override
  String get setQuietAfter => 'Still nach';

  @override
  String get setRadioData => 'Funkgerätedaten';

  @override
  String get setRadioDataSub =>
      'Funkgerät verloren oder ersetzt? Nachrichten, Knoten und Verlauf auf das neue übertragen';

  @override
  String get setMoveToConnected => 'Auf das verbundene übertragen';

  @override
  String get setDataUnreadable =>
      'Die Funkgerätedaten konnten nicht gelesen werden.';

  @override
  String get setNoData => 'Noch keine Funkgerätedaten auf diesem Telefon.';

  @override
  String get setFilters => 'Filter';

  @override
  String get setFilterHelp =>
      'Eingehende Nachrichten mit diesen Wörtern werden ausgeblendet, nicht gelöscht.';

  @override
  String get setShowFiltered => 'Gefilterte Nachrichten anzeigen';

  @override
  String get setIgnored => 'Ignoriert';

  @override
  String get setUnignore => 'Nicht mehr ignorieren';

  @override
  String get setMuted => 'Stummgeschaltet';

  @override
  String get setUnmute => 'Stummschaltung aufheben';

  @override
  String get setOffLoc => 'Aus. Ihr Telefonstandort wird nie gesendet.';

  @override
  String get setOnNoRadio => 'An. Startet, sobald ein Funkgerät verbunden ist.';

  @override
  String get setOnNoFix => 'An. Wartet auf einen GPS-Fix.';

  @override
  String setOnSent(String time) {
    return 'An. Zuletzt gesendet um $time.';
  }

  @override
  String get setSubtitle =>
      'Ihr Funkgerät, das Verhalten der App und Ihre Daten.';

  @override
  String get setCanChange => 'Verbunden • Einstellungen können geändert werden';

  @override
  String setReadOnly(String version, String minimum, String url) {
    return 'Nur lesen: Firmware $version ist älter als $minimum. Aktualisieren unter $url.';
  }

  @override
  String get setConnectToView =>
      'Verbinden Sie ein Funkgerät, um seine Einstellungen anzuzeigen und zu ändern';

  @override
  String get setWaitingNode =>
      'Warte auf die Knoteninformationen dieses Funkgeräts';

  @override
  String get setNoLong => 'Kein langer Name';

  @override
  String get setNoShort => 'Kein Kurzname';

  @override
  String get setNoId => 'ID nicht gemeldet';

  @override
  String setConfigWait(int count) {
    return 'Noch nicht empfangen ($count Konfigurationsnachrichten)';
  }

  @override
  String setChannelWait(int count) {
    return 'Noch nicht empfangen ($count Kanalnachrichten)';
  }

  @override
  String setModulesSub(int count) {
    return '$count Modulnachrichten empfangen. Ändern Sie sie in den Funkgeräteeinstellungen.';
  }

  @override
  String setShareLocSub(String status) {
    return '$status\nWird verwendet, wenn das Funkgerät kein eigenes GPS hat. Aktualisiert alle 5 Min. oder früher, wenn Sie sich bewegen.';
  }

  @override
  String get setPrecise => 'Genau';

  @override
  String setAbout2(String distance) {
    return 'Etwa $distance';
  }

  @override
  String get setLowPowerSub =>
      'Der geteilte Standort nutzt ausgewogenes GPS und aktualisiert alle 15 Min. oder nach 200 m Bewegung. Funkverbindung und Abdeckungsaufzeichnung bleiben unverändert.';

  @override
  String get setWidgetSub =>
      'Aus: Das Widget zeigt nur, wie viele Nachrichten ungelesen sind. An: Es zeigt auch Absender und Text, die jeder sehen kann, der das Telefon in der Hand hält.';

  @override
  String get setDemoSub =>
      'Erkunden Sie die App mit einem simulierten Funkgerät und Mesh. Nichts wird gesendet, und Ihre eigenen Nachrichten und Einstellungen bleiben unberührt.';

  @override
  String get setDevBuild => 'Entwicklungsversion • Unabhängiger Mesh-Begleiter';

  @override
  String get setConnection => 'Verbindung';

  @override
  String get setConnectionSub =>
      'Bluetooth LE • Sicherheitsmodus an: Kein ungeprüftes Gerät wird als Mesh-Knoten behandelt';

  @override
  String get setTrademark => 'Marken und Kompatibilität';

  @override
  String get setDevWarning =>
      'Verlassen Sie sich nicht auf diese Entwicklungsversion als einzige Möglichkeit, Hilfe zu rufen.';

  @override
  String get setChannelsKept => 'Kanalnachrichten werden behalten';

  @override
  String setChannelsDeleted(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Kanalnachrichten werden nach $days Tagen gelöscht',
      one: 'Kanalnachrichten werden nach $days Tag gelöscht',
    );
    return '$_temp0';
  }

  @override
  String setNewestPer(String count) {
    return 'die neuesten $count pro Unterhaltung';
  }

  @override
  String get setReadOn => 'Vorlesen an';

  @override
  String get setDeleteOld => 'Alte Kanalnachrichten löschen';

  @override
  String get setDirectKept => 'Direktnachrichten werden immer behalten';

  @override
  String get setNever => 'Nie';

  @override
  String setAfterDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Nach $days Tagen',
      one: 'Nach $days Tag',
    );
    return '$_temp0';
  }

  @override
  String get setHistory => 'Nachrichtenverlauf';

  @override
  String get setHistoryHelp =>
      'Pro Kanal oder Direktunterhaltung. Eine niedrigere Grenze löscht ältere Nachrichten.';

  @override
  String setKeepNewest(String count) {
    return 'Die neuesten $count behalten';
  }

  @override
  String get setMqttOff =>
      'Aus. Nutzt im eingeschalteten Zustand die mobilen Daten Ihres Telefons.';

  @override
  String get setMqttWait => 'An. Wartet auf Ihr Funkgerät.';

  @override
  String get setMqttNoConfig =>
      'Ihr Funkgerät ist dafür nicht eingerichtet. Schalten Sie in seinen Einstellungen MQTT und „Proxy to client\" ein.';

  @override
  String setMqttConnected(String host, int up, int down, String kb) {
    return 'Verbunden mit $host. $up gesendet, $down empfangen, etwa $kb KB Daten.';
  }

  @override
  String setMqttConnecting(String host) {
    return 'Verbinde mit $host…';
  }

  @override
  String get setMqttFailed => 'Verbindung fehlgeschlagen.';

  @override
  String get setMqttStarting => 'Wird gestartet…';

  @override
  String get setBgOptimized =>
      'Die Akkuoptimierung kann NOTORYX Connect anhalten, wenn es nicht im Vordergrund ist, und die Funkverbindung trennen. Stellen Sie die Akkunutzung auf Uneingeschränkt, um verbunden zu bleiben.';

  @override
  String get setBgAllowed =>
      'Darf im Hintergrund laufen. Solange ein Funkgerät verbunden ist, wird eine Benachrichtigung angezeigt.';

  @override
  String get setSizeUnknown => 'Größe unbekannt';

  @override
  String setMbSaved(String mb) {
    return '$mb MB gespeichert';
  }

  @override
  String get setTilesHelp =>
      'Online angesehene Kartenbereiche bleiben ein Jahr lang offline verfügbar (bis zu 500 MB).';

  @override
  String get setAlertSaveFailed =>
      'Die Warneinstellungen gelten jetzt, konnten aber nicht gespeichert werden.';

  @override
  String setLowBatterySub(int pct) {
    return 'Ihr Funkgerät oder ein Favorit meldet $pct % oder weniger';
  }

  @override
  String setFavQuietSub(String time) {
    return 'Ein Favorit ist $time lang nicht zu hören, während Sie verbunden sind';
  }

  @override
  String get setTheConnected => 'das verbundene Funkgerät';

  @override
  String setMoveTitle(String label) {
    return '$label übertragen?';
  }

  @override
  String setMoveBody(String to, String id) {
    return 'Nachrichten, Offline-Warteschlange, NodeVault-Verlauf, Spuren und Telemetrieverlauf gehen auf $to über. Was $to bereits hat, bleibt erhalten, es wird also nichts überschrieben. $id hat danach keinen eigenen Eintrag mehr.\n\nErstellen Sie sicherheitshalber zuerst eine Sicherung der Telefondaten.';
  }

  @override
  String get setMove => 'Übertragen';

  @override
  String setMoved(String label, String to) {
    return '$label auf $to übertragen.';
  }

  @override
  String setDataCounts(int messages, int nodes, int trails) {
    return '$messages Nachrichten • $nodes Knoten • $trails Spuren';
  }

  @override
  String get setConnectNew =>
      'Verbinden Sie das neue Funkgerät, um die Daten eines alten darauf zu übertragen.';

  @override
  String setFilterCounts(int ignored, int muted, int words) {
    return '$ignored ignoriert • $muted stumm • $words gefilterte Wörter';
  }

  @override
  String get setFilteredWords => 'Gefilterte Wörter';

  @override
  String get setWordField => 'Wort oder Ausdruck';

  @override
  String get setAddWord => 'Gefiltertes Wort hinzufügen';

  @override
  String setRemoveWord(String word) {
    return '$word entfernen';
  }

  @override
  String get setIgnoredMuted => 'Ignorierte und stummgeschaltete Knoten';

  @override
  String get setNoneIgnored =>
      'Keine. Öffnen Sie einen Knoten, um ihn zu ignorieren oder stummzuschalten.';

  @override
  String get chatsForward => 'Weiterleiten';

  @override
  String get chatsForwardTo => 'Weiterleiten an';

  @override
  String get chatsForwardReview =>
      'Prüfen Sie die Nachricht und tippen Sie dann auf Senden.';

  @override
  String chatsChannelNumbered(int index, String name) {
    return 'Kanal $index: $name';
  }

  @override
  String get chatsSchedule => 'Später senden';

  @override
  String get chatsSchedule15 => 'In 15 Minuten';

  @override
  String get chatsSchedule60 => 'In 1 Stunde';

  @override
  String get chatsSchedule240 => 'In 4 Stunden';

  @override
  String get chatsScheduleTomorrow => 'Morgen um 8:00';

  @override
  String get chatsSchedulePick => 'Datum und Uhrzeit wählen';

  @override
  String get chatsScheduleNote =>
      'Wird nur gesendet, solange die App läuft und das Funkgerät verbunden ist.';

  @override
  String chatsScheduleFull(int max) {
    return 'Sie können bis zu $max Nachrichten planen.';
  }

  @override
  String get chatsScheduled => 'Geplant';

  @override
  String chatsScheduledFor(String day, String time) {
    return '$day um $time';
  }

  @override
  String get chatsScheduleMissed =>
      'Nicht gesendet: Das Funkgerät war nicht rechtzeitig verbunden';

  @override
  String get chatsScheduleCancel => 'Geplante Nachricht abbrechen';

  @override
  String get mapNoPositions => 'Noch kein Knoten hat eine Position gemeldet';

  @override
  String get mapConnectForPositions =>
      'Verbinden Sie ein Funkgerät, um Knotenpositionen anzuzeigen';

  @override
  String mapPlaced(int placed, int total) {
    return '$placed von $total Knoten platziert';
  }

  @override
  String mapWaypointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Wegpunkte',
      one: '$count Wegpunkt',
    );
    return '$_temp0';
  }

  @override
  String get mapLongPressHint =>
      'Lange auf die Karte drücken, um einen Wegpunkt zu setzen';

  @override
  String get mapHeardWithin =>
      'Knoten anzeigen, die gehört wurden innerhalb von';

  @override
  String get mapHeardAny => 'Jederzeit gehört';

  @override
  String get mapHeardHour => 'In der letzten Stunde gehört';

  @override
  String get mapHeardDay => 'In den letzten 24 Stunden gehört';

  @override
  String get mapHeardWeek => 'In den letzten 7 Tagen gehört';

  @override
  String get mapShowStreet => 'Straßenkarte anzeigen';

  @override
  String get mapShowTopo => 'Topografische Karte anzeigen';

  @override
  String get mapLinkPlanner => 'Verbindungsplaner';

  @override
  String get mapRallyRoutes => 'Sammelpunkte und Routen';

  @override
  String get mapTeam => 'Team';

  @override
  String get mapZones => 'Zonen';

  @override
  String get mapExportGpx => 'Als GPX exportieren';

  @override
  String get mapHideTrails => 'Spuren ausblenden';

  @override
  String get mapShowTrails => 'Spuren anzeigen';

  @override
  String get mapHideLinks => 'Funkverbindungen ausblenden';

  @override
  String get mapShowLinks => 'Funkverbindungen anzeigen';

  @override
  String get mapShowAll => 'Alle Knoten anzeigen';

  @override
  String mapPlanHint(int max) {
    return 'Tippen Sie auf die Karte, um der Reihe nach Stopps hinzuzufügen. Bis zu $max.';
  }

  @override
  String mapPlanProgress(int count, int max, String distance) {
    return '$count von $max Stopps • $distance';
  }

  @override
  String get mapUndo => 'Rückgängig';

  @override
  String get mapShareRoute => 'Route teilen';

  @override
  String get mapRallyIntro =>
      'Sammelpunkte sind die Orte, an denen sich alle treffen sollen. Setzen Sie einen mit langem Drücken und wählen Sie „Sammelpunkt\". Routen werden als nummerierte Wegpunkte geteilt, sodass auch andere Meshtastic-Apps die Stopps sehen.';

  @override
  String get mapRallyPoints => 'Sammelpunkte';

  @override
  String get mapNoneYet => 'Noch keine.';

  @override
  String mapDistanceOfYou(String distance, String direction) {
    return '$distance $direction von Ihnen';
  }

  @override
  String get mapNoOwnPosition => 'Ihr Funkgerät hat noch keine Position';

  @override
  String get mapShowOnMap => 'Auf der Karte zeigen';

  @override
  String get mapRoutes => 'Routen';

  @override
  String mapStops(int count) {
    return '$count Stopps';
  }

  @override
  String mapStopsHeard(int heard, int count) {
    return '$heard von $count Stopps gehört';
  }

  @override
  String get mapFromYou => 'von Ihnen';

  @override
  String mapFromNode(String name) {
    return 'von $name';
  }

  @override
  String get mapPlanRoute => 'Route planen';

  @override
  String get mapConnectForRoutes =>
      'Verbinden Sie ein Funkgerät, um Routen zu teilen';

  @override
  String mapRouteShared(int count) {
    return 'Route geteilt: $count Stopps auf Kanal 0.';
  }

  @override
  String mapRouteStopped(int sent, int count, String error) {
    return 'Route nach $sent von $count Stopps abgebrochen: $error';
  }

  @override
  String mapGpxExported(int waypoints, int trails) {
    return '$waypoints Wegpunkte und $trails Spuren als GPX exportiert.';
  }

  @override
  String mapGpxFailed(String error) {
    return 'GPX-Export fehlgeschlagen: $error';
  }

  @override
  String get mapWatchTrip => 'Tourkontakte';

  @override
  String get mapWatchFavorites => 'Favoriten';

  @override
  String get mapWatchAll => 'Alle Knoten';

  @override
  String get mapAlertArrive => 'ankommen';

  @override
  String get mapAlertLeave => 'gehen';

  @override
  String get mapAlertBoth => 'ankommen oder gehen';

  @override
  String get mapZonesIntro =>
      'Erhalten Sie eine Telefonwarnung, wenn jemand einen Ort wie das Lager oder den Ausgangspunkt erreicht oder verlässt. Warnungen brauchen ein verbundenes Funkgerät; nichts wird über das Mesh gesendet.';

  @override
  String get mapNoZones => 'Noch keine Zonen.';

  @override
  String mapZoneSummary(String radius, String watch, String alert) {
    return 'Radius $radius • $watch • Warnung, wenn sie $alert';
  }

  @override
  String mapDeleteZone(String name) {
    return '$name löschen';
  }

  @override
  String get mapAddZone => 'Zone in der Kartenmitte hinzufügen';

  @override
  String get mapTeamIntro =>
      'Ihre Tourkontakte. Tippen Sie auf einen, um ihn auf der Karte zu finden.';

  @override
  String get mapNoTeam => 'Noch keine Tourkontakte';

  @override
  String get mapNoTeamHint =>
      'Fügen Sie unter START → Tour bis zu 6 Personen hinzu. Sie erscheinen hier und sind auf der Karte hervorgehoben.';

  @override
  String get mapFreshOk => 'OK';

  @override
  String get mapFreshQuiet => 'STILL';

  @override
  String get mapFreshLost => 'VERLOREN';

  @override
  String get mapConnectForWaypoints =>
      'Verbinden Sie ein Funkgerät, um Wegpunkte zu teilen.';

  @override
  String mapWaypointShared(String name) {
    return 'Wegpunkt „$name\" auf Kanal 0 geteilt.';
  }

  @override
  String mapWaypointFailed(String error) {
    return 'Wegpunkt konnte nicht geteilt werden: $error';
  }

  @override
  String get mapNeverExpires => 'Läuft nie ab';

  @override
  String mapExpires(String time) {
    return 'Läuft ab $time';
  }

  @override
  String mapSharedBy(String name) {
    return 'Geteilt von $name';
  }

  @override
  String get mapLocked => 'Für den Ersteller gesperrt';

  @override
  String get mapDeleteEveryone => 'Für alle löschen';

  @override
  String mapDeleted(String name) {
    return '„$name\" gelöscht.';
  }

  @override
  String mapDeleteFailed(String error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get mapUnknown => 'unbekannt';

  @override
  String mapFromThisRadio(String distance) {
    return '$distance von diesem Funkgerät';
  }

  @override
  String mapPositionHeard(String position, String heard) {
    return 'Position: $position • Gehört: $heard';
  }

  @override
  String get mapDirect => 'direkt';

  @override
  String get mapBatteryExternal => 'Akku: externe Stromversorgung';

  @override
  String mapBattery(int level) {
    return 'Akku: $level %';
  }

  @override
  String get mapOpenDetails => 'Details öffnen';

  @override
  String get mapThisRadioSuffix => ', dieses Funkgerät';

  @override
  String mapTripContactSuffix(String summary) {
    return ', Tourkontakt, $summary';
  }

  @override
  String get mapRallyPoint => 'Sammelpunkt';

  @override
  String get mapWaypoint => 'Wegpunkt';

  @override
  String get mapExpireHour => '1 Stunde';

  @override
  String get mapExpireDay => '1 Tag';

  @override
  String get mapExpireWeek => '1 Woche';

  @override
  String get mapExpireNever => 'Nie';

  @override
  String get mapNewWaypoint => 'Neuer Wegpunkt';

  @override
  String get mapName => 'Name';

  @override
  String get mapDescription => 'Beschreibung (optional)';

  @override
  String get mapRallySub => 'Wo sich alle treffen sollen';

  @override
  String get mapExpiresAfter => 'Läuft ab nach';

  @override
  String get mapOnlyMe => 'Nur ich darf bearbeiten oder löschen';

  @override
  String get mapSharedChannel0 => 'Mit allen auf Kanal 0 geteilt.';

  @override
  String get mapShare => 'Teilen';

  @override
  String get mapNewZone => 'Neue Zone';

  @override
  String mapCenteredOn(String lat, String lon) {
    return 'Zentriert auf $lat, $lon';
  }

  @override
  String get mapZoneName => 'Name, z. B. Lager';

  @override
  String get mapRadius => 'Radius';

  @override
  String get mapWatch => 'Beobachten';

  @override
  String get mapAlertWhen => 'Warnen, wenn sie';

  @override
  String get mapAdd => 'Hinzufügen';

  @override
  String get mapRouteName => 'Routenname';

  @override
  String mapRouteSends(int count) {
    return 'Sendet $count Wegpunkte auf Kanal 0 im Abstand von etwa 3 Sekunden. Sie laufen nach einem Tag ab.';
  }

  @override
  String get mapShowHeatmap => 'Abdeckungskarte anzeigen';

  @override
  String get mapHideHeatmap => 'Abdeckungskarte ausblenden';

  @override
  String get mapHeatmapEmpty =>
      'Noch keine Abdeckungsmessungen. Schalten Sie in den Feldaufzeichnungen „Abdeckung aufzeichnen\" ein.';

  @override
  String mapHeatmapSummary(int readings) {
    return 'Abdeckung: $readings Messungen. Die Zahlen sind der durchschnittliche SNR in dB.';
  }

  @override
  String get mapHeatStrong => 'Stark';

  @override
  String get mapHeatFair => 'Mittel';

  @override
  String get mapHeatWeak => 'Schwach';

  @override
  String get mapShowRemembered => 'Gemerkte Knoten anzeigen';

  @override
  String get mapHideRemembered => 'Gemerkte Knoten ausblenden';

  @override
  String get mapRememberedNone =>
      'Keine gemerkten Knoten mit gespeicherter Position.';

  @override
  String mapRememberedPin(String name, String when) {
    return '$name, gemerkt, zuletzt gesehen $when';
  }

  @override
  String get mapRememberedNote =>
      'Ihr Funkgerät führt diesen Knoten nicht mehr. Hier hat er sich zuletzt gemeldet.';

  @override
  String mapLastSeen(String when) {
    return 'Zuletzt gesehen $when';
  }

  @override
  String get lockTitle => 'NOTORYX Connect ist gesperrt';

  @override
  String get lockBody =>
      'Ihr Funkgerät bleibt verbunden, während die App gesperrt ist.';

  @override
  String get lockUnlock => 'Entsperren';

  @override
  String get lockReason => 'NOTORYX Connect entsperren';

  @override
  String get takTitle => 'ATAK-Verbindung';

  @override
  String get toolsTakSub =>
      'Positionen mit ATAK auf diesem Telefon austauschen';

  @override
  String get takIntro =>
      'Sendet die Position jedes Mesh-Knotens alle 30 Sekunden an ATAK auf diesem Telefon. Nichts verlässt das Telefon, und nichts wird über das Mesh gesendet.';

  @override
  String get takSwitch => 'Mesh-Positionen an ATAK senden';

  @override
  String get takPort => 'UDP-Port';

  @override
  String get takBadPort => 'Verwenden Sie eine Zahl von 1024 bis 65535.';

  @override
  String takStatus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sende $count Knoten',
      one: 'Sende $count Knoten',
    );
    return '$_temp0';
  }

  @override
  String takProblem(String error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String get takHowTo =>
      'Öffnen Sie in ATAK Settings, dann Network Preferences, dann Manage Inputs, und fügen Sie einen UDP-Eingang auf diesem Port hinzu. Knoten ohne Position in der letzten Stunde werden ausgelassen.';

  @override
  String ndFailed(String error) {
    return 'Fehlgeschlagen: $error';
  }

  @override
  String ndSendFailed(String error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String get ndFieldNote => 'Feldnotiz';

  @override
  String get ndRemoveFavorite => 'Aus Favoriten entfernen';

  @override
  String get ndAddFavorite => 'Zu Favoriten hinzufügen';

  @override
  String get ndShortName => 'Kurzname';

  @override
  String get ndHardware => 'Hardware';

  @override
  String get ndThisRadio => 'Dieses Funkgerät';

  @override
  String get ndYes => 'Ja';

  @override
  String get ndLastHeard => 'Zuletzt gehört';

  @override
  String get ndSignal => 'Signal';

  @override
  String get ndHopsAway => 'Sprünge entfernt';

  @override
  String get ndDirect => 'Direkt';

  @override
  String get ndBattery => 'Akku';

  @override
  String get ndExternalPower => 'Externe Stromversorgung';

  @override
  String get ndVoltage => 'Spannung';

  @override
  String get ndChannelUse => 'Kanalauslastung';

  @override
  String get ndPosition => 'Position';

  @override
  String get ndAltitude => 'Höhe';

  @override
  String get ndPositionAge => 'Alter der Position';

  @override
  String get ndDistance => 'Entfernung';

  @override
  String get ndEncounters => 'Begegnungen';

  @override
  String get ndTraceroute => 'Traceroute';

  @override
  String get ndRequestPosition => 'Position anfordern';

  @override
  String get ndPositionRequested =>
      'Position angefordert. Sie wird aktualisiert, wenn der Knoten antwortet.';

  @override
  String get ndRequestTelemetry => 'Telemetrie anfordern';

  @override
  String get ndTelemetryRequested =>
      'Telemetrie angefordert. Sie wird aktualisiert, wenn der Knoten antwortet.';

  @override
  String get ndRemoteAdmin => 'Fernverwaltung';

  @override
  String get ndRequestSensors => 'Sensoren anfordern';

  @override
  String get ndSensorsRequested =>
      'Sensorwerte angefordert. Knoten ohne Sensoren antworten nicht.';

  @override
  String get ndMute => 'Benachrichtigungen stummschalten';

  @override
  String get ndMuteSub =>
      'Nachrichten werden weiter angezeigt; keine Warnungen oder Vorlesen';

  @override
  String get ndIgnore => 'Diesen Knoten ignorieren';

  @override
  String get ndIgnoreSub =>
      'In Knoten, Karte und Chats ausgeblendet; löst nie Benachrichtigungen oder Bot-Antworten aus. Rückgängig hier oder in den Einstellungen.';

  @override
  String get ndAddNote => 'Tippen, um eine Notiz hinzuzufügen';

  @override
  String get ndDirectMessages => 'DIREKTNACHRICHTEN';

  @override
  String get ndNoDirect => 'Noch keine Direktnachrichten mit diesem Knoten.';

  @override
  String get ndDirectMessage => 'Direktnachricht';

  @override
  String get ndSend => 'Senden';

  @override
  String get ndRadioLinks => 'DIREKTE FUNKVERBINDUNGEN';

  @override
  String get ndNoNeighbors =>
      'Noch keine Nachbarberichte. Knoten teilen sie, wenn das Modul Neighbor Info aktiviert ist (Einstellungen → Funkgeräteeinstellungen ändern → Neighborinfo).';

  @override
  String ndHears(int count) {
    return 'Hört direkt ($count):';
  }

  @override
  String get ndNoneReported => '  Keine Nachbarn gemeldet';

  @override
  String ndHeardBy(int count) {
    return 'Direkt gehört von ($count):';
  }

  @override
  String get ndTrustQ => 'Dem neuen Schlüssel vertrauen?';

  @override
  String ndTrustBody(String name) {
    return 'Tun Sie das nur, wenn Sie beim Besitzer von $name geprüft haben, dass er sein Funkgerät zurückgesetzt oder ersetzt hat. Andernfalls gibt sich vielleicht jemand anderes als dieser Knoten aus.';
  }

  @override
  String get ndTrust => 'Neuem Schlüssel vertrauen';

  @override
  String get ndKeyChanged => 'Sicherheitsschlüssel geändert';

  @override
  String ndKeyChangedBody(String newCode, String oldCode) {
    return 'Dieser Knoten zeigt jetzt einen anderen Schlüssel ($newCode) als beim ersten Mal ($oldCode). Sein Funkgerät wurde vielleicht zurückgesetzt oder ersetzt, oder jemand gibt sich als er aus. Fragen Sie beim Besitzer nach, bevor Sie private Nachrichten senden.';
  }

  @override
  String get ndSecurityKey => 'Sicherheitsschlüssel';

  @override
  String get ndKeyNotShared =>
      'Noch nicht geteilt. Knoten mit Firmware 2.5 oder neuer teilen einen Schlüssel für private Direktnachrichten.';

  @override
  String ndSafetyCode(String code) {
    return 'Sicherheitscode $code\nVergleichen Sie ihn mit dem Funkgerät des Besitzers, um sicherzugehen, dass er es ist.';
  }

  @override
  String get homeFirmwareTitle => 'Firmware-Update des Funkgeräts empfohlen';

  @override
  String get homeCheckIn => 'Melden';

  @override
  String get homeEmergency => 'Notfall';

  @override
  String get homeSosHint =>
      '2 Sekunden halten. Es geht an Ihre Tourkontakte und wird alle 5 Minuten wiederholt, bis jemand antwortet.';

  @override
  String homeSosHintChannel(int channel) {
    return '2 Sekunden halten. Es geht an Ihre Tourkontakte und Kanal $channel und wird alle 5 Minuten wiederholt, bis jemand antwortet.';
  }

  @override
  String get homeNotReceived =>
      'Gesendet oder wartend heißt nicht empfangen. Bestätigen Sie mit einer Antwort oder einem Anruf.';

  @override
  String get homeConnected => 'Funkgerät verbunden';

  @override
  String get homeNotConnected => 'Kein Funkgerät verbunden';

  @override
  String get homeYourRadio => 'Ihr Funkgerät';

  @override
  String get homeConnectHint =>
      'Verbinden Sie sich, um sich zu melden, ein SOS zu senden und das Mesh zu sehen.';

  @override
  String get homeNodes => 'Knoten';

  @override
  String get homeBattery => 'Akku';

  @override
  String get homeUnknown => 'Unbekannt';

  @override
  String get homePluggedIn => 'Angeschlossen';

  @override
  String get homeConnectRadio => 'Funkgerät verbinden';

  @override
  String get homeTryDemo => 'Demo ausprobieren';

  @override
  String get homeTripRunning => 'Tour läuft';

  @override
  String get homeTripNotStarted => 'Tour nicht gestartet';

  @override
  String homeContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kontakte',
      one: '$count Kontakt',
    );
    return '$_temp0';
  }

  @override
  String homeTripNamed(String name) {
    return 'Tour: $name';
  }

  @override
  String get homePlanTrip => 'Tour planen';

  @override
  String homeOverdue(String names) {
    return 'Überfällig: $names';
  }

  @override
  String homeCheckInLabel(String label) {
    return 'Meldung: $label';
  }

  @override
  String homeDelivered(String label, String time, int delivered, int total) {
    return '$label um $time: an $delivered von $total zugestellt';
  }

  @override
  String homeNotDelivered(String names) {
    return 'nicht zugestellt an $names';
  }

  @override
  String homeWaiting(int count) {
    return '$count wartend';
  }

  @override
  String get homeDetails => 'Details';

  @override
  String get homeResend => 'Erneut senden';

  @override
  String get homeSendSosQ => 'SOS senden?';

  @override
  String get homeSosRepeats =>
      'Ihr SOS wird alle 5 Minuten wiederholt, bis jemand antwortet oder Sie es beenden.';

  @override
  String get homeSendSos => 'SOS senden';

  @override
  String get homeHoldSos => 'Für SOS halten';

  @override
  String homeSosReplied(String name) {
    return '$name hat geantwortet. Wiederholungen beendet.';
  }

  @override
  String homeSosNext(int sends, int max, String time) {
    return '$sends von $max gesendet. Nächstes um $time.';
  }

  @override
  String get homeSosBusy =>
      ' Der Kanal ist ausgelastet, daher werden die Wiederholungen gestreckt, um durchzukommen.';

  @override
  String homeSosDone(int max) {
    return '$max-mal gesendet. Wiederholungen beendet; das SOS bleibt angezeigt, bis Sie es beenden.';
  }

  @override
  String get homeSosActive => 'SOS aktiv';

  @override
  String get homeImSafe => 'Ich bin in Sicherheit';

  @override
  String get homeStopNoMessage => 'Ohne Nachricht beenden';

  @override
  String get frTitle => 'Feldaufzeichnungen';

  @override
  String get frTplAssistance => 'Hilfe';

  @override
  String get frTplCheckIn => 'Meldung';

  @override
  String get frTplAllClear => 'Alles in Ordnung';

  @override
  String get frTooLong => 'Geben Sie eine Nachricht mit 1–220 UTF-8-Bytes ein.';

  @override
  String frBroadcastQ(int channel) {
    return 'Auf Kanal $channel rundsenden?';
  }

  @override
  String get frNoProof =>
      'Senden beweist keinen Empfang. Bestätigen Sie mit einer Antwort oder per Sprechfunk.';

  @override
  String get frSendMessage => 'Nachricht senden';

  @override
  String get frChanged =>
      'Funkgerät oder Kanal hat sich geändert. Verbinden Sie sich neu und prüfen Sie die Nachricht.';

  @override
  String get frSubmitted =>
      'An das Funkgerät übergeben. Sendestatus und Antworten finden Sie unter Chats.';

  @override
  String get frIncidentLog => 'Einsatzprotokoll';

  @override
  String get frIncidentLogSub =>
      'Private Notizen, auf diesem Telefon gespeichert';

  @override
  String get frIncidentField => 'Vorfall oder Beobachtung';

  @override
  String get frIncidentSaved => 'Vorfall gespeichert.';

  @override
  String get frSaveIncident => 'Vorfall speichern';

  @override
  String get frIncidentCopied =>
      'Vorfall-CSV kopiert. In eine Datei oder Tabelle einfügen.';

  @override
  String get frCopyIncident => 'Vorfall-CSV kopieren';

  @override
  String frRadioOf(String time, String radio) {
    return '$time • Funkgerät $radio';
  }

  @override
  String get frUnassigned => 'nicht zugeordnet';

  @override
  String get frRemoveIncident => 'Vorfall entfernen';

  @override
  String get frRemoveIncidentQ => 'Diesen Vorfall entfernen?';

  @override
  String get frKeep => 'Behalten';

  @override
  String get frRemove => 'Entfernen';

  @override
  String get frIncidentRemoved => 'Vorfall entfernt.';

  @override
  String get frTemplates => 'Vorlagen für Notfall und Meldung';

  @override
  String get frTemplatesSub =>
      'Details bearbeiten, Kanal wählen und vor dem Senden prüfen';

  @override
  String get frMessageField => 'Nachricht – leere Angaben ersetzen';

  @override
  String get frBroadcastChannel => 'Rundsendekanal';

  @override
  String frChannelItem(int index, String name) {
    return 'Kanal $index • $name';
  }

  @override
  String get frReview => 'Nachricht prüfen';

  @override
  String get frNotEmergency =>
      'Eine Vorlage ist gewöhnlicher Mesh-Text. Sie kontaktiert keine Rettungsdienste.';

  @override
  String get frCoverage => 'Abdeckungsverlauf';

  @override
  String get frCoverageSub =>
      'Empfängerstandort mit empfangenem Funksignal • nur lokale Aufzeichnung';

  @override
  String get frRecord => 'Abdeckung aufzeichnen';

  @override
  String get frRecordSub =>
      'Fordert das GPS des Telefons an. Stoppt beim Trennen. Sendet Ihren Standort nicht.';

  @override
  String get frRecordOn =>
      'Abdeckungsaufzeichnung aktiv; wartet auf einen frischen, genauen GPS-Fix und Funkpakete.';

  @override
  String get frRecordOff => 'Abdeckungsaufzeichnung gestoppt.';

  @override
  String frReadings(int count) {
    return '$count Messungen • höchstens 2000 Abdeckungsmessungen • sie verfallen nach 30 Tagen';
  }

  @override
  String get frCoverageCopied =>
      'Abdeckungs-CSV kopiert. In eine Datei oder Tabelle einfügen.';

  @override
  String get frCopyCoverage => 'Abdeckungs-CSV kopieren';

  @override
  String get frBot => 'Bot-Schutz und Ruhezeiten';

  @override
  String get frBotSub =>
      '6 Antworten/Stunde • 30 Sekunden Abstand • 5 Minuten Pause pro Knoten';

  @override
  String get frBotEnable =>
      'Schalten Sie den Bot-Modus in Chats für diese Sitzung ein.';

  @override
  String get frBotRules =>
      'Nur frische Nachrichten auf dem gewählten Kanal zählen. Wiederholungen und Bot-Antworten (NOTORYX: oder Bastion:) werden ignoriert. Die Ruhezeiten richten sich nach der Ortszeit dieses Telefons.';

  @override
  String get frQuiet => 'Ruhezeiten';

  @override
  String get frQuietStart => 'Beginn der Ruhezeit';

  @override
  String get frQuietEnd => 'Ende der Ruhezeit';

  @override
  String get frBotChannel => 'Kanalplatz des Bots';

  @override
  String frChannelN(int index) {
    return 'Kanal $index';
  }

  @override
  String frBytes(int bytes, int max) {
    return '$bytes von $max Bytes. Leere Zeilen werden weggelassen.';
  }

  @override
  String frBytesOver(int bytes, int max) {
    return '$bytes von $max Bytes. Zu lang zum Senden: Kürzen Sie ein Feld.';
  }

  @override
  String get frUseReport => 'Bericht verwenden';

  @override
  String get rsTitle => 'Funkgeräteeinstellungen';

  @override
  String get rsNotReady => 'Funkgerät nicht bereit';

  @override
  String get rsNotReadySub =>
      'Verbinden Sie ein Funkgerät und warten Sie auf BEREIT, um Einstellungen zu ändern.';

  @override
  String get rsAvailability => 'Verfügbarkeit der Einstellungen';

  @override
  String get rsAvailabilitySub =>
      'Prüfen Sie die Lesewerte vor dem Bearbeiten. Fehlende Starteinstellungen beweisen nicht, dass ein Modul nicht unterstützt wird. Die Ergebnisse werden beim Neuverbinden zurückgesetzt.';

  @override
  String get rsStopChecking => 'Prüfung beenden';

  @override
  String get rsOwner => 'Besitzer';

  @override
  String get rsOwnerSub => 'Lange und kurze Knotennamen';

  @override
  String get rsLoraSub => 'Region, Modem-Voreinstellung, Sprunglimit, Senden';

  @override
  String get rsChannels => 'Kanäle';

  @override
  String get rsChannelsSub => 'Namen, Rollen und Schlüssel';

  @override
  String get rsDevice => 'Gerät';

  @override
  String get rsDeviceSub => 'Geräterolle und Weiterleitungsmodus';

  @override
  String get rsPosition => 'Position';

  @override
  String get rsPositionSub =>
      'Sendeintervall, GPS-Modus, intelligente Position';

  @override
  String get rsAllSettings => 'ALLE FUNKGERÄTEEINSTELLUNGEN';

  @override
  String get rsModules => 'MODULE';

  @override
  String get rsRadioChanged =>
      'Das verbundene Funkgerät hat sich beim Laden geändert. Lesen Sie erneut.';

  @override
  String rsSaveQ(String section) {
    return '$section speichern?';
  }

  @override
  String get rsSaveWarning =>
      'Dadurch wird die Änderung auf das verbundene Funkgerät geschrieben. Es kann neu starten und sich neu verbinden.';

  @override
  String get rsIdentityChanged =>
      'Die Identität des Funkgeräts hat sich geändert oder ist nicht verfügbar. Vor dem Speichern neu laden.';

  @override
  String rsSaved(String section) {
    return '$section gespeichert und vom Funkgerät bestätigt.';
  }

  @override
  String rsNotVerified(String error) {
    return 'Speichern nicht bestätigt: $error\nDas Funkgerät hat die Änderung vielleicht übernommen. Laden Sie neu, um den aktuellen Wert zu prüfen; nichts wird automatisch erneut gesendet.';
  }

  @override
  String get rsSaveButton => 'SPEICHERN';

  @override
  String rsUnavailable(String section) {
    return 'Die Einstellungen für $section sind über die Firmware-API dieses Funkgeräts nicht verfügbar.';
  }

  @override
  String rsReadFailed(String error) {
    return 'Lesen vom Funkgerät fehlgeschlagen: $error';
  }

  @override
  String get rsRetry => 'Erneut versuchen';

  @override
  String get rsWaitingReconnect =>
      'Warte auf Neuverbindung und frisches Lesen der Einstellungen…';

  @override
  String get rsReload => 'Vom Funkgerät neu laden';

  @override
  String get rsLongName => 'Langer Name';

  @override
  String get rsShortName => 'Kurzname';

  @override
  String get rsChooseRegion =>
      'Wählen Sie vor dem Speichern eine Region; ohne Region sendet das Funkgerät nicht.';

  @override
  String get rsCustomInvalid =>
      'Eigene Einstellungen brauchen eine positive Bandbreite, Spreizfaktor 5–12 und einen Coderaten-Nenner von 5–8. Prüfen Sie die von Ihrem Funkgerät unterstützten Werte.';

  @override
  String get rsRegionWarning =>
      'Eine Änderung von Region oder Modem-Voreinstellung trennt dieses Funkgerät von Knoten mit den alten Einstellungen.';

  @override
  String get rsRegion => 'Region';

  @override
  String get rsUsePreset => 'Modem-Voreinstellung verwenden';

  @override
  String get rsModemPreset => 'Modem-Voreinstellung';

  @override
  String get rsBandwidth => 'Bandbreite (kHz)';

  @override
  String get rsSpreadFactor => 'Spreizfaktor';

  @override
  String get rsCodingRate => 'Nenner der Coderate (5–8)';

  @override
  String get rsRxBoost => 'Verstärkter Empfangsgewinn';

  @override
  String get rsRxBoostSub =>
      'Interner SX126x-Empfangsgewinn; getrennt vom externen LNA';

  @override
  String get rsLna => 'Externer LNA';

  @override
  String get rsLnaReported =>
      'Externer Empfangsverstärker von diesem Funkgerät gemeldet';

  @override
  String get rsLnaNone =>
      'Dieses Funkgerät hat keinen steuerbaren externen LNA gemeldet';

  @override
  String rsHopLimit(int hops) {
    return 'Sprunglimit: $hops';
  }

  @override
  String get rsTransmit => 'Senden aktiviert';

  @override
  String get rsTransmitSub => 'Aus macht das Funkgerät zum reinen Empfänger';

  @override
  String rsInfraWarning(String role) {
    return '$role ist für feste Infrastruktur mit guter Abdeckung gedacht. Auf einem Handgerät verschwendet es Sendezeit und Akku.';
  }

  @override
  String get rsRole => 'Rolle';

  @override
  String get rsRebroadcast => 'Weiterleitungsmodus';

  @override
  String get rsIntervalInvalid =>
      'Das Sendeintervall muss 0 (Firmware-Standard) oder mindestens 30 Sekunden sein.';

  @override
  String get rsGpsMode => 'GPS-Modus';

  @override
  String get rsInterval => 'Sendeintervall (Sekunden, 0 = Standard)';

  @override
  String get rsSmart => 'Intelligentes Senden der Position';

  @override
  String get rsSmartSub =>
      'Zusätzliche Aktualisierungen senden, wenn sich der Knoten bewegt';

  @override
  String get rsFixed => 'Feste Position';

  @override
  String get rsFixedSub => 'Letzte bekannte Position statt GPS melden';

  @override
  String get rsShareQr => 'Als QR-Code teilen';

  @override
  String get rsImportLink => 'Kanallink importieren';

  @override
  String get rsDisabled => 'Deaktiviert';

  @override
  String get rsDefaultName => '(Standardname)';

  @override
  String rsChannelsFailed(String error) {
    return 'Kanäle konnten nicht gelesen werden: $error';
  }

  @override
  String get rsNoEncryption => 'Keine Verschlüsselung';

  @override
  String get rsDefaultKey => 'Standardschlüssel';

  @override
  String get rsAes128 => 'AES-128-Schlüssel';

  @override
  String get rsAes256 => 'AES-256-Schlüssel';

  @override
  String get rsUnknownKey => 'Unbekannter Schlüssel';

  @override
  String rsChannelN(int index) {
    return 'Kanal $index';
  }

  @override
  String get rsKeyWarning =>
      'Der Schlüssel ändert sich. Knoten ohne den neuen Schlüssel können diesen Kanal nicht mehr lesen. Teilen Sie ihn über den QR-Code des Kanals.';

  @override
  String get rsChannelName => 'Name (leer = Name der Voreinstellung)';

  @override
  String rsEncryption(String key) {
    return 'Verschlüsselung: $key';
  }

  @override
  String get rsNewAes256 => 'Neuer zufälliger AES-256-Schlüssel';

  @override
  String rsGpsHidden(String model) {
    return 'GPS-Pins sind ausgeblendet: Beim $model ist das GPS vom Hersteller verdrahtet, sie bewirken also nichts.';
  }

  @override
  String get bcShareQ => 'Ihren Primärkanal teilen?';

  @override
  String get bcShareBody =>
      'Die Bake enthält Name und Schlüssel Ihres Primärkanals. Jeder in Reichweite kann ihm dann beitreten und seine Nachrichten lesen.';

  @override
  String get bcShare => 'Teilen';

  @override
  String get bcSent => 'Bake gesendet.';

  @override
  String bcNotSent(String error) {
    return 'Bake nicht gesendet: $error';
  }

  @override
  String get bcTitle => 'Mesh-Baken';

  @override
  String get bcClear => 'Gehörte Baken löschen';

  @override
  String get bcIntro =>
      'Eine Bake ist eine kurze Rundsendung, die Funkgeräten in der Nähe zeigt, dass hier ein Mesh ist, und sie in einen Kanal einladen kann. Funkgeräte mit neuerer Meshtastic-Firmware zeigen sie an; NOTORYX Connect zeigt gehörte Baken mit jeder Firmware an.';

  @override
  String get bcSendTitle => 'Eine Bake senden';

  @override
  String get bcMessage => 'Baken-Nachricht';

  @override
  String get bcMessageHelp =>
      'Wird auf Ihrem Primärkanal gesendet. Höchstens eine Bake pro Stunde.';

  @override
  String bcBytes(int used, int max) {
    return '$used/$max Bytes';
  }

  @override
  String get bcTooLong => 'Zu lang';

  @override
  String get bcAddLocationNone =>
      'Meinen Standort hinzufügen (noch keine Position)';

  @override
  String get bcAddLocation => 'Meinen Standort als Plus Code hinzufügen';

  @override
  String get bcInvite => 'In meinen Primärkanal einladen';

  @override
  String get bcInviteSub =>
      'Enthält Kanalname und Schlüssel sowie Ihre Region und Voreinstellung';

  @override
  String get bcSending => 'Sende…';

  @override
  String get bcSend => 'Bake senden';

  @override
  String get bcConnect =>
      'Verbinden Sie ein Funkgerät, um eine Bake zu senden.';

  @override
  String bcNext(String time) {
    return 'Die nächste Bake kann um $time gesendet werden.';
  }

  @override
  String get bcHeard => 'Gehörte Baken';

  @override
  String get bcNoneHeard => 'Noch keine Baken gehört';

  @override
  String get bcNoneHeardSub =>
      'Baken von Funkgeräten in Reichweite auf Ihren Kanälen erscheinen hier.';

  @override
  String bcFrom(String name) {
    return 'Von $name';
  }

  @override
  String bcHeardAt(String time) {
    return 'gehört um $time';
  }

  @override
  String bcChannel(String name) {
    return 'Kanal „$name\"';
  }

  @override
  String get bcDefault => 'Standard';

  @override
  String bcRegion(String name) {
    return 'Region $name';
  }

  @override
  String bcPreset(String name) {
    return 'Voreinstellung $name';
  }

  @override
  String bcSlot(int slot) {
    return 'Platz $slot';
  }

  @override
  String get bcNoMessage => '(keine Nachricht)';

  @override
  String bcInvitesTo(String offer) {
    return 'Lädt ein in: $offer';
  }

  @override
  String get bcJoin => 'Kanal prüfen und beitreten';

  @override
  String get csShareTitle => 'Kanäle teilen';

  @override
  String csReadFailed(String error) {
    return 'Kanäle konnten nicht gelesen werden: $error';
  }

  @override
  String get csRetry => 'Erneut versuchen';

  @override
  String csPrimary(String name) {
    return 'Primär: $name';
  }

  @override
  String csSecondary(String name) {
    return 'Sekundär: $name';
  }

  @override
  String get csDefaultName => '(Standardname)';

  @override
  String get csCopyLink => 'Link kopieren';

  @override
  String get csCopied => 'Kanallink kopiert.';

  @override
  String get csKeysWarning =>
      'Dieser Code enthält die Schlüssel Ihrer Kanäle. Wer ihn scannt, kann auf diesen Kanälen lesen und senden.';

  @override
  String get csReplaceQ => 'Alle Kanäle ersetzen?';

  @override
  String get csAddQ => 'Kanäle hinzufügen?';

  @override
  String get csReplaceBody =>
      'Alle 8 Kanalplätze werden überschrieben. Ohne deren Link verlieren Sie den Zugang zu den aktuellen Kanälen. Das Funkgerät startet neu.';

  @override
  String get csReplaceLoraBody =>
      'Alle 8 Kanalplätze und die LoRa-Einstellungen werden überschrieben. Ohne deren Link verlieren Sie den Zugang zu den aktuellen Kanälen. Das Funkgerät startet neu.';

  @override
  String get csAddBody =>
      'Neue Kanäle aus dem Link kommen in freie Plätze. Vorhandene Kanäle und LoRa-Einstellungen bleiben gleich.';

  @override
  String get csApply => 'Anwenden';

  @override
  String get csAlreadyThere =>
      'Alle Kanäle aus dem Link sind bereits auf dem Funkgerät.';

  @override
  String csWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kanäle geschrieben und vom Funkgerät bestätigt.',
      one: '$count Kanal geschrieben und vom Funkgerät bestätigt.',
    );
    return '$_temp0';
  }

  @override
  String csNotVerified(String error) {
    return 'Import nicht bestätigt: $error\nNichts wird automatisch erneut gesendet.';
  }

  @override
  String csRefused(String error) {
    return 'Import abgelehnt: $error';
  }

  @override
  String csFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get csImportTitle => 'Kanäle importieren';

  @override
  String get csScan => 'Kanal-QR-Code scannen';

  @override
  String get csScanTitle => 'Kanal-QR scannen';

  @override
  String get csLinkLabel => 'Meshtastic-Kanallink';

  @override
  String get csPaste => 'Einfügen';

  @override
  String csLora(String region, String modem) {
    return 'LoRa: $region, $modem';
  }

  @override
  String get csCustomModem => 'eigenes Modem';

  @override
  String get csAdd => 'Zum Funkgerät hinzufügen';

  @override
  String get csReplaceAll => 'Alle ersetzen';

  @override
  String get csApplyRadio => 'Auf Funkgerät anwenden';

  @override
  String get trTitle => 'Tour planen';

  @override
  String get trName => 'Name der Tour';

  @override
  String trContacts(int count, int max) {
    return 'TOURKONTAKTE ($count/$max)';
  }

  @override
  String get trContactsSub =>
      'Meldungen und SOS gehen als Direktnachricht an jeden von ihnen.';

  @override
  String get trNoNodes => 'Noch keine Knoten';

  @override
  String get trNoNodesSub =>
      'Verbinden Sie Ihr Funkgerät, damit Knoten in der Nähe und Favoriten hier erscheinen.';

  @override
  String get trOverdue => 'Überfällig-Warnung';

  @override
  String get trOverdueHelp =>
      'Warnt Sie, wenn ein Tourkontakt so lange nicht gehört wurde';

  @override
  String get trOff => 'Aus';

  @override
  String trMinutes(int count) {
    return '$count Min.';
  }

  @override
  String trHours(int count) {
    return '$count Std.';
  }

  @override
  String get trReminder => 'Melde-Erinnerung';

  @override
  String get trReminderHelp =>
      'Erinnert Sie so lange nach Ihrer letzten Meldung daran, sich zu melden';

  @override
  String trEvery(String time) {
    return 'Alle $time';
  }

  @override
  String get trSosChannel => 'SOS auch auf einem Kanal senden';

  @override
  String get trSosChannelHelp =>
      'Alle auf diesem Kanal sehen Ihr SOS, nicht nur die Tourkontakte';

  @override
  String get trContactsOnly => 'Nein, nur Tourkontakte';

  @override
  String trChannelItem(int index, String name) {
    return 'Kanal $index • $name';
  }

  @override
  String get trDefault => 'Standard';

  @override
  String get trReadiness => 'Bereitschaftsprüfung';

  @override
  String get trEnd => 'Tour beenden';

  @override
  String get trStart => 'Tour starten';

  @override
  String trRunning(String time) {
    return 'Tour läuft seit $time. Überfällig-Warnungen und Erinnerungen sind an.';
  }

  @override
  String get trNotRunning =>
      'Beim Start der Tour werden Überfällig-Warnungen und Melde-Erinnerungen eingeschaltet. Meldungen und SOS funktionieren jederzeit.';

  @override
  String get pvEncryptedOn => 'Der Chatverlauf ist jetzt verschlüsselt.';

  @override
  String get pvEncryptedOff => 'Der Chatverlauf ist nicht mehr verschlüsselt.';

  @override
  String get pvLockOnReason => 'App-Sperre einschalten';

  @override
  String get pvLockOffReason => 'App-Sperre ausschalten';

  @override
  String get pvLockUnchanged => 'Die App-Sperre wurde nicht geändert.';

  @override
  String get pvStored1 =>
      'Chatverlauf und Offline-Warteschlangen für jedes Funkgerät (die neuesten 500 Nachrichten pro Funkgerät)';

  @override
  String get pvStored2 =>
      'NodeVault: von Ihren Funkgeräten gehörte Knoten sowie Ihre Favoriten und Notizen';

  @override
  String get pvStored3 => 'Aus dem Mesh empfangene Wegpunkte';

  @override
  String get pvStored4 =>
      'Einsatzprotokoll und Abdeckungsaufzeichnungen, nur wenn Sie sie anlegen';

  @override
  String get pvStored5 =>
      'Einstellungen für Feldwarnungen, Bot, Standort und Erscheinungsbild';

  @override
  String get pvStored6 => 'Kartenkacheln für Gebiete, die Sie angesehen haben';

  @override
  String get pvSent1 =>
      'Ihre gesendeten Nachrichten gehen an Ihr Funkgerät, das sie mit dem Kanalschlüssel über das Mesh überträgt';

  @override
  String get pvSent2 =>
      'Ihr Telefonstandort, nur solange „Telefonstandort teilen\" an ist, in der gewählten Genauigkeit';

  @override
  String get pvSent3 =>
      'Positions-, Telemetrie- und Traceroute-Anfragen, die Sie starten';

  @override
  String get pvSent4 =>
      'Kartenkachel-Anfragen an OpenStreetMap-Server, wenn Sie die Karte ansehen; sie sehen Ihre IP-Adresse';

  @override
  String get pvSent5 =>
      'Anfragen für topografische Kacheln an OpenTopoMap-Server, nur solange die Topo-Karte angezeigt wird; sie sehen Ihre IP-Adresse';

  @override
  String get pvSent6 =>
      'Punkte entlang einer Verbindung an den Höhendienst Open-Meteo, nur wenn Sie im Verbindungsplaner eine Verbindung prüfen';

  @override
  String get pvDisconnectFirst =>
      'Trennen Sie das Funkgerät, bevor Sie Telefondaten löschen.';

  @override
  String get pvDeleteAllQ => 'Alle Telefondaten löschen?';

  @override
  String get pvDeleteChatsQ => 'Chatverlauf löschen?';

  @override
  String get pvDeleteAllBody =>
      'Löscht Chats und Offline-Warteschlangen aller Funkgeräte, NodeVault, Favoriten und Notizen, Wegpunkte, Feldaufzeichnungen, zwischengespeicherte Kartenkacheln und alle App-Einstellungen von diesem Telefon. Die Funkgeräteeinstellungen bleiben unverändert. Das kann nicht rückgängig gemacht werden; erstellen Sie vorher eine Sicherung der Telefondaten, falls Sie sie brauchen könnten.\n\nDie App wird danach geschlossen.';

  @override
  String get pvDeleteChatsBody =>
      'Löscht Chatverlauf und wartende Nachrichten aller Funkgeräte von diesem Telefon. Bereits über das Mesh gesendete Nachrichten sind nicht betroffen. Das kann nicht rückgängig gemacht werden.\n\nDie App wird danach geschlossen.';

  @override
  String get pvDelete => 'Löschen';

  @override
  String pvDeleteFailed(String error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get pvDeleted => 'Gelöscht';

  @override
  String get pvDeletedBody =>
      'NOTORYX Connect wird jetzt geschlossen, damit nichts, was noch im Speicher ist, erneut gespeichert wird.';

  @override
  String get pvCloseApp => 'App schließen';

  @override
  String get pvTitle => 'Datenschutz und Daten';

  @override
  String get pvIntro =>
      'NOTORYX Connect hat kein Konto, keine Analyse, keine Werbung und keine eigenen Server. Alles, was es speichert, bleibt im privaten Speicher der App auf Ihrem Telefon und wird beim Deinstallieren entfernt.';

  @override
  String get pvAppLock => 'App-Sperre';

  @override
  String get pvAppLockSub =>
      'Beim Öffnen der App und nach einer Minute Abwesenheit nach Fingerabdruck, Gesicht oder Bildschirmsperre fragen. Sie brauchen sie auch, um zum SOS zu gelangen. Das Funkgerät bleibt verbunden.';

  @override
  String get pvAppLockNone =>
      'Richten Sie auf diesem Telefon eine Bildschirmsperre ein, um die App-Sperre zu nutzen.';

  @override
  String get pvEncrypt => 'Chatverlauf verschlüsseln';

  @override
  String get pvEncryptSub =>
      'Verschlüsselt gespeicherte Nachrichten mit einem Schlüssel aus dem sicheren Speicher dieses Telefons. Geht dieser Schlüssel verloren, etwa nach dem Wechsel auf ein neues Telefon, ist der gespeicherte Verlauf nicht mehr lesbar. Exportieren Sie vorher, was Sie brauchen.';

  @override
  String get pvStored => 'Auf diesem Telefon gespeichert';

  @override
  String get pvSent => 'Von diesem Telefon gesendet';

  @override
  String get pvDeleteChats => 'Chatverlauf löschen';

  @override
  String get pvDeleteAll => 'Alle Telefondaten löschen';

  @override
  String pbFailed(String error) {
    return 'Vorgang fehlgeschlagen: $error';
  }

  @override
  String get pbShortPassword =>
      'Verwenden Sie für das Sicherungspasswort mindestens 12 Zeichen.';

  @override
  String get pbCreated =>
      'Sicherung erstellt. Speichern Sie die Datei außerhalb dieses Telefons. Bewahren Sie das Passwort getrennt auf; es kann nicht wiederhergestellt werden.';

  @override
  String get pbDisconnectFirst =>
      'Trennen Sie das Funkgerät, bevor Sie Telefondaten wiederherstellen.';

  @override
  String get pbReplaceQ => 'Alle Telefondaten ersetzen?';

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
      other: '$radios Funkgeräten',
      one: '$radios Funkgerät',
    );
    return 'Sicherung erstellt am $date mit Version $version.\n\nSie enthält den Chatverlauf von $_temp0 ($messages Nachrichten) und insgesamt $items gespeicherte Einträge.\n\nAlles, was NOTORYX Connect auf diesem Telefon speichert (Chats, Offline-Warteschlangen, NodeVault, Wegpunkte, Feldaufzeichnungen und Einstellungen), wird ersetzt. Die Funkgeräteeinstellungen bleiben unverändert. Die App wird nach der Wiederherstellung geschlossen; öffnen Sie sie erneut, um fortzufahren.';
  }

  @override
  String get pbReplace => 'Telefondaten ersetzen';

  @override
  String get pbRestored => 'Wiederherstellung abgeschlossen';

  @override
  String get pbRestoredBody =>
      'NOTORYX Connect wird jetzt geschlossen, damit nichts aus dem Speicher die wiederhergestellten Daten überschreibt. Öffnen Sie die App erneut, um fortzufahren.';

  @override
  String get pbTitle => 'Sicherung der Telefondaten';

  @override
  String get pbIntro =>
      'Sichert alles, was NOTORYX Connect auf diesem Telefon speichert: Chatverlauf und Offline-Warteschlangen aller Funkgeräte, NodeVault-Favoriten und -Notizen, Wegpunkte, Feldaufzeichnungen und App-Einstellungen. Nutzen Sie sie für den Umzug auf ein neues Telefon. Die Datei wird mit Ihrem Passwort verschlüsselt. Die Funkgeräteeinstellungen haben eine eigene Sicherung.';

  @override
  String get pbPassword => 'Sicherungspasswort (mindestens 12 Zeichen)';

  @override
  String get pbCreate => 'Sicherungsdatei erstellen';

  @override
  String get pbRestore => 'Aus Datei wiederherstellen';

  @override
  String get rbFailed =>
      'Vorgang fehlgeschlagen. Falls eine Wiederherstellung begonnen hatte, können Einstellungen teilweise geändert sein. Verbinden Sie sich neu und prüfen Sie das Funkgerät, bevor Sie es erneut versuchen.';

  @override
  String get rbReady =>
      'Verschlüsselte Sicherung bereit. Kopieren Sie sie und speichern Sie sie in einer Textdatei. Bewahren Sie das Passwort getrennt auf; es kann nicht wiederhergestellt werden.';

  @override
  String get rbReplaceQ => 'Funkgeräteeinstellungen ersetzen?';

  @override
  String rbSummary(
    String source,
    String firmware,
    String date,
    String target,
    int configs,
    int modules,
  ) {
    return 'Sicherung von Funkgerät $source (Firmware $firmware), erstellt am $date.\n\nZiel: $target. Ersetzt Besitzernamen, alle 8 Kanalplätze samt geheimen Schlüsseln, $configs Konfigurationsabschnitte und $modules Module. Geräteidentitäts-/Sicherheitsschlüssel, Sitzungsdaten, Chats auf dem Telefon und Karten werden nicht wiederhergestellt (dafür gibt es die Sicherung der Telefondaten).\n\nSichern Sie zuerst das Ziel. Das Funkgerät kann neu starten oder die Mesh-Verbindung verlieren. Ein Schreibvorgang auf dem Funkgerät kann nach einem Strom- oder Verbindungsausfall kein Zurücksetzen garantieren.';
  }

  @override
  String get rbReplace => 'Einstellungen ersetzen';

  @override
  String get rbRadioChanged => 'Das verbundene Funkgerät hat sich geändert.';

  @override
  String get rbRestored =>
      'Wiederherstellung abgeschlossen. Das erneute Auslesen des Funkgeräts stimmt mit der Sicherung überein.';

  @override
  String get rbTitle => 'Verschlüsselte Funkgerätesicherung';

  @override
  String get rbIntro =>
      'Sichert die aktuelle, von der Firmware gemeldete Konfiguration und Module, alle Kanalplätze und die Besitzernamen. Kanalschlüssel und Netzwerk-/Modul-Zugangsdaten werden mit Passwort verschlüsselt. Geräteidentitätsschlüssel und Sitzungsdaten sind ausgenommen.';

  @override
  String get rbCreate => 'Verschlüsselte Sicherung erstellen';

  @override
  String get rbText => 'Text der verschlüsselten Sicherung';

  @override
  String get rbTextHint =>
      'Fügen Sie eine gespeicherte verschlüsselte Sicherung zum Wiederherstellen ein';

  @override
  String get rbCopied =>
      'Verschlüsselte Sicherung kopiert. Speichern Sie sie in einer Textdatei.';

  @override
  String get rbCopy => 'Verschlüsselte Sicherung kopieren';

  @override
  String get rbReview => 'Prüfen und wiederherstellen';

  @override
  String get raPower => 'Stromversorgung';

  @override
  String get raDisplay => 'Anzeige';

  @override
  String get raLoraQ => 'LoRa-Einstellungen aus der Ferne ändern?';

  @override
  String get raLoraBody =>
      'Landet der Knoten auf einer anderen Region, Voreinstellung oder Frequenz als das restliche Mesh, ist er nicht mehr erreichbar und muss vor Ort repariert werden.';

  @override
  String get raSaveAnyway => 'Trotzdem speichern';

  @override
  String raSent(String section) {
    return 'Einstellungen für $section gesendet. Der Knoten startet eventuell neu, um sie zu übernehmen.';
  }

  @override
  String get raNameSent => 'Name an den Knoten gesendet.';

  @override
  String raRestartQ(String name) {
    return '$name neu starten?';
  }

  @override
  String get raRestartBody =>
      'Der Knoten ist beim Neustart kurz nicht im Mesh.';

  @override
  String get raRestart => 'Neu starten';

  @override
  String get raRestartRequested => 'Neustart angefordert.';

  @override
  String get raDiscardQ => 'Änderungen verwerfen?';

  @override
  String get raDiscardBody =>
      'Ihre Änderungen wurden nicht an den Knoten gesendet.';

  @override
  String get raDiscard => 'Verwerfen';

  @override
  String get raTitle => 'Fernverwaltung';

  @override
  String get raIntro =>
      'Ändern Sie die Einstellungen dieses Knotens über das Mesh. Jede Anfrage verbraucht Sendezeit und kann bis zu einer Minute dauern.';

  @override
  String get raUnavailable => 'Fernverwaltung ist nicht verfügbar';

  @override
  String get raWaiting => 'Warte auf den Knoten';

  @override
  String get raAccess => 'Zugriff';

  @override
  String get raAccessHint =>
      'Fragen Sie den Knoten nach seinen Angaben. Antwortet er, darf Ihr Funkgerät ihn verwalten.';

  @override
  String get raCheckAccess => 'Zugriff prüfen';

  @override
  String get raAccessConfirmed => 'Zugriff bestätigt';

  @override
  String raFirmware(String version, String role) {
    return 'Firmware $version · $role';
  }

  @override
  String get raUnknown => 'unbekannt';

  @override
  String get raNoName => 'Kein Name';

  @override
  String raShortName(String name) {
    return 'Kurzname $name';
  }

  @override
  String get raRename => 'Umbenennen';

  @override
  String get raRestartNode => 'Knoten neu starten';

  @override
  String get raSettings => 'Einstellungen';

  @override
  String get raLoraWarning =>
      'Eine falsche LoRa-Einstellung kann diesen Knoten vom Mesh abschneiden. Ändern Sie sie nur, wenn Sie den Knoten vor Ort erreichen können.';

  @override
  String raSend(String section) {
    return 'Einstellungen für $section senden';
  }

  @override
  String get raUndo => 'Rückgängig';

  @override
  String get raKeyTitle => 'Admin-Schlüssel Ihres Funkgeräts';

  @override
  String raKeyBody(String name) {
    return 'Bevor $name Änderungen annimmt, trägt der Besitzer diesen Schlüssel mit einer beliebigen Meshtastic-App unter Funkgeräteeinstellungen → Sicherheit → Admin-Schlüssel ein.';
  }

  @override
  String get raNoKey =>
      'Ihr Funkgerät hat seinen Schlüssel noch nicht gemeldet.';

  @override
  String get raCopyKey => 'Admin-Schlüssel kopieren';

  @override
  String get raKeyCopied => 'Admin-Schlüssel kopiert.';

  @override
  String get raRenameTitle => 'Knoten umbenennen';

  @override
  String get raSendButton => 'Senden';

  @override
  String get frSaluteTitle => 'SALUTE-Meldung';

  @override
  String get frNineTitle => '9-Line-Rettungsanforderung';

  @override
  String get frSaluteS => 'Größe';

  @override
  String get frSaluteSHint => 'Wie viele Personen oder Fahrzeuge';

  @override
  String get frSaluteA => 'Tätigkeit';

  @override
  String get frSaluteAHint => 'Was sie tun';

  @override
  String get frSaluteL => 'Ort';

  @override
  String get frSaluteLHint => 'Wo sie sind';

  @override
  String get frSaluteU => 'Einheit';

  @override
  String get frSaluteUHint => 'Wer sie sind, Uniform oder Kennzeichen';

  @override
  String get frSaluteT => 'Zeit';

  @override
  String get frSaluteTHint => 'Wann Sie sie gesehen haben';

  @override
  String get frSaluteE => 'Ausrüstung';

  @override
  String get frSaluteEHint => 'Was sie bei sich haben';

  @override
  String get frNine1 => 'Abholort';

  @override
  String get frNine1Hint => 'Koordinaten oder Orientierungspunkt';

  @override
  String get frNine2 => 'Funkfrequenz und Rufzeichen';

  @override
  String get frNine2Hint => 'Wie Sie erreichbar sind';

  @override
  String get frNine3 => 'Patienten nach Dringlichkeit';

  @override
  String get frNine3Hint => 'Zum Beispiel 1 dringend, 2 Routine';

  @override
  String get frNine4 => 'Spezialausrüstung';

  @override
  String get frNine4Hint => 'Keine, Winde, Bergung, Beatmungsgerät';

  @override
  String get frNine5 => 'Patienten nach Art';

  @override
  String get frNine5Hint => 'Trage oder gehfähig';

  @override
  String get frNine6 => 'Sicherheit am Abholort';

  @override
  String get frNine6Hint => 'Keine Bedrohung, möglich oder bewaffnete Eskorte';

  @override
  String get frNine7 => 'Wie der Ort markiert ist';

  @override
  String get frNine7Hint => 'Tafel, Rauch, Licht oder keine';

  @override
  String get frNine8 => 'Patientenstatus';

  @override
  String get frNine8Hint => 'Wer die Patienten sind';

  @override
  String get frNine9 => 'Gefahren und Gelände';

  @override
  String get frNine9Hint => 'Gefälle, Leitungen, Kontamination';

  @override
  String get svcConnectToCheckIn =>
      'Verbinden Sie ein Funkgerät, um sich zu melden.';

  @override
  String get svcChooseContacts => 'Wählen Sie zuerst Tourkontakte.';

  @override
  String get svcConnectToSos =>
      'Verbinden Sie ein Funkgerät, um ein SOS zu senden.';

  @override
  String get svcChooseSosTargets =>
      'Wählen Sie zuerst Tourkontakte oder einen SOS-Kanal.';

  @override
  String svcFirmwareUnsupported(String version, String minimum, String url) {
    return 'Ihr Funkgerät nutzt Firmware $version. NOTORYX Connect braucht $minimum oder neuer, um Funkgeräteeinstellungen zu ändern, daher sind die Einstellungen nur lesbar. Nachrichten funktionieren weiterhin. Aktualisieren unter $url.';
  }

  @override
  String svcFirmwareOutdated(String version, String recommended, String url) {
    return 'Ihr Funkgerät nutzt Firmware $version. Ein Update auf $recommended oder neuer unter $url schaltet neuere Funktionen wie Sensorwerte und die Prüfung von Sicherheitsschlüsseln frei.';
  }

  @override
  String get svcToday => 'Heute';

  @override
  String get svcYesterday => 'Gestern';

  @override
  String get svcLowBatteryOwn => 'Der Akku Ihres Funkgeräts ist schwach';

  @override
  String svcLowBattery(String name) {
    return 'Akku von $name ist schwach';
  }

  @override
  String svcLowBatteryOwnBody(int level) {
    return 'Ihr Funkgerät meldet $level % Akku.';
  }

  @override
  String svcLowBatteryBody(String name, int level) {
    return '$name meldet $level % Akku.';
  }

  @override
  String svcNewNode(String name) {
    return 'Neuer Knoten: $name';
  }

  @override
  String svcNewNodeBody(String name) {
    return 'Ihr Funkgerät hat $name zum ersten Mal gehört.';
  }

  @override
  String get svcMeshQuieter => 'Das Mesh ist stiller geworden';

  @override
  String svcMeshQuieterBody(int active, int peak) {
    return 'In der letzten Stunde $active Knoten gehört, zuvor $peak. Vielleicht ist ein Repeater ausgefallen oder Sie sind außer Reichweite.';
  }

  @override
  String svcQuiet(String name) {
    return '$name ist verstummt';
  }

  @override
  String svcQuietBody(String time) {
    return 'Seit $time nicht gehört.';
  }

  @override
  String svcHoursMinutes(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String svcMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String get svcReply => 'Antworten';

  @override
  String get svcDirectChannel => 'Direktnachrichten';

  @override
  String get svcDirectChannelSub =>
      'Nachrichten, die Ihnen über das Mesh gesendet werden.';

  @override
  String get svcChannelChannel => 'Kanalnachrichten';

  @override
  String get svcChannelChannelSub => 'Nachrichten auf Ihren Mesh-Kanälen.';

  @override
  String get svcFieldChannel => 'Feldwarnungen';

  @override
  String get svcFieldChannelSub =>
      'Schwacher Akku, neue Knoten und verstummte Favoriten.';

  @override
  String svcFromChannel(String sender, int channel) {
    return '$sender • Kanal $channel';
  }

  @override
  String mapHeatSummary(int strong, int fair, int weak, int readings) {
    return 'Abdeckungskarte: $strong starke, $fair mittlere, $weak schwache Bereiche, aus $readings Messungen.';
  }

  @override
  String get nrTitle => 'Wechsel auf ein neues Funkgerät';

  @override
  String nrSub(int done, int total) {
    return '$done von $total erledigt';
  }

  @override
  String get nrStep1 =>
      'Erstellen Sie hier mit dem alten Funkgerät eine verschlüsselte Sicherung und bewahren Sie den Text sicher auf.';

  @override
  String get nrStep2 =>
      'Notieren Sie Region und Modem-Voreinstellung des alten Funkgeräts (Funkgeräteeinstellungen → LoRa).';

  @override
  String get nrStep3 =>
      'Aktualisieren Sie die Firmware des neuen Funkgeräts auf dieselbe oder eine neuere Version.';

  @override
  String get nrStep4 =>
      'Verbinden Sie das neue Funkgerät und stellen Sie zuerst die Region ein, damit es senden darf.';

  @override
  String get nrStep5 =>
      'Fügen Sie die Sicherung ein, prüfen Sie sie und stellen Sie sie wieder her. Verwenden Sie dasselbe Passwort.';

  @override
  String get nrStep6 =>
      'Prüfen Sie die Kanäle: Namen und Schlüssel sollten übereinstimmen. Senden Sie auf jedem Kanal eine Testnachricht an jemanden.';

  @override
  String get nrStep7 =>
      'Das neue Funkgerät hat eine eigene Knoten-ID und einen eigenen Sicherheitsschlüssel. Informieren Sie Ihre Kontakte und tragen Sie es auf ferngesteuerten Knoten erneut als Admin ein.';

  @override
  String get nrReset => 'Von vorn beginnen';

  @override
  String get cpLabel => 'Auf diesem Kanal geteilte Position';

  @override
  String get cpHelp =>
      'Wie genau die Position Ihres Funkgeräts auf diesem Kanal gesendet wird. Andere Kanäle behalten ihre eigene Einstellung.';

  @override
  String get cpNotSet => 'Nicht festgelegt: Die Firmware entscheidet';

  @override
  String get cpNone => 'Position nicht teilen';

  @override
  String get cpExact => 'Genaue Position';

  @override
  String cpWithin(String distance) {
    return 'Auf etwa $distance genau';
  }

  @override
  String get rdBattery => 'Akku des Funkgeräts';

  @override
  String get rdNotReported => 'Noch nicht gemeldet.';

  @override
  String get rdExternal => 'An externer Stromversorgung.';

  @override
  String rdChargeNow(int level) {
    return '$level %. Laden Sie das Funkgerät vor dem Aufbruch.';
  }

  @override
  String rdChargeSoon(int level) {
    return '$level %. Laden Sie es auf oder nehmen Sie eine Powerbank mit.';
  }

  @override
  String rdLevel(int level) {
    return '$level %.';
  }

  @override
  String get rdFirmware => 'Firmware';

  @override
  String get rdConnectToCheck => 'Verbinden Sie Ihr Funkgerät zum Prüfen.';

  @override
  String get rdTooOld => 'Zu alt.';

  @override
  String get rdUpdateRecommended => 'Update empfohlen.';

  @override
  String get rdVersionUnknown => 'Version nicht gemeldet.';

  @override
  String get rdSupported => 'Unterstützt.';

  @override
  String get rdChannels => 'Kanäle';

  @override
  String get rdNoChannels => 'Keine Kanäle auf diesem Funkgerät.';

  @override
  String rdSosChannelGone(int channel) {
    return 'SOS-Kanal $channel existiert nicht mehr. Wählen Sie in Ihrem Tourplan einen anderen.';
  }

  @override
  String rdChannelsSet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Kanäle eingerichtet.',
      one: '$count Kanal eingerichtet.',
    );
    return '$_temp0';
  }

  @override
  String get rdContacts => 'Tourkontakte';

  @override
  String get rdChooseContacts =>
      'Wählen Sie, wer Ihre Meldungen und Ihr SOS erhält.';

  @override
  String rdNoRoute(String names) {
    return 'Keine Route zu $names.';
  }

  @override
  String rdNotHeard(String names) {
    return 'In den letzten 2 Stunden nicht gehört: $names. Machen Sie einen Routentest oder prüfen Sie, ob sie eingeschaltet sind.';
  }

  @override
  String rdAllHeard(int count) {
    return 'Alle $count kürzlich gehört.';
  }

  @override
  String get rdPosition => 'Position';

  @override
  String get rdRecentPosition => 'Ihr Funkgerät hat eine aktuelle Position.';

  @override
  String get rdWaitingPhone =>
      'Warte auf eine Position von diesem Telefon. Prüfen Sie, ob die Standortfreigabe an ist.';

  @override
  String get rdNoPosition =>
      'Keine aktuelle Position, andere sehen also nicht, wo Sie sind. Schalten Sie das GPS des Funkgeräts ein oder teilen Sie den Standort dieses Telefons.';

  @override
  String get rdBackground => 'Hintergrund';

  @override
  String get rdBackgroundRestricted =>
      'Die Akkuoptimierung kann die Verbindung bei ausgeschaltetem Bildschirm trennen. Stellen Sie NOTORYX Connect auf „Uneingeschränkt\".';

  @override
  String get rdBackgroundOk =>
      'Die App kann bei ausgeschaltetem Bildschirm verbunden bleiben.';

  @override
  String get rdCouldntCheck => 'Prüfung nicht möglich.';

  @override
  String get rpTitle => 'Bereitschaftsprüfung';

  @override
  String get rpReady => 'Startklar';

  @override
  String get rpCheck => 'Prüfen Sie diese Punkte vor dem Aufbruch';

  @override
  String get rpNotReady => 'Noch nicht bereit';

  @override
  String get rpNeedRadio => 'Einige Prüfungen brauchen Ihr Funkgerät';

  @override
  String get rpNotReceived =>
      'Gesendet oder wartend heißt nicht empfangen. Vereinbaren Sie einen Ausweichplan.';

  @override
  String get rpTestRoute => 'Route testen';

  @override
  String get rpTestHint =>
      'Sendet eine Routenanfrage an diesen Kontakt. In ausgelasteten Meshes sparsam verwenden.';

  @override
  String get rpRouteFound => 'Route gefunden';

  @override
  String get rpNoRoute => 'Keine Route gefunden';

  @override
  String get rpNotTested => 'Nicht getestet';

  @override
  String get rpTest => 'Testen';

  @override
  String get rpStatusReady => 'Bereit';

  @override
  String get rpStatusCheck => 'Prüfen';

  @override
  String get rpStatusFix => 'Zuerst beheben';

  @override
  String get rpStatusUnknown => 'Unbekannt';

  @override
  String get cdFixBluetooth => 'Bluetooth einschalten';

  @override
  String get cdFixPermission => 'Bluetooth-Zugriff erlauben';

  @override
  String get cdFixBattery => 'Akkueinstellungen öffnen';

  @override
  String get cdFixRetry => 'Erneut versuchen';

  @override
  String get cdFixScan => 'Nach Funkgeräten suchen';

  @override
  String get cdFixFirmware => 'So aktualisieren Sie';

  @override
  String get cdTheRadio => 'das Funkgerät';

  @override
  String get cdYourRadio => 'Ihr Funkgerät';

  @override
  String get cdBluetoothOffDetail =>
      'Bluetooth ist aus. Schalten Sie es ein, dann verbindet sich die App von selbst neu.';

  @override
  String get cdPermissionDetail =>
      'Die App darf Bluetooth nicht verwenden. Erlauben Sie „Geräte in der Nähe\", wenn Sie gefragt werden, oder unter Android-Einstellungen → Apps → NOTORYX Connect → Berechtigungen.';

  @override
  String cdPairedDetail(String name) {
    return '$name ist eventuell mit einem anderen Telefon oder einer anderen App verbunden. Ein Funkgerät spricht immer nur mit einem Telefon: Schließen Sie die andere App oder schalten Sie Bluetooth am anderen Telefon aus und versuchen Sie es erneut. Klappt es weiterhin nicht, entfernen Sie das Funkgerät in den Bluetooth-Einstellungen von Android und koppeln Sie es neu.';
  }

  @override
  String cdTimeoutDetail(String name) {
    return '$name hat nicht rechtzeitig geantwortet. Gehen Sie näher heran, prüfen Sie, ob es eingeschaltet ist, oder starten Sie es neu und versuchen Sie es erneut.';
  }

  @override
  String get cdNetworkDetail =>
      'Das Funkgerät ist über das Netzwerk nicht erreichbar. Prüfen Sie, ob Telefon und Funkgerät im selben WLAN sind und Adresse und Port (meist 4403) stimmen.';

  @override
  String get cdUsbDetail =>
      'Die USB-Verbindung ist fehlgeschlagen. Ziehen Sie das Kabel ab, stecken Sie es wieder ein und erlauben Sie den USB-Zugriff, wenn Android fragt.';

  @override
  String cdGaveUpDetail(String name) {
    return 'Die Verbindung ist abgebrochen und das Neuverbinden hat nicht geklappt. Prüfen Sie, ob $name eingeschaltet und in Reichweite ist, und versuchen Sie es erneut.';
  }

  @override
  String get cdNotMeshtasticDetail =>
      'Das Gerät hat geantwortet, scheint aber kein Meshtastic-Funkgerät zu sein, oder seine Firmware ist zu alt.';

  @override
  String get cdUnknownProblem => 'Unbekanntes Problem.';

  @override
  String get cdBluetooth => 'Bluetooth';

  @override
  String get cdOn => 'An.';

  @override
  String get cdBluetoothOff => 'Bluetooth ist aus.';

  @override
  String get cdCouldntCheck => 'Prüfung nicht möglich.';

  @override
  String get cdAccess => 'Bluetooth-Zugriff';

  @override
  String get cdAllowed => 'Erlaubt.';

  @override
  String get cdNotAllowed =>
      'Die App darf keine Funkgeräte suchen und sich nicht mit ihnen verbinden.';

  @override
  String get cdLink => 'Funkverbindung';

  @override
  String cdConnectedTo(String name) {
    return 'Verbunden mit $name.';
  }

  @override
  String cdConnectingTo(String name) {
    return 'Verbinde mit $name…';
  }

  @override
  String get cdNoneFound =>
      'Keine Funkgeräte gefunden. Prüfen Sie, ob das Funkgerät eingeschaltet und wenige Meter entfernt ist, Bluetooth in seinen Einstellungen aktiviert ist und es nicht mit einem anderen Telefon verbunden ist.';

  @override
  String get cdNotConnected => 'Nicht verbunden.';

  @override
  String get cdBackground => 'Hintergrund';

  @override
  String get cdBatteryOptimised =>
      'Die Akkuoptimierung kann die Funkverbindung bei ausgeschaltetem Bildschirm trennen. Stellen Sie NOTORYX Connect auf „Uneingeschränkt\".';

  @override
  String get cdBackgroundOk =>
      'Die Verbindung kann bei ausgeschaltetem Bildschirm offen bleiben.';

  @override
  String get cdFirmware => 'Firmware';

  @override
  String get cdFirmwareTooOld => 'Firmware zu alt.';

  @override
  String get cdSupported => 'Unterstützt.';

  @override
  String get cpFlasherCopied =>
      'flasher.meshtastic.org kopiert. Öffnen Sie es auf einem Computer mit angeschlossenem Funkgerät.';

  @override
  String cpFixFailed(String error) {
    return 'Das hat nicht geklappt: $error';
  }

  @override
  String get cpReportCopied =>
      'Bericht kopiert. Er enthält nur Verbindungsdaten: keine Nachrichten, Schlüssel oder Positionen.';

  @override
  String get cpTitle => 'Verbindungsdiagnose';

  @override
  String get cpChecking => 'Prüfe…';

  @override
  String get cpNoProblems => 'Keine Probleme gefunden';

  @override
  String cpProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Probleme gefunden',
      one: '1 Problem gefunden',
    );
    return '$_temp0';
  }

  @override
  String get cpStillFails =>
      'Wenn sich das Funkgerät weiterhin nicht verbindet, kopieren Sie den Bericht unten und teilen Sie ihn.';

  @override
  String get cpFixFirst =>
      'Beheben Sie das erste Problem und prüfen Sie dann erneut.';

  @override
  String get cpCheckAgain => 'Erneut prüfen';

  @override
  String get cpCopyReport => 'Bericht kopieren';

  @override
  String get cpRecentEvents => 'Letzte Verbindungsereignisse';

  @override
  String get cpNoEvents =>
      'Noch nichts. Ereignisse erscheinen hier, während die App sich verbindet.';

  @override
  String get cpOk => 'OK';

  @override
  String get cpProblem => 'Problem';

  @override
  String get cpUnknown => 'Unbekannt';

  @override
  String get sntTitle => 'Community-Moderation';

  @override
  String get sntToolSubtitle =>
      'Spam an NOTORYX-Moderatoren melden und markierte Knoten sehen';

  @override
  String get sntIntro =>
      'Meldungen gehen an NOTORYX-Moderatoren, die jede einzeln von Hand prüfen. Bestätigte Sperren kommen als Hinweisliste zurück: Markierte Knoten erhalten eine Kennzeichnung, im Mesh wird nichts blockiert.';

  @override
  String get sntEnable => 'Community-Moderation verwenden';

  @override
  String get sntEnableSub =>
      'Standardmäßig aus. Solange sie aus ist, kontaktiert NOTORYX den Moderationsdienst nie.';

  @override
  String get sntHide => 'Nachrichten von markierten Absendern ausblenden';

  @override
  String get sntHideSub =>
      'Nur Kanalnachrichten. Sie können das jederzeit ausschalten.';

  @override
  String sntSynced(String time) {
    return 'Sperrliste aktualisiert $time';
  }

  @override
  String get sntNeverSynced => 'Sperrliste noch nicht heruntergeladen';

  @override
  String sntFlaggedCount(int count) {
    return 'Markierte Knoten: $count';
  }

  @override
  String sntQueued(int count) {
    return 'Wartende Meldungen: $count';
  }

  @override
  String get sntRefresh => 'Jetzt aktualisieren';

  @override
  String get sntYourNode => 'Ihr Knoten';

  @override
  String get sntYourNodeClear => 'Ihr Knoten ist nicht markiert.';

  @override
  String sntYourNodeFlagged(String caseRef) {
    return 'Ihr Knoten ist markiert (Fall $caseRef). Falls das ein Fehler ist, können Sie Einspruch einlegen.';
  }

  @override
  String get sntYourNodeUnknown =>
      'Verbinden Sie ein Funkgerät, um Ihren Knoten zu prüfen.';

  @override
  String get sntAppealPending => 'Ihr Einspruch wird geprüft.';

  @override
  String get sntAppeal => 'Einspruch einlegen';

  @override
  String get sntAppealOther => 'Einspruch zu einer Fallnummer einlegen';

  @override
  String get sntYourReports => 'Ihre letzten Meldungen';

  @override
  String get sntReport => 'An Moderatoren melden';

  @override
  String sntReportTitle(String name) {
    return '$name melden';
  }

  @override
  String get sntReasonSpam => 'Spam oder Werbung';

  @override
  String get sntReasonFlooding => 'Überfluten des Mesh';

  @override
  String get sntReasonAbuse => 'Belästigung oder Missbrauch';

  @override
  String get sntReasonImpersonation => 'Identitätsvortäuschung';

  @override
  String get sntReasonOther => 'Sonstiges';

  @override
  String get sntNote => 'Details (optional)';

  @override
  String get sntIncludeMessage => 'Diese Nachricht beifügen';

  @override
  String get sntSends =>
      'Sendet ID und Namen des Knotens, Ihren Grund und, falls angehakt, diese Nachricht. Nicht Ihren Namen, Schlüssel oder Standort.';

  @override
  String get sntSend => 'Meldung senden';

  @override
  String sntSent(String caseRef) {
    return 'Meldung gesendet ($caseRef)';
  }

  @override
  String get sntQueuedOne =>
      'Keine Verbindung. Die Meldung wird später gesendet.';

  @override
  String sntRejected(String message) {
    return 'Meldung nicht angenommen: $message';
  }

  @override
  String get sntOffPrompt => 'Community-Moderation einschalten?';

  @override
  String get sntTurnOn => 'Einschalten';

  @override
  String get sntFlagged => 'Markiert';

  @override
  String sntFlaggedHint(String caseRef) {
    return 'Von NOTORYX-Moderatoren markiert (Fall $caseRef). Nur als Hinweis.';
  }

  @override
  String get sntCaseRef => 'Fallnummer (SNT-1234)';

  @override
  String get sntStatement => 'Warum sollte die Sperre aufgehoben werden?';

  @override
  String get sntContact => 'Kontakt (optional, nur für Moderatoren sichtbar)';

  @override
  String get sntAppealSend => 'Einspruch senden';

  @override
  String get sntAppealReceived =>
      'Einspruch gesendet. Ein Moderator prüft ihn.';

  @override
  String get sntAppealUnknown => 'Kein Meshtastic-Fall hat diese Nummer.';

  @override
  String get sntAppealNotOpen =>
      'Dieser Fall hat keine aktive Sperre, oder ein Einspruch wartet bereits.';

  @override
  String get sntAppealTooMany =>
      'Zu viele Einsprüche. Versuchen Sie es in einer Minute erneut.';

  @override
  String get sntFailed =>
      'Der Moderationsdienst ist nicht erreichbar. Versuchen Sie es später erneut.';

  @override
  String get pvSent7 =>
      'Meldungen, Einsprüche und Abfragen der Sperrliste an NOTORYX-Moderatoren über sentinel-relay.meshmayhem.org, nur wenn Sie die Community-Moderation einschalten';

  @override
  String get psTitle => 'Ort suchen';

  @override
  String get psHint => 'Knoten, Wegpunkt oder Ortsname';

  @override
  String get psNoLocal =>
      'Kein Knoten oder Wegpunkt passt. Versuchen Sie die Online-Suche.';

  @override
  String get psOnlineNote =>
      'Die Online-Suche sendet Ihre Eingabe an den Nominatim-Dienst von OpenStreetMap, der auch Ihre IP-Adresse sieht. Sie braucht Internetzugang.';

  @override
  String get psSearchOnline => 'Online suchen';

  @override
  String get psTooSoon =>
      'Warten Sie eine Sekunde, bevor Sie erneut online suchen.';

  @override
  String get psOnlineFailed =>
      'Online-Suche fehlgeschlagen. Prüfen Sie, ob das Telefon Internetzugang hat, und versuchen Sie es erneut.';

  @override
  String get psNoOnline => 'Online keine Orte gefunden.';

  @override
  String get psAttribution => 'Ortsdaten © OpenStreetMap-Mitwirkende';

  @override
  String get psKindNode => 'Knoten';

  @override
  String get psKindWaypoint => 'Wegpunkt';

  @override
  String get psKindOnline => 'Ort';

  @override
  String get mapFindPlace => 'Ort suchen';

  @override
  String mapFoundPin(String name) {
    return 'Gefunden: $name';
  }

  @override
  String get pvSent8 =>
      'Was Sie in „Ort suchen\" eingeben, an den Nominatim-Dienst von OpenStreetMap, nur wenn Sie auf „Online suchen\" tippen; er sieht Ihre IP-Adresse';

  @override
  String get takReceiveTitle => 'Von ATAK';

  @override
  String get takReceiveIntro =>
      'Zeigt Markierungen, die ATAK auf diesem Telefon teilt, etwa Teammitglieder und Kartenpunkte, auf der Karte dieser App. Sie bleiben auf diesem Telefon und werden nie über das Mesh gesendet.';

  @override
  String get takReceiveSwitch => 'ATAK-Markierungen auf der Karte zeigen';

  @override
  String get takReceivePort => 'UDP-Port zum Empfangen';

  @override
  String takReceiveStatus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Markierungen angezeigt',
      one: '$count Markierung angezeigt',
      zero: 'Empfangsbereit. Noch keine Markierungen.',
    );
    return '$_temp0';
  }

  @override
  String takReceiveProblem(String error) {
    return 'Empfang nicht möglich: $error';
  }

  @override
  String get takReceiveHowTo =>
      'Öffnen Sie in ATAK Settings, dann Network Preferences, dann Manage Outputs, und fügen Sie einen UDP-Ausgang an 127.0.0.1 auf diesem Port hinzu. Markierungen verschwinden, wenn ATAK sie als veraltet meldet.';

  @override
  String get takClear => 'Markierungen löschen';

  @override
  String get takFriendly => 'Freund';

  @override
  String get takHostile => 'Feind';

  @override
  String get takNeutral => 'Neutral';

  @override
  String get takUnknown => 'Unbekannt';

  @override
  String get takPoint => 'Kartenpunkt';

  @override
  String mapTakPin(String kind, String callsign) {
    return 'ATAK $kind: $callsign';
  }

  @override
  String mapTakUpdated(String time, String stale) {
    return 'Von ATAK, aktualisiert um $time. Angezeigt bis $stale.';
  }

  @override
  String get takSamePort =>
      'Verwenden Sie einen anderen Port als den, an den Positionen gesendet werden.';

  @override
  String get nodesFavoritesOnly => 'Nur Favoriten';

  @override
  String get nodesNoFavorites => 'Noch keine Favoriten';

  @override
  String get nodesNoFavoritesHint =>
      'Öffne einen Knoten und tippe auf seinen Stern, um ihm zu vertrauen. Nur Favoriten zeigt dann nur die Personen, denen du vertraust.';

  @override
  String get mapShowAllNodes => 'Alle Knoten zeigen';

  @override
  String get topologyTitle => 'Netzdiagramm';

  @override
  String get topologyEmpty =>
      'Noch nichts zu zeichnen. Knoten erscheinen, sobald dein Funkgerät weiß, wie viele Sprünge entfernt sie sind, oder ein Knoten Neighbor Info sendet.';

  @override
  String get topologyHint =>
      'Dein Funkgerät ist in der Mitte, jeder Ring ist ein Sprung mehr. Linien sind Verbindungen aus Neighbor-Info-Berichten (dicker = besseres Signal) und direkt gehörte Knoten. Tippe auf einen Punkt, um den Knoten zu öffnen.';

  @override
  String get topologyNoReports =>
      'Noch keine Neighbor-Info-Berichte, daher haben nur direkt gehörte Knoten Linien. Schalte das Neighbor-Info-Modul auf deinen Funkgeräten ein, um mehr Verbindungen zu sehen.';

  @override
  String topologyRing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sprünge entfernt',
      one: '1 Sprung entfernt',
      zero: 'Direkt gehört',
    );
    return '$_temp0';
  }

  @override
  String topologyLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Verbindungen',
      one: '1 Verbindung',
    );
    return '$_temp0';
  }

  @override
  String topologySemantics(int count, int rings) {
    return 'Netzdiagramm: $count Knoten auf $rings Ringen um dein Funkgerät.';
  }

  @override
  String get mapRouteWatchTitle => 'Abseits-der-Route-Alarm';

  @override
  String get mapRouteWatchLimit => 'Alarm, wenn jemand weiter entfernt ist als';

  @override
  String get mapRouteWatchWho => 'Beobachten';

  @override
  String get mapRouteWatchHint =>
      'Jede beobachtete Person, die auf der Route war, löst einmal einen Alarm aus, wenn sie das Limit überschreitet, und erst nach ihrer Rückkehr wieder. Der Alarm funktioniert auch, nachdem die Wegpunkte der Route abgelaufen sind. Eine Route zur Zeit.';

  @override
  String get mapRouteWatchStart => 'Beobachten';

  @override
  String get mapRouteWatchStop => 'Beenden';

  @override
  String mapRouteWatching(String name, String distance) {
    return 'Beobachte $name • Alarm ab $distance';
  }

  @override
  String get njTitle => 'Knotentagebuch';

  @override
  String get njToolSub =>
      'Jeder Knoten, den dieses Telefon gehört hat, und wie er sich verhält';

  @override
  String get njSubtitle =>
      'Auf diesem Telefon für alle Funkgeräte gespeichert. Die Kennzeichnungen sind Schätzungen aus dem Gehörten.';

  @override
  String get njStorageProblem =>
      'Das Tagebuch konnte nicht gelesen werden. Neue Einträge bleiben bis zum Schließen der App erhalten.';

  @override
  String get njEmptyTitle => 'Noch nichts gehört';

  @override
  String get njEmptyDetail =>
      'Knoten erscheinen hier, sobald ein Funkgerät sie zum ersten Mal hört.';

  @override
  String get njSearch => 'Namen, IDs und Tags suchen';

  @override
  String get njAll => 'Alle';

  @override
  String njCount(int shown, int total) {
    return '$shown von $total angezeigt';
  }

  @override
  String get njNoMatch => 'Keine passenden Knoten.';

  @override
  String get njLearning => 'Lernt noch';

  @override
  String njLastHeard(String time) {
    return 'Zuletzt gehört $time';
  }

  @override
  String njFirstHeard(String time) {
    return 'Zuerst gehört $time';
  }

  @override
  String njStats(int heard, int days) {
    return '$heard-mal an $days Tagen gehört';
  }

  @override
  String get njSteadyRelay => 'Dauerhaft aktives Relais';

  @override
  String get njRoamer => 'Unterwegs';

  @override
  String get njRegular => 'Regelmäßiger Besucher';

  @override
  String get njRarelyHeard => 'Selten gehört';

  @override
  String get njNewcomer => 'Neuling';

  @override
  String get njGoneQuiet => 'Verstummt';

  @override
  String get njInternetLinked => 'Über Internet verbunden';

  @override
  String get njConfLow => 'Geringe Sicherheit';

  @override
  String get njConfMedium => 'Mittlere Sicherheit';

  @override
  String get njConfHigh => 'Hohe Sicherheit';

  @override
  String njEvHoursOnAir(int a, int b) {
    return 'In $a der letzten $b Stunden aktiv';
  }

  @override
  String njEvPlacesSpread(int count, String distance) {
    return '$count Orte gemeldet, bis zu $distance auseinander';
  }

  @override
  String njEvStaysPut(String distance) {
    return 'Gemeldete Positionen bleiben innerhalb von $distance';
  }

  @override
  String njEvExternalPower(int count) {
    return '$count Meldungen nannten externe Stromversorgung';
  }

  @override
  String njEvDaysHeard(int count) {
    return 'An $count verschiedenen Tagen gehört';
  }

  @override
  String njEvFewHours(int hours, int days) {
    return 'Nur in $hours Stunden über $days Tage gehört';
  }

  @override
  String njEvFirstHeard(int hours) {
    return 'Zuerst vor $hours Stunden gehört';
  }

  @override
  String njEvSilentDays(int days) {
    return 'Seit $days Tagen still';
  }

  @override
  String njEvViaInternet(int a, int b) {
    return '$a von $b Meldungen kamen über das Internet';
  }

  @override
  String get njWhy => 'Was er meist tut';

  @override
  String get njNoLabels =>
      'Noch zu wenig gehört, um diesen Knoten zu beschreiben.';

  @override
  String get njTags => 'Tags';

  @override
  String get njAddTag => 'Tag hinzufügen';

  @override
  String njAddThisTag(String tag) {
    return 'Tag $tag hinzufügen';
  }

  @override
  String njRemoveTag(String tag) {
    return 'Tag $tag entfernen';
  }

  @override
  String get njNotes => 'Notizen';

  @override
  String get njNoteHint => 'Alles Wissenswerte über diesen Knoten';

  @override
  String get njSaveNote => 'Notiz speichern';

  @override
  String get njSaved => 'Gespeichert';

  @override
  String get njSaveFailed =>
      'Speichern fehlgeschlagen. Die Änderung bleibt bis zum Schließen der App erhalten.';

  @override
  String get drTitle => 'Tagesrückblick';

  @override
  String get drToolSub => 'Abspielen, wo dein Team an einem Tag unterwegs war';

  @override
  String get drSubtitle =>
      'Tour-Kontakte und dieses Funkgerät, 14 Tage auf diesem Telefon gespeichert.';

  @override
  String get drEmptyTitle => 'Noch keine Tage aufgezeichnet';

  @override
  String get drEmptyDetail =>
      'Füge Personen als Tour-Kontakte hinzu. Ab dann werden ihre Positionen pro Tag gespeichert.';

  @override
  String get drDay => 'Tag';

  @override
  String get drNoPositions => 'Keine Positionen an diesem Tag.';

  @override
  String get drPlay => 'Abspielen';

  @override
  String get drPause => 'Pause';

  @override
  String drAt(String time) {
    return 'Um $time';
  }

  @override
  String get drSpeed => 'Tempo';

  @override
  String drSpeedTimes(int times) {
    return '$times×';
  }

  @override
  String get drWho => 'Team zu dieser Zeit';

  @override
  String drNotYet(String time) {
    return 'Erste Position um $time';
  }

  @override
  String drMoving(String time) {
    return 'Unterwegs, letzte Meldung $time';
  }

  @override
  String drStill(String time) {
    return 'Letzte Meldung $time';
  }

  @override
  String drCovered(String distance) {
    return 'Bisher zurückgelegt: $distance';
  }

  @override
  String drMapSummary(int count, String time) {
    return 'Karte von $count Teammitgliedern um $time. Ihre Positionen stehen darunter.';
  }

  @override
  String get clTitle => 'Checklisten';

  @override
  String get clToolSub =>
      'Wiederverwendbare Checklisten, offline, mit gespeicherten Protokollen';

  @override
  String get auTitle => 'Automatisierungen';

  @override
  String get auToolSub =>
      'Regeln, die senden, warnen oder den Kanal wechseln, wenn etwas passiert';

  @override
  String get auSubtitle =>
      'Regeln laufen auf diesem Telefon, solange ein Funkgerät verbunden ist. Ihre Nachrichten beginnen mit [auto], damit andere Automatisierungen sie ignorieren. Jede Regel hält ihre Wartezeit ein, und alle zusammen laufen höchstens 30-mal pro Stunde.';

  @override
  String get auNotReady =>
      'Regeln laufen nur, wenn ein Funkgerät verbunden und bereit ist.';

  @override
  String get auStorageProblem =>
      'Gespeicherte Automatisierungen konnten nicht gelesen oder gespeichert werden.';

  @override
  String get auWebhooks => 'Webanfragen erlauben';

  @override
  String get auWebhooksSub =>
      'Braucht Internet. Webhook-Aktionen senden das Ereignis an die angegebene Adresse. Aus, bis Sie es einschalten.';

  @override
  String get auRules => 'Regeln';

  @override
  String get auEmpty => 'Noch keine Automatisierungen.';

  @override
  String get auNew => 'Neue Automatisierung';

  @override
  String get auEdit => 'Automatisierung bearbeiten';

  @override
  String auToggle(String name) {
    return '$name aktiv';
  }

  @override
  String auWhenAny(String list) {
    return 'Wenn eines eintritt: $list';
  }

  @override
  String auWhenAll(String list) {
    return 'Wenn alle zutreffen: $list';
  }

  @override
  String auThen(String list) {
    return 'Dann: $list';
  }

  @override
  String get auNeedsInternet => 'Braucht Internet';

  @override
  String get auWebOffNote =>
      'Braucht Internet. Webanfragen sind aus, daher läuft dies erst, wenn Sie sie erlauben.';

  @override
  String get auActivity => 'Letzte Aktivität';

  @override
  String get auNoActivity => 'Bisher ist nichts gelaufen.';

  @override
  String auRunOk(String rule, String action) {
    return '$rule: $action';
  }

  @override
  String auRunFailed(String rule, String action, String problem) {
    return '$rule: $action (nicht ausgeführt: $problem)';
  }

  @override
  String get auProblemNotConnected => 'Funkgerät nicht verbunden';

  @override
  String get auProblemWebOff => 'Webanfragen sind aus';

  @override
  String auProblemHttp(int status) {
    return 'Server antwortete $status';
  }

  @override
  String get auProblemFailed => 'fehlgeschlagen';

  @override
  String get auName => 'Name';

  @override
  String get auNeedAll =>
      'Geben Sie einen Namen, mindestens einen Auslöser und mindestens eine Aktion an.';

  @override
  String get auMatch => 'Ausführen, wenn';

  @override
  String get auMatchAny => 'Ein Auslöser (ODER)';

  @override
  String get auMatchAll => 'Alle Auslöser (UND)';

  @override
  String get auTriggers => 'Auslöser';

  @override
  String get auActions => 'Aktionen';

  @override
  String get auAddTrigger => 'Auslöser hinzufügen';

  @override
  String get auAddAction => 'Aktion hinzufügen';

  @override
  String get auRemove => 'Entfernen';

  @override
  String get auCooldown =>
      'Mindestens so lange zwischen zwei Ausführungen warten';

  @override
  String auMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '$count Minute',
    );
    return '$_temp0';
  }

  @override
  String get auSave => 'Speichern';

  @override
  String get auDelete => 'Automatisierung löschen';

  @override
  String get auCancel => 'Abbrechen';

  @override
  String get auAdd => 'Hinzufügen';

  @override
  String get auKindBattery => 'Akku schwach';

  @override
  String get auKindTime => 'Uhrzeit';

  @override
  String get auKindZone => 'Geofence-Zone';

  @override
  String get auKindMessage => 'Nachricht empfangen';

  @override
  String get auKindPresence => 'Knoten online oder offline';

  @override
  String get auKindSend => 'Nachricht senden';

  @override
  String get auKindAlert => 'Warnung anzeigen';

  @override
  String get auKindChannel => 'Kanal wechseln (aus Link hinzufügen)';

  @override
  String get auKindSound => 'Warnton abspielen';

  @override
  String get auKindWebhook => 'Webhook (braucht Internet)';

  @override
  String auTrigBattery(String node, int percent) {
    return 'Akku von $node unter $percent %';
  }

  @override
  String auTrigTime(String time) {
    return 'Täglich um $time';
  }

  @override
  String auTrigTimeDays(String time, String days) {
    return 'Um $time am $days';
  }

  @override
  String auTrigZoneEnter(String who, String zone) {
    return '$who betritt $zone';
  }

  @override
  String auTrigZoneLeave(String who, String zone) {
    return '$who verlässt $zone';
  }

  @override
  String get auZoneMissing => 'eine gelöschte Zone';

  @override
  String get auAnyNode => 'Beliebiger Knoten';

  @override
  String get auTrigMessageAny => 'Jede empfangene Nachricht';

  @override
  String auTrigMessageHas(String text) {
    return 'Nachricht mit „$text“';
  }

  @override
  String auTrigOnline(String node, int minutes) {
    return '$node wieder da nach $minutes Min. Stille';
  }

  @override
  String auTrigOffline(String node, int minutes) {
    return '$node seit $minutes Min. still';
  }

  @override
  String auActSend(String target, String text) {
    return 'An $target senden: $text';
  }

  @override
  String auActAlert(String text) {
    return 'Warnung: $text';
  }

  @override
  String auActWebhook(String host) {
    return 'Webanfrage an $host';
  }

  @override
  String get auNode => 'Knoten';

  @override
  String get auBelow => 'Unter';

  @override
  String get auTime => 'Uhrzeit';

  @override
  String get auDays => 'Tage (keiner gewählt = jeden Tag)';

  @override
  String get auZone => 'Zone';

  @override
  String get auNoZones =>
      'Noch keine Zonen. Legen Sie zuerst auf der Karte eine Geofence-Zone an.';

  @override
  String get auEnters => 'Betritt';

  @override
  String get auLeaves => 'Verlässt';

  @override
  String get auContains => 'Enthält (optional)';

  @override
  String get auDirect => 'Nur Direktnachrichten';

  @override
  String get auChannel => 'Kanal';

  @override
  String auChannelN(int index) {
    return 'Kanal $index';
  }

  @override
  String get auAnywhere => 'Beliebiger Kanal';

  @override
  String get auGoesQuiet => 'Wird still';

  @override
  String get auComesBack => 'Kommt zurück';

  @override
  String get auAfter => 'Nach';

  @override
  String get auEveryone => 'Alle im Kanal';

  @override
  String get auOneNode => 'Ein Knoten';

  @override
  String get auMessage => 'Nachricht';

  @override
  String get auAlertText => 'Warntext';

  @override
  String auPlaceholders(String list) {
    return 'Sie können $list verwenden.';
  }

  @override
  String get auLink => 'Kanal-Freigabelink';

  @override
  String get auLinkHint =>
      'Fügt die Kanäle aus dem Link zum Funkgerät hinzu und behält die vorhandenen.';

  @override
  String get auBadLink => 'Das ist kein Kanal-Freigabelink.';

  @override
  String get auUrl => 'Webadresse (https://…)';

  @override
  String get auBadUrl =>
      'Geben Sie eine vollständige http- oder https-Adresse ein.';

  @override
  String get clSubtitle =>
      'Alles bleibt auf diesem Telefon. Jeder abgeschlossene Durchgang wird mit Zeiten gespeichert und kann exportiert werden.';

  @override
  String get clStorageProblem =>
      'Gespeicherte Checklisten konnten nicht gelesen werden. Änderungen bleiben bis zum Schließen erhalten, nichts wird überschrieben.';

  @override
  String get clInProgress => 'In Arbeit';

  @override
  String get clChecklists => 'Checklisten';

  @override
  String get clCompleted => 'Abgeschlossen';

  @override
  String get clEmptyTitle => 'Noch keine Checklisten';

  @override
  String get clEmptyDetail =>
      'Erstelle eine eigene oder starte mit zwei üblichen.';

  @override
  String get clAddStarters => 'Start-Checklisten hinzufügen';

  @override
  String get clStarterRadio => 'Funkcheck';

  @override
  String get clStarterRadio0 => 'Akku über der Hälfte';

  @override
  String get clStarterRadio1 => 'Kanal und Region passen zum Team';

  @override
  String get clStarterRadio2 => 'Positionsfreigabe wie vereinbart eingestellt';

  @override
  String get clStarterRadio3 => 'Testnachricht zugestellt';

  @override
  String get clStarterRadio4 => 'Ersatzstrom eingepackt';

  @override
  String get clNew => 'Neue Checkliste';

  @override
  String get clEdit => 'Checkliste bearbeiten';

  @override
  String clEditNamed(String name) {
    return '$name bearbeiten';
  }

  @override
  String clStartNamed(String name) {
    return '$name starten';
  }

  @override
  String clSteps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Schritte',
      one: '1 Schritt',
    );
    return '$_temp0';
  }

  @override
  String clProgress(int done, int total) {
    return '$done von $total erledigt';
  }

  @override
  String get clName => 'Name';

  @override
  String get clStepsLabel => 'Schritte';

  @override
  String clStepN(int n) {
    return 'Schritt $n';
  }

  @override
  String clMoveUp(int n) {
    return 'Schritt $n nach oben';
  }

  @override
  String clMoveDown(int n) {
    return 'Schritt $n nach unten';
  }

  @override
  String clRemoveStep(int n) {
    return 'Schritt $n entfernen';
  }

  @override
  String get clAddStep => 'Schritt hinzufügen';

  @override
  String get clNeedTitleAndStep =>
      'Gib der Checkliste einen Namen und mindestens einen Schritt.';

  @override
  String get clSave => 'Checkliste speichern';

  @override
  String get clDelete => 'Löschen';

  @override
  String get clCancel => 'Abbrechen';

  @override
  String get clDeleteTitle => 'Diese Checkliste löschen?';

  @override
  String get clDeleteBody => 'Protokolle früherer Durchgänge bleiben erhalten.';

  @override
  String clStarted(String time) {
    return 'Begonnen $time';
  }

  @override
  String clFinishedAt(String time) {
    return 'Abgeschlossen $time';
  }

  @override
  String clTickedAt(String time) {
    return 'Erledigt $time';
  }

  @override
  String get clNote => 'Notiz';

  @override
  String get clNoNote => 'Keine Notiz.';

  @override
  String get clNoteHint => 'Was zu diesem Durchgang wichtig ist';

  @override
  String get clFinish => 'Abschließen und speichern';

  @override
  String get clFinishEarlyTitle => 'Mit offenen Schritten abschließen?';

  @override
  String clFinishEarlyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Schritte sind offen. Sie werden als nicht erledigt gespeichert.',
      one: '1 Schritt ist offen. Er wird als nicht erledigt gespeichert.',
    );
    return '$_temp0';
  }

  @override
  String get clKeepGoing => 'Weitermachen';

  @override
  String get clExport => 'Protokoll exportieren';

  @override
  String get clExportCsv => 'Tabelle (CSV)';

  @override
  String get clExportJson => 'Datendatei (JSON)';

  @override
  String get clExportFailed => 'Teilen konnte nicht geöffnet werden.';
}
