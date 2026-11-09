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
