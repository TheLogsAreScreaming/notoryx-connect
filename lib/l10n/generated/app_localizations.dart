import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabNodes.
  ///
  /// In en, this message translates to:
  /// **'Nodes'**
  String get tabNodes;

  /// No description provided for @tabChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get tabChats;

  /// No description provided for @tabMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get tabMap;

  /// No description provided for @tabTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tabTools;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @connOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get connOffline;

  /// No description provided for @connScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get connScanning;

  /// No description provided for @connConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get connConnecting;

  /// No description provided for @connSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get connSyncing;

  /// No description provided for @connConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connConnected;

  /// No description provided for @connError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get connError;

  /// No description provided for @radioStatus.
  ///
  /// In en, this message translates to:
  /// **'Radio: {status}'**
  String radioStatus(String status);

  /// No description provided for @radioStatusTip.
  ///
  /// In en, this message translates to:
  /// **'Radio: {status}. Tap to manage.'**
  String radioStatusTip(String status);

  /// No description provided for @radioStatusHint.
  ///
  /// In en, this message translates to:
  /// **'manage the radio'**
  String get radioStatusHint;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// No description provided for @toolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Utilities for planning, testing and running a deployment.'**
  String get toolsSubtitle;

  /// No description provided for @toolsDoctor.
  ///
  /// In en, this message translates to:
  /// **'Connection doctor'**
  String get toolsDoctor;

  /// No description provided for @toolsDoctorSub.
  ///
  /// In en, this message translates to:
  /// **'Find out why a radio won\'t connect or keeps dropping'**
  String get toolsDoctorSub;

  /// No description provided for @toolsBeforeYouGo.
  ///
  /// In en, this message translates to:
  /// **'Before you go'**
  String get toolsBeforeYouGo;

  /// No description provided for @toolsChecklist.
  ///
  /// In en, this message translates to:
  /// **'Deployment checklist'**
  String get toolsChecklist;

  /// No description provided for @toolsBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery runtime'**
  String get toolsBattery;

  /// No description provided for @toolsBatterySub.
  ///
  /// In en, this message translates to:
  /// **'Estimate hours from capacity and average draw'**
  String get toolsBatterySub;

  /// No description provided for @toolsCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get toolsCalculate;

  /// No description provided for @toolsMeshTools.
  ///
  /// In en, this message translates to:
  /// **'Mesh tools'**
  String get toolsMeshTools;

  /// No description provided for @toolsHealth.
  ///
  /// In en, this message translates to:
  /// **'Mesh health & airtime'**
  String get toolsHealth;

  /// No description provided for @toolsHealthSub.
  ///
  /// In en, this message translates to:
  /// **'How busy the channel is and how much your radio transmits'**
  String get toolsHealthSub;

  /// No description provided for @toolsLink.
  ///
  /// In en, this message translates to:
  /// **'Link planner'**
  String get toolsLink;

  /// No description provided for @toolsLinkSub.
  ///
  /// In en, this message translates to:
  /// **'Check line of sight between two nodes over the terrain'**
  String get toolsLinkSub;

  /// No description provided for @toolsRange.
  ///
  /// In en, this message translates to:
  /// **'Range test'**
  String get toolsRange;

  /// No description provided for @toolsRangeSub.
  ///
  /// In en, this message translates to:
  /// **'Log packets from a range test sender with signal and distance'**
  String get toolsRangeSub;

  /// No description provided for @toolsTraceroute.
  ///
  /// In en, this message translates to:
  /// **'Traceroute'**
  String get toolsTraceroute;

  /// No description provided for @toolsStore.
  ///
  /// In en, this message translates to:
  /// **'Store & forward'**
  String get toolsStore;

  /// No description provided for @toolsStoreSub.
  ///
  /// In en, this message translates to:
  /// **'Replay messages you missed from a router'**
  String get toolsStoreSub;

  /// No description provided for @toolsBeacons.
  ///
  /// In en, this message translates to:
  /// **'Mesh beacons'**
  String get toolsBeacons;

  /// No description provided for @toolsRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get toolsRecords;

  /// No description provided for @toolsIncident.
  ///
  /// In en, this message translates to:
  /// **'Incident log, templates & coverage'**
  String get toolsIncident;

  /// No description provided for @toolsIncidentSub.
  ///
  /// In en, this message translates to:
  /// **'Saved field records and exports'**
  String get toolsIncidentSub;

  /// No description provided for @toolsSignal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get toolsSignal;

  /// No description provided for @toolsTelemetry.
  ///
  /// In en, this message translates to:
  /// **'Live telemetry'**
  String get toolsTelemetry;

  /// No description provided for @toolsNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing received yet. Metrics appear when nodes send them.'**
  String get toolsNothingYet;

  /// No description provided for @toolsGuide.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth signal guide'**
  String get toolsGuide;

  /// No description provided for @toolsGuideSub.
  ///
  /// In en, this message translates to:
  /// **'What the signal numbers (RSSI) mean'**
  String get toolsGuideSub;

  /// No description provided for @toolsScan.
  ///
  /// In en, this message translates to:
  /// **'Scan for radios'**
  String get toolsScan;

  /// No description provided for @toolsCheck0.
  ///
  /// In en, this message translates to:
  /// **'Radio charged'**
  String get toolsCheck0;

  /// No description provided for @toolsCheck1.
  ///
  /// In en, this message translates to:
  /// **'Antenna attached'**
  String get toolsCheck1;

  /// No description provided for @toolsCheck2.
  ///
  /// In en, this message translates to:
  /// **'Region configured'**
  String get toolsCheck2;

  /// No description provided for @toolsCheck3.
  ///
  /// In en, this message translates to:
  /// **'Primary channel verified'**
  String get toolsCheck3;

  /// No description provided for @toolsCheck4.
  ///
  /// In en, this message translates to:
  /// **'GPS / position policy checked'**
  String get toolsCheck4;

  /// No description provided for @toolsReady.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} ready'**
  String toolsReady(int done, int total);

  /// No description provided for @toolsBatteryField.
  ///
  /// In en, this message translates to:
  /// **'Battery (mAh)'**
  String get toolsBatteryField;

  /// No description provided for @toolsDrawField.
  ///
  /// In en, this message translates to:
  /// **'Average draw (mA)'**
  String get toolsDrawField;

  /// No description provided for @toolsAboutHours.
  ///
  /// In en, this message translates to:
  /// **'About {hours} hours'**
  String toolsAboutHours(String hours);

  /// No description provided for @toolsTraceReady.
  ///
  /// In en, this message translates to:
  /// **'Show the relay path to a node and back'**
  String get toolsTraceReady;

  /// No description provided for @toolsTraceOff.
  ///
  /// In en, this message translates to:
  /// **'Connect to a radio to trace routes'**
  String get toolsTraceOff;

  /// No description provided for @toolsBeaconsSub.
  ///
  /// In en, this message translates to:
  /// **'Hear mesh invitations nearby and send your own'**
  String get toolsBeaconsSub;

  /// No description provided for @toolsBeaconsHeard.
  ///
  /// In en, this message translates to:
  /// **'{count} heard • send your own'**
  String toolsBeaconsHeard(int count);

  /// No description provided for @toolsReporting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} node reporting device metrics} other{{count} nodes reporting device metrics}}'**
  String toolsReporting(int count);

  /// No description provided for @toolsTelemetryOff.
  ///
  /// In en, this message translates to:
  /// **'Connect to a radio to receive telemetry'**
  String get toolsTelemetryOff;

  /// No description provided for @toolsBatteryPct.
  ///
  /// In en, this message translates to:
  /// **'Battery {pct}%'**
  String toolsBatteryPct(int pct);

  /// No description provided for @toolsChannelBusy.
  ///
  /// In en, this message translates to:
  /// **'Channel busy {pct}%'**
  String toolsChannelBusy(String pct);

  /// No description provided for @toolsTransmitting.
  ///
  /// In en, this message translates to:
  /// **'Transmitting {pct}%'**
  String toolsTransmitting(String pct);

  /// No description provided for @toolsSigExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent, very close'**
  String get toolsSigExcellent;

  /// No description provided for @toolsSigStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get toolsSigStrong;

  /// No description provided for @toolsSigUsable.
  ///
  /// In en, this message translates to:
  /// **'Usable'**
  String get toolsSigUsable;

  /// No description provided for @toolsSigWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get toolsSigWeak;

  /// No description provided for @toolsSigVeryWeak.
  ///
  /// In en, this message translates to:
  /// **'Very weak, may drop'**
  String get toolsSigVeryWeak;

  /// No description provided for @toolsScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get toolsScanning;

  /// No description provided for @toolsFound.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} Bluetooth device found} other{{count} Bluetooth devices found}}'**
  String toolsFound(int count);

  /// No description provided for @deliveryReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get deliveryReceived;

  /// No description provided for @deliveryQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get deliveryQueued;

  /// No description provided for @deliverySent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get deliverySent;

  /// No description provided for @deliveryDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveryDelivered;

  /// No description provided for @deliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Not delivered'**
  String get deliveryFailed;

  /// No description provided for @hopsDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get hopsDirect;

  /// No description provided for @hopsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} hop} other{{count} hops}}'**
  String hopsCount(int count);

  /// No description provided for @chatsNoMention.
  ///
  /// In en, this message translates to:
  /// **'No nodes heard yet to mention.'**
  String get chatsNoMention;

  /// No description provided for @chatsMentionNode.
  ///
  /// In en, this message translates to:
  /// **'Mention a node'**
  String get chatsMentionNode;

  /// No description provided for @chatsViaMqttFull.
  ///
  /// In en, this message translates to:
  /// **'Arrived over MQTT (the internet), not over the air'**
  String get chatsViaMqttFull;

  /// No description provided for @chatsPathUnknown.
  ///
  /// In en, this message translates to:
  /// **'Path not reported by the sender\'s firmware'**
  String get chatsPathUnknown;

  /// No description provided for @chatsHeardDirect.
  ///
  /// In en, this message translates to:
  /// **'Heard directly, no relays'**
  String get chatsHeardDirect;

  /// No description provided for @chatsLastThrough.
  ///
  /// In en, this message translates to:
  /// **', last through {name}'**
  String chatsLastThrough(String name);

  /// No description provided for @chatsLastThroughEnding.
  ///
  /// In en, this message translates to:
  /// **', last through a node ending in {hex}'**
  String chatsLastThroughEnding(String hex);

  /// No description provided for @chatsCameThrough.
  ///
  /// In en, this message translates to:
  /// **'{hops, plural, one{Came through {hops} relay{via}} other{Came through {hops} relays{via}}}'**
  String chatsCameThrough(int hops, String via);

  /// No description provided for @chatsReact.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get chatsReact;

  /// No description provided for @chatsReactEmoji.
  ///
  /// In en, this message translates to:
  /// **'React {emoji}'**
  String chatsReactEmoji(String emoji);

  /// No description provided for @chatsNoSignal.
  ///
  /// In en, this message translates to:
  /// **'No signal reading'**
  String get chatsNoSignal;

  /// No description provided for @chatsUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get chatsUnpin;

  /// No description provided for @chatsPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get chatsPin;

  /// No description provided for @chatsCopyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get chatsCopyText;

  /// No description provided for @chatsCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get chatsCopied;

  /// No description provided for @chatsReactionFailed.
  ///
  /// In en, this message translates to:
  /// **'Reaction not sent: {error}'**
  String chatsReactionFailed(String error);

  /// No description provided for @chatsSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Message not sent: {error}'**
  String chatsSendFailed(String error);

  /// No description provided for @chatsYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatsYou;

  /// No description provided for @chatsYouLower.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get chatsYouLower;

  /// No description provided for @chatsChannelN.
  ///
  /// In en, this message translates to:
  /// **'Channel {n}'**
  String chatsChannelN(int n);

  /// No description provided for @chatsReactHint.
  ///
  /// In en, this message translates to:
  /// **'react to this message'**
  String get chatsReactHint;

  /// No description provided for @chatsViaMqtt.
  ///
  /// In en, this message translates to:
  /// **'via MQTT'**
  String get chatsViaMqtt;

  /// No description provided for @chatsPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get chatsPinned;

  /// No description provided for @chatsMentionsYou.
  ///
  /// In en, this message translates to:
  /// **'Mentions you'**
  String get chatsMentionsYou;

  /// No description provided for @chatsReactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions: {list}'**
  String chatsReactions(String list);

  /// No description provided for @chatsReactionFrom.
  ///
  /// In en, this message translates to:
  /// **'{emoji} from {name}'**
  String chatsReactionFrom(String emoji, String name);

  /// No description provided for @chatsConnectedSub.
  ///
  /// In en, this message translates to:
  /// **'Connected. Messages send right away.'**
  String get chatsConnectedSub;

  /// No description provided for @chatsOfflineSub.
  ///
  /// In en, this message translates to:
  /// **'Offline. Messages wait in a queue and send when your radio connects.'**
  String get chatsOfflineSub;

  /// No description provided for @chatsStorageProblem.
  ///
  /// In en, this message translates to:
  /// **'Message storage problem'**
  String get chatsStorageProblem;

  /// No description provided for @chatsFilterShowing.
  ///
  /// In en, this message translates to:
  /// **'Showing messages that match your word filters'**
  String get chatsFilterShowing;

  /// No description provided for @chatsFilterHidden.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} message hidden by your word filters} other{{count} messages hidden by your word filters}}'**
  String chatsFilterHidden(int count);

  /// No description provided for @chatsHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get chatsHide;

  /// No description provided for @chatsShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get chatsShow;

  /// No description provided for @chatsStatLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get chatsStatLink;

  /// No description provided for @chatsOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get chatsOnline;

  /// No description provided for @chatsStatMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatsStatMessages;

  /// No description provided for @chatsStatQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get chatsStatQueued;

  /// No description provided for @chatsNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get chatsNewMessage;

  /// No description provided for @chatsKeyChanged.
  ///
  /// In en, this message translates to:
  /// **'Security key changed'**
  String get chatsKeyChanged;

  /// No description provided for @chatsKeyChangedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} now shows a different key. Check with its owner before sending anything private. Open the node to review or trust the new key.'**
  String chatsKeyChangedBody(String name);

  /// No description provided for @chatsTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get chatsTo;

  /// No description provided for @chatsEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone on the channel'**
  String get chatsEveryone;

  /// No description provided for @chatsDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct • {name}'**
  String chatsDirect(String name);

  /// No description provided for @chatsChannelLabel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get chatsChannelLabel;

  /// No description provided for @chatsChannelBroadcast.
  ///
  /// In en, this message translates to:
  /// **'Channel 0 • Broadcast'**
  String get chatsChannelBroadcast;

  /// No description provided for @chatsChannelOffline.
  ///
  /// In en, this message translates to:
  /// **'Channel {n} • Offline'**
  String chatsChannelOffline(int n);

  /// No description provided for @chatsChannelNamed.
  ///
  /// In en, this message translates to:
  /// **'Channel {n} • {name}'**
  String chatsChannelNamed(int n, String name);

  /// No description provided for @chatsDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get chatsDefault;

  /// No description provided for @chatsMessageChannel.
  ///
  /// In en, this message translates to:
  /// **'Message Channel {n}'**
  String chatsMessageChannel(int n);

  /// No description provided for @chatsMessageNode.
  ///
  /// In en, this message translates to:
  /// **'Message {name}'**
  String chatsMessageNode(String name);

  /// No description provided for @chatsSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatsSend;

  /// No description provided for @chatsQuickReplies.
  ///
  /// In en, this message translates to:
  /// **'Quick replies'**
  String get chatsQuickReplies;

  /// No description provided for @chatsMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatsMessages;

  /// No description provided for @chatsHoldHint.
  ///
  /// In en, this message translates to:
  /// **'Hold a message for more'**
  String get chatsHoldHint;

  /// No description provided for @chatsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search message history'**
  String get chatsSearch;

  /// No description provided for @chatsClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get chatsClearSearch;

  /// No description provided for @chatsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get chatsNoMatches;

  /// No description provided for @chatsNoMatchesBody.
  ///
  /// In en, this message translates to:
  /// **'No messages match your search.'**
  String get chatsNoMatchesBody;

  /// No description provided for @chatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No mesh messages yet'**
  String get chatsEmpty;

  /// No description provided for @chatsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Channel and direct messages appear here once your radio hears them.'**
  String get chatsEmptyBody;

  /// No description provided for @chatsNewAbove.
  ///
  /// In en, this message translates to:
  /// **'New messages above'**
  String get chatsNewAbove;

  /// No description provided for @chatsAutoReplies.
  ///
  /// In en, this message translates to:
  /// **'Automatic replies'**
  String get chatsAutoReplies;

  /// No description provided for @chatsBot.
  ///
  /// In en, this message translates to:
  /// **'Bot mode'**
  String get chatsBot;

  /// No description provided for @chatsBotOn.
  ///
  /// In en, this message translates to:
  /// **'On. Replies to direct messages and answers !help and !status, within quiet hours and airtime limits.'**
  String get chatsBotOn;

  /// No description provided for @chatsBotOff.
  ///
  /// In en, this message translates to:
  /// **'Off. No automatic replies are sent.'**
  String get chatsBotOff;

  /// No description provided for @chatsBotReply.
  ///
  /// In en, this message translates to:
  /// **'Bot reply message'**
  String get chatsBotReply;

  /// No description provided for @chatsBotReplyField.
  ///
  /// In en, this message translates to:
  /// **'Message to send while Bot mode is on'**
  String get chatsBotReplyField;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get commonConnect;

  /// No description provided for @commonDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get commonDisconnect;

  /// No description provided for @agoNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get agoNow;

  /// No description provided for @agoMin.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String agoMin(int n);

  /// No description provided for @agoHours.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String agoHours(int n);

  /// No description provided for @agoDays.
  ///
  /// In en, this message translates to:
  /// **'{n} d ago'**
  String agoDays(int n);

  /// No description provided for @rssiStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong Bluetooth signal'**
  String get rssiStrong;

  /// No description provided for @rssiUsable.
  ///
  /// In en, this message translates to:
  /// **'Usable Bluetooth signal'**
  String get rssiUsable;

  /// No description provided for @rssiWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak Bluetooth signal'**
  String get rssiWeak;

  /// No description provided for @rssiVeryWeak.
  ///
  /// In en, this message translates to:
  /// **'Very weak Bluetooth signal'**
  String get rssiVeryWeak;

  /// No description provided for @heardAny.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get heardAny;

  /// No description provided for @heardHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get heardHour;

  /// No description provided for @heardDay.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get heardDay;

  /// No description provided for @heardWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get heardWeek;

  /// No description provided for @nodesConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect: {error}'**
  String nodesConnectFailed(String error);

  /// No description provided for @nodesUsbFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect over USB: {error}'**
  String nodesUsbFailed(String error);

  /// No description provided for @nodesNotesFor.
  ///
  /// In en, this message translates to:
  /// **'Notes for {name}'**
  String nodesNotesFor(String name);

  /// No description provided for @nodesNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Location, antenna, observations…'**
  String get nodesNotesHint;

  /// No description provided for @nodesConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {name}.'**
  String nodesConnectedTo(String name);

  /// No description provided for @nodesYourRadio.
  ///
  /// In en, this message translates to:
  /// **'your radio'**
  String get nodesYourRadio;

  /// No description provided for @nodesFindRadio.
  ///
  /// In en, this message translates to:
  /// **'Find your radio nearby and connect over Bluetooth.'**
  String get nodesFindRadio;

  /// No description provided for @nodesRadiosFound.
  ///
  /// In en, this message translates to:
  /// **'Radios found'**
  String get nodesRadiosFound;

  /// No description provided for @nodesMeshNodes.
  ///
  /// In en, this message translates to:
  /// **'Mesh nodes'**
  String get nodesMeshNodes;

  /// No description provided for @nodesStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get nodesStatus;

  /// No description provided for @nodesConnProblem.
  ///
  /// In en, this message translates to:
  /// **'Connection problem'**
  String get nodesConnProblem;

  /// No description provided for @nodesDiagnose.
  ///
  /// In en, this message translates to:
  /// **'Diagnose'**
  String get nodesDiagnose;

  /// No description provided for @nodesNearby.
  ///
  /// In en, this message translates to:
  /// **'Radios nearby'**
  String get nodesNearby;

  /// No description provided for @nodesLooking.
  ///
  /// In en, this message translates to:
  /// **'Looking for radios…'**
  String get nodesLooking;

  /// No description provided for @nodesStopScan.
  ///
  /// In en, this message translates to:
  /// **'Stop scan'**
  String get nodesStopScan;

  /// No description provided for @nodesRadio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get nodesRadio;

  /// No description provided for @nodesOverUsb.
  ///
  /// In en, this message translates to:
  /// **'Over USB'**
  String get nodesOverUsb;

  /// No description provided for @nodesOverWifi.
  ///
  /// In en, this message translates to:
  /// **'Over Wi-Fi'**
  String get nodesOverWifi;

  /// No description provided for @nodesConnectWifi.
  ///
  /// In en, this message translates to:
  /// **'Connect over Wi-Fi'**
  String get nodesConnectWifi;

  /// No description provided for @nodesConnectUsb.
  ///
  /// In en, this message translates to:
  /// **'Connect over USB'**
  String get nodesConnectUsb;

  /// No description provided for @nodesNoRadios.
  ///
  /// In en, this message translates to:
  /// **'No radios found yet'**
  String get nodesNoRadios;

  /// No description provided for @nodesNoRadiosBody.
  ///
  /// In en, this message translates to:
  /// **'Turn your radio on, keep it close, then tap Scan for radios.'**
  String get nodesNoRadiosBody;

  /// No description provided for @nodesTryDemo.
  ///
  /// In en, this message translates to:
  /// **'No radio? Try the demo'**
  String get nodesTryDemo;

  /// No description provided for @nodesMeshtasticRadio.
  ///
  /// In en, this message translates to:
  /// **'Meshtastic radio'**
  String get nodesMeshtasticRadio;

  /// No description provided for @nodesBluetoothDevice.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth device'**
  String get nodesBluetoothDevice;

  /// No description provided for @nodesCount.
  ///
  /// In en, this message translates to:
  /// **'Mesh nodes ({count})'**
  String nodesCount(int count);

  /// No description provided for @nodesCountOf.
  ///
  /// In en, this message translates to:
  /// **'Mesh nodes ({shown} of {total})'**
  String nodesCountOf(int shown, int total);

  /// No description provided for @nodesNoneHeard.
  ///
  /// In en, this message translates to:
  /// **'No nodes heard in the last {window}'**
  String nodesNoneHeard(String window);

  /// No description provided for @nodesPickLonger.
  ///
  /// In en, this message translates to:
  /// **'Pick a longer time to see older nodes.'**
  String get nodesPickLonger;

  /// No description provided for @nodesShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all nodes'**
  String get nodesShowAll;

  /// No description provided for @nodesHealth.
  ///
  /// In en, this message translates to:
  /// **'Mesh health'**
  String get nodesHealth;

  /// No description provided for @nodesDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get nodesDetails;

  /// No description provided for @nodesKnown.
  ///
  /// In en, this message translates to:
  /// **'Known nodes'**
  String get nodesKnown;

  /// No description provided for @nodesWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting to send'**
  String get nodesWaiting;

  /// No description provided for @nodesSignalQuality.
  ///
  /// In en, this message translates to:
  /// **'Signal quality'**
  String get nodesSignalQuality;

  /// No description provided for @nodesSignalSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} messages heard • latest signal-to-noise {snr}'**
  String nodesSignalSummary(int count, String snr);

  /// No description provided for @nodesNotMeasured.
  ///
  /// In en, this message translates to:
  /// **'not yet measured'**
  String get nodesNotMeasured;

  /// No description provided for @nodesSignalHistory.
  ///
  /// In en, this message translates to:
  /// **'Signal history of the last {count} messages'**
  String nodesSignalHistory(int count);

  /// No description provided for @nodesSignalStarts.
  ///
  /// In en, this message translates to:
  /// **'Signal history starts when another node sends a message.'**
  String get nodesSignalStarts;

  /// No description provided for @nodesMeasuredFrom.
  ///
  /// In en, this message translates to:
  /// **'Measured from received text messages only.'**
  String get nodesMeasuredFrom;

  /// No description provided for @nodesEncounters.
  ///
  /// In en, this message translates to:
  /// **'Saved encounters'**
  String get nodesEncounters;

  /// No description provided for @nodesSeen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Seen {count} time • last {when}} other{Seen {count} times • last {when}}}'**
  String nodesSeen(int count, String when);

  /// No description provided for @nodesTapNotes.
  ///
  /// In en, this message translates to:
  /// **'Tap to add notes'**
  String get nodesTapNotes;

  /// No description provided for @nodesRemoveFav.
  ///
  /// In en, this message translates to:
  /// **'Remove favorite'**
  String get nodesRemoveFav;

  /// No description provided for @nodesAddFav.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get nodesAddFav;

  /// No description provided for @nodesMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get nodesMore;

  /// No description provided for @nodesFieldTools.
  ///
  /// In en, this message translates to:
  /// **'Field tools'**
  String get nodesFieldTools;

  /// No description provided for @nodesFieldToolsSub.
  ///
  /// In en, this message translates to:
  /// **'Signal reference, checklists, backups and more'**
  String get nodesFieldToolsSub;

  /// No description provided for @nodesReadyBanner.
  ///
  /// In en, this message translates to:
  /// **'Your radio is connected. Nodes update live as they are heard.'**
  String get nodesReadyBanner;

  /// No description provided for @nodesHelpBanner.
  ///
  /// In en, this message translates to:
  /// **'Tap Scan for radios, then Connect. The app checks it is a Meshtastic radio and downloads its node list before it is ready to use.'**
  String get nodesHelpBanner;

  /// No description provided for @nodesHeardWithin.
  ///
  /// In en, this message translates to:
  /// **'Show nodes heard within'**
  String get nodesHeardWithin;

  /// No description provided for @nodesWifiHelp.
  ///
  /// In en, this message translates to:
  /// **'For radios with Wi-Fi or Ethernet turned on. Your phone must be on the same network.'**
  String get nodesWifiHelp;

  /// No description provided for @nodesAddress.
  ///
  /// In en, this message translates to:
  /// **'Radio address'**
  String get nodesAddress;

  /// No description provided for @nodesAddressHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 192.168.1.42 or meshtastic.local'**
  String get nodesAddressHint;

  /// No description provided for @nodesPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get nodesPort;

  /// No description provided for @nodesPortHelp.
  ///
  /// In en, this message translates to:
  /// **'Meshtastic uses 4403'**
  String get nodesPortHelp;

  /// No description provided for @nodesUsbHelp.
  ///
  /// In en, this message translates to:
  /// **'Plug the radio into the phone with a USB data cable (an OTG adapter may be needed). Android asks for permission the first time.'**
  String get nodesUsbHelp;

  /// No description provided for @nodesUsbListFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not list USB devices: {error}'**
  String nodesUsbListFailed(String error);

  /// No description provided for @nodesNoUsb.
  ///
  /// In en, this message translates to:
  /// **'No USB devices found'**
  String get nodesNoUsb;

  /// No description provided for @nodesNoUsbBody.
  ///
  /// In en, this message translates to:
  /// **'Check the cable carries data, not just power, then refresh.'**
  String get nodesNoUsbBody;

  /// No description provided for @nodesLikelyRadio.
  ///
  /// In en, this message translates to:
  /// **'Likely a radio • {chip}'**
  String nodesLikelyRadio(String chip);

  /// No description provided for @nodesOtherUsb.
  ///
  /// In en, this message translates to:
  /// **'Other USB device'**
  String get nodesOtherUsb;

  /// No description provided for @nodesRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get nodesRefresh;

  /// No description provided for @setRadioSec.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get setRadioSec;

  /// No description provided for @setRadioConfig.
  ///
  /// In en, this message translates to:
  /// **'Radio configuration'**
  String get setRadioConfig;

  /// No description provided for @setIdentity.
  ///
  /// In en, this message translates to:
  /// **'Node identity'**
  String get setIdentity;

  /// No description provided for @setChange.
  ///
  /// In en, this message translates to:
  /// **'Change radio settings'**
  String get setChange;

  /// No description provided for @setChangeSub.
  ///
  /// In en, this message translates to:
  /// **'Owner, LoRa, channels, device role and position'**
  String get setChangeSub;

  /// No description provided for @setDeviceLora.
  ///
  /// In en, this message translates to:
  /// **'Device & LoRa'**
  String get setDeviceLora;

  /// No description provided for @setChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get setChannels;

  /// No description provided for @setModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get setModules;

  /// No description provided for @setShareLoc.
  ///
  /// In en, this message translates to:
  /// **'Share phone location with mesh'**
  String get setShareLoc;

  /// No description provided for @setPrecision.
  ///
  /// In en, this message translates to:
  /// **'Location precision'**
  String get setPrecision;

  /// No description provided for @setPrecisionSub.
  ///
  /// In en, this message translates to:
  /// **'Rounded on this phone before it is sent'**
  String get setPrecisionSub;

  /// No description provided for @setLowPower.
  ///
  /// In en, this message translates to:
  /// **'Low-power field mode'**
  String get setLowPower;

  /// No description provided for @setApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get setApp;

  /// No description provided for @setWidget.
  ///
  /// In en, this message translates to:
  /// **'Show messages on the home-screen widget'**
  String get setWidget;

  /// No description provided for @setYourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get setYourData;

  /// No description provided for @setRadioBackup.
  ///
  /// In en, this message translates to:
  /// **'Encrypted radio backup'**
  String get setRadioBackup;

  /// No description provided for @setRadioBackupSub.
  ///
  /// In en, this message translates to:
  /// **'Save or restore settings and channel keys, protected by a password'**
  String get setRadioBackupSub;

  /// No description provided for @setPhoneBackup.
  ///
  /// In en, this message translates to:
  /// **'Phone data backup'**
  String get setPhoneBackup;

  /// No description provided for @setPhoneBackupSub.
  ///
  /// In en, this message translates to:
  /// **'Chats, nodes, waypoints, records and settings, for moving to a new phone'**
  String get setPhoneBackupSub;

  /// No description provided for @setPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get setPrivacy;

  /// No description provided for @setPrivacySub.
  ///
  /// In en, this message translates to:
  /// **'What is stored and sent; delete chat history or all phone data'**
  String get setPrivacySub;

  /// No description provided for @setDemo.
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get setDemo;

  /// No description provided for @setAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get setAbout;

  /// No description provided for @setLicenses.
  ///
  /// In en, this message translates to:
  /// **'Third-party licenses'**
  String get setLicenses;

  /// No description provided for @setReadAloud.
  ///
  /// In en, this message translates to:
  /// **'Read messages aloud'**
  String get setReadAloud;

  /// No description provided for @setReadSub.
  ///
  /// In en, this message translates to:
  /// **'Uses the phone\'s text-to-speech, including with the screen off'**
  String get setReadSub;

  /// No description provided for @setMqttTitle.
  ///
  /// In en, this message translates to:
  /// **'Carry MQTT through this phone'**
  String get setMqttTitle;

  /// No description provided for @setBackground.
  ///
  /// In en, this message translates to:
  /// **'Background connection'**
  String get setBackground;

  /// No description provided for @setOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get setOpenSettings;

  /// No description provided for @setOfflineTiles.
  ///
  /// In en, this message translates to:
  /// **'Offline map tiles'**
  String get setOfflineTiles;

  /// No description provided for @setClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get setClear;

  /// No description provided for @setAlerts.
  ///
  /// In en, this message translates to:
  /// **'Field alerts'**
  String get setAlerts;

  /// No description provided for @setAlertsSub.
  ///
  /// In en, this message translates to:
  /// **'Phone notifications only; nothing is sent over the mesh'**
  String get setAlertsSub;

  /// No description provided for @setLowBattery.
  ///
  /// In en, this message translates to:
  /// **'Low battery'**
  String get setLowBattery;

  /// No description provided for @setThreshold.
  ///
  /// In en, this message translates to:
  /// **'Battery threshold'**
  String get setThreshold;

  /// No description provided for @setNewNode.
  ///
  /// In en, this message translates to:
  /// **'New node'**
  String get setNewNode;

  /// No description provided for @setNewNodeSub.
  ///
  /// In en, this message translates to:
  /// **'Your radio hears a node for the first time'**
  String get setNewNodeSub;

  /// No description provided for @setFavQuiet.
  ///
  /// In en, this message translates to:
  /// **'Favorite goes quiet'**
  String get setFavQuiet;

  /// No description provided for @setMeshQuiet.
  ///
  /// In en, this message translates to:
  /// **'Mesh goes quiet'**
  String get setMeshQuiet;

  /// No description provided for @setMeshQuietSub.
  ///
  /// In en, this message translates to:
  /// **'Half or more of the nodes you were hearing stop being heard'**
  String get setMeshQuietSub;

  /// No description provided for @setQuietAfter.
  ///
  /// In en, this message translates to:
  /// **'Quiet after'**
  String get setQuietAfter;

  /// No description provided for @setRadioData.
  ///
  /// In en, this message translates to:
  /// **'Radio data'**
  String get setRadioData;

  /// No description provided for @setRadioDataSub.
  ///
  /// In en, this message translates to:
  /// **'Lost or replaced a radio? Move its messages, nodes and history to the new one'**
  String get setRadioDataSub;

  /// No description provided for @setMoveToConnected.
  ///
  /// In en, this message translates to:
  /// **'Move to connected'**
  String get setMoveToConnected;

  /// No description provided for @setDataUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Radio data could not be read.'**
  String get setDataUnreadable;

  /// No description provided for @setNoData.
  ///
  /// In en, this message translates to:
  /// **'No radio data on this phone yet.'**
  String get setNoData;

  /// No description provided for @setFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get setFilters;

  /// No description provided for @setFilterHelp.
  ///
  /// In en, this message translates to:
  /// **'Incoming messages with these words are hidden, not deleted.'**
  String get setFilterHelp;

  /// No description provided for @setShowFiltered.
  ///
  /// In en, this message translates to:
  /// **'Show filtered messages'**
  String get setShowFiltered;

  /// No description provided for @setIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored'**
  String get setIgnored;

  /// No description provided for @setUnignore.
  ///
  /// In en, this message translates to:
  /// **'Unignore'**
  String get setUnignore;

  /// No description provided for @setMuted.
  ///
  /// In en, this message translates to:
  /// **'Muted'**
  String get setMuted;

  /// No description provided for @setUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get setUnmute;

  /// No description provided for @setOffLoc.
  ///
  /// In en, this message translates to:
  /// **'Off. Your phone location is never sent.'**
  String get setOffLoc;

  /// No description provided for @setOnNoRadio.
  ///
  /// In en, this message translates to:
  /// **'On. Starts when a radio is connected.'**
  String get setOnNoRadio;

  /// No description provided for @setOnNoFix.
  ///
  /// In en, this message translates to:
  /// **'On. Waiting for a GPS fix.'**
  String get setOnNoFix;

  /// No description provided for @setOnSent.
  ///
  /// In en, this message translates to:
  /// **'On. Last sent {time}.'**
  String setOnSent(String time);

  /// No description provided for @setSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your radio, how the app behaves, and your data.'**
  String get setSubtitle;

  /// No description provided for @setCanChange.
  ///
  /// In en, this message translates to:
  /// **'Connected • settings can be changed'**
  String get setCanChange;

  /// No description provided for @setReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only: firmware {version} is older than {minimum}. Update at {url}.'**
  String setReadOnly(String version, String minimum, String url);

  /// No description provided for @setConnectToView.
  ///
  /// In en, this message translates to:
  /// **'Connect to a radio to view and change its settings'**
  String get setConnectToView;

  /// No description provided for @setWaitingNode.
  ///
  /// In en, this message translates to:
  /// **'Waiting for this radio\'s node information'**
  String get setWaitingNode;

  /// No description provided for @setNoLong.
  ///
  /// In en, this message translates to:
  /// **'No long name'**
  String get setNoLong;

  /// No description provided for @setNoShort.
  ///
  /// In en, this message translates to:
  /// **'No short name'**
  String get setNoShort;

  /// No description provided for @setNoId.
  ///
  /// In en, this message translates to:
  /// **'ID not reported'**
  String get setNoId;

  /// No description provided for @setConfigWait.
  ///
  /// In en, this message translates to:
  /// **'Not received yet ({count} configuration messages)'**
  String setConfigWait(int count);

  /// No description provided for @setChannelWait.
  ///
  /// In en, this message translates to:
  /// **'Not received yet ({count} channel messages)'**
  String setChannelWait(int count);

  /// No description provided for @setModulesSub.
  ///
  /// In en, this message translates to:
  /// **'{count} module messages received. Change them in radio settings.'**
  String setModulesSub(int count);

  /// No description provided for @setShareLocSub.
  ///
  /// In en, this message translates to:
  /// **'{status}\nUsed when the radio has no GPS of its own. Updates every 5 min, or sooner when you move.'**
  String setShareLocSub(String status);

  /// No description provided for @setPrecise.
  ///
  /// In en, this message translates to:
  /// **'Precise'**
  String get setPrecise;

  /// No description provided for @setAbout2.
  ///
  /// In en, this message translates to:
  /// **'About {distance}'**
  String setAbout2(String distance);

  /// No description provided for @setLowPowerSub.
  ///
  /// In en, this message translates to:
  /// **'Shared location uses balanced GPS and updates every 15 min, or after 200 m of movement. The radio link and coverage recording are unchanged.'**
  String get setLowPowerSub;

  /// No description provided for @setWidgetSub.
  ///
  /// In en, this message translates to:
  /// **'Off: the widget shows only how many messages are unread. On: it also shows the sender and text, which anyone holding the phone can see.'**
  String get setWidgetSub;

  /// No description provided for @setDemoSub.
  ///
  /// In en, this message translates to:
  /// **'Explore the app with a pretend radio and mesh. Nothing is sent, and your own messages and settings are left alone.'**
  String get setDemoSub;

  /// No description provided for @setDevBuild.
  ///
  /// In en, this message translates to:
  /// **'Development build • Independent mesh companion'**
  String get setDevBuild;

  /// No description provided for @setConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get setConnection;

  /// No description provided for @setConnectionSub.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth LE • Safety mode on: no unverified device is treated as a mesh node'**
  String get setConnectionSub;

  /// No description provided for @setTrademark.
  ///
  /// In en, this message translates to:
  /// **'Trademark & compatibility'**
  String get setTrademark;

  /// No description provided for @setDevWarning.
  ///
  /// In en, this message translates to:
  /// **'Do not rely on this development build as your only way to call for help.'**
  String get setDevWarning;

  /// No description provided for @setChannelsKept.
  ///
  /// In en, this message translates to:
  /// **'Channel messages kept'**
  String get setChannelsKept;

  /// No description provided for @setChannelsDeleted.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{Channel messages deleted after {days} day} other{Channel messages deleted after {days} days}}'**
  String setChannelsDeleted(int days);

  /// No description provided for @setNewestPer.
  ///
  /// In en, this message translates to:
  /// **'newest {count} per conversation'**
  String setNewestPer(String count);

  /// No description provided for @setReadOn.
  ///
  /// In en, this message translates to:
  /// **'read aloud on'**
  String get setReadOn;

  /// No description provided for @setDeleteOld.
  ///
  /// In en, this message translates to:
  /// **'Delete old channel messages'**
  String get setDeleteOld;

  /// No description provided for @setDirectKept.
  ///
  /// In en, this message translates to:
  /// **'Direct messages are always kept'**
  String get setDirectKept;

  /// No description provided for @setNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get setNever;

  /// No description provided for @setAfterDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{After {days} day} other{After {days} days}}'**
  String setAfterDays(int days);

  /// No description provided for @setHistory.
  ///
  /// In en, this message translates to:
  /// **'Message history'**
  String get setHistory;

  /// No description provided for @setHistoryHelp.
  ///
  /// In en, this message translates to:
  /// **'Per channel or direct conversation. A lower limit deletes older messages.'**
  String get setHistoryHelp;

  /// No description provided for @setKeepNewest.
  ///
  /// In en, this message translates to:
  /// **'Keep newest {count}'**
  String setKeepNewest(String count);

  /// No description provided for @setMqttOff.
  ///
  /// In en, this message translates to:
  /// **'Off. Uses your phone\'s data when on.'**
  String get setMqttOff;

  /// No description provided for @setMqttWait.
  ///
  /// In en, this message translates to:
  /// **'On. Waits for your radio.'**
  String get setMqttWait;

  /// No description provided for @setMqttNoConfig.
  ///
  /// In en, this message translates to:
  /// **'Your radio isn\'t set to use this. Turn on MQTT and \"Proxy to client\" in its settings.'**
  String get setMqttNoConfig;

  /// No description provided for @setMqttConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to {host}. {up} sent, {down} received, about {kb} KB of data.'**
  String setMqttConnected(String host, int up, int down, String kb);

  /// No description provided for @setMqttConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {host}…'**
  String setMqttConnecting(String host);

  /// No description provided for @setMqttFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t connect.'**
  String get setMqttFailed;

  /// No description provided for @setMqttStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get setMqttStarting;

  /// No description provided for @setBgOptimized.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization can pause NOTORYX Connect when it is not on screen and drop the radio link. Set its battery use to Unrestricted to stay connected.'**
  String get setBgOptimized;

  /// No description provided for @setBgAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed to run in the background. A notification shows while a radio is connected.'**
  String get setBgAllowed;

  /// No description provided for @setSizeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Size unknown'**
  String get setSizeUnknown;

  /// No description provided for @setMbSaved.
  ///
  /// In en, this message translates to:
  /// **'{mb} MB saved'**
  String setMbSaved(String mb);

  /// No description provided for @setTilesHelp.
  ///
  /// In en, this message translates to:
  /// **'Map areas you view online stay available offline for a year (up to 500 MB).'**
  String get setTilesHelp;

  /// No description provided for @setAlertSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Alert settings apply now, but could not be saved.'**
  String get setAlertSaveFailed;

  /// No description provided for @setLowBatterySub.
  ///
  /// In en, this message translates to:
  /// **'Your radio or a favorite reports {pct}% or less'**
  String setLowBatterySub(int pct);

  /// No description provided for @setFavQuietSub.
  ///
  /// In en, this message translates to:
  /// **'A favorite is not heard for {time} while connected'**
  String setFavQuietSub(String time);

  /// No description provided for @setTheConnected.
  ///
  /// In en, this message translates to:
  /// **'the connected radio'**
  String get setTheConnected;

  /// No description provided for @setMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move {label}?'**
  String setMoveTitle(String label);

  /// No description provided for @setMoveBody.
  ///
  /// In en, this message translates to:
  /// **'Its messages, offline queue, NodeDex history, trails and telemetry history move to {to}. Whatever {to} already has is kept, so nothing is overwritten. {id} then no longer has an entry of its own.\n\nTo be safe, make a phone data backup first.'**
  String setMoveBody(String to, String id);

  /// No description provided for @setMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get setMove;

  /// No description provided for @setMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved {label} to {to}.'**
  String setMoved(String label, String to);

  /// No description provided for @setDataCounts.
  ///
  /// In en, this message translates to:
  /// **'{messages} messages • {nodes} nodes • {trails} trails'**
  String setDataCounts(int messages, int nodes, int trails);

  /// No description provided for @setConnectNew.
  ///
  /// In en, this message translates to:
  /// **'Connect to the new radio to move an old radio\'s data to it.'**
  String get setConnectNew;

  /// No description provided for @setFilterCounts.
  ///
  /// In en, this message translates to:
  /// **'{ignored} ignored • {muted} muted • {words} filtered words'**
  String setFilterCounts(int ignored, int muted, int words);

  /// No description provided for @setFilteredWords.
  ///
  /// In en, this message translates to:
  /// **'Filtered words'**
  String get setFilteredWords;

  /// No description provided for @setWordField.
  ///
  /// In en, this message translates to:
  /// **'Word or phrase'**
  String get setWordField;

  /// No description provided for @setAddWord.
  ///
  /// In en, this message translates to:
  /// **'Add filtered word'**
  String get setAddWord;

  /// No description provided for @setRemoveWord.
  ///
  /// In en, this message translates to:
  /// **'Remove {word}'**
  String setRemoveWord(String word);

  /// No description provided for @setIgnoredMuted.
  ///
  /// In en, this message translates to:
  /// **'Ignored and muted nodes'**
  String get setIgnoredMuted;

  /// No description provided for @setNoneIgnored.
  ///
  /// In en, this message translates to:
  /// **'None. Open a node to ignore or mute it.'**
  String get setNoneIgnored;

  /// No description provided for @chatsForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chatsForward;

  /// No description provided for @chatsForwardTo.
  ///
  /// In en, this message translates to:
  /// **'Forward to'**
  String get chatsForwardTo;

  /// No description provided for @chatsForwardReview.
  ///
  /// In en, this message translates to:
  /// **'Check the message, then tap Send.'**
  String get chatsForwardReview;

  /// No description provided for @chatsChannelNumbered.
  ///
  /// In en, this message translates to:
  /// **'Channel {index}: {name}'**
  String chatsChannelNumbered(int index, String name);

  /// No description provided for @chatsSchedule.
  ///
  /// In en, this message translates to:
  /// **'Send later'**
  String get chatsSchedule;

  /// No description provided for @chatsSchedule15.
  ///
  /// In en, this message translates to:
  /// **'In 15 minutes'**
  String get chatsSchedule15;

  /// No description provided for @chatsSchedule60.
  ///
  /// In en, this message translates to:
  /// **'In 1 hour'**
  String get chatsSchedule60;

  /// No description provided for @chatsSchedule240.
  ///
  /// In en, this message translates to:
  /// **'In 4 hours'**
  String get chatsSchedule240;

  /// No description provided for @chatsScheduleTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow at 8:00'**
  String get chatsScheduleTomorrow;

  /// No description provided for @chatsSchedulePick.
  ///
  /// In en, this message translates to:
  /// **'Pick a date and time'**
  String get chatsSchedulePick;

  /// No description provided for @chatsScheduleNote.
  ///
  /// In en, this message translates to:
  /// **'Goes out only while the app is running and the radio is connected.'**
  String get chatsScheduleNote;

  /// No description provided for @chatsScheduleFull.
  ///
  /// In en, this message translates to:
  /// **'You can schedule up to {max} messages.'**
  String chatsScheduleFull(int max);

  /// No description provided for @chatsScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get chatsScheduled;

  /// No description provided for @chatsScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'{day} at {time}'**
  String chatsScheduledFor(String day, String time);

  /// No description provided for @chatsScheduleMissed.
  ///
  /// In en, this message translates to:
  /// **'Not sent: the radio was not connected in time'**
  String get chatsScheduleMissed;

  /// No description provided for @chatsScheduleCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel scheduled message'**
  String get chatsScheduleCancel;

  /// No description provided for @mapNoPositions.
  ///
  /// In en, this message translates to:
  /// **'No node has reported a position yet'**
  String get mapNoPositions;

  /// No description provided for @mapConnectForPositions.
  ///
  /// In en, this message translates to:
  /// **'Connect a radio to show node positions'**
  String get mapConnectForPositions;

  /// No description provided for @mapPlaced.
  ///
  /// In en, this message translates to:
  /// **'{placed} of {total} nodes placed'**
  String mapPlaced(int placed, int total);

  /// No description provided for @mapWaypointCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} waypoint} other{{count} waypoints}}'**
  String mapWaypointCount(int count);

  /// No description provided for @mapLongPressHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press the map to drop a waypoint'**
  String get mapLongPressHint;

  /// No description provided for @mapHeardWithin.
  ///
  /// In en, this message translates to:
  /// **'Show nodes heard within'**
  String get mapHeardWithin;

  /// No description provided for @mapHeardAny.
  ///
  /// In en, this message translates to:
  /// **'Heard any time'**
  String get mapHeardAny;

  /// No description provided for @mapHeardHour.
  ///
  /// In en, this message translates to:
  /// **'Heard in last hour'**
  String get mapHeardHour;

  /// No description provided for @mapHeardDay.
  ///
  /// In en, this message translates to:
  /// **'Heard in last 24 hours'**
  String get mapHeardDay;

  /// No description provided for @mapHeardWeek.
  ///
  /// In en, this message translates to:
  /// **'Heard in last 7 days'**
  String get mapHeardWeek;

  /// No description provided for @mapShowStreet.
  ///
  /// In en, this message translates to:
  /// **'Show street map'**
  String get mapShowStreet;

  /// No description provided for @mapShowTopo.
  ///
  /// In en, this message translates to:
  /// **'Show topographic map'**
  String get mapShowTopo;

  /// No description provided for @mapLinkPlanner.
  ///
  /// In en, this message translates to:
  /// **'Link planner'**
  String get mapLinkPlanner;

  /// No description provided for @mapRallyRoutes.
  ///
  /// In en, this message translates to:
  /// **'Rally points & routes'**
  String get mapRallyRoutes;

  /// No description provided for @mapTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get mapTeam;

  /// No description provided for @mapZones.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get mapZones;

  /// No description provided for @mapExportGpx.
  ///
  /// In en, this message translates to:
  /// **'Export GPX'**
  String get mapExportGpx;

  /// No description provided for @mapHideTrails.
  ///
  /// In en, this message translates to:
  /// **'Hide trails'**
  String get mapHideTrails;

  /// No description provided for @mapShowTrails.
  ///
  /// In en, this message translates to:
  /// **'Show trails'**
  String get mapShowTrails;

  /// No description provided for @mapHideLinks.
  ///
  /// In en, this message translates to:
  /// **'Hide radio links'**
  String get mapHideLinks;

  /// No description provided for @mapShowLinks.
  ///
  /// In en, this message translates to:
  /// **'Show radio links'**
  String get mapShowLinks;

  /// No description provided for @mapShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all nodes'**
  String get mapShowAll;

  /// No description provided for @mapPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to add stops, in order. Up to {max}.'**
  String mapPlanHint(int max);

  /// No description provided for @mapPlanProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} of {max} stops • {distance}'**
  String mapPlanProgress(int count, int max, String distance);

  /// No description provided for @mapUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get mapUndo;

  /// No description provided for @mapShareRoute.
  ///
  /// In en, this message translates to:
  /// **'Share route'**
  String get mapShareRoute;

  /// No description provided for @mapRallyIntro.
  ///
  /// In en, this message translates to:
  /// **'Rally points are where everyone should meet. Drop one with a long-press and choose \"Rally point\". Routes are shared as numbered waypoints, so other Meshtastic apps see the stops too.'**
  String get mapRallyIntro;

  /// No description provided for @mapRallyPoints.
  ///
  /// In en, this message translates to:
  /// **'Rally points'**
  String get mapRallyPoints;

  /// No description provided for @mapNoneYet.
  ///
  /// In en, this message translates to:
  /// **'None yet.'**
  String get mapNoneYet;

  /// No description provided for @mapDistanceOfYou.
  ///
  /// In en, this message translates to:
  /// **'{distance} {direction} of you'**
  String mapDistanceOfYou(String distance, String direction);

  /// No description provided for @mapNoOwnPosition.
  ///
  /// In en, this message translates to:
  /// **'Your radio has no position yet'**
  String get mapNoOwnPosition;

  /// No description provided for @mapShowOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get mapShowOnMap;

  /// No description provided for @mapRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get mapRoutes;

  /// No description provided for @mapStops.
  ///
  /// In en, this message translates to:
  /// **'{count} stops'**
  String mapStops(int count);

  /// No description provided for @mapStopsHeard.
  ///
  /// In en, this message translates to:
  /// **'{heard} of {count} stops heard'**
  String mapStopsHeard(int heard, int count);

  /// No description provided for @mapFromYou.
  ///
  /// In en, this message translates to:
  /// **'from you'**
  String get mapFromYou;

  /// No description provided for @mapFromNode.
  ///
  /// In en, this message translates to:
  /// **'from {name}'**
  String mapFromNode(String name);

  /// No description provided for @mapPlanRoute.
  ///
  /// In en, this message translates to:
  /// **'Plan a route'**
  String get mapPlanRoute;

  /// No description provided for @mapConnectForRoutes.
  ///
  /// In en, this message translates to:
  /// **'Connect a radio to share routes'**
  String get mapConnectForRoutes;

  /// No description provided for @mapRouteShared.
  ///
  /// In en, this message translates to:
  /// **'Route shared: {count} stops on channel 0.'**
  String mapRouteShared(int count);

  /// No description provided for @mapRouteStopped.
  ///
  /// In en, this message translates to:
  /// **'Route stopped after {sent} of {count} stops: {error}'**
  String mapRouteStopped(int sent, int count, String error);

  /// No description provided for @mapGpxExported.
  ///
  /// In en, this message translates to:
  /// **'Exported {waypoints} waypoints and {trails} trails as GPX.'**
  String mapGpxExported(int waypoints, int trails);

  /// No description provided for @mapGpxFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export GPX: {error}'**
  String mapGpxFailed(String error);

  /// No description provided for @mapWatchTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip contacts'**
  String get mapWatchTrip;

  /// No description provided for @mapWatchFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get mapWatchFavorites;

  /// No description provided for @mapWatchAll.
  ///
  /// In en, this message translates to:
  /// **'All nodes'**
  String get mapWatchAll;

  /// No description provided for @mapAlertArrive.
  ///
  /// In en, this message translates to:
  /// **'arrive'**
  String get mapAlertArrive;

  /// No description provided for @mapAlertLeave.
  ///
  /// In en, this message translates to:
  /// **'leave'**
  String get mapAlertLeave;

  /// No description provided for @mapAlertBoth.
  ///
  /// In en, this message translates to:
  /// **'arrive or leave'**
  String get mapAlertBoth;

  /// No description provided for @mapZonesIntro.
  ///
  /// In en, this message translates to:
  /// **'Get a phone alert when someone arrives at or leaves a place, like camp or the trailhead. Alerts need the radio connected; nothing is sent over the mesh.'**
  String get mapZonesIntro;

  /// No description provided for @mapNoZones.
  ///
  /// In en, this message translates to:
  /// **'No zones yet.'**
  String get mapNoZones;

  /// No description provided for @mapZoneSummary.
  ///
  /// In en, this message translates to:
  /// **'{radius} radius • {watch} • alert when they {alert}'**
  String mapZoneSummary(String radius, String watch, String alert);

  /// No description provided for @mapDeleteZone.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}'**
  String mapDeleteZone(String name);

  /// No description provided for @mapAddZone.
  ///
  /// In en, this message translates to:
  /// **'Add zone at map center'**
  String get mapAddZone;

  /// No description provided for @mapTeamIntro.
  ///
  /// In en, this message translates to:
  /// **'Your trip contacts. Tap one to find them on the map.'**
  String get mapTeamIntro;

  /// No description provided for @mapNoTeam.
  ///
  /// In en, this message translates to:
  /// **'No trip contacts yet'**
  String get mapNoTeam;

  /// No description provided for @mapNoTeamHint.
  ///
  /// In en, this message translates to:
  /// **'Add up to 6 people on HOME → Trip. They show here and stand out on the map.'**
  String get mapNoTeamHint;

  /// No description provided for @mapFreshOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get mapFreshOk;

  /// No description provided for @mapFreshQuiet.
  ///
  /// In en, this message translates to:
  /// **'QUIET'**
  String get mapFreshQuiet;

  /// No description provided for @mapFreshLost.
  ///
  /// In en, this message translates to:
  /// **'LOST'**
  String get mapFreshLost;

  /// No description provided for @mapConnectForWaypoints.
  ///
  /// In en, this message translates to:
  /// **'Connect a radio to share waypoints.'**
  String get mapConnectForWaypoints;

  /// No description provided for @mapWaypointShared.
  ///
  /// In en, this message translates to:
  /// **'Waypoint \"{name}\" shared on channel 0.'**
  String mapWaypointShared(String name);

  /// No description provided for @mapWaypointFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share waypoint: {error}'**
  String mapWaypointFailed(String error);

  /// No description provided for @mapNeverExpires.
  ///
  /// In en, this message translates to:
  /// **'Never expires'**
  String get mapNeverExpires;

  /// No description provided for @mapExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {time}'**
  String mapExpires(String time);

  /// No description provided for @mapSharedBy.
  ///
  /// In en, this message translates to:
  /// **'Shared by {name}'**
  String mapSharedBy(String name);

  /// No description provided for @mapLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked to its creator'**
  String get mapLocked;

  /// No description provided for @mapDeleteEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get mapDeleteEveryone;

  /// No description provided for @mapDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{name}\".'**
  String mapDeleted(String name);

  /// No description provided for @mapDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {error}'**
  String mapDeleteFailed(String error);

  /// No description provided for @mapUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get mapUnknown;

  /// No description provided for @mapFromThisRadio.
  ///
  /// In en, this message translates to:
  /// **'{distance} from this radio'**
  String mapFromThisRadio(String distance);

  /// No description provided for @mapPositionHeard.
  ///
  /// In en, this message translates to:
  /// **'Position: {position} • Heard: {heard}'**
  String mapPositionHeard(String position, String heard);

  /// No description provided for @mapDirect.
  ///
  /// In en, this message translates to:
  /// **'direct'**
  String get mapDirect;

  /// No description provided for @mapBatteryExternal.
  ///
  /// In en, this message translates to:
  /// **'Battery: external power'**
  String get mapBatteryExternal;

  /// No description provided for @mapBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery: {level}%'**
  String mapBattery(int level);

  /// No description provided for @mapOpenDetails.
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get mapOpenDetails;

  /// No description provided for @mapThisRadioSuffix.
  ///
  /// In en, this message translates to:
  /// **', this radio'**
  String get mapThisRadioSuffix;

  /// No description provided for @mapTripContactSuffix.
  ///
  /// In en, this message translates to:
  /// **', trip contact, {summary}'**
  String mapTripContactSuffix(String summary);

  /// No description provided for @mapRallyPoint.
  ///
  /// In en, this message translates to:
  /// **'Rally point'**
  String get mapRallyPoint;

  /// No description provided for @mapWaypoint.
  ///
  /// In en, this message translates to:
  /// **'Waypoint'**
  String get mapWaypoint;

  /// No description provided for @mapExpireHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour'**
  String get mapExpireHour;

  /// No description provided for @mapExpireDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get mapExpireDay;

  /// No description provided for @mapExpireWeek.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get mapExpireWeek;

  /// No description provided for @mapExpireNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get mapExpireNever;

  /// No description provided for @mapNewWaypoint.
  ///
  /// In en, this message translates to:
  /// **'New waypoint'**
  String get mapNewWaypoint;

  /// No description provided for @mapName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get mapName;

  /// No description provided for @mapDescription.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get mapDescription;

  /// No description provided for @mapRallySub.
  ///
  /// In en, this message translates to:
  /// **'Where everyone should meet'**
  String get mapRallySub;

  /// No description provided for @mapExpiresAfter.
  ///
  /// In en, this message translates to:
  /// **'Expires after'**
  String get mapExpiresAfter;

  /// No description provided for @mapOnlyMe.
  ///
  /// In en, this message translates to:
  /// **'Only I can edit or delete'**
  String get mapOnlyMe;

  /// No description provided for @mapSharedChannel0.
  ///
  /// In en, this message translates to:
  /// **'Shared with everyone on channel 0.'**
  String get mapSharedChannel0;

  /// No description provided for @mapShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get mapShare;

  /// No description provided for @mapNewZone.
  ///
  /// In en, this message translates to:
  /// **'New zone'**
  String get mapNewZone;

  /// No description provided for @mapCenteredOn.
  ///
  /// In en, this message translates to:
  /// **'Centered on {lat}, {lon}'**
  String mapCenteredOn(String lat, String lon);

  /// No description provided for @mapZoneName.
  ///
  /// In en, this message translates to:
  /// **'Name, e.g. Camp'**
  String get mapZoneName;

  /// No description provided for @mapRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get mapRadius;

  /// No description provided for @mapWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get mapWatch;

  /// No description provided for @mapAlertWhen.
  ///
  /// In en, this message translates to:
  /// **'Alert when they'**
  String get mapAlertWhen;

  /// No description provided for @mapAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get mapAdd;

  /// No description provided for @mapRouteName.
  ///
  /// In en, this message translates to:
  /// **'Route name'**
  String get mapRouteName;

  /// No description provided for @mapRouteSends.
  ///
  /// In en, this message translates to:
  /// **'Sends {count} waypoints on channel 0, about 3 seconds apart. They expire after a day.'**
  String mapRouteSends(int count);

  /// No description provided for @mapShowHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Show coverage heatmap'**
  String get mapShowHeatmap;

  /// No description provided for @mapHideHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Hide coverage heatmap'**
  String get mapHideHeatmap;

  /// No description provided for @mapHeatmapEmpty.
  ///
  /// In en, this message translates to:
  /// **'No coverage readings yet. Turn on Record coverage in Field records.'**
  String get mapHeatmapEmpty;

  /// No description provided for @mapHeatmapSummary.
  ///
  /// In en, this message translates to:
  /// **'Coverage: {readings} readings. Numbers are average SNR in dB.'**
  String mapHeatmapSummary(int readings);

  /// No description provided for @mapHeatStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get mapHeatStrong;

  /// No description provided for @mapHeatFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get mapHeatFair;

  /// No description provided for @mapHeatWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get mapHeatWeak;

  /// No description provided for @mapShowRemembered.
  ///
  /// In en, this message translates to:
  /// **'Show remembered nodes'**
  String get mapShowRemembered;

  /// No description provided for @mapHideRemembered.
  ///
  /// In en, this message translates to:
  /// **'Hide remembered nodes'**
  String get mapHideRemembered;

  /// No description provided for @mapRememberedNone.
  ///
  /// In en, this message translates to:
  /// **'No remembered nodes with a saved position.'**
  String get mapRememberedNone;

  /// No description provided for @mapRememberedPin.
  ///
  /// In en, this message translates to:
  /// **'{name}, remembered, last seen {when}'**
  String mapRememberedPin(String name, String when);

  /// No description provided for @mapRememberedNote.
  ///
  /// In en, this message translates to:
  /// **'Your radio no longer lists this node. This is where it last reported.'**
  String get mapRememberedNote;

  /// No description provided for @mapLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {when}'**
  String mapLastSeen(String when);

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTORYX Connect is locked'**
  String get lockTitle;

  /// No description provided for @lockBody.
  ///
  /// In en, this message translates to:
  /// **'Your radio stays connected while the app is locked.'**
  String get lockBody;

  /// No description provided for @lockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlock;

  /// No description provided for @lockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock NOTORYX Connect'**
  String get lockReason;

  /// No description provided for @takTitle.
  ///
  /// In en, this message translates to:
  /// **'ATAK feed'**
  String get takTitle;

  /// No description provided for @toolsTakSub.
  ///
  /// In en, this message translates to:
  /// **'Swap positions with ATAK on this phone'**
  String get toolsTakSub;

  /// No description provided for @takIntro.
  ///
  /// In en, this message translates to:
  /// **'Sends the position of each mesh node to ATAK on this phone, once every 30 seconds. Nothing leaves the phone, and nothing goes out over the mesh.'**
  String get takIntro;

  /// No description provided for @takSwitch.
  ///
  /// In en, this message translates to:
  /// **'Send mesh positions to ATAK'**
  String get takSwitch;

  /// No description provided for @takPort.
  ///
  /// In en, this message translates to:
  /// **'UDP port'**
  String get takPort;

  /// No description provided for @takBadPort.
  ///
  /// In en, this message translates to:
  /// **'Use a number from 1024 to 65535.'**
  String get takBadPort;

  /// No description provided for @takStatus.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Sending {count} node} other{Sending {count} nodes}}'**
  String takStatus(int count);

  /// No description provided for @takProblem.
  ///
  /// In en, this message translates to:
  /// **'Could not send: {error}'**
  String takProblem(String error);

  /// No description provided for @takHowTo.
  ///
  /// In en, this message translates to:
  /// **'In ATAK, open Settings, then Network Preferences, then Manage Inputs, and add a UDP input on this port. Nodes with no position in the last hour are left out.'**
  String get takHowTo;

  /// No description provided for @ndFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed: {error}'**
  String ndFailed(String error);

  /// No description provided for @ndSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Send failed: {error}'**
  String ndSendFailed(String error);

  /// No description provided for @ndFieldNote.
  ///
  /// In en, this message translates to:
  /// **'Field note'**
  String get ndFieldNote;

  /// No description provided for @ndRemoveFavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove favorite'**
  String get ndRemoveFavorite;

  /// No description provided for @ndAddFavorite.
  ///
  /// In en, this message translates to:
  /// **'Add favorite'**
  String get ndAddFavorite;

  /// No description provided for @ndShortName.
  ///
  /// In en, this message translates to:
  /// **'Short name'**
  String get ndShortName;

  /// No description provided for @ndHardware.
  ///
  /// In en, this message translates to:
  /// **'Hardware'**
  String get ndHardware;

  /// No description provided for @ndThisRadio.
  ///
  /// In en, this message translates to:
  /// **'This radio'**
  String get ndThisRadio;

  /// No description provided for @ndYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get ndYes;

  /// No description provided for @ndLastHeard.
  ///
  /// In en, this message translates to:
  /// **'Last heard'**
  String get ndLastHeard;

  /// No description provided for @ndSignal.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get ndSignal;

  /// No description provided for @ndHopsAway.
  ///
  /// In en, this message translates to:
  /// **'Hops away'**
  String get ndHopsAway;

  /// No description provided for @ndDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get ndDirect;

  /// No description provided for @ndBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get ndBattery;

  /// No description provided for @ndExternalPower.
  ///
  /// In en, this message translates to:
  /// **'External power'**
  String get ndExternalPower;

  /// No description provided for @ndVoltage.
  ///
  /// In en, this message translates to:
  /// **'Voltage'**
  String get ndVoltage;

  /// No description provided for @ndChannelUse.
  ///
  /// In en, this message translates to:
  /// **'Channel use'**
  String get ndChannelUse;

  /// No description provided for @ndPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get ndPosition;

  /// No description provided for @ndAltitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get ndAltitude;

  /// No description provided for @ndPositionAge.
  ///
  /// In en, this message translates to:
  /// **'Position age'**
  String get ndPositionAge;

  /// No description provided for @ndDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get ndDistance;

  /// No description provided for @ndEncounters.
  ///
  /// In en, this message translates to:
  /// **'Encounters'**
  String get ndEncounters;

  /// No description provided for @ndTraceroute.
  ///
  /// In en, this message translates to:
  /// **'Traceroute'**
  String get ndTraceroute;

  /// No description provided for @ndRequestPosition.
  ///
  /// In en, this message translates to:
  /// **'Request position'**
  String get ndRequestPosition;

  /// No description provided for @ndPositionRequested.
  ///
  /// In en, this message translates to:
  /// **'Position requested. It updates when the node replies.'**
  String get ndPositionRequested;

  /// No description provided for @ndRequestTelemetry.
  ///
  /// In en, this message translates to:
  /// **'Request telemetry'**
  String get ndRequestTelemetry;

  /// No description provided for @ndTelemetryRequested.
  ///
  /// In en, this message translates to:
  /// **'Telemetry requested. It updates when the node replies.'**
  String get ndTelemetryRequested;

  /// No description provided for @ndRemoteAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remote admin'**
  String get ndRemoteAdmin;

  /// No description provided for @ndRequestSensors.
  ///
  /// In en, this message translates to:
  /// **'Request sensors'**
  String get ndRequestSensors;

  /// No description provided for @ndSensorsRequested.
  ///
  /// In en, this message translates to:
  /// **'Sensor readings requested. Nodes without sensors don\'t answer.'**
  String get ndSensorsRequested;

  /// No description provided for @ndMute.
  ///
  /// In en, this message translates to:
  /// **'Mute notifications'**
  String get ndMute;

  /// No description provided for @ndMuteSub.
  ///
  /// In en, this message translates to:
  /// **'Messages still show; no alerts or read-aloud'**
  String get ndMuteSub;

  /// No description provided for @ndIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore this node'**
  String get ndIgnore;

  /// No description provided for @ndIgnoreSub.
  ///
  /// In en, this message translates to:
  /// **'Hidden from nodes, map and chats; never notifies or gets bot replies. Undo here or in Settings.'**
  String get ndIgnoreSub;

  /// No description provided for @ndAddNote.
  ///
  /// In en, this message translates to:
  /// **'Tap to add a note'**
  String get ndAddNote;

  /// No description provided for @ndDirectMessages.
  ///
  /// In en, this message translates to:
  /// **'DIRECT MESSAGES'**
  String get ndDirectMessages;

  /// No description provided for @ndNoDirect.
  ///
  /// In en, this message translates to:
  /// **'No direct messages with this node yet.'**
  String get ndNoDirect;

  /// No description provided for @ndDirectMessage.
  ///
  /// In en, this message translates to:
  /// **'Direct message'**
  String get ndDirectMessage;

  /// No description provided for @ndSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get ndSend;

  /// No description provided for @ndRadioLinks.
  ///
  /// In en, this message translates to:
  /// **'DIRECT RADIO LINKS'**
  String get ndRadioLinks;

  /// No description provided for @ndNoNeighbors.
  ///
  /// In en, this message translates to:
  /// **'No neighbor reports yet. Nodes share these when the Neighbor Info module is enabled (Settings → Change radio settings → Neighborinfo).'**
  String get ndNoNeighbors;

  /// No description provided for @ndHears.
  ///
  /// In en, this message translates to:
  /// **'Hears directly ({count}):'**
  String ndHears(int count);

  /// No description provided for @ndNoneReported.
  ///
  /// In en, this message translates to:
  /// **'  No neighbors reported'**
  String get ndNoneReported;

  /// No description provided for @ndHeardBy.
  ///
  /// In en, this message translates to:
  /// **'Heard directly by ({count}):'**
  String ndHeardBy(int count);

  /// No description provided for @ndTrustQ.
  ///
  /// In en, this message translates to:
  /// **'Trust the new key?'**
  String get ndTrustQ;

  /// No description provided for @ndTrustBody.
  ///
  /// In en, this message translates to:
  /// **'Only do this if you have checked with {name}\'s owner that they reset or replaced their radio. If not, someone else may be pretending to be this node.'**
  String ndTrustBody(String name);

  /// No description provided for @ndTrust.
  ///
  /// In en, this message translates to:
  /// **'Trust new key'**
  String get ndTrust;

  /// No description provided for @ndKeyChanged.
  ///
  /// In en, this message translates to:
  /// **'Security key changed'**
  String get ndKeyChanged;

  /// No description provided for @ndKeyChangedBody.
  ///
  /// In en, this message translates to:
  /// **'This node now shows a different key ({newCode}) from the one first seen ({oldCode}). Its radio may have been reset or replaced, or someone may be impersonating it. Check with its owner before sending private messages.'**
  String ndKeyChangedBody(String newCode, String oldCode);

  /// No description provided for @ndSecurityKey.
  ///
  /// In en, this message translates to:
  /// **'Security key'**
  String get ndSecurityKey;

  /// No description provided for @ndKeyNotShared.
  ///
  /// In en, this message translates to:
  /// **'Not shared yet. Nodes on firmware 2.5 or newer share a key for private direct messages.'**
  String get ndKeyNotShared;

  /// No description provided for @ndSafetyCode.
  ///
  /// In en, this message translates to:
  /// **'Safety code {code}\nCompare this with the owner\'s radio to be sure it\'s them.'**
  String ndSafetyCode(String code);

  /// No description provided for @homeFirmwareTitle.
  ///
  /// In en, this message translates to:
  /// **'Radio firmware update suggested'**
  String get homeFirmwareTitle;

  /// No description provided for @homeCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get homeCheckIn;

  /// No description provided for @homeEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get homeEmergency;

  /// No description provided for @homeSosHint.
  ///
  /// In en, this message translates to:
  /// **'Hold for 2 seconds. It goes to your trip contacts, and repeats every 5 minutes until someone replies.'**
  String get homeSosHint;

  /// No description provided for @homeSosHintChannel.
  ///
  /// In en, this message translates to:
  /// **'Hold for 2 seconds. It goes to your trip contacts and channel {channel}, and repeats every 5 minutes until someone replies.'**
  String homeSosHintChannel(int channel);

  /// No description provided for @homeNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Sent or queued does not mean received. Confirm with a reply or a call.'**
  String get homeNotReceived;

  /// No description provided for @homeConnected.
  ///
  /// In en, this message translates to:
  /// **'Radio connected'**
  String get homeConnected;

  /// No description provided for @homeNotConnected.
  ///
  /// In en, this message translates to:
  /// **'No radio connected'**
  String get homeNotConnected;

  /// No description provided for @homeYourRadio.
  ///
  /// In en, this message translates to:
  /// **'Your radio'**
  String get homeYourRadio;

  /// No description provided for @homeConnectHint.
  ///
  /// In en, this message translates to:
  /// **'Connect to check in, send an SOS and see the mesh.'**
  String get homeConnectHint;

  /// No description provided for @homeNodes.
  ///
  /// In en, this message translates to:
  /// **'Nodes'**
  String get homeNodes;

  /// No description provided for @homeBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get homeBattery;

  /// No description provided for @homeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get homeUnknown;

  /// No description provided for @homePluggedIn.
  ///
  /// In en, this message translates to:
  /// **'Plugged in'**
  String get homePluggedIn;

  /// No description provided for @homeConnectRadio.
  ///
  /// In en, this message translates to:
  /// **'Connect radio'**
  String get homeConnectRadio;

  /// No description provided for @homeTryDemo.
  ///
  /// In en, this message translates to:
  /// **'Try the demo'**
  String get homeTryDemo;

  /// No description provided for @homeTripRunning.
  ///
  /// In en, this message translates to:
  /// **'Trip running'**
  String get homeTripRunning;

  /// No description provided for @homeTripNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Trip not started'**
  String get homeTripNotStarted;

  /// No description provided for @homeContacts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} contact} other{{count} contacts}}'**
  String homeContacts(int count);

  /// No description provided for @homeTripNamed.
  ///
  /// In en, this message translates to:
  /// **'Trip: {name}'**
  String homeTripNamed(String name);

  /// No description provided for @homePlanTrip.
  ///
  /// In en, this message translates to:
  /// **'Plan your trip'**
  String get homePlanTrip;

  /// No description provided for @homeOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue: {names}'**
  String homeOverdue(String names);

  /// No description provided for @homeCheckInLabel.
  ///
  /// In en, this message translates to:
  /// **'Check in: {label}'**
  String homeCheckInLabel(String label);

  /// No description provided for @homeDelivered.
  ///
  /// In en, this message translates to:
  /// **'{label} at {time}: delivered to {delivered} of {total}'**
  String homeDelivered(String label, String time, int delivered, int total);

  /// No description provided for @homeNotDelivered.
  ///
  /// In en, this message translates to:
  /// **'not delivered to {names}'**
  String homeNotDelivered(String names);

  /// No description provided for @homeWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String homeWaiting(int count);

  /// No description provided for @homeDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get homeDetails;

  /// No description provided for @homeResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get homeResend;

  /// No description provided for @homeSendSosQ.
  ///
  /// In en, this message translates to:
  /// **'Send SOS?'**
  String get homeSendSosQ;

  /// No description provided for @homeSosRepeats.
  ///
  /// In en, this message translates to:
  /// **'Your SOS repeats every 5 minutes until someone replies or you stop it.'**
  String get homeSosRepeats;

  /// No description provided for @homeSendSos.
  ///
  /// In en, this message translates to:
  /// **'Send SOS'**
  String get homeSendSos;

  /// No description provided for @homeHoldSos.
  ///
  /// In en, this message translates to:
  /// **'Hold for SOS'**
  String get homeHoldSos;

  /// No description provided for @homeSosReplied.
  ///
  /// In en, this message translates to:
  /// **'{name} replied. Repeats stopped.'**
  String homeSosReplied(String name);

  /// No description provided for @homeSosNext.
  ///
  /// In en, this message translates to:
  /// **'Sent {sends} of {max}. Next at {time}.'**
  String homeSosNext(int sends, int max, String time);

  /// No description provided for @homeSosBusy.
  ///
  /// In en, this message translates to:
  /// **' The channel is busy, so repeats are spaced out to get through.'**
  String get homeSosBusy;

  /// No description provided for @homeSosDone.
  ///
  /// In en, this message translates to:
  /// **'Sent {max} times. Repeats finished; the SOS stays shown until you stop it.'**
  String homeSosDone(int max);

  /// No description provided for @homeSosActive.
  ///
  /// In en, this message translates to:
  /// **'SOS active'**
  String get homeSosActive;

  /// No description provided for @homeImSafe.
  ///
  /// In en, this message translates to:
  /// **'I\'m safe'**
  String get homeImSafe;

  /// No description provided for @homeStopNoMessage.
  ///
  /// In en, this message translates to:
  /// **'Stop without message'**
  String get homeStopNoMessage;

  /// No description provided for @frTitle.
  ///
  /// In en, this message translates to:
  /// **'Field records'**
  String get frTitle;

  /// No description provided for @frTplAssistance.
  ///
  /// In en, this message translates to:
  /// **'Assistance'**
  String get frTplAssistance;

  /// No description provided for @frTplCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get frTplCheckIn;

  /// No description provided for @frTplAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get frTplAllClear;

  /// No description provided for @frTooLong.
  ///
  /// In en, this message translates to:
  /// **'Enter a message of 1–220 UTF-8 bytes.'**
  String get frTooLong;

  /// No description provided for @frBroadcastQ.
  ///
  /// In en, this message translates to:
  /// **'Broadcast to channel {channel}?'**
  String frBroadcastQ(int channel);

  /// No description provided for @frNoProof.
  ///
  /// In en, this message translates to:
  /// **'Sending does not prove reception. Confirm with a reply or voice contact.'**
  String get frNoProof;

  /// No description provided for @frSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get frSendMessage;

  /// No description provided for @frChanged.
  ///
  /// In en, this message translates to:
  /// **'Radio or channel changed. Reconnect and review the message.'**
  String get frChanged;

  /// No description provided for @frSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted to the radio. Check Chats for transmission status and replies.'**
  String get frSubmitted;

  /// No description provided for @frIncidentLog.
  ///
  /// In en, this message translates to:
  /// **'Incident log'**
  String get frIncidentLog;

  /// No description provided for @frIncidentLogSub.
  ///
  /// In en, this message translates to:
  /// **'Private notes saved on this phone'**
  String get frIncidentLogSub;

  /// No description provided for @frIncidentField.
  ///
  /// In en, this message translates to:
  /// **'Incident or observation'**
  String get frIncidentField;

  /// No description provided for @frIncidentSaved.
  ///
  /// In en, this message translates to:
  /// **'Incident saved.'**
  String get frIncidentSaved;

  /// No description provided for @frSaveIncident.
  ///
  /// In en, this message translates to:
  /// **'Save incident'**
  String get frSaveIncident;

  /// No description provided for @frIncidentCopied.
  ///
  /// In en, this message translates to:
  /// **'Incident CSV copied. Paste into a file or spreadsheet.'**
  String get frIncidentCopied;

  /// No description provided for @frCopyIncident.
  ///
  /// In en, this message translates to:
  /// **'Copy incident CSV'**
  String get frCopyIncident;

  /// No description provided for @frRadioOf.
  ///
  /// In en, this message translates to:
  /// **'{time} • Radio {radio}'**
  String frRadioOf(String time, String radio);

  /// No description provided for @frUnassigned.
  ///
  /// In en, this message translates to:
  /// **'unassigned'**
  String get frUnassigned;

  /// No description provided for @frRemoveIncident.
  ///
  /// In en, this message translates to:
  /// **'Remove incident'**
  String get frRemoveIncident;

  /// No description provided for @frRemoveIncidentQ.
  ///
  /// In en, this message translates to:
  /// **'Remove this incident?'**
  String get frRemoveIncidentQ;

  /// No description provided for @frKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get frKeep;

  /// No description provided for @frRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get frRemove;

  /// No description provided for @frIncidentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Incident removed.'**
  String get frIncidentRemoved;

  /// No description provided for @frTemplates.
  ///
  /// In en, this message translates to:
  /// **'Emergency & check-in templates'**
  String get frTemplates;

  /// No description provided for @frTemplatesSub.
  ///
  /// In en, this message translates to:
  /// **'Edit details, choose a channel, then review before sending'**
  String get frTemplatesSub;

  /// No description provided for @frMessageField.
  ///
  /// In en, this message translates to:
  /// **'Message — replace the blank details'**
  String get frMessageField;

  /// No description provided for @frBroadcastChannel.
  ///
  /// In en, this message translates to:
  /// **'Broadcast channel'**
  String get frBroadcastChannel;

  /// No description provided for @frChannelItem.
  ///
  /// In en, this message translates to:
  /// **'Channel {index} • {name}'**
  String frChannelItem(int index, String name);

  /// No description provided for @frReview.
  ///
  /// In en, this message translates to:
  /// **'Review message'**
  String get frReview;

  /// No description provided for @frNotEmergency.
  ///
  /// In en, this message translates to:
  /// **'A template is ordinary mesh text. It does not contact emergency services.'**
  String get frNotEmergency;

  /// No description provided for @frCoverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage history'**
  String get frCoverage;

  /// No description provided for @frCoverageSub.
  ///
  /// In en, this message translates to:
  /// **'Receiver location with received RF signal • local recording only'**
  String get frCoverageSub;

  /// No description provided for @frRecord.
  ///
  /// In en, this message translates to:
  /// **'Record coverage'**
  String get frRecord;

  /// No description provided for @frRecordSub.
  ///
  /// In en, this message translates to:
  /// **'Requests phone GPS. Stops on disconnect. Does not send your location.'**
  String get frRecordSub;

  /// No description provided for @frRecordOn.
  ///
  /// In en, this message translates to:
  /// **'Coverage recorder enabled; waiting for a fresh accurate GPS fix and RF packets.'**
  String get frRecordOn;

  /// No description provided for @frRecordOff.
  ///
  /// In en, this message translates to:
  /// **'Coverage recorder stopped.'**
  String get frRecordOff;

  /// No description provided for @frReadings.
  ///
  /// In en, this message translates to:
  /// **'{count} readings • maximum 2000 coverage readings • coverage expires after 30 days'**
  String frReadings(int count);

  /// No description provided for @frCoverageCopied.
  ///
  /// In en, this message translates to:
  /// **'Coverage CSV copied. Paste into a file or spreadsheet.'**
  String get frCoverageCopied;

  /// No description provided for @frCopyCoverage.
  ///
  /// In en, this message translates to:
  /// **'Copy coverage CSV'**
  String get frCopyCoverage;

  /// No description provided for @frBot.
  ///
  /// In en, this message translates to:
  /// **'Bot safeguards & quiet hours'**
  String get frBot;

  /// No description provided for @frBotSub.
  ///
  /// In en, this message translates to:
  /// **'6 replies/hour • 30-second spacing • 5-minute per-node cooldown'**
  String get frBotSub;

  /// No description provided for @frBotEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Bot Mode in Chats for this session.'**
  String get frBotEnable;

  /// No description provided for @frBotRules.
  ///
  /// In en, this message translates to:
  /// **'Only fresh messages on the selected channel qualify. Replays and bot replies (NOTORYX: or Bastion:) are ignored. Quiet hours use this phone’s local time.'**
  String get frBotRules;

  /// No description provided for @frQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get frQuiet;

  /// No description provided for @frQuietStart.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours start'**
  String get frQuietStart;

  /// No description provided for @frQuietEnd.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours end'**
  String get frQuietEnd;

  /// No description provided for @frBotChannel.
  ///
  /// In en, this message translates to:
  /// **'Bot channel slot'**
  String get frBotChannel;

  /// No description provided for @frChannelN.
  ///
  /// In en, this message translates to:
  /// **'Channel {index}'**
  String frChannelN(int index);

  /// No description provided for @frBytes.
  ///
  /// In en, this message translates to:
  /// **'{bytes} of {max} bytes. Blank lines are left out.'**
  String frBytes(int bytes, int max);

  /// No description provided for @frBytesOver.
  ///
  /// In en, this message translates to:
  /// **'{bytes} of {max} bytes. Too long to send: shorten a field.'**
  String frBytesOver(int bytes, int max);

  /// No description provided for @frUseReport.
  ///
  /// In en, this message translates to:
  /// **'Use report'**
  String get frUseReport;

  /// No description provided for @rsTitle.
  ///
  /// In en, this message translates to:
  /// **'Radio settings'**
  String get rsTitle;

  /// No description provided for @rsNotReady.
  ///
  /// In en, this message translates to:
  /// **'Radio not ready'**
  String get rsNotReady;

  /// No description provided for @rsNotReadySub.
  ///
  /// In en, this message translates to:
  /// **'Connect to a radio and wait for READY to change settings.'**
  String get rsNotReadySub;

  /// No description provided for @rsAvailability.
  ///
  /// In en, this message translates to:
  /// **'Settings availability'**
  String get rsAvailability;

  /// No description provided for @rsAvailabilitySub.
  ///
  /// In en, this message translates to:
  /// **'Check reads before editing. Missing startup settings do not prove a module is unsupported. Results reset on reconnect.'**
  String get rsAvailabilitySub;

  /// No description provided for @rsStopChecking.
  ///
  /// In en, this message translates to:
  /// **'Stop checking'**
  String get rsStopChecking;

  /// No description provided for @rsOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get rsOwner;

  /// No description provided for @rsOwnerSub.
  ///
  /// In en, this message translates to:
  /// **'Long and short node names'**
  String get rsOwnerSub;

  /// No description provided for @rsLoraSub.
  ///
  /// In en, this message translates to:
  /// **'Region, modem preset, hop limit, transmit'**
  String get rsLoraSub;

  /// No description provided for @rsChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get rsChannels;

  /// No description provided for @rsChannelsSub.
  ///
  /// In en, this message translates to:
  /// **'Names, roles and encryption keys'**
  String get rsChannelsSub;

  /// No description provided for @rsDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get rsDevice;

  /// No description provided for @rsDeviceSub.
  ///
  /// In en, this message translates to:
  /// **'Device role and rebroadcast mode'**
  String get rsDeviceSub;

  /// No description provided for @rsPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get rsPosition;

  /// No description provided for @rsPositionSub.
  ///
  /// In en, this message translates to:
  /// **'Broadcast interval, GPS mode, smart position'**
  String get rsPositionSub;

  /// No description provided for @rsAllSettings.
  ///
  /// In en, this message translates to:
  /// **'ALL RADIO SETTINGS'**
  String get rsAllSettings;

  /// No description provided for @rsModules.
  ///
  /// In en, this message translates to:
  /// **'MODULES'**
  String get rsModules;

  /// No description provided for @rsRadioChanged.
  ///
  /// In en, this message translates to:
  /// **'Connected radio changed while loading. Retry the read.'**
  String get rsRadioChanged;

  /// No description provided for @rsSaveQ.
  ///
  /// In en, this message translates to:
  /// **'Save {section}?'**
  String rsSaveQ(String section);

  /// No description provided for @rsSaveWarning.
  ///
  /// In en, this message translates to:
  /// **'This writes the change to the connected radio. The radio may reboot and reconnect.'**
  String get rsSaveWarning;

  /// No description provided for @rsIdentityChanged.
  ///
  /// In en, this message translates to:
  /// **'Radio identity changed or is unavailable. Reload before saving.'**
  String get rsIdentityChanged;

  /// No description provided for @rsSaved.
  ///
  /// In en, this message translates to:
  /// **'{section} saved and verified from radio.'**
  String rsSaved(String section);

  /// No description provided for @rsNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Save not verified: {error}\nThe radio may have applied the change. Reload to inspect its current value; nothing will be resent automatically.'**
  String rsNotVerified(String error);

  /// No description provided for @rsSaveButton.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get rsSaveButton;

  /// No description provided for @rsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{section} settings are unavailable through this radio’s firmware API.'**
  String rsUnavailable(String section);

  /// No description provided for @rsReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read from the radio: {error}'**
  String rsReadFailed(String error);

  /// No description provided for @rsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get rsRetry;

  /// No description provided for @rsWaitingReconnect.
  ///
  /// In en, this message translates to:
  /// **'Waiting for reconnect and a fresh settings read…'**
  String get rsWaitingReconnect;

  /// No description provided for @rsReload.
  ///
  /// In en, this message translates to:
  /// **'Reload from radio'**
  String get rsReload;

  /// No description provided for @rsLongName.
  ///
  /// In en, this message translates to:
  /// **'Long name'**
  String get rsLongName;

  /// No description provided for @rsShortName.
  ///
  /// In en, this message translates to:
  /// **'Short name'**
  String get rsShortName;

  /// No description provided for @rsChooseRegion.
  ///
  /// In en, this message translates to:
  /// **'Choose a region before saving; the radio will not transmit without one.'**
  String get rsChooseRegion;

  /// No description provided for @rsCustomInvalid.
  ///
  /// In en, this message translates to:
  /// **'Custom settings require a positive bandwidth, spreading factor 5–12 and coding rate denominator 5–8. Check your radio’s supported values.'**
  String get rsCustomInvalid;

  /// No description provided for @rsRegionWarning.
  ///
  /// In en, this message translates to:
  /// **'Changing region or modem preset disconnects this radio from nodes that keep the old settings.'**
  String get rsRegionWarning;

  /// No description provided for @rsRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get rsRegion;

  /// No description provided for @rsUsePreset.
  ///
  /// In en, this message translates to:
  /// **'Use modem preset'**
  String get rsUsePreset;

  /// No description provided for @rsModemPreset.
  ///
  /// In en, this message translates to:
  /// **'Modem preset'**
  String get rsModemPreset;

  /// No description provided for @rsBandwidth.
  ///
  /// In en, this message translates to:
  /// **'Bandwidth (kHz)'**
  String get rsBandwidth;

  /// No description provided for @rsSpreadFactor.
  ///
  /// In en, this message translates to:
  /// **'Spreading factor'**
  String get rsSpreadFactor;

  /// No description provided for @rsCodingRate.
  ///
  /// In en, this message translates to:
  /// **'Coding rate denominator (5–8)'**
  String get rsCodingRate;

  /// No description provided for @rsRxBoost.
  ///
  /// In en, this message translates to:
  /// **'RX boosted gain'**
  String get rsRxBoost;

  /// No description provided for @rsRxBoostSub.
  ///
  /// In en, this message translates to:
  /// **'Internal SX126x receiver gain; separate from external LNA'**
  String get rsRxBoostSub;

  /// No description provided for @rsLna.
  ///
  /// In en, this message translates to:
  /// **'External LNA'**
  String get rsLna;

  /// No description provided for @rsLnaReported.
  ///
  /// In en, this message translates to:
  /// **'External receive amplifier reported by this radio'**
  String get rsLnaReported;

  /// No description provided for @rsLnaNone.
  ///
  /// In en, this message translates to:
  /// **'This radio has not reported a controllable external LNA'**
  String get rsLnaNone;

  /// No description provided for @rsHopLimit.
  ///
  /// In en, this message translates to:
  /// **'Hop limit: {hops}'**
  String rsHopLimit(int hops);

  /// No description provided for @rsTransmit.
  ///
  /// In en, this message translates to:
  /// **'Transmit enabled'**
  String get rsTransmit;

  /// No description provided for @rsTransmitSub.
  ///
  /// In en, this message translates to:
  /// **'Off makes the radio receive-only'**
  String get rsTransmitSub;

  /// No description provided for @rsInfraWarning.
  ///
  /// In en, this message translates to:
  /// **'{role} is for fixed infrastructure with good coverage. On a handheld it wastes airtime and battery.'**
  String rsInfraWarning(String role);

  /// No description provided for @rsRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get rsRole;

  /// No description provided for @rsRebroadcast.
  ///
  /// In en, this message translates to:
  /// **'Rebroadcast mode'**
  String get rsRebroadcast;

  /// No description provided for @rsIntervalInvalid.
  ///
  /// In en, this message translates to:
  /// **'Broadcast interval must be 0 (firmware default) or at least 30 seconds.'**
  String get rsIntervalInvalid;

  /// No description provided for @rsGpsMode.
  ///
  /// In en, this message translates to:
  /// **'GPS mode'**
  String get rsGpsMode;

  /// No description provided for @rsInterval.
  ///
  /// In en, this message translates to:
  /// **'Broadcast interval (seconds, 0 = default)'**
  String get rsInterval;

  /// No description provided for @rsSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart position broadcast'**
  String get rsSmart;

  /// No description provided for @rsSmartSub.
  ///
  /// In en, this message translates to:
  /// **'Send extra updates when the node moves'**
  String get rsSmartSub;

  /// No description provided for @rsFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed position'**
  String get rsFixed;

  /// No description provided for @rsFixedSub.
  ///
  /// In en, this message translates to:
  /// **'Report the last known position instead of GPS'**
  String get rsFixedSub;

  /// No description provided for @rsShareQr.
  ///
  /// In en, this message translates to:
  /// **'Share as QR code'**
  String get rsShareQr;

  /// No description provided for @rsImportLink.
  ///
  /// In en, this message translates to:
  /// **'Import channel link'**
  String get rsImportLink;

  /// No description provided for @rsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get rsDisabled;

  /// No description provided for @rsDefaultName.
  ///
  /// In en, this message translates to:
  /// **'(default name)'**
  String get rsDefaultName;

  /// No description provided for @rsChannelsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read channels: {error}'**
  String rsChannelsFailed(String error);

  /// No description provided for @rsNoEncryption.
  ///
  /// In en, this message translates to:
  /// **'No encryption'**
  String get rsNoEncryption;

  /// No description provided for @rsDefaultKey.
  ///
  /// In en, this message translates to:
  /// **'Default key'**
  String get rsDefaultKey;

  /// No description provided for @rsAes128.
  ///
  /// In en, this message translates to:
  /// **'AES-128 key'**
  String get rsAes128;

  /// No description provided for @rsAes256.
  ///
  /// In en, this message translates to:
  /// **'AES-256 key'**
  String get rsAes256;

  /// No description provided for @rsUnknownKey.
  ///
  /// In en, this message translates to:
  /// **'Unrecognized key'**
  String get rsUnknownKey;

  /// No description provided for @rsChannelN.
  ///
  /// In en, this message translates to:
  /// **'Channel {index}'**
  String rsChannelN(int index);

  /// No description provided for @rsKeyWarning.
  ///
  /// In en, this message translates to:
  /// **'The encryption key changes. Nodes without the new key can no longer read this channel. Share it from the channel QR code.'**
  String get rsKeyWarning;

  /// No description provided for @rsChannelName.
  ///
  /// In en, this message translates to:
  /// **'Name (blank uses the preset name)'**
  String get rsChannelName;

  /// No description provided for @rsEncryption.
  ///
  /// In en, this message translates to:
  /// **'Encryption: {key}'**
  String rsEncryption(String key);

  /// No description provided for @rsNewAes256.
  ///
  /// In en, this message translates to:
  /// **'New random AES-256'**
  String get rsNewAes256;

  /// No description provided for @rsGpsHidden.
  ///
  /// In en, this message translates to:
  /// **'GPS pins are hidden: {model} has its GPS wired by the maker, so they do nothing.'**
  String rsGpsHidden(String model);

  /// No description provided for @bcShareQ.
  ///
  /// In en, this message translates to:
  /// **'Share your primary channel?'**
  String get bcShareQ;

  /// No description provided for @bcShareBody.
  ///
  /// In en, this message translates to:
  /// **'The beacon will include your primary channel\'s name and key. Anyone in range can then join it and read its messages.'**
  String get bcShareBody;

  /// No description provided for @bcShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get bcShare;

  /// No description provided for @bcSent.
  ///
  /// In en, this message translates to:
  /// **'Beacon sent.'**
  String get bcSent;

  /// No description provided for @bcNotSent.
  ///
  /// In en, this message translates to:
  /// **'Beacon not sent: {error}'**
  String bcNotSent(String error);

  /// No description provided for @bcTitle.
  ///
  /// In en, this message translates to:
  /// **'Mesh beacons'**
  String get bcTitle;

  /// No description provided for @bcClear.
  ///
  /// In en, this message translates to:
  /// **'Clear heard beacons'**
  String get bcClear;

  /// No description provided for @bcIntro.
  ///
  /// In en, this message translates to:
  /// **'A beacon is a short broadcast that tells nearby radios a mesh is here, and can invite them to a channel. Radios on the newer Meshtastic firmware show it; NOTORYX Connect shows beacons it hears with any firmware.'**
  String get bcIntro;

  /// No description provided for @bcSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a beacon'**
  String get bcSendTitle;

  /// No description provided for @bcMessage.
  ///
  /// In en, this message translates to:
  /// **'Beacon message'**
  String get bcMessage;

  /// No description provided for @bcMessageHelp.
  ///
  /// In en, this message translates to:
  /// **'Sent on your primary channel. At most one beacon an hour.'**
  String get bcMessageHelp;

  /// No description provided for @bcBytes.
  ///
  /// In en, this message translates to:
  /// **'{used}/{max} bytes'**
  String bcBytes(int used, int max);

  /// No description provided for @bcTooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long'**
  String get bcTooLong;

  /// No description provided for @bcAddLocationNone.
  ///
  /// In en, this message translates to:
  /// **'Add my location (no position yet)'**
  String get bcAddLocationNone;

  /// No description provided for @bcAddLocation.
  ///
  /// In en, this message translates to:
  /// **'Add my location as a Plus Code'**
  String get bcAddLocation;

  /// No description provided for @bcInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite to my primary channel'**
  String get bcInvite;

  /// No description provided for @bcInviteSub.
  ///
  /// In en, this message translates to:
  /// **'Includes the channel name and key, and your region and preset'**
  String get bcInviteSub;

  /// No description provided for @bcSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get bcSending;

  /// No description provided for @bcSend.
  ///
  /// In en, this message translates to:
  /// **'Send beacon'**
  String get bcSend;

  /// No description provided for @bcConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect to a radio to send a beacon.'**
  String get bcConnect;

  /// No description provided for @bcNext.
  ///
  /// In en, this message translates to:
  /// **'Next beacon can be sent at {time}.'**
  String bcNext(String time);

  /// No description provided for @bcHeard.
  ///
  /// In en, this message translates to:
  /// **'Heard beacons'**
  String get bcHeard;

  /// No description provided for @bcNoneHeard.
  ///
  /// In en, this message translates to:
  /// **'No beacons heard yet'**
  String get bcNoneHeard;

  /// No description provided for @bcNoneHeardSub.
  ///
  /// In en, this message translates to:
  /// **'Beacons from radios in range on your channels appear here.'**
  String get bcNoneHeardSub;

  /// No description provided for @bcFrom.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String bcFrom(String name);

  /// No description provided for @bcHeardAt.
  ///
  /// In en, this message translates to:
  /// **'heard {time}'**
  String bcHeardAt(String time);

  /// No description provided for @bcChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel \"{name}\"'**
  String bcChannel(String name);

  /// No description provided for @bcDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get bcDefault;

  /// No description provided for @bcRegion.
  ///
  /// In en, this message translates to:
  /// **'region {name}'**
  String bcRegion(String name);

  /// No description provided for @bcPreset.
  ///
  /// In en, this message translates to:
  /// **'preset {name}'**
  String bcPreset(String name);

  /// No description provided for @bcSlot.
  ///
  /// In en, this message translates to:
  /// **'slot {slot}'**
  String bcSlot(int slot);

  /// No description provided for @bcNoMessage.
  ///
  /// In en, this message translates to:
  /// **'(no message)'**
  String get bcNoMessage;

  /// No description provided for @bcInvitesTo.
  ///
  /// In en, this message translates to:
  /// **'Invites to: {offer}'**
  String bcInvitesTo(String offer);

  /// No description provided for @bcJoin.
  ///
  /// In en, this message translates to:
  /// **'Review and join channel'**
  String get bcJoin;

  /// No description provided for @csShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share channels'**
  String get csShareTitle;

  /// No description provided for @csReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read channels: {error}'**
  String csReadFailed(String error);

  /// No description provided for @csRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get csRetry;

  /// No description provided for @csPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary: {name}'**
  String csPrimary(String name);

  /// No description provided for @csSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary: {name}'**
  String csSecondary(String name);

  /// No description provided for @csDefaultName.
  ///
  /// In en, this message translates to:
  /// **'(default name)'**
  String get csDefaultName;

  /// No description provided for @csCopyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get csCopyLink;

  /// No description provided for @csCopied.
  ///
  /// In en, this message translates to:
  /// **'Channel link copied.'**
  String get csCopied;

  /// No description provided for @csKeysWarning.
  ///
  /// In en, this message translates to:
  /// **'This code contains your channel encryption keys. Anyone who scans it can read and send on these channels.'**
  String get csKeysWarning;

  /// No description provided for @csReplaceQ.
  ///
  /// In en, this message translates to:
  /// **'Replace all channels?'**
  String get csReplaceQ;

  /// No description provided for @csAddQ.
  ///
  /// In en, this message translates to:
  /// **'Add channels?'**
  String get csAddQ;

  /// No description provided for @csReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'All 8 channel slots will be overwritten. You will lose access to current channels unless you have their link. The radio will reboot.'**
  String get csReplaceBody;

  /// No description provided for @csReplaceLoraBody.
  ///
  /// In en, this message translates to:
  /// **'All 8 channel slots and the LoRa settings will be overwritten. You will lose access to current channels unless you have their link. The radio will reboot.'**
  String get csReplaceLoraBody;

  /// No description provided for @csAddBody.
  ///
  /// In en, this message translates to:
  /// **'New channels from the link go into free slots. Existing channels and LoRa settings stay the same.'**
  String get csAddBody;

  /// No description provided for @csApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get csApply;

  /// No description provided for @csAlreadyThere.
  ///
  /// In en, this message translates to:
  /// **'All channels from the link are already on the radio.'**
  String get csAlreadyThere;

  /// No description provided for @csWritten.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} channel written and verified from radio.} other{{count} channels written and verified from radio.}}'**
  String csWritten(int count);

  /// No description provided for @csNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Import not verified: {error}\nNothing will be resent automatically.'**
  String csNotVerified(String error);

  /// No description provided for @csRefused.
  ///
  /// In en, this message translates to:
  /// **'Import refused: {error}'**
  String csRefused(String error);

  /// No description provided for @csFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String csFailed(String error);

  /// No description provided for @csImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import channels'**
  String get csImportTitle;

  /// No description provided for @csScan.
  ///
  /// In en, this message translates to:
  /// **'Scan channel QR code'**
  String get csScan;

  /// No description provided for @csScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan channel QR'**
  String get csScanTitle;

  /// No description provided for @csLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Meshtastic channel link'**
  String get csLinkLabel;

  /// No description provided for @csPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get csPaste;

  /// No description provided for @csLora.
  ///
  /// In en, this message translates to:
  /// **'LoRa: {region}, {modem}'**
  String csLora(String region, String modem);

  /// No description provided for @csCustomModem.
  ///
  /// In en, this message translates to:
  /// **'custom modem'**
  String get csCustomModem;

  /// No description provided for @csAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to radio'**
  String get csAdd;

  /// No description provided for @csReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'Replace all'**
  String get csReplaceAll;

  /// No description provided for @csApplyRadio.
  ///
  /// In en, this message translates to:
  /// **'Apply to radio'**
  String get csApplyRadio;

  /// No description provided for @trTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan your trip'**
  String get trTitle;

  /// No description provided for @trName.
  ///
  /// In en, this message translates to:
  /// **'Trip name'**
  String get trName;

  /// No description provided for @trContacts.
  ///
  /// In en, this message translates to:
  /// **'TRIP CONTACTS ({count}/{max})'**
  String trContacts(int count, int max);

  /// No description provided for @trContactsSub.
  ///
  /// In en, this message translates to:
  /// **'Check-ins and SOS go to each of them as a direct message.'**
  String get trContactsSub;

  /// No description provided for @trNoNodes.
  ///
  /// In en, this message translates to:
  /// **'No nodes yet'**
  String get trNoNodes;

  /// No description provided for @trNoNodesSub.
  ///
  /// In en, this message translates to:
  /// **'Connect to your radio so nearby nodes and favorites appear here.'**
  String get trNoNodesSub;

  /// No description provided for @trOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue alert'**
  String get trOverdue;

  /// No description provided for @trOverdueHelp.
  ///
  /// In en, this message translates to:
  /// **'Warns you when a trip contact has not been heard for this long'**
  String get trOverdueHelp;

  /// No description provided for @trOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get trOff;

  /// No description provided for @trMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String trMinutes(int count);

  /// No description provided for @trHours.
  ///
  /// In en, this message translates to:
  /// **'{count} h'**
  String trHours(int count);

  /// No description provided for @trReminder.
  ///
  /// In en, this message translates to:
  /// **'Check-in reminder'**
  String get trReminder;

  /// No description provided for @trReminderHelp.
  ///
  /// In en, this message translates to:
  /// **'Reminds you to check in this long after your last check-in'**
  String get trReminderHelp;

  /// No description provided for @trEvery.
  ///
  /// In en, this message translates to:
  /// **'Every {time}'**
  String trEvery(String time);

  /// No description provided for @trSosChannel.
  ///
  /// In en, this message translates to:
  /// **'Also send SOS on a channel'**
  String get trSosChannel;

  /// No description provided for @trSosChannelHelp.
  ///
  /// In en, this message translates to:
  /// **'Everyone on that channel sees your SOS, not just trip contacts'**
  String get trSosChannelHelp;

  /// No description provided for @trContactsOnly.
  ///
  /// In en, this message translates to:
  /// **'No, trip contacts only'**
  String get trContactsOnly;

  /// No description provided for @trChannelItem.
  ///
  /// In en, this message translates to:
  /// **'Channel {index} • {name}'**
  String trChannelItem(int index, String name);

  /// No description provided for @trDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get trDefault;

  /// No description provided for @trReadiness.
  ///
  /// In en, this message translates to:
  /// **'Readiness check'**
  String get trReadiness;

  /// No description provided for @trEnd.
  ///
  /// In en, this message translates to:
  /// **'End trip'**
  String get trEnd;

  /// No description provided for @trStart.
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get trStart;

  /// No description provided for @trRunning.
  ///
  /// In en, this message translates to:
  /// **'Trip running since {time}. Overdue alerts and reminders are on.'**
  String trRunning(String time);

  /// No description provided for @trNotRunning.
  ///
  /// In en, this message translates to:
  /// **'Starting the trip turns on overdue alerts and check-in reminders. Check-ins and SOS work any time.'**
  String get trNotRunning;

  /// No description provided for @pvEncryptedOn.
  ///
  /// In en, this message translates to:
  /// **'Chat history is now encrypted.'**
  String get pvEncryptedOn;

  /// No description provided for @pvEncryptedOff.
  ///
  /// In en, this message translates to:
  /// **'Chat history is no longer encrypted.'**
  String get pvEncryptedOff;

  /// No description provided for @pvLockOnReason.
  ///
  /// In en, this message translates to:
  /// **'Turn on app lock'**
  String get pvLockOnReason;

  /// No description provided for @pvLockOffReason.
  ///
  /// In en, this message translates to:
  /// **'Turn off app lock'**
  String get pvLockOffReason;

  /// No description provided for @pvLockUnchanged.
  ///
  /// In en, this message translates to:
  /// **'App lock was not changed.'**
  String get pvLockUnchanged;

  /// No description provided for @pvStored1.
  ///
  /// In en, this message translates to:
  /// **'Chat history and offline queues for each radio (newest 500 messages per radio)'**
  String get pvStored1;

  /// No description provided for @pvStored2.
  ///
  /// In en, this message translates to:
  /// **'NodeDex: nodes your radios have heard, plus your favorites and notes'**
  String get pvStored2;

  /// No description provided for @pvStored3.
  ///
  /// In en, this message translates to:
  /// **'Waypoints received from the mesh'**
  String get pvStored3;

  /// No description provided for @pvStored4.
  ///
  /// In en, this message translates to:
  /// **'Incident log and coverage records, only if you create them'**
  String get pvStored4;

  /// No description provided for @pvStored5.
  ///
  /// In en, this message translates to:
  /// **'Field alert, bot, location and appearance settings'**
  String get pvStored5;

  /// No description provided for @pvStored6.
  ///
  /// In en, this message translates to:
  /// **'Map tiles for areas you have viewed'**
  String get pvStored6;

  /// No description provided for @pvSent1.
  ///
  /// In en, this message translates to:
  /// **'Messages you send go to your radio, which transmits them on the mesh using the channel\'s encryption key'**
  String get pvSent1;

  /// No description provided for @pvSent2.
  ///
  /// In en, this message translates to:
  /// **'Your phone location, only while \"Share phone location\" is on, at the precision you choose'**
  String get pvSent2;

  /// No description provided for @pvSent3.
  ///
  /// In en, this message translates to:
  /// **'Position, telemetry and traceroute requests that you start'**
  String get pvSent3;

  /// No description provided for @pvSent4.
  ///
  /// In en, this message translates to:
  /// **'Map tile requests to OpenStreetMap servers when you view the map; they see your IP address'**
  String get pvSent4;

  /// No description provided for @pvSent5.
  ///
  /// In en, this message translates to:
  /// **'Topographic map tile requests to OpenTopoMap servers, only while the topo map is shown; they see your IP address'**
  String get pvSent5;

  /// No description provided for @pvSent6.
  ///
  /// In en, this message translates to:
  /// **'Points along a link to the Open-Meteo elevation service, only when you check a link in the Link planner'**
  String get pvSent6;

  /// No description provided for @pvDisconnectFirst.
  ///
  /// In en, this message translates to:
  /// **'Disconnect the radio before deleting phone data.'**
  String get pvDisconnectFirst;

  /// No description provided for @pvDeleteAllQ.
  ///
  /// In en, this message translates to:
  /// **'Delete all phone data?'**
  String get pvDeleteAllQ;

  /// No description provided for @pvDeleteChatsQ.
  ///
  /// In en, this message translates to:
  /// **'Delete chat history?'**
  String get pvDeleteChatsQ;

  /// No description provided for @pvDeleteAllBody.
  ///
  /// In en, this message translates to:
  /// **'Deletes chats and offline queues for every radio, NodeDex, favorites and notes, waypoints, field records, cached map tiles and all app settings from this phone. Radio settings are not changed. This cannot be undone; make a phone data backup first if you may need it.\n\nThe app closes afterwards.'**
  String get pvDeleteAllBody;

  /// No description provided for @pvDeleteChatsBody.
  ///
  /// In en, this message translates to:
  /// **'Deletes chat history and queued messages for every radio from this phone. Messages already sent on the mesh are not affected. This cannot be undone.\n\nThe app closes afterwards.'**
  String get pvDeleteChatsBody;

  /// No description provided for @pvDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get pvDelete;

  /// No description provided for @pvDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String pvDeleteFailed(String error);

  /// No description provided for @pvDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get pvDeleted;

  /// No description provided for @pvDeletedBody.
  ///
  /// In en, this message translates to:
  /// **'NOTORYX Connect will close now so nothing still in memory is saved again.'**
  String get pvDeletedBody;

  /// No description provided for @pvCloseApp.
  ///
  /// In en, this message translates to:
  /// **'Close app'**
  String get pvCloseApp;

  /// No description provided for @pvTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get pvTitle;

  /// No description provided for @pvIntro.
  ///
  /// In en, this message translates to:
  /// **'NOTORYX Connect has no account, analytics, ads or servers of its own. Everything it keeps stays in this app\'s private storage on your phone and is removed if you uninstall it.'**
  String get pvIntro;

  /// No description provided for @pvAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get pvAppLock;

  /// No description provided for @pvAppLockSub.
  ///
  /// In en, this message translates to:
  /// **'Ask for your fingerprint, face or screen lock when opening the app, and after a minute away. You will also need it to reach SOS. The radio stays connected.'**
  String get pvAppLockSub;

  /// No description provided for @pvAppLockNone.
  ///
  /// In en, this message translates to:
  /// **'Set a screen lock on this phone to use app lock.'**
  String get pvAppLockNone;

  /// No description provided for @pvEncrypt.
  ///
  /// In en, this message translates to:
  /// **'Encrypt chat history'**
  String get pvEncrypt;

  /// No description provided for @pvEncryptSub.
  ///
  /// In en, this message translates to:
  /// **'Scrambles saved messages using a key held in this phone\'s secure storage. If that key is lost, for example after moving to a new phone, the saved history can\'t be read. Export anything you need first.'**
  String get pvEncryptSub;

  /// No description provided for @pvStored.
  ///
  /// In en, this message translates to:
  /// **'Stored on this phone'**
  String get pvStored;

  /// No description provided for @pvSent.
  ///
  /// In en, this message translates to:
  /// **'Sent off this phone'**
  String get pvSent;

  /// No description provided for @pvDeleteChats.
  ///
  /// In en, this message translates to:
  /// **'Delete chat history'**
  String get pvDeleteChats;

  /// No description provided for @pvDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all phone data'**
  String get pvDeleteAll;

  /// No description provided for @pbFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String pbFailed(String error);

  /// No description provided for @pbShortPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters for the backup password.'**
  String get pbShortPassword;

  /// No description provided for @pbCreated.
  ///
  /// In en, this message translates to:
  /// **'Backup created. Save the file somewhere off this phone. Keep the password separately; it cannot be recovered.'**
  String get pbCreated;

  /// No description provided for @pbDisconnectFirst.
  ///
  /// In en, this message translates to:
  /// **'Disconnect the radio before restoring phone data.'**
  String get pbDisconnectFirst;

  /// No description provided for @pbReplaceQ.
  ///
  /// In en, this message translates to:
  /// **'Replace all phone data?'**
  String get pbReplaceQ;

  /// No description provided for @pbSummary.
  ///
  /// In en, this message translates to:
  /// **'Backup created {date} by version {version}.\n\nIt has chat history for {radios, plural, one{{radios} radio} other{{radios} radios}} ({messages} messages) and {items} saved items in all.\n\nEverything NOTORYX Connect stores on this phone (chats, offline queues, NodeDex, waypoints, field records and settings) is replaced. Radio settings are not changed. The app closes when the restore finishes; open it again to continue.'**
  String pbSummary(
    String date,
    String version,
    int radios,
    int messages,
    int items,
  );

  /// No description provided for @pbReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace phone data'**
  String get pbReplace;

  /// No description provided for @pbRestored.
  ///
  /// In en, this message translates to:
  /// **'Restore complete'**
  String get pbRestored;

  /// No description provided for @pbRestoredBody.
  ///
  /// In en, this message translates to:
  /// **'NOTORYX Connect will close now so nothing still in memory overwrites the restored data. Open it again to continue.'**
  String get pbRestoredBody;

  /// No description provided for @pbTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone data backup'**
  String get pbTitle;

  /// No description provided for @pbIntro.
  ///
  /// In en, this message translates to:
  /// **'Backs up everything NOTORYX Connect stores on this phone: chat history and offline queues for every radio, NodeDex favorites and notes, waypoints, field records and app settings. Use it to move to a new phone. The file is encrypted with your password. Radio settings have their own backup.'**
  String get pbIntro;

  /// No description provided for @pbPassword.
  ///
  /// In en, this message translates to:
  /// **'Backup password (at least 12 characters)'**
  String get pbPassword;

  /// No description provided for @pbCreate.
  ///
  /// In en, this message translates to:
  /// **'Create backup file'**
  String get pbCreate;

  /// No description provided for @pbRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from file'**
  String get pbRestore;

  /// No description provided for @rbFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed. If a restore had started, settings may be partially changed. Reconnect and check the radio before retrying.'**
  String get rbFailed;

  /// No description provided for @rbReady.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup ready. Copy it and save it in a text file. Keep the password separately; it cannot be recovered.'**
  String get rbReady;

  /// No description provided for @rbReplaceQ.
  ///
  /// In en, this message translates to:
  /// **'Replace radio settings?'**
  String get rbReplaceQ;

  /// No description provided for @rbSummary.
  ///
  /// In en, this message translates to:
  /// **'Backup from radio {source} (firmware {firmware}), created {date}.\n\nTarget: {target}. Replaces owner names, all 8 channel slots including their secret keys, {configs} configuration sections and {modules} modules. Device identity/security keys, session credentials, phone chats and maps are not restored (use Phone data backup for those).\n\nSave a backup of the target first. The radio may reboot or lose mesh connectivity. A radio write cannot guarantee rollback after a power or connection failure.'**
  String rbSummary(
    String source,
    String firmware,
    String date,
    String target,
    int configs,
    int modules,
  );

  /// No description provided for @rbReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace settings'**
  String get rbReplace;

  /// No description provided for @rbRadioChanged.
  ///
  /// In en, this message translates to:
  /// **'Connected radio changed.'**
  String get rbRadioChanged;

  /// No description provided for @rbRestored.
  ///
  /// In en, this message translates to:
  /// **'Restore complete. Fresh radio readback matches the backup.'**
  String get rbRestored;

  /// No description provided for @rbTitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted radio backup'**
  String get rbTitle;

  /// No description provided for @rbIntro.
  ///
  /// In en, this message translates to:
  /// **'Backs up fresh radio configuration and modules reported by the firmware, all channel slots and owner names. Channel keys and any network/module credentials are password encrypted. Device identity keys and session credentials are excluded.'**
  String get rbIntro;

  /// No description provided for @rbCreate.
  ///
  /// In en, this message translates to:
  /// **'Create encrypted backup'**
  String get rbCreate;

  /// No description provided for @rbText.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup text'**
  String get rbText;

  /// No description provided for @rbTextHint.
  ///
  /// In en, this message translates to:
  /// **'Paste a saved encrypted backup to restore'**
  String get rbTextHint;

  /// No description provided for @rbCopied.
  ///
  /// In en, this message translates to:
  /// **'Encrypted backup copied. Save it in a text file.'**
  String get rbCopied;

  /// No description provided for @rbCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy encrypted backup'**
  String get rbCopy;

  /// No description provided for @rbReview.
  ///
  /// In en, this message translates to:
  /// **'Review and restore'**
  String get rbReview;

  /// No description provided for @raPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get raPower;

  /// No description provided for @raDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get raDisplay;

  /// No description provided for @raLoraQ.
  ///
  /// In en, this message translates to:
  /// **'Change LoRa settings remotely?'**
  String get raLoraQ;

  /// No description provided for @raLoraBody.
  ///
  /// In en, this message translates to:
  /// **'If the node ends up on a different region, preset or frequency from the rest of the mesh, it can no longer be reached and someone will have to fix it in person.'**
  String get raLoraBody;

  /// No description provided for @raSaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get raSaveAnyway;

  /// No description provided for @raSent.
  ///
  /// In en, this message translates to:
  /// **'{section} settings sent. The node may restart to apply them.'**
  String raSent(String section);

  /// No description provided for @raNameSent.
  ///
  /// In en, this message translates to:
  /// **'Name sent to the node.'**
  String get raNameSent;

  /// No description provided for @raRestartQ.
  ///
  /// In en, this message translates to:
  /// **'Restart {name}?'**
  String raRestartQ(String name);

  /// No description provided for @raRestartBody.
  ///
  /// In en, this message translates to:
  /// **'The node goes off the mesh for a short while as it restarts.'**
  String get raRestartBody;

  /// No description provided for @raRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get raRestart;

  /// No description provided for @raRestartRequested.
  ///
  /// In en, this message translates to:
  /// **'Restart requested.'**
  String get raRestartRequested;

  /// No description provided for @raDiscardQ.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get raDiscardQ;

  /// No description provided for @raDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits haven\'t been sent to the node.'**
  String get raDiscardBody;

  /// No description provided for @raDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get raDiscard;

  /// No description provided for @raTitle.
  ///
  /// In en, this message translates to:
  /// **'Remote admin'**
  String get raTitle;

  /// No description provided for @raIntro.
  ///
  /// In en, this message translates to:
  /// **'Change this node\'s settings over the mesh. Each request uses airtime and can take up to a minute.'**
  String get raIntro;

  /// No description provided for @raUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Remote admin isn\'t available'**
  String get raUnavailable;

  /// No description provided for @raWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the node'**
  String get raWaiting;

  /// No description provided for @raAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get raAccess;

  /// No description provided for @raAccessHint.
  ///
  /// In en, this message translates to:
  /// **'Ask the node for its details. If it answers, your radio is allowed to manage it.'**
  String get raAccessHint;

  /// No description provided for @raCheckAccess.
  ///
  /// In en, this message translates to:
  /// **'Check access'**
  String get raCheckAccess;

  /// No description provided for @raAccessConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Access confirmed'**
  String get raAccessConfirmed;

  /// No description provided for @raFirmware.
  ///
  /// In en, this message translates to:
  /// **'Firmware {version} · {role}'**
  String raFirmware(String version, String role);

  /// No description provided for @raUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get raUnknown;

  /// No description provided for @raNoName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get raNoName;

  /// No description provided for @raShortName.
  ///
  /// In en, this message translates to:
  /// **'Short name {name}'**
  String raShortName(String name);

  /// No description provided for @raRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get raRename;

  /// No description provided for @raRestartNode.
  ///
  /// In en, this message translates to:
  /// **'Restart node'**
  String get raRestartNode;

  /// No description provided for @raSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get raSettings;

  /// No description provided for @raLoraWarning.
  ///
  /// In en, this message translates to:
  /// **'A wrong LoRa setting can cut this node off the mesh. Change it only if you can reach the node in person.'**
  String get raLoraWarning;

  /// No description provided for @raSend.
  ///
  /// In en, this message translates to:
  /// **'Send {section} settings'**
  String raSend(String section);

  /// No description provided for @raUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get raUndo;

  /// No description provided for @raKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your radio\'s admin key'**
  String get raKeyTitle;

  /// No description provided for @raKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Before {name} will accept changes, its owner adds this key under Radio settings → Security → Admin key, using any Meshtastic app.'**
  String raKeyBody(String name);

  /// No description provided for @raNoKey.
  ///
  /// In en, this message translates to:
  /// **'Your radio hasn\'t reported its key yet.'**
  String get raNoKey;

  /// No description provided for @raCopyKey.
  ///
  /// In en, this message translates to:
  /// **'Copy admin key'**
  String get raCopyKey;

  /// No description provided for @raKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Admin key copied.'**
  String get raKeyCopied;

  /// No description provided for @raRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename node'**
  String get raRenameTitle;

  /// No description provided for @raSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get raSendButton;

  /// No description provided for @frSaluteTitle.
  ///
  /// In en, this message translates to:
  /// **'SALUTE report'**
  String get frSaluteTitle;

  /// No description provided for @frNineTitle.
  ///
  /// In en, this message translates to:
  /// **'9-Line medical evacuation'**
  String get frNineTitle;

  /// No description provided for @frSaluteS.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get frSaluteS;

  /// No description provided for @frSaluteSHint.
  ///
  /// In en, this message translates to:
  /// **'How many people or vehicles'**
  String get frSaluteSHint;

  /// No description provided for @frSaluteA.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get frSaluteA;

  /// No description provided for @frSaluteAHint.
  ///
  /// In en, this message translates to:
  /// **'What they are doing'**
  String get frSaluteAHint;

  /// No description provided for @frSaluteL.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get frSaluteL;

  /// No description provided for @frSaluteLHint.
  ///
  /// In en, this message translates to:
  /// **'Where they are'**
  String get frSaluteLHint;

  /// No description provided for @frSaluteU.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get frSaluteU;

  /// No description provided for @frSaluteUHint.
  ///
  /// In en, this message translates to:
  /// **'Who they are, uniform or markings'**
  String get frSaluteUHint;

  /// No description provided for @frSaluteT.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get frSaluteT;

  /// No description provided for @frSaluteTHint.
  ///
  /// In en, this message translates to:
  /// **'When you saw them'**
  String get frSaluteTHint;

  /// No description provided for @frSaluteE.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get frSaluteE;

  /// No description provided for @frSaluteEHint.
  ///
  /// In en, this message translates to:
  /// **'What they have with them'**
  String get frSaluteEHint;

  /// No description provided for @frNine1.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get frNine1;

  /// No description provided for @frNine1Hint.
  ///
  /// In en, this message translates to:
  /// **'Coordinates or landmark'**
  String get frNine1Hint;

  /// No description provided for @frNine2.
  ///
  /// In en, this message translates to:
  /// **'Radio frequency and callsign'**
  String get frNine2;

  /// No description provided for @frNine2Hint.
  ///
  /// In en, this message translates to:
  /// **'How to reach you'**
  String get frNine2Hint;

  /// No description provided for @frNine3.
  ///
  /// In en, this message translates to:
  /// **'Patients by urgency'**
  String get frNine3;

  /// No description provided for @frNine3Hint.
  ///
  /// In en, this message translates to:
  /// **'For example 1 urgent, 2 routine'**
  String get frNine3Hint;

  /// No description provided for @frNine4.
  ///
  /// In en, this message translates to:
  /// **'Special equipment'**
  String get frNine4;

  /// No description provided for @frNine4Hint.
  ///
  /// In en, this message translates to:
  /// **'None, hoist, extraction, ventilator'**
  String get frNine4Hint;

  /// No description provided for @frNine5.
  ///
  /// In en, this message translates to:
  /// **'Patients by type'**
  String get frNine5;

  /// No description provided for @frNine5Hint.
  ///
  /// In en, this message translates to:
  /// **'Litter or walking'**
  String get frNine5Hint;

  /// No description provided for @frNine6.
  ///
  /// In en, this message translates to:
  /// **'Security at pickup'**
  String get frNine6;

  /// No description provided for @frNine6Hint.
  ///
  /// In en, this message translates to:
  /// **'No threat, possible, or armed escort'**
  String get frNine6Hint;

  /// No description provided for @frNine7.
  ///
  /// In en, this message translates to:
  /// **'How the site is marked'**
  String get frNine7;

  /// No description provided for @frNine7Hint.
  ///
  /// In en, this message translates to:
  /// **'Panel, smoke, light, or none'**
  String get frNine7Hint;

  /// No description provided for @frNine8.
  ///
  /// In en, this message translates to:
  /// **'Patient status'**
  String get frNine8;

  /// No description provided for @frNine8Hint.
  ///
  /// In en, this message translates to:
  /// **'Who the patients are'**
  String get frNine8Hint;

  /// No description provided for @frNine9.
  ///
  /// In en, this message translates to:
  /// **'Hazards and terrain'**
  String get frNine9;

  /// No description provided for @frNine9Hint.
  ///
  /// In en, this message translates to:
  /// **'Slope, wires, contamination'**
  String get frNine9Hint;

  /// No description provided for @svcConnectToCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Connect to a radio to check in.'**
  String get svcConnectToCheckIn;

  /// No description provided for @svcChooseContacts.
  ///
  /// In en, this message translates to:
  /// **'Choose trip contacts first.'**
  String get svcChooseContacts;

  /// No description provided for @svcConnectToSos.
  ///
  /// In en, this message translates to:
  /// **'Connect to a radio to send an SOS.'**
  String get svcConnectToSos;

  /// No description provided for @svcChooseSosTargets.
  ///
  /// In en, this message translates to:
  /// **'Choose trip contacts or an SOS channel first.'**
  String get svcChooseSosTargets;

  /// No description provided for @svcFirmwareUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Your radio runs firmware {version}. NOTORYX Connect needs {minimum} or newer to change radio settings, so settings are read-only. Messages still work. Update at {url}.'**
  String svcFirmwareUnsupported(String version, String minimum, String url);

  /// No description provided for @svcFirmwareOutdated.
  ///
  /// In en, this message translates to:
  /// **'Your radio runs firmware {version}. Updating to {recommended} or newer at {url} turns on newer features such as sensor readings and security key checks.'**
  String svcFirmwareOutdated(String version, String recommended, String url);

  /// No description provided for @svcToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get svcToday;

  /// No description provided for @svcYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get svcYesterday;

  /// No description provided for @svcLowBatteryOwn.
  ///
  /// In en, this message translates to:
  /// **'Your radio battery is low'**
  String get svcLowBatteryOwn;

  /// No description provided for @svcLowBattery.
  ///
  /// In en, this message translates to:
  /// **'{name} battery is low'**
  String svcLowBattery(String name);

  /// No description provided for @svcLowBatteryOwnBody.
  ///
  /// In en, this message translates to:
  /// **'Your radio reports {level}% battery.'**
  String svcLowBatteryOwnBody(int level);

  /// No description provided for @svcLowBatteryBody.
  ///
  /// In en, this message translates to:
  /// **'{name} reports {level}% battery.'**
  String svcLowBatteryBody(String name, int level);

  /// No description provided for @svcNewNode.
  ///
  /// In en, this message translates to:
  /// **'New node: {name}'**
  String svcNewNode(String name);

  /// No description provided for @svcNewNodeBody.
  ///
  /// In en, this message translates to:
  /// **'Your radio heard {name} for the first time.'**
  String svcNewNodeBody(String name);

  /// No description provided for @svcMeshQuieter.
  ///
  /// In en, this message translates to:
  /// **'The mesh has gone quieter'**
  String get svcMeshQuieter;

  /// No description provided for @svcMeshQuieterBody.
  ///
  /// In en, this message translates to:
  /// **'Heard {active} nodes in the last hour, down from {peak}. A repeater may be down, or you may have moved out of range.'**
  String svcMeshQuieterBody(int active, int peak);

  /// No description provided for @svcQuiet.
  ///
  /// In en, this message translates to:
  /// **'{name} has gone quiet'**
  String svcQuiet(String name);

  /// No description provided for @svcQuietBody.
  ///
  /// In en, this message translates to:
  /// **'Not heard for {time}.'**
  String svcQuietBody(String time);

  /// No description provided for @svcHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String svcHoursMinutes(int hours, int minutes);

  /// No description provided for @svcMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String svcMinutes(int minutes);

  /// No description provided for @svcReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get svcReply;

  /// No description provided for @svcDirectChannel.
  ///
  /// In en, this message translates to:
  /// **'Direct messages'**
  String get svcDirectChannel;

  /// No description provided for @svcDirectChannelSub.
  ///
  /// In en, this message translates to:
  /// **'Messages sent to you on the mesh.'**
  String get svcDirectChannelSub;

  /// No description provided for @svcChannelChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel messages'**
  String get svcChannelChannel;

  /// No description provided for @svcChannelChannelSub.
  ///
  /// In en, this message translates to:
  /// **'Messages on your mesh channels.'**
  String get svcChannelChannelSub;

  /// No description provided for @svcFieldChannel.
  ///
  /// In en, this message translates to:
  /// **'Field alerts'**
  String get svcFieldChannel;

  /// No description provided for @svcFieldChannelSub.
  ///
  /// In en, this message translates to:
  /// **'Low battery, new nodes and favorites that go quiet.'**
  String get svcFieldChannelSub;

  /// No description provided for @svcFromChannel.
  ///
  /// In en, this message translates to:
  /// **'{sender} • channel {channel}'**
  String svcFromChannel(String sender, int channel);

  /// No description provided for @mapHeatSummary.
  ///
  /// In en, this message translates to:
  /// **'Coverage map: {strong} strong, {fair} fair, {weak} weak areas, from {readings} readings.'**
  String mapHeatSummary(int strong, int fair, int weak, int readings);

  /// No description provided for @nrTitle.
  ///
  /// In en, this message translates to:
  /// **'Moving to a new radio'**
  String get nrTitle;

  /// No description provided for @nrSub.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String nrSub(int done, int total);

  /// No description provided for @nrStep1.
  ///
  /// In en, this message translates to:
  /// **'With the old radio connected, create an encrypted backup here and save the text somewhere safe.'**
  String get nrStep1;

  /// No description provided for @nrStep2.
  ///
  /// In en, this message translates to:
  /// **'Write down the old radio\'s region and modem preset (Radio settings → LoRa).'**
  String get nrStep2;

  /// No description provided for @nrStep3.
  ///
  /// In en, this message translates to:
  /// **'Update the new radio\'s firmware to the same version or newer.'**
  String get nrStep3;

  /// No description provided for @nrStep4.
  ///
  /// In en, this message translates to:
  /// **'Connect the new radio and set its region before anything else, so it may transmit.'**
  String get nrStep4;

  /// No description provided for @nrStep5.
  ///
  /// In en, this message translates to:
  /// **'Paste the backup, review it and restore. Use the same password.'**
  String get nrStep5;

  /// No description provided for @nrStep6.
  ///
  /// In en, this message translates to:
  /// **'Check Channels: names and keys should match, and send a test message to someone on each channel.'**
  String get nrStep6;

  /// No description provided for @nrStep7.
  ///
  /// In en, this message translates to:
  /// **'The new radio has its own node ID and security key. Tell your contacts, and re-add it as an admin on any nodes you manage remotely.'**
  String get nrStep7;

  /// No description provided for @nrReset.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get nrReset;

  /// No description provided for @cpLabel.
  ///
  /// In en, this message translates to:
  /// **'Position shared on this channel'**
  String get cpLabel;

  /// No description provided for @cpHelp.
  ///
  /// In en, this message translates to:
  /// **'How exact your radio\'s position is when sent on this channel. Other channels keep their own setting.'**
  String get cpHelp;

  /// No description provided for @cpNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set: the firmware decides'**
  String get cpNotSet;

  /// No description provided for @cpNone.
  ///
  /// In en, this message translates to:
  /// **'Don\'t share position'**
  String get cpNone;

  /// No description provided for @cpExact.
  ///
  /// In en, this message translates to:
  /// **'Exact position'**
  String get cpExact;

  /// No description provided for @cpWithin.
  ///
  /// In en, this message translates to:
  /// **'Within about {distance}'**
  String cpWithin(String distance);

  /// No description provided for @rdBattery.
  ///
  /// In en, this message translates to:
  /// **'Radio battery'**
  String get rdBattery;

  /// No description provided for @rdNotReported.
  ///
  /// In en, this message translates to:
  /// **'Not reported yet.'**
  String get rdNotReported;

  /// No description provided for @rdExternal.
  ///
  /// In en, this message translates to:
  /// **'On external power.'**
  String get rdExternal;

  /// No description provided for @rdChargeNow.
  ///
  /// In en, this message translates to:
  /// **'{level}%. Charge the radio before you leave.'**
  String rdChargeNow(int level);

  /// No description provided for @rdChargeSoon.
  ///
  /// In en, this message translates to:
  /// **'{level}%. Consider charging or bringing a power bank.'**
  String rdChargeSoon(int level);

  /// No description provided for @rdLevel.
  ///
  /// In en, this message translates to:
  /// **'{level}%.'**
  String rdLevel(int level);

  /// No description provided for @rdFirmware.
  ///
  /// In en, this message translates to:
  /// **'Firmware'**
  String get rdFirmware;

  /// No description provided for @rdConnectToCheck.
  ///
  /// In en, this message translates to:
  /// **'Connect your radio to check.'**
  String get rdConnectToCheck;

  /// No description provided for @rdTooOld.
  ///
  /// In en, this message translates to:
  /// **'Too old.'**
  String get rdTooOld;

  /// No description provided for @rdUpdateRecommended.
  ///
  /// In en, this message translates to:
  /// **'Update recommended.'**
  String get rdUpdateRecommended;

  /// No description provided for @rdVersionUnknown.
  ///
  /// In en, this message translates to:
  /// **'Version not reported.'**
  String get rdVersionUnknown;

  /// No description provided for @rdSupported.
  ///
  /// In en, this message translates to:
  /// **'Supported.'**
  String get rdSupported;

  /// No description provided for @rdChannels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get rdChannels;

  /// No description provided for @rdNoChannels.
  ///
  /// In en, this message translates to:
  /// **'No channels on this radio.'**
  String get rdNoChannels;

  /// No description provided for @rdSosChannelGone.
  ///
  /// In en, this message translates to:
  /// **'SOS channel {channel} no longer exists. Pick another in your trip plan.'**
  String rdSosChannelGone(int channel);

  /// No description provided for @rdChannelsSet.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} channel set up.} other{{count} channels set up.}}'**
  String rdChannelsSet(int count);

  /// No description provided for @rdContacts.
  ///
  /// In en, this message translates to:
  /// **'Trip contacts'**
  String get rdContacts;

  /// No description provided for @rdChooseContacts.
  ///
  /// In en, this message translates to:
  /// **'Choose who gets your check-ins and SOS.'**
  String get rdChooseContacts;

  /// No description provided for @rdNoRoute.
  ///
  /// In en, this message translates to:
  /// **'No route to {names}.'**
  String rdNoRoute(String names);

  /// No description provided for @rdNotHeard.
  ///
  /// In en, this message translates to:
  /// **'Not heard in the last 2 hours: {names}. Run a route test, or check they\'re on.'**
  String rdNotHeard(String names);

  /// No description provided for @rdAllHeard.
  ///
  /// In en, this message translates to:
  /// **'All {count} heard recently.'**
  String rdAllHeard(int count);

  /// No description provided for @rdPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get rdPosition;

  /// No description provided for @rdRecentPosition.
  ///
  /// In en, this message translates to:
  /// **'Your radio has a recent position.'**
  String get rdRecentPosition;

  /// No description provided for @rdWaitingPhone.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a position from this phone. Check location is on.'**
  String get rdWaitingPhone;

  /// No description provided for @rdNoPosition.
  ///
  /// In en, this message translates to:
  /// **'No recent position, so others can\'t see where you are. Turn on the radio\'s GPS or share this phone\'s location.'**
  String get rdNoPosition;

  /// No description provided for @rdBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get rdBackground;

  /// No description provided for @rdBackgroundRestricted.
  ///
  /// In en, this message translates to:
  /// **'Battery optimisation can cut the link with the screen off. Set NOTORYX Connect to \"Unrestricted\".'**
  String get rdBackgroundRestricted;

  /// No description provided for @rdBackgroundOk.
  ///
  /// In en, this message translates to:
  /// **'The app can stay connected with the screen off.'**
  String get rdBackgroundOk;

  /// No description provided for @rdCouldntCheck.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check.'**
  String get rdCouldntCheck;

  /// No description provided for @rpTitle.
  ///
  /// In en, this message translates to:
  /// **'Readiness check'**
  String get rpTitle;

  /// No description provided for @rpReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to go'**
  String get rpReady;

  /// No description provided for @rpCheck.
  ///
  /// In en, this message translates to:
  /// **'Check these before you leave'**
  String get rpCheck;

  /// No description provided for @rpNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not ready yet'**
  String get rpNotReady;

  /// No description provided for @rpNeedRadio.
  ///
  /// In en, this message translates to:
  /// **'Some checks need your radio'**
  String get rpNeedRadio;

  /// No description provided for @rpNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Sent or queued does not mean received. Agree a backup plan.'**
  String get rpNotReceived;

  /// No description provided for @rpTestRoute.
  ///
  /// In en, this message translates to:
  /// **'Test a route'**
  String get rpTestRoute;

  /// No description provided for @rpTestHint.
  ///
  /// In en, this message translates to:
  /// **'Sends one route request to that contact. Use sparingly on busy meshes.'**
  String get rpTestHint;

  /// No description provided for @rpRouteFound.
  ///
  /// In en, this message translates to:
  /// **'Route found'**
  String get rpRouteFound;

  /// No description provided for @rpNoRoute.
  ///
  /// In en, this message translates to:
  /// **'No route found'**
  String get rpNoRoute;

  /// No description provided for @rpNotTested.
  ///
  /// In en, this message translates to:
  /// **'Not tested'**
  String get rpNotTested;

  /// No description provided for @rpTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get rpTest;

  /// No description provided for @rpStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get rpStatusReady;

  /// No description provided for @rpStatusCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get rpStatusCheck;

  /// No description provided for @rpStatusFix.
  ///
  /// In en, this message translates to:
  /// **'Fix first'**
  String get rpStatusFix;

  /// No description provided for @rpStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get rpStatusUnknown;

  /// No description provided for @cdFixBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Turn on Bluetooth'**
  String get cdFixBluetooth;

  /// No description provided for @cdFixPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow Bluetooth access'**
  String get cdFixPermission;

  /// No description provided for @cdFixBattery.
  ///
  /// In en, this message translates to:
  /// **'Open battery settings'**
  String get cdFixBattery;

  /// No description provided for @cdFixRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get cdFixRetry;

  /// No description provided for @cdFixScan.
  ///
  /// In en, this message translates to:
  /// **'Scan for radios'**
  String get cdFixScan;

  /// No description provided for @cdFixFirmware.
  ///
  /// In en, this message translates to:
  /// **'How to update'**
  String get cdFixFirmware;

  /// No description provided for @cdTheRadio.
  ///
  /// In en, this message translates to:
  /// **'the radio'**
  String get cdTheRadio;

  /// No description provided for @cdYourRadio.
  ///
  /// In en, this message translates to:
  /// **'your radio'**
  String get cdYourRadio;

  /// No description provided for @cdBluetoothOffDetail.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off. Turn it on and the app reconnects by itself.'**
  String get cdBluetoothOffDetail;

  /// No description provided for @cdPermissionDetail.
  ///
  /// In en, this message translates to:
  /// **'The app isn\'t allowed to use Bluetooth. Allow \"Nearby devices\" when asked, or in Android Settings → Apps → NOTORYX Connect → Permissions.'**
  String get cdPermissionDetail;

  /// No description provided for @cdPairedDetail.
  ///
  /// In en, this message translates to:
  /// **'{name} may be connected to another phone or app. A radio talks to one phone at a time: close the other app or turn off Bluetooth on the other phone, then try again. If it keeps failing, forget the radio in Android Bluetooth settings and pair again.'**
  String cdPairedDetail(String name);

  /// No description provided for @cdTimeoutDetail.
  ///
  /// In en, this message translates to:
  /// **'{name} didn\'t answer in time. Move closer, check it\'s switched on, or restart it, then try again.'**
  String cdTimeoutDetail(String name);

  /// No description provided for @cdNetworkDetail.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the radio over the network. Check the phone and radio are on the same Wi-Fi, and that the address and port (usually 4403) are right.'**
  String get cdNetworkDetail;

  /// No description provided for @cdUsbDetail.
  ///
  /// In en, this message translates to:
  /// **'The USB link failed. Unplug and plug the cable back in, and allow USB access when Android asks.'**
  String get cdUsbDetail;

  /// No description provided for @cdGaveUpDetail.
  ///
  /// In en, this message translates to:
  /// **'The link dropped and reconnecting didn\'t work. Check {name} is on and in range, then try again.'**
  String cdGaveUpDetail(String name);

  /// No description provided for @cdNotMeshtasticDetail.
  ///
  /// In en, this message translates to:
  /// **'The device answered but doesn\'t look like a Meshtastic radio, or its firmware is too old.'**
  String get cdNotMeshtasticDetail;

  /// No description provided for @cdUnknownProblem.
  ///
  /// In en, this message translates to:
  /// **'Unknown problem.'**
  String get cdUnknownProblem;

  /// No description provided for @cdBluetooth.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth'**
  String get cdBluetooth;

  /// No description provided for @cdOn.
  ///
  /// In en, this message translates to:
  /// **'On.'**
  String get cdOn;

  /// No description provided for @cdBluetoothOff.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth is off.'**
  String get cdBluetoothOff;

  /// No description provided for @cdCouldntCheck.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check.'**
  String get cdCouldntCheck;

  /// No description provided for @cdAccess.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth access'**
  String get cdAccess;

  /// No description provided for @cdAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed.'**
  String get cdAllowed;

  /// No description provided for @cdNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'The app isn\'t allowed to find and connect to radios.'**
  String get cdNotAllowed;

  /// No description provided for @cdLink.
  ///
  /// In en, this message translates to:
  /// **'Radio link'**
  String get cdLink;

  /// No description provided for @cdConnectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to {name}.'**
  String cdConnectedTo(String name);

  /// No description provided for @cdConnectingTo.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {name}…'**
  String cdConnectingTo(String name);

  /// No description provided for @cdNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No radios found. Check the radio is on and within a few metres, that Bluetooth is enabled in its settings, and that it isn\'t connected to another phone.'**
  String get cdNoneFound;

  /// No description provided for @cdNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected.'**
  String get cdNotConnected;

  /// No description provided for @cdBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get cdBackground;

  /// No description provided for @cdBatteryOptimised.
  ///
  /// In en, this message translates to:
  /// **'Battery optimisation can cut the radio link when the screen is off. Set NOTORYX Connect to \"Unrestricted\".'**
  String get cdBatteryOptimised;

  /// No description provided for @cdBackgroundOk.
  ///
  /// In en, this message translates to:
  /// **'The link can stay open with the screen off.'**
  String get cdBackgroundOk;

  /// No description provided for @cdFirmware.
  ///
  /// In en, this message translates to:
  /// **'Firmware'**
  String get cdFirmware;

  /// No description provided for @cdFirmwareTooOld.
  ///
  /// In en, this message translates to:
  /// **'Firmware too old.'**
  String get cdFirmwareTooOld;

  /// No description provided for @cdSupported.
  ///
  /// In en, this message translates to:
  /// **'Supported.'**
  String get cdSupported;

  /// No description provided for @cpFlasherCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied flasher.meshtastic.org. Open it on a computer with the radio plugged in.'**
  String get cpFlasherCopied;

  /// No description provided for @cpFixFailed.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work: {error}'**
  String cpFixFailed(String error);

  /// No description provided for @cpReportCopied.
  ///
  /// In en, this message translates to:
  /// **'Report copied. It holds connection details only: no messages, keys or positions.'**
  String get cpReportCopied;

  /// No description provided for @cpTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection doctor'**
  String get cpTitle;

  /// No description provided for @cpChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get cpChecking;

  /// No description provided for @cpNoProblems.
  ///
  /// In en, this message translates to:
  /// **'No problems found'**
  String get cpNoProblems;

  /// No description provided for @cpProblems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 problem found} other{{count} problems found}}'**
  String cpProblems(int count);

  /// No description provided for @cpStillFails.
  ///
  /// In en, this message translates to:
  /// **'If the radio still won\'t connect, copy the report below and share it.'**
  String get cpStillFails;

  /// No description provided for @cpFixFirst.
  ///
  /// In en, this message translates to:
  /// **'Fix the first problem, then check again.'**
  String get cpFixFirst;

  /// No description provided for @cpCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get cpCheckAgain;

  /// No description provided for @cpCopyReport.
  ///
  /// In en, this message translates to:
  /// **'Copy report'**
  String get cpCopyReport;

  /// No description provided for @cpRecentEvents.
  ///
  /// In en, this message translates to:
  /// **'Recent connection events'**
  String get cpRecentEvents;

  /// No description provided for @cpNoEvents.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. Events appear here as the app connects.'**
  String get cpNoEvents;

  /// No description provided for @cpOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get cpOk;

  /// No description provided for @cpProblem.
  ///
  /// In en, this message translates to:
  /// **'Problem'**
  String get cpProblem;

  /// No description provided for @cpUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get cpUnknown;

  /// No description provided for @sntTitle.
  ///
  /// In en, this message translates to:
  /// **'Community moderation'**
  String get sntTitle;

  /// No description provided for @sntToolSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report spam to NOTORYX moderators and see flagged nodes'**
  String get sntToolSubtitle;

  /// No description provided for @sntIntro.
  ///
  /// In en, this message translates to:
  /// **'Reports go to NOTORYX moderators, who review each one by hand. Approved bans come back as an advisory list: flagged nodes get a label, and nothing on the mesh is blocked.'**
  String get sntIntro;

  /// No description provided for @sntEnable.
  ///
  /// In en, this message translates to:
  /// **'Use community moderation'**
  String get sntEnable;

  /// No description provided for @sntEnableSub.
  ///
  /// In en, this message translates to:
  /// **'Off by default. While it is off, NOTORYX never contacts the moderation service.'**
  String get sntEnableSub;

  /// No description provided for @sntHide.
  ///
  /// In en, this message translates to:
  /// **'Hide messages from flagged senders'**
  String get sntHide;

  /// No description provided for @sntHideSub.
  ///
  /// In en, this message translates to:
  /// **'Channel messages only. You can turn this off at any time.'**
  String get sntHideSub;

  /// No description provided for @sntSynced.
  ///
  /// In en, this message translates to:
  /// **'Ban list updated {time}'**
  String sntSynced(String time);

  /// No description provided for @sntNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Ban list not downloaded yet'**
  String get sntNeverSynced;

  /// No description provided for @sntFlaggedCount.
  ///
  /// In en, this message translates to:
  /// **'Flagged nodes: {count}'**
  String sntFlaggedCount(int count);

  /// No description provided for @sntQueued.
  ///
  /// In en, this message translates to:
  /// **'Reports waiting to send: {count}'**
  String sntQueued(int count);

  /// No description provided for @sntRefresh.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get sntRefresh;

  /// No description provided for @sntYourNode.
  ///
  /// In en, this message translates to:
  /// **'Your node'**
  String get sntYourNode;

  /// No description provided for @sntYourNodeClear.
  ///
  /// In en, this message translates to:
  /// **'Your node is not flagged.'**
  String get sntYourNodeClear;

  /// No description provided for @sntYourNodeFlagged.
  ///
  /// In en, this message translates to:
  /// **'Your node is flagged (case {caseRef}). If this is a mistake, you can appeal.'**
  String sntYourNodeFlagged(String caseRef);

  /// No description provided for @sntYourNodeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Connect a radio to check your node.'**
  String get sntYourNodeUnknown;

  /// No description provided for @sntAppealPending.
  ///
  /// In en, this message translates to:
  /// **'Your appeal is being reviewed.'**
  String get sntAppealPending;

  /// No description provided for @sntAppeal.
  ///
  /// In en, this message translates to:
  /// **'Appeal'**
  String get sntAppeal;

  /// No description provided for @sntAppealOther.
  ///
  /// In en, this message translates to:
  /// **'Appeal a case by number'**
  String get sntAppealOther;

  /// No description provided for @sntYourReports.
  ///
  /// In en, this message translates to:
  /// **'Your recent reports'**
  String get sntYourReports;

  /// No description provided for @sntReport.
  ///
  /// In en, this message translates to:
  /// **'Report to moderators'**
  String get sntReport;

  /// No description provided for @sntReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String sntReportTitle(String name);

  /// No description provided for @sntReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or advertising'**
  String get sntReasonSpam;

  /// No description provided for @sntReasonFlooding.
  ///
  /// In en, this message translates to:
  /// **'Flooding the mesh'**
  String get sntReasonFlooding;

  /// No description provided for @sntReasonAbuse.
  ///
  /// In en, this message translates to:
  /// **'Harassment or abuse'**
  String get sntReasonAbuse;

  /// No description provided for @sntReasonImpersonation.
  ///
  /// In en, this message translates to:
  /// **'Impersonation'**
  String get sntReasonImpersonation;

  /// No description provided for @sntReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get sntReasonOther;

  /// No description provided for @sntNote.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get sntNote;

  /// No description provided for @sntIncludeMessage.
  ///
  /// In en, this message translates to:
  /// **'Include this message'**
  String get sntIncludeMessage;

  /// No description provided for @sntSends.
  ///
  /// In en, this message translates to:
  /// **'Sends the node\'s ID and name, your reason and, if ticked, this message. Not your name, key or location.'**
  String get sntSends;

  /// No description provided for @sntSend.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get sntSend;

  /// No description provided for @sntSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent ({caseRef})'**
  String sntSent(String caseRef);

  /// No description provided for @sntQueuedOne.
  ///
  /// In en, this message translates to:
  /// **'No connection. The report will be sent later.'**
  String get sntQueuedOne;

  /// No description provided for @sntRejected.
  ///
  /// In en, this message translates to:
  /// **'Report not accepted: {message}'**
  String sntRejected(String message);

  /// No description provided for @sntOffPrompt.
  ///
  /// In en, this message translates to:
  /// **'Turn on community moderation?'**
  String get sntOffPrompt;

  /// No description provided for @sntTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get sntTurnOn;

  /// No description provided for @sntFlagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get sntFlagged;

  /// No description provided for @sntFlaggedHint.
  ///
  /// In en, this message translates to:
  /// **'Flagged by NOTORYX moderators (case {caseRef}). Advisory only.'**
  String sntFlaggedHint(String caseRef);

  /// No description provided for @sntCaseRef.
  ///
  /// In en, this message translates to:
  /// **'Case number (SNT-1234)'**
  String get sntCaseRef;

  /// No description provided for @sntStatement.
  ///
  /// In en, this message translates to:
  /// **'Why should the ban be lifted?'**
  String get sntStatement;

  /// No description provided for @sntContact.
  ///
  /// In en, this message translates to:
  /// **'Contact (optional, only moderators see it)'**
  String get sntContact;

  /// No description provided for @sntAppealSend.
  ///
  /// In en, this message translates to:
  /// **'Send appeal'**
  String get sntAppealSend;

  /// No description provided for @sntAppealReceived.
  ///
  /// In en, this message translates to:
  /// **'Appeal sent. A moderator will review it.'**
  String get sntAppealReceived;

  /// No description provided for @sntAppealUnknown.
  ///
  /// In en, this message translates to:
  /// **'No Meshtastic case has that number.'**
  String get sntAppealUnknown;

  /// No description provided for @sntAppealNotOpen.
  ///
  /// In en, this message translates to:
  /// **'That case has no active ban, or an appeal is already waiting.'**
  String get sntAppealNotOpen;

  /// No description provided for @sntAppealTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many appeals. Try again in a minute.'**
  String get sntAppealTooMany;

  /// No description provided for @sntFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the moderation service. Try again later.'**
  String get sntFailed;

  /// No description provided for @pvSent7.
  ///
  /// In en, this message translates to:
  /// **'Reports, appeals and ban-list checks to NOTORYX moderators through sentinel-relay.meshmayhem.org, only if you turn on Community moderation'**
  String get pvSent7;

  /// No description provided for @takReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'From ATAK'**
  String get takReceiveTitle;

  /// No description provided for @takReceiveIntro.
  ///
  /// In en, this message translates to:
  /// **'Shows markers that ATAK on this phone shares, such as team members and map points, on this app\'s map. They stay on this phone and are never sent over the mesh.'**
  String get takReceiveIntro;

  /// No description provided for @takReceiveSwitch.
  ///
  /// In en, this message translates to:
  /// **'Show ATAK markers on the map'**
  String get takReceiveSwitch;

  /// No description provided for @takReceivePort.
  ///
  /// In en, this message translates to:
  /// **'UDP port to listen on'**
  String get takReceivePort;

  /// No description provided for @takReceiveStatus.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Listening. No markers yet.} one{Showing {count} marker} other{Showing {count} markers}}'**
  String takReceiveStatus(int count);

  /// No description provided for @takReceiveProblem.
  ///
  /// In en, this message translates to:
  /// **'Could not listen: {error}'**
  String takReceiveProblem(String error);

  /// No description provided for @takReceiveHowTo.
  ///
  /// In en, this message translates to:
  /// **'In ATAK, open Settings, then Network Preferences, then Manage Outputs, and add a UDP output to 127.0.0.1 on this port. Markers disappear when ATAK says they are stale.'**
  String get takReceiveHowTo;

  /// No description provided for @takClear.
  ///
  /// In en, this message translates to:
  /// **'Clear markers'**
  String get takClear;

  /// No description provided for @takFriendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get takFriendly;

  /// No description provided for @takHostile.
  ///
  /// In en, this message translates to:
  /// **'Hostile'**
  String get takHostile;

  /// No description provided for @takNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get takNeutral;

  /// No description provided for @takUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get takUnknown;

  /// No description provided for @takPoint.
  ///
  /// In en, this message translates to:
  /// **'Map point'**
  String get takPoint;

  /// No description provided for @mapTakPin.
  ///
  /// In en, this message translates to:
  /// **'ATAK {kind}: {callsign}'**
  String mapTakPin(String kind, String callsign);

  /// No description provided for @mapTakUpdated.
  ///
  /// In en, this message translates to:
  /// **'From ATAK, updated {time}. Shown until {stale}.'**
  String mapTakUpdated(String time, String stale);

  /// No description provided for @takSamePort.
  ///
  /// In en, this message translates to:
  /// **'Use a different port from the one positions are sent to.'**
  String get takSamePort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
