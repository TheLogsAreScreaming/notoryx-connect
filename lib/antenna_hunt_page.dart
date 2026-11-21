import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_traffic.dart';
import 'services/meshtastic_node_database.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// How long between clicks for an SNR: about 1.5 s when barely heard, down
/// to about 0.12 s when strong, like a metal detector. As on NOTORYX Core.
Duration clickIntervalFor(double snr) {
  final t = ((snr + 15) / 27).clamp(0.0, 1.0);
  return Duration(milliseconds: (1500 - t * 1380).round());
}

/// What the hunt page needs from the radio; the coordinator in the app,
/// a fake in tests.
abstract interface class HuntRadio {
  List<MeshtasticNode> get nodes;
  int? get localNodeNum;
  Stream<TrafficPacket> get packets;

  /// Asks [num] to reply. Returns the SNR it heard us at, when known.
  Future<double?> askReply(int num);
}

/// Antenna hunt: listens to one node heard directly and shows how well this
/// radio hears it in very large digits, clicking faster as it improves, so
/// you can turn an antenna or walk around without staring at the screen.
class AntennaHuntPage extends StatefulWidget {
  const AntennaHuntPage({super.key, required this.radio, this.clock = DateTime.now, this.sounds = true});

  final HuntRadio radio;
  final DateTime Function() clock;

  /// Off in tests, where there is no sound or vibration.
  final bool sounds;

  /// How often a reply is asked for, when that is on.
  static const pingEvery = Duration(seconds: 30);

  /// Not heard for this long: the clicks stop rather than keep a stale beat.
  static const lostAfter = Duration(minutes: 2);

  @override
  State<AntennaHuntPage> createState() => _AntennaHuntPageState();
}

class _AntennaHuntPageState extends State<AntennaHuntPage> {
  MeshtasticNode? _target;
  bool _hunting = false;
  bool _sound = true;
  bool _ping = false;
  double? _snr, _best, _theyHear;
  int? _rssi;
  DateTime? _heard;
  StreamSubscription<TrafficPacket>? _sub;
  Timer? _clicks, _pinger, _tick;

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start() {
    final target = _target;
    if (target == null) return;
    setState(() {
      _hunting = true;
      _snr = _best = _theyHear = null;
      _rssi = null;
      _heard = null;
    });
    _sub = widget.radio.packets.listen((p) {
      // Only what the node itself sends straight to us says how we hear it.
      if (p.from != target.num || p.viaMqtt || (p.hopsAway ?? 0) != 0) return;
      final snr = p.snr;
      if (snr == null) return;
      setState(() {
        _snr = snr;
        _rssi = p.rssi;
        _heard = widget.clock();
        if (_best == null || snr > _best!) _best = snr;
      });
      _retune();
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _retune();
    });
    if (_ping) _startPinging();
  }

  void _startPinging() {
    _pinger?.cancel();
    Future<void> ask() async {
      final target = _target;
      if (target == null || !_hunting) return;
      try {
        final theyHear = await widget.radio.askReply(target.num);
        if (mounted && theyHear != null) setState(() => _theyHear = theyHear);
      } on Object catch (e) {
        debugPrint('Antenna hunt reply request failed: $e');
      }
    }

    unawaited(ask());
    _pinger = Timer.periodic(AntennaHuntPage.pingEvery, (_) => unawaited(ask()));
  }

  void _stop() {
    _hunting = false;
    unawaited(_sub?.cancel());
    _sub = null;
    _clicks?.cancel();
    _pinger?.cancel();
    _tick?.cancel();
    _clicks = _pinger = _tick = null;
  }

  bool get _lost {
    final heard = _heard;
    return heard == null || widget.clock().difference(heard) > AntennaHuntPage.lostAfter;
  }

  Duration? _interval;

