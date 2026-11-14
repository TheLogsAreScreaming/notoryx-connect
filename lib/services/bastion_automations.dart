import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bastion_chat_message.dart';
import 'bastion_field_alerts.dart';
import 'bastion_geo.dart';
import 'bastion_geofences.dart';
import 'meshtastic_channel_url.dart';
import 'meshtastic_node_database.dart';
import 'meshtastic_radio_coordinator.dart';

/// The app's automation engine, set up by the app shell for the real radio.
abstract final class BastionAutomations {
  static AutomationEngine? instance;
}

/// Broadcast address: a message to everyone on a channel.
const automationBroadcast = 0xffffffff;

// ---------------------------------------------------------------- triggers

/// What starts an automation.
sealed class AutoTrigger {
  const AutoTrigger();

  Map<String, Object?> toJson();

  static AutoTrigger? fromJson(Object? j) {
    if (j is! Map) return null;
    final node = j['node'] is int ? j['node'] as int : null;
    switch (j['t']) {
      case 'battery':
        final below = j['below'];
        if (below is! int || node == null) return null;
        return BatteryTrigger(node: node, below: below.clamp(1, 99));
      case 'time':
        final (h, m, days) = (j['h'], j['m'], j['days']);
        if (h is! int || m is! int || days is! List) return null;
        return TimeTrigger(
          hour: h.clamp(0, 23),
          minute: m.clamp(0, 59),
          weekdays: {for (final d in days) if (d is int && d >= 1 && d <= 7) d},
        );
      case 'zone':
        final (zone, enter) = (j['zone'], j['enter']);
        if (zone is! String || enter is! bool) return null;
        return GeofenceTrigger(zone: zone, enter: enter, node: node);
      case 'message':
        final channel = j['ch'];
        return MessageTrigger(
          contains: j['has'] is String ? j['has'] as String : '',
          channel: channel is int ? channel : null,
          directOnly: j['dm'] == true,
        );
      case 'presence':
        final mins = j['after'];
        if (node == null || mins is! int) return null;
        return PresenceTrigger(node: node, online: j['on'] == true, after: Duration(minutes: mins.clamp(5, 24 * 60)));
    }
    return null;
  }
}

/// A node's battery falls below [below] percent.
final class BatteryTrigger extends AutoTrigger {
  const BatteryTrigger({required this.node, required this.below});

  final int node;
  final int below;

  @override
  Map<String, Object?> toJson() => {'t': 'battery', 'node': node, 'below': below};
}

/// A time of day on some days of the week (1 = Monday … 7 = Sunday; none
/// means every day).
final class TimeTrigger extends AutoTrigger {
  const TimeTrigger({required this.hour, required this.minute, this.weekdays = const {}});

  final int hour;
  final int minute;
  final Set<int> weekdays;

  bool matches(DateTime t) =>
      t.hour == hour && t.minute == minute && (weekdays.isEmpty || weekdays.contains(t.weekday));

  @override
  Map<String, Object?> toJson() => {'t': 'time', 'h': hour, 'm': minute, 'days': weekdays.toList()..sort()};
}

/// A node enters or leaves one of the geofence zones set up on the map;
/// any node when [node] is null.
final class GeofenceTrigger extends AutoTrigger {
  const GeofenceTrigger({required this.zone, required this.enter, this.node});

  /// [BastionGeofence.id] of the zone.
  final String zone;
  final bool enter;
  final int? node;

  @override
  Map<String, Object?> toJson() => {'t': 'zone', 'zone': zone, 'enter': enter, 'node': ?node};
}

/// A message arrives, optionally containing [contains] (ignoring case), on
/// one [channel], or only direct messages.
final class MessageTrigger extends AutoTrigger {
  const MessageTrigger({this.contains = '', this.channel, this.directOnly = false});

  final String contains;
  final int? channel;
  final bool directOnly;

  bool matches(BastionChatMessage m) {
    final direct = m.to != automationBroadcast;
    if (directOnly && !direct) return false;
    if (channel != null && (direct || m.channel != channel)) return false;
    final want = contains.trim().toLowerCase();
    return want.isEmpty || m.text.toLowerCase().contains(want);
  }

