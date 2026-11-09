import 'package:flutter/material.dart';

import 'l10n/generated/app_localizations.dart';

import 'services/bastion_trip.dart';
import 'services/meshtastic_radio_coordinator.dart';
import 'trip_readiness_page.dart';

/// Plan your trip: who gets check-ins and SOS, and when to warn.
class TripPage extends StatefulWidget {
  const TripPage({super.key, required this.radio});
  final MeshtasticRadioCoordinator radio;
  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  late final TextEditingController _name =
      TextEditingController(text: widget.radio.trip.plan.name);
  String? _status;

  AppLocalizations get l => AppLocalizations.of(context);

  BastionTripController get _trip => widget.radio.trip;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _update(TripPlan plan) async {
    try {
      await _trip.updatePlan(plan);
      if (mounted) setState(() => _status = null);
    } on ArgumentError catch (e) {
      if (mounted) setState(() => _status = '${e.message}');
    }
  }

  /// Trip contact candidates: nodes heard now plus saved favorites.
  List<({int num, String name})> _candidates() {
    final me = widget.radio.localNodeNum;
    final seen = <int>{};
    final result = <({int num, String name})>[];
    for (final num in [
      ..._trip.plan.members,
      for (final r in widget.radio.nodeDex) if (r.favorite) r.num,
      for (final n in widget.radio.nodes) n.num,
    ]) {
      if (num == me || !seen.add(num)) continue;
      result.add((num: num, name: widget.radio.nodeName(num)));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(l.trTitle)),
    body: SafeArea(top: false, child: AnimatedBuilder(
      animation: widget.radio,
      builder: (context, _) {
        final plan = _trip.plan;
        final channels = widget.radio.channelMetadata.where((c) => c.role != 0).toList();
        return ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.trName),
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (value) => _update(plan.copyWith(name: value.trim().isEmpty ? 'My trip' : value.trim())),
            onTapOutside: (_) {
              final value = _name.text.trim();
              if (value.isNotEmpty && value != plan.name) _update(plan.copyWith(name: value));
            },
          ),
          const SizedBox(height: 16),
          Text(l.trContacts(plan.members.length, TripPlan.maxMembers),
            style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(l.trContactsSub),
          const SizedBox(height: 8),
          if (_candidates().isEmpty)
            Card(child: ListTile(
              leading: const Icon(Icons.person_search),
              title: Text(l.trNoNodes),
              subtitle: Text(l.trNoNodesSub),
            )),
          for (final c in _candidates())
            CheckboxListTile(
              title: Text(c.name),
              subtitle: Text('!${c.num.toRadixString(16).padLeft(8, '0')}'),
              value: plan.members.contains(c.num),
              onChanged: (on) => _update(plan.copyWith(members: on == true
                  ? [...plan.members, c.num]
                  : plan.members.where((m) => m != c.num).toList())),
            ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: overdueChoices.contains(plan.overdueMinutes) ? plan.overdueMinutes : 60,
            decoration: InputDecoration(
              labelText: l.trOverdue,
              helperText: l.trOverdueHelp,
              helperMaxLines: 2,
            ),
            items: [for (final m in overdueChoices)
              DropdownMenuItem(value: m, child: Text(m == 0 ? l.trOff : _minutes(l, m)))],
            onChanged: (m) => _update(plan.copyWith(overdueMinutes: m)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: reminderChoices.contains(plan.reminderMinutes) ? plan.reminderMinutes : 0,
            decoration: InputDecoration(
              labelText: l.trReminder,
              helperText: l.trReminderHelp,
              helperMaxLines: 2,
            ),
            items: [for (final m in reminderChoices)
              DropdownMenuItem(value: m, child: Text(m == 0 ? l.trOff : l.trEvery(_minutes(l, m))))],
            onChanged: (m) => _update(plan.copyWith(reminderMinutes: m)),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: plan.sosChannel >= 0 && channels.any((c) => c.index == plan.sosChannel)
                ? plan.sosChannel : -1,
            decoration: InputDecoration(
              labelText: l.trSosChannel,
              helperText: l.trSosChannelHelp,
              helperMaxLines: 2,
            ),
            items: [
              DropdownMenuItem(value: -1, child: Text(l.trContactsOnly)),
              for (final c in channels)
                DropdownMenuItem(value: c.index,
                  child: Text(l.trChannelItem(c.index, c.name.isEmpty ? l.trDefault : c.name))),
            ],
            onChanged: (i) => _update(plan.copyWith(sosChannel: i)),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const ValueKey('open-readiness'),
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(l.trReadiness),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => TripReadinessPage(radio: widget.radio))),
          ),
          const SizedBox(height: 8),
          if (plan.active)
            OutlinedButton.icon(
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(l.trEnd),
              onPressed: _trip.stopTrip,
            )
          else
            FilledButton.icon(
              icon: const Icon(Icons.hiking),
              label: Text(l.trStart),
              onPressed: plan.members.isEmpty ? null : _trip.startTrip,
            ),
          const SizedBox(height: 8),
          Text(plan.active
              ? l.trRunning(_time(plan.startedAt!))
              : l.trNotRunning),
          if (_status != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_status!)),
        ]);
      },
    )),
  );
}

String _minutes(AppLocalizations l, int m) => m < 60 ? l.trMinutes(m) : l.trHours(m ~/ 60);

String _time(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
