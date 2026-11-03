/// Pure scan planning for Meshtastic LoRa modem presets.
///
/// This model deliberately does not write radio settings. A future scanner
/// must acquire the radio configuration lock, snapshot the original settings,
/// and restore them on success, cancellation, or failure.
enum DiscoveryPreset {
  longFast,
  longModerate,
  longSlow,
  mediumFast,
  mediumSlow,
  shortFast,
  shortSlow,
  shortTurbo,
}

extension DiscoveryPresetLabel on DiscoveryPreset {
  String get label => switch (this) {
    DiscoveryPreset.longFast => 'Long Range - Fast',
    DiscoveryPreset.longModerate => 'Long Range - Moderate',
    DiscoveryPreset.longSlow => 'Long Range - Slow',
    DiscoveryPreset.mediumFast => 'Medium Range - Fast',
    DiscoveryPreset.mediumSlow => 'Medium Range - Slow',
    DiscoveryPreset.shortFast => 'Short Range - Fast',
    DiscoveryPreset.shortSlow => 'Short Range - Slow',
    DiscoveryPreset.shortTurbo => 'Short Range - Turbo',
  };
}

class LocalMeshDiscoveryPlan {
  LocalMeshDiscoveryPlan({
    required Iterable<DiscoveryPreset> presets,
    required this.dwell,
  }) : presets = List.unmodifiable(presets.toSet()) {
    if (this.presets.isEmpty) {
      throw ArgumentError.value(presets, 'presets', 'Select a preset');
    }
    if (dwell < const Duration(minutes: 1) ||
        dwell > const Duration(minutes: 30)) {
      throw ArgumentError.value(dwell, 'dwell', 'Use 1 to 30 minutes');
    }
  }

  final List<DiscoveryPreset> presets;
  final Duration dwell;

  Duration get estimatedListeningTime =>
      Duration(microseconds: dwell.inMicroseconds * presets.length);

  static const recommended = <DiscoveryPreset>[
    DiscoveryPreset.longFast,
    DiscoveryPreset.mediumFast,
  ];
}
