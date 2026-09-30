import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/app_theme.dart';

class _Colors {
  const _Colors(this.sky, this.sun, this.r1, this.r2, this.r3);
  final Color sky, sun, r1, r2, r3;
}

const _palettes = {
  ScenePalette.day: _Colors(
    AppColors.sky,
    Color(0xFFF2B84B),
    Color(0xFF9CC7B4),
    Color(0xFF4F9C82),
    AppColors.primary,
  ),
  ScenePalette.sand: _Colors(
    AppColors.sand,
    AppColors.clay,
    Color(0xFFC9B98F),
    Color(0xFF8FA07A),
    Color(0xFF4D6B4B),
  ),
  ScenePalette.dusk: _Colors(
    Color(0xFF26404F),
    Color(0xFFF2B84B),
    Color(0xFF3F6B78),
    Color(0xFF2C5560),
    Color(0xFF173A3A),
  ),
};

/// Yerel görsel yerine kullanılan düz renkli manzara çizimi.
class SceneArt extends StatelessWidget {
  const SceneArt({
    super.key,
    this.palette = ScenePalette.day,
    this.radius = 0,
    this.custom,
  });

  final ScenePalette palette;
  final double radius;

  /// Verilirse (sky, sun, r1, r2, r3) bu renkler kullanılır.
  final List<Color>? custom;

  @override
  Widget build(BuildContext context) {
    final c = custom != null
        ? _Colors(custom![0], custom![1], custom![2], custom![3], custom![4])
        : _palettes[palette]!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.expand(child: CustomPaint(painter: _ScenePainter(c))),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.c);
  final _Colors c;

  @override
  void paint(Canvas canvas, Size size) {
    const w = 400.0, h = 240.0;
    final scale = size.width / w > size.height / h
        ? size.width / w
        : size.height / h;
    canvas.clipRect(Offset.zero & size);
    canvas.translate((size.width - w * scale) / 2, size.height - h * scale);
    canvas.scale(scale);
    canvas.drawRect(
      const Rect.fromLTWH(0, -200, w, h + 200),
      Paint()..color = c.sky,
    );
    canvas.drawCircle(const Offset(292, 62), 28, Paint()..color = c.sun);

    Path ridge(void Function(Path) f) {
      final p = Path();
      f(p);
      p.lineTo(w, h);
      p.lineTo(0, h);
      p.close();
      return p;
    }

    canvas.drawPath(
      ridge(
        (p) => p
          ..moveTo(0, 150)
          ..lineTo(70, 84)
          ..lineTo(130, 140)
          ..lineTo(200, 76)
          ..lineTo(280, 150)
          ..lineTo(340, 106)
          ..lineTo(400, 150),
      ),
      Paint()..color = c.r1,
    );
    canvas.drawPath(
      ridge(
        (p) => p
          ..moveTo(0, 182)
          ..quadraticBezierTo(80, 128, 160, 170)
          ..quadraticBezierTo(240, 212, 320, 158)
          ..quadraticBezierTo(370, 140, 400, 176),
      ),
      Paint()..color = c.r2,
    );
    canvas.drawPath(
      ridge(
        (p) => p
          ..moveTo(0, 208)
          ..quadraticBezierTo(100, 172, 200, 202)
          ..quadraticBezierTo(300, 232, 400, 190),
      ),
      Paint()..color = c.r3,
    );
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.c != c;
}
