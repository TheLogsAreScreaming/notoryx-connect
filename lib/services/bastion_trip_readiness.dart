import 'bastion_firmware.dart';

enum ReadinessStatus { ready, warning, blocked, unknown }

/// One line of the pre-trip check.
class ReadinessItem {
  const ReadinessItem(this.id, this.title, this.status, this.detail);
  final String id;
  final String title;
  final ReadinessStatus status;
  final String detail;
}

/// A trip contact, when it was last heard, and any test just run on it.
class ReadinessContact {
  const ReadinessContact({required this.num, required this.name, this.lastHeard, this.testReached});
  final int num;
  final String name;
  final DateTime? lastHeard;

  /// Result of a route test run from the check; null when none was run.
  final bool? testReached;
}

/// What the pre-trip check looks at.
class ReadinessFacts {
  const ReadinessFacts({
    required this.radioReady,
    required this.now,
    this.batteryPercent,
    this.firmwareVersion,
    this.channelCount = 0,
    this.sosChannel = -1,
    this.sosChannelExists = true,
    this.contacts = const [],
    this.positionTime,
    this.sharesPhoneLocation = false,
    this.backgroundRestricted,
  });

  final bool radioReady;
  final DateTime now;

  /// 0–100, 101 when externally powered, null when unknown.
  final int? batteryPercent;
  final String? firmwareVersion;
  final int channelCount;
  final int sosChannel;
  final bool sosChannelExists;
  final List<ReadinessContact> contacts;

  /// When your radio's position was last updated.
  final DateTime? positionTime;
  final bool sharesPhoneLocation;

  /// True when battery optimisation may stop the app; null when unknown.
  final bool? backgroundRestricted;
}

/// The six checks to run before leaving: battery, firmware, channel,
/// contacts, position and background. Pure and read-only; it sends nothing.
abstract final class BastionTripReadiness {
  static const lowBattery = 30;
  static const okBattery = 60;
  static const contactFresh = Duration(hours: 2);
  static const positionFresh = Duration(hours: 1);

  static List<ReadinessItem> check(ReadinessFacts f) => [
        _battery(f),
        _firmware(f),
        _channel(f),
        _contacts(f),
        _position(f),
        _background(f),
      ];

  /// The worst status in [items], for the summary line.
  static ReadinessStatus overall(List<ReadinessItem> items) {
    if (items.any((i) => i.status == ReadinessStatus.blocked)) return ReadinessStatus.blocked;
    if (items.any((i) => i.status == ReadinessStatus.warning)) return ReadinessStatus.warning;
    if (items.any((i) => i.status == ReadinessStatus.unknown)) return ReadinessStatus.unknown;
    return ReadinessStatus.ready;
  }

  static ReadinessItem _battery(ReadinessFacts f) {
    const t = 'Radio battery';
    final b = f.batteryPercent;
    if (!f.radioReady || b == null) return const ReadinessItem('battery', t, ReadinessStatus.unknown, 'Not reported yet.');
    if (b > 100) return const ReadinessItem('battery', t, ReadinessStatus.ready, 'On external power.');
    if (b < lowBattery) return ReadinessItem('battery', t, ReadinessStatus.blocked, '$b%. Charge the radio before you leave.');
    if (b < okBattery) return ReadinessItem('battery', t, ReadinessStatus.warning, '$b%. Consider charging or bringing a power bank.');
    return ReadinessItem('battery', t, ReadinessStatus.ready, '$b%.');
  }

  static ReadinessItem _firmware(ReadinessFacts f) {
    const t = 'Firmware';
    if (!f.radioReady) return const ReadinessItem('firmware', t, ReadinessStatus.unknown, 'Connect your radio to check.');
    final advice = BastionFirmware.advice(f.firmwareVersion);
    return switch (BastionFirmware.supportOf(f.firmwareVersion)) {
      FirmwareSupport.unsupported => ReadinessItem('firmware', t, ReadinessStatus.blocked, advice ?? 'Too old.'),
      FirmwareSupport.outdated => ReadinessItem('firmware', t, ReadinessStatus.warning, advice ?? 'Update recommended.'),
      FirmwareSupport.unknown => const ReadinessItem('firmware', t, ReadinessStatus.unknown, 'Version not reported.'),
      FirmwareSupport.supported => ReadinessItem('firmware', t, ReadinessStatus.ready, f.firmwareVersion ?? 'Supported.'),
    };
  }

  static ReadinessItem _channel(ReadinessFacts f) {
    const t = 'Channels';
    if (!f.radioReady) return const ReadinessItem('channel', t, ReadinessStatus.unknown, 'Connect your radio to check.');
    if (f.channelCount == 0) return const ReadinessItem('channel', t, ReadinessStatus.blocked, 'No channels on this radio.');
    if (f.sosChannel >= 0 && !f.sosChannelExists) {
      return ReadinessItem('channel', t, ReadinessStatus.blocked, 'SOS channel ${f.sosChannel} no longer exists. Pick another in your trip plan.');
    }
    return ReadinessItem('channel', t, ReadinessStatus.ready, '${f.channelCount} channel${f.channelCount == 1 ? '' : 's'} set up.');
  }

  static ReadinessItem _contacts(ReadinessFacts f) {
    const t = 'Trip contacts';
    if (f.contacts.isEmpty) return const ReadinessItem('contacts', t, ReadinessStatus.blocked, 'Choose who gets your check-ins and SOS.');
    bool reachable(ReadinessContact c) =>
        c.testReached ?? (c.lastHeard != null && f.now.difference(c.lastHeard!) <= contactFresh);
    final failed = f.contacts.where((c) => c.testReached == false).toList();
    if (failed.isNotEmpty) {
      return ReadinessItem('contacts', t, ReadinessStatus.warning, 'No route to ${failed.map((c) => c.name).join(', ')}.');
    }
    final quiet = f.contacts.where((c) => !reachable(c)).toList();
    if (quiet.isNotEmpty) {
      return ReadinessItem('contacts', t, ReadinessStatus.warning,
          'Not heard in the last 2 hours: ${quiet.map((c) => c.name).join(', ')}. Run a route test, or check they\'re on.');
    }
    return ReadinessItem('contacts', t, ReadinessStatus.ready, 'All ${f.contacts.length} heard recently.');
  }

  static ReadinessItem _position(ReadinessFacts f) {
    const t = 'Position';
    final p = f.positionTime;
    if (p != null && f.now.difference(p) <= positionFresh) {
      return const ReadinessItem('position', t, ReadinessStatus.ready, 'Your radio has a recent position.');
    }
    if (f.sharesPhoneLocation) {
      return const ReadinessItem('position', t, ReadinessStatus.warning, 'Waiting for a position from this phone. Check location is on.');
    }
    return const ReadinessItem('position', t, ReadinessStatus.warning,
        'No recent position, so others can\'t see where you are. Turn on the radio\'s GPS or share this phone\'s location.');
  }

  static ReadinessItem _background(ReadinessFacts f) {
    const t = 'Background';
    return switch (f.backgroundRestricted) {
      true => const ReadinessItem('background', t, ReadinessStatus.warning,
          'Battery optimisation can cut the link with the screen off. Set NOTORYX Connect to "Unrestricted".'),
      false => const ReadinessItem('background', t, ReadinessStatus.ready, 'The app can stay connected with the screen off.'),
      null => const ReadinessItem('background', t, ReadinessStatus.unknown, 'Couldn\'t check.'),
    };
  }
}
