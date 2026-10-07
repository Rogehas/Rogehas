import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/hero_slides.dart';
import '../data/hero_style.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/data_stream.dart';
import '../widgets/news_visual.dart';
import '../widgets/remote_image.dart';
import 'business_screen.dart';
import 'complaint_screen.dart';
import '../widgets/notice_prefs.dart';
import '../widgets/url_opener.dart';
import 'eczane_screen.dart';
import 'events_screen.dart';
import 'guide_screen.dart';
import 'news_detail_screen.dart';
import 'tabs.dart';
import '../weather/weather.dart';

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
          onOpenVefat: () => onOpenTab(Tabs.vefat),
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
                                color: AppColors.accentText,
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
  const _Hero({
    required this.onBell,
    required this.onOpen,
    required this.onOpenVefat,
  });
  final VoidCallback onBell;
  final ValueChanged<NewsItem> onOpen;
  final VoidCallback onOpenVefat;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
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
    return Column(
      children: [
        // İnce kırmızı üst çubuk: küçük selamlama ve bildirim düğmesi.
        Container(
          color: AppColors.primary,
          padding: EdgeInsets.fromLTRB(18, top + 8, 12, 8),
          child: Row(
            children: [
              // Kırmızı çubukta kaybolmasın diye ince beyaz halkalı küçük logo.
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/branding/logo.png',
                    excludeFromSemantics: true,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${greeting(DateTime.now())}, Tavas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              if (WeatherScope.of(context) case final w?) _WeatherChip(w),
              const SizedBox(width: 6),
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
        SizedBox(
          height: 340,
          child: Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: AppColors.surface),
              ),
              Positioned.fill(
                child: DataStream<List<NewsItem>>(
                  dark: true,
                  source: ContentScope.of(context).news,
                  builder: (context, all) => StreamBuilder<List<VefatItem>>(
                    // Vefat akışı hata verirse kayan bölüm yalnızca haberlerle çalışır.
                    stream: ContentScope.of(context).vefat.stream,
                    initialData: ContentScope.of(context).vefat.latest,
                    builder: (context, vefatSnap) {
                      final vefat = vefatSnap.data;
                      final slides = buildHeroSlides(all, vefat ?? const []);
                      if (slides.isEmpty) {
                        return const Center(
                          child: Text(
                            'Henüz haber yok.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      final page = _page.clamp(0, slides.length - 1);
                      return Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            bottom: 26,
                            child: PageView.builder(
                              controller: _controller,
                              itemCount: slides.length,
                              onPageChanged: (i) => setState(() => _page = i),
                              itemBuilder: (context, i) {
                                final slide = slides[i];
                                final v = slide.vefat;
                                if (v != null) {
                                  return _VefatSlide(
                                    v,
                                    onTap: widget.onOpenVefat,
                                  );
                                }
                                final n = slide.news!;
                                return _Slide(
                                  n,
                                  style: heroStyleFor(i, n.kind),
                                  onTap: () => widget.onOpen(n),
                                );
                              },
                            ),
                          ),
                          if (slides.length > 1) ...[
                            Positioned(
                              left: 14,
                              top: 106,
                              child: _Arrow(
                                icon: Icons.chevron_left,
                                label: 'Önceki haber',
                                onTap: () => _go(
                                  (page - 1 + slides.length) % slides.length,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 14,
                              top: 106,
                              child: _Arrow(
                                icon: Icons.chevron_right,
                                label: 'Sonraki haber',
                                onTap: () => _go((page + 1) % slides.length),
                              ),
                            ),
                            // Noktalar fotoğrafın ve başlığın altında, kendi ince şeridinde durur.
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 26,
                              child: ColoredBox(
                                color: AppColors.bg,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var i = 0; i < slides.length; i++)
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        width: i == page ? 20 : 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: i == page
                                              ? AppColors.lime
                                              : const Color(0xFF5A5A5A),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Üst çubukta Tavas'ın anlık havası: simge, derece ve kısa açıklama.
class _WeatherChip extends StatelessWidget {
  const _WeatherChip(this.w);
  final Weather w;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tavas hava durumu: ${w.tempC} derece, ${w.label}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(w.icon, size: 20, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            '${w.tempC}°',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            w.label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFF3C9CD)),
          ),
        ],
      ),
    );
  }
}

/// Kayan bölümde vefat ilanı: ölen kişinin fotoğrafı ve altta "Vefat: Ad Soyad".
class _VefatSlide extends StatelessWidget {
  const _VefatSlide(this.v, {required this.onTap});
  final VefatItem v;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: AppColors.darkSurface,
      child: Center(
        child: Text(
          v.initials,
          style: AppTheme.display(96, color: AppColors.darkAccent),
        ),
      ),
    );
    final photo = v.photoUrl;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Portre fotoğraflarda yüz kırpılmasın diye üst kısım tutulur.
          if (photo == null || photo.isEmpty)
            placeholder
          else
            RemoteImage(
              url: photo,
              fallback: placeholder,
              alignment: Alignment.topCenter,
            ),
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'VEFAT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                  color: AppColors.darkAccent,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xD9000000),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Vefat: ${v.name}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: Color(0xFFE6EBF0),
                ),
              ),
            ),
          ),
        ],
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
  const _Slide(this.item, {required this.style, required this.onTap});
  final NewsItem item;
  final HeroStyle style;
  final VoidCallback onTap;

  static const _shadow = [
    Shadow(color: Color(0xE6000000), blurRadius: 8, offset: Offset(0, 2)),
    Shadow(color: Color(0x99000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Şeritsiz, gölgeli yazı (altta).
  Widget _plain(Color color) => Positioned(
    left: 18,
    right: 18,
    bottom: 18,
    child: Text(
      item.title,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 27,
        fontWeight: FontWeight.w800,
        height: 1.2,
        color: color,
        shadows: _shadow,
      ),
    ),
  );

  /// Siyah yuvarlak şerit, altta.
  Widget _band(Color color) => Positioned(
    left: 14,
    right: 14,
    bottom: 16,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xD9000000),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        item.title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          height: 1.25,
          color: color,
        ),
      ),
    ),
  );

  Widget _title() => switch (style) {
    HeroStyle.whiteBottom => _plain(Colors.white),
    HeroStyle.yellowBottom => _plain(const Color(0xFFFFD84D)),
    HeroStyle.cyanBottom => _plain(const Color(0xFF8FE3FF)),
    HeroStyle.bandWhite => _band(Colors.white),
    HeroStyle.bandYellow => _band(const Color(0xFFFFD84D)),
    HeroStyle.bandAlert => _band(const Color(0xFFFF7A59)),
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fotoğrafın üstüne renk katmanı bindirilmez; yalnızca yazı stilleri vardır.
          NewsVisual(item, palette: ScenePalette.dusk),
          _title(),
          // Haber / Duyuru / Kesinti etiketi fotoğrafın sol üst köşesinde.
          Positioned(
            left: 14,
            top: 14,
            child: TagChip(item.tagText, item.kind),
          ),
        ],
      ),
    );
  }
}

