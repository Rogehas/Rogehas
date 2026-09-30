import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/app_theme.dart';

class TagChip extends StatelessWidget {
  const TagChip(this.text, this.kind, {super.key});
  final String text;
  final NewsKind kind;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (kind) {
      NewsKind.haber => (AppColors.primary, AppColors.limeSoft),
      NewsKind.duyuru => (AppColors.ink, AppColors.sky),
      NewsKind.kesinti => (AppColors.clay, AppColors.claySoft),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: .6,
          color: fg,
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.background = AppColors.surface,
    this.color = AppColors.ink,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            boxShadow: background == AppColors.surface
                ? AppTheme.cardShadow
                : null,
          ),
          child: Icon(icon, size: 22, color: color),
        ),
      ),
    );
  }
}

class FilterChipPill extends StatelessWidget {
  const FilterChipPill(
    this.text, {
    super.key,
    this.selected = false,
    this.onTap,
  });
  final String text;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.surface,
          borderRadius: BorderRadius.circular(21),
          boxShadow: selected ? null : AppTheme.cardShadow,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
