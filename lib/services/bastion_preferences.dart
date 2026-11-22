import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../backdrop_page.dart';
import '../theme/nx_theme_picker.dart';
import '../theme/nx_themes.dart';
import 'bastion_heard_filter.dart';
import 'bastion_history_limit.dart';
import 'bastion_stale.dart';
import 'bastion_units.dart';

/// Phone appearance preferences; radio configuration is never changed.
class BastionPreferences extends ChangeNotifier {
  static final instance = BastionPreferences();
  /// The chosen theme's id (see [BastionTheme]); BLACKOUT by default.
  String appTheme = BastionTheme.fallback.id;

  /// The theme used while the device is in dark mode, or '' for none.
  String darkModeTheme = '';

  /// Ask a Store & Forward router for missed messages after reconnecting.
  bool storeForwardCatchUp = false;
  /// Let this phone carry MQTT for a radio set to "proxy to client".
  bool mqttProxy = false;
  /// Hide nodes on Nodes and Map not heard within this window.
  BastionHeardWithin heardWithin = BastionHeardWithin.any;
  /// Show only favourite (trusted) nodes on Nodes and Map.
  bool favoritesOnly = false;
  /// Mark nodes stale on Nodes and Map after this long unheard.
  BastionStaleAfter staleAfter = BastionStaleAfter.standard;
  /// Draw distance rings around this radio on the map.
  bool rangeRings = false;

  /// The theme id to show for the device's light/dark [platform] setting.
  String activeTheme(Brightness platform) => activeThemeId(
      appTheme: appTheme, darkModeTheme: darkModeTheme, platformBrightness: platform);

  /// The palette to show right now for the device's [platform] setting.
  BastionPalette palette(Brightness platform) => resolveThemePalette(activeTheme(platform));
  bool statistics = true;
  bool meshHealth = true;
  bool encounters = true;

  /// Delete channel messages older than this many days; 0 keeps them.
  int channelRetentionDays = 0;

  /// Messages kept in each conversation (a channel or a direct thread).
  int historyLimit = BastionHistoryLimit.standard;

  /// Read incoming messages aloud while the app is open.
  bool readAloud = false;

  /// Fetch a title for web links in chats. Off unless switched on, since it
  /// asks the linked site for the page.
  bool linkPreviews = false;

  /// Miles and feet, or kilometers and meters. Defaults from the phone's region.
  BastionUnits units = BastionUnits.metric;
  String? error;

  static const retentionChoices = [0, 1, 7, 30];

  Future<void> load() async {
    try {
      final p = SharedPreferencesAsync();
      final saved = await p.getString('bastion.app_theme');
      if (saved != null) {
        // A theme that was removed (or any unknown id) opens as BLACKOUT.
        appTheme = BastionTheme.fromId(saved).id;
        final dark = await p.getString('bastion.dark_mode_theme') ?? '';
        darkModeTheme = dark.isEmpty ? '' : BastionTheme.fromId(dark).id;
      } else {
        // Before the theme list there was only light, dark or system. A
        // fresh install has neither and starts on BLACKOUT.
        final mode = await p.getString('bastion.theme');
        appTheme = mode == null ? BastionTheme.fallback.id : BastionTheme.fromId(mode).id;
        darkModeTheme = mode == 'system' ? BastionTheme.blaze.id : '';
      }
      storeForwardCatchUp = await p.getBool('bastion.store_forward_catch_up') ?? false;
      mqttProxy = await p.getBool('bastion.mqtt_proxy') ?? false;
      heardWithin = BastionHeardWithin.fromName(await p.getString('bastion.nodes.heard_within'));
      favoritesOnly = await p.getBool('bastion.nodes.favorites_only') ?? false;
      staleAfter = BastionStaleAfter.fromName(await p.getString('bastion.nodes.stale_after'));
      rangeRings = await p.getBool('bastion.map.range_rings') ?? false;
      statistics = await p.getBool('bastion.dashboard.statistics') ?? true;
      meshHealth = await p.getBool('bastion.dashboard.health') ?? true;
      encounters = await p.getBool('bastion.dashboard.encounters') ?? true;
      channelRetentionDays = await p.getInt('bastion.messages.channel_retention_days') ?? 0;
      readAloud = await p.getBool('bastion.messages.read_aloud') ?? false;
      linkPreviews = await p.getBool('bastion.messages.link_previews') ?? false;
      final limit = await p.getInt('bastion.messages.history_limit');
      historyLimit = BastionHistoryLimit.choices.contains(limit) ? limit! : BastionHistoryLimit.standard;
      final unitName = await p.getString('bastion.units');
      units = BastionUnits.values.where((u) => u.name == unitName).firstOrNull ??
          BastionUnitFormat.defaultFor(WidgetsBinding.instance.platformDispatcher.locale.countryCode);
    } catch (_) { error = 'Appearance preferences could not be loaded.'; }
    notifyListeners();
  }

