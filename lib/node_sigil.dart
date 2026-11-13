import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The shape drawn for a node, worked out from its number alone.
///
/// The same node always gets the same sigil on every phone: a coloured disc
/// with a star figure whose points, turn, stride and marks come from a hash of
/// the node number. Nothing is random and nothing is stored.
@immutable
class NodeSigilSpec {
  const NodeSigilSpec({
    required this.hue,
    required this.points,
    required this.turn,
    required this.stride,
    required this.core,
    required this.marks,
  });

  /// FNV-1a over the node number's four bytes, so nearby numbers differ.
  static int hash(int num) {
    var h = 0x811c9dc5;
    for (var shift = 0; shift < 32; shift += 8) {
      h ^= (num >> shift) & 0xff;
      h = (h * 0x01000193) & 0xffffffff;
    }
    return h;
  }

  factory NodeSigilSpec.of(int num) {
    final h = hash(num);
    final points = 3 + (h >> 9) % 5;
    return NodeSigilSpec(
      hue: (h % 360).toDouble(),
      points: points,
      turn: (h >> 12) % 12,
      stride: 1 + (h >> 16) % (points - 1),
      core: (h >> 20) % 3,
      marks: (h >> 23) & ((1 << points) - 1),
    );
  }

  /// Background hue in degrees.
  final double hue;

  /// Number of outer points, 3–7.
  final int points;

  /// Rotation in twelfths of a turn.
  final int turn;

  /// How many points each line skips; 1 draws a plain polygon.
  final int stride;

  /// Centre mark: 0 none, 1 ring, 2 dot.
  final int core;

  /// Bit i set: point i carries a dot.
  final int marks;

  Color get background => HSLColor.fromAHSL(1, hue, 0.55, 0.32).toColor();
  Color get ink => HSLColor.fromAHSL(1, hue, 0.45, 0.93).toColor();

  @override
  bool operator ==(Object other) =>
      other is NodeSigilSpec && other.hue == hue && other.points == points &&
      other.turn == turn && other.stride == stride && other.core == core && other.marks == marks;

  @override
  int get hashCode => Object.hash(hue, points, turn, stride, core, marks);
}

/// A node's sigil. Decorative: screen readers hear the node's name from the
/// surrounding tile instead, so the drawing is hidden from them.
class NodeSigil extends StatelessWidget {
  const NodeSigil({super.key, required this.num, this.size = 40});
  final int num;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: CustomPaint(
          size: Size.square(size),
          painter: _SigilPainter(NodeSigilSpec.of(num)),
        ),
      );
}

class _SigilPainter extends CustomPainter {
  _SigilPainter(this.spec);
  final NodeSigilSpec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, r, Paint()..color = spec.background);
    final ink = Paint()
      ..color = spec.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, r * 0.09)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final start = spec.turn * math.pi / 6 - math.pi / 2;
    final outer = [
      for (var i = 0; i < spec.points; i++)
        c + Offset.fromDirection(start + i * 2 * math.pi / spec.points, r * 0.62),
    ];
    final path = Path();
    final visited = <int>{};
    for (var s = 0; s < spec.points; s++) {
      if (visited.contains(s)) continue;
      var i = s;
      path.moveTo(outer[i].dx, outer[i].dy);
      do {
        visited.add(i);
        i = (i + spec.stride) % spec.points;
        path.lineTo(outer[i].dx, outer[i].dy);
      } while (i != s);
    }
    canvas.drawPath(path, ink);
    final fill = Paint()..color = spec.ink;
    for (var i = 0; i < spec.points; i++) {
      if (spec.marks & (1 << i) != 0) canvas.drawCircle(outer[i], r * 0.11, fill);
    }
    switch (spec.core) {
      case 1:
        canvas.drawCircle(c, r * 0.2, ink);
      case 2:
        canvas.drawCircle(c, r * 0.12, fill);
    }
  }

  @override
  bool shouldRepaint(_SigilPainter old) => old.spec != spec;
}
