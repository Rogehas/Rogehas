import 'dart:async';

import 'package:flutter/material.dart';

import '../notifications/notification_settings.dart';
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
  StreamSubscription<NoticeMessage>? _sub;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final settings = NotificationScope.of(context);
    // İlk açılışta bildirim izni istenir ve varsayılan konulara abone olunur.
    unawaited(settings.start());
    _sub = settings.foreground.listen(_showNotice);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Uygulama açıkken gelen bildirimi ekranda gösterir.
  void _showNotice(NoticeMessage m) {
    if (!mounted) return;
    final isVefat = m.topic == NoticeTopics.vefat;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (m.body.isNotEmpty) Text(m.body),
          ],
        ),
        action: isVefat
            ? SnackBarAction(
                label: 'Gör',
                onPressed: () => setState(() => _index = _vefatIndex),
              )
            : null,
      ),
    );
  }

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
