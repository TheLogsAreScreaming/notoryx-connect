import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bastion_backdrop.dart';

/// The color or photo someone picked for one node. Only on this phone; it
/// is never sent over the mesh.
@immutable
class NodeLook {
  const NodeLook({this.color, this.photo});

  /// ARGB color, or null for the app's own.
  final int? color;

  /// A small PNG, or null for no photo.
  final Uint8List? photo;

  bool get isEmpty => color == null && (photo == null || photo!.isEmpty);

  Map<String, Object> toJson() => {
        'c': ?color,
        if (photo case final p? when p.isNotEmpty) 'p': base64Encode(p),
      };

  static NodeLook? fromJson(Object? json) {
    if (json is! Map) return null;
    Uint8List? photo;
    if (json['p'] case final String p when p.isNotEmpty) {
      try {
        photo = base64Decode(p);
      } on FormatException {
        photo = null;
      }
    }
    final look = NodeLook(color: json['c'] is int ? json['c'] as int : null, photo: photo);
    return look.isEmpty ? null : look;
  }
}

/// Colors offered for a node: distinct hues plus neutrals.
abstract final class NodeLookColors {
  static const List<int> all = [
    0xFFE53935, // red
    0xFFFB8C00, // orange
    0xFFFDD835, // yellow
    0xFF7CB342, // green
    0xFF00897B, // teal
    0xFF29B6F6, // sky
    0xFF1E88E5, // blue
    0xFF5E35B1, // violet
    0xFFD81B60, // pink
    0xFF8D6E63, // brown
    0xFF90A4AE, // grey
    0xFFF5F5F5, // white
  ];
}

/// Every node's chosen color or photo, by node number. Kept in the app's
/// preferences on this phone.
class BastionNodeLooks extends ChangeNotifier {
  BastionNodeLooks({SharedPreferencesAsync? prefs}) : _prefs = prefs;

  /// The one the app uses.
  static BastionNodeLooks instance = BastionNodeLooks();

  static const prefsKey = 'bastion.node_looks_v1';

  /// Photos are kept this small (pixels on the long side).
  static const photoSide = 192;

  /// At most this many bytes per photo, so preferences stay small.
  static const maxPhotoBytes = 128 * 1024;

  final SharedPreferencesAsync? _prefs;
  final Map<int, NodeLook> _looks = {};

  SharedPreferencesAsync get _store => _prefs ?? SharedPreferencesAsync();

  /// The look for node [num], or null if none was picked.
  NodeLook? lookFor(int num) => _looks[num];

  Future<void> load() async {
    _looks.clear();
    try {
      final raw = await _store.getString(prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          for (final e in decoded.entries) {
            final num = int.tryParse(e.key.toString());
            final look = NodeLook.fromJson(e.value);
            if (num != null && look != null) _looks[num] = look;
          }
        }
      }
    } catch (e) {
      debugPrint('Node looks unreadable, starting fresh: $e');
    }
    notifyListeners();
  }

  /// Sets the color for [num]; null clears it.
  Future<void> setColor(int num, int? color) =>
      _update(num, (old) => NodeLook(color: color, photo: old?.photo));

  /// Shrinks [bytes] and sets it as the photo for [num]. Returns false when
  /// it isn't a picture this phone can read.
  Future<bool> setPhoto(int num, Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > BastionBackdrop.photoMaxBytes) return false;
    Uint8List small;
    try {
      small = await BastionBackdrop.shrinkImage(bytes, maxSide: photoSide);
      if (small.length > maxPhotoBytes) small = await BastionBackdrop.shrinkImage(bytes, maxSide: photoSide ~/ 2);
    } catch (e) {
      debugPrint('Node photo unreadable: $e');
      return false;
    }
    if (small.length > maxPhotoBytes) return false;
    await _update(num, (old) => NodeLook(color: old?.color, photo: small));
    return true;
  }

  /// Removes the photo for [num], keeping any color.
  Future<void> removePhoto(int num) => _update(num, (old) => NodeLook(color: old?.color));

  /// Removes both color and photo for [num].
  Future<void> clear(int num) => _update(num, (_) => null);

  Future<void> _update(int num, NodeLook? Function(NodeLook? old) change) async {
    final next = change(_looks[num]);
    if (next == null || next.isEmpty) {
      _looks.remove(num);
    } else {
      _looks[num] = next;
    }
    notifyListeners();
    try {
      await _store.setString(prefsKey, jsonEncode({for (final e in _looks.entries) '${e.key}': e.value.toJson()}));
    } catch (e) {
      debugPrint('Could not save node looks: $e');
    }
  }
}
