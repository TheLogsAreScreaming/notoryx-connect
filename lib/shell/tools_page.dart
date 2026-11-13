part of '../main.dart';

class _ToolsPage extends StatefulWidget {
  const _ToolsPage({required this.discovery, required this.radio});
  final MeshtasticBleDiscovery discovery;
  final MeshtasticRadioCoordinator radio;
  @override
  State<_ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<_ToolsPage> {
  final battery = TextEditingController(text: '3000');
  final draw = TextEditingController(text: '100');
  double? runtime;
  final checked = <int>{};

  @override
  void dispose() { battery.dispose(); draw.dispose(); super.dispose(); }

  void calculate() {
    final mah = double.tryParse(battery.text);
    final ma = double.tryParse(draw.text);
    setState(() => runtime = mah != null && ma != null && ma > 0 ? mah / ma : null);
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.radio, widget.discovery]),
    builder: (context, _) {
      final l = AppLocalizations.of(context);
      final checklist = [l.toolsCheck0, l.toolsCheck1, l.toolsCheck2, l.toolsCheck3, l.toolsCheck4];
      final radio = widget.radio;
      final readings = radio.deviceTelemetry.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return ListView(
    padding: NxSpace.page,
    children: [
      NxPageHeader(title: l.toolsTitle,
        subtitle: l.toolsSubtitle),
      Card(child: ListTile(
        leading: const Icon(Icons.medical_services_outlined),
        title: Text(l.toolsDoctor),
        subtitle: Text(l.toolsDoctorSub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(ConnectionDoctorPage(radio: radio, discovery: widget.discovery)),
      )),
      NxSectionLabel(l.toolsBeforeYouGo),
      Card(child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.checklist),
        title: Text(l.toolsChecklist),
        subtitle: Text(l.toolsReady(checked.length, checklist.length)),
        children: [
          for (final (i, item) in checklist.indexed)
            CheckboxListTile(
              title: Text(item), value: checked.contains(i),
              onChanged: (value) => setState(() {
                value == true ? checked.add(i) : checked.remove(i);
              }),
            ),
        ],
      )),
      Card(child: ExpansionTile(
        leading: const Icon(Icons.battery_charging_full),
        title: Text(l.toolsBattery),
        subtitle: Text(l.toolsBatterySub),
        childrenPadding: const EdgeInsets.fromLTRB(NxSpace.md, 0, NxSpace.md, NxSpace.md),
        children: [
          Row(children: [
            Expanded(child: TextField(controller: battery,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.toolsBatteryField))),
            const SizedBox(width: NxSpace.sm),
            Expanded(child: TextField(controller: draw,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l.toolsDrawField))),
          ]),
          const SizedBox(height: NxSpace.sm),
          SizedBox(width: double.infinity,
            child: FilledButton(onPressed: calculate, child: Text(l.toolsCalculate))),
          if (runtime != null)
            Padding(padding: const EdgeInsets.only(top: NxSpace.sm),
              child: Semantics(liveRegion: true, child: Text(l.toolsAboutHours(runtime!.toStringAsFixed(1)),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary)))),
        ],
      )),
      NxSectionLabel(l.toolsMeshTools),
      NxGroupCard(children: [
        ListTile(
          leading: const Icon(Icons.monitor_heart_outlined),
          title: Text(l.toolsHealth),
          subtitle: Text(l.toolsHealthSub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(MeshHealthPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.terrain),
          title: Text(l.toolsLink),
          subtitle: Text(l.toolsLinkSub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(LinkPlannerPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.network_check),
          title: Text(l.toolsRange),
          subtitle: Text(l.toolsRangeSub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(MeshToolsPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          enabled: radio.isReady,
          leading: const Icon(Icons.route),
          title: Text(l.toolsTraceroute),
          subtitle: Text(radio.isReady
            ? l.toolsTraceReady
            : l.toolsTraceOff),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(TraceroutePage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: Text(l.toolsStore),
          subtitle: Text(l.toolsStoreSub),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(MeshToolsPage(radio: radio, initialTab: 1)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.campaign_outlined),
          title: Text(l.toolsBeacons),
          subtitle: Text(radio.beacons.isEmpty
              ? l.toolsBeaconsSub
              : l.toolsBeaconsHeard(radio.beacons.length)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(BeaconPage(radio: radio)),
        ),
      ]),
      NxSectionLabel(l.toolsRecords),
      Card(child: ListTile(
        key: const ValueKey('tools-node-journal'),
        leading: const Icon(Icons.menu_book_outlined),
        title: Text(l.njTitle),
        subtitle: Text(l.njToolSub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(NodeJournalPage(journal: radio.nodeJournal)),
      )),
      Card(child: ListTile(
        leading: const Icon(Icons.assignment_outlined),
        title: Text(l.toolsIncident),
        subtitle: Text(l.toolsIncidentSub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(FieldToolsPage(radio: radio)),
      )),
      Card(child: ListTile(
        key: const ValueKey('tools-sentinel'),
        leading: const Icon(Icons.shield_outlined),
        title: Text(l.sntTitle),
        subtitle: Text(l.sntToolSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(SentinelPage(localNodeNum: radio.localNodeNum)),
      )),
      if (!kIsWeb && Platform.isAndroid) // ATAK is an Android app.
        Card(child: ListTile(
        leading: const Icon(Icons.share_location),
        title: Text(l.takTitle),
        subtitle: Text(l.toolsTakSub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(TakBridgePage(bridge: BastionTakBridge.instance)),
      )),
      if (BastionSmsRelay.available)
        Card(child: ListTile(
          leading: const Icon(Icons.sms_outlined),
          title: const Text('SMS relay'),
          subtitle: const Text('Let chosen nodes text through this phone'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(SmsRelayPage(radio: radio, relay: BastionSmsRelay.instance)),
        )),
      NxSectionLabel(l.toolsSignal),
      Card(child: ExpansionTile(
        leading: const Icon(Icons.monitor_heart_outlined),
        title: Text(l.toolsTelemetry),
        subtitle: Text(radio.isReady
          ? l.toolsReporting(readings.length)
          : l.toolsTelemetryOff),
        childrenPadding: const EdgeInsets.fromLTRB(NxSpace.md, 0, NxSpace.md, NxSpace.md),
        children: [
          if (readings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: NxSpace.sm),
              child: Text(l.toolsNothingYet),
            ),
          for (final entry in readings)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(radio.nodeName(entry.key)),
              subtitle: Text([
                if (entry.value.batteryLevel != null)
                  l.toolsBatteryPct(entry.value.batteryLevel!),
                if (entry.value.voltage != null)
                  '${entry.value.voltage!.toStringAsFixed(2)} V',
                if (entry.value.channelUtilization != null)
                  l.toolsChannelBusy(entry.value.channelUtilization!.toStringAsFixed(1)),
                if (entry.value.airUtilTx != null)
                  l.toolsTransmitting(entry.value.airUtilTx!.toStringAsFixed(1)),
              ].join(' • ')),
            ),
        ],
      )),
      Card(child: ExpansionTile(
        leading: const Icon(Icons.signal_cellular_alt),
        title: Text(l.toolsGuide),
        subtitle: Text(l.toolsGuideSub),
        childrenPadding: const EdgeInsets.fromLTRB(NxSpace.md, 0, NxSpace.md, NxSpace.md),
        children: [
          _ReferenceRow(value: '−50 dBm', label: l.toolsSigExcellent),
          _ReferenceRow(value: '−60 dBm', label: l.toolsSigStrong),
          _ReferenceRow(value: '−70 dBm', label: l.toolsSigUsable),
          _ReferenceRow(value: '−80 dBm', label: l.toolsSigWeak),
          _ReferenceRow(value: '≤ −90', label: l.toolsSigVeryWeak),
        ],
      )),
      Card(child: ListTile(
        leading: const Icon(Icons.bluetooth_searching),
        title: Text(l.toolsScan),
        subtitle: Text(widget.discovery.scanning
            ? l.toolsScanning
            : l.toolsFound(widget.discovery.results.length)),
        trailing: const Icon(Icons.chevron_right),
        onTap: widget.discovery.scanning ? null : widget.discovery.scan,
      )),
    ],
  );
    },
  );
}
