import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NavItem {
  const NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Yüzen, hap biçimli alt menü. Aktif sekme etiketiyle görünür.
class FloatingNav extends StatelessWidget {
  const FloatingNav({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.dark = false,
  });

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onChanged;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.darkSurface2 : AppColors.ink;
    final accent = dark ? AppColors.darkAccent : AppColors.lime;
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < items.length; i++)
            Flexible(
              flex: i == index ? 2 : 1,
              child: Semantics(
                button: true,
                selected: i == index,
                label: items[i].label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 52,
                    constraints: const BoxConstraints(minWidth: 46),
                    padding: EdgeInsets.symmetric(
                      horizontal: i == index ? 14 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: i == index ? accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].icon,
                          size: 22,
                          color: i == index
                              ? AppColors.ink
                              : const Color(0xFFB4C4BE),
                        ),
                        if (i == index) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              items[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ],
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
