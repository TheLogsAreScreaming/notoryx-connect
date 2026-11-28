import 'package:flutter/material.dart';

import 'generated/meshtastic/config.pb.dart';
import 'l10n/generated/app_localizations.dart';
import 'local_mesh_discovery_page.dart';
import 'services/bastion_radio_policy.dart';
import 'services/bastion_region_suggest.dart';
import 'services/meshtastic_radio_coordinator.dart';

/// First setup for a radio with no region: it can't transmit until one is
/// set. Suggests the region for the phone's country, keeps the radio's
/// other LoRa settings, saves, then offers to look for meshes nearby.
class RegionSetupPage extends StatefulWidget {
  const RegionSetupPage({super.key, required this.radio, this.countryCode});

  final MeshtasticRadioCoordinator radio;

  /// The phone's country; read from the locale when null.
  final String? countryCode;

  @override
  State<RegionSetupPage> createState() => _RegionSetupPageState();
}

class _RegionSetupPageState extends State<RegionSetupPage> {
  Config_LoRaConfig_RegionCode? _region;
  Config_LoRaConfig_RegionCode? _suggested;
  bool _suggestedOnce = false;
  bool _saving = false;
  bool _saved = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_suggestedOnce) return;
    _suggestedOnce = true;
    _suggested = BastionRegionSuggest.forCountry(
      widget.countryCode ??
          Localizations.maybeLocaleOf(context)?.countryCode ??
          WidgetsBinding.instance.platformDispatcher.locale.countryCode,
    );
    _region = _suggested;
  }

  Future<void> _save() async {
    final region = _region;
    if (region == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final draft = (widget.radio.loraConfig ?? Config_LoRaConfig()).deepCopy();
      if (!draft.hasUsePreset() && !draft.hasModemPreset())
        draft.usePreset = true;
      BastionRadioPolicy.chooseRegion(
        draft,
        region,
        widget.radio.firmwareVersion,
      );
      await widget.radio.writeConfig(Config(lora: draft));
      if (mounted) setState(() => _saved = true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _name(Config_LoRaConfig_RegionCode r) => r.name.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final regions = [
      for (final r in Config_LoRaConfig_RegionCode.values)
        if (r != Config_LoRaConfig_RegionCode.UNSET) r,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.regionSetupTitle)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.regionSetupIntro),
            const SizedBox(height: 16),
            DropdownButtonFormField<Config_LoRaConfig_RegionCode>(
              key: const ValueKey('region-setup-region'),
              initialValue: _region,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l.rsRegion,
                helperText: _region != null && _region == _suggested
                    ? l.regionSetupSuggested
                    : l.regionSetupCheckLaw,
                helperMaxLines: 3,
              ),
              items: [
                for (final r in regions)
                  DropdownMenuItem(value: r, child: Text(_name(r))),
              ],
              onChanged: _saving || _saved
                  ? null
                  : (r) => setState(() => _region = r),
            ),
            const SizedBox(height: 24),
            if (!_saved)
              FilledButton.icon(
                key: const ValueKey('region-setup-save'),
                onPressed:
                    _region == null || _saving || !widget.radio.canAdminister
                    ? null
                    : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(l.regionSetupSave),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                l.regionSetupFailed(_error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_saved) ...[
              ListTile(
                key: const ValueKey('region-setup-done'),
                leading: const Icon(Icons.check_circle_outline),
                title: Text(l.regionSetupDone),
                subtitle: Text(l.regionSetupRestart),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey('region-setup-discover'),
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => LocalMeshDiscoveryPage(radio: widget.radio),
                  ),
                ),
                icon: const Icon(Icons.travel_explore),
                label: Text(l.regionSetupFindMeshes),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
