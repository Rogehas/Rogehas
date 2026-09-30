import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../notifications/notification_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_nav.dart';
import 'home_screen.dart';
import 'news_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';
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
  StreamSubscription<NoticeMessage>? _openedSub;
  bool _started = false;

  /// Haberler sekmesinin süzgeci; ana sayfadaki "Kesintiler" / "Duyurular" kısayolları da bunu değiştirir.
  final _newsFilter = ValueNotifier<NewsKind?>(null);
  late final _newsScreen = NewsScreen(filter: _newsFilter);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final settings = NotificationScope.of(context);
    // Dinleyiciler önce bağlanır; sonra start() bildirim izni ister ve (varsa) açılışı tetikleyen bildirimi yayar.
    _sub = settings.foreground.listen(_showNotice);
    _openedSub = settings.opened.listen(_openFromNotice);
    unawaited(settings.start());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _openedSub?.cancel();
    _newsFilter.dispose();
    super.dispose();
  }

  /// Telefondaki bildirime dokunulunca ilgili sekmeyi açar.
  void _openFromNotice(NoticeMessage m) {
    if (!mounted) return;
    setState(() {
      switch (m.topic) {
        case NoticeTopics.vefat:
          _index = _vefatIndex;
        case NoticeTopics.kesinti:
          _newsFilter.value = NewsKind.kesinti;
          _index = 1;
        case NoticeTopics.duyuru:
          _newsFilter.value = NewsKind.duyuru;
          _index = 1;
        default:
          _newsFilter.value = null;
          _index = 1;
      }
    });
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
                HomeScreen(
                  onOpenTab: (i) => setState(() => _index = i),
                  onOpenNews: (kind) => setState(() {
                    _newsFilter.value = kind;
                    _index = 1;
                  }),
                ),
                _newsScreen,
                const VefatScreen(),
                const ExploreScreen(),
                const ProfileScreen(),
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
