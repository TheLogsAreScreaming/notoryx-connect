// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabHome => 'Home';

  @override
  String get tabNodes => 'Nodes';

  @override
  String get tabChats => 'Chats';

  @override
  String get tabMap => 'Map';

  @override
  String get tabTools => 'Tools';

  @override
  String get tabSettings => 'Settings';

  @override
  String get connOffline => 'Offline';

  @override
  String get connScanning => 'Scanning';

  @override
  String get connConnecting => 'Connecting';

  @override
  String get connSyncing => 'Syncing';

  @override
  String get connConnected => 'Connected';

  @override
  String get connError => 'Error';

  @override
  String radioStatus(String status) {
    return 'Radio: $status';
  }

  @override
  String radioStatusTip(String status) {
    return 'Radio: $status. Tap to manage.';
  }

  @override
  String get radioStatusHint => 'manage the radio';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get toolsSubtitle =>
      'Utilities for planning, testing and running a deployment.';

  @override
  String get toolsDoctor => 'Connection doctor';

  @override
  String get toolsDoctorSub =>
      'Find out why a radio won\'t connect or keeps dropping';

  @override
  String get toolsBeforeYouGo => 'Before you go';

  @override
  String get toolsChecklist => 'Deployment checklist';

  @override
  String get toolsBattery => 'Battery runtime';

  @override
  String get toolsBatterySub => 'Estimate hours from capacity and average draw';

  @override
  String get toolsCalculate => 'Calculate';

  @override
  String get toolsMeshTools => 'Mesh tools';

  @override
  String get toolsHealth => 'Mesh health & airtime';

  @override
  String get toolsHealthSub =>
      'How busy the channel is and how much your radio transmits';

  @override
  String get toolsLink => 'Link planner';

  @override
  String get toolsLinkSub =>
      'Check line of sight between two nodes over the terrain';

  @override
  String get toolsRange => 'Range test';

  @override
  String get toolsRangeSub =>
      'Log packets from a range test sender with signal and distance';

  @override
  String get toolsTraceroute => 'Traceroute';

  @override
  String get toolsStore => 'Store & forward';

  @override
  String get toolsStoreSub => 'Replay messages you missed from a router';

  @override
  String get toolsBeacons => 'Mesh beacons';

  @override
  String get toolsRecords => 'Records';

  @override
  String get toolsIncident => 'Incident log, templates & coverage';

  @override
  String get toolsIncidentSub => 'Saved field records and exports';

  @override
  String get toolsSignal => 'Signal';

  @override
  String get toolsTelemetry => 'Live telemetry';

  @override
  String get toolsNothingYet =>
      'Nothing received yet. Metrics appear when nodes send them.';

  @override
  String get toolsGuide => 'Bluetooth signal guide';

  @override
  String get toolsGuideSub => 'What the signal numbers (RSSI) mean';

  @override
  String get toolsScan => 'Scan for radios';

  @override
  String get toolsCheck0 => 'Radio charged';

  @override
  String get toolsCheck1 => 'Antenna attached';

  @override
  String get toolsCheck2 => 'Region configured';

  @override
  String get toolsCheck3 => 'Primary channel verified';

  @override
  String get toolsCheck4 => 'GPS / position policy checked';

  @override
  String toolsReady(int done, int total) {
    return '$done of $total ready';
  }

  @override
  String get toolsBatteryField => 'Battery (mAh)';

  @override
  String get toolsDrawField => 'Average draw (mA)';

  @override
  String toolsAboutHours(String hours) {
    return 'About $hours hours';
  }

  @override
  String get toolsTraceReady => 'Show the relay path to a node and back';

  @override
  String get toolsTraceOff => 'Connect to a radio to trace routes';

  @override
  String get toolsBeaconsSub =>
      'Hear mesh invitations nearby and send your own';

  @override
  String toolsBeaconsHeard(int count) {
    return '$count heard • send your own';
  }

  @override
  String toolsReporting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nodes reporting device metrics',
      one: '$count node reporting device metrics',
    );
    return '$_temp0';
  }

  @override
  String get toolsTelemetryOff => 'Connect to a radio to receive telemetry';

  @override
  String toolsBatteryPct(int pct) {
    return 'Battery $pct%';
  }

  @override
  String toolsChannelBusy(String pct) {
    return 'Channel busy $pct%';
  }

  @override
  String toolsTransmitting(String pct) {
    return 'Transmitting $pct%';
  }

  @override
  String get toolsSigExcellent => 'Excellent, very close';

  @override
  String get toolsSigStrong => 'Strong';

  @override
  String get toolsSigUsable => 'Usable';

  @override
  String get toolsSigWeak => 'Weak';

  @override
  String get toolsSigVeryWeak => 'Very weak, may drop';

  @override
  String get toolsScanning => 'Scanning…';

  @override
  String toolsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bluetooth devices found',
      one: '$count Bluetooth device found',
    );
    return '$_temp0';
  }

  @override
  String get deliveryReceived => 'Received';

  @override
  String get deliveryQueued => 'Queued';

  @override
  String get deliverySent => 'Sent';

  @override
  String get deliveryDelivered => 'Delivered';

  @override
  String get deliveryFailed => 'Not delivered';

  @override
  String get hopsDirect => 'Direct';

  @override
  String hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hops',
      one: '$count hop',
    );
    return '$_temp0';
  }

  @override
  String get chatsNoMention => 'No nodes heard yet to mention.';

  @override
  String get chatsMentionNode => 'Mention a node';

  @override
  String get chatsViaMqttFull =>
      'Arrived over MQTT (the internet), not over the air';

  @override
  String get chatsPathUnknown => 'Path not reported by the sender\'s firmware';

  @override
  String get chatsHeardDirect => 'Heard directly, no relays';

  @override
  String chatsLastThrough(String name) {
    return ', last through $name';
  }

  @override
  String chatsLastThroughEnding(String hex) {
    return ', last through a node ending in $hex';
  }

  @override
  String chatsCameThrough(int hops, String via) {
    String _temp0 = intl.Intl.pluralLogic(
      hops,
      locale: localeName,
      other: 'Came through $hops relays$via',
      one: 'Came through $hops relay$via',
    );
    return '$_temp0';
  }

  @override
  String get chatsReact => 'React';

  @override
  String chatsReactEmoji(String emoji) {
    return 'React $emoji';
  }

  @override
  String get chatsNoSignal => 'No signal reading';

  @override
  String get chatsUnpin => 'Unpin';

  @override
  String get chatsPin => 'Pin';

  @override
  String get chatsCopyText => 'Copy text';

  @override
  String get chatsCopied => 'Message copied';

  @override
  String chatsReactionFailed(String error) {
    return 'Reaction not sent: $error';
  }

  @override
  String chatsSendFailed(String error) {
    return 'Message not sent: $error';
  }

  @override
  String get chatsYou => 'You';

  @override
  String get chatsYouLower => 'you';

  @override
  String chatsChannelN(int n) {
    return 'Channel $n';
  }

  @override
  String get chatsReactHint => 'react to this message';

  @override
  String get chatsViaMqtt => 'via MQTT';

  @override
  String get chatsPinned => 'Pinned';

  @override
  String get chatsMentionsYou => 'Mentions you';

  @override
  String chatsReactions(String list) {
    return 'Reactions: $list';
  }

  @override
  String chatsReactionFrom(String emoji, String name) {
    return '$emoji from $name';
  }

  @override
  String get chatsConnectedSub => 'Connected. Messages send right away.';

  @override
  String get chatsOfflineSub =>
      'Offline. Messages wait in a queue and send when your radio connects.';

  @override
  String get chatsStorageProblem => 'Message storage problem';

  @override
  String get chatsFilterShowing =>
      'Showing messages that match your word filters';

  @override
  String chatsFilterHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages hidden by your word filters',
      one: '$count message hidden by your word filters',
    );
    return '$_temp0';
  }

  @override
  String get chatsHide => 'Hide';

  @override
  String get chatsShow => 'Show';

  @override
  String get chatsStatLink => 'Link';

  @override
  String get chatsOnline => 'Online';

  @override
  String get chatsStatMessages => 'Messages';

  @override
  String get chatsStatQueued => 'Queued';

  @override
  String get chatsNewMessage => 'New message';

  @override
  String get chatsKeyChanged => 'Security key changed';

  @override
  String chatsKeyChangedBody(String name) {
    return '$name now shows a different key. Check with its owner before sending anything private. Open the node to review or trust the new key.';
  }

  @override
  String get chatsTo => 'To';

  @override
  String get chatsEveryone => 'Everyone on the channel';

  @override
  String chatsDirect(String name) {
    return 'Direct • $name';
  }

  @override
  String get chatsChannelLabel => 'Channel';

  @override
  String get chatsChannelBroadcast => 'Channel 0 • Broadcast';

  @override
  String chatsChannelOffline(int n) {
    return 'Channel $n • Offline';
  }

  @override
  String chatsChannelNamed(int n, String name) {
    return 'Channel $n • $name';
  }

  @override
  String get chatsDefault => 'Default';

  @override
  String chatsMessageChannel(int n) {
    return 'Message Channel $n';
  }

  @override
  String chatsMessageNode(String name) {
    return 'Message $name';
  }

  @override
  String get chatsSend => 'Send';

  @override
  String get chatsQuickReplies => 'Quick replies';

  @override
  String get chatsMessages => 'Messages';

  @override
  String get chatsHoldHint => 'Hold a message for more';

  @override
  String get chatsSearch => 'Search message history';

  @override
  String get chatsClearSearch => 'Clear search';

  @override
  String get chatsNoMatches => 'No matches';

  @override
  String get chatsNoMatchesBody => 'No messages match your search.';

  @override
  String get chatsEmpty => 'No mesh messages yet';

  @override
  String get chatsEmptyBody =>
      'Channel and direct messages appear here once your radio hears them.';

  @override
  String get chatsNewAbove => 'New messages above';

  @override
  String get chatsAutoReplies => 'Automatic replies';

  @override
  String get chatsBot => 'Bot mode';

  @override
  String get chatsBotOn =>
      'On. Replies to direct messages and answers !help and !status, within quiet hours and airtime limits.';

  @override
  String get chatsBotOff => 'Off. No automatic replies are sent.';

  @override
  String get chatsBotReply => 'Bot reply message';

  @override
  String get chatsBotReplyField => 'Message to send while Bot mode is on';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonConnect => 'Connect';

  @override
  String get commonDisconnect => 'Disconnect';

  @override
  String get agoNow => 'just now';

  @override
  String agoMin(int n) {
    return '$n min ago';
  }

  @override
  String agoHours(int n) {
    return '$n h ago';
  }

  @override
  String agoDays(int n) {
    return '$n d ago';
  }

  @override
  String get rssiStrong => 'Strong Bluetooth signal';

  @override
  String get rssiUsable => 'Usable Bluetooth signal';

  @override
  String get rssiWeak => 'Weak Bluetooth signal';

  @override
  String get rssiVeryWeak => 'Very weak Bluetooth signal';

  @override
  String get heardAny => 'Any time';

  @override
  String get heardHour => '1 hour';

  @override
  String get heardDay => '24 hours';

  @override
  String get heardWeek => '7 days';

  @override
  String nodesConnectFailed(String error) {
    return 'Could not connect: $error';
  }

  @override
  String nodesUsbFailed(String error) {
    return 'Could not connect over USB: $error';
  }

  @override
  String nodesNotesFor(String name) {
    return 'Notes for $name';
  }

  @override
  String get nodesNotesHint => 'Location, antenna, observations…';

  @override
  String nodesConnectedTo(String name) {
    return 'Connected to $name.';
  }

  @override
  String get nodesYourRadio => 'your radio';

  @override
  String get nodesFindRadio =>
      'Find your radio nearby and connect over Bluetooth.';

  @override
  String get nodesRadiosFound => 'Radios found';

  @override
  String get nodesMeshNodes => 'Mesh nodes';

  @override
  String get nodesStatus => 'Status';

  @override
  String get nodesConnProblem => 'Connection problem';

  @override
  String get nodesDiagnose => 'Diagnose';

  @override
  String get nodesNearby => 'Radios nearby';

  @override
  String get nodesLooking => 'Looking for radios…';

  @override
  String get nodesStopScan => 'Stop scan';

  @override
  String get nodesRadio => 'Radio';

  @override
  String get nodesOverUsb => 'Over USB';

  @override
  String get nodesOverWifi => 'Over Wi-Fi';

  @override
  String get nodesConnectWifi => 'Connect over Wi-Fi';

  @override
  String get nodesConnectUsb => 'Connect over USB';

  @override
  String get nodesNoRadios => 'No radios found yet';

  @override
  String get nodesNoRadiosBody =>
      'Turn your radio on, keep it close, then tap Scan for radios.';

  @override
  String get nodesTryDemo => 'No radio? Try the demo';

  @override
  String get nodesMeshtasticRadio => 'Meshtastic radio';

  @override
  String get nodesBluetoothDevice => 'Bluetooth device';

  @override
  String nodesCount(int count) {
    return 'Mesh nodes ($count)';
  }

  @override
  String nodesCountOf(int shown, int total) {
    return 'Mesh nodes ($shown of $total)';
  }

  @override
  String nodesNoneHeard(String window) {
    return 'No nodes heard in the last $window';
  }

  @override
  String get nodesPickLonger => 'Pick a longer time to see older nodes.';

  @override
  String get nodesShowAll => 'Show all nodes';

  @override
  String get nodesHealth => 'Mesh health';

  @override
  String get nodesDetails => 'Details';

  @override
  String get nodesKnown => 'Known nodes';

  @override
  String get nodesWaiting => 'Waiting to send';

  @override
  String get nodesSignalQuality => 'Signal quality';

  @override
  String nodesSignalSummary(int count, String snr) {
    return '$count messages heard • latest signal-to-noise $snr';
  }

  @override
  String get nodesNotMeasured => 'not yet measured';

  @override
  String nodesSignalHistory(int count) {
    return 'Signal history of the last $count messages';
  }

  @override
  String get nodesSignalStarts =>
      'Signal history starts when another node sends a message.';

  @override
  String get nodesMeasuredFrom => 'Measured from received text messages only.';

  @override
  String get nodesEncounters => 'Saved encounters';

  @override
  String nodesSeen(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Seen $count times • last $when',
      one: 'Seen $count time • last $when',
    );
    return '$_temp0';
  }

  @override
  String get nodesTapNotes => 'Tap to add notes';

  @override
  String get nodesRemoveFav => 'Remove favorite';

  @override
  String get nodesAddFav => 'Add to favorites';

  @override
  String get nodesMore => 'More';

  @override
  String get nodesFieldTools => 'Field tools';

  @override
  String get nodesFieldToolsSub =>
      'Signal reference, checklists, backups and more';

  @override
  String get nodesReadyBanner =>
      'Your radio is connected. Nodes update live as they are heard.';

  @override
  String get nodesHelpBanner =>
      'Tap Scan for radios, then Connect. The app checks it is a Meshtastic radio and downloads its node list before it is ready to use.';

  @override
  String get nodesHeardWithin => 'Show nodes heard within';

  @override
  String get nodesWifiHelp =>
      'For radios with Wi-Fi or Ethernet turned on. Your phone must be on the same network.';

  @override
  String get nodesAddress => 'Radio address';

  @override
  String get nodesAddressHint => 'e.g. 192.168.1.42 or meshtastic.local';

  @override
  String get nodesPort => 'Port';

  @override
  String get nodesPortHelp => 'Meshtastic uses 4403';

  @override
  String get nodesUsbHelp =>
      'Plug the radio into the phone with a USB data cable (an OTG adapter may be needed). Android asks for permission the first time.';

  @override
  String nodesUsbListFailed(String error) {
    return 'Could not list USB devices: $error';
  }

  @override
  String get nodesNoUsb => 'No USB devices found';

  @override
  String get nodesNoUsbBody =>
      'Check the cable carries data, not just power, then refresh.';

  @override
  String nodesLikelyRadio(String chip) {
    return 'Likely a radio • $chip';
  }

  @override
  String get nodesOtherUsb => 'Other USB device';

  @override
  String get nodesRefresh => 'Refresh';

  @override
  String get setRadioSec => 'Radio';

  @override
  String get setRadioConfig => 'Radio configuration';

  @override
  String get setIdentity => 'Node identity';

  @override
  String get setChange => 'Change radio settings';

  @override
  String get setChangeSub => 'Owner, LoRa, channels, device role and position';

  @override
  String get setDeviceLora => 'Device & LoRa';

  @override
  String get setChannels => 'Channels';

  @override
  String get setModules => 'Modules';

  @override
  String get setShareLoc => 'Share phone location with mesh';

  @override
  String get setPrecision => 'Location precision';

  @override
  String get setPrecisionSub => 'Rounded on this phone before it is sent';

  @override
  String get setLowPower => 'Low-power field mode';

  @override
  String get setApp => 'App';

  @override
  String get setWidget => 'Show messages on the home-screen widget';

  @override
  String get setYourData => 'Your data';

  @override
  String get setRadioBackup => 'Encrypted radio backup';

  @override
  String get setRadioBackupSub =>
      'Save or restore settings and channel keys, protected by a password';

  @override
  String get setPhoneBackup => 'Phone data backup';

  @override
  String get setPhoneBackupSub =>
      'Chats, nodes, waypoints, records and settings, for moving to a new phone';

  @override
  String get setPrivacy => 'Privacy & data';

  @override
  String get setPrivacySub =>
      'What is stored and sent; delete chat history or all phone data';

  @override
  String get setDemo => 'Demo mode';

  @override
  String get setAbout => 'About';

  @override
  String get setLicenses => 'Third-party licenses';

  @override
  String get setReadAloud => 'Read messages aloud';

  @override
  String get setReadSub =>
      'Uses the phone\'s text-to-speech, including with the screen off';

  @override
  String get setMqttTitle => 'Carry MQTT through this phone';

  @override
  String get setBackground => 'Background connection';

  @override
  String get setOpenSettings => 'Open settings';

  @override
  String get setOfflineTiles => 'Offline map tiles';

  @override
  String get setClear => 'Clear';

  @override
  String get setAlerts => 'Field alerts';

  @override
  String get setAlertsSub =>
      'Phone notifications only; nothing is sent over the mesh';

  @override
  String get setLowBattery => 'Low battery';

  @override
  String get setThreshold => 'Battery threshold';

  @override
  String get setNewNode => 'New node';

  @override
  String get setNewNodeSub => 'Your radio hears a node for the first time';

  @override
  String get setFavQuiet => 'Favorite goes quiet';

  @override
  String get setMeshQuiet => 'Mesh goes quiet';

  @override
  String get setMeshQuietSub =>
      'Half or more of the nodes you were hearing stop being heard';

  @override
  String get setQuietAfter => 'Quiet after';

  @override
  String get setRadioData => 'Radio data';

  @override
  String get setRadioDataSub =>
      'Lost or replaced a radio? Move its messages, nodes and history to the new one';

  @override
  String get setMoveToConnected => 'Move to connected';

  @override
  String get setDataUnreadable => 'Radio data could not be read.';

  @override
  String get setNoData => 'No radio data on this phone yet.';

  @override
  String get setFilters => 'Filters';

  @override
  String get setFilterHelp =>
      'Incoming messages with these words are hidden, not deleted.';

  @override
  String get setShowFiltered => 'Show filtered messages';

  @override
  String get setIgnored => 'Ignored';

  @override
  String get setUnignore => 'Unignore';

  @override
  String get setMuted => 'Muted';

  @override
  String get setUnmute => 'Unmute';

  @override
  String get setOffLoc => 'Off. Your phone location is never sent.';

  @override
  String get setOnNoRadio => 'On. Starts when a radio is connected.';

  @override
  String get setOnNoFix => 'On. Waiting for a GPS fix.';

  @override
  String setOnSent(String time) {
    return 'On. Last sent $time.';
  }

  @override
  String get setSubtitle => 'Your radio, how the app behaves, and your data.';

  @override
  String get setCanChange => 'Connected • settings can be changed';

  @override
  String setReadOnly(String version, String minimum, String url) {
    return 'Read-only: firmware $version is older than $minimum. Update at $url.';
  }

  @override
  String get setConnectToView =>
      'Connect to a radio to view and change its settings';

  @override
  String get setWaitingNode => 'Waiting for this radio\'s node information';

  @override
  String get setNoLong => 'No long name';

  @override
  String get setNoShort => 'No short name';

  @override
  String get setNoId => 'ID not reported';

  @override
  String setConfigWait(int count) {
    return 'Not received yet ($count configuration messages)';
  }

  @override
  String setChannelWait(int count) {
    return 'Not received yet ($count channel messages)';
  }

  @override
  String setModulesSub(int count) {
    return '$count module messages received. Change them in radio settings.';
  }

  @override
  String setShareLocSub(String status) {
    return '$status\nUsed when the radio has no GPS of its own. Updates every 5 min, or sooner when you move.';
  }

  @override
  String get setPrecise => 'Precise';

  @override
  String setAbout2(String distance) {
    return 'About $distance';
  }

  @override
  String get setLowPowerSub =>
      'Shared location uses balanced GPS and updates every 15 min, or after 200 m of movement. The radio link and coverage recording are unchanged.';

  @override
  String get setWidgetSub =>
      'Off: the widget shows only how many messages are unread. On: it also shows the sender and text, which anyone holding the phone can see.';

  @override
  String get setDemoSub =>
      'Explore the app with a pretend radio and mesh. Nothing is sent, and your own messages and settings are left alone.';

  @override
  String get setDevBuild => 'Development build • Independent mesh companion';

  @override
  String get setConnection => 'Connection';

  @override
  String get setConnectionSub =>
      'Bluetooth LE • Safety mode on: no unverified device is treated as a mesh node';

  @override
  String get setTrademark => 'Trademark & compatibility';

  @override
  String get setDevWarning =>
      'Do not rely on this development build as your only way to call for help.';

  @override
  String get setChannelsKept => 'Channel messages kept';

  @override
  String setChannelsDeleted(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Channel messages deleted after $days days',
      one: 'Channel messages deleted after $days day',
    );
    return '$_temp0';
  }

  @override
  String setNewestPer(String count) {
    return 'newest $count per conversation';
  }

  @override
  String get setReadOn => 'read aloud on';

  @override
  String get setDeleteOld => 'Delete old channel messages';

  @override
  String get setDirectKept => 'Direct messages are always kept';

  @override
  String get setNever => 'Never';

  @override
  String setAfterDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'After $days days',
      one: 'After $days day',
    );
    return '$_temp0';
  }

  @override
  String get setHistory => 'Message history';

  @override
  String get setHistoryHelp =>
      'Per channel or direct conversation. A lower limit deletes older messages.';

  @override
  String setKeepNewest(String count) {
    return 'Keep newest $count';
  }

  @override
  String get setMqttOff => 'Off. Uses your phone\'s data when on.';

  @override
  String get setMqttWait => 'On. Waits for your radio.';

  @override
  String get setMqttNoConfig =>
      'Your radio isn\'t set to use this. Turn on MQTT and \"Proxy to client\" in its settings.';

  @override
  String setMqttConnected(String host, int up, int down, String kb) {
    return 'Connected to $host. $up sent, $down received, about $kb KB of data.';
  }

  @override
  String setMqttConnecting(String host) {
    return 'Connecting to $host…';
  }

  @override
  String get setMqttFailed => 'Couldn\'t connect.';

  @override
  String get setMqttStarting => 'Starting…';

  @override
  String get setBgOptimized =>
      'Battery optimization can pause NOTORYX Connect when it is not on screen and drop the radio link. Set its battery use to Unrestricted to stay connected.';

  @override
  String get setBgAllowed =>
      'Allowed to run in the background. A notification shows while a radio is connected.';

  @override
  String get setSizeUnknown => 'Size unknown';

  @override
  String setMbSaved(String mb) {
    return '$mb MB saved';
  }

  @override
  String get setTilesHelp =>
      'Map areas you view online stay available offline for a year (up to 500 MB).';

  @override
  String get setAlertSaveFailed =>
      'Alert settings apply now, but could not be saved.';

  @override
  String setLowBatterySub(int pct) {
    return 'Your radio or a favorite reports $pct% or less';
  }

  @override
  String setFavQuietSub(String time) {
    return 'A favorite is not heard for $time while connected';
  }

  @override
  String get setTheConnected => 'the connected radio';

  @override
  String setMoveTitle(String label) {
    return 'Move $label?';
  }

  @override
  String setMoveBody(String to, String id) {
    return 'Its messages, offline queue, NodeVault history, trails and telemetry history move to $to. Whatever $to already has is kept, so nothing is overwritten. $id then no longer has an entry of its own.\n\nTo be safe, make a phone data backup first.';
  }

  @override
  String get setMove => 'Move';

  @override
  String setMoved(String label, String to) {
    return 'Moved $label to $to.';
  }

  @override
  String setDataCounts(int messages, int nodes, int trails) {
    return '$messages messages • $nodes nodes • $trails trails';
  }

  @override
  String get setConnectNew =>
      'Connect to the new radio to move an old radio\'s data to it.';

  @override
  String setFilterCounts(int ignored, int muted, int words) {
    return '$ignored ignored • $muted muted • $words filtered words';
  }

  @override
  String get setFilteredWords => 'Filtered words';

  @override
  String get setWordField => 'Word or phrase';

  @override
  String get setAddWord => 'Add filtered word';

  @override
  String setRemoveWord(String word) {
    return 'Remove $word';
  }

  @override
  String get setIgnoredMuted => 'Ignored and muted nodes';

  @override
  String get setNoneIgnored => 'None. Open a node to ignore or mute it.';

  @override
  String get chatsForward => 'Forward';

  @override
  String get chatsForwardTo => 'Forward to';

  @override
  String get chatsForwardReview => 'Check the message, then tap Send.';

  @override
  String chatsChannelNumbered(int index, String name) {
    return 'Channel $index: $name';
  }

  @override
  String get chatsSchedule => 'Send later';

  @override
  String get chatsSchedule15 => 'In 15 minutes';

  @override
  String get chatsSchedule60 => 'In 1 hour';

  @override
  String get chatsSchedule240 => 'In 4 hours';

  @override
  String get chatsScheduleTomorrow => 'Tomorrow at 8:00';

  @override
  String get chatsSchedulePick => 'Pick a date and time';

  @override
  String get chatsScheduleNote =>
      'Goes out only while the app is running and the radio is connected.';

  @override
  String chatsScheduleFull(int max) {
    return 'You can schedule up to $max messages.';
  }

  @override
  String get chatsScheduled => 'Scheduled';

  @override
  String chatsScheduledFor(String day, String time) {
    return '$day at $time';
  }

  @override
  String get chatsScheduleMissed =>
      'Not sent: the radio was not connected in time';

  @override
  String get chatsScheduleCancel => 'Cancel scheduled message';

  @override
  String get mapNoPositions => 'No node has reported a position yet';

  @override
  String get mapConnectForPositions => 'Connect a radio to show node positions';

  @override
  String mapPlaced(int placed, int total) {
    return '$placed of $total nodes placed';
  }

  @override
  String mapWaypointCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count waypoints',
      one: '$count waypoint',
    );
    return '$_temp0';
  }

  @override
  String get mapLongPressHint => 'Long-press the map to drop a waypoint';

  @override
  String get mapHeardWithin => 'Show nodes heard within';

  @override
  String get mapHeardAny => 'Heard any time';

  @override
  String get mapHeardHour => 'Heard in last hour';

  @override
  String get mapHeardDay => 'Heard in last 24 hours';

  @override
  String get mapHeardWeek => 'Heard in last 7 days';

  @override
  String get mapShowStreet => 'Show street map';

  @override
  String get mapShowTopo => 'Show topographic map';

  @override
  String get mapLinkPlanner => 'Link planner';

  @override
  String get mapRallyRoutes => 'Rally points & routes';

  @override
  String get mapTeam => 'Team';

  @override
  String get mapZones => 'Zones';

  @override
  String get mapExportGpx => 'Export GPX';

  @override
  String get mapHideTrails => 'Hide trails';

  @override
  String get mapShowTrails => 'Show trails';

  @override
  String get mapHideLinks => 'Hide radio links';

  @override
  String get mapShowLinks => 'Show radio links';

  @override
  String get mapShowAll => 'Show all nodes';

  @override
  String mapPlanHint(int max) {
    return 'Tap the map to add stops, in order. Up to $max.';
  }

  @override
  String mapPlanProgress(int count, int max, String distance) {
    return '$count of $max stops • $distance';
  }

  @override
  String get mapUndo => 'Undo';

  @override
  String get mapShareRoute => 'Share route';

  @override
  String get mapRallyIntro =>
      'Rally points are where everyone should meet. Drop one with a long-press and choose \"Rally point\". Routes are shared as numbered waypoints, so other Meshtastic apps see the stops too.';

  @override
  String get mapRallyPoints => 'Rally points';

  @override
  String get mapNoneYet => 'None yet.';

  @override
  String mapDistanceOfYou(String distance, String direction) {
    return '$distance $direction of you';
  }

  @override
  String get mapNoOwnPosition => 'Your radio has no position yet';

  @override
  String get mapShowOnMap => 'Show on map';

  @override
  String get mapRoutes => 'Routes';

  @override
  String mapStops(int count) {
    return '$count stops';
  }

  @override
  String mapStopsHeard(int heard, int count) {
    return '$heard of $count stops heard';
  }

  @override
  String get mapFromYou => 'from you';

  @override
  String mapFromNode(String name) {
    return 'from $name';
  }

  @override
  String get mapPlanRoute => 'Plan a route';

  @override
  String get mapConnectForRoutes => 'Connect a radio to share routes';

  @override
  String mapRouteShared(int count) {
    return 'Route shared: $count stops on channel 0.';
  }

  @override
  String mapRouteStopped(int sent, int count, String error) {
    return 'Route stopped after $sent of $count stops: $error';
  }

  @override
  String mapGpxExported(int waypoints, int trails) {
    return 'Exported $waypoints waypoints and $trails trails as GPX.';
  }

  @override
  String mapGpxFailed(String error) {
    return 'Could not export GPX: $error';
  }

  @override
  String get mapWatchTrip => 'Trip contacts';

  @override
  String get mapWatchFavorites => 'Favorites';

  @override
  String get mapWatchAll => 'All nodes';

  @override
  String get mapAlertArrive => 'arrive';

  @override
  String get mapAlertLeave => 'leave';

  @override
  String get mapAlertBoth => 'arrive or leave';

  @override
  String get mapZonesIntro =>
      'Get a phone alert when someone arrives at or leaves a place, like camp or the trailhead. Alerts need the radio connected; nothing is sent over the mesh.';

  @override
  String get mapNoZones => 'No zones yet.';

  @override
  String mapZoneSummary(String radius, String watch, String alert) {
    return '$radius radius • $watch • alert when they $alert';
  }

  @override
  String mapDeleteZone(String name) {
    return 'Delete $name';
  }

  @override
  String get mapAddZone => 'Add zone at map center';

  @override
  String get mapTeamIntro =>
      'Your trip contacts. Tap one to find them on the map.';

  @override
  String get mapNoTeam => 'No trip contacts yet';

  @override
  String get mapNoTeamHint =>
      'Add up to 6 people on HOME → Trip. They show here and stand out on the map.';

  @override
  String get mapFreshOk => 'OK';

  @override
  String get mapFreshQuiet => 'QUIET';

  @override
  String get mapFreshLost => 'LOST';

  @override
  String get mapConnectForWaypoints => 'Connect a radio to share waypoints.';

  @override
  String mapWaypointShared(String name) {
    return 'Waypoint \"$name\" shared on channel 0.';
  }

  @override
  String mapWaypointFailed(String error) {
    return 'Could not share waypoint: $error';
  }

  @override
  String get mapNeverExpires => 'Never expires';

  @override
  String mapExpires(String time) {
    return 'Expires $time';
  }

  @override
  String mapSharedBy(String name) {
    return 'Shared by $name';
  }

  @override
  String get mapLocked => 'Locked to its creator';

  @override
  String get mapDeleteEveryone => 'Delete for everyone';

  @override
  String mapDeleted(String name) {
    return 'Deleted \"$name\".';
  }

  @override
  String mapDeleteFailed(String error) {
    return 'Could not delete: $error';
  }

  @override
  String get mapUnknown => 'unknown';

  @override
  String mapFromThisRadio(String distance) {
    return '$distance from this radio';
  }

  @override
  String mapPositionHeard(String position, String heard) {
    return 'Position: $position • Heard: $heard';
  }

  @override
  String get mapDirect => 'direct';

  @override
  String get mapBatteryExternal => 'Battery: external power';

  @override
  String mapBattery(int level) {
    return 'Battery: $level%';
  }

  @override
  String get mapOpenDetails => 'Open details';

  @override
  String get mapThisRadioSuffix => ', this radio';

  @override
  String mapTripContactSuffix(String summary) {
    return ', trip contact, $summary';
  }

  @override
  String get mapRallyPoint => 'Rally point';

  @override
  String get mapWaypoint => 'Waypoint';

  @override
  String get mapExpireHour => '1 hour';

  @override
  String get mapExpireDay => '1 day';

  @override
  String get mapExpireWeek => '1 week';

  @override
  String get mapExpireNever => 'Never';

  @override
  String get mapNewWaypoint => 'New waypoint';

  @override
  String get mapName => 'Name';

  @override
  String get mapDescription => 'Description (optional)';

  @override
  String get mapRallySub => 'Where everyone should meet';

  @override
  String get mapExpiresAfter => 'Expires after';

  @override
  String get mapOnlyMe => 'Only I can edit or delete';

  @override
  String get mapSharedChannel0 => 'Shared with everyone on channel 0.';

  @override
  String get mapShare => 'Share';

  @override
  String get mapNewZone => 'New zone';

  @override
  String mapCenteredOn(String lat, String lon) {
    return 'Centered on $lat, $lon';
  }

  @override
  String get mapZoneName => 'Name, e.g. Camp';

  @override
  String get mapRadius => 'Radius';

  @override
  String get mapWatch => 'Watch';

  @override
  String get mapAlertWhen => 'Alert when they';

  @override
  String get mapAdd => 'Add';

  @override
  String get mapRouteName => 'Route name';

  @override
  String mapRouteSends(int count) {
    return 'Sends $count waypoints on channel 0, about 3 seconds apart. They expire after a day.';
  }

  @override
  String get mapShowHeatmap => 'Show coverage heatmap';

  @override
  String get mapHideHeatmap => 'Hide coverage heatmap';

  @override
  String get mapHeatmapEmpty =>
      'No coverage readings yet. Turn on Record coverage in Field records.';

  @override
  String mapHeatmapSummary(int readings) {
    return 'Coverage: $readings readings. Numbers are average SNR in dB.';
  }

  @override
  String get mapHeatStrong => 'Strong';

  @override
  String get mapHeatFair => 'Fair';

  @override
  String get mapHeatWeak => 'Weak';

  @override
  String get mapShowRemembered => 'Show remembered nodes';

  @override
  String get mapHideRemembered => 'Hide remembered nodes';

  @override
  String get mapRememberedNone => 'No remembered nodes with a saved position.';

  @override
  String mapRememberedPin(String name, String when) {
    return '$name, remembered, last seen $when';
  }

  @override
  String get mapRememberedNote =>
      'Your radio no longer lists this node. This is where it last reported.';

  @override
  String mapLastSeen(String when) {
    return 'Last seen $when';
  }

  @override
  String get lockTitle => 'NOTORYX Connect is locked';

  @override
  String get lockBody => 'Your radio stays connected while the app is locked.';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockReason => 'Unlock NOTORYX Connect';

  @override
  String get takTitle => 'ATAK feed';

  @override
  String get toolsTakSub => 'Swap positions with ATAK on this phone';

  @override
  String get takIntro =>
      'Sends the position of each mesh node to ATAK on this phone, once every 30 seconds. Nothing leaves the phone, and nothing goes out over the mesh.';

  @override
  String get takSwitch => 'Send mesh positions to ATAK';

  @override
  String get takPort => 'UDP port';

  @override
  String get takBadPort => 'Use a number from 1024 to 65535.';

  @override
  String takStatus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sending $count nodes',
      one: 'Sending $count node',
    );
    return '$_temp0';
  }

  @override
  String takProblem(String error) {
    return 'Could not send: $error';
  }

  @override
  String get takHowTo =>
      'In ATAK, open Settings, then Network Preferences, then Manage Inputs, and add a UDP input on this port. Nodes with no position in the last hour are left out.';

  @override
  String ndFailed(String error) {
    return 'Failed: $error';
  }

  @override
  String ndSendFailed(String error) {
    return 'Send failed: $error';
  }

  @override
  String get ndFieldNote => 'Field note';

  @override
  String get ndRemoveFavorite => 'Remove favorite';

  @override
  String get ndAddFavorite => 'Add favorite';

  @override
  String get ndShortName => 'Short name';

  @override
  String get ndHardware => 'Hardware';

  @override
  String get ndThisRadio => 'This radio';

  @override
  String get ndYes => 'Yes';

  @override
  String get ndLastHeard => 'Last heard';

  @override
  String get ndSignal => 'Signal';

  @override
  String get ndHopsAway => 'Hops away';

  @override
  String get ndDirect => 'Direct';

  @override
  String get ndBattery => 'Battery';

  @override
  String get ndExternalPower => 'External power';

  @override
  String get ndVoltage => 'Voltage';

  @override
  String get ndChannelUse => 'Channel use';

  @override
  String get ndPosition => 'Position';

  @override
  String get ndAltitude => 'Altitude';

  @override
  String get ndPositionAge => 'Position age';

  @override
  String get ndDistance => 'Distance';

  @override
  String get ndEncounters => 'Encounters';

  @override
  String get ndTraceroute => 'Traceroute';

  @override
  String get ndRequestPosition => 'Request position';

  @override
  String get ndPositionRequested =>
      'Position requested. It updates when the node replies.';

  @override
  String get ndRequestTelemetry => 'Request telemetry';

  @override
  String get ndTelemetryRequested =>
      'Telemetry requested. It updates when the node replies.';

  @override
  String get ndRemoteAdmin => 'Remote admin';

  @override
  String get ndRequestSensors => 'Request sensors';

  @override
  String get ndSensorsRequested =>
      'Sensor readings requested. Nodes without sensors don\'t answer.';

  @override
  String get ndMute => 'Mute notifications';

  @override
  String get ndMuteSub => 'Messages still show; no alerts or read-aloud';

  @override
  String get ndIgnore => 'Ignore this node';

  @override
  String get ndIgnoreSub =>
      'Hidden from nodes, map and chats; never notifies or gets bot replies. Undo here or in Settings.';

  @override
  String get ndAddNote => 'Tap to add a note';

  @override
  String get ndDirectMessages => 'DIRECT MESSAGES';

  @override
  String get ndNoDirect => 'No direct messages with this node yet.';

  @override
  String get ndDirectMessage => 'Direct message';

  @override
  String get ndSend => 'Send';

  @override
  String get ndRadioLinks => 'DIRECT RADIO LINKS';

  @override
  String get ndNoNeighbors =>
      'No neighbor reports yet. Nodes share these when the Neighbor Info module is enabled (Settings → Change radio settings → Neighborinfo).';

  @override
  String ndHears(int count) {
    return 'Hears directly ($count):';
  }

  @override
  String get ndNoneReported => '  No neighbors reported';

  @override
  String ndHeardBy(int count) {
    return 'Heard directly by ($count):';
  }

  @override
  String get ndTrustQ => 'Trust the new key?';

  @override
  String ndTrustBody(String name) {
    return 'Only do this if you have checked with $name\'s owner that they reset or replaced their radio. If not, someone else may be pretending to be this node.';
  }

  @override
  String get ndTrust => 'Trust new key';

  @override
  String get ndKeyChanged => 'Security key changed';

  @override
  String ndKeyChangedBody(String newCode, String oldCode) {
    return 'This node now shows a different key ($newCode) from the one first seen ($oldCode). Its radio may have been reset or replaced, or someone may be impersonating it. Check with its owner before sending private messages.';
  }

  @override
  String get ndSecurityKey => 'Security key';

  @override
  String get ndKeyNotShared =>
      'Not shared yet. Nodes on firmware 2.5 or newer share a key for private direct messages.';

  @override
  String ndSafetyCode(String code) {
    return 'Safety code $code\nCompare this with the owner\'s radio to be sure it\'s them.';
  }

  @override
  String get homeFirmwareTitle => 'Radio firmware update suggested';

  @override
  String get homeCheckIn => 'Check in';

  @override
  String get homeEmergency => 'Emergency';

  @override
  String get homeSosHint =>
      'Hold for 2 seconds. It goes to your trip contacts, and repeats every 5 minutes until someone replies.';

  @override
  String homeSosHintChannel(int channel) {
    return 'Hold for 2 seconds. It goes to your trip contacts and channel $channel, and repeats every 5 minutes until someone replies.';
  }

  @override
  String get homeNotReceived =>
      'Sent or queued does not mean received. Confirm with a reply or a call.';

  @override
  String get homeConnected => 'Radio connected';

  @override
  String get homeNotConnected => 'No radio connected';

  @override
  String get homeYourRadio => 'Your radio';

  @override
  String get homeConnectHint =>
      'Connect to check in, send an SOS and see the mesh.';

  @override
  String get homeNodes => 'Nodes';

  @override
  String get homeBattery => 'Battery';

  @override
  String get homeUnknown => 'Unknown';

  @override
  String get homePluggedIn => 'Plugged in';

  @override
  String get homeConnectRadio => 'Connect radio';

  @override
  String get homeTryDemo => 'Try the demo';

  @override
  String get homeTripRunning => 'Trip running';

  @override
  String get homeTripNotStarted => 'Trip not started';

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
    return 'Trip: $name';
  }

  @override
  String get homePlanTrip => 'Plan your trip';

  @override
  String homeOverdue(String names) {
    return 'Overdue: $names';
  }

  @override
  String homeCheckInLabel(String label) {
    return 'Check in: $label';
  }

  @override
  String homeDelivered(String label, String time, int delivered, int total) {
    return '$label at $time: delivered to $delivered of $total';
  }

  @override
  String homeNotDelivered(String names) {
    return 'not delivered to $names';
  }

  @override
  String homeWaiting(int count) {
    return '$count waiting';
  }

  @override
  String get homeDetails => 'Details';

  @override
  String get homeResend => 'Resend';

  @override
  String get homeSendSosQ => 'Send SOS?';

  @override
  String get homeSosRepeats =>
      'Your SOS repeats every 5 minutes until someone replies or you stop it.';

  @override
  String get homeSendSos => 'Send SOS';

  @override
  String get homeHoldSos => 'Hold for SOS';

  @override
  String homeSosReplied(String name) {
    return '$name replied. Repeats stopped.';
  }

  @override
  String homeSosNext(int sends, int max, String time) {
    return 'Sent $sends of $max. Next at $time.';
  }

  @override
  String get homeSosBusy =>
      ' The channel is busy, so repeats are spaced out to get through.';

  @override
  String homeSosDone(int max) {
    return 'Sent $max times. Repeats finished; the SOS stays shown until you stop it.';
  }

  @override
  String get homeSosActive => 'SOS active';

  @override
  String get homeImSafe => 'I\'m safe';

  @override
  String get homeStopNoMessage => 'Stop without message';

  @override
  String get frTitle => 'Field records';

  @override
  String get frTplAssistance => 'Assistance';

  @override
  String get frTplCheckIn => 'Check-in';

  @override
  String get frTplAllClear => 'All clear';

  @override
  String get frTooLong => 'Enter a message of 1–220 UTF-8 bytes.';

  @override
  String frBroadcastQ(int channel) {
    return 'Broadcast to channel $channel?';
  }

  @override
  String get frNoProof =>
      'Sending does not prove reception. Confirm with a reply or voice contact.';

  @override
  String get frSendMessage => 'Send message';

  @override
  String get frChanged =>
      'Radio or channel changed. Reconnect and review the message.';

  @override
  String get frSubmitted =>
      'Submitted to the radio. Check Chats for transmission status and replies.';

  @override
  String get frIncidentLog => 'Incident log';

  @override
  String get frIncidentLogSub => 'Private notes saved on this phone';

  @override
  String get frIncidentField => 'Incident or observation';

  @override
  String get frIncidentSaved => 'Incident saved.';

  @override
  String get frSaveIncident => 'Save incident';

  @override
  String get frIncidentCopied =>
      'Incident CSV copied. Paste into a file or spreadsheet.';

  @override
  String get frCopyIncident => 'Copy incident CSV';

  @override
  String frRadioOf(String time, String radio) {
    return '$time • Radio $radio';
  }

  @override
  String get frUnassigned => 'unassigned';

  @override
  String get frRemoveIncident => 'Remove incident';

  @override
  String get frRemoveIncidentQ => 'Remove this incident?';

  @override
  String get frKeep => 'Keep';

  @override
  String get frRemove => 'Remove';

  @override
  String get frIncidentRemoved => 'Incident removed.';

  @override
  String get frTemplates => 'Emergency & check-in templates';

  @override
  String get frTemplatesSub =>
      'Edit details, choose a channel, then review before sending';

  @override
  String get frMessageField => 'Message — replace the blank details';

  @override
  String get frBroadcastChannel => 'Broadcast channel';

  @override
  String frChannelItem(int index, String name) {
    return 'Channel $index • $name';
  }

  @override
  String get frReview => 'Review message';

  @override
  String get frNotEmergency =>
      'A template is ordinary mesh text. It does not contact emergency services.';

  @override
  String get frCoverage => 'Coverage history';

  @override
  String get frCoverageSub =>
      'Receiver location with received RF signal • local recording only';

  @override
  String get frRecord => 'Record coverage';

  @override
  String get frRecordSub =>
      'Requests phone GPS. Stops on disconnect. Does not send your location.';

  @override
  String get frRecordOn =>
      'Coverage recorder enabled; waiting for a fresh accurate GPS fix and RF packets.';

  @override
  String get frRecordOff => 'Coverage recorder stopped.';

  @override
  String frReadings(int count) {
    return '$count readings • maximum 2000 coverage readings • coverage expires after 30 days';
  }

  @override
  String get frCoverageCopied =>
      'Coverage CSV copied. Paste into a file or spreadsheet.';

  @override
  String get frCopyCoverage => 'Copy coverage CSV';

  @override
  String get frBot => 'Bot safeguards & quiet hours';

  @override
  String get frBotSub =>
      '6 replies/hour • 30-second spacing • 5-minute per-node cooldown';

  @override
  String get frBotEnable => 'Enable Bot Mode in Chats for this session.';

  @override
  String get frBotRules =>
      'Only fresh messages on the selected channel qualify. Replays and bot replies (NOTORYX: or Bastion:) are ignored. Quiet hours use this phone’s local time.';

  @override
  String get frQuiet => 'Quiet hours';

  @override
  String get frQuietStart => 'Quiet hours start';

  @override
  String get frQuietEnd => 'Quiet hours end';

  @override
  String get frBotChannel => 'Bot channel slot';

  @override
  String frChannelN(int index) {
    return 'Channel $index';
  }

  @override
  String frBytes(int bytes, int max) {
    return '$bytes of $max bytes. Blank lines are left out.';
  }

  @override
  String frBytesOver(int bytes, int max) {
    return '$bytes of $max bytes. Too long to send: shorten a field.';
  }

  @override
  String get frUseReport => 'Use report';

  @override
  String get rsTitle => 'Radio settings';

  @override
  String get rsNotReady => 'Radio not ready';

  @override
  String get rsNotReadySub =>
      'Connect to a radio and wait for READY to change settings.';

  @override
  String get rsAvailability => 'Settings availability';

  @override
  String get rsAvailabilitySub =>
      'Check reads before editing. Missing startup settings do not prove a module is unsupported. Results reset on reconnect.';

  @override
  String get rsStopChecking => 'Stop checking';

  @override
  String get rsOwner => 'Owner';

  @override
  String get rsOwnerSub => 'Long and short node names';

  @override
  String get rsLoraSub => 'Region, modem preset, hop limit, transmit';

  @override
  String get rsChannels => 'Channels';

  @override
  String get rsChannelsSub => 'Names, roles and encryption keys';

  @override
  String get rsDevice => 'Device';

  @override
  String get rsDeviceSub => 'Device role and rebroadcast mode';

  @override
  String get rsPosition => 'Position';

  @override
  String get rsPositionSub => 'Broadcast interval, GPS mode, smart position';

  @override
  String get rsAllSettings => 'ALL RADIO SETTINGS';

  @override
  String get rsModules => 'MODULES';

  @override
  String get rsRadioChanged =>
      'Connected radio changed while loading. Retry the read.';

  @override
  String rsSaveQ(String section) {
    return 'Save $section?';
  }

  @override
  String get rsSaveWarning =>
      'This writes the change to the connected radio. The radio may reboot and reconnect.';

  @override
  String get rsIdentityChanged =>
      'Radio identity changed or is unavailable. Reload before saving.';

  @override
  String rsSaved(String section) {
    return '$section saved and verified from radio.';
  }

  @override
  String rsNotVerified(String error) {
    return 'Save not verified: $error\nThe radio may have applied the change. Reload to inspect its current value; nothing will be resent automatically.';
  }

  @override
  String get rsSaveButton => 'SAVE';

  @override
  String rsUnavailable(String section) {
    return '$section settings are unavailable through this radio’s firmware API.';
  }

  @override
  String rsReadFailed(String error) {
    return 'Could not read from the radio: $error';
  }

  @override
  String get rsRetry => 'Retry';

  @override
  String get rsWaitingReconnect =>
      'Waiting for reconnect and a fresh settings read…';

  @override
  String get rsReload => 'Reload from radio';

  @override
  String get rsLongName => 'Long name';

  @override
  String get rsShortName => 'Short name';

  @override
  String get rsChooseRegion =>
      'Choose a region before saving; the radio will not transmit without one.';

  @override
  String get rsCustomInvalid =>
      'Custom settings require a positive bandwidth, spreading factor 5–12 and coding rate denominator 5–8. Check your radio’s supported values.';

  @override
  String get rsRegionWarning =>
      'Changing region or modem preset disconnects this radio from nodes that keep the old settings.';

  @override
  String get rsRegion => 'Region';

  @override
  String get rsUsePreset => 'Use modem preset';

  @override
  String get rsModemPreset => 'Modem preset';

  @override
  String get rsBandwidth => 'Bandwidth (kHz)';

  @override
  String get rsSpreadFactor => 'Spreading factor';

  @override
  String get rsCodingRate => 'Coding rate denominator (5–8)';

  @override
  String get rsRxBoost => 'RX boosted gain';

  @override
  String get rsRxBoostSub =>
      'Internal SX126x receiver gain; separate from external LNA';

  @override
  String get rsLna => 'External LNA';

  @override
  String get rsLnaReported =>
      'External receive amplifier reported by this radio';

  @override
  String get rsLnaNone =>
      'This radio has not reported a controllable external LNA';

  @override
  String rsHopLimit(int hops) {
    return 'Hop limit: $hops';
  }

  @override
  String get rsTransmit => 'Transmit enabled';

  @override
  String get rsTransmitSub => 'Off makes the radio receive-only';

  @override
  String rsInfraWarning(String role) {
    return '$role is for fixed infrastructure with good coverage. On a handheld it wastes airtime and battery.';
  }

  @override
  String get rsRole => 'Role';

  @override
  String get rsRebroadcast => 'Rebroadcast mode';

  @override
  String get rsIntervalInvalid =>
      'Broadcast interval must be 0 (firmware default) or at least 30 seconds.';

  @override
  String get rsGpsMode => 'GPS mode';

  @override
  String get rsInterval => 'Broadcast interval (seconds, 0 = default)';

  @override
  String get rsSmart => 'Smart position broadcast';

  @override
  String get rsSmartSub => 'Send extra updates when the node moves';

  @override
  String get rsFixed => 'Fixed position';

  @override
  String get rsFixedSub => 'Report the last known position instead of GPS';

  @override
  String get rsShareQr => 'Share as QR code';

  @override
  String get rsImportLink => 'Import channel link';

  @override
  String get rsDisabled => 'Disabled';

  @override
  String get rsDefaultName => '(default name)';

  @override
  String rsChannelsFailed(String error) {
    return 'Could not read channels: $error';
  }

  @override
  String get rsNoEncryption => 'No encryption';

  @override
  String get rsDefaultKey => 'Default key';

  @override
  String get rsAes128 => 'AES-128 key';

  @override
  String get rsAes256 => 'AES-256 key';

  @override
  String get rsUnknownKey => 'Unrecognized key';

  @override
  String rsChannelN(int index) {
    return 'Channel $index';
  }

  @override
  String get rsKeyWarning =>
      'The encryption key changes. Nodes without the new key can no longer read this channel. Share it from the channel QR code.';

  @override
  String get rsChannelName => 'Name (blank uses the preset name)';

  @override
  String rsEncryption(String key) {
    return 'Encryption: $key';
  }

  @override
  String get rsNewAes256 => 'New random AES-256';

  @override
  String rsGpsHidden(String model) {
    return 'GPS pins are hidden: $model has its GPS wired by the maker, so they do nothing.';
  }

  @override
  String get bcShareQ => 'Share your primary channel?';

  @override
  String get bcShareBody =>
      'The beacon will include your primary channel\'s name and key. Anyone in range can then join it and read its messages.';

  @override
  String get bcShare => 'Share';

  @override
  String get bcSent => 'Beacon sent.';

  @override
  String bcNotSent(String error) {
    return 'Beacon not sent: $error';
  }

  @override
  String get bcTitle => 'Mesh beacons';

  @override
  String get bcClear => 'Clear heard beacons';

  @override
  String get bcIntro =>
      'A beacon is a short broadcast that tells nearby radios a mesh is here, and can invite them to a channel. Radios on the newer Meshtastic firmware show it; NOTORYX Connect shows beacons it hears with any firmware.';

  @override
  String get bcSendTitle => 'Send a beacon';

  @override
  String get bcMessage => 'Beacon message';

  @override
  String get bcMessageHelp =>
      'Sent on your primary channel. At most one beacon an hour.';

  @override
  String bcBytes(int used, int max) {
    return '$used/$max bytes';
  }

  @override
  String get bcTooLong => 'Too long';

  @override
  String get bcAddLocationNone => 'Add my location (no position yet)';

  @override
  String get bcAddLocation => 'Add my location as a Plus Code';

  @override
  String get bcInvite => 'Invite to my primary channel';

  @override
  String get bcInviteSub =>
      'Includes the channel name and key, and your region and preset';

  @override
  String get bcSending => 'Sending…';

  @override
  String get bcSend => 'Send beacon';

  @override
  String get bcConnect => 'Connect to a radio to send a beacon.';

  @override
  String bcNext(String time) {
    return 'Next beacon can be sent at $time.';
  }

  @override
  String get bcHeard => 'Heard beacons';

  @override
  String get bcNoneHeard => 'No beacons heard yet';

  @override
  String get bcNoneHeardSub =>
      'Beacons from radios in range on your channels appear here.';

  @override
  String bcFrom(String name) {
    return 'From $name';
  }

  @override
  String bcHeardAt(String time) {
    return 'heard $time';
  }

  @override
  String bcChannel(String name) {
    return 'Channel \"$name\"';
  }

  @override
  String get bcDefault => 'Default';

  @override
  String bcRegion(String name) {
    return 'region $name';
  }

  @override
  String bcPreset(String name) {
    return 'preset $name';
  }

  @override
  String bcSlot(int slot) {
    return 'slot $slot';
  }

  @override
  String get bcNoMessage => '(no message)';

  @override
  String bcInvitesTo(String offer) {
    return 'Invites to: $offer';
  }

  @override
  String get bcJoin => 'Review and join channel';

  @override
  String get csShareTitle => 'Share channels';

  @override
  String csReadFailed(String error) {
    return 'Could not read channels: $error';
  }

  @override
  String get csRetry => 'Retry';

  @override
  String csPrimary(String name) {
    return 'Primary: $name';
  }

  @override
  String csSecondary(String name) {
    return 'Secondary: $name';
  }

  @override
  String get csDefaultName => '(default name)';

  @override
  String get csCopyLink => 'Copy link';

  @override
  String get csCopied => 'Channel link copied.';

  @override
  String get csKeysWarning =>
      'This code contains your channel encryption keys. Anyone who scans it can read and send on these channels.';

  @override
  String get csReplaceQ => 'Replace all channels?';

  @override
  String get csAddQ => 'Add channels?';

  @override
  String get csReplaceBody =>
      'All 8 channel slots will be overwritten. You will lose access to current channels unless you have their link. The radio will reboot.';

  @override
  String get csReplaceLoraBody =>
      'All 8 channel slots and the LoRa settings will be overwritten. You will lose access to current channels unless you have their link. The radio will reboot.';

  @override
  String get csAddBody =>
      'New channels from the link go into free slots. Existing channels and LoRa settings stay the same.';

  @override
  String get csApply => 'Apply';

  @override
  String get csAlreadyThere =>
      'All channels from the link are already on the radio.';

  @override
  String csWritten(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count channels written and verified from radio.',
      one: '$count channel written and verified from radio.',
    );
    return '$_temp0';
  }

  @override
  String csNotVerified(String error) {
    return 'Import not verified: $error\nNothing will be resent automatically.';
  }

  @override
  String csRefused(String error) {
    return 'Import refused: $error';
  }

  @override
  String csFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get csImportTitle => 'Import channels';

  @override
  String get csScan => 'Scan channel QR code';

  @override
  String get csScanTitle => 'Scan channel QR';

  @override
  String get csLinkLabel => 'Meshtastic channel link';

  @override
  String get csPaste => 'Paste';

  @override
  String csLora(String region, String modem) {
    return 'LoRa: $region, $modem';
  }

  @override
  String get csCustomModem => 'custom modem';

  @override
  String get csAdd => 'Add to radio';

  @override
  String get csReplaceAll => 'Replace all';

  @override
  String get csApplyRadio => 'Apply to radio';

  @override
  String get trTitle => 'Plan your trip';

  @override
  String get trName => 'Trip name';

  @override
  String trContacts(int count, int max) {
    return 'TRIP CONTACTS ($count/$max)';
  }

  @override
  String get trContactsSub =>
      'Check-ins and SOS go to each of them as a direct message.';

  @override
  String get trNoNodes => 'No nodes yet';

  @override
  String get trNoNodesSub =>
      'Connect to your radio so nearby nodes and favorites appear here.';

  @override
  String get trOverdue => 'Overdue alert';

  @override
  String get trOverdueHelp =>
      'Warns you when a trip contact has not been heard for this long';

  @override
  String get trOff => 'Off';

  @override
  String trMinutes(int count) {
    return '$count min';
  }

  @override
  String trHours(int count) {
    return '$count h';
  }

  @override
  String get trReminder => 'Check-in reminder';

  @override
  String get trReminderHelp =>
      'Reminds you to check in this long after your last check-in';

  @override
  String trEvery(String time) {
    return 'Every $time';
  }

  @override
  String get trSosChannel => 'Also send SOS on a channel';

  @override
  String get trSosChannelHelp =>
      'Everyone on that channel sees your SOS, not just trip contacts';

  @override
  String get trContactsOnly => 'No, trip contacts only';

  @override
  String trChannelItem(int index, String name) {
    return 'Channel $index • $name';
  }

  @override
  String get trDefault => 'Default';

  @override
  String get trReadiness => 'Readiness check';

  @override
  String get trEnd => 'End trip';

  @override
  String get trStart => 'Start trip';

  @override
  String trRunning(String time) {
    return 'Trip running since $time. Overdue alerts and reminders are on.';
  }

  @override
  String get trNotRunning =>
      'Starting the trip turns on overdue alerts and check-in reminders. Check-ins and SOS work any time.';

  @override
  String get pvEncryptedOn => 'Chat history is now encrypted.';

  @override
  String get pvEncryptedOff => 'Chat history is no longer encrypted.';

  @override
  String get pvLockOnReason => 'Turn on app lock';

  @override
  String get pvLockOffReason => 'Turn off app lock';

  @override
  String get pvLockUnchanged => 'App lock was not changed.';

  @override
  String get pvStored1 =>
      'Chat history and offline queues for each radio (newest 500 messages per radio)';

  @override
  String get pvStored2 =>
      'NodeVault: nodes your radios have heard, plus your favorites and notes';

  @override
  String get pvStored3 => 'Waypoints received from the mesh';

  @override
  String get pvStored4 =>
      'Incident log and coverage records, only if you create them';

  @override
  String get pvStored5 => 'Field alert, bot, location and appearance settings';

  @override
  String get pvStored6 => 'Map tiles for areas you have viewed';

  @override
  String get pvSent1 =>
      'Messages you send go to your radio, which transmits them on the mesh using the channel\'s encryption key';

  @override
  String get pvSent2 =>
      'Your phone location, only while \"Share phone location\" is on, at the precision you choose';

  @override
  String get pvSent3 =>
      'Position, telemetry and traceroute requests that you start';

  @override
  String get pvSent4 =>
      'Map tile requests to OpenStreetMap servers when you view the map; they see your IP address';

  @override
  String get pvSent5 =>
      'Topographic map tile requests to OpenTopoMap servers, only while the topo map is shown; they see your IP address';

  @override
  String get pvSent6 =>
      'Points along a link to the Open-Meteo elevation service, only when you check a link in the Link planner';

  @override
  String get pvDisconnectFirst =>
      'Disconnect the radio before deleting phone data.';

  @override
  String get pvDeleteAllQ => 'Delete all phone data?';

  @override
  String get pvDeleteChatsQ => 'Delete chat history?';

  @override
  String get pvDeleteAllBody =>
      'Deletes chats and offline queues for every radio, NodeVault, favorites and notes, waypoints, field records, cached map tiles and all app settings from this phone. Radio settings are not changed. This cannot be undone; make a phone data backup first if you may need it.\n\nThe app closes afterwards.';

  @override
  String get pvDeleteChatsBody =>
      'Deletes chat history and queued messages for every radio from this phone. Messages already sent on the mesh are not affected. This cannot be undone.\n\nThe app closes afterwards.';

  @override
  String get pvDelete => 'Delete';

  @override
  String pvDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get pvDeleted => 'Deleted';

  @override
  String get pvDeletedBody =>
      'NOTORYX Connect will close now so nothing still in memory is saved again.';

  @override
  String get pvCloseApp => 'Close app';

  @override
  String get pvTitle => 'Privacy & data';

  @override
  String get pvIntro =>
      'NOTORYX Connect has no account, analytics, ads or servers of its own. Everything it keeps stays in this app\'s private storage on your phone and is removed if you uninstall it.';

  @override
  String get pvAppLock => 'App lock';

  @override
  String get pvAppLockSub =>
      'Ask for your fingerprint, face or screen lock when opening the app, and after a minute away. You will also need it to reach SOS. The radio stays connected.';

  @override
  String get pvAppLockNone =>
      'Set a screen lock on this phone to use app lock.';

  @override
  String get pvEncrypt => 'Encrypt chat history';

  @override
  String get pvEncryptSub =>
      'Scrambles saved messages using a key held in this phone\'s secure storage. If that key is lost, for example after moving to a new phone, the saved history can\'t be read. Export anything you need first.';

  @override
  String get pvStored => 'Stored on this phone';

  @override
  String get pvSent => 'Sent off this phone';

  @override
  String get pvDeleteChats => 'Delete chat history';

  @override
  String get pvDeleteAll => 'Delete all phone data';

  @override
  String pbFailed(String error) {
    return 'Operation failed: $error';
  }

  @override
  String get pbShortPassword =>
      'Use at least 12 characters for the backup password.';

  @override
  String get pbCreated =>
      'Backup created. Save the file somewhere off this phone. Keep the password separately; it cannot be recovered.';

  @override
  String get pbDisconnectFirst =>
      'Disconnect the radio before restoring phone data.';

  @override
  String get pbReplaceQ => 'Replace all phone data?';

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
    return 'Backup created $date by version $version.\n\nIt has chat history for $_temp0 ($messages messages) and $items saved items in all.\n\nEverything NOTORYX Connect stores on this phone (chats, offline queues, NodeVault, waypoints, field records and settings) is replaced. Radio settings are not changed. The app closes when the restore finishes; open it again to continue.';
  }

  @override
  String get pbReplace => 'Replace phone data';

  @override
  String get pbRestored => 'Restore complete';

  @override
  String get pbRestoredBody =>
      'NOTORYX Connect will close now so nothing still in memory overwrites the restored data. Open it again to continue.';

  @override
  String get pbTitle => 'Phone data backup';

  @override
  String get pbIntro =>
      'Backs up everything NOTORYX Connect stores on this phone: chat history and offline queues for every radio, NodeVault favorites and notes, waypoints, field records and app settings. Use it to move to a new phone. The file is encrypted with your password. Radio settings have their own backup.';

  @override
  String get pbPassword => 'Backup password (at least 12 characters)';

  @override
  String get pbCreate => 'Create backup file';

  @override
  String get pbRestore => 'Restore from file';

  @override
  String get rbFailed =>
      'Operation failed. If a restore had started, settings may be partially changed. Reconnect and check the radio before retrying.';

  @override
  String get rbReady =>
      'Encrypted backup ready. Copy it and save it in a text file. Keep the password separately; it cannot be recovered.';

  @override
  String get rbReplaceQ => 'Replace radio settings?';

  @override
  String rbSummary(
    String source,
    String firmware,
    String date,
    String target,
    int configs,
    int modules,
  ) {
    return 'Backup from radio $source (firmware $firmware), created $date.\n\nTarget: $target. Replaces owner names, all 8 channel slots including their secret keys, $configs configuration sections and $modules modules. Device identity/security keys, session credentials, phone chats and maps are not restored (use Phone data backup for those).\n\nSave a backup of the target first. The radio may reboot or lose mesh connectivity. A radio write cannot guarantee rollback after a power or connection failure.';
  }

  @override
  String get rbReplace => 'Replace settings';

  @override
  String get rbRadioChanged => 'Connected radio changed.';

  @override
  String get rbRestored =>
      'Restore complete. Fresh radio readback matches the backup.';

  @override
  String get rbTitle => 'Encrypted radio backup';

  @override
  String get rbIntro =>
      'Backs up fresh radio configuration and modules reported by the firmware, all channel slots and owner names. Channel keys and any network/module credentials are password encrypted. Device identity keys and session credentials are excluded.';

  @override
  String get rbCreate => 'Create encrypted backup';

  @override
  String get rbText => 'Encrypted backup text';

  @override
  String get rbTextHint => 'Paste a saved encrypted backup to restore';

  @override
  String get rbCopied => 'Encrypted backup copied. Save it in a text file.';

  @override
  String get rbCopy => 'Copy encrypted backup';

  @override
  String get rbReview => 'Review and restore';

  @override
  String get raPower => 'Power';

  @override
  String get raDisplay => 'Display';

  @override
  String get raLoraQ => 'Change LoRa settings remotely?';

  @override
  String get raLoraBody =>
      'If the node ends up on a different region, preset or frequency from the rest of the mesh, it can no longer be reached and someone will have to fix it in person.';

  @override
  String get raSaveAnyway => 'Save anyway';

  @override
  String raSent(String section) {
    return '$section settings sent. The node may restart to apply them.';
  }

  @override
  String get raNameSent => 'Name sent to the node.';

  @override
  String raRestartQ(String name) {
    return 'Restart $name?';
  }

  @override
  String get raRestartBody =>
      'The node goes off the mesh for a short while as it restarts.';

  @override
  String get raRestart => 'Restart';

  @override
  String get raRestartRequested => 'Restart requested.';

  @override
  String get raDiscardQ => 'Discard changes?';

  @override
  String get raDiscardBody => 'Your edits haven\'t been sent to the node.';

  @override
  String get raDiscard => 'Discard';

  @override
  String get raTitle => 'Remote admin';

  @override
  String get raIntro =>
      'Change this node\'s settings over the mesh. Each request uses airtime and can take up to a minute.';

  @override
  String get raUnavailable => 'Remote admin isn\'t available';

  @override
  String get raWaiting => 'Waiting for the node';

  @override
  String get raAccess => 'Access';

  @override
  String get raAccessHint =>
      'Ask the node for its details. If it answers, your radio is allowed to manage it.';

  @override
  String get raCheckAccess => 'Check access';

  @override
  String get raAccessConfirmed => 'Access confirmed';

  @override
  String raFirmware(String version, String role) {
    return 'Firmware $version · $role';
  }

  @override
  String get raUnknown => 'unknown';

  @override
  String get raNoName => 'No name';

  @override
  String raShortName(String name) {
    return 'Short name $name';
  }

  @override
  String get raRename => 'Rename';

  @override
  String get raRestartNode => 'Restart node';

  @override
  String get raSettings => 'Settings';

  @override
  String get raLoraWarning =>
      'A wrong LoRa setting can cut this node off the mesh. Change it only if you can reach the node in person.';

  @override
  String raSend(String section) {
    return 'Send $section settings';
  }

  @override
  String get raUndo => 'Undo';

  @override
  String get raKeyTitle => 'Your radio\'s admin key';

  @override
  String raKeyBody(String name) {
    return 'Before $name will accept changes, its owner adds this key under Radio settings → Security → Admin key, using any Meshtastic app.';
  }

  @override
  String get raNoKey => 'Your radio hasn\'t reported its key yet.';

  @override
  String get raCopyKey => 'Copy admin key';

  @override
  String get raKeyCopied => 'Admin key copied.';

  @override
  String get raRenameTitle => 'Rename node';

  @override
  String get raSendButton => 'Send';

  @override
  String get frSaluteTitle => 'SALUTE report';

  @override
  String get frNineTitle => '9-Line medical evacuation';

  @override
  String get frSaluteS => 'Size';

  @override
  String get frSaluteSHint => 'How many people or vehicles';

  @override
  String get frSaluteA => 'Activity';

  @override
  String get frSaluteAHint => 'What they are doing';

  @override
  String get frSaluteL => 'Location';

  @override
  String get frSaluteLHint => 'Where they are';

  @override
  String get frSaluteU => 'Unit';

  @override
  String get frSaluteUHint => 'Who they are, uniform or markings';

  @override
  String get frSaluteT => 'Time';

  @override
  String get frSaluteTHint => 'When you saw them';

  @override
  String get frSaluteE => 'Equipment';

  @override
  String get frSaluteEHint => 'What they have with them';

  @override
  String get frNine1 => 'Pickup location';

  @override
  String get frNine1Hint => 'Coordinates or landmark';

  @override
  String get frNine2 => 'Radio frequency and callsign';

  @override
  String get frNine2Hint => 'How to reach you';

  @override
  String get frNine3 => 'Patients by urgency';

  @override
  String get frNine3Hint => 'For example 1 urgent, 2 routine';

  @override
  String get frNine4 => 'Special equipment';

  @override
  String get frNine4Hint => 'None, hoist, extraction, ventilator';

  @override
  String get frNine5 => 'Patients by type';

  @override
  String get frNine5Hint => 'Litter or walking';

  @override
  String get frNine6 => 'Security at pickup';

  @override
  String get frNine6Hint => 'No threat, possible, or armed escort';

  @override
  String get frNine7 => 'How the site is marked';

  @override
  String get frNine7Hint => 'Panel, smoke, light, or none';

  @override
  String get frNine8 => 'Patient status';

  @override
  String get frNine8Hint => 'Who the patients are';

  @override
  String get frNine9 => 'Hazards and terrain';

  @override
  String get frNine9Hint => 'Slope, wires, contamination';

  @override
  String get svcConnectToCheckIn => 'Connect to a radio to check in.';

  @override
  String get svcChooseContacts => 'Choose trip contacts first.';

  @override
  String get svcConnectToSos => 'Connect to a radio to send an SOS.';

  @override
  String get svcChooseSosTargets =>
      'Choose trip contacts or an SOS channel first.';

  @override
  String svcFirmwareUnsupported(String version, String minimum, String url) {
    return 'Your radio runs firmware $version. NOTORYX Connect needs $minimum or newer to change radio settings, so settings are read-only. Messages still work. Update at $url.';
  }

  @override
  String svcFirmwareOutdated(String version, String recommended, String url) {
    return 'Your radio runs firmware $version. Updating to $recommended or newer at $url turns on newer features such as sensor readings and security key checks.';
  }

  @override
  String get svcToday => 'Today';

  @override
  String get svcYesterday => 'Yesterday';

  @override
  String get svcLowBatteryOwn => 'Your radio battery is low';

  @override
  String svcLowBattery(String name) {
    return '$name battery is low';
  }

  @override
  String svcLowBatteryOwnBody(int level) {
    return 'Your radio reports $level% battery.';
  }

  @override
  String svcLowBatteryBody(String name, int level) {
    return '$name reports $level% battery.';
  }

  @override
  String svcNewNode(String name) {
    return 'New node: $name';
  }

  @override
  String svcNewNodeBody(String name) {
    return 'Your radio heard $name for the first time.';
  }

  @override
  String get svcMeshQuieter => 'The mesh has gone quieter';

  @override
  String svcMeshQuieterBody(int active, int peak) {
    return 'Heard $active nodes in the last hour, down from $peak. A repeater may be down, or you may have moved out of range.';
  }

  @override
  String svcQuiet(String name) {
    return '$name has gone quiet';
  }

  @override
  String svcQuietBody(String time) {
    return 'Not heard for $time.';
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
  String get svcReply => 'Reply';

  @override
  String get svcDirectChannel => 'Direct messages';

  @override
  String get svcDirectChannelSub => 'Messages sent to you on the mesh.';

  @override
  String get svcChannelChannel => 'Channel messages';

  @override
  String get svcChannelChannelSub => 'Messages on your mesh channels.';

  @override
  String get svcFieldChannel => 'Field alerts';

  @override
  String get svcFieldChannelSub =>
      'Low battery, new nodes and favorites that go quiet.';

  @override
  String svcFromChannel(String sender, int channel) {
    return '$sender • channel $channel';
  }

  @override
  String mapHeatSummary(int strong, int fair, int weak, int readings) {
    return 'Coverage map: $strong strong, $fair fair, $weak weak areas, from $readings readings.';
  }

  @override
  String get nrTitle => 'Moving to a new radio';

  @override
  String nrSub(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get nrStep1 =>
      'With the old radio connected, create an encrypted backup here and save the text somewhere safe.';

  @override
  String get nrStep2 =>
      'Write down the old radio\'s region and modem preset (Radio settings → LoRa).';

  @override
  String get nrStep3 =>
      'Update the new radio\'s firmware to the same version or newer.';

  @override
  String get nrStep4 =>
      'Connect the new radio and set its region before anything else, so it may transmit.';

  @override
  String get nrStep5 =>
      'Paste the backup, review it and restore. Use the same password.';

  @override
  String get nrStep6 =>
      'Check Channels: names and keys should match, and send a test message to someone on each channel.';

  @override
  String get nrStep7 =>
      'The new radio has its own node ID and security key. Tell your contacts, and re-add it as an admin on any nodes you manage remotely.';

  @override
  String get nrReset => 'Start over';

  @override
  String get cpLabel => 'Position shared on this channel';

  @override
  String get cpHelp =>
      'How exact your radio\'s position is when sent on this channel. Other channels keep their own setting.';

  @override
  String get cpNotSet => 'Not set: the firmware decides';

  @override
  String get cpNone => 'Don\'t share position';

  @override
  String get cpExact => 'Exact position';

  @override
  String cpWithin(String distance) {
    return 'Within about $distance';
  }

  @override
  String get rdBattery => 'Radio battery';

  @override
  String get rdNotReported => 'Not reported yet.';

  @override
  String get rdExternal => 'On external power.';

  @override
  String rdChargeNow(int level) {
    return '$level%. Charge the radio before you leave.';
  }

  @override
  String rdChargeSoon(int level) {
    return '$level%. Consider charging or bringing a power bank.';
  }

  @override
  String rdLevel(int level) {
    return '$level%.';
  }

  @override
  String get rdFirmware => 'Firmware';

  @override
  String get rdConnectToCheck => 'Connect your radio to check.';

  @override
  String get rdTooOld => 'Too old.';

  @override
  String get rdUpdateRecommended => 'Update recommended.';

  @override
  String get rdVersionUnknown => 'Version not reported.';

  @override
  String get rdSupported => 'Supported.';

  @override
  String get rdChannels => 'Channels';

  @override
  String get rdNoChannels => 'No channels on this radio.';

  @override
  String rdSosChannelGone(int channel) {
    return 'SOS channel $channel no longer exists. Pick another in your trip plan.';
  }

  @override
  String rdChannelsSet(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count channels set up.',
      one: '$count channel set up.',
    );
    return '$_temp0';
  }

  @override
  String get rdContacts => 'Trip contacts';

  @override
  String get rdChooseContacts => 'Choose who gets your check-ins and SOS.';

  @override
  String rdNoRoute(String names) {
    return 'No route to $names.';
  }

  @override
  String rdNotHeard(String names) {
    return 'Not heard in the last 2 hours: $names. Run a route test, or check they\'re on.';
  }

  @override
  String rdAllHeard(int count) {
    return 'All $count heard recently.';
  }

  @override
  String get rdPosition => 'Position';

  @override
  String get rdRecentPosition => 'Your radio has a recent position.';

  @override
  String get rdWaitingPhone =>
      'Waiting for a position from this phone. Check location is on.';

  @override
  String get rdNoPosition =>
      'No recent position, so others can\'t see where you are. Turn on the radio\'s GPS or share this phone\'s location.';

  @override
  String get rdBackground => 'Background';

  @override
  String get rdBackgroundRestricted =>
      'Battery optimisation can cut the link with the screen off. Set NOTORYX Connect to \"Unrestricted\".';

  @override
  String get rdBackgroundOk =>
      'The app can stay connected with the screen off.';

  @override
  String get rdCouldntCheck => 'Couldn\'t check.';

  @override
  String get rpTitle => 'Readiness check';

  @override
  String get rpReady => 'Ready to go';

  @override
  String get rpCheck => 'Check these before you leave';

  @override
  String get rpNotReady => 'Not ready yet';

  @override
  String get rpNeedRadio => 'Some checks need your radio';

  @override
  String get rpNotReceived =>
      'Sent or queued does not mean received. Agree a backup plan.';

  @override
  String get rpTestRoute => 'Test a route';

  @override
  String get rpTestHint =>
      'Sends one route request to that contact. Use sparingly on busy meshes.';

  @override
  String get rpRouteFound => 'Route found';

  @override
  String get rpNoRoute => 'No route found';

  @override
  String get rpNotTested => 'Not tested';

  @override
  String get rpTest => 'Test';

  @override
  String get rpStatusReady => 'Ready';

  @override
  String get rpStatusCheck => 'Check';

  @override
  String get rpStatusFix => 'Fix first';

  @override
  String get rpStatusUnknown => 'Unknown';

  @override
  String get cdFixBluetooth => 'Turn on Bluetooth';

  @override
  String get cdFixPermission => 'Allow Bluetooth access';

  @override
  String get cdFixBattery => 'Open battery settings';

  @override
  String get cdFixRetry => 'Try again';

  @override
  String get cdFixScan => 'Scan for radios';

  @override
  String get cdFixFirmware => 'How to update';

  @override
  String get cdTheRadio => 'the radio';

  @override
  String get cdYourRadio => 'your radio';

  @override
  String get cdBluetoothOffDetail =>
      'Bluetooth is off. Turn it on and the app reconnects by itself.';

  @override
  String get cdPermissionDetail =>
      'The app isn\'t allowed to use Bluetooth. Allow \"Nearby devices\" when asked, or in Android Settings → Apps → NOTORYX Connect → Permissions.';

  @override
  String cdPairedDetail(String name) {
    return '$name may be connected to another phone or app. A radio talks to one phone at a time: close the other app or turn off Bluetooth on the other phone, then try again. If it keeps failing, forget the radio in Android Bluetooth settings and pair again.';
  }

  @override
  String cdTimeoutDetail(String name) {
    return '$name didn\'t answer in time. Move closer, check it\'s switched on, or restart it, then try again.';
  }

  @override
  String get cdNetworkDetail =>
      'Couldn\'t reach the radio over the network. Check the phone and radio are on the same Wi-Fi, and that the address and port (usually 4403) are right.';

  @override
  String get cdUsbDetail =>
      'The USB link failed. Unplug and plug the cable back in, and allow USB access when Android asks.';

  @override
  String cdGaveUpDetail(String name) {
    return 'The link dropped and reconnecting didn\'t work. Check $name is on and in range, then try again.';
  }

  @override
  String get cdNotMeshtasticDetail =>
      'The device answered but doesn\'t look like a Meshtastic radio, or its firmware is too old.';

  @override
  String get cdUnknownProblem => 'Unknown problem.';

  @override
  String get cdBluetooth => 'Bluetooth';

  @override
  String get cdOn => 'On.';

  @override
  String get cdBluetoothOff => 'Bluetooth is off.';

  @override
  String get cdCouldntCheck => 'Couldn\'t check.';

  @override
  String get cdAccess => 'Bluetooth access';

  @override
  String get cdAllowed => 'Allowed.';

  @override
  String get cdNotAllowed =>
      'The app isn\'t allowed to find and connect to radios.';

  @override
  String get cdLink => 'Radio link';

  @override
  String cdConnectedTo(String name) {
    return 'Connected to $name.';
  }

  @override
  String cdConnectingTo(String name) {
    return 'Connecting to $name…';
  }

  @override
  String get cdNoneFound =>
      'No radios found. Check the radio is on and within a few metres, that Bluetooth is enabled in its settings, and that it isn\'t connected to another phone.';

  @override
  String get cdNotConnected => 'Not connected.';

  @override
  String get cdBackground => 'Background';

  @override
  String get cdBatteryOptimised =>
      'Battery optimisation can cut the radio link when the screen is off. Set NOTORYX Connect to \"Unrestricted\".';

  @override
  String get cdBackgroundOk => 'The link can stay open with the screen off.';

  @override
  String get cdFirmware => 'Firmware';

  @override
  String get cdFirmwareTooOld => 'Firmware too old.';

  @override
  String get cdSupported => 'Supported.';

  @override
  String get cpFlasherCopied =>
      'Copied flasher.meshtastic.org. Open it on a computer with the radio plugged in.';

  @override
  String cpFixFailed(String error) {
    return 'That didn\'t work: $error';
  }

  @override
  String get cpReportCopied =>
      'Report copied. It holds connection details only: no messages, keys or positions.';

  @override
  String get cpTitle => 'Connection doctor';

  @override
  String get cpChecking => 'Checking…';

  @override
  String get cpNoProblems => 'No problems found';

  @override
  String cpProblems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count problems found',
      one: '1 problem found',
    );
    return '$_temp0';
  }

  @override
  String get cpStillFails =>
      'If the radio still won\'t connect, copy the report below and share it.';

  @override
  String get cpFixFirst => 'Fix the first problem, then check again.';

  @override
  String get cpCheckAgain => 'Check again';

  @override
  String get cpCopyReport => 'Copy report';

  @override
  String get cpRecentEvents => 'Recent connection events';

  @override
  String get cpNoEvents =>
      'Nothing yet. Events appear here as the app connects.';

  @override
  String get cpOk => 'OK';

  @override
  String get cpProblem => 'Problem';

  @override
  String get cpUnknown => 'Unknown';

  @override
  String get sntTitle => 'Community moderation';

  @override
  String get sntToolSubtitle =>
      'Report spam to NOTORYX moderators and see flagged nodes';

  @override
  String get sntIntro =>
      'Reports go to NOTORYX moderators, who review each one by hand. Approved bans come back as an advisory list: flagged nodes get a label, and nothing on the mesh is blocked.';

  @override
  String get sntEnable => 'Use community moderation';

  @override
  String get sntEnableSub =>
      'Off by default. While it is off, NOTORYX never contacts the moderation service.';

  @override
  String get sntHide => 'Hide messages from flagged senders';

  @override
  String get sntHideSub =>
      'Channel messages only. You can turn this off at any time.';

  @override
  String sntSynced(String time) {
    return 'Ban list updated $time';
  }

  @override
  String get sntNeverSynced => 'Ban list not downloaded yet';

  @override
  String sntFlaggedCount(int count) {
    return 'Flagged nodes: $count';
  }

  @override
  String sntQueued(int count) {
    return 'Reports waiting to send: $count';
  }

  @override
  String get sntRefresh => 'Update now';

  @override
  String get sntYourNode => 'Your node';

  @override
  String get sntYourNodeClear => 'Your node is not flagged.';

  @override
  String sntYourNodeFlagged(String caseRef) {
    return 'Your node is flagged (case $caseRef). If this is a mistake, you can appeal.';
  }

  @override
  String get sntYourNodeUnknown => 'Connect a radio to check your node.';

  @override
  String get sntAppealPending => 'Your appeal is being reviewed.';

  @override
  String get sntAppeal => 'Appeal';

  @override
  String get sntAppealOther => 'Appeal a case by number';

  @override
  String get sntYourReports => 'Your recent reports';

  @override
  String get sntReport => 'Report to moderators';

  @override
  String sntReportTitle(String name) {
    return 'Report $name';
  }

  @override
  String get sntReasonSpam => 'Spam or advertising';

  @override
  String get sntReasonFlooding => 'Flooding the mesh';

  @override
  String get sntReasonAbuse => 'Harassment or abuse';

  @override
  String get sntReasonImpersonation => 'Impersonation';

  @override
  String get sntReasonOther => 'Other';

  @override
  String get sntNote => 'Details (optional)';

  @override
  String get sntIncludeMessage => 'Include this message';

  @override
  String get sntSends =>
      'Sends the node\'s ID and name, your reason and, if ticked, this message. Not your name, key or location.';

  @override
  String get sntSend => 'Send report';

  @override
  String sntSent(String caseRef) {
    return 'Report sent ($caseRef)';
  }

  @override
  String get sntQueuedOne => 'No connection. The report will be sent later.';

  @override
  String sntRejected(String message) {
    return 'Report not accepted: $message';
  }

  @override
  String get sntOffPrompt => 'Turn on community moderation?';

  @override
  String get sntTurnOn => 'Turn on';

  @override
  String get sntFlagged => 'Flagged';

  @override
  String sntFlaggedHint(String caseRef) {
    return 'Flagged by NOTORYX moderators (case $caseRef). Advisory only.';
  }

  @override
  String get sntCaseRef => 'Case number (SNT-1234)';

  @override
  String get sntStatement => 'Why should the ban be lifted?';

  @override
  String get sntContact => 'Contact (optional, only moderators see it)';

  @override
  String get sntAppealSend => 'Send appeal';

  @override
  String get sntAppealReceived => 'Appeal sent. A moderator will review it.';

  @override
  String get sntAppealUnknown => 'No Meshtastic case has that number.';

  @override
  String get sntAppealNotOpen =>
      'That case has no active ban, or an appeal is already waiting.';

  @override
  String get sntAppealTooMany => 'Too many appeals. Try again in a minute.';

  @override
  String get sntFailed =>
      'Couldn\'t reach the moderation service. Try again later.';

  @override
  String get pvSent7 =>
      'Reports, appeals and ban-list checks to NOTORYX moderators through sentinel-relay.meshmayhem.org, only if you turn on Community moderation';

  @override
  String get psTitle => 'Find a place';

  @override
  String get psHint => 'Node, waypoint or place name';

  @override
  String get psNoLocal => 'No nodes or waypoints match. Try searching online.';

  @override
  String get psOnlineNote =>
      'Searching online sends what you typed to OpenStreetMap\'s Nominatim service, which also sees your IP address. It needs internet access.';

  @override
  String get psSearchOnline => 'Search online';

  @override
  String get psTooSoon => 'Wait a second before searching online again.';

  @override
  String get psOnlineFailed =>
      'Couldn\'t search online. Check the phone has internet access and try again.';

  @override
  String get psNoOnline => 'No places found online.';

  @override
  String get psAttribution => 'Place data © OpenStreetMap contributors';

  @override
  String get psKindNode => 'Node';

  @override
  String get psKindWaypoint => 'Waypoint';

  @override
  String get psKindOnline => 'Place';

  @override
  String get mapFindPlace => 'Find a place';

  @override
  String mapFoundPin(String name) {
    return 'Found: $name';
  }

  @override
  String get pvSent8 =>
      'What you type into Find a place, to OpenStreetMap\'s Nominatim service, only when you press Search online; it sees your IP address';

  @override
  String get takReceiveTitle => 'From ATAK';

  @override
  String get takReceiveIntro =>
      'Shows markers that ATAK on this phone shares, such as team members and map points, on this app\'s map. They stay on this phone and are never sent over the mesh.';

  @override
  String get takReceiveSwitch => 'Show ATAK markers on the map';

  @override
  String get takReceivePort => 'UDP port to listen on';

  @override
  String takReceiveStatus(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Showing $count markers',
      one: 'Showing $count marker',
      zero: 'Listening. No markers yet.',
    );
    return '$_temp0';
  }

  @override
  String takReceiveProblem(String error) {
    return 'Could not listen: $error';
  }

  @override
  String get takReceiveHowTo =>
      'In ATAK, open Settings, then Network Preferences, then Manage Outputs, and add a UDP output to 127.0.0.1 on this port. Markers disappear when ATAK says they are stale.';

  @override
  String get takClear => 'Clear markers';

  @override
  String get takFriendly => 'Friendly';

  @override
  String get takHostile => 'Hostile';

  @override
  String get takNeutral => 'Neutral';

  @override
  String get takUnknown => 'Unknown';

  @override
  String get takPoint => 'Map point';

  @override
  String mapTakPin(String kind, String callsign) {
    return 'ATAK $kind: $callsign';
  }

  @override
  String mapTakUpdated(String time, String stale) {
    return 'From ATAK, updated $time. Shown until $stale.';
  }

  @override
  String get takSamePort =>
      'Use a different port from the one positions are sent to.';

  @override
  String get nodesFavoritesOnly => 'Favorites only';

  @override
  String get nodesNoFavorites => 'No favorites yet';

  @override
  String get nodesNoFavoritesHint =>
      'Open a node and tap its star to trust it. Favorites only then shows just the people you trust.';

  @override
  String get mapShowAllNodes => 'Show all nodes';

  @override
  String get topologyTitle => 'Network diagram';

  @override
  String get topologyEmpty =>
      'Nothing to draw yet. Nodes appear once your radio knows how many hops away they are, or a node sends Neighbor Info.';

  @override
  String get topologyHint =>
      'Your radio is in the middle and each ring is one more hop. Lines are links from Neighbor Info reports (bolder = better signal) and nodes your radio hears directly. Tap a dot to open the node.';

  @override
  String get topologyNoReports =>
      'No Neighbor Info reports yet, so only nodes heard directly have lines. Turn on the Neighbor Info module on your radios to see more links.';

  @override
  String topologyRing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hops away',
      one: '1 hop away',
      zero: 'Heard directly',
    );
    return '$_temp0';
  }

  @override
  String topologyLinks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count links',
      one: '1 link',
    );
    return '$_temp0';
  }

  @override
  String topologySemantics(int count, int rings) {
    return 'Network diagram: $count nodes on $rings rings around your radio.';
  }

  @override
  String get mapRouteWatchTitle => 'Off-route alert';

  @override
  String get mapRouteWatchLimit => 'Alert when someone is farther than';

  @override
  String get mapRouteWatchWho => 'Watch';

  @override
  String get mapRouteWatchHint =>
      'Each watched person who has been on the route alerts once when they go past the limit, and again only after coming back. The alert keeps working after the route\'s waypoints expire. One route at a time.';

  @override
  String get mapRouteWatchStart => 'Watch';

  @override
  String get mapRouteWatchStop => 'Stop';

  @override
  String mapRouteWatching(String name, String distance) {
    return 'Watching $name • alert past $distance';
  }
}