  @override
  Map<String, Object?> toJson() => {
        't': 'message',
        if (contains.isNotEmpty) 'has': contains,
        'ch': ?channel,
        if (directOnly) 'dm': true,
      };
}

/// A node comes back ([online]) after not being heard for [after], or goes
/// quiet for [after].
final class PresenceTrigger extends AutoTrigger {
  const PresenceTrigger({required this.node, required this.online, this.after = const Duration(minutes: 30)});

  final int node;
  final bool online;
  final Duration after;

  @override
  Map<String, Object?> toJson() => {'t': 'presence', 'node': node, 'on': online, 'after': after.inMinutes};
}

// ----------------------------------------------------------------- actions

/// What an automation does.
sealed class AutoAction {
  const AutoAction();

  Map<String, Object?> toJson();

  /// Whether it reaches the internet.
  bool get needsInternet => false;

  static AutoAction? fromJson(Object? j) {
    if (j is! Map) return null;
    switch (j['a']) {
      case 'send':
        final (to, ch, text) = (j['to'], j['ch'], j['text']);
        if (to is! int || ch is! int || text is! String || text.trim().isEmpty) return null;
        return SendAction(destination: to, channel: ch.clamp(0, 7), text: text);
      case 'alert':
        final text = j['text'];
        return text is String && text.trim().isNotEmpty ? AlertAction(text) : null;
      case 'channel':
        final link = j['link'];
        return link is String && JoinChannelAction.validLink(link) ? JoinChannelAction(link) : null;
      case 'sound':
        return const SoundAction();
      case 'webhook':
        final url = j['url'];
        return url is String && WebhookAction.validUrl(url) ? WebhookAction(url) : null;
    }
    return null;
  }
}

/// Sends [text] (with `{node}`, `{battery}`, `{zone}`, `{time}`, `{text}`
/// and `{rule}` filled in) to [destination] on [channel].
final class SendAction extends AutoAction {
  const SendAction({required this.destination, required this.channel, required this.text});

  /// A node number, or [automationBroadcast] for everyone on [channel].
  final int destination;
  final int channel;
  final String text;

  @override
  Map<String, Object?> toJson() => {'a': 'send', 'to': destination, 'ch': channel, 'text': text};
}

/// Shows a notification on this phone.
final class AlertAction extends AutoAction {
  const AlertAction(this.text);

  final String text;

  @override
  Map<String, Object?> toJson() => {'a': 'alert', 'text': text};
}

/// Changes channel: adds the channels in a share [link] to the radio,
/// keeping the ones already there.
final class JoinChannelAction extends AutoAction {
  const JoinChannelAction(this.link);

  final String link;

