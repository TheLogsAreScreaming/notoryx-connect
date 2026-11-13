import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_day_tracks.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_trails.dart';
import 'services/bastion_units.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// Track colours. Each member also gets a numbered badge, so colour is
/// never the only way to tell them apart. All keep 3:1 on light map tiles.
const _trackColors = [
  Color(0xFFC2410C), Color(0xFF1D4ED8), Color(0xFF15803D), Color(0xFF7E22CE),
  Color(0xFFB91C1C), Color(0xFF0E7490), Color(0xFFA16207), Color(0xFFBE185D),
];

/// Plays back where team members went on a chosen day, with a time scrubber.
class DayReplayPage extends StatefulWidget {
  const DayReplayPage({
    super.key,
    required this.tracks,
    required this.nameOf,
    this.showMap = true,
  });

  final BastionDayTracks tracks;
  final String Function(int num) nameOf;

  /// Tests turn the tile map off; everything else still renders.
  final bool showMap;

  @override
  State<DayReplayPage> createState() => _DayReplayPageState();
}

class _DayReplayPageState extends State<DayReplayPage> {
  List<DateTime>? _days;
  DateTime? _day;
  Map<int, List<TrailPoint>> _tracks = const {};
  ({DateTime start, DateTime end})? _span;
  DateTime? _at;
  Timer? _timer;
  int _speed = 300;

  static const _tick = Duration(milliseconds: 100);
  static const _speeds = [60, 300, 900];

  @override
  void initState() {
    super.initState();
    _loadDays();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadDays() async {
    final days = await widget.tracks.days();
    if (!mounted) return;
    setState(() => _days = days);
    if (days.isNotEmpty) await _pick(days.first);
  }

  Future<void> _pick(DateTime day) async {
    _pause();
    final tracks = await widget.tracks.tracksOn(day);
    if (!mounted) return;
    final span = DayReplay.span(tracks);
    setState(() {
      _day = day;
      _tracks = tracks;
      _span = span;
      _at = span?.start;
    });
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
  }

  void _togglePlay() {
    final span = _span;
    if (span == null) return;
    if (_timer != null) {
      setState(_pause);
      return;
    }
    if (!_at!.isBefore(span.end)) _at = span.start;
    _timer = Timer.periodic(_tick, (_) {
      final next = _at!.add(_tick * _speed);
      setState(() {
        if (next.isBefore(span.end)) {
          _at = next;
        } else {
          _at = span.end;
          _pause();
        }
      });
    });
    setState(() {});
  }

  String _time(BuildContext context, DateTime t) =>
      MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(t.toLocal()));

