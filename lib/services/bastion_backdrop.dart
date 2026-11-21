import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What sits behind the main tabs' glass cards.
enum BackdropKind {
  /// The theme's own glow.
  theme,

  /// One flat colour.
  solid,

  /// Two colours, top-left to bottom-right.
  linear,

  /// Soft blobs of both colours over the darker one.
  mesh,

  /// The person's own photo.
  photo,
}

/// The chosen background. Colours are ARGB.
@immutable
class BackdropStyle {
  const BackdropStyle({
    this.kind = BackdropKind.theme,
    this.color1 = 0xFF1E3A5F,
    this.color2 = 0xFFB4532A,
    this.dim = defaultDim,
    this.blur = defaultBlur,
  });

  /// How much of the theme's page colour is laid over a custom background
  /// (0 to 1). Never below [minDim], so text on the cards stays readable.
  static const double defaultDim = 0.45;
  static const double minDim = 0.2;
  static const double maxDim = 0.9;

  /// Blur radius for photos, in logical pixels.
  static const double defaultBlur = 8;
  static const double maxBlur = 30;

  final BackdropKind kind;
  final int color1;
  final int color2;
  final double dim;
  final double blur;

  bool get isCustom => kind != BackdropKind.theme;

  BackdropStyle copyWith({BackdropKind? kind, int? color1, int? color2, double? dim, double? blur}) =>
      BackdropStyle(
        kind: kind ?? this.kind,
        color1: color1 ?? this.color1,
        color2: color2 ?? this.color2,
        dim: (dim ?? this.dim).clamp(minDim, maxDim).toDouble(),
        blur: (blur ?? this.blur).clamp(0, maxBlur).toDouble(),
      );

  Map<String, Object> toJson() => {'kind': kind.name, 'c1': color1, 'c2': color2, 'dim': dim, 'blur': blur};