  static bool validLink(String link) {
    try {
      return MeshtasticChannelUrl.decode(link.trim()).settings.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Map<String, Object?> toJson() => {'a': 'channel', 'link': link};
}

/// Plays the phone's alert sound.
final class SoundAction extends AutoAction {
  const SoundAction();

  @override
  Map<String, Object?> toJson() => {'a': 'sound'};
}

/// Posts what happened, as JSON, to [url]. Needs internet, and only runs
/// while web requests are allowed in [AutomationSettings].
final class WebhookAction extends AutoAction {
  const WebhookAction(this.url);

  final String url;

  @override
  bool get needsInternet => true;

  /// An absolute http(s) address with a host.
  static bool validUrl(String text) {
    final u = Uri.tryParse(text.trim());
    return u != null && (u.scheme == 'https' || u.scheme == 'http') && u.host.isNotEmpty;
  }

  @override
  Map<String, Object?> toJson() => {'a': 'webhook', 'url': url};
}

// ------------------------------------------------------------------- rules

/// One automation: when its triggers fire (any of them, or all at once),
/// run its actions.
@immutable
class Automation {
  const Automation({
    required this.id,
    required this.name,
    this.enabled = true,
    this.matchAll = false,
    this.triggers = const [],
    this.actions = const [],
    this.cooldown = const Duration(minutes: 5),
  });

  static const cooldownChoices = [1, 5, 15, 60, 240, 1440];

  final int id;
  final String name;
  final bool enabled;

  /// AND: every trigger must hold when one fires. OR (false): any fires.
  final bool matchAll;
  final List<AutoTrigger> triggers;
  final List<AutoAction> actions;

  /// The shortest time between two runs of this rule.
  final Duration cooldown;

  bool get needsInternet => actions.any((a) => a.needsInternet);

  Automation copyWith({
    String? name,
    bool? enabled,
    bool? matchAll,
    List<AutoTrigger>? triggers,
    List<AutoAction>? actions,
    Duration? cooldown,
  }) =>
      Automation(
        id: id,
        name: name ?? this.name,
        enabled: enabled ?? this.enabled,
        matchAll: matchAll ?? this.matchAll,
        triggers: triggers ?? this.triggers,
        actions: actions ?? this.actions,
        cooldown: cooldown ?? this.cooldown,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'on': enabled,
        'all': matchAll,
        'cool': cooldown.inMinutes,
        'when': [for (final t in triggers) t.toJson()],
        'do': [for (final a in actions) a.toJson()],
      };

  static Automation? fromJson(Object? j) {
    if (j is! Map) return null;
    final (id, name, ts, act) = (j['id'], j['name'], j['when'], j['do']);
    if (id is! int || name is! String || ts is! List || act is! List) return null;
    final cool = j['cool'];
    return Automation(
      id: id,
      name: name,
      enabled: j['on'] != false,
      matchAll: j['all'] == true,
      cooldown: Duration(minutes: cool is int ? cool.clamp(1, 1440) : 5),
      triggers: [for (final t in ts) ?AutoTrigger.fromJson(t)],
      actions: [for (final a in act) ?AutoAction.fromJson(a)],
    );
  }
}

/// Every automation, and whether web requests may be made at all.
@immutable
class AutomationSettings {
  const AutomationSettings({this.rules = const [], this.webhooks = false});

  final List<Automation> rules;

  /// Web requests (webhooks) are off until the person turns them on.
  final bool webhooks;

  int get nextId => rules.fold(0, (m, r) => r.id > m ? r.id : m) + 1;

  AutomationSettings copyWith({List<Automation>? rules, bool? webhooks}) =>
      AutomationSettings(rules: rules ?? this.rules, webhooks: webhooks ?? this.webhooks);

  String encode() => jsonEncode({'webhooks': webhooks, 'rules': [for (final r in rules) r.toJson()]});

  static AutomationSettings decode(String? saved) {
    if (saved == null) return const AutomationSettings();
    try {
      final j = jsonDecode(saved);
      if (j is! Map) return const AutomationSettings();
      final rules = j['rules'];
      return AutomationSettings(
        webhooks: j['webhooks'] == true,
        rules: rules is List ? [for (final r in rules) ?Automation.fromJson(r)] : const [],
      );
    } on FormatException {
      return const AutomationSettings();
    }
  }
}

// ------------------------------------------------------------------ engine

/// What a run of a rule is about, for filling in message text.
@immutable
class AutoContext {
  const AutoContext({this.node, this.battery, this.zone, this.text, required this.time});

  final String? node;
  final int? battery;
  final String? zone;
  final String? text;
  final DateTime time;

  AutoContext merge(AutoContext o) => AutoContext(
        node: node ?? o.node,
        battery: battery ?? o.battery,
        zone: zone ?? o.zone,
        text: text ?? o.text,
        time: time,
      );

  static String _hm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String fill(String template, String rule) => template
      .replaceAll('{rule}', rule)
      .replaceAll('{node}', node ?? '')
      .replaceAll('{battery}', battery?.toString() ?? '')
      .replaceAll('{zone}', zone ?? '')
      .replaceAll('{text}', text ?? '')
      .replaceAll('{time}', _hm(time));

  Map<String, Object?> toJson(String rule) => {
        'rule': rule,
        'time': time.toUtc().toIso8601String(),
        'node': ?node,
        'battery': ?battery,
        'zone': ?zone,
        'text': ?text,
      };
}

/// What the engine reads from the connected radio.
abstract interface class AutomationSource implements Listenable {
  int? get localNodeNum;
  bool get isReady;
  List<MeshtasticNode> get nodes;
  List<BastionChatMessage> get messages;
  List<BastionGeofence> get geofences;
  int? batteryOf(int node);
  String nodeName(int node);
}

/// The side effects an automation can have, supplied by the app.
class AutomationHooks {
  const AutomationHooks({
    required this.send,
    required this.alert,
    required this.playSound,
    required this.joinChannel,
    required this.post,
  });

  /// Sends a message; false when the radio isn't ready.
  final Future<bool> Function(int destination, int channel, String text) send;
  final Future<void> Function(int ruleId, String title, String body) alert;
  final Future<void> Function() playSound;

  /// Adds the channels in a share link; false when the radio isn't ready.
  final Future<bool> Function(String link) joinChannel;

  /// Posts JSON to a web address and returns the HTTP status.
  final Future<int> Function(Uri url, String json) post;
}

/// Why an action didn't run.
enum AutoProblem { notConnected, webOff, httpError, failed }

/// One action that ran (or was skipped), for the activity list.
@immutable
class AutoRun {
  const AutoRun(this.time, this.rule, this.action, {this.problem, this.status});

  final DateTime time;
  final String rule;
  final AutoAction action;
  final AutoProblem? problem;

  /// The HTTP status for a webhook that answered with an error.
  final int? status;

  bool get ok => problem == null;
}

/// Runs automations: watches messages, nodes, zones and the clock, and runs
/// a rule's actions when its triggers fire.
///
/// Limits keep it from running away: a rule runs at most once per its
/// cooldown, all rules together at most [maxPerHour] times an hour, messages
/// that start with [marker] (sent by an automation, here or on another
/// phone), check-ins, SOS and backlog older than [maxAge] never trigger
/// anything, and the first battery, position or presence reading is only a
/// starting point. Nothing runs unless the radio link is ready.
class AutomationEngine extends ChangeNotifier {
  AutomationEngine({
    required this.hooks,
    SharedPreferencesAsync? preferences,
    DateTime Function()? clock,
  })  : _givenPrefs = preferences,
        _now = clock ?? DateTime.now;

  static const storageName = 'bastion.automations';
  static const maxPerHour = 30;
  static const maxAge = Duration(minutes: 10);

  /// Put in front of every message an automation sends.
  static const marker = '[auto] ';

  final AutomationHooks hooks;
  SharedPreferencesAsync? _givenPrefs;
  SharedPreferencesAsync get _prefs => _givenPrefs ??= SharedPreferencesAsync();
  final DateTime Function() _now;

  AutomationSettings _settings = const AutomationSettings();
  AutomationSettings get settings => _settings;

  /// Whether saved settings have been read.
  bool loaded = false;

  /// Set when saved settings couldn't be read or written.
  bool storageProblem = false;

  final List<AutoRun> log = [];

  AutomationSource? _source;
  AutomationSource? get source => _source;
  int? _radio;
  bool _primed = false;
  final Set<(int, int)> _seenMessages = {};
  final Map<String, int> _battery = {};
  final Map<String, bool> _inside = {};
  final Map<String, bool> _present = {};
  final Map<int, DateTime> _lastRun = {};
  final Map<String, DateTime> _timeFired = {};
  final List<DateTime> _recent = [];
  Timer? _tick;

  /// Reads the saved rules.
  Future<void> load() async {
    try {
      _settings = AutomationSettings.decode(await _prefs.getString(storageName));
    } catch (_) {
      storageProblem = true;
    }
    loaded = true;
    _syncTimer();
    notifyListeners();
  }

  /// Saves new rules and the web-request switch.
  Future<bool> save(AutomationSettings s) async {
    _settings = s;
    _syncTimer();
    notifyListeners();
    try {
      await _prefs.setString(storageName, s.encode());
      storageProblem = false;
      return true;
    } catch (_) {
      storageProblem = true;
      notifyListeners();
      return false;
    }
  }

  /// Starts watching [source]; replaces any earlier one.
  void attach(AutomationSource source) {
    detach();
    _source = source;
    source.addListener(_changed);
    _changed();
  }

  void detach() {
    _source?.removeListener(_changed);
    _source = null;
    _tick?.cancel();
    _tick = null;
  }

  bool get _active => _source?.isReady == true;

  /// The clock is needed only for time and going-quiet triggers, and only
  /// while a radio is ready.
  void _syncTimer() {
    final needed = _active &&
        _settings.rules.any((r) => r.enabled && r.triggers.any((t) => t is TimeTrigger || t is PresenceTrigger));
    if (needed) {
      _tick ??= Timer.periodic(const Duration(seconds: 20), (_) => unawaited(onTick()));
    } else {
      _tick?.cancel();
      _tick = null;
    }
  }

  void _changed() {
    final source = _source;
    if (source == null) return;
    final radio = source.localNodeNum;
    if (radio != _radio) {
      _radio = radio;
      _primed = false;
      _seenMessages.clear();
      _battery.clear();
      _inside.clear();
      _present.clear();
    }
    _syncTimer();
    if (!source.isReady) return;
    if (!_primed) {
      // What is there when the link comes up is the starting point.
      _primed = true;
      for (final m in source.messages) {
        _seenMessages.add((m.from, m.packetId));
      }
      unawaited(onNodes());
      return;
    }
    final fresh = [
      for (final m in source.messages)
        if (_seenMessages.add((m.from, m.packetId))) m,
    ];
    unawaited(_afterMessages(fresh));
  }

  Future<void> _afterMessages(List<BastionChatMessage> fresh) async {
    for (final m in fresh) {
      await onMessage(m);
    }
    await onNodes();
  }

  /// Whether [m] may set off message triggers.
  @visibleForTesting
  static bool canTrigger(BastionChatMessage m, DateTime now) {
    if (m.direction != BastionMessageDirection.incoming || m.isReaction) return false;
    final t = m.text.trimLeft();
    if (t.startsWith(marker.trim()) || t.startsWith('[NOTORYX')) return false;
    return now.difference(m.timestamp).abs() <= maxAge;
  }

  /// A message arrived.
  Future<void> onMessage(BastionChatMessage m) async {
    final now = _now();
    if (!_active || !canTrigger(m, now)) return;
    final ctx = AutoContext(node: _source!.nodeName(m.from), text: m.text, time: now);
    await _evaluate((t) => t is MessageTrigger && t.matches(m) ? ctx : null, now);
  }

  static String _key(Automation r, Object k) => '${r.id}|$k';

  /// Nodes changed: battery, positions and presence.
  Future<void> onNodes() async {
    final source = _source;
    if (source == null || !_active) return;
    final now = _now();
    final fired = <AutoTrigger, AutoContext>{};
    final nodes = [for (final n in source.nodes) if (n.num != source.localNodeNum) n];
    final zones = {for (final z in source.geofences) z.id: z};
    for (final r in _settings.rules) {
      if (!r.enabled) continue;
      for (final t in r.triggers) {
        switch (t) {
          case BatteryTrigger(:final node, :final below):
            final b = source.batteryOf(node);
            if (b == null) continue;
            final key = _key(r, node);
            final was = _battery[key];
            _battery[key] = b;
            if (was != null && was >= below && b < below) {
              fired[t] = AutoContext(node: source.nodeName(node), battery: b, time: now);
            }
          case GeofenceTrigger(:final zone, :final enter, :final node):
            final z = zones[zone];
            if (z == null) continue;
            for (final n in nodes) {
              if ((node != null && n.num != node) || !n.hasPosition) continue;
              final key = _key(r, '$zone|${n.num}');
              final was = _inside[key];
              final metres = BastionGeo.distanceMeters(z.latitude, z.longitude, n.latitude!, n.longitude!);
              // A little slack on the way out, so a node on the edge doesn't flap.
              final inside = was == true ? metres <= z.radiusMeters * 1.1 : metres <= z.radiusMeters;
              _inside[key] = inside;
              if (was != null && was != inside && inside == enter) {
                fired[t] = AutoContext(node: n.displayName, zone: z.name, time: now);
              }
            }
          case PresenceTrigger(:final online):
            // Going quiet is noticed by the clock; coming back here.
            if (!online) continue;
            final ctx = _presence(r, t, now);
            if (ctx != null) fired[t] = ctx;
          case TimeTrigger() || MessageTrigger():
            break;
        }
      }
    }
    await _evaluate((t) => fired[t], now);
  }

  /// Checks the clock: times of day and nodes going quiet.
  Future<void> onTick() async {
    if (!_active) return;
    final now = _now();
    final fired = <AutoTrigger, AutoContext>{};
    for (final r in _settings.rules) {
      if (!r.enabled) continue;
      for (final t in r.triggers) {
        switch (t) {
          case TimeTrigger():
            if (!t.matches(now)) continue;
            final key = _key(r, '${t.hour}:${t.minute}');
            final last = _timeFired[key];
            if (last != null && now.difference(last) < const Duration(minutes: 2)) continue;
            _timeFired[key] = now;
            fired[t] = AutoContext(time: now);
          case PresenceTrigger():
            final ctx = _presence(r, t, now);
            if (ctx != null) fired[t] = ctx;
          case BatteryTrigger() || GeofenceTrigger() || MessageTrigger():
            break;
        }
      }
    }
    await _evaluate((t) => fired[t], now);
  }

  MeshtasticNode? _node(int num) {
    for (final n in _source?.nodes ?? const <MeshtasticNode>[]) {
      if (n.num == num) return n;
    }
    return null;
  }

  /// Notes whether [t]'s node is present and returns a context when that
  /// changed the way [t] waits for.
  AutoContext? _presence(Automation r, PresenceTrigger t, DateTime now) {
    final heard = _node(t.node)?.lastHeard;
    if (heard == null) return null;
    final present = now.difference(heard) < t.after;
    final key = _key(r, '${t.online}|${t.node}');
    final was = _present[key];
    _present[key] = present;
    if (was == null || was == present || present != t.online) return null;
    return AutoContext(node: _source!.nodeName(t.node), time: now);
  }

  /// Whether [t] holds right now (for rules that need every trigger).
  bool _holds(AutoTrigger t, DateTime now) {
    final source = _source!;
    switch (t) {
      case BatteryTrigger(:final node, :final below):
        final b = source.batteryOf(node);
        return b != null && b < below;
      case TimeTrigger():
        return t.matches(now);
      case GeofenceTrigger(:final zone, :final enter, :final node):
        final z = source.geofences.where((g) => g.id == zone).firstOrNull;
        if (z == null) return false;
        return source.nodes.any((n) {
          if ((node != null && n.num != node) || !n.hasPosition || n.num == source.localNodeNum) return false;
          return (BastionGeo.distanceMeters(z.latitude, z.longitude, n.latitude!, n.longitude!) <= z.radiusMeters) ==
              enter;
        });
      case MessageTrigger():
        return false;
      case PresenceTrigger(:final node, :final online, :final after):
        final heard = _node(node)?.lastHeard;
        if (heard == null) return false;
        return (now.difference(heard) < after) == online;
    }
  }

  Future<void> _evaluate(AutoContext? Function(AutoTrigger) firedBy, DateTime now) async {
    for (final r in _settings.rules) {
      if (!r.enabled || r.triggers.isEmpty || r.actions.isEmpty) continue;
      AutoContext? ctx;
      for (final t in r.triggers) {
        final c = firedBy(t);
        if (c != null) ctx = ctx == null ? c : ctx.merge(c);
      }
      if (ctx == null) continue;
      if (r.matchAll && !r.triggers.every((t) => firedBy(t) != null || _holds(t, now))) continue;
      final last = _lastRun[r.id];
      if (last != null && now.difference(last) < r.cooldown) continue;
      _recent.removeWhere((t) => now.difference(t) >= const Duration(hours: 1));
      if (_recent.length >= maxPerHour) continue;
      _lastRun[r.id] = now;
      _recent.add(now);
      await run(r, ctx);
    }
  }

  /// Runs [rule]'s actions with [ctx]; one failing doesn't stop the rest.
  Future<void> run(Automation rule, AutoContext ctx) async {
    for (final a in rule.actions) {
      AutoProblem? problem;
      int? status;
      try {
        switch (a) {
          case SendAction(:final destination, :final channel, :final text):
            final body = ctx.fill(text, rule.name).trim();
            if (!await hooks.send(destination, channel, '$marker$body')) problem = AutoProblem.notConnected;
          case AlertAction(:final text):
            await hooks.alert(rule.id, rule.name, ctx.fill(text, rule.name));
          case SoundAction():
            await hooks.playSound();
          case JoinChannelAction(:final link):
            if (!await hooks.joinChannel(link.trim())) problem = AutoProblem.notConnected;
          case WebhookAction(:final url):
            if (!_settings.webhooks) {
              problem = AutoProblem.webOff;
            } else {
              final code = await hooks.post(Uri.parse(url.trim()), jsonEncode(ctx.toJson(rule.name)));
              if (code < 200 || code >= 300) {
                problem = AutoProblem.httpError;
                status = code;
              }
            }
        }
      } catch (_) {
        problem = AutoProblem.failed;
      }
      log.insert(0, AutoRun(ctx.time, rule.name, a, problem: problem, status: status));
      if (log.length > 100) log.removeLast();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    detach();
    super.dispose();
  }
}

// ------------------------------------------------------------ app wiring

/// Reads what automations need from the app's radio coordinator.
class CoordinatorAutomationSource implements AutomationSource {
  CoordinatorAutomationSource(this.radio);

  final MeshtasticRadioCoordinator radio;

  @override
  int? get localNodeNum => radio.localNodeNum;
  @override
  bool get isReady => radio.isReady;
  @override
  List<MeshtasticNode> get nodes => radio.nodes;
  @override
  List<BastionChatMessage> get messages => radio.messages;
  @override
  List<BastionGeofence> get geofences => radio.geofences;
  @override
  int? batteryOf(int node) =>
      radio.deviceTelemetry[node]?.batteryLevel ?? radio.nodes.where((n) => n.num == node).firstOrNull?.batteryLevel;
  @override
  String nodeName(int node) => radio.nodeName(node);
  @override
  void addListener(VoidCallback listener) => radio.addListener(listener);
  @override
  void removeListener(VoidCallback listener) => radio.removeListener(listener);
}

/// The real side effects, through [radio].
AutomationHooks coordinatorAutomationHooks(MeshtasticRadioCoordinator radio) => AutomationHooks(
      send: (destination, channel, text) async {
        if (!radio.isReady) return false;
        await radio.sendText(text: text, destination: destination, channel: channel);
        return true;
      },
      alert: (ruleId, title, body) =>
          radio.showLocalAlert(BastionFieldAlert(BastionAlertKind.automation, ruleId, title, body)),
      playSound: () => SystemSound.play(SystemSoundType.alert),
      joinChannel: (link) async {
        if (!radio.isReady) return false;
        await radio.applyChannelSet(MeshtasticChannelUrl.decode(link), replace: false);
        return true;
      },
      post: postAutomationJson,
    );

/// Posts [json] to [url] and returns the HTTP status. Times out after 10 s.
Future<int> postAutomationJson(Uri url, String json) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.postUrl(url).timeout(const Duration(seconds: 10));
    request.headers.contentType = ContentType.json;
    request.write(json);
    final response = await request.close().timeout(const Duration(seconds: 10));
    await response.drain<void>();
    return response.statusCode;
  } finally {
    client.close(force: true);
  }
}
