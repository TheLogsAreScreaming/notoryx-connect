import 'package:bastion/services/bastion_local_names.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    BastionLocalNames.instance.debugReset();
    await BastionLocalNames.instance.load();
  });

  test('a local name replaces the shown name, not the node\'s own', () async {
    const node = MeshtasticNode(num: 0x1234, longName: 'Hilltop Relay');
    expect(node.displayName, 'Hilltop Relay');
    await BastionLocalNames.instance.set(0x1234, '  Base camp  ');
    expect(node.displayName, 'Base camp');
    expect(node.radioName, 'Hilltop Relay');
    await BastionLocalNames.instance.set(0x1234, '');
    expect(node.displayName, 'Hilltop Relay');
  });

  test('names survive a reload, are one line and capped', () async {
    await BastionLocalNames.instance.set(7, 'Line\none');
    await BastionLocalNames.instance.set(8, 'x' * 60);
    BastionLocalNames.instance.debugReset();
    await BastionLocalNames.instance.load();
    expect(BastionLocalNames.instance.nameFor(7), 'Line one');
    expect(
      BastionLocalNames.instance.nameFor(8)!.length,
      BastionLocalNames.maxLength,
    );
    final raw = await SharedPreferencesAsync().getString(
      BastionLocalNames.prefsKey,
    );
    expect(raw, isNotNull);
    expect(BastionLocalNames.prefsKey, startsWith('bastion.'));
  });
}
