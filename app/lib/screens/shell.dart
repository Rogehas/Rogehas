import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/floating_nav.dart';
import 'home_screen.dart';
import 'news_screen.dart';
import 'placeholder_screen.dart';
import 'vefat_screen.dart';

const _items = [
  NavItem(Icons.home_outlined, 'Ana Sayfa'),
  NavItem(Icons.article_outlined, 'Haberler'),
  NavItem(Icons.local_fire_department_outlined, 'Vefat'),
  NavItem(Icons.explore_outlined, 'Keşfet'),
  NavItem(Icons.person_outline, 'Profil'),
];

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;
  static const _vefatIndex = 2;

  @override
  Widget build(BuildContext context) {
    final dark = _index == _vefatIndex;
    return Scaffold(
      backgroundColor: dark ? AppColors.darkBg : AppColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _index,
              children: [
                HomeScreen(onOpenTab: (i) => setState(() => _index = i)),
                const NewsScreen(),
                const VefatScreen(),
                const PlaceholderScreen(title: 'Keşfet'),
                const PlaceholderScreen(title: 'Profil'),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: SafeArea(
              top: false,
              child: FloatingNav(
                items: _items,
                index: _index,
                dark: dark,
                onChanged: (i) => setState(() => _index = i),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