  String _date(BuildContext context, DateTime d) =>
      MaterialLocalizations.of(context).formatMediumDate(d);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final days = _days;
    return Scaffold(
      appBar: AppBar(title: Text(l.drTitle)),
      body: days == null
          ? const Center(child: CircularProgressIndicator())
          : days.isEmpty
              ? ListView(padding: NxSpace.page, children: [
                  NxEmptyState(icon: Icons.history_toggle_off, title: l.drEmptyTitle, detail: l.drEmptyDetail),
                ])
              : _body(context, l, days),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l, List<DateTime> days) {
    final span = _span;
    final at = _at;
    final members = _tracks.keys.toList()..sort();
    final units = BastionPreferences.instance.units;
    return ListView(padding: NxSpace.page, children: [
      NxPageHeader(title: l.drTitle, subtitle: l.drSubtitle),
      DropdownButtonFormField<DateTime>(
        initialValue: _day,
        decoration: InputDecoration(labelText: l.drDay),
        items: [
          for (final d in days) DropdownMenuItem(value: d, child: Text(_date(context, d))),
        ],
        onChanged: (d) {
          if (d != null) _pick(d);
        },
      ),
      const SizedBox(height: NxSpace.sm),
      if (span == null || at == null)
        Text(l.drNoPositions)
      else ...[
        if (widget.showMap)
          SizedBox(height: 320, child: _map(context, l, members, at)),
        const SizedBox(height: NxSpace.sm),
        Row(children: [
          IconButton.filled(
            tooltip: _timer == null ? l.drPlay : l.drPause,
            onPressed: _togglePlay,
            icon: Icon(_timer == null ? Icons.play_arrow : Icons.pause),
          ),
          const SizedBox(width: NxSpace.xs),
          Expanded(child: Semantics(
            liveRegion: _timer == null,
            child: Text(l.drAt(_time(context, at)), style: Theme.of(context).textTheme.titleMedium),
          )),
        ]),
        Slider(
          min: 0,
          max: span.end.difference(span.start).inSeconds.toDouble().clamp(1, double.infinity),
          value: at.difference(span.start).inSeconds.toDouble(),
          label: _time(context, at),
          semanticFormatterCallback: (_) => _time(context, at),
          onChangeStart: (_) => setState(_pause),
          onChanged: (v) => setState(() => _at = span.start.add(Duration(seconds: v.round()))),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_time(context, span.start)),
          Text(_time(context, span.end)),
        ]),
        const SizedBox(height: NxSpace.xs),
        Wrap(spacing: NxSpace.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(l.drSpeed),
          for (final s in _speeds)
            ChoiceChip(
              label: Text(l.drSpeedTimes(s)),
              selected: _speed == s,
              onSelected: (_) => setState(() => _speed = s),
            ),
        ]),
        NxSectionLabel(l.drWho),
        for (final (i, num) in members.indexed)
          _memberTile(context, l, i, num, at, units),
      ],
    ]);
  }

  Widget _memberTile(BuildContext context, AppLocalizations l, int i, int num, DateTime at, BastionUnits units) {
    final track = _tracks[num]!;
    final fix = DayReplay.positionAt(track, at);
    final walked = DayReplay.distance(DayReplay.walked(track, at));
    final status = fix == null
        ? l.drNotYet(_time(context, track.first.time))
        : fix.moving
            ? l.drMoving(_time(context, fix.fixTime))
            : l.drStill(_time(context, fix.fixTime));
    return Card(child: ListTile(
      leading: _Badge(index: i),
      title: Text(widget.nameOf(num)),
      subtitle: Text('$status\n${l.drCovered(BastionUnitFormat.distance(walked, units))}'),
      isThreeLine: true,
    ));
  }

  Widget _map(BuildContext context, AppLocalizations l, List<int> members, DateTime at) {
    final all = [for (final t in _tracks.values) for (final p in t) LatLng(p.latitude, p.longitude)];
    final single = all.toSet().length < 2;
    final summary = l.drMapSummary(members.length, _time(context, at));
    return Semantics(
      label: summary,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(NxRadius.md),
        child: FlutterMap(
          key: ValueKey(_day),
          options: MapOptions(
            initialCameraFit: single
                ? null
                : CameraFit.bounds(bounds: LatLngBounds.fromPoints(all), padding: const EdgeInsets.all(32)),
            initialCenter: all.first,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bastionmesh.connect',
              maxNativeZoom: 19,
            ),
            PolylineLayer(polylines: [
              for (final (i, num) in members.indexed) ...[
                if (_tracks[num]!.length >= 2)
                  Polyline(
                    points: [for (final p in _tracks[num]!) LatLng(p.latitude, p.longitude)],
                    color: _trackColors[i % _trackColors.length].withValues(alpha: 0.3),
                    strokeWidth: 3,
                  ),
                if (DayReplay.walked(_tracks[num]!, at) case final walked when walked.length >= 2)
                  Polyline(
                    points: [for (final p in walked) LatLng(p.latitude, p.longitude)],
                    color: _trackColors[i % _trackColors.length],
                    strokeWidth: 4,
                  ),
              ],
            ]),
            MarkerLayer(markers: [
              for (final (i, num) in members.indexed)
                if (DayReplay.positionAt(_tracks[num]!, at) case final fix?)
                  Marker(
                    point: LatLng(fix.latitude, fix.longitude),
                    width: 32,
                    height: 32,
                    child: _Badge(index: i),
                  ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// A numbered disc in the member's track colour.
class _Badge extends StatelessWidget {
  const _Badge({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _trackColors[index % _trackColors.length],
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Text('${index + 1}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      );
}
