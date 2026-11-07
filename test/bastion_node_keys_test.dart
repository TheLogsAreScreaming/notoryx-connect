import 'dart:typed_data';

import 'package:bastion/generated/meshtastic/mesh.pb.dart' as pb;
import 'package:bastion/services/bastion_node_keys.dart';
import 'package:bastion/services/meshtastic_node_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Uint8List _key(int seed) => Uint8List.fromList(List.generate(32, (i) => (i * 7 + seed) & 0xff));

void main() {
  setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  test('a key is remembered, a different one is flagged, and trust clears it', () async {
    final keys = BastionNodeKeys();
    await keys.load();
    expect(await keys.check(5, _key(1)), KeyCheck.firstSeen);
    expect(await keys.check(5, _key(1)), KeyCheck.same);
    expect(await keys.check(5, _key(2)), KeyCheck.changed);
    expect(keys.hasChanged(5), isTrue);

    // The warning survives a restart.
    final reloaded = BastionNodeKeys();
    await reloaded.load();
    expect(reloaded.hasChanged(5), isTrue);

    await reloaded.trust(5);
    expect(reloaded.hasChanged(5), isFalse);
    expect(await reloaded.check(5, _key(2)), KeyCheck.same);
  });

  test('going back to the remembered key clears the warning', () async {
    final keys = BastionNodeKeys();
    await keys.load();
    await keys.check(9, _key(1));
    await keys.check(9, _key(2));
    expect(await keys.check(9, _key(1)), KeyCheck.same);
    expect(keys.changedNodes, isEmpty);
  });

  test('unreadable storage is never overwritten', () async {
    SharedPreferencesAsyncPlatform.instance = _Unreadable();
    final keys = BastionNodeKeys();
    await keys.load();
    await keys.check(1, _key(1));
    expect((SharedPreferencesAsyncPlatform.instance! as _Unreadable).wrote, isFalse);
  });

  test('safety codes are four groups of hex', () {
    final code = BastionNodeKeys.safetyCode('AQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHyA=');
    expect(code, '0102 0304 0506 0708');
  });

  test('node info carries a 32-byte public key and ignores others', () {
    final node = MeshtasticNodeInfoCodec.applyUser(const MeshtasticNode(num: 1),
        pb.User(id: '!00000001', longName: 'A', publicKey: _key(3)));
    expect(node.publicKey, _key(3));
    final none = MeshtasticNodeInfoCodec.applyUser(const MeshtasticNode(num: 1),
        pb.User(id: '!00000001', publicKey: [1, 2, 3]));
    expect(none.publicKey, isNull);
  });

  test('saved keys use the documented storage key', () async {
    final keys = BastionNodeKeys();
    await keys.load();
    await keys.check(1, _key(1));
    expect(await SharedPreferencesAsync().getString(BastionNodeKeys.key), isNotNull);
  });
}

final class _Unreadable extends InMemorySharedPreferencesAsync {
  _Unreadable() : super.empty();
  bool wrote = false;
  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) async {
    if (key == BastionNodeKeys.key) throw StateError('read failed');
    return super.getString(key, options);
  }

  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) async {
    if (key == BastionNodeKeys.key) wrote = true;
    return super.setString(key, value, options);
  }
}
