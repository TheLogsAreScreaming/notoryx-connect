import 'dart:async';

import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';
import 'services/bastion_map_layers.dart';
import 'services/bastion_phone_position.dart';
import 'services/bastion_preferences.dart';
import 'services/bastion_track_log.dart';
import 'services/bastion_units.dart';
import 'theme/notoryx_theme.dart';
import 'theme/notoryx_tokens.dart';
import 'theme/nx_components.dart';

/// Hands a GPX file to the share sheet; the map page's own sharer.
typedef TrackShare = Future<void> Function(String fileName, String text);

/// Record where you go, Start to Stop; export it, show it on the map, or be
/// warned when you stray from it later. As on NOTORYX Core.
class TrackLogPage extends StatelessWidget {
  const TrackLogPage({
    super.key,
    required this.log,
    required this.share,
    this.location,
    this.layers,
  });

  final BastionTrackLog log;
  final TrackShare share;

  /// Asked for location access before recording; null skips the check.
  final PhoneLocationSource? location;

  /// Defaults to [BastionMapLayers.instance].
  final BastionMapLayers? layers;

  static String duration(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60;
    return h > 0 ? '$h h ${m.toString().padLeft(2, '0')} min' : '$m min';
  }

  Future<void> _start(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = l.tlgDefaultName(MaterialLocalizations.of(context).formatMediumDate(DateTime.now()));
    final problem = await location?.ensureAccess();
    // Without phone location the radio's GPS can still feed the track.
    if (problem != null) messenger.showSnackBar(SnackBar(content: Text(l.tlgPhoneLocationOff(problem))));
    await log.start(name);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tlgTitle)),
      body: ListenableBuilder(
        listenable: log,
        builder: (context, _) {
          final units = BastionPreferences.instance.units;
          final now = DateTime.now();
          final running = log.recording;
          final finished = [for (final t in log.tracks) if (!t.isRecording) t];
          return ListView(
            padding: NxSpace.page,
            children: [
              Text(l.tlgSources, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: NxSpace.md),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(NxSpace.md),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (running != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Row(children: [
                          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                          const SizedBox(width: NxSpace.xs),
                          Expanded(
                              child: Text(l.tlgRecording, style: Theme.of(context).textTheme.titleMedium)),
                        ]),
                      ),
                      const SizedBox(height: NxSpace.xs),
                      Text(l.tlgStats(running.points.length, BastionUnitFormat.distance(running.meters, units),
                          duration(running.duration(now)))),
                      const SizedBox(height: NxSpace.sm),
                      FilledButton.icon(
                        key: const ValueKey('track-stop'),
                        onPressed: () => unawaited(log.stop()),
                        icon: const Icon(Icons.stop),
                        label: Text(l.tlgStop),
                      ),
                    ] else
                      FilledButton.icon(
                        key: const ValueKey('track-start'),
                        onPressed: () => unawaited(_start(context)),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l.tlgStart),
                      ),
                  ]),
                ),
              ),
              if (log.watchedTrack case final watched?)
                NxBanner(
                  key: const ValueKey('track-watching'),
                  tone: NxTone.info,
                  icon: Icons.near_me_outlined,
                  title: l.tlgWatching(watched.name,
                      BastionUnitFormat.distance(log.watch!.limitMeters, units)),
                  message: log.lastOffMeters == null
                      ? l.tlgWaitingFix
                      : l.tlgOffNow(BastionUnitFormat.distance(log.lastOffMeters!, units)),
                ),
              NxSectionLabel(l.tlgSaved),
              if (finished.isEmpty)
                Padding(padding: const EdgeInsets.all(NxSpace.sm), child: Text(l.tlgEmpty))
              else
                for (final t in finished)
                  Card(
                    child: ListTile(
                      key: ValueKey('track-${t.id}'),
                      leading: Icon(log.watch?.trackId == t.id ? Icons.near_me : Icons.timeline),
                      title: Text(t.name),
                      subtitle: Text(l.tlgStats(
                          t.points.length, BastionUnitFormat.distance(t.meters, units), duration(t.duration(now)))),
                      trailing: const Icon(Icons.more_vert),
                      onTap: () => _actions(context, t),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _actions(BuildContext context, Track t) async {
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final units = BastionPreferences.instance.units;
    final watching = log.watch?.trackId == t.id;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          ListTile(title: Text(t.name, style: Theme.of(sheet).textTheme.titleMedium)),
          if (t.points.length >= 2) ...[
            ListTile(
              key: const ValueKey('track-map'),
              leading: const Icon(Icons.map_outlined),
              title: Text(l.tlgShowMap),
              onTap: () => Navigator.pop(sheet, 'map'),
            ),
            ListTile(
              key: const ValueKey('track-gpx'),
              leading: const Icon(Icons.ios_share),
              title: Text(l.tlgExport),
              onTap: () => Navigator.pop(sheet, 'gpx'),
            ),
            if (watching)
              ListTile(
                key: const ValueKey('track-unwatch'),
                leading: const Icon(Icons.near_me_disabled_outlined),
                title: Text(l.tlgUnwatch),
                onTap: () => Navigator.pop(sheet, 'unwatch'),
              )
            else
              for (final limit in BastionTrackLog.limits)
                ListTile(
                  key: ValueKey('track-watch-${limit.round()}'),
                  leading: const Icon(Icons.near_me_outlined),
                  title: Text(l.tlgWatchAt(BastionUnitFormat.distance(limit, units))),
                  onTap: () => Navigator.pop(sheet, 'watch:$limit'),
                ),
          ],
          ListTile(
            key: const ValueKey('track-delete'),
            leading: Icon(Icons.delete_outline, color: Theme.of(sheet).colorScheme.error),
            title: Text(l.tlgDelete),
            onTap: () => Navigator.pop(sheet, 'delete'),
          ),
        ]),
      ),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case 'map':
        try {
          await (layers ?? BastionMapLayers.instance).import(t.name, t.toGpx(DateTime.now()));
          messenger.showSnackBar(SnackBar(content: Text(l.tlgOnMap)));
        } on Object catch (e) {
          messenger.showSnackBar(SnackBar(content: Text(l.tlgMapFailed)));
          debugPrint('Track to map failed: $e');
        }
      case 'gpx':
        final file = '${t.name.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim().replaceAll(' ', '_')}.gpx';
        await share(file.length > 4 ? file : 'track.gpx', t.toGpx(DateTime.now()));
      case 'unwatch':
        await log.watchTrack(null);
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: Text(l.tlgDeleteQ),
            content: Text(t.name),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d, false), child: Text(l.commonCancel)),
              TextButton(
                  key: const ValueKey('track-delete-confirm'),
                  onPressed: () => Navigator.pop(d, true),
                  child: Text(l.tlgDelete)),
            ],
          ),
        );
        if (ok == true) await log.delete(t);
      default:
        if (choice.startsWith('watch:')) {
          await log.watchTrack(t, limitMeters: double.parse(choice.substring(6)));
        }
    }
  }
}
