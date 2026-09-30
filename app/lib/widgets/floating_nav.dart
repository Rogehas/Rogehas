import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NavItem {
  const NavItem(IconData icon, this.label) : _icon = icon, _builder = null;
  const NavItem.custom(Widget Function(Color color) builder, this.label)
    : _icon = null,
      _builder = builder;

  final String label;
  final IconData? _icon;
  final Widget Function(Color color)? _builder;

  Widget build(Color color, {double size = 24}) => _builder != null
      ? _builder(color)
      : Icon(_icon, size: size, color: color);
}

/// Mezar taşı simgesi (Vefat sekmesi).
class TombstoneIcon extends StatelessWidget {
  const TombstoneIcon({super.key, required this.color, this.size = 24});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _TombstonePainter(color));
}

class _TombstonePainter extends CustomPainter {
  _TombstonePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final stone = Path()
      ..moveTo(6.5 * k, 21 * k)
      ..lineTo(6.5 * k, 10 * k)
      ..arcTo(
        Rect.fromCircle(center: Offset(12 * k, 10 * k), radius: 5.5 * k),
        math.pi,
        math.pi,
        false,
      )
      ..lineTo(17.5 * k, 21 * k);
    canvas.drawPath(stone, paint);
    canvas
      ..drawLine(Offset(3.5 * k, 21 * k), Offset(20.5 * k, 21 * k), paint)
      ..drawLine(Offset(9.5 * k, 11 * k), Offset(14.5 * k, 11 * k), paint)
      ..drawLine(Offset(9.5 * k, 14 * k), Offset(14.5 * k, 14 * k), paint);
  }

  @override
  bool shouldRepaint(_TombstonePainter old) => old.color != color;
}

/// Yüzen, hap biçimli alt menü. [centerIndex] öğesi ortada yukarı taşan yuvarlak düğmedir.
class FloatingNav extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    required this.centerIndex,
    this.dark = false,
  });

  final List<NavItem> items;
  final int index;
  final int centerIndex;
  final ValueChanged<int> onChanged;
  final bool dark;

  static const _height = 68.0;
  static const _lift = 26.0;
  static const _centerSize = 68.0;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.darkSurface2 : AppColors.primary;
    final accent = dark ? AppColors.darkAccent : AppColors.lime;
    const idle = Color(0xFFA9C4BA);
    final center = items[centerIndex];
    return SizedBox(
      height: _height + _lift,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _height,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(34),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D10201B),
                    blurRadius: 32,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: i == centerIndex
                          ? Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ExcludeSemantics(
                                  child: Text(
                                    center.label,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: accent,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Semantics(
                              excludeSemantics: true,
                              button: true,
                              selected: i == index,
                              label: items[i].label,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => onChanged(i),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    items[i].build(i == index ? accent : idle),
                                    const SizedBox(height: 3),
                                    Text(
                                      items[i].label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: i == index ? accent : idle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                excludeSemantics: true,
                button: true,
                selected: index == centerIndex,
                label: center.label,
                child: GestureDetector(
                  onTap: () => onChanged(centerIndex),
                  child: Container(
                    width: _centerSize,
                    height: _centerSize,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: dark ? AppColors.darkBg : AppColors.bg,
                        width: 5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D10201B),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: center.build(AppColors.ink, size: 30),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
