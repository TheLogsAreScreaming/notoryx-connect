import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/nx_theme_picker.dart';
import '../theme/nx_themes.dart';
import 'bastion_heard_filter.dart';
import 'bastion_history_limit.dart';
import 'bastion_units.dart';

/// Phone appearance preferences; radio configuration is never changed.
class BastionPreferences extends ChangeNotifier {
  static final instance = BastionPreferences();
  /// The chosen theme's id (see [BastionTheme]); Blaze by default.
  String appTheme = BastionTheme.blaze.id;

  /// The theme used while the device is in dark mode, or '' for none.
  String darkModeTheme = '';

  /// The Seasonal theme's season: 'auto' (by date) or a [Season] id.
  String seasonalOverride = 'auto';

  /// Whether Seasonal switches to holiday colors on their dates.
  bool seasonalHolidays = true;

  /// Ask a Store & Forward router for missed messages after reconnecting.
  bool storeForwardCatchUp = false;
  /// Let this phone carry MQTT for a radio set to "proxy to client".
  bool mqttProxy = false;
  /// Hide nodes on Nodes and Map not heard within this window.
  BastionHeardWithin heardWithin = BastionHeardWithin.any;
  /// Show only favourite (trusted) nodes on Nodes and Map.
  bool favoritesOnly = false;

  /// The theme id to show for the device's light/dark [platform] setting.
  String activeTheme(Brightness platform) => activeThemeId(
      appTheme: appTheme, darkModeTheme: darkModeTheme, platformBrightness: platform);

  /// The palette to show right now for the device's [platform] setting.
  BastionPalette palette(Brightness platform, {DateTime? now}) => resolveThemePalette(
      activeTheme(platform),
      seasonalOverride: seasonalOverride, seasonalHolidays: seasonalHolidays, now: now);
  bool statistics = true;
  bool meshHealth = true;
  bool encounters = true;

  /// Delete channel messages older than this many days; 0 keeps them.
  int channelRetentionDays = 0;

  /// Messages kept in each conversation (a channel or a direct thread).
  int historyLimit = BastionHistoryLimit.standard;

  /// Read incoming messages aloud while the app is open.
  bool readAloud = false;

  /// Miles and feet, or kilometers and meters. Defaults from the phone's region.
  BastionUnits units = BastionUnits.metric;
  String? error;

  static const retentionChoices = [0, 1, 7, 30];

  Future<void> load() async {
    try {
      final p = SharedPreferencesAsync();
      final saved = await p.getString('bastion.app_theme');
      if (saved != null) {
        appTheme = BastionTheme.fromId(saved).id;
        final dark = await p.getString('bastion.dark_mode_theme') ?? '';
        darkModeTheme = dark.isEmpty ? '' : BastionTheme.fromId(dark).id;
      } else {
        // Before the eight themes there was only light, dark or system.
        final mode = await p.getString('bastion.theme');
        appTheme = BastionTheme.fromId(mode ?? 'dark').id;
        darkModeTheme = mode == 'system' ? BastionTheme.blaze.id : '';
      }
      seasonalOverride = await p.getString('bastion.seasonal_override') ?? 'auto';
      seasonalHolidays = await p.getBool('bastion.seasonal_holidays') ?? true;
      storeForwardCatchUp = await p.getBool('bastion.store_forward_catch_up') ?? false;
      mqttProxy = await p.getBool('bastion.mqtt_proxy') ?? false;
      heardWithin = BastionHeardWithin.fromName(await p.getString('bastion.nodes.heard_within'));
      favoritesOnly = await p.getBool('bastion.nodes.favorites_only') ?? false;
      statistics = await p.getBool('bastion.dashboard.statistics') ?? true;
      meshHealth = await p.getBool('bastion.dashboard.health') ?? true;
      encounters = await p.getBool('bastion.dashboard.encounters') ?? true;
      channelRetentionDays = await p.getInt('bastion.messages.channel_retention_days') ?? 0;
      readAloud = await p.getBool('bastion.messages.read_aloud') ?? false;
      final limit = await p.getInt('bastion.messages.history_limit');
      historyLimit = BastionHistoryLimit.choices.contains(limit) ? limit! : BastionHistoryLimit.standard;
      final unitName = await p.getString('bastion.units');
      units = BastionUnits.values.where((u) => u.name == unitName).firstOrNull ??
          BastionUnitFormat.defaultFor(WidgetsBinding.instance.platformDispatcher.locale.countryCode);
    } catch (_) { error = 'Appearance preferences could not be loaded.'; }
    notifyListeners();
  }

  Future<void> update({bool? catchUp, bool? proxyMqtt, BastionHeardWithin? heard, bool? favorites, String? theme, String? darkTheme, String? season, bool? holidays, bool? stats, bool? health, bool? saved,
      int? retentionDays, bool? speak, BastionUnits? unitSystem, int? keepMessages}) async {
    storeForwardCatchUp = catchUp ?? storeForwardCatchUp;
    mqttProxy = proxyMqtt ?? mqttProxy;
    heardWithin = heard ?? heardWithin;
    favoritesOnly = favorites ?? favoritesOnly;
    appTheme = theme ?? appTheme;
    darkModeTheme = darkTheme ?? darkModeTheme;
    seasonalOverride = season ?? seasonalOverride;
    seasonalHolidays = holidays ?? seasonalHolidays;
    statistics = stats ?? statistics;
    meshHealth = health ?? meshHealth;
    encounters = saved ?? encounters;
    channelRetentionDays = retentionDays ?? channelRetentionDays;
    readAloud = speak ?? readAloud;
    historyLimit = keepMessages ?? historyLimit;
    units = unitSystem ?? units;
    error = null;
    notifyListeners();
    try {
      final p = SharedPreferencesAsync();
      await p.setString('bastion.app_theme', appTheme);
      await p.setString('bastion.dark_mode_theme', darkModeTheme);
      await p.setString('bastion.seasonal_override', seasonalOverride);
      await p.setBool('bastion.seasonal_holidays', seasonalHolidays);
      await p.setBool('bastion.store_forward_catch_up', storeForwardCatchUp);
      await p.setBool('bastion.mqtt_proxy', mqttProxy);
      await p.setString('bastion.nodes.heard_within', heardWithin.name);
      await p.setBool('bastion.nodes.favorites_only', favoritesOnly);
      await p.setBool('bastion.dashboard.statistics', statistics);
      await p.setBool('bastion.dashboard.health', meshHealth);
      await p.setBool('bastion.dashboard.encounters', encounters);
      await p.setInt('bastion.messages.channel_retention_days', channelRetentionDays);
      await p.setBool('bastion.messages.read_aloud', readAloud);
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
          ListTile(
            title: const Text('Units'),
            subtitle: const Text('Distances and altitudes'),
            trailing: SegmentedButton<BastionUnits>(
              segments: const [
                ButtonSegment(value: BastionUnits.metric, label: Text('km, m')),
                ButtonSegment(value: BastionUnits.imperial, label: Text('mi, ft')),
              ],
              selected: {p.units},
              showSelectedIcon: false,
              onSelectionChanged: (v) => p.update(unitSystem: v.single),
            ),
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
