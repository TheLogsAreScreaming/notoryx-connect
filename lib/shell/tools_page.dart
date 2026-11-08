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
  final checked = <String>{};
  static const checklist = [
    'Radio charged', 'Antenna attached', 'Region configured',
    'Primary channel verified', 'GPS / position policy checked',
  ];

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
      final radio = widget.radio;
      final readings = radio.deviceTelemetry.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      return ListView(
    padding: NxSpace.page,
    children: [
      const NxPageHeader(title: 'Tools',
        subtitle: 'Utilities for planning, testing and running a deployment.'),
      Card(child: ListTile(
        leading: const Icon(Icons.medical_services_outlined),
        title: const Text('Connection doctor'),
        subtitle: const Text('Find out why a radio won\'t connect or keeps dropping'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(ConnectionDoctorPage(radio: radio, discovery: widget.discovery)),
      )),
      const NxSectionLabel('Before you go'),
      Card(child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.checklist),
        title: const Text('Deployment checklist'),
        subtitle: Text('${checked.length} of ${checklist.length} ready'),
        children: [
          for (final item in checklist)
            CheckboxListTile(
              title: Text(item), value: checked.contains(item),
              onChanged: (value) => setState(() {
                value == true ? checked.add(item) : checked.remove(item);
              }),
            ),
        ],
      )),
      Card(child: ExpansionTile(
        leading: const Icon(Icons.battery_charging_full),
        title: const Text('Battery runtime'),
        subtitle: const Text('Estimate hours from capacity and average draw'),
        childrenPadding: const EdgeInsets.fromLTRB(NxSpace.md, 0, NxSpace.md, NxSpace.md),
        children: [
          Row(children: [
            Expanded(child: TextField(controller: battery,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Battery (mAh)'))),
            const SizedBox(width: NxSpace.sm),
            Expanded(child: TextField(controller: draw,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Average draw (mA)'))),
          ]),
          const SizedBox(height: NxSpace.sm),
          SizedBox(width: double.infinity,
            child: FilledButton(onPressed: calculate, child: const Text('Calculate'))),
          if (runtime != null)
            Padding(padding: const EdgeInsets.only(top: NxSpace.sm),
              child: Semantics(liveRegion: true, child: Text('About ${runtime!.toStringAsFixed(1)} hours',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary)))),
        ],
      )),
      const NxSectionLabel('Mesh tools'),
      NxGroupCard(children: [
        ListTile(
          leading: const Icon(Icons.monitor_heart_outlined),
          title: const Text('Mesh health & airtime'),
          subtitle: const Text('How busy the channel is and how much your radio transmits'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(MeshHealthPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.terrain),
          title: const Text('Link planner'),
          subtitle: const Text('Check line of sight between two nodes over the terrain'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(LinkPlannerPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.network_check),
          title: const Text('Range test'),
          subtitle: const Text('Log packets from a range test sender with signal and distance'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(MeshToolsPage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          enabled: radio.isReady,
          leading: const Icon(Icons.route),
          title: const Text('Traceroute'),
          subtitle: Text(radio.isReady
            ? 'Show the relay path to a node and back'
            : 'Connect to a radio to trace routes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(TraceroutePage(radio: radio)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: const Text('Store & forward'),
          subtitle: const Text('Replay messages you missed from a router'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(MeshToolsPage(radio: radio, initialTab: 1)),
        ),
        const Divider(indent: 56),
        ListTile(
          leading: const Icon(Icons.campaign_outlined),
          title: const Text('Mesh beacons'),
          subtitle: Text(radio.beacons.isEmpty
              ? 'Hear mesh invitations nearby and send your own'
              : '${radio.beacons.length} heard • send your own'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _open(BeaconPage(radio: radio)),
        ),
      ]),
      const NxSectionLabel('Records'),
      Card(child: ListTile(
        leading: const Icon(Icons.assignment_outlined),
        title: const Text('Incident log, templates & coverage'),
        subtitle: const Text('Saved field records and exports'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _open(FieldToolsPage(radio: radio)),
      )),
      const NxSectionLabel('Signal'),
      Card(child: ExpansionTile(
        leading: const Icon(Icons.monitor_heart_outlined),
        title: const Text('Live telemetry'),
        subtitle: Text(radio.isReady
          ? '${readings.length} node${readings.length == 1 ? '' : 's'} reporting device metrics'
          : 'Connect to a radio to receive telemetry'),
        childrenPadding: const EdgeInsets.fromLTRB(NxSpace.md, 0, NxSpace.md, NxSpace.md),
        children: [
          if (readings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: NxSpace.sm),
              child: Text('Nothing received yet. Metrics appear when nodes send them.'),
            ),
          for (final entry in readings)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(radio.nodeName(entry.key)),
              subtitle: Text([
                if (entry.value.batteryLevel != null)
                  'Battery ${entry.value.batteryLevel}%',
                if (entry.value.voltage != null)
                  '${entry.value.voltage!.toStringAsFixed(2)} V',
                if (entry.value.channelUtilization != null)
                  'Channel busy ${entry.value.channelUtilization!.toStringAsFixed(1)}%',
                if (entry.value.airUtilTx != null)
                  'Transmitting ${entry.value.airUtilTx!.toStringAsFixed(1)}%',
              ].join(' • ')),
            ),
        ],
      )),
      Card(child: ExpansionTile(
        leading: const Icon(Icons.signal_cellular_alt),
        title: const Text('Bluetooth signal guide'),
        subtitle: const Text('What the signal numbers (RSSI) mean'),
        childrenPadding: const EdgeInsets.fromLTRB(NxSpace.md, 0, NxSpace.md, NxSpace.md),
        children: const [
          _ReferenceRow(value: '−50 dBm', label: 'Excellent, very close'),
          _ReferenceRow(value: '−60 dBm', label: 'Strong'),
          _ReferenceRow(value: '−70 dBm', label: 'Usable'),
          _ReferenceRow(value: '−80 dBm', label: 'Weak'),
          _ReferenceRow(value: '≤ −90', label: 'Very weak, may drop'),
        ],
      )),
      Card(child: ListTile(
        leading: const Icon(Icons.bluetooth_searching),
        title: const Text('Scan for radios'),
        subtitle: Text(widget.discovery.scanning
            ? 'Scanning…'
            : '${widget.discovery.results.length} Bluetooth device${widget.discovery.results.length == 1 ? '' : 's'} found'),
        trailing: const Icon(Icons.chevron_right),
        onTap: widget.discovery.scanning ? null : widget.discovery.scan,
      )),
    ],
  );
    },
  );
}