enum _Shortcut {
  eczane(
    Icons.local_pharmacy_rounded,
    'Nöbetçi\nEczane',
    Color(0xFF34D399),
    Color(0xFF059669),
  ),
  rehber(
    Icons.menu_book_rounded,
    'Rehber',
    Color(0xFF60A5FA),
    Color(0xFF2563EB),
  ),
  etkinlik(
    Icons.celebration_rounded,
    'Etkinlik',
    Color(0xFFA78BFA),
    Color(0xFF7C3AED),
  ),
  esnaf(
    Icons.storefront_rounded,
    'Esnaf',
    Color(0xFFFBBF24),
    Color(0xFFEA580C),
  ),
  kesinti(
    Icons.bolt_rounded,
    'Kesintiler',
    Color(0xFFFACC15),
    Color(0xFFD97706),
  ),
  duyuru(
    Icons.campaign_rounded,
    'Duyurular',
    Color(0xFFF472B6),
    Color(0xFFDB2777),
  ),
  harita(Icons.map_rounded, 'Harita', Color(0xFF2DD4BF), Color(0xFF0D9488)),
  sikayet(
    Icons.rate_review_rounded,
    'Şikâyet\nÖneri',
    Color(0xFFFB7185),
    Color(0xFFE11D48),
  );

  const _Shortcut(this.icon, this.label, this.light, this.deep);
  final IconData icon;
  final String label;

  /// Simge karesinin gradyanındaki açık ve koyu tonlar.
  final Color light;
  final Color deep;
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
      case _Shortcut.sikayet:
        _push(context, const ComplaintScreen());
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [s.light, s.deep],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: s.deep.withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(s.icon, size: 30, color: Colors.white),
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
