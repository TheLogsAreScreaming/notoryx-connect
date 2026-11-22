import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/bastion_backdrop.dart';
import 'nx_themes.dart';

/// The theme colours the backdrop glows with, carried on the app theme so
/// the backdrop always matches the chosen palette.
@immutable
class NxGlow extends ThemeExtension<NxGlow> {
  const NxGlow({
    required this.ground,
    required this.glow,
    required this.secondary,
    required this.tertiary,
    required this.contour,
    this.sparkle,
  });

  factory NxGlow.fromPalette(BastionPalette p) => NxGlow(
        ground: p.bg,
        glow: p.accent,
        secondary: p.secondary,
        tertiary: p.tertiary,
        contour: p.ink,
      );

  final Color ground, glow, secondary, tertiary, contour;
  final List<Color>? sparkle;

  static NxGlow of(BuildContext context) =>
      Theme.of(context).extension<NxGlow>() ?? NxGlow.fromPalette(BastionTheme.fallback.palette);

  @override
  NxGlow copyWith() => this;

  @override
  NxGlow lerp(NxGlow? other, double t) => t < 0.5 || other == null ? this : other;
}

/// Which main tab the backdrop sits behind; each places its glows a little
/// differently so moving between tabs doesn't look like a repeat.
enum NxScene { home, chats, nodes, map, more }

/// The glowing ground behind the main tabs: the theme's page colour, a glow
/// from its accent, a softer second glow and faint contour lines, or the
/// background chosen in Settings. Cards in front show it through their
/// see-through fill.
class NxBackdrop extends StatelessWidget {
  const NxBackdrop({super.key, required this.child, this.scene = NxScene.home, BastionBackdrop? store})
      : _store = store;

  final Widget child;
  final NxScene scene;
  final BastionBackdrop? _store;

  @override
  Widget build(BuildContext context) {
    final store = _store ?? BastionBackdrop.instance;
    return Stack(
      fit: StackFit.expand,
      children: [
        ListenableBuilder(
          listenable: store,
          builder: (context, _) => NxBackdropLayer(
            style: store.style,
            photo: store.photo,
            scene: scene,
          ),
        ),
        child,
      ],
    );
  }
}

/// Just the painted background, with no content on top.
class NxBackdropLayer extends StatelessWidget {
  const NxBackdropLayer({super.key, required this.style, this.photo, this.scene = NxScene.home});

  final BackdropStyle style;
  final Uint8List? photo;
  final NxScene scene;

  @override
  Widget build(BuildContext context) {
    final g = NxGlow.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (style.isCustom) {
      return _CustomBackdrop(style: style, photo: photo, ground: g.ground, reduceEffects: reduce);
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    final second = switch (scene) {
      NxScene.home || NxScene.chats || NxScene.map => g.secondary,
      NxScene.nodes || NxScene.more => g.tertiary,
    };
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: NxGlowPainter(
            scene: scene,
            ground: g.ground,
            glow: g.glow,
            second: second,
            contour: g.contour,
            dark: dark,
            sparkle: g.sparkle,
          ),
        ),
      ),
    );
  }
}

class _CustomBackdrop extends StatelessWidget {
  const _CustomBackdrop({required this.style, required this.ground, this.photo, this.reduceEffects = false});

  final BackdropStyle style;
  final Uint8List? photo;
  final Color ground;
  final bool reduceEffects;

  @override
  Widget build(BuildContext context) {
    final c1 = Color(style.color1);
    final c2 = Color(style.color2);
    final Widget base = switch (style.kind) {
      BackdropKind.theme || BackdropKind.solid => ColoredBox(color: c1),
      BackdropKind.linear => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c1, c2]),
          ),
        ),
      BackdropKind.mesh => RepaintBoundary(child: CustomPaint(painter: NxMeshPainter(c1, c2))),
      BackdropKind.photo => _photo(c1),
    };
    // The theme's page colour over the top keeps text on the cards readable.
    return ExcludeSemantics(
      child: Stack(fit: StackFit.expand, children: [base, ColoredBox(color: ground.withValues(alpha: style.dim))]),
    );
  }

  Widget _photo(Color fallback) {
    final bytes = photo;
    if (bytes == null || bytes.isEmpty) return ColoredBox(color: fallback);
    final image = Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => ColoredBox(color: fallback),
    );
    final sigma = reduceEffects ? 0.0 : style.blur;
    if (sigma <= 0) return RepaintBoundary(child: image);
    return RepaintBoundary(
      child: ClipRect(
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.clamp),
          child: image,
        ),
      ),
    );
  }
}

/// Soft overlapping blobs of two colours, like a mesh gradient.
class NxMeshPainter extends CustomPainter {
  NxMeshPainter(this.a, this.b);

  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    final darker = a.computeLuminance() <= b.computeLuminance() ? a : b;
    canvas.drawRect(Offset.zero & size, Paint()..color = darker);
    final mid = Color.lerp(a, b, 0.5)!;
    final s = size.shortestSide;
    final blobs = [
      (Offset(size.width * 0.15, size.height * 0.12), s * 0.95, a),
      (Offset(size.width * 0.95, size.height * 0.35), s * 0.85, b),
      (Offset(size.width * 0.25, size.height * 0.80), s * 0.90, b),
      (Offset(size.width * 0.85, size.height * 0.95), s * 0.80, a),
      (Offset(size.width * 0.55, size.height * 0.55), s * 0.70, mid),
    ];
    for (final (centre, radius, colour) in blobs) {
      if (radius <= 0) continue;
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [colour, colour.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
    }
  }

