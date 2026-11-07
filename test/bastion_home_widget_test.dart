import 'package:bastion/services/bastion_chat_message.dart';
import 'package:bastion/services/bastion_home_widget.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:bastion/services/meshtastic_radio_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _Radio extends MeshtasticRadioCoordinator {
  bool ready = true;
  int unread = 2;
  @override
  bool get isReady => ready;
  @override
  int? get localNodeNum => 1;
  @override
  MeshtasticNode? get localNode => const MeshtasticNode(num: 1, longName: 'Base', batteryLevel: 81);
  @override
  List<MeshtasticNode> get nodes => const [
        MeshtasticNode(num: 1, longName: 'Base'),
        MeshtasticNode(num: 2, longName: 'Mara'),
      ];
  @override
  int get unreadCount => unread;
  @override
  List<BastionChatMessage> get messages => [
        BastionChatMessage(packetId: 1, from: 2, to: 0xffffffff, channel: 0, text: 'At the saddle',
            timestamp: DateTime(2026), direction: BastionMessageDirection.incoming,
            deliveryState: BastionDeliveryState.received),
      ];
  @override
  String nodeName(int num) => nodes.firstWhere((n) => n.num == num).displayName;
  void poke() => notifyListeners();
}

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());
  final now = DateTime(2026, 11, 7, 14, 5);

  test('the widget shows status and counts, and message text only when allowed', () {
    final radio = _Radio();
    addTearDown(radio.dispose);
    final hidden = WidgetSnapshot.of(radio, now, showMessage: false);
    expect(hidden.title, 'Connected • Base');
    expect(hidden.detail, '2 nodes • battery 81%');
    expect(hidden.messages, '2 unread');
    expect(hidden.alert, isEmpty);
    expect(hidden.updated, 'Updated 14:05');
    expect(WidgetSnapshot.of(radio, now, showMessage: true).messages, '2 unread • Mara: At the saddle');

    radio.ready = false;
    radio.unread = 0;
    final offline = WidgetSnapshot.of(radio, now, showMessage: true);
    expect(offline.title, 'No radio connected');
    expect(offline.messages, 'No unread messages');
    expect(offline.toMap().keys, containsAll(['widget_title', 'widget_detail', 'widget_messages', 'widget_alert', 'widget_updated']));
  });

  testWidgets('updates are sent on change, skipped when nothing changed, and spaced out', (tester) async {
    final radio = _Radio();
    addTearDown(radio.dispose);
    var clock = now;
    final pushes = <Map<String, String>>[];
    final w = BastionHomeWidget(radio, push: (v) async => pushes.add(v), clock: () => clock);
    addTearDown(w.dispose);
    await w.start();
    expect(pushes, hasLength(1));

    radio.poke();
    expect(pushes, hasLength(1), reason: 'nothing changed');

    radio.unread = 3;
    clock = now.add(const Duration(seconds: 5));
    radio.poke();
    expect(pushes, hasLength(1), reason: 'too soon; waits');
    clock = now.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 26));
    expect(pushes, hasLength(2));
    expect(pushes.last['widget_messages'], '3 unread');

    await w.setShowMessage(true);
    clock = now.add(const Duration(minutes: 2));
    radio.poke();
    await tester.pump(const Duration(seconds: 31));
    expect(pushes.last['widget_messages'], contains('At the saddle'));
  });
}
