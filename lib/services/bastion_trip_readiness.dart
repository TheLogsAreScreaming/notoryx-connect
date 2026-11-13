import '../l10n/bastion_text.dart';
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
    final l = BastionText.l;
    final t = l.rdBattery;
    final b = f.batteryPercent;
    if (!f.radioReady || b == null) return ReadinessItem('battery', t, ReadinessStatus.unknown, l.rdNotReported);
    if (b > 100) return ReadinessItem('battery', t, ReadinessStatus.ready, l.rdExternal);
    if (b < lowBattery) return ReadinessItem('battery', t, ReadinessStatus.blocked, l.rdChargeNow(b));
    if (b < okBattery) return ReadinessItem('battery', t, ReadinessStatus.warning, l.rdChargeSoon(b));
    return ReadinessItem('battery', t, ReadinessStatus.ready, l.rdLevel(b));
  }

  static ReadinessItem _firmware(ReadinessFacts f) {
    final l = BastionText.l;
    final t = l.rdFirmware;
    if (!f.radioReady) return ReadinessItem('firmware', t, ReadinessStatus.unknown, l.rdConnectToCheck);
    final advice = BastionFirmware.advice(f.firmwareVersion);
    return switch (BastionFirmware.supportOf(f.firmwareVersion)) {
      FirmwareSupport.unsupported => ReadinessItem('firmware', t, ReadinessStatus.blocked, advice ?? l.rdTooOld),
      FirmwareSupport.outdated => ReadinessItem('firmware', t, ReadinessStatus.warning, advice ?? l.rdUpdateRecommended),
      FirmwareSupport.unknown => ReadinessItem('firmware', t, ReadinessStatus.unknown, l.rdVersionUnknown),
      FirmwareSupport.supported => ReadinessItem('firmware', t, ReadinessStatus.ready, f.firmwareVersion ?? l.rdSupported),
    };
  }

  static ReadinessItem _channel(ReadinessFacts f) {
    final l = BastionText.l;
    final t = l.rdChannels;
    if (!f.radioReady) return ReadinessItem('channel', t, ReadinessStatus.unknown, l.rdConnectToCheck);
    if (f.channelCount == 0) return ReadinessItem('channel', t, ReadinessStatus.blocked, l.rdNoChannels);
    if (f.sosChannel >= 0 && !f.sosChannelExists) {
      return ReadinessItem('channel', t, ReadinessStatus.blocked, l.rdSosChannelGone(f.sosChannel));
    }
    return ReadinessItem('channel', t, ReadinessStatus.ready, l.rdChannelsSet(f.channelCount));
  }

  static ReadinessItem _contacts(ReadinessFacts f) {
    final l = BastionText.l;
    final t = l.rdContacts;
    if (f.contacts.isEmpty) return ReadinessItem('contacts', t, ReadinessStatus.blocked, l.rdChooseContacts);
    bool reachable(ReadinessContact c) =>
        c.testReached ?? (c.lastHeard != null && f.now.difference(c.lastHeard!) <= contactFresh);
    final failed = f.contacts.where((c) => c.testReached == false).toList();
    if (failed.isNotEmpty) {
      return ReadinessItem('contacts', t, ReadinessStatus.warning, l.rdNoRoute(failed.map((c) => c.name).join(', ')));
    }
    final quiet = f.contacts.where((c) => !reachable(c)).toList();
    if (quiet.isNotEmpty) {
      return ReadinessItem('contacts', t, ReadinessStatus.warning,
          l.rdNotHeard(quiet.map((c) => c.name).join(', ')));
    }
    return ReadinessItem('contacts', t, ReadinessStatus.ready, l.rdAllHeard(f.contacts.length));
  }

  static ReadinessItem _position(ReadinessFacts f) {
    final l = BastionText.l;
    final t = l.rdPosition;
    final p = f.positionTime;
    if (p != null && f.now.difference(p) <= positionFresh) {
      return ReadinessItem('position', t, ReadinessStatus.ready, l.rdRecentPosition);
    }
    if (f.sharesPhoneLocation) {
      return ReadinessItem('position', t, ReadinessStatus.warning, l.rdWaitingPhone);
    }
    return ReadinessItem('position', t, ReadinessStatus.warning, l.rdNoPosition);
  }

  static ReadinessItem _background(ReadinessFacts f) {
    final l = BastionText.l;
    final t = l.rdBackground;
    return switch (f.backgroundRestricted) {
      true => ReadinessItem('background', t, ReadinessStatus.warning, l.rdBackgroundRestricted),
      false => ReadinessItem('background', t, ReadinessStatus.ready, l.rdBackgroundOk),
      null => ReadinessItem('background', t, ReadinessStatus.unknown, l.rdCouldntCheck),
    };
  }
}
