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
