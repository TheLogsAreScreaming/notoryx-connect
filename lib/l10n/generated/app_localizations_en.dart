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
    return 'Its messages, offline queue, NodeDex history, trails and telemetry history move to $to. Whatever $to already has is kept, so nothing is overwritten. $id then no longer has an entry of its own.\n\nTo be safe, make a phone data backup first.';
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
}
