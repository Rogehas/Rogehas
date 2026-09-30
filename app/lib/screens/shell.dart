import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../notifications/notification_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_nav.dart';
import 'chat_screen.dart';
import 'home_screen.dart';
import 'news_screen.dart';
import 'profile_screen.dart';
import 'tabs.dart';
import 'vefat_screen.dart';

/// Sıra [Tabs] ile aynıdır: Haberler, Sohbet, Ana Sayfa (ortada), Profil, Vefat.
final _items = [
  const NavItem(Icons.article_outlined, 'Haberler'),
  const NavItem(Icons.chat_bubble_outline, 'Sohbet'),
  const NavItem(Icons.home_rounded, 'Ana Sayfa'),
  const NavItem(Icons.person_outline, 'Profil'),
  NavItem.custom((c) => TombstoneIcon(color: c), 'Vefat'),
];

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = Tabs.ana; // Uygulama doğrudan ana sayfada açılır.
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
          _index = Tabs.vefat;
        case NoticeTopics.kesinti:
          _newsFilter.value = NewsKind.kesinti;
          _index = Tabs.haberler;
        case NoticeTopics.duyuru:
          _newsFilter.value = NewsKind.duyuru;
          _index = Tabs.haberler;
        default:
          _newsFilter.value = null;
          _index = Tabs.haberler;
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
                onPressed: () => setState(() => _index = Tabs.vefat),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = _index == Tabs.vefat;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    // Ana sayfanın üstü koyu yeşil, vefat koyu tema: durum çubuğu simgeleri açık renk.
    final lightIcons = _index == Tabs.ana || dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightIcons
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: dark ? AppColors.darkBg : AppColors.bg,
        body: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: _index,
                children: [
                  _newsScreen,
                  const ChatScreen(),
                  HomeScreen(
                    onOpenTab: (i) => setState(() => _index = i),
                    onOpenNews: (kind) => setState(() {
                      _newsFilter.value = kind;
                      _index = Tabs.haberler;
                    }),
                  ),
                  const ProfileScreen(),
                  const VefatScreen(),
                ],
              ),
            ),
            // Klavye açıkken (sohbet yazarken) menü yazı alanını kapatmasın.
            if (!keyboardOpen)
              Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: SafeArea(
                  top: false,
                  child: FloatingNav(
                    items: _items,
                    index: _index,
                    centerIndex: Tabs.ana,
                    dark: dark,
                    onChanged: (i) => setState(() => _index = i),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