  Future<void> update({bool? catchUp, bool? proxyMqtt, BastionHeardWithin? heard, bool? favorites, String? theme, String? darkTheme, bool? stats, bool? health, bool? saved,
      int? retentionDays, bool? speak, BastionUnits? unitSystem, int? keepMessages, BastionStaleAfter? stale, bool? rings, bool? previews}) async {
    storeForwardCatchUp = catchUp ?? storeForwardCatchUp;
    mqttProxy = proxyMqtt ?? mqttProxy;
    heardWithin = heard ?? heardWithin;
    favoritesOnly = favorites ?? favoritesOnly;
    staleAfter = stale ?? staleAfter;
    rangeRings = rings ?? rangeRings;
    appTheme = theme ?? appTheme;
    darkModeTheme = darkTheme ?? darkModeTheme;
    statistics = stats ?? statistics;
    meshHealth = health ?? meshHealth;
    encounters = saved ?? encounters;
    channelRetentionDays = retentionDays ?? channelRetentionDays;
    readAloud = speak ?? readAloud;
    linkPreviews = previews ?? linkPreviews;
    historyLimit = keepMessages ?? historyLimit;
    units = unitSystem ?? units;
    error = null;
    notifyListeners();
    try {
      final p = SharedPreferencesAsync();
      await p.setString('bastion.app_theme', appTheme);
      await p.setString('bastion.dark_mode_theme', darkModeTheme);
      // Settings of the removed Seasonal theme.
      await p.remove('bastion.seasonal_override');
      await p.remove('bastion.seasonal_holidays');
      await p.setBool('bastion.store_forward_catch_up', storeForwardCatchUp);
      await p.setBool('bastion.mqtt_proxy', mqttProxy);
      await p.setString('bastion.nodes.heard_within', heardWithin.name);
      await p.setBool('bastion.nodes.favorites_only', favoritesOnly);
      await p.setString('bastion.nodes.stale_after', staleAfter.name);
      await p.setBool('bastion.map.range_rings', rangeRings);
      await p.setBool('bastion.dashboard.statistics', statistics);
      await p.setBool('bastion.dashboard.health', meshHealth);
      await p.setBool('bastion.dashboard.encounters', encounters);
      await p.setInt('bastion.messages.channel_retention_days', channelRetentionDays);
      await p.setBool('bastion.messages.read_aloud', readAloud);
      await p.setBool('bastion.messages.link_previews', linkPreviews);
      await p.setInt('bastion.messages.history_limit', historyLimit);
      await p.setString('bastion.units', units.name);
    } catch (_) { error = 'Changes apply now, but could not be saved.'; notifyListeners(); }
  }
}

class BastionAppearanceCard extends StatelessWidget {
  const BastionAppearanceCard({super.key});
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: BastionPreferences.instance,
    builder: (context, _) {
      final p = BastionPreferences.instance;
      return Card(child: ExpansionTile(
        title: const Text('Appearance & dashboard'),
        leading: const Icon(Icons.palette_outlined),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: NxThemePicker(prefs: p),
          ),
          const BackdropSettingsTile(),
          ListTile(
            title: const Text('Units'),
            // The choice sits under the description, so it never runs out of
            // room on a narrow screen with large text.
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Distances and altitudes'),
              const SizedBox(height: 8),
              SegmentedButton<BastionUnits>(
                segments: const [
                  ButtonSegment(value: BastionUnits.metric, label: Text('km, m')),
                  ButtonSegment(value: BastionUnits.imperial, label: Text('mi, ft')),
                ],
                selected: {p.units},
                showSelectedIcon: false,
                onSelectionChanged: (v) => p.update(unitSystem: v.single),
              ),
            ]),
          ),
          SwitchListTile(title: const Text('Dashboard statistics'), value: p.statistics,
            onChanged: (v) => p.update(stats: v)),
          SwitchListTile(title: const Text('Mesh health & signal'), value: p.meshHealth,
            onChanged: (v) => p.update(health: v)),
          SwitchListTile(title: const Text('Saved encounters'), value: p.encounters,
            onChanged: (v) => p.update(saved: v)),
          if (p.error != null) ListTile(title: Text(p.error!)),
        ],
      ));
    },
  );
}
