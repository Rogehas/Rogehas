import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/data_stream.dart';
import '../widgets/news_visual.dart';
import 'business_screen.dart';
import '../widgets/notice_prefs.dart';
import '../widgets/url_opener.dart';
import 'eczane_screen.dart';
import 'events_screen.dart';
import 'guide_screen.dart';
import 'news_detail_screen.dart';
import 'tabs.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenTab,
    required this.onOpenNews,
    this.opener = defaultOpen,
  });
  final ValueChanged<int> onOpenTab;

  /// Haberler sekmesini verilen türe süzülmüş açar.
  final ValueChanged<NewsKind> onOpenNews;
  final UrlOpener opener;

  void _openNews(BuildContext context, NewsItem n) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => NewsDetailScreen(n)));

  @override
  Widget build(BuildContext context) {
    final news = ContentScope.of(context).news;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Hero(
          onBell: () => showNoticePrefsSheet(context),
          onOpen: (n) => _openNews(context, n),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _ShortcutGrid(onOpenNews: onOpenNews, opener: opener),
              DataStream<List<NewsItem>>(
                source: news,
                builder: (context, all) {
                  final rest = all.skip(1).take(3).toList();
                  if (rest.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: [
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              'Son gönderiler',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.display(24),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => onOpenTab(Tabs.haberler),
                            child: const Text(
                              'Tümü',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final n in rest) ...[
                        _NewsRow(n, onTap: () => _openNews(context, n)),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 120),
      ],
    );
  }
}

/// Günün saatine göre selamlama.
String greeting(DateTime now) {
  final h = now.hour;
  if (h < 6) return 'İyi geceler';
  if (h < 12) return 'Günaydın';
  if (h < 18) return 'İyi günler';
  return 'İyi akşamlar';
}

/// Üstte, kaydırılarak gezilen son haberler; üzerinde selamlama ve bildirim düğmesi.
class _Hero extends StatefulWidget {
  const _Hero({required this.onBell, required this.onOpen});
  final VoidCallback onBell;
  final ValueChanged<NewsItem> onOpen;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  static const _maxSlides = 5;
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(int page) => _controller.animateToPage(
    page,
    duration: const Duration(milliseconds: 280),
    curve: Curves.easeOut,
  );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final height = 400 + top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: AppColors.primary)),
            Positioned.fill(
              child: DataStream<List<NewsItem>>(
                dark: true,
                source: ContentScope.of(context).news,
                builder: (context, all) {
                  final slides = all.take(_maxSlides).toList();
                  if (slides.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Text(
                          'Henüz haber yok.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }
                  final page = _page.clamp(0, slides.length - 1);
                  return Stack(
                    children: [
                      PageView.builder(
                        controller: _controller,
                        itemCount: slides.length,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemBuilder: (context, i) => _Slide(
                          slides[i],
                          onTap: () => widget.onOpen(slides[i]),
                        ),
                      ),
                      if (slides.length > 1) ...[
                        Positioned(
                          left: 14,
                          top: top + 170,
                          child: _Arrow(
                            icon: Icons.chevron_left,
                            label: 'Önceki haber',
                            onTap: () =>
                                _go((page - 1 + slides.length) % slides.length),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          top: top + 170,
                          child: _Arrow(
                            icon: Icons.chevron_right,
                            label: 'Sonraki haber',
                            onTap: () => _go((page + 1) % slides.length),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 20,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < slides.length; i++)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3.5,
                                  ),
                                  width: i == page ? 26 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(
                                      alpha: i == page ? 1 : 0.45,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Positioned(
              top: top + 14,
              left: 20,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${greeting(DateTime.now())}, Tavas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.display(26, color: Colors.white),
                    ),
                  ),
                  RoundIconButton(
                    icon: Icons.notifications_none,
                    label: 'Bildirim ayarları',
                    background: const Color(0x29FFFFFF),
                    color: Colors.white,
                    onTap: widget.onBell,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RoundIconButton(
      icon: icon,
      label: label,
      background: const Color(0x8C092821),
      color: Colors.white,
      onTap: onTap,
    );
  }
}

/// Tek haber slaytı: tam genişlik görsel, altta etiket, başlık ve zaman.
class _Slide extends StatelessWidget {
  const _Slide(this.item, {required this.onTap});
  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          NewsVisual(item, palette: ScenePalette.dusk),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.3, 1],
                colors: [
                  Color(0x59092821),
                  Color(0x00092821),
                  Color(0xEB092821),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 50,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TagChip(item.tagText, item.kind),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.display(26, color: Colors.white),
                ),
                if (item.meta.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.meta,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFD5E2DD),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Shortcut {
  eczane(Icons.local_pharmacy_outlined, 'Nöbetçi\nEczane', AppColors.limeSoft),
  rehber(Icons.menu_book_outlined, 'Rehber', AppColors.sky),
  etkinlik(Icons.event_outlined, 'Etkinlik', AppColors.sand),
  esnaf(Icons.storefront_outlined, 'Esnaf', AppColors.lavender),
  kesinti(Icons.bolt_outlined, 'Kesintiler', AppColors.claySoft),
  duyuru(Icons.campaign_outlined, 'Duyurular', AppColors.mint),
  harita(Icons.map_outlined, 'Harita', AppColors.sky),
  bildirim(Icons.notifications_none, 'Bildirimler', AppColors.sand);

  const _Shortcut(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
}

/// "Harita" kısayolu: telefonun harita uygulamasında Tavas'ı açar.
final Uri tavasMapUri = Uri.https('www.google.com', '/maps/search/', {
  'api': '1',
  'query': 'Tavas, Denizli',
});

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({required this.onOpenNews, required this.opener});
  final ValueChanged<NewsKind> onOpenNews;
  final UrlOpener opener;

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  void _run(BuildContext context, _Shortcut s) {
    switch (s) {
      case _Shortcut.eczane:
        _push(context, const EczaneScreen());
      case _Shortcut.rehber:
        _push(context, const GuideScreen());
      case _Shortcut.etkinlik:
        _push(context, const EventsScreen());
      case _Shortcut.esnaf:
        _push(context, const BusinessScreen());
      case _Shortcut.kesinti:
        onOpenNews(NewsKind.kesinti);
      case _Shortcut.duyuru:
        onOpenNews(NewsKind.duyuru);
      case _Shortcut.harita:
        openOrWarn(context, opener, tavasMapUri);
      case _Shortcut.bildirim:
        showNoticePrefsSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 6,
        mainAxisExtent: 108,
      ),
      children: [
        for (final s in _Shortcut.values)
          Semantics(
            button: true,
            label: s.label.replaceAll('\n', ' '),
            child: GestureDetector(
              onTap: () => _run(context, s),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: s.color,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(s.icon, size: 26, color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      s.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _NewsRow extends StatelessWidget {
  const _NewsRow(this.item, {required this.onTap});
  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: NewsVisual(item, radius: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TagChip(item.tagText, item.kind),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (item.meta.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.meta,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
