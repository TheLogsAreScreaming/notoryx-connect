// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabNodes => 'Nœuds';

  @override
  String get tabChats => 'Discussions';

  @override
  String get tabMap => 'Carte';

  @override
  String get tabTools => 'Outils';

  @override
  String get tabSettings => 'Réglages';

  @override
  String get connOffline => 'Hors ligne';

  @override
  String get connScanning => 'Recherche';

  @override
  String get connConnecting => 'Connexion';

  @override
  String get connSyncing => 'Synchronisation';

  @override
  String get connConnected => 'Connecté';

  @override
  String get connError => 'Erreur';

  @override
  String radioStatus(String status) {
    return 'Radio : $status';
  }

  @override
  String radioStatusTip(String status) {
    return 'Radio : $status. Touchez pour gérer.';
  }

  @override
  String get radioStatusHint => 'gérer la radio';

  @override
  String get toolsTitle => 'Outils';

  @override
  String get toolsSubtitle =>
      'Utilitaires pour planifier, tester et mener un déploiement.';

  @override
  String get toolsDoctor => 'Diagnostic de connexion';

  @override
  String get toolsDoctorSub =>
      'Comprendre pourquoi une radio ne se connecte pas ou décroche';

  @override
  String get toolsBeforeYouGo => 'Avant de partir';

  @override
  String get toolsChecklist => 'Liste de contrôle de déploiement';

  @override
  String get toolsBattery => 'Autonomie de la batterie';

  @override
  String get toolsBatterySub =>
      'Estimer les heures à partir de la capacité et de la consommation moyenne';

  @override
  String get toolsCalculate => 'Calculer';

  @override
  String get toolsMeshTools => 'Outils du maillage';

  @override
  String get toolsHealth => 'Santé du maillage et temps d\'antenne';

  @override
  String get toolsHealthSub =>
      'À quel point le canal est occupé et combien votre radio émet';

  @override
  String get toolsLink => 'Planificateur de liaison';

  @override
  String get toolsLinkSub =>
      'Vérifier la ligne de vue entre deux nœuds selon le relief';

  @override
  String get toolsRange => 'Test de portée';

  @override
  String get toolsRangeSub =>
      'Enregistrer les paquets d\'un émetteur de test de portée avec le signal et la distance';

  @override
  String get toolsTraceroute => 'Traceroute';

  @override
  String get toolsStore => 'Stockage et retransmission';

  @override
  String get toolsStoreSub =>
      'Récupérer auprès d\'un routeur les messages manqués';

  @override
  String get toolsBeacons => 'Balises du maillage';

  @override
  String get toolsRecords => 'Registres';

  @override
  String get toolsIncident => 'Journal d\'incidents, modèles et couverture';

  @override
  String get toolsIncidentSub => 'Registres de terrain enregistrés et exports';

  @override
  String get toolsSignal => 'Signal';

  @override
  String get toolsTelemetry => 'Télémétrie en direct';

  @override
  String get toolsNothingYet =>
      'Rien reçu pour l\'instant. Les mesures apparaissent quand les nœuds les envoient.';

  @override
  String get toolsGuide => 'Guide du signal Bluetooth';

  @override
  String get toolsGuideSub => 'Ce que signifient les valeurs de signal (RSSI)';

  @override
  String get toolsScan => 'Rechercher des radios';

  @override
  String get toolsCheck0 => 'Radio chargée';

  @override
  String get toolsCheck1 => 'Antenne branchée';

  @override
  String get toolsCheck2 => 'Région configurée';

  @override
  String get toolsCheck3 => 'Canal principal vérifié';

  @override
  String get toolsCheck4 => 'GPS / règles de position vérifiés';

  @override
  String toolsReady(int done, int total) {
    return '$done sur $total prêts';
  }

  @override
  String get toolsBatteryField => 'Batterie (mAh)';

  @override
  String get toolsDrawField => 'Consommation moyenne (mA)';

  @override
  String toolsAboutHours(String hours) {
    return 'Environ $hours heures';
  }

  @override
  String get toolsTraceReady =>
      'Afficher le chemin des relais vers un nœud et retour';

  @override
  String get toolsTraceOff => 'Connectez une radio pour tracer des routes';

  @override
  String get toolsBeaconsSub =>
      'Entendre les invitations du maillage à proximité et envoyer la vôtre';

  @override
  String toolsBeaconsHeard(int count) {
    return '$count entendues • envoyer la vôtre';
  }

  @override
  String toolsReporting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nœuds envoient des mesures d\'appareil',
      one: '$count nœud envoie des mesures d\'appareil',
    );
    return '$_temp0';
  }

  @override
  String get toolsTelemetryOff =>
      'Connectez une radio pour recevoir la télémétrie';

  @override
  String toolsBatteryPct(int pct) {
    return 'Batterie $pct %';
  }

  @override
  String toolsChannelBusy(String pct) {
    return 'Canal occupé $pct %';
  }

  @override
  String toolsTransmitting(String pct) {
    return 'Émission $pct %';
  }

  @override
  String get toolsSigExcellent => 'Excellent, très proche';

  @override
  String get toolsSigStrong => 'Fort';

  @override
  String get toolsSigUsable => 'Utilisable';

  @override
  String get toolsSigWeak => 'Faible';

  @override
  String get toolsSigVeryWeak => 'Très faible, peut décrocher';

  @override
  String get toolsScanning => 'Recherche…';

  @override
  String toolsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count appareils Bluetooth trouvés',
      one: '$count appareil Bluetooth trouvé',
    );
    return '$_temp0';
  }

  @override
  String get deliveryReceived => 'Reçu';

  @override
  String get deliveryQueued => 'En attente';

  @override
  String get deliverySent => 'Envoyé';

  @override
  String get deliveryDelivered => 'Remis';

  @override
  String get deliveryFailed => 'Non remis';

  @override
  String get hopsDirect => 'Direct';

  @override
  String hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sauts',
      one: '$count saut',
    );
    return '$_temp0';
  }

  @override
  String get chatsNoMention =>
      'Aucun nœud entendu à mentionner pour l\'instant.';

  @override
  String get chatsMentionNode => 'Mentionner un nœud';

  @override
  String get chatsViaMqttFull =>
      'Arrivé par MQTT (internet), pas par les ondes';

  @override
  String get chatsPathUnknown =>
      'Chemin non indiqué par le firmware de l\'expéditeur';

  @override
  String get chatsHeardDirect => 'Entendu directement, sans relais';

  @override
  String chatsLastThrough(String name) {
    return ', en dernier par $name';
  }

  @override
  String chatsLastThroughEnding(String hex) {
    return ', en dernier par un nœud se terminant par $hex';
  }

  @override
  String chatsCameThrough(int hops, String via) {
    String _temp0 = intl.Intl.pluralLogic(
      hops,
      locale: localeName,
      other: 'Passé par $hops relais$via',
      one: 'Passé par $hops relais$via',
    );
    return '$_temp0';
  }

  @override
  String get chatsReact => 'Réagir';

  @override
  String chatsReactEmoji(String emoji) {
    return 'Réagir $emoji';
  }

  @override
  String get chatsNoSignal => 'Pas de mesure du signal';

  @override
  String get chatsUnpin => 'Désépingler';

  @override
  String get chatsPin => 'Épingler';

  @override
  String get chatsCopyText => 'Copier le texte';

  @override
  String get chatsCopied => 'Message copié';

  @override
  String chatsReactionFailed(String error) {
    return 'Réaction non envoyée : $error';
  }

  @override
  String chatsSendFailed(String error) {
    return 'Message non envoyé : $error';
  }

  @override
  String get chatsYou => 'Vous';

  @override
  String get chatsYouLower => 'vous';

  @override
  String chatsChannelN(int n) {
    return 'Canal $n';
  }

  @override
  String get chatsReactHint => 'réagir à ce message';

  @override
  String get chatsViaMqtt => 'via MQTT';

  @override
  String get chatsPinned => 'Épinglé';

  @override
  String get chatsMentionsYou => 'Vous mentionne';

  @override
  String chatsReactions(String list) {
    return 'Réactions : $list';
  }

  @override
  String chatsReactionFrom(String emoji, String name) {
    return '$emoji de $name';
  }

  @override
  String get chatsConnectedSub =>
      'Connecté. Les messages partent tout de suite.';

  @override
  String get chatsOfflineSub =>
      'Hors ligne. Les messages attendent dans une file et partent quand votre radio se connecte.';

  @override
  String get chatsStorageProblem => 'Problème de stockage des messages';

  @override
  String get chatsFilterShowing =>
      'Affichage des messages qui correspondent à vos filtres de mots';

  @override
  String chatsFilterHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages masqués par vos filtres de mots',
      one: '$count message masqué par vos filtres de mots',
    );
    return '$_temp0';
  }

  @override
  String get chatsHide => 'Masquer';

  @override
  String get chatsShow => 'Afficher';

  @override
  String get chatsStatLink => 'Liaison';

  @override
  String get chatsOnline => 'En ligne';

  @override
  String get chatsStatMessages => 'Messages';

  @override
  String get chatsStatQueued => 'En attente';

  @override
  String get chatsNewMessage => 'Nouveau message';

  @override
  String get chatsKeyChanged => 'Clé de sécurité modifiée';

  @override
  String chatsKeyChangedBody(String name) {
    return '$name affiche maintenant une autre clé. Vérifiez auprès de son propriétaire avant d\'envoyer quoi que ce soit de privé. Ouvrez le nœud pour examiner ou approuver la nouvelle clé.';
  }

  @override
  String get chatsTo => 'À';

  @override
  String get chatsEveryone => 'Tout le monde sur le canal';

  @override
  String chatsDirect(String name) {
    return 'Direct • $name';
  }

  @override
  String get chatsChannelLabel => 'Canal';

  @override
  String get chatsChannelBroadcast => 'Canal 0 • Diffusion';

  @override
  String chatsChannelOffline(int n) {
    return 'Canal $n • Hors ligne';
  }

  @override
  String chatsChannelNamed(int n, String name) {
    return 'Canal $n • $name';
  }

  @override
  String get chatsDefault => 'Par défaut';

  @override
  String chatsMessageChannel(int n) {
    return 'Écrire sur le canal $n';
  }

  @override
  String chatsMessageNode(String name) {
    return 'Écrire à $name';
  }

  @override
  String get chatsSend => 'Envoyer';

  @override
  String get chatsQuickReplies => 'Réponses rapides';

  @override
  String get chatsMessages => 'Messages';

  @override
  String get chatsHoldHint => 'Maintenez un message pour plus d\'options';

  @override
  String get chatsSearch => 'Rechercher dans l\'historique';

  @override
  String get chatsClearSearch => 'Effacer la recherche';

  @override
  String get chatsNoMatches => 'Aucun résultat';

  @override
  String get chatsNoMatchesBody =>
      'Aucun message ne correspond à votre recherche.';

  @override
  String get chatsEmpty => 'Aucun message du maillage pour l\'instant';

  @override
  String get chatsEmptyBody =>
      'Les messages de canal et directs apparaissent ici dès que votre radio les entend.';

  @override
  String get chatsNewAbove => 'Nouveaux messages au-dessus';

  @override
  String get chatsAutoReplies => 'Réponses automatiques';

  @override
  String get chatsBot => 'Mode bot';

  @override
  String get chatsBotOn =>
      'Activé. Répond aux messages directs ainsi qu\'à !help et !status, en respectant les heures calmes et les limites de temps d\'antenne.';

  @override
  String get chatsBotOff =>
      'Désactivé. Aucune réponse automatique n\'est envoyée.';

  @override
  String get chatsBotReply => 'Message de réponse du bot';

  @override
  String get chatsBotReplyField =>
      'Message à envoyer quand le mode bot est activé';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonConnect => 'Connecter';

  @override
  String get commonDisconnect => 'Déconnecter';

  @override
  String get agoNow => 'à l\'instant';

  @override
  String agoMin(int n) {
    return 'il y a $n min';
  }

  @override
  String agoHours(int n) {
    return 'il y a $n h';
  }

  @override
  String agoDays(int n) {
    return 'il y a $n j';
  }

  @override
  String get rssiStrong => 'Signal Bluetooth fort';

  @override
  String get rssiUsable => 'Signal Bluetooth utilisable';

  @override
  String get rssiWeak => 'Signal Bluetooth faible';

  @override
  String get rssiVeryWeak => 'Signal Bluetooth très faible';

  @override
  String get heardAny => 'N\'importe quand';

  @override
  String get heardHour => '1 heure';

  @override
  String get heardDay => '24 heures';

  @override
  String get heardWeek => '7 jours';

  @override
  String nodesConnectFailed(String error) {
    return 'Connexion impossible : $error';
  }

  @override
  String nodesUsbFailed(String error) {
    return 'Connexion USB impossible : $error';
  }

  @override
  String nodesNotesFor(String name) {
    return 'Notes pour $name';
  }

  @override
  String get nodesNotesHint => 'Emplacement, antenne, observations…';

  @override
  String nodesConnectedTo(String name) {
    return 'Connecté à $name.';
  }

  @override
  String get nodesYourRadio => 'votre radio';

  @override
  String get nodesFindRadio =>
      'Trouvez votre radio à proximité et connectez-vous en Bluetooth.';

  @override
  String get nodesRadiosFound => 'Radios trouvées';

  @override
  String get nodesMeshNodes => 'Nœuds du maillage';

  @override
  String get nodesStatus => 'État';

  @override
  String get nodesConnProblem => 'Problème de connexion';

  @override
  String get nodesDiagnose => 'Diagnostiquer';

  @override
  String get nodesNearby => 'Radios à proximité';

  @override
  String get nodesLooking => 'Recherche de radios…';

  @override
  String get nodesStopScan => 'Arrêter la recherche';

  @override
  String get nodesRadio => 'Radio';

  @override
  String get nodesOverUsb => 'Par USB';

  @override
  String get nodesOverWifi => 'Par Wi-Fi';

  @override
  String get nodesConnectWifi => 'Se connecter par Wi-Fi';

  @override
  String get nodesConnectUsb => 'Se connecter par USB';

  @override
  String get nodesNoRadios => 'Aucune radio trouvée pour l\'instant';

  @override
  String get nodesNoRadiosBody =>
      'Allumez votre radio, gardez-la près de vous, puis touchez Rechercher des radios.';

  @override
  String get nodesTryDemo => 'Pas de radio ? Essayez la démo';

  @override
  String get nodesMeshtasticRadio => 'Radio Meshtastic';

  @override
  String get nodesBluetoothDevice => 'Appareil Bluetooth';

  @override
  String nodesCount(int count) {
    return 'Nœuds du maillage ($count)';
  }

  @override
  String nodesCountOf(int shown, int total) {
    return 'Nœuds du maillage ($shown sur $total)';
  }

  @override
  String nodesNoneHeard(String window) {
    return 'Aucun nœud entendu sur $window';
  }

  @override
  String get nodesPickLonger =>
      'Choisissez une durée plus longue pour voir les nœuds plus anciens.';

  @override
  String get nodesShowAll => 'Afficher tous les nœuds';

  @override
  String get nodesHealth => 'Santé du maillage';

  @override
  String get nodesDetails => 'Détails';

  @override
  String get nodesKnown => 'Nœuds connus';

  @override
  String get nodesWaiting => 'En attente d\'envoi';

  @override
  String get nodesSignalQuality => 'Qualité du signal';

  @override
  String nodesSignalSummary(int count, String snr) {
    return '$count messages entendus • dernier rapport signal/bruit $snr';
  }

  @override
  String get nodesNotMeasured => 'pas encore mesuré';

  @override
  String nodesSignalHistory(int count) {
    return 'Historique du signal des $count derniers messages';
  }

  @override
  String get nodesSignalStarts =>
      'L\'historique du signal commence quand un autre nœud envoie un message.';

  @override
  String get nodesMeasuredFrom =>
      'Mesuré uniquement à partir des messages texte reçus.';

  @override
  String get nodesEncounters => 'Rencontres enregistrées';

  @override
  String nodesSeen(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vu $count fois • dernière fois $when',
      one: 'Vu $count fois • dernière fois $when',
    );
    return '$_temp0';
  }

  @override
  String get nodesTapNotes => 'Touchez pour ajouter des notes';

  @override
  String get nodesRemoveFav => 'Retirer des favoris';

  @override
  String get nodesAddFav => 'Ajouter aux favoris';

  @override
  String get nodesMore => 'Plus';

  @override
  String get nodesFieldTools => 'Outils de terrain';

  @override
  String get nodesFieldToolsSub =>
      'Référence du signal, listes de contrôle, sauvegardes et plus';

  @override
  String get nodesReadyBanner =>
      'Votre radio est connectée. Les nœuds se mettent à jour en direct quand ils sont entendus.';

  @override
  String get nodesHelpBanner =>
      'Touchez Rechercher des radios, puis Connecter. L\'application vérifie qu\'il s\'agit d\'une radio Meshtastic et télécharge sa liste de nœuds avant qu\'elle soit prête.';

  @override
  String get nodesHeardWithin => 'Afficher les nœuds entendus dans';

  @override
  String get nodesWifiHelp =>
      'Pour les radios avec le Wi-Fi ou l\'Ethernet activé. Votre téléphone doit être sur le même réseau.';

  @override
  String get nodesAddress => 'Adresse de la radio';

  @override
  String get nodesAddressHint => 'p. ex. 192.168.1.42 ou meshtastic.local';

  @override
  String get nodesPort => 'Port';

  @override
  String get nodesPortHelp => 'Meshtastic utilise le 4403';

  @override
  String get nodesUsbHelp =>
      'Branchez la radio au téléphone avec un câble USB de données (un adaptateur OTG peut être nécessaire). Android demande l\'autorisation la première fois.';

  @override
  String nodesUsbListFailed(String error) {
    return 'Impossible de lister les appareils USB : $error';
  }

  @override
  String get nodesNoUsb => 'Aucun appareil USB trouvé';

  @override
  String get nodesNoUsbBody =>
      'Vérifiez que le câble transporte des données, pas seulement du courant, puis actualisez.';

  @override
  String nodesLikelyRadio(String chip) {
    return 'Probablement une radio • $chip';
  }

  @override
  String get nodesOtherUsb => 'Autre appareil USB';

  @override
  String get nodesRefresh => 'Actualiser';

  @override
  String get setRadioSec => 'Radio';

  @override
  String get setRadioConfig => 'Configuration de la radio';

  @override
  String get setIdentity => 'Identité du nœud';

  @override
  String get setChange => 'Modifier les réglages de la radio';

  @override
  String get setChangeSub =>
      'Propriétaire, LoRa, canaux, rôle de l\'appareil et position';

  @override
  String get setDeviceLora => 'Appareil et LoRa';

  @override
  String get setChannels => 'Canaux';

  @override
  String get setModules => 'Modules';

  @override
  String get setShareLoc =>
      'Partager la position du téléphone avec le maillage';

  @override
  String get setPrecision => 'Précision de la position';

  @override
  String get setPrecisionSub => 'Arrondie sur ce téléphone avant l\'envoi';

  @override
  String get setLowPower => 'Mode terrain basse consommation';

  @override
  String get setApp => 'Application';

  @override
  String get setWidget =>
      'Afficher les messages dans le widget de l\'écran d\'accueil';

  @override
  String get setYourData => 'Vos données';

  @override
  String get setRadioBackup => 'Sauvegarde chiffrée de la radio';

  @override
  String get setRadioBackupSub =>
      'Enregistrer ou restaurer les réglages et les clés de canal, protégés par un mot de passe';

  @override
  String get setPhoneBackup => 'Sauvegarde des données du téléphone';

  @override
  String get setPhoneBackupSub =>
      'Discussions, nœuds, points de passage, registres et réglages, pour passer à un nouveau téléphone';

  @override
  String get setPrivacy => 'Confidentialité et données';

  @override
  String get setPrivacySub =>
      'Ce qui est stocké et envoyé ; supprimer l\'historique des discussions ou toutes les données du téléphone';

  @override
  String get setDemo => 'Mode démo';

  @override
  String get setAbout => 'À propos';

  @override
  String get setLicenses => 'Licences tierces';

  @override
  String get setReadAloud => 'Lire les messages à voix haute';

  @override
  String get setReadSub =>
      'Utilise la synthèse vocale du téléphone, même écran éteint';

  @override
  String get setMqttTitle => 'Faire passer MQTT par ce téléphone';

  @override
  String get setBackground => 'Connexion en arrière-plan';

  @override
  String get setOpenSettings => 'Ouvrir les réglages';

  @override
  String get setOfflineTiles => 'Tuiles de carte hors ligne';

  @override
  String get setClear => 'Effacer';

  @override
  String get setAlerts => 'Alertes de terrain';

  @override
  String get setAlertsSub =>
      'Notifications du téléphone uniquement ; rien n\'est envoyé sur le maillage';

  @override
  String get setLowBattery => 'Batterie faible';

  @override
  String get setThreshold => 'Seuil de batterie';

  @override
  String get setNewNode => 'Nouveau nœud';

  @override
  String get setNewNodeSub =>
      'Votre radio entend un nœud pour la première fois';

  @override
  String get setFavQuiet => 'Un favori devient silencieux';

  @override
  String get setMeshQuiet => 'Le maillage devient silencieux';

  @override
  String get setMeshQuietSub =>
      'La moitié ou plus des nœuds que vous entendiez ne sont plus entendus';

  @override
  String get setQuietAfter => 'Silencieux après';

  @override
  String get setRadioData => 'Données de la radio';

  @override
  String get setRadioDataSub =>
      'Radio perdue ou remplacée ? Transférez ses messages, nœuds et historique vers la nouvelle';

  @override
  String get setMoveToConnected => 'Transférer vers la radio connectée';

  @override
  String get setDataUnreadable =>
      'Les données de la radio n\'ont pas pu être lues.';

  @override
  String get setNoData =>
      'Aucune donnée de radio sur ce téléphone pour l\'instant.';

  @override
  String get setFilters => 'Filtres';

  @override
  String get setFilterHelp =>
      'Les messages entrants contenant ces mots sont masqués, pas supprimés.';

  @override
  String get setShowFiltered => 'Afficher les messages filtrés';

  @override
  String get setIgnored => 'Ignorés';

  @override
  String get setUnignore => 'Ne plus ignorer';

  @override
  String get setMuted => 'En sourdine';

  @override
  String get setUnmute => 'Réactiver le son';

  @override
  String get setOffLoc =>
      'Désactivé. La position de votre téléphone n\'est jamais envoyée.';

  @override
  String get setOnNoRadio => 'Activé. Démarre quand une radio est connectée.';

  @override
  String get setOnNoFix => 'Activé. En attente d\'une position GPS.';

  @override
  String setOnSent(String time) {
    return 'Activé. Dernier envoi à $time.';
  }

  @override
  String get setSubtitle =>
      'Votre radio, le comportement de l\'application et vos données.';

  @override
  String get setCanChange => 'Connecté • les réglages peuvent être modifiés';

  @override
  String setReadOnly(String version, String minimum, String url) {
    return 'Lecture seule : le firmware $version est plus ancien que $minimum. Mettez-le à jour sur $url.';
  }

  @override
  String get setConnectToView =>
      'Connectez une radio pour voir et modifier ses réglages';

  @override
  String get setWaitingNode =>
      'En attente des informations de nœud de cette radio';

  @override
  String get setNoLong => 'Pas de nom long';

  @override
  String get setNoShort => 'Pas de nom court';

  @override
  String get setNoId => 'ID non indiqué';

  @override
  String setConfigWait(int count) {
    return 'Pas encore reçu ($count messages de configuration)';
  }

  @override
  String setChannelWait(int count) {
    return 'Pas encore reçu ($count messages de canal)';
  }

  @override
  String setModulesSub(int count) {
    return '$count messages de module reçus. Modifiez-les dans les réglages de la radio.';
  }

  @override
  String setShareLocSub(String status) {
    return '$status\nUtilisé quand la radio n\'a pas son propre GPS. Mise à jour toutes les 5 min, ou plus tôt quand vous bougez.';
  }

  @override
  String get setPrecise => 'Précise';

  @override
  String setAbout2(String distance) {
    return 'Environ $distance';
  }

  @override
  String get setLowPowerSub =>
      'La position partagée utilise un GPS équilibré et se met à jour toutes les 15 min, ou après 200 m de déplacement. La liaison radio et l\'enregistrement de couverture ne changent pas.';

  @override
  String get setWidgetSub =>
      'Désactivé : le widget n\'affiche que le nombre de messages non lus. Activé : il affiche aussi l\'expéditeur et le texte, visibles par quiconque tient le téléphone.';

  @override
  String get setDemoSub =>
      'Découvrez l\'application avec une radio et un maillage fictifs. Rien n\'est envoyé, et vos propres messages et réglages ne sont pas touchés.';

  @override
  String get setDevBuild =>
      'Version de développement • Compagnon de maillage indépendant';

  @override
  String get setConnection => 'Connexion';

  @override
  String get setConnectionSub =>
      'Bluetooth LE • Mode sécurité activé : aucun appareil non vérifié n\'est traité comme un nœud du maillage';

  @override
  String get setTrademark => 'Marques et compatibilité';

  @override
  String get setDevWarning =>
      'Ne comptez pas sur cette version de développement comme seul moyen d\'appeler à l\'aide.';

  @override
  String get setChannelsKept => 'Messages de canal conservés';

  @override
  String setChannelsDeleted(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Messages de canal supprimés après $days jours',
      one: 'Messages de canal supprimés après $days jour',
    );
    return '$_temp0';
  }

  @override
  String setNewestPer(String count) {
    return 'les $count plus récents par conversation';
  }

  @override
  String get setReadOn => 'lecture à voix haute activée';

  @override
  String get setDeleteOld => 'Supprimer les anciens messages de canal';

  @override
  String get setDirectKept => 'Les messages directs sont toujours conservés';

  @override
  String get setNever => 'Jamais';

  @override
  String setAfterDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Après $days jours',
      one: 'Après $days jour',
    );
    return '$_temp0';
  }

  @override
  String get setHistory => 'Historique des messages';

  @override
  String get setHistoryHelp =>
      'Par canal ou conversation directe. Une limite plus basse supprime les messages plus anciens.';

  @override
  String setKeepNewest(String count) {
    return 'Garder les $count plus récents';
  }

  @override
  String get setMqttOff =>
      'Désactivé. Utilise les données de votre téléphone une fois activé.';

  @override
  String get setMqttWait => 'Activé. Attend votre radio.';

  @override
  String get setMqttNoConfig =>
      'Votre radio n\'est pas configurée pour cela. Activez MQTT et « Proxy to client » dans ses réglages.';

  @override
  String setMqttConnected(String host, int up, int down, String kb) {
    return 'Connecté à $host. $up envoyés, $down reçus, environ $kb Ko de données.';
  }

  @override
  String setMqttConnecting(String host) {
    return 'Connexion à $host…';
  }

  @override
  String get setMqttFailed => 'Connexion impossible.';

  @override
  String get setMqttStarting => 'Démarrage…';

  @override
  String get setBgOptimized =>
      'L\'optimisation de la batterie peut mettre NOTORYX Connect en pause lorsqu\'il n\'est pas à l\'écran et couper la liaison radio. Réglez son utilisation de la batterie sur Sans restriction pour rester connecté.';

  @override
  String get setBgAllowed =>
      'Autorisé à fonctionner en arrière-plan. Une notification s\'affiche tant qu\'une radio est connectée.';

  @override
  String get setSizeUnknown => 'Taille inconnue';

  @override
  String setMbSaved(String mb) {
    return '$mb Mo enregistrés';
  }

  @override
  String get setTilesHelp =>
      'Les zones de carte consultées en ligne restent disponibles hors ligne pendant un an (jusqu\'à 500 Mo).';

  @override
  String get setAlertSaveFailed =>
      'Les réglages d\'alerte s\'appliquent maintenant, mais n\'ont pas pu être enregistrés.';

  @override
  String setLowBatterySub(int pct) {
    return 'Votre radio ou un favori indique $pct % ou moins';
  }

  @override
  String setFavQuietSub(String time) {
    return 'Un favori n\'est pas entendu pendant $time alors que vous êtes connecté';
  }

  @override
  String get setTheConnected => 'la radio connectée';

  @override
  String setMoveTitle(String label) {
    return 'Transférer $label ?';
  }

  @override
  String setMoveBody(String to, String id) {
    return 'Ses messages, sa file hors ligne, son historique NodeDex, ses traces et son historique de télémétrie passent à $to. Ce que $to possède déjà est conservé, donc rien n\'est écrasé. $id n\'a ensuite plus d\'entrée propre.\n\nPar précaution, faites d\'abord une sauvegarde des données du téléphone.';
  }

  @override
  String get setMove => 'Transférer';

  @override
  String setMoved(String label, String to) {
    return '$label transféré vers $to.';
  }

  @override
  String setDataCounts(int messages, int nodes, int trails) {
    return '$messages messages • $nodes nœuds • $trails traces';
  }

  @override
  String get setConnectNew =>
      'Connectez la nouvelle radio pour y transférer les données d\'une ancienne radio.';

  @override
  String setFilterCounts(int ignored, int muted, int words) {
    return '$ignored ignorés • $muted en sourdine • $words mots filtrés';
  }

  @override
  String get setFilteredWords => 'Mots filtrés';

  @override
  String get setWordField => 'Mot ou expression';

  @override
  String get setAddWord => 'Ajouter un mot filtré';

  @override
  String setRemoveWord(String word) {
    return 'Retirer $word';
  }

  @override
  String get setIgnoredMuted => 'Nœuds ignorés et en sourdine';

  @override
  String get setNoneIgnored =>
      'Aucun. Ouvrez un nœud pour l\'ignorer ou le mettre en sourdine.';

  @override
  String get chatsForward => 'Transférer';

  @override
  String get chatsForwardTo => 'Transférer à';

  @override
  String get chatsForwardReview => 'Vérifiez le message, puis touchez Envoyer.';

  @override
  String chatsChannelNumbered(int index, String name) {
    return 'Canal $index : $name';
  }

  @override
  String get chatsSchedule => 'Envoyer plus tard';

  @override
  String get chatsSchedule15 => 'Dans 15 minutes';

  @override
  String get chatsSchedule60 => 'Dans 1 heure';

  @override
  String get chatsSchedule240 => 'Dans 4 heures';

  @override
  String get chatsScheduleTomorrow => 'Demain à 8 h 00';

  @override
  String get chatsSchedulePick => 'Choisir une date et une heure';

  @override
  String get chatsScheduleNote =>
      'Ne part que si l\'application est ouverte et la radio connectée.';

  @override
  String chatsScheduleFull(int max) {
    return 'Vous pouvez programmer jusqu\'à $max messages.';
  }

  @override
  String get chatsScheduled => 'Programmé';

  @override
  String chatsScheduledFor(String day, String time) {
    return '$day à $time';
  }

  @override
  String get chatsScheduleMissed =>
      'Non envoyé : la radio n\'était pas connectée à temps';

  @override
  String get chatsScheduleCancel => 'Annuler le message programmé';

  @override
  String get mapNoPositions => 'Aucun nœud n\'a encore indiqué de position';

  @override
  String get mapConnectForPositions =>
      'Connectez une radio pour afficher la position des nœuds';

  @override
  String mapPlaced(int placed, int total) {
    return '$placed nœuds placés sur $total';
  }

  @override
  String mapWaypointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points de passage',
      one: '$count point de passage',
    );
    return '$_temp0';
  }

  @override
  String get mapLongPressHint =>
      'Appuyez longuement sur la carte pour poser un point de passage';

  @override
  String get mapHeardWithin => 'Afficher les nœuds entendus dans';

  @override
  String get mapHeardAny => 'Entendus n\'importe quand';

  @override
  String get mapHeardHour => 'Entendus dans la dernière heure';

  @override
  String get mapHeardDay => 'Entendus dans les dernières 24 heures';

  @override
  String get mapHeardWeek => 'Entendus dans les 7 derniers jours';

  @override
  String get mapShowStreet => 'Afficher le plan des rues';

  @override
  String get mapShowTopo => 'Afficher la carte topographique';

  @override
  String get mapLinkPlanner => 'Planificateur de liaison';

  @override
  String get mapRallyRoutes => 'Points de ralliement et itinéraires';

  @override
  String get mapTeam => 'Équipe';

  @override
  String get mapZones => 'Zones';

  @override
  String get mapExportGpx => 'Exporter en GPX';

  @override
  String get mapHideTrails => 'Masquer les traces';

  @override
  String get mapShowTrails => 'Afficher les traces';

  @override
  String get mapHideLinks => 'Masquer les liaisons radio';

  @override
  String get mapShowLinks => 'Afficher les liaisons radio';

  @override
  String get mapShowAll => 'Afficher tous les nœuds';

  @override
  String mapPlanHint(int max) {
    return 'Touchez la carte pour ajouter des étapes, dans l\'ordre. Jusqu\'à $max.';
  }

  @override
  String mapPlanProgress(int count, int max, String distance) {
    return '$count étapes sur $max • $distance';
  }

  @override
  String get mapUndo => 'Annuler';

  @override
  String get mapShareRoute => 'Partager l\'itinéraire';

  @override
  String get mapRallyIntro =>
      'Les points de ralliement sont là où tout le monde doit se retrouver. Posez-en un par un appui long et choisissez « Point de ralliement ». Les itinéraires sont partagés comme des points de passage numérotés, donc les autres applications Meshtastic voient aussi les étapes.';

  @override
  String get mapRallyPoints => 'Points de ralliement';

  @override
  String get mapNoneYet => 'Aucun pour l\'instant.';

  @override
  String mapDistanceOfYou(String distance, String direction) {
    return '$distance au $direction de vous';
  }

  @override
  String get mapNoOwnPosition => 'Votre radio n\'a pas encore de position';

  @override
  String get mapShowOnMap => 'Afficher sur la carte';

  @override
  String get mapRoutes => 'Itinéraires';

  @override
  String mapStops(int count) {
    return '$count étapes';
  }

  @override
  String mapStopsHeard(int heard, int count) {
    return '$heard étapes entendues sur $count';
  }

  @override
  String get mapFromYou => 'de vous';

  @override
  String mapFromNode(String name) {
    return 'de $name';
  }

  @override
  String get mapPlanRoute => 'Planifier un itinéraire';

  @override
  String get mapConnectForRoutes =>
      'Connectez une radio pour partager des itinéraires';

  @override
  String mapRouteShared(int count) {
    return 'Itinéraire partagé : $count étapes sur le canal 0.';
  }

  @override
  String mapRouteStopped(int sent, int count, String error) {
    return 'Itinéraire interrompu après $sent étapes sur $count : $error';
  }

  @override
  String mapGpxExported(int waypoints, int trails) {
    return '$waypoints points de passage et $trails traces exportés en GPX.';
  }

  @override
  String mapGpxFailed(String error) {
    return 'Export GPX impossible : $error';
  }

  @override
  String get mapWatchTrip => 'Contacts de sortie';

  @override
  String get mapWatchFavorites => 'Favoris';

  @override
  String get mapWatchAll => 'Tous les nœuds';

  @override
  String get mapAlertArrive => 'arrivent';

  @override
  String get mapAlertLeave => 'partent';

  @override
  String get mapAlertBoth => 'arrivent ou partent';

  @override
  String get mapZonesIntro =>
      'Recevez une alerte sur le téléphone quand quelqu\'un arrive à un lieu ou le quitte, comme le camp ou le départ du sentier. Les alertes nécessitent une radio connectée ; rien n\'est envoyé sur le maillage.';

  @override
  String get mapNoZones => 'Aucune zone pour l\'instant.';

  @override
  String mapZoneSummary(String radius, String watch, String alert) {
    return 'Rayon de $radius • $watch • alerte quand ils $alert';
  }

  @override
  String mapDeleteZone(String name) {
    return 'Supprimer $name';
  }

  @override
  String get mapAddZone => 'Ajouter une zone au centre de la carte';

  @override
  String get mapTeamIntro =>
      'Vos contacts de sortie. Touchez-en un pour le trouver sur la carte.';

  @override
  String get mapNoTeam => 'Aucun contact de sortie pour l\'instant';

  @override
  String get mapNoTeamHint =>
      'Ajoutez jusqu\'à 6 personnes dans ACCUEIL → Sortie. Elles apparaissent ici et ressortent sur la carte.';

  @override
  String get mapFreshOk => 'OK';

  @override
  String get mapFreshQuiet => 'SILENCIEUX';

  @override
  String get mapFreshLost => 'PERDU';

  @override
  String get mapConnectForWaypoints =>
      'Connectez une radio pour partager des points de passage.';

  @override
  String mapWaypointShared(String name) {
    return 'Point de passage « $name » partagé sur le canal 0.';
  }

  @override
  String mapWaypointFailed(String error) {
    return 'Partage du point de passage impossible : $error';
  }

  @override
  String get mapNeverExpires => 'N\'expire jamais';

  @override
  String mapExpires(String time) {
    return 'Expire $time';
  }

  @override
  String mapSharedBy(String name) {
    return 'Partagé par $name';
  }

  @override
  String get mapLocked => 'Verrouillé pour son créateur';

  @override
  String get mapDeleteEveryone => 'Supprimer pour tout le monde';

  @override
  String mapDeleted(String name) {
    return '« $name » supprimé.';
  }

  @override
  String mapDeleteFailed(String error) {
    return 'Suppression impossible : $error';
  }

  @override
  String get mapUnknown => 'inconnu';

  @override
  String mapFromThisRadio(String distance) {
    return '$distance de cette radio';
  }

  @override
  String mapPositionHeard(String position, String heard) {
    return 'Position : $position • Entendu : $heard';
  }

  @override
  String get mapDirect => 'direct';

  @override
  String get mapBatteryExternal => 'Batterie : alimentation externe';

  @override
  String mapBattery(int level) {
    return 'Batterie : $level %';
  }

  @override
  String get mapOpenDetails => 'Ouvrir les détails';

  @override
  String get mapThisRadioSuffix => ', cette radio';

  @override
  String mapTripContactSuffix(String summary) {
    return ', contact de sortie, $summary';
  }

  @override
  String get mapRallyPoint => 'Point de ralliement';

  @override
  String get mapWaypoint => 'Point de passage';

  @override
  String get mapExpireHour => '1 heure';

  @override
  String get mapExpireDay => '1 jour';

  @override
  String get mapExpireWeek => '1 semaine';

  @override
  String get mapExpireNever => 'Jamais';

  @override
  String get mapNewWaypoint => 'Nouveau point de passage';

  @override
  String get mapName => 'Nom';

  @override
  String get mapDescription => 'Description (facultative)';

  @override
  String get mapRallySub => 'Là où tout le monde doit se retrouver';

  @override
  String get mapExpiresAfter => 'Expire après';

  @override
  String get mapOnlyMe => 'Seul moi peux modifier ou supprimer';

  @override
  String get mapSharedChannel0 => 'Partagé avec tout le monde sur le canal 0.';

  @override
  String get mapShare => 'Partager';

  @override
  String get mapNewZone => 'Nouvelle zone';

  @override
  String mapCenteredOn(String lat, String lon) {
    return 'Centré sur $lat, $lon';
  }

  @override
  String get mapZoneName => 'Nom, p. ex. Camp';

  @override
  String get mapRadius => 'Rayon';

  @override
  String get mapWatch => 'Surveiller';

  @override
  String get mapAlertWhen => 'Alerter quand ils';

  @override
  String get mapAdd => 'Ajouter';

  @override
  String get mapRouteName => 'Nom de l\'itinéraire';

  @override
  String mapRouteSends(int count) {
    return 'Envoie $count points de passage sur le canal 0, à environ 3 secondes d\'intervalle. Ils expirent au bout d\'un jour.';
  }

  @override
  String get mapShowHeatmap => 'Afficher la carte de couverture';

  @override
  String get mapHideHeatmap => 'Masquer la carte de couverture';

  @override
  String get mapHeatmapEmpty =>
      'Aucune mesure de couverture pour l\'instant. Activez Enregistrer la couverture dans Registres de terrain.';

  @override
  String mapHeatmapSummary(int readings) {
    return 'Couverture : $readings mesures. Les nombres sont le SNR moyen en dB.';
  }

  @override
  String get mapHeatStrong => 'Forte';

  @override
  String get mapHeatFair => 'Moyenne';

  @override
  String get mapHeatWeak => 'Faible';

  @override
  String get mapShowRemembered => 'Afficher les nœuds mémorisés';

  @override
  String get mapHideRemembered => 'Masquer les nœuds mémorisés';

  @override
  String get mapRememberedNone =>
      'Aucun nœud mémorisé avec une position enregistrée.';

  @override
  String mapRememberedPin(String name, String when) {
    return '$name, mémorisé, vu pour la dernière fois $when';
  }

  @override
  String get mapRememberedNote =>
      'Votre radio ne liste plus ce nœud. Voici où il a signalé sa position en dernier.';

  @override
  String mapLastSeen(String when) {
    return 'Vu pour la dernière fois $when';
  }

  @override
  String get lockTitle => 'NOTORYX Connect est verrouillé';

  @override
  String get lockBody =>
      'Votre radio reste connectée pendant que l\'application est verrouillée.';

  @override
  String get lockUnlock => 'Déverrouiller';

  @override
  String get lockReason => 'Déverrouiller NOTORYX Connect';

  @override
  String get takTitle => 'Lien ATAK';

  @override
  String get toolsTakSub => 'Échanger des positions avec ATAK sur ce téléphone';

  @override
  String get takIntro =>
      'Envoie la position de chaque nœud du maillage à ATAK sur ce téléphone, toutes les 30 secondes. Rien ne quitte le téléphone, et rien ne part sur le maillage.';

  @override
  String get takSwitch => 'Envoyer les positions du maillage à ATAK';

  @override
  String get takPort => 'Port UDP';

  @override
  String get takBadPort => 'Utilisez un nombre entre 1024 et 65535.';

  @override
  String takStatus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Envoi de $count nœuds',
      one: 'Envoi de $count nœud',
    );
    return '$_temp0';
  }

  @override
  String takProblem(String error) {
    return 'Envoi impossible : $error';
  }

  @override
  String get takHowTo =>
      'Dans ATAK, ouvrez Settings, puis Network Preferences, puis Manage Inputs, et ajoutez une entrée UDP sur ce port. Les nœuds sans position dans la dernière heure sont exclus.';

  @override
  String ndFailed(String error) {
    return 'Échec : $error';
  }

  @override
  String ndSendFailed(String error) {
    return 'Échec de l\'envoi : $error';
  }

  @override
  String get ndFieldNote => 'Note de terrain';

  @override
  String get ndRemoveFavorite => 'Retirer des favoris';

  @override
  String get ndAddFavorite => 'Ajouter aux favoris';

  @override
  String get ndShortName => 'Nom court';

  @override
  String get ndHardware => 'Matériel';

  @override
  String get ndThisRadio => 'Cette radio';

  @override
  String get ndYes => 'Oui';

  @override
  String get ndLastHeard => 'Dernière écoute';

  @override
  String get ndSignal => 'Signal';

  @override
  String get ndHopsAway => 'Sauts';

  @override
  String get ndDirect => 'Direct';

  @override
  String get ndBattery => 'Batterie';

  @override
  String get ndExternalPower => 'Alimentation externe';

  @override
  String get ndVoltage => 'Tension';

  @override
  String get ndChannelUse => 'Utilisation du canal';

  @override
  String get ndPosition => 'Position';

  @override
  String get ndAltitude => 'Altitude';

  @override
  String get ndPositionAge => 'Âge de la position';

  @override
  String get ndDistance => 'Distance';

  @override
  String get ndEncounters => 'Rencontres';

  @override
  String get ndTraceroute => 'Traceroute';

  @override
  String get ndRequestPosition => 'Demander la position';

  @override
  String get ndPositionRequested =>
      'Position demandée. Elle se met à jour quand le nœud répond.';

  @override
  String get ndRequestTelemetry => 'Demander la télémétrie';

  @override
  String get ndTelemetryRequested =>
      'Télémétrie demandée. Elle se met à jour quand le nœud répond.';

  @override
  String get ndRemoteAdmin => 'Administration à distance';

  @override
  String get ndRequestSensors => 'Demander les capteurs';

  @override
  String get ndSensorsRequested =>
      'Mesures des capteurs demandées. Les nœuds sans capteurs ne répondent pas.';

  @override
  String get ndMute => 'Couper les notifications';

  @override
  String get ndMuteSub =>
      'Les messages s\'affichent toujours ; pas d\'alertes ni de lecture à voix haute';

  @override
  String get ndIgnore => 'Ignorer ce nœud';

  @override
  String get ndIgnoreSub =>
      'Masqué des nœuds, de la carte et des discussions ; ne déclenche jamais de notification ni de réponse du bot. Annulez ici ou dans Réglages.';

  @override
  String get ndAddNote => 'Touchez pour ajouter une note';

  @override
  String get ndDirectMessages => 'MESSAGES DIRECTS';

  @override
  String get ndNoDirect => 'Aucun message direct avec ce nœud pour l\'instant.';

  @override
  String get ndDirectMessage => 'Message direct';

  @override
  String get ndSend => 'Envoyer';

  @override
  String get ndRadioLinks => 'LIAISONS RADIO DIRECTES';

  @override
  String get ndNoNeighbors =>
      'Aucun rapport de voisins pour l\'instant. Les nœuds les partagent quand le module Neighbor Info est activé (Réglages → Modifier les réglages de la radio → Neighborinfo).';

  @override
  String ndHears(int count) {
    return 'Entend directement ($count) :';
  }

  @override
  String get ndNoneReported => '  Aucun voisin signalé';

  @override
  String ndHeardBy(int count) {
    return 'Entendu directement par ($count) :';
  }

  @override
  String get ndTrustQ => 'Faire confiance à la nouvelle clé ?';

  @override
  String ndTrustBody(String name) {
    return 'Ne le faites que si vous avez vérifié auprès du propriétaire de $name qu\'il a réinitialisé ou remplacé sa radio. Sinon, quelqu\'un d\'autre se fait peut-être passer pour ce nœud.';
  }

  @override
  String get ndTrust => 'Faire confiance à la nouvelle clé';

  @override
  String get ndKeyChanged => 'Clé de sécurité modifiée';

  @override
  String ndKeyChangedBody(String newCode, String oldCode) {
    return 'Ce nœud affiche maintenant une clé ($newCode) différente de celle vue la première fois ($oldCode). Sa radio a peut-être été réinitialisée ou remplacée, ou quelqu\'un se fait passer pour lui. Vérifiez auprès de son propriétaire avant d\'envoyer des messages privés.';
  }

  @override
  String get ndSecurityKey => 'Clé de sécurité';

  @override
  String get ndKeyNotShared =>
      'Pas encore partagée. Les nœuds en firmware 2.5 ou plus récent partagent une clé pour les messages directs privés.';

  @override
  String ndSafetyCode(String code) {
    return 'Code de sécurité $code\nComparez-le avec la radio du propriétaire pour être sûr que c\'est bien lui.';
  }

  @override
  String get homeFirmwareTitle =>
      'Mise à jour du firmware de la radio conseillée';

  @override
  String get homeCheckIn => 'Se signaler';

  @override
  String get homeEmergency => 'Urgence';

  @override
  String get homeSosHint =>
      'Maintenez 2 secondes. Il part vers vos contacts de sortie et se répète toutes les 5 minutes jusqu\'à ce que quelqu\'un réponde.';

  @override
  String homeSosHintChannel(int channel) {
    return 'Maintenez 2 secondes. Il part vers vos contacts de sortie et le canal $channel, et se répète toutes les 5 minutes jusqu\'à ce que quelqu\'un réponde.';
  }

  @override
  String get homeNotReceived =>
      'Envoyé ou en attente ne veut pas dire reçu. Confirmez par une réponse ou un appel.';

  @override
  String get homeConnected => 'Radio connectée';

  @override
  String get homeNotConnected => 'Aucune radio connectée';

  @override
  String get homeYourRadio => 'Votre radio';

  @override
  String get homeConnectHint =>
      'Connectez-vous pour vous signaler, envoyer un SOS et voir le maillage.';

  @override
  String get homeNodes => 'Nœuds';

  @override
  String get homeBattery => 'Batterie';

  @override
  String get homeUnknown => 'Inconnu';

  @override
  String get homePluggedIn => 'Branché';

  @override
  String get homeConnectRadio => 'Connecter une radio';

  @override
  String get homeTryDemo => 'Essayer la démo';

  @override
  String get homeTripRunning => 'Sortie en cours';

  @override
  String get homeTripNotStarted => 'Sortie non commencée';

  @override
  String homeContacts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts',
      one: '$count contact',
    );
    return '$_temp0';
  }

  @override
  String homeTripNamed(String name) {
    return 'Sortie : $name';
  }

  @override
  String get homePlanTrip => 'Planifier votre sortie';

  @override
  String homeOverdue(String names) {
    return 'En retard : $names';
  }

  @override
  String homeCheckInLabel(String label) {
    return 'Signalement : $label';
  }

  @override
  String homeDelivered(String label, String time, int delivered, int total) {
    return '$label à $time : remis à $delivered sur $total';
  }

  @override
  String homeNotDelivered(String names) {
    return 'non remis à $names';
  }

  @override
  String homeWaiting(int count) {
    return '$count en attente';
  }

  @override
  String get homeDetails => 'Détails';

  @override
  String get homeResend => 'Renvoyer';

  @override
  String get homeSendSosQ => 'Envoyer un SOS ?';

  @override
  String get homeSosRepeats =>
      'Votre SOS se répète toutes les 5 minutes jusqu\'à ce que quelqu\'un réponde ou que vous l\'arrêtiez.';

  @override
  String get homeSendSos => 'Envoyer le SOS';

  @override
  String get homeHoldSos => 'Maintenir pour SOS';

  @override
  String homeSosReplied(String name) {
    return '$name a répondu. Répétitions arrêtées.';
  }

  @override
  String homeSosNext(int sends, int max, String time) {
    return 'Envoyé $sends fois sur $max. Prochain à $time.';
  }

  @override
  String get homeSosBusy =>
      ' Le canal est occupé, donc les répétitions sont espacées pour passer.';

  @override
  String homeSosDone(int max) {
    return 'Envoyé $max fois. Répétitions terminées ; le SOS reste affiché jusqu\'à ce que vous l\'arrêtiez.';
  }

  @override
  String get homeSosActive => 'SOS actif';

  @override
  String get homeImSafe => 'Je suis en sécurité';

  @override
  String get homeStopNoMessage => 'Arrêter sans message';

  @override
  String get frTitle => 'Registres de terrain';

  @override
  String get frTplAssistance => 'Assistance';

  @override
  String get frTplCheckIn => 'Signalement';

  @override
  String get frTplAllClear => 'Tout va bien';

  @override
  String get frTooLong => 'Saisissez un message de 1 à 220 octets UTF-8.';

  @override
  String frBroadcastQ(int channel) {
    return 'Diffuser sur le canal $channel ?';
  }

  @override
  String get frNoProof =>
      'L\'envoi ne prouve pas la réception. Confirmez par une réponse ou un contact vocal.';

  @override
  String get frSendMessage => 'Envoyer le message';

  @override
  String get frChanged =>
      'La radio ou le canal a changé. Reconnectez-vous et vérifiez le message.';

  @override
  String get frSubmitted =>
      'Transmis à la radio. Consultez Discussions pour l\'état de l\'envoi et les réponses.';

  @override
  String get frIncidentLog => 'Journal d\'incidents';

  @override
  String get frIncidentLogSub => 'Notes privées enregistrées sur ce téléphone';

  @override
  String get frIncidentField => 'Incident ou observation';

  @override
  String get frIncidentSaved => 'Incident enregistré.';

  @override
  String get frSaveIncident => 'Enregistrer l\'incident';

  @override
  String get frIncidentCopied =>
      'CSV de l\'incident copié. Collez-le dans un fichier ou un tableur.';

  @override
  String get frCopyIncident => 'Copier le CSV de l\'incident';

  @override
  String frRadioOf(String time, String radio) {
    return '$time • Radio $radio';
  }

  @override
  String get frUnassigned => 'non attribué';

  @override
  String get frRemoveIncident => 'Retirer l\'incident';

  @override
  String get frRemoveIncidentQ => 'Retirer cet incident ?';

  @override
  String get frKeep => 'Garder';

  @override
  String get frRemove => 'Retirer';

  @override
  String get frIncidentRemoved => 'Incident retiré.';

  @override
  String get frTemplates => 'Modèles d\'urgence et de signalement';

  @override
  String get frTemplatesSub =>
      'Modifiez les détails, choisissez un canal, puis vérifiez avant d\'envoyer';

  @override
  String get frMessageField => 'Message — remplacez les détails vides';

  @override
  String get frBroadcastChannel => 'Canal de diffusion';

  @override
  String frChannelItem(int index, String name) {
    return 'Canal $index • $name';
  }

  @override
  String get frReview => 'Vérifier le message';

  @override
  String get frNotEmergency =>
      'Un modèle est un texte ordinaire du maillage. Il ne contacte pas les services d\'urgence.';

  @override
  String get frCoverage => 'Historique de couverture';

  @override
  String get frCoverageSub =>
      'Position du récepteur avec le signal RF reçu • enregistrement local uniquement';

  @override
  String get frRecord => 'Enregistrer la couverture';

  @override
  String get frRecordSub =>
      'Demande le GPS du téléphone. S\'arrête à la déconnexion. N\'envoie pas votre position.';

  @override
  String get frRecordOn =>
      'Enregistreur de couverture activé ; en attente d\'une position GPS récente et précise et de paquets RF.';

  @override
  String get frRecordOff => 'Enregistreur de couverture arrêté.';

  @override
  String frReadings(int count) {
    return '$count mesures • au plus 2000 mesures de couverture • elles expirent après 30 jours';
  }

  @override
  String get frCoverageCopied =>
      'CSV de couverture copié. Collez-le dans un fichier ou un tableur.';

  @override
  String get frCopyCoverage => 'Copier le CSV de couverture';

  @override
  String get frBot => 'Garde-fous du bot et heures calmes';

  @override
  String get frBotSub =>
      '6 réponses/heure • 30 secondes d\'écart • 5 minutes d\'attente par nœud';

  @override
  String get frBotEnable =>
      'Activez le mode bot dans Discussions pour cette session.';

  @override
  String get frBotRules =>
      'Seuls les messages récents du canal choisi comptent. Les rediffusions et les réponses de bot (NOTORYX: ou Bastion:) sont ignorées. Les heures calmes suivent l\'heure locale de ce téléphone.';

  @override
  String get frQuiet => 'Heures calmes';

  @override
  String get frQuietStart => 'Début des heures calmes';

  @override
  String get frQuietEnd => 'Fin des heures calmes';

  @override
  String get frBotChannel => 'Emplacement du canal du bot';

  @override
  String frChannelN(int index) {
    return 'Canal $index';
  }

  @override
  String frBytes(int bytes, int max) {
    return '$bytes octets sur $max. Les lignes vides sont omises.';
  }

  @override
  String frBytesOver(int bytes, int max) {
    return '$bytes octets sur $max. Trop long pour l\'envoi : raccourcissez un champ.';
  }

  @override
  String get frUseReport => 'Utiliser le rapport';

  @override
  String get rsTitle => 'Réglages de la radio';

  @override
  String get rsNotReady => 'Radio pas prête';

  @override
  String get rsNotReadySub =>
      'Connectez une radio et attendez PRÊT pour modifier les réglages.';

  @override
  String get rsAvailability => 'Disponibilité des réglages';

  @override
  String get rsAvailabilitySub =>
      'Vérifiez les lectures avant de modifier. Des réglages absents au démarrage ne prouvent pas qu\'un module n\'est pas pris en charge. Les résultats sont réinitialisés à la reconnexion.';

  @override
  String get rsStopChecking => 'Arrêter la vérification';

  @override
  String get rsOwner => 'Propriétaire';

  @override
  String get rsOwnerSub => 'Noms longs et courts du nœud';

  @override
  String get rsLoraSub =>
      'Région, préréglage du modem, limite de sauts, émission';

  @override
  String get rsChannels => 'Canaux';

  @override
  String get rsChannelsSub => 'Noms, rôles et clés de chiffrement';

  @override
  String get rsDevice => 'Appareil';

  @override
  String get rsDeviceSub => 'Rôle de l\'appareil et mode de rediffusion';

  @override
  String get rsPosition => 'Position';

  @override
  String get rsPositionSub =>
      'Intervalle de diffusion, mode GPS, position intelligente';

  @override
  String get rsAllSettings => 'TOUS LES RÉGLAGES DE LA RADIO';

  @override
  String get rsModules => 'MODULES';

  @override
  String get rsRadioChanged =>
      'La radio connectée a changé pendant le chargement. Relancez la lecture.';

  @override
  String rsSaveQ(String section) {
    return 'Enregistrer $section ?';
  }

  @override
  String get rsSaveWarning =>
      'Cela écrit la modification sur la radio connectée. La radio peut redémarrer et se reconnecter.';

  @override
  String get rsIdentityChanged =>
      'L\'identité de la radio a changé ou est indisponible. Rechargez avant d\'enregistrer.';

  @override
  String rsSaved(String section) {
    return '$section enregistré et vérifié sur la radio.';
  }

  @override
  String rsNotVerified(String error) {
    return 'Enregistrement non vérifié : $error\nLa radio a peut-être appliqué la modification. Rechargez pour voir sa valeur actuelle ; rien ne sera renvoyé automatiquement.';
  }

  @override
  String get rsSaveButton => 'ENREGISTRER';

  @override
  String rsUnavailable(String section) {
    return 'Les réglages $section ne sont pas disponibles via l\'API du firmware de cette radio.';
  }

  @override
  String rsReadFailed(String error) {
    return 'Lecture impossible depuis la radio : $error';
  }

  @override
  String get rsRetry => 'Réessayer';

  @override
  String get rsWaitingReconnect =>
      'En attente de la reconnexion et d\'une nouvelle lecture des réglages…';

  @override
  String get rsReload => 'Recharger depuis la radio';

  @override
  String get rsLongName => 'Nom long';

  @override
  String get rsShortName => 'Nom court';

  @override
  String get rsChooseRegion =>
      'Choisissez une région avant d\'enregistrer ; la radio n\'émettra pas sans région.';

  @override
  String get rsCustomInvalid =>
      'Les réglages personnalisés exigent une bande passante positive, un facteur d\'étalement de 5 à 12 et un dénominateur de taux de codage de 5 à 8. Vérifiez les valeurs prises en charge par votre radio.';

  @override
  String get rsRegionWarning =>
      'Changer de région ou de préréglage du modem déconnecte cette radio des nœuds qui gardent les anciens réglages.';

  @override
  String get rsRegion => 'Région';

  @override
  String get rsUsePreset => 'Utiliser un préréglage du modem';

  @override
  String get rsModemPreset => 'Préréglage du modem';

  @override
  String get rsBandwidth => 'Bande passante (kHz)';

  @override
  String get rsSpreadFactor => 'Facteur d\'étalement';

  @override
  String get rsCodingRate => 'Dénominateur du taux de codage (5–8)';

  @override
  String get rsRxBoost => 'Gain de réception renforcé';

  @override
  String get rsRxBoostSub =>
      'Gain du récepteur SX126x interne ; distinct du LNA externe';

  @override
  String get rsLna => 'LNA externe';

  @override
  String get rsLnaReported =>
      'Amplificateur de réception externe signalé par cette radio';

  @override
  String get rsLnaNone =>
      'Cette radio n\'a pas signalé de LNA externe pilotable';

  @override
  String rsHopLimit(int hops) {
    return 'Limite de sauts : $hops';
  }

  @override
  String get rsTransmit => 'Émission activée';

  @override
  String get rsTransmitSub => 'Désactivé, la radio ne fait que recevoir';

  @override
  String rsInfraWarning(String role) {
    return '$role est destiné aux infrastructures fixes avec une bonne couverture. Sur un appareil portatif, il gaspille du temps d\'antenne et de la batterie.';
  }

  @override
  String get rsRole => 'Rôle';

  @override
  String get rsRebroadcast => 'Mode de rediffusion';

  @override
  String get rsIntervalInvalid =>
      'L\'intervalle de diffusion doit être 0 (valeur par défaut du firmware) ou au moins 30 secondes.';

  @override
  String get rsGpsMode => 'Mode GPS';

  @override
  String get rsInterval => 'Intervalle de diffusion (secondes, 0 = par défaut)';

  @override
  String get rsSmart => 'Diffusion de position intelligente';

  @override
  String get rsSmartSub =>
      'Envoyer des mises à jour supplémentaires quand le nœud se déplace';

  @override
  String get rsFixed => 'Position fixe';

  @override
  String get rsFixedSub =>
      'Indiquer la dernière position connue au lieu du GPS';

  @override
  String get rsShareQr => 'Partager en QR code';

  @override
  String get rsImportLink => 'Importer un lien de canal';

  @override
  String get rsDisabled => 'Désactivé';

  @override
  String get rsDefaultName => '(nom par défaut)';

  @override
  String rsChannelsFailed(String error) {
    return 'Lecture des canaux impossible : $error';
  }

  @override
  String get rsNoEncryption => 'Pas de chiffrement';

  @override
  String get rsDefaultKey => 'Clé par défaut';

  @override
  String get rsAes128 => 'Clé AES-128';

  @override
  String get rsAes256 => 'Clé AES-256';

  @override
  String get rsUnknownKey => 'Clé non reconnue';

  @override
  String rsChannelN(int index) {
    return 'Canal $index';
  }

  @override
  String get rsKeyWarning =>
      'La clé de chiffrement change. Les nœuds sans la nouvelle clé ne peuvent plus lire ce canal. Partagez-la depuis le QR code du canal.';

  @override
  String get rsChannelName => 'Nom (vide = nom du préréglage)';

  @override
  String rsEncryption(String key) {
    return 'Chiffrement : $key';
  }

  @override
  String get rsNewAes256 => 'Nouvelle clé AES-256 aléatoire';

  @override
  String rsGpsHidden(String model) {
    return 'Les broches GPS sont masquées : le GPS du $model est câblé par le fabricant, elles n\'ont donc aucun effet.';
  }

  @override
  String get bcShareQ => 'Partager votre canal principal ?';

  @override
  String get bcShareBody =>
      'La balise inclura le nom et la clé de votre canal principal. Toute personne à portée pourra alors le rejoindre et lire ses messages.';

  @override
  String get bcShare => 'Partager';

  @override
  String get bcSent => 'Balise envoyée.';

  @override
  String bcNotSent(String error) {
    return 'Balise non envoyée : $error';
  }

  @override
  String get bcTitle => 'Balises du maillage';

  @override
  String get bcClear => 'Effacer les balises entendues';

  @override
  String get bcIntro =>
      'Une balise est une courte diffusion qui indique aux radios proches qu\'un maillage est là, et peut les inviter sur un canal. Les radios avec le firmware Meshtastic récent l\'affichent ; NOTORYX Connect affiche les balises qu\'il entend, quel que soit le firmware.';

  @override
  String get bcSendTitle => 'Envoyer une balise';

  @override
  String get bcMessage => 'Message de la balise';

  @override
  String get bcMessageHelp =>
      'Envoyé sur votre canal principal. Une balise par heure au plus.';

  @override
  String bcBytes(int used, int max) {
    return '$used/$max octets';
  }

  @override
  String get bcTooLong => 'Trop long';

  @override
  String get bcAddLocationNone =>
      'Ajouter ma position (pas encore de position)';

  @override
  String get bcAddLocation => 'Ajouter ma position en Plus Code';

  @override
  String get bcInvite => 'Inviter sur mon canal principal';

  @override
  String get bcInviteSub =>
      'Inclut le nom et la clé du canal, ainsi que votre région et votre préréglage';

  @override
  String get bcSending => 'Envoi…';

  @override
  String get bcSend => 'Envoyer la balise';

  @override
  String get bcConnect => 'Connectez une radio pour envoyer une balise.';

  @override
  String bcNext(String time) {
    return 'La prochaine balise pourra être envoyée à $time.';
  }

  @override
  String get bcHeard => 'Balises entendues';

  @override
  String get bcNoneHeard => 'Aucune balise entendue pour l\'instant';

  @override
  String get bcNoneHeardSub =>
      'Les balises des radios à portée sur vos canaux apparaissent ici.';

  @override
  String bcFrom(String name) {
    return 'De $name';
  }

  @override
  String bcHeardAt(String time) {
    return 'entendue à $time';
  }

  @override
  String bcChannel(String name) {
    return 'Canal « $name »';
  }

  @override
  String get bcDefault => 'Par défaut';

  @override
  String bcRegion(String name) {
    return 'région $name';
  }

  @override
  String bcPreset(String name) {
    return 'préréglage $name';
  }

  @override
  String bcSlot(int slot) {
    return 'emplacement $slot';
  }

  @override
  String get bcNoMessage => '(pas de message)';

  @override
  String bcInvitesTo(String offer) {
    return 'Invite sur : $offer';
  }

  @override
  String get bcJoin => 'Vérifier et rejoindre le canal';

  @override
  String get csShareTitle => 'Partager les canaux';

  @override
  String csReadFailed(String error) {
    return 'Lecture des canaux impossible : $error';
  }

  @override
  String get csRetry => 'Réessayer';

  @override
  String csPrimary(String name) {
    return 'Principal : $name';
  }

  @override
  String csSecondary(String name) {
    return 'Secondaire : $name';
  }

  @override
  String get csDefaultName => '(nom par défaut)';

  @override
  String get csCopyLink => 'Copier le lien';

  @override
  String get csCopied => 'Lien du canal copié.';

  @override
  String get csKeysWarning =>
      'Ce code contient les clés de chiffrement de vos canaux. Quiconque le scanne peut lire et envoyer sur ces canaux.';

  @override
  String get csReplaceQ => 'Remplacer tous les canaux ?';

  @override
  String get csAddQ => 'Ajouter des canaux ?';

  @override
  String get csReplaceBody =>
      'Les 8 emplacements de canal seront écrasés. Vous perdrez l\'accès aux canaux actuels si vous n\'avez pas leur lien. La radio va redémarrer.';

  @override
  String get csReplaceLoraBody =>
      'Les 8 emplacements de canal et les réglages LoRa seront écrasés. Vous perdrez l\'accès aux canaux actuels si vous n\'avez pas leur lien. La radio va redémarrer.';

  @override
  String get csAddBody =>
      'Les nouveaux canaux du lien vont dans les emplacements libres. Les canaux existants et les réglages LoRa ne changent pas.';

  @override
  String get csApply => 'Appliquer';

  @override
  String get csAlreadyThere =>
      'Tous les canaux du lien sont déjà sur la radio.';

  @override
  String csWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canaux écrits et vérifiés sur la radio.',
      one: '$count canal écrit et vérifié sur la radio.',
    );
    return '$_temp0';
  }

  @override
  String csNotVerified(String error) {
    return 'Importation non vérifiée : $error\nRien ne sera renvoyé automatiquement.';
  }

  @override
  String csRefused(String error) {
    return 'Importation refusée : $error';
  }

  @override
  String csFailed(String error) {
    return 'Échec de l\'importation : $error';
  }

  @override
  String get csImportTitle => 'Importer des canaux';

  @override
  String get csScan => 'Scanner le QR code du canal';

  @override
  String get csScanTitle => 'Scanner le QR du canal';

  @override
  String get csLinkLabel => 'Lien de canal Meshtastic';

  @override
  String get csPaste => 'Coller';

  @override
  String csLora(String region, String modem) {
    return 'LoRa : $region, $modem';
  }

  @override
  String get csCustomModem => 'modem personnalisé';

  @override
  String get csAdd => 'Ajouter à la radio';

  @override
  String get csReplaceAll => 'Tout remplacer';

  @override
  String get csApplyRadio => 'Appliquer à la radio';

  @override
  String get trTitle => 'Planifier votre sortie';

  @override
  String get trName => 'Nom de la sortie';

  @override
  String trContacts(int count, int max) {
    return 'CONTACTS DE SORTIE ($count/$max)';
  }

  @override
  String get trContactsSub =>
      'Les signalements et le SOS partent vers chacun d\'eux en message direct.';

  @override
  String get trNoNodes => 'Aucun nœud pour l\'instant';

  @override
  String get trNoNodesSub =>
      'Connectez votre radio pour que les nœuds proches et les favoris apparaissent ici.';

  @override
  String get trOverdue => 'Alerte de retard';

  @override
  String get trOverdueHelp =>
      'Vous prévient quand un contact de sortie n\'a pas été entendu depuis ce délai';

  @override
  String get trOff => 'Désactivé';

  @override
  String trMinutes(int count) {
    return '$count min';
  }

  @override
  String trHours(int count) {
    return '$count h';
  }

  @override
  String get trReminder => 'Rappel de signalement';

  @override
  String get trReminderHelp =>
      'Vous rappelle de vous signaler ce délai après votre dernier signalement';

  @override
  String trEvery(String time) {
    return 'Toutes les $time';
  }

  @override
  String get trSosChannel => 'Envoyer aussi le SOS sur un canal';

  @override
  String get trSosChannelHelp =>
      'Tout le monde sur ce canal voit votre SOS, pas seulement les contacts de sortie';

  @override
  String get trContactsOnly => 'Non, contacts de sortie uniquement';

  @override
  String trChannelItem(int index, String name) {
    return 'Canal $index • $name';
  }

  @override
  String get trDefault => 'Par défaut';

  @override
  String get trReadiness => 'Vérification avant départ';

  @override
  String get trEnd => 'Terminer la sortie';

  @override
  String get trStart => 'Commencer la sortie';

  @override
  String trRunning(String time) {
    return 'Sortie en cours depuis $time. Les alertes de retard et les rappels sont activés.';
  }

  @override
  String get trNotRunning =>
      'Commencer la sortie active les alertes de retard et les rappels de signalement. Les signalements et le SOS fonctionnent à tout moment.';

  @override
  String get pvEncryptedOn =>
      'L\'historique des discussions est maintenant chiffré.';

  @override
  String get pvEncryptedOff =>
      'L\'historique des discussions n\'est plus chiffré.';

  @override
  String get pvLockOnReason => 'Activer le verrouillage de l\'application';

  @override
  String get pvLockOffReason => 'Désactiver le verrouillage de l\'application';

  @override
  String get pvLockUnchanged =>
      'Le verrouillage de l\'application n\'a pas été modifié.';

  @override
  String get pvStored1 =>
      'Historique des discussions et files hors ligne de chaque radio (les 500 messages les plus récents par radio)';

  @override
  String get pvStored2 =>
      'NodeDex : les nœuds que vos radios ont entendus, ainsi que vos favoris et notes';

  @override
  String get pvStored3 => 'Points de passage reçus du maillage';

  @override
  String get pvStored4 =>
      'Journal d\'incidents et registres de couverture, seulement si vous les créez';

  @override
  String get pvStored5 =>
      'Réglages des alertes de terrain, du bot, de la position et de l\'apparence';

  @override
  String get pvStored6 => 'Tuiles de carte des zones que vous avez consultées';

  @override
  String get pvSent1 =>
      'Les messages que vous envoyez vont à votre radio, qui les transmet sur le maillage avec la clé de chiffrement du canal';

  @override
  String get pvSent2 =>
      'La position de votre téléphone, seulement quand « Partager la position du téléphone » est activé, à la précision choisie';

  @override
  String get pvSent3 =>
      'Les demandes de position, de télémétrie et de traceroute que vous lancez';

  @override
  String get pvSent4 =>
      'Les demandes de tuiles de carte aux serveurs OpenStreetMap quand vous consultez la carte ; ils voient votre adresse IP';

  @override
  String get pvSent5 =>
      'Les demandes de tuiles topographiques aux serveurs OpenTopoMap, seulement quand la carte topo est affichée ; ils voient votre adresse IP';

  @override
  String get pvSent6 =>
      'Des points le long d\'une liaison au service d\'altitude Open-Meteo, seulement quand vous vérifiez une liaison dans le planificateur';

  @override
  String get pvDisconnectFirst =>
      'Déconnectez la radio avant de supprimer les données du téléphone.';

  @override
  String get pvDeleteAllQ => 'Supprimer toutes les données du téléphone ?';

  @override
  String get pvDeleteChatsQ => 'Supprimer l\'historique des discussions ?';

  @override
  String get pvDeleteAllBody =>
      'Supprime de ce téléphone les discussions et files hors ligne de chaque radio, NodeDex, favoris et notes, points de passage, registres de terrain, tuiles de carte en cache et tous les réglages de l\'application. Les réglages de la radio ne changent pas. Cette action est irréversible ; faites d\'abord une sauvegarde des données du téléphone si vous pourriez en avoir besoin.\n\nL\'application se ferme ensuite.';

  @override
  String get pvDeleteChatsBody =>
      'Supprime de ce téléphone l\'historique des discussions et les messages en attente de chaque radio. Les messages déjà envoyés sur le maillage ne sont pas concernés. Cette action est irréversible.\n\nL\'application se ferme ensuite.';

  @override
  String get pvDelete => 'Supprimer';

  @override
  String pvDeleteFailed(String error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String get pvDeleted => 'Supprimé';

  @override
  String get pvDeletedBody =>
      'NOTORYX Connect va se fermer pour que rien de ce qui reste en mémoire ne soit réenregistré.';

  @override
  String get pvCloseApp => 'Fermer l\'application';

  @override
  String get pvTitle => 'Confidentialité et données';

  @override
  String get pvIntro =>
      'NOTORYX Connect n\'a ni compte, ni statistiques, ni publicités, ni serveurs propres. Tout ce qu\'il conserve reste dans le stockage privé de l\'application sur votre téléphone et est supprimé si vous la désinstallez.';

  @override
  String get pvAppLock => 'Verrouillage de l\'application';

  @override
  String get pvAppLockSub =>
      'Demander votre empreinte, votre visage ou le verrouillage de l\'écran à l\'ouverture de l\'application, et après une minute d\'absence. Il sera aussi nécessaire pour accéder au SOS. La radio reste connectée.';

  @override
  String get pvAppLockNone =>
      'Définissez un verrouillage de l\'écran sur ce téléphone pour utiliser le verrouillage de l\'application.';

  @override
  String get pvEncrypt => 'Chiffrer l\'historique des discussions';

  @override
  String get pvEncryptSub =>
      'Brouille les messages enregistrés avec une clé conservée dans le stockage sécurisé de ce téléphone. Si cette clé est perdue, par exemple après un passage à un nouveau téléphone, l\'historique enregistré devient illisible. Exportez d\'abord ce dont vous avez besoin.';

  @override
  String get pvStored => 'Stocké sur ce téléphone';

  @override
  String get pvSent => 'Envoyé hors de ce téléphone';

  @override
  String get pvDeleteChats => 'Supprimer l\'historique des discussions';

  @override
  String get pvDeleteAll => 'Supprimer toutes les données du téléphone';

  @override
  String pbFailed(String error) {
    return 'Échec de l\'opération : $error';
  }

  @override
  String get pbShortPassword =>
      'Utilisez au moins 12 caractères pour le mot de passe de sauvegarde.';

  @override
  String get pbCreated =>
      'Sauvegarde créée. Enregistrez le fichier ailleurs que sur ce téléphone. Gardez le mot de passe à part ; il ne peut pas être récupéré.';

  @override
  String get pbDisconnectFirst =>
      'Déconnectez la radio avant de restaurer les données du téléphone.';

  @override
  String get pbReplaceQ => 'Remplacer toutes les données du téléphone ?';

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
    return 'Sauvegarde créée le $date par la version $version.\n\nElle contient l\'historique des discussions de $_temp0 ($messages messages) et $items éléments enregistrés au total.\n\nTout ce que NOTORYX Connect stocke sur ce téléphone (discussions, files hors ligne, NodeDex, points de passage, registres de terrain et réglages) est remplacé. Les réglages de la radio ne changent pas. L\'application se ferme à la fin de la restauration ; rouvrez-la pour continuer.';
  }

  @override
  String get pbReplace => 'Remplacer les données du téléphone';

  @override
  String get pbRestored => 'Restauration terminée';

  @override
  String get pbRestoredBody =>
      'NOTORYX Connect va se fermer pour que rien de ce qui reste en mémoire n\'écrase les données restaurées. Rouvrez-le pour continuer.';

  @override
  String get pbTitle => 'Sauvegarde des données du téléphone';

  @override
  String get pbIntro =>
      'Sauvegarde tout ce que NOTORYX Connect stocke sur ce téléphone : historique des discussions et files hors ligne de chaque radio, favoris et notes NodeDex, points de passage, registres de terrain et réglages de l\'application. Utilisez-la pour passer à un nouveau téléphone. Le fichier est chiffré avec votre mot de passe. Les réglages de la radio ont leur propre sauvegarde.';

  @override
  String get pbPassword =>
      'Mot de passe de sauvegarde (au moins 12 caractères)';

  @override
  String get pbCreate => 'Créer un fichier de sauvegarde';

  @override
  String get pbRestore => 'Restaurer depuis un fichier';

  @override
  String get rbFailed =>
      'Échec de l\'opération. Si une restauration avait commencé, les réglages peuvent être partiellement modifiés. Reconnectez-vous et vérifiez la radio avant de réessayer.';

  @override
  String get rbReady =>
      'Sauvegarde chiffrée prête. Copiez-la et enregistrez-la dans un fichier texte. Gardez le mot de passe à part ; il ne peut pas être récupéré.';

  @override
  String get rbReplaceQ => 'Remplacer les réglages de la radio ?';

  @override
  String rbSummary(
    String source,
    String firmware,
    String date,
    String target,
    int configs,
    int modules,
  ) {
    return 'Sauvegarde de la radio $source (firmware $firmware), créée le $date.\n\nCible : $target. Remplace les noms du propriétaire, les 8 emplacements de canal avec leurs clés secrètes, $configs sections de configuration et $modules modules. Les clés d\'identité/sécurité de l\'appareil, les identifiants de session, les discussions du téléphone et les cartes ne sont pas restaurés (utilisez la sauvegarde des données du téléphone pour cela).\n\nSauvegardez d\'abord la cible. La radio peut redémarrer ou perdre la connexion au maillage. Une écriture sur la radio ne garantit pas de retour en arrière après une coupure de courant ou de connexion.';
  }

  @override
  String get rbReplace => 'Remplacer les réglages';

  @override
  String get rbRadioChanged => 'La radio connectée a changé.';

  @override
  String get rbRestored =>
      'Restauration terminée. La relecture de la radio correspond à la sauvegarde.';

  @override
  String get rbTitle => 'Sauvegarde chiffrée de la radio';

  @override
  String get rbIntro =>
      'Sauvegarde la configuration et les modules actuels signalés par le firmware, tous les emplacements de canal et les noms du propriétaire. Les clés de canal et les identifiants réseau/module sont chiffrés par mot de passe. Les clés d\'identité de l\'appareil et les identifiants de session sont exclus.';

  @override
  String get rbCreate => 'Créer une sauvegarde chiffrée';

  @override
  String get rbText => 'Texte de la sauvegarde chiffrée';

  @override
  String get rbTextHint =>
      'Collez une sauvegarde chiffrée enregistrée pour la restaurer';

  @override
  String get rbCopied =>
      'Sauvegarde chiffrée copiée. Enregistrez-la dans un fichier texte.';

  @override
  String get rbCopy => 'Copier la sauvegarde chiffrée';

  @override
  String get rbReview => 'Vérifier et restaurer';

  @override
  String get raPower => 'Alimentation';

  @override
  String get raDisplay => 'Affichage';

  @override
  String get raLoraQ => 'Modifier les réglages LoRa à distance ?';

  @override
  String get raLoraBody =>
      'Si le nœud se retrouve sur une région, un préréglage ou une fréquence différents du reste du maillage, il devient injoignable et quelqu\'un devra le réparer sur place.';

  @override
  String get raSaveAnyway => 'Enregistrer quand même';

  @override
  String raSent(String section) {
    return 'Réglages $section envoyés. Le nœud peut redémarrer pour les appliquer.';
  }

  @override
  String get raNameSent => 'Nom envoyé au nœud.';

  @override
  String raRestartQ(String name) {
    return 'Redémarrer $name ?';
  }

  @override
  String get raRestartBody =>
      'Le nœud quitte brièvement le maillage pendant son redémarrage.';

  @override
  String get raRestart => 'Redémarrer';

  @override
  String get raRestartRequested => 'Redémarrage demandé.';

  @override
  String get raDiscardQ => 'Abandonner les modifications ?';

  @override
  String get raDiscardBody =>
      'Vos modifications n\'ont pas été envoyées au nœud.';

  @override
  String get raDiscard => 'Abandonner';

  @override
  String get raTitle => 'Administration à distance';

  @override
  String get raIntro =>
      'Modifiez les réglages de ce nœud par le maillage. Chaque demande utilise du temps d\'antenne et peut prendre jusqu\'à une minute.';

  @override
  String get raUnavailable =>
      'L\'administration à distance n\'est pas disponible';

  @override
  String get raWaiting => 'En attente du nœud';

  @override
  String get raAccess => 'Accès';

  @override
  String get raAccessHint =>
      'Demandez ses informations au nœud. S\'il répond, votre radio a le droit de le gérer.';

  @override
  String get raCheckAccess => 'Vérifier l\'accès';

  @override
  String get raAccessConfirmed => 'Accès confirmé';

  @override
  String raFirmware(String version, String role) {
    return 'Firmware $version · $role';
  }

  @override
  String get raUnknown => 'inconnu';

  @override
  String get raNoName => 'Sans nom';

  @override
  String raShortName(String name) {
    return 'Nom court $name';
  }

  @override
  String get raRename => 'Renommer';

  @override
  String get raRestartNode => 'Redémarrer le nœud';

  @override
  String get raSettings => 'Réglages';

  @override
  String get raLoraWarning =>
      'Un mauvais réglage LoRa peut couper ce nœud du maillage. Ne le modifiez que si vous pouvez accéder au nœud sur place.';

  @override
  String raSend(String section) {
    return 'Envoyer les réglages $section';
  }

  @override
  String get raUndo => 'Annuler';

  @override
  String get raKeyTitle => 'La clé d\'administration de votre radio';

  @override
  String raKeyBody(String name) {
    return 'Avant que $name accepte des modifications, son propriétaire ajoute cette clé dans Réglages de la radio → Sécurité → Clé d\'administration, depuis n\'importe quelle application Meshtastic.';
  }

  @override
  String get raNoKey => 'Votre radio n\'a pas encore indiqué sa clé.';

  @override
  String get raCopyKey => 'Copier la clé d\'administration';

  @override
  String get raKeyCopied => 'Clé d\'administration copiée.';

  @override
  String get raRenameTitle => 'Renommer le nœud';

  @override
  String get raSendButton => 'Envoyer';

  @override
  String get frSaluteTitle => 'Rapport SALUTE';

  @override
  String get frNineTitle => 'Évacuation médicale 9-Line';

  @override
  String get frSaluteS => 'Taille';

  @override
  String get frSaluteSHint => 'Combien de personnes ou de véhicules';

  @override
  String get frSaluteA => 'Activité';

  @override
  String get frSaluteAHint => 'Ce qu\'ils font';

  @override
  String get frSaluteL => 'Lieu';

  @override
  String get frSaluteLHint => 'Où ils se trouvent';

  @override
  String get frSaluteU => 'Unité';

  @override
  String get frSaluteUHint => 'Qui ils sont, tenue ou insignes';

  @override
  String get frSaluteT => 'Heure';

  @override
  String get frSaluteTHint => 'Quand vous les avez vus';

  @override
  String get frSaluteE => 'Équipement';

  @override
  String get frSaluteEHint => 'Ce qu\'ils ont avec eux';

  @override
  String get frNine1 => 'Lieu de récupération';

  @override
  String get frNine1Hint => 'Coordonnées ou point de repère';

  @override
  String get frNine2 => 'Fréquence radio et indicatif';

  @override
  String get frNine2Hint => 'Comment vous joindre';

  @override
  String get frNine3 => 'Patients par urgence';

  @override
  String get frNine3Hint => 'Par exemple 1 urgent, 2 routine';

  @override
  String get frNine4 => 'Équipement spécial';

  @override
  String get frNine4Hint => 'Aucun, treuil, désincarcération, respirateur';

  @override
  String get frNine5 => 'Patients par type';

  @override
  String get frNine5Hint => 'Brancard ou valide';

  @override
  String get frNine6 => 'Sécurité au point de récupération';

  @override
  String get frNine6Hint => 'Aucune menace, possible, ou escorte armée';

  @override
  String get frNine7 => 'Comment le site est balisé';

  @override
  String get frNine7Hint => 'Panneau, fumée, lumière ou rien';

  @override
  String get frNine8 => 'État des patients';

  @override
  String get frNine8Hint => 'Qui sont les patients';

  @override
  String get frNine9 => 'Dangers et terrain';

  @override
  String get frNine9Hint => 'Pente, câbles, contamination';

  @override
  String get svcConnectToCheckIn => 'Connectez une radio pour vous signaler.';

  @override
  String get svcChooseContacts => 'Choisissez d\'abord des contacts de sortie.';

  @override
  String get svcConnectToSos => 'Connectez une radio pour envoyer un SOS.';

  @override
  String get svcChooseSosTargets =>
      'Choisissez d\'abord des contacts de sortie ou un canal SOS.';

  @override
  String svcFirmwareUnsupported(String version, String minimum, String url) {
    return 'Votre radio utilise le firmware $version. NOTORYX Connect a besoin de la version $minimum ou plus récente pour modifier les réglages de la radio, donc les réglages sont en lecture seule. Les messages fonctionnent toujours. Mettez à jour sur $url.';
  }

  @override
  String svcFirmwareOutdated(String version, String recommended, String url) {
    return 'Votre radio utilise le firmware $version. Passer à la version $recommended ou plus récente sur $url active de nouvelles fonctions comme les mesures de capteurs et la vérification des clés de sécurité.';
  }

  @override
  String get svcToday => 'Aujourd\'hui';

  @override
  String get svcYesterday => 'Hier';

  @override
  String get svcLowBatteryOwn => 'La batterie de votre radio est faible';

  @override
  String svcLowBattery(String name) {
    return 'Batterie faible pour $name';
  }

  @override
  String svcLowBatteryOwnBody(int level) {
    return 'Votre radio indique $level % de batterie.';
  }

  @override
  String svcLowBatteryBody(String name, int level) {
    return '$name indique $level % de batterie.';
  }

  @override
  String svcNewNode(String name) {
    return 'Nouveau nœud : $name';
  }

  @override
  String svcNewNodeBody(String name) {
    return 'Votre radio a entendu $name pour la première fois.';
  }

  @override
  String get svcMeshQuieter => 'Le maillage est devenu plus calme';

  @override
  String svcMeshQuieterBody(int active, int peak) {
    return '$active nœuds entendus dans la dernière heure, contre $peak auparavant. Un relais est peut-être en panne, ou vous êtes peut-être hors de portée.';
  }

  @override
  String svcQuiet(String name) {
    return '$name est devenu silencieux';
  }

  @override
  String svcQuietBody(String time) {
    return 'Pas entendu depuis $time.';
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
  String get svcReply => 'Répondre';

  @override
  String get svcDirectChannel => 'Messages directs';

  @override
  String get svcDirectChannelSub =>
      'Messages qui vous sont envoyés sur le maillage.';

  @override
  String get svcChannelChannel => 'Messages de canal';

  @override
  String get svcChannelChannelSub => 'Messages sur vos canaux du maillage.';

  @override
  String get svcFieldChannel => 'Alertes de terrain';

  @override
  String get svcFieldChannelSub =>
      'Batterie faible, nouveaux nœuds et favoris devenus silencieux.';

  @override
  String svcFromChannel(String sender, int channel) {
    return '$sender • canal $channel';
  }

  @override
  String mapHeatSummary(int strong, int fair, int weak, int readings) {
    return 'Carte de couverture : $strong zones fortes, $fair moyennes, $weak faibles, d\'après $readings mesures.';
  }

  @override
  String get nrTitle => 'Passer à une nouvelle radio';

  @override
  String nrSub(int done, int total) {
    return '$done sur $total terminés';
  }

  @override
  String get nrStep1 =>
      'Avec l\'ancienne radio connectée, créez ici une sauvegarde chiffrée et enregistrez le texte en lieu sûr.';

  @override
  String get nrStep2 =>
      'Notez la région et le préréglage du modem de l\'ancienne radio (Réglages de la radio → LoRa).';

  @override
  String get nrStep3 =>
      'Mettez à jour le firmware de la nouvelle radio vers la même version ou une plus récente.';

  @override
  String get nrStep4 =>
      'Connectez la nouvelle radio et réglez sa région avant tout le reste, pour qu\'elle puisse émettre.';

  @override
  String get nrStep5 =>
      'Collez la sauvegarde, vérifiez-la et restaurez-la. Utilisez le même mot de passe.';

  @override
  String get nrStep6 =>
      'Vérifiez les canaux : les noms et les clés doivent correspondre, et envoyez un message de test à quelqu\'un sur chaque canal.';

  @override
  String get nrStep7 =>
      'La nouvelle radio a son propre ID de nœud et sa propre clé de sécurité. Prévenez vos contacts et ajoutez-la de nouveau comme administrateur sur les nœuds que vous gérez à distance.';

  @override
  String get nrReset => 'Recommencer';

  @override
  String get cpLabel => 'Position partagée sur ce canal';

  @override
  String get cpHelp =>
      'La précision de la position de votre radio quand elle est envoyée sur ce canal. Les autres canaux gardent leur propre réglage.';

  @override
  String get cpNotSet => 'Non défini : le firmware décide';

  @override
  String get cpNone => 'Ne pas partager la position';

  @override
  String get cpExact => 'Position exacte';

  @override
  String cpWithin(String distance) {
    return 'À environ $distance près';
  }

  @override
  String get rdBattery => 'Batterie de la radio';

  @override
  String get rdNotReported => 'Pas encore indiqué.';

  @override
  String get rdExternal => 'Sur alimentation externe.';

  @override
  String rdChargeNow(int level) {
    return '$level %. Chargez la radio avant de partir.';
  }

  @override
  String rdChargeSoon(int level) {
    return '$level %. Pensez à la charger ou à emporter une batterie externe.';
  }

  @override
  String rdLevel(int level) {
    return '$level %.';
  }

  @override
  String get rdFirmware => 'Firmware';

  @override
  String get rdConnectToCheck => 'Connectez votre radio pour vérifier.';

  @override
  String get rdTooOld => 'Trop ancien.';

  @override
  String get rdUpdateRecommended => 'Mise à jour conseillée.';

  @override
  String get rdVersionUnknown => 'Version non indiquée.';

  @override
  String get rdSupported => 'Pris en charge.';

  @override
  String get rdChannels => 'Canaux';

  @override
  String get rdNoChannels => 'Aucun canal sur cette radio.';

  @override
  String rdSosChannelGone(int channel) {
    return 'Le canal SOS $channel n\'existe plus. Choisissez-en un autre dans votre plan de sortie.';
  }

  @override
  String rdChannelsSet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canaux configurés.',
      one: '$count canal configuré.',
    );
    return '$_temp0';
  }

  @override
  String get rdContacts => 'Contacts de sortie';

  @override
  String get rdChooseContacts =>
      'Choisissez qui reçoit vos signalements et votre SOS.';

  @override
  String rdNoRoute(String names) {
    return 'Aucune route vers $names.';
  }

  @override
  String rdNotHeard(String names) {
    return 'Pas entendus depuis 2 heures : $names. Lancez un test de route ou vérifiez qu\'ils sont allumés.';
  }

  @override
  String rdAllHeard(int count) {
    return 'Les $count ont été entendus récemment.';
  }

  @override
  String get rdPosition => 'Position';

  @override
  String get rdRecentPosition => 'Votre radio a une position récente.';

  @override
  String get rdWaitingPhone =>
      'En attente d\'une position de ce téléphone. Vérifiez que la localisation est activée.';

  @override
  String get rdNoPosition =>
      'Pas de position récente, donc les autres ne voient pas où vous êtes. Activez le GPS de la radio ou partagez la position de ce téléphone.';

  @override
  String get rdBackground => 'Arrière-plan';

  @override
  String get rdBackgroundRestricted =>
      'L\'optimisation de la batterie peut couper la liaison écran éteint. Réglez NOTORYX Connect sur « Sans restriction ».';

  @override
  String get rdBackgroundOk =>
      'L\'application peut rester connectée écran éteint.';

  @override
  String get rdCouldntCheck => 'Vérification impossible.';

  @override
  String get rpTitle => 'Vérification avant départ';

  @override
  String get rpReady => 'Prêt à partir';

  @override
  String get rpCheck => 'Vérifiez ces points avant de partir';

  @override
  String get rpNotReady => 'Pas encore prêt';

  @override
  String get rpNeedRadio => 'Certaines vérifications nécessitent votre radio';

  @override
  String get rpNotReceived =>
      'Envoyé ou en attente ne veut pas dire reçu. Convenez d\'un plan de secours.';

  @override
  String get rpTestRoute => 'Tester une route';

  @override
  String get rpTestHint =>
      'Envoie une demande de route à ce contact. À utiliser avec modération sur les maillages chargés.';

  @override
  String get rpRouteFound => 'Route trouvée';

  @override
  String get rpNoRoute => 'Aucune route trouvée';

  @override
  String get rpNotTested => 'Non testé';

  @override
  String get rpTest => 'Tester';

  @override
  String get rpStatusReady => 'Prêt';

  @override
  String get rpStatusCheck => 'À vérifier';

  @override
  String get rpStatusFix => 'À corriger d\'abord';

  @override
  String get rpStatusUnknown => 'Inconnu';

  @override
  String get cdFixBluetooth => 'Activer le Bluetooth';

  @override
  String get cdFixPermission => 'Autoriser l\'accès Bluetooth';

  @override
  String get cdFixBattery => 'Ouvrir les réglages de batterie';

  @override
  String get cdFixRetry => 'Réessayer';

  @override
  String get cdFixScan => 'Rechercher des radios';

  @override
  String get cdFixFirmware => 'Comment mettre à jour';

  @override
  String get cdTheRadio => 'la radio';

  @override
  String get cdYourRadio => 'votre radio';

  @override
  String get cdBluetoothOffDetail =>
      'Le Bluetooth est désactivé. Activez-le et l\'application se reconnecte toute seule.';

  @override
  String get cdPermissionDetail =>
      'L\'application n\'a pas le droit d\'utiliser le Bluetooth. Autorisez « Appareils à proximité » quand on vous le demande, ou dans Paramètres Android → Applications → NOTORYX Connect → Autorisations.';

  @override
  String cdPairedDetail(String name) {
    return '$name est peut-être connectée à un autre téléphone ou une autre application. Une radio ne parle qu\'à un téléphone à la fois : fermez l\'autre application ou désactivez le Bluetooth de l\'autre téléphone, puis réessayez. Si l\'échec persiste, oubliez la radio dans les réglages Bluetooth d\'Android et associez-la de nouveau.';
  }

  @override
  String cdTimeoutDetail(String name) {
    return '$name n\'a pas répondu à temps. Rapprochez-vous, vérifiez qu\'elle est allumée ou redémarrez-la, puis réessayez.';
  }

  @override
  String get cdNetworkDetail =>
      'Impossible de joindre la radio par le réseau. Vérifiez que le téléphone et la radio sont sur le même Wi-Fi, et que l\'adresse et le port (généralement 4403) sont corrects.';

  @override
  String get cdUsbDetail =>
      'La liaison USB a échoué. Débranchez et rebranchez le câble, et autorisez l\'accès USB quand Android le demande.';

  @override
  String cdGaveUpDetail(String name) {
    return 'La liaison a été coupée et la reconnexion n\'a pas fonctionné. Vérifiez que $name est allumée et à portée, puis réessayez.';
  }

  @override
  String get cdNotMeshtasticDetail =>
      'L\'appareil a répondu mais ne ressemble pas à une radio Meshtastic, ou son firmware est trop ancien.';

  @override
  String get cdUnknownProblem => 'Problème inconnu.';

  @override
  String get cdBluetooth => 'Bluetooth';

  @override
  String get cdOn => 'Activé.';

  @override
  String get cdBluetoothOff => 'Le Bluetooth est désactivé.';

  @override
  String get cdCouldntCheck => 'Vérification impossible.';

  @override
  String get cdAccess => 'Accès Bluetooth';

  @override
  String get cdAllowed => 'Autorisé.';

  @override
  String get cdNotAllowed =>
      'L\'application n\'a pas le droit de trouver les radios et de s\'y connecter.';

  @override
  String get cdLink => 'Liaison radio';

  @override
  String cdConnectedTo(String name) {
    return 'Connecté à $name.';
  }

  @override
  String cdConnectingTo(String name) {
    return 'Connexion à $name…';
  }

  @override
  String get cdNoneFound =>
      'Aucune radio trouvée. Vérifiez que la radio est allumée et à quelques mètres, que le Bluetooth est activé dans ses réglages et qu\'elle n\'est pas connectée à un autre téléphone.';

  @override
  String get cdNotConnected => 'Non connecté.';

  @override
  String get cdBackground => 'Arrière-plan';

  @override
  String get cdBatteryOptimised =>
      'L\'optimisation de la batterie peut couper la liaison radio écran éteint. Réglez NOTORYX Connect sur « Sans restriction ».';

  @override
  String get cdBackgroundOk => 'La liaison peut rester ouverte écran éteint.';

  @override
  String get cdFirmware => 'Firmware';

  @override
  String get cdFirmwareTooOld => 'Firmware trop ancien.';

  @override
  String get cdSupported => 'Pris en charge.';

  @override
  String get cpFlasherCopied =>
      'flasher.meshtastic.org copié. Ouvrez-le sur un ordinateur avec la radio branchée.';

  @override
  String cpFixFailed(String error) {
    return 'Cela n\'a pas fonctionné : $error';
  }

  @override
  String get cpReportCopied =>
      'Rapport copié. Il ne contient que des détails de connexion : ni messages, ni clés, ni positions.';

  @override
  String get cpTitle => 'Diagnostic de connexion';

  @override
  String get cpChecking => 'Vérification…';

  @override
  String get cpNoProblems => 'Aucun problème trouvé';

  @override
  String cpProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problèmes trouvés',
      one: '1 problème trouvé',
    );
    return '$_temp0';
  }

  @override
  String get cpStillFails =>
      'Si la radio ne se connecte toujours pas, copiez le rapport ci-dessous et partagez-le.';

  @override
  String get cpFixFirst =>
      'Corrigez le premier problème, puis vérifiez à nouveau.';

  @override
  String get cpCheckAgain => 'Vérifier à nouveau';

  @override
  String get cpCopyReport => 'Copier le rapport';

  @override
  String get cpRecentEvents => 'Événements de connexion récents';

  @override
  String get cpNoEvents =>
      'Rien pour l\'instant. Les événements apparaissent ici au fil de la connexion.';

  @override
  String get cpOk => 'OK';

  @override
  String get cpProblem => 'Problème';

  @override
  String get cpUnknown => 'Inconnu';

  @override
  String get sntTitle => 'Modération communautaire';

  @override
  String get sntToolSubtitle =>
      'Signaler le spam aux modérateurs NOTORYX et voir les nœuds signalés';

  @override
  String get sntIntro =>
      'Les signalements vont aux modérateurs NOTORYX, qui les examinent un par un à la main. Les bannissements approuvés reviennent sous forme de liste indicative : les nœuds signalés reçoivent une étiquette, et rien n\'est bloqué sur le maillage.';

  @override
  String get sntEnable => 'Utiliser la modération communautaire';

  @override
  String get sntEnableSub =>
      'Désactivée par défaut. Tant qu\'elle l\'est, NOTORYX ne contacte jamais le service de modération.';

  @override
  String get sntHide => 'Masquer les messages des expéditeurs signalés';

  @override
  String get sntHideSub =>
      'Messages de canal uniquement. Vous pouvez le désactiver à tout moment.';

  @override
  String sntSynced(String time) {
    return 'Liste de bannissement mise à jour $time';
  }

  @override
  String get sntNeverSynced => 'Liste de bannissement pas encore téléchargée';

  @override
  String sntFlaggedCount(int count) {
    return 'Nœuds signalés : $count';
  }

  @override
  String sntQueued(int count) {
    return 'Signalements en attente d\'envoi : $count';
  }

  @override
  String get sntRefresh => 'Mettre à jour maintenant';

  @override
  String get sntYourNode => 'Votre nœud';

  @override
  String get sntYourNodeClear => 'Votre nœud n\'est pas signalé.';

  @override
  String sntYourNodeFlagged(String caseRef) {
    return 'Votre nœud est signalé (dossier $caseRef). S\'il s\'agit d\'une erreur, vous pouvez faire appel.';
  }

  @override
  String get sntYourNodeUnknown =>
      'Connectez une radio pour vérifier votre nœud.';

  @override
  String get sntAppealPending => 'Votre appel est en cours d\'examen.';

  @override
  String get sntAppeal => 'Faire appel';

  @override
  String get sntAppealOther => 'Faire appel d\'un dossier par son numéro';

  @override
  String get sntYourReports => 'Vos signalements récents';

  @override
  String get sntReport => 'Signaler aux modérateurs';

  @override
  String sntReportTitle(String name) {
    return 'Signaler $name';
  }

  @override
  String get sntReasonSpam => 'Spam ou publicité';

  @override
  String get sntReasonFlooding => 'Saturation du maillage';

  @override
  String get sntReasonAbuse => 'Harcèlement ou abus';

  @override
  String get sntReasonImpersonation => 'Usurpation d\'identité';

  @override
  String get sntReasonOther => 'Autre';

  @override
  String get sntNote => 'Détails (facultatif)';

  @override
  String get sntIncludeMessage => 'Inclure ce message';

  @override
  String get sntSends =>
      'Envoie l\'ID et le nom du nœud, votre motif et, si la case est cochée, ce message. Pas votre nom, votre clé ni votre position.';

  @override
  String get sntSend => 'Envoyer le signalement';

  @override
  String sntSent(String caseRef) {
    return 'Signalement envoyé ($caseRef)';
  }

  @override
  String get sntQueuedOne =>
      'Pas de connexion. Le signalement sera envoyé plus tard.';

  @override
  String sntRejected(String message) {
    return 'Signalement refusé : $message';
  }

  @override
  String get sntOffPrompt => 'Activer la modération communautaire ?';

  @override
  String get sntTurnOn => 'Activer';

  @override
  String get sntFlagged => 'Signalé';

  @override
  String sntFlaggedHint(String caseRef) {
    return 'Signalé par les modérateurs NOTORYX (dossier $caseRef). À titre indicatif seulement.';
  }

  @override
  String get sntCaseRef => 'Numéro de dossier (SNT-1234)';

  @override
  String get sntStatement => 'Pourquoi le bannissement devrait-il être levé ?';

  @override
  String get sntContact =>
      'Contact (facultatif, visible des modérateurs seulement)';

  @override
  String get sntAppealSend => 'Envoyer l\'appel';

  @override
  String get sntAppealReceived => 'Appel envoyé. Un modérateur va l\'examiner.';

  @override
  String get sntAppealUnknown => 'Aucun dossier Meshtastic ne porte ce numéro.';

  @override
  String get sntAppealNotOpen =>
      'Ce dossier n\'a pas de bannissement actif, ou un appel est déjà en attente.';

  @override
  String get sntAppealTooMany => 'Trop d\'appels. Réessayez dans une minute.';

  @override
  String get sntFailed =>
      'Impossible de joindre le service de modération. Réessayez plus tard.';

  @override
  String get pvSent7 =>
      'Signalements, appels et vérifications de la liste de bannissement aux modérateurs NOTORYX via sentinel-relay.meshmayhem.org, seulement si vous activez la modération communautaire';

  @override
  String get psTitle => 'Trouver un lieu';

  @override
  String get psHint => 'Nom d\'un nœud, d\'un point de passage ou d\'un lieu';

  @override
  String get psNoLocal =>
      'Aucun nœud ni point de passage ne correspond. Essayez la recherche en ligne.';

  @override
  String get psOnlineNote =>
      'La recherche en ligne envoie ce que vous avez saisi au service Nominatim d\'OpenStreetMap, qui voit aussi votre adresse IP. Elle nécessite un accès à internet.';

  @override
  String get psSearchOnline => 'Rechercher en ligne';

  @override
  String get psTooSoon =>
      'Attendez une seconde avant de relancer une recherche en ligne.';

  @override
  String get psOnlineFailed =>
      'Recherche en ligne impossible. Vérifiez que le téléphone a accès à internet et réessayez.';

  @override
  String get psNoOnline => 'Aucun lieu trouvé en ligne.';

  @override
  String get psAttribution => 'Données de lieux © contributeurs OpenStreetMap';

  @override
  String get psKindNode => 'Nœud';

  @override
  String get psKindWaypoint => 'Point de passage';

  @override
  String get psKindOnline => 'Lieu';

  @override
  String get mapFindPlace => 'Trouver un lieu';

  @override
  String mapFoundPin(String name) {
    return 'Trouvé : $name';
  }

  @override
  String get pvSent8 =>
      'Ce que vous saisissez dans Trouver un lieu, au service Nominatim d\'OpenStreetMap, seulement quand vous touchez Rechercher en ligne ; il voit votre adresse IP';

  @override
  String get takReceiveTitle => 'Depuis ATAK';

  @override
  String get takReceiveIntro =>
      'Affiche sur la carte de cette application les marqueurs que partage ATAK sur ce téléphone, comme les membres de l\'équipe et les points de la carte. Ils restent sur ce téléphone et ne sont jamais envoyés sur le maillage.';

  @override
  String get takReceiveSwitch => 'Afficher les marqueurs ATAK sur la carte';

  @override
  String get takReceivePort => 'Port UDP d\'écoute';

  @override
  String takReceiveStatus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marqueurs affichés',
      one: '$count marqueur affiché',
      zero: 'À l\'écoute. Aucun marqueur pour l\'instant.',
    );
    return '$_temp0';
  }

  @override
  String takReceiveProblem(String error) {
    return 'Écoute impossible : $error';
  }

  @override
  String get takReceiveHowTo =>
      'Dans ATAK, ouvrez Settings, puis Network Preferences, puis Manage Outputs, et ajoutez une sortie UDP vers 127.0.0.1 sur ce port. Les marqueurs disparaissent quand ATAK les indique comme périmés.';

  @override
  String get takClear => 'Effacer les marqueurs';

  @override
  String get takFriendly => 'Ami';

  @override
  String get takHostile => 'Hostile';

  @override
  String get takNeutral => 'Neutre';

  @override
  String get takUnknown => 'Inconnu';

  @override
  String get takPoint => 'Point de la carte';

  @override
  String mapTakPin(String kind, String callsign) {
    return 'ATAK $kind : $callsign';
  }

  @override
  String mapTakUpdated(String time, String stale) {
    return 'Depuis ATAK, mis à jour à $time. Affiché jusqu\'à $stale.';
  }

  @override
  String get takSamePort =>
      'Utilisez un port différent de celui où les positions sont envoyées.';

  @override
  String get nodesFavoritesOnly => 'Favoris uniquement';

  @override
  String get nodesNoFavorites => 'Aucun favori pour l\'instant';

  @override
  String get nodesNoFavoritesHint =>
      'Ouvrez un nœud et touchez son étoile pour lui faire confiance. Favoris uniquement n\'affichera alors que les personnes de confiance.';

  @override
  String get mapShowAllNodes => 'Afficher tous les nœuds';

  @override
  String get topologyTitle => 'Schéma du réseau';

  @override
  String get topologyEmpty =>
      'Rien à dessiner pour l\'instant. Les nœuds apparaissent dès que votre radio connaît leur nombre de sauts, ou qu\'un nœud envoie Neighbor Info.';

  @override
  String get topologyHint =>
      'Votre radio est au centre et chaque anneau est un saut de plus. Les lignes sont les liens des rapports Neighbor Info (plus épais = meilleur signal) et les nœuds entendus directement. Touchez un point pour ouvrir le nœud.';

  @override
  String get topologyNoReports =>
      'Pas encore de rapports Neighbor Info : seuls les nœuds entendus directement ont des lignes. Activez le module Neighbor Info sur vos radios pour voir plus de liens.';

  @override
  String topologyRing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'À $count sauts',
      one: 'À 1 saut',
      zero: 'Entendus directement',
    );
    return '$_temp0';
  }

  @override
  String topologyLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count liens',
      one: '1 lien',
    );
    return '$_temp0';
  }

  @override
  String topologySemantics(int count, int rings) {
    return 'Schéma du réseau : $count nœuds sur $rings anneaux autour de votre radio.';
  }
}