  void _retune() {
    final snr = _snr;
    final want = _hunting && _sound && snr != null && !_lost ? clickIntervalFor(snr) : null;
    if (want == _interval) return;
    _clicks?.cancel();
    _clicks = null;
    _interval = want;
    if (want == null || !widget.sounds) return;
    _clicks = Timer.periodic(want, (_) {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.selectionClick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final target = _target;
    return Scaffold(
      appBar: AppBar(title: Text(l.ahTitle)),
      body: target == null ? _picker(context, l) : _hunt(context, l, target),
    );
  }

  Widget _picker(BuildContext context, AppLocalizations l) {
    final now = widget.clock();
    final direct = [
      for (final n in widget.radio.nodes)
        if (n.num != widget.radio.localNodeNum && n.hopsAway == 0 && !n.viaMqtt) n,
    ]..sort((a, b) => (b.lastHeard ?? DateTime(0)).compareTo(a.lastHeard ?? DateTime(0)));
    if (direct.isEmpty) {
      return Center(
        child: NxEmptyState(icon: Icons.settings_input_antenna, title: l.ahPick, detail: l.ahNoneDirect),
      );
    }
    return ListView(padding: NxSpace.page, children: [
      Text(l.ahToolSub),
      NxSectionLabel(l.ahPick),
      for (final n in direct)
        Card(
          child: ListTile(
            key: ValueKey('hunt-${n.num}'),
            title: Text(n.displayName),
            subtitle: Text([
              if (n.snr case final s?) 'SNR ${s.toStringAsFixed(1)} dB',
              if (n.lastHeard case final h?) l.ahAgo(now.difference(h).inSeconds.clamp(0, 1 << 30)),
            ].join(' • ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => setState(() => _target = n),
          ),
        ),
    ]);
  }

  Widget _hunt(BuildContext context, AppLocalizations l, MeshtasticNode target) {
    final type = Theme.of(context).textTheme;
    final snr = _snr;
    final heard = _heard;
    return ListView(padding: NxSpace.page, children: [
      Row(children: [
        Expanded(child: Text(target.displayName, style: type.titleLarge)),
        TextButton(
          onPressed: _hunting ? null : () => setState(() => _target = null),
          child: Text(l.ahChange),
        ),
      ]),
      const SizedBox(height: NxSpace.md),
      // The reading, big enough to see at arm's length.
      Semantics(
        liveRegion: true,
        label: snr == null ? null : '${l.ahYouHear}: ${snr.toStringAsFixed(1)} dB',
        child: Column(children: [
          Text(l.ahYouHear, style: type.labelLarge),
          Text(
            snr == null ? '–' : '${snr.toStringAsFixed(1)} dB',
            key: const ValueKey('hunt-snr'),
            style: type.displayLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (_rssi case final r? when r != 0) Text('RSSI $r dBm', style: type.titleMedium),
        ]),
      ),
      const SizedBox(height: NxSpace.md),
      NxStatRow(children: [
        NxStatTile(label: l.ahBest, value: _best == null ? '–' : '${_best!.toStringAsFixed(1)} dB', icon: Icons.star_outline),
        NxStatTile(
            label: l.ahTheyHear,
            value: _theyHear == null ? '–' : '${_theyHear!.toStringAsFixed(1)} dB',
            icon: Icons.hearing),
      ]),
      const SizedBox(height: NxSpace.sm),
      if (_hunting)
        Text(
          heard == null
              ? l.ahWaiting(target.displayName)
              : _lost
                  ? l.ahLost
                  : l.ahAgo(widget.clock().difference(heard).inSeconds),
          key: const ValueKey('hunt-status'),
        ),
      const SizedBox(height: NxSpace.md),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l.ahSound),
        value: _sound,
        onChanged: (v) {
          setState(() => _sound = v);
          _retune();
        },
      ),
      SwitchListTile(
        key: const ValueKey('hunt-ping'),
        contentPadding: EdgeInsets.zero,
        title: Text(l.ahPing),
        subtitle: Text(l.ahPingSub),
        value: _ping,
        onChanged: (v) {
          setState(() => _ping = v);
          if (!_hunting) return;
          if (v) {
            _startPinging();
          } else {
            _pinger?.cancel();
          }
        },
      ),
      const SizedBox(height: NxSpace.sm),
      FilledButton.icon(
        key: const ValueKey('hunt-toggle'),
        onPressed: () {
          if (_hunting) {
            setState(_stop);
          } else {
            _start();
          }
        },
        icon: Icon(_hunting ? Icons.stop : Icons.play_arrow),
        label: Text(_hunting ? l.ahStop : l.ahStart),
      ),
    ]);
  }
}

/// The app's radio, for the hunt page.
class CoordinatorHuntRadio implements HuntRadio {
  CoordinatorHuntRadio(this.radio);
  final MeshtasticRadioCoordinator radio;

  @override
  List<MeshtasticNode> get nodes => radio.nodes;

  @override
  int? get localNodeNum => radio.localNodeNum;

  @override
  Stream<TrafficPacket> get packets => radio.traffic.packets;

  /// A traceroute: its reply is heard like any packet, and its first hop
  /// says how well the node heard us.
  @override
  Future<double?> askReply(int num) async {
    if (!radio.canTraceroute) return null;
    final result = await radio.traceroute(num);
    return result.towards.isEmpty ? null : result.towards.last.snrDb;
  }
}