  @override
  bool shouldRepaint(NxMeshPainter old) => old.a != a || old.b != b;
}

/// Paints the theme glow. Positions are laid out on a 390 x 844 phone and
/// scaled to the real size.
class NxGlowPainter extends CustomPainter {
  NxGlowPainter({
    required this.scene,
    required this.ground,
    required this.glow,
    required this.second,
    required this.contour,
    required this.dark,
    this.sparkle,
  });

  final NxScene scene;
  final Color ground, glow, second, contour;
  final bool dark;

  /// Colours for small fixed glints, or null for none.
  final List<Color>? sparkle;

  static const _w = 390.0;
  static const _h = 844.0;

  List<(double, double, double, double)> get _glows => switch (scene) {
        NxScene.home => [(90, 70, 250, 0.64), (370, 560, 240, 0.48)],
        NxScene.chats => [(360, 60, 260, 0.60), (0, 660, 240, 0.44)],
        NxScene.nodes => [(160, 0, 250, 0.60), (400, 720, 240, 0.42)],
        NxScene.map => [(40, 760, 240, 0.50), (380, 80, 230, 0.40)],
        NxScene.more => [(320, 40, 250, 0.60), (20, 600, 240, 0.44)],
      };

  List<double> get _bands => switch (scene) {
        NxScene.home => [120, 520],
        NxScene.chats => [300, 700],
        NxScene.nodes => [240, 640],
        NxScene.map => [200, 600],
        NxScene.more => [180, 600],
      };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = ground);
    if (size.isEmpty) return;
    final sx = size.width / _w;
    final sy = size.height / _h;
    // A wide window stretches the layout; size glows by the shorter axis so
    // they stay round.
    final s = sx < sy ? sx : sy;
    final fade = dark ? 1.0 : 0.7;
    for (final (i, (cx, cy, r, strength)) in _glows.indexed) {
      final colour = i == 0 ? glow : second;
      final centre = Offset(cx * sx, cy * sy);
      final radius = r * s * 1.15;
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [colour.withValues(alpha: strength * fade), colour.withValues(alpha: 0)],
            stops: const [0, 0.7],
          ).createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = contour.withValues(alpha: dark ? 0.08 : 0.07);
    for (final top in _bands) {
      for (var k = 0; k < 3; k++) {
        final y = top + k * 45;
        final path = Path()
          ..moveTo(-20 * sx, y * sy)
          ..cubicTo((80 + k * 10) * sx, (y - 60) * sy, (180 + k * 10) * sx, (y + 60) * sy, (300 + k * 5) * sx,
              (y - 10) * sy)
          ..cubicTo(360 * sx, (y - 25) * sy, 420 * sx, (y + 20) * sy, 440 * sx, (y + 20) * sy);
        canvas.drawPath(path, line);
      }
    }
    final glints = sparkle;
    if (glints != null && glints.isNotEmpty) _paintSparkle(canvas, size, glints);
  }

  /// A fixed scatter of glints: the same seed per scene gives the same
  /// picture every time, so nothing flickers.
  void _paintSparkle(Canvas canvas, Size size, List<Color> colors) {
    final rnd = math.Random(17 + scene.index * 101);
    final count = (size.width * size.height / 9000).clamp(18, 60).round();
    // Big glints stay in the side margins so none sits under text.
    const gutter = 22.0;
    for (var i = 0; i < count; i++) {
      final big = rnd.nextDouble() < 0.35;
      final x = big
          ? (rnd.nextBool() ? rnd.nextDouble() * gutter : size.width - rnd.nextDouble() * gutter)
          : rnd.nextDouble() * size.width;
      final centre = Offset(x, rnd.nextDouble() * size.height);
      final r = big ? 5 + rnd.nextDouble() * 5 : 1.2 + rnd.nextDouble() * 1.2;
      final colour = colors[i % colors.length];
      final alpha = big ? 0.6 : 0.25 + rnd.nextDouble() * 0.2;
      final paint = Paint()..color = colour.withValues(alpha: alpha);
      if (r < 3) {
        canvas.drawCircle(centre, r * 0.6, paint);
        continue;
      }
      final w = r * 0.18;
      final path = Path()
        ..moveTo(centre.dx, centre.dy - r)
        ..quadraticBezierTo(centre.dx + w, centre.dy - w, centre.dx + r, centre.dy)
        ..quadraticBezierTo(centre.dx + w, centre.dy + w, centre.dx, centre.dy + r)
        ..quadraticBezierTo(centre.dx - w, centre.dy + w, centre.dx - r, centre.dy)
        ..quadraticBezierTo(centre.dx - w, centre.dy - w, centre.dx, centre.dy - r)
        ..close();
      canvas.drawCircle(
        centre,
        r * 0.9,
        Paint()
          ..color = colour.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(NxGlowPainter old) =>
      old.scene != scene ||
      old.ground != ground ||
      old.glow != glow ||
      old.second != second ||
      old.contour != contour ||
      old.dark != dark ||
      !_same(old.sparkle, sparkle);

  static bool _same(List<Color>? a, List<Color>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