  /// Reads a saved style; anything unreadable falls back to the defaults.
  static BackdropStyle fromJson(Object? json) {
    if (json is! Map) return const BackdropStyle();
    final kind = BackdropKind.values.where((k) => k.name == json['kind']).firstOrNull;
    double number(Object? v, double fallback) => v is num ? v.toDouble() : fallback;
    return const BackdropStyle().copyWith(
      kind: kind ?? BackdropKind.theme,
      color1: json['c1'] is int ? json['c1'] as int : null,
      color2: json['c2'] is int ? json['c2'] as int : null,
      dim: number(json['dim'], defaultDim),
      blur: number(json['blur'], defaultBlur),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BackdropStyle &&
      other.kind == kind &&
      other.color1 == color1 &&
      other.color2 == color2 &&
      other.dim == dim &&
      other.blur == blur;

  @override
  int get hashCode => Object.hash(kind, color1, color2, dim, blur);
}

/// Colours offered for a colour, gradient or mesh background.
abstract final class BackdropColours {
  static const List<int> all = [
    0xFF0B1F3A, // night blue
    0xFF1E3A5F, // slate blue
    0xFF0F766E, // deep teal
    0xFF14532D, // forest
    0xFF4D7C0F, // moss
    0xFFB4532A, // ember
    0xFFC2410C, // orange
    0xFF9F1239, // crimson
    0xFF6D28D9, // violet
    0xFFDB2777, // pink
    0xFF374151, // graphite
    0xFFE7E5E4, // stone
  ];
}

/// Keeps the chosen background. The style is a preference; the photo is a
/// file in the app's own folder and is not part of backups.
class BastionBackdrop extends ChangeNotifier {
  BastionBackdrop({SharedPreferencesAsync? prefs, Directory? folder})
      : _prefs = prefs,
        _folderOverride = folder;

  /// The one the app uses.
  static BastionBackdrop instance = BastionBackdrop();

  static const prefsKey = 'bastion.backdrop_v1';
  static const photoFileName = 'backdrop_photo.png';

  /// Photos are scaled to fit inside this, so a big camera picture doesn't
  /// sit in memory at full size.
  static const photoMaxSide = 1600;

  /// Larger picked files are refused before they are read.
  static const photoMaxBytes = 25 * 1024 * 1024;

  final SharedPreferencesAsync? _prefs;
  final Directory? _folderOverride;
  BackdropStyle _style = const BackdropStyle();
  Uint8List? _photo;

  BackdropStyle get style => _style;

  /// The photo's bytes; null when there is none.
  Uint8List? get photo => _photo;

  SharedPreferencesAsync get _store => _prefs ?? SharedPreferencesAsync();

  Future<Directory?> _folder() async {
    if (_folderOverride != null) return _folderOverride;
    if (kIsWeb) return null;
    return getApplicationSupportDirectory();
  }

  /// Reads the saved style and photo. Failures leave the theme's glow.
  Future<void> load() async {
    try {
      final raw = await _store.getString(prefsKey);
      _style = raw == null ? const BackdropStyle() : BackdropStyle.fromJson(jsonDecode(raw));
    } catch (e) {
      debugPrint('Background setting unreadable, using the theme: $e');
      _style = const BackdropStyle();
    }
    if (_style.kind == BackdropKind.photo) {
      try {
        final dir = await _folder();
        final file = dir == null ? null : File('${dir.path}/$photoFileName');
        if (file != null && await file.exists()) _photo = await file.readAsBytes();
      } on Exception catch (e) {
        debugPrint('Background photo unreadable: $e');
      }
      // A photo setting with no photo left shows the theme instead.
      if (_photo == null) _style = _style.copyWith(kind: BackdropKind.theme);
    }
    notifyListeners();
  }

  /// Saves [next] and redraws every backdrop.
  Future<void> setStyle(BackdropStyle next) async {
    _style = next;
    notifyListeners();
    try {
      await _store.setString(prefsKey, jsonEncode(next.toJson()));
    } catch (e) {
      debugPrint('Could not save background setting: $e');
    }
  }

  /// Scales [bytes] down to fit [photoMaxSide], saves it as the photo and
  /// switches to it. Returns false when it isn't a picture this phone can
  /// read, or it can't be saved.
  Future<bool> setPhoto(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > photoMaxBytes) return false;
    final Uint8List png;
    try {
      png = await shrinkImage(bytes, maxSide: photoMaxSide);
    } catch (e) {
      debugPrint('Background photo unreadable: $e');
      return false;
    }
    final dir = await _folder();
    if (dir == null) return false;
    try {
      await dir.create(recursive: true);
      final file = File('${dir.path}/$photoFileName');
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(png, flush: true);
      await tmp.rename(file.path);
    } on FileSystemException catch (e) {
      debugPrint('Could not save background photo: $e');
      return false;
    }
    _photo = png;
    await setStyle(_style.copyWith(kind: BackdropKind.photo));
    return true;
  }

  /// Decodes [bytes] as a picture, scales it to fit inside [maxSide] and
  /// returns it as PNG. Throws when it isn't a picture this phone can read.
  static Future<Uint8List> shrinkImage(Uint8List bytes, {required int maxSide}) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final w = descriptor.width, h = descriptor.height;
    final scale = w > h ? maxSide / w : maxSide / h;
    final codec = await descriptor.instantiateCodec(
      targetWidth: scale < 1 ? (w * scale).round() : w,
      targetHeight: scale < 1 ? (h * scale).round() : h,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    if (data == null) throw const FormatException('not an image');
    return data.buffer.asUint8List();
  }

  /// Back to the theme's own background, deleting any photo.
  Future<void> reset() async {
    _photo = null;
    try {
      final dir = await _folder();
      final file = dir == null ? null : File('${dir.path}/$photoFileName');
      if (file != null && await file.exists()) await file.delete();
    } on FileSystemException catch (e) {
      debugPrint('Could not delete background photo: $e');
    }
    await setStyle(const BackdropStyle());
  }
}
