import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/models.dart';
import '../data/vefat_filter.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/data_stream.dart';
import '../widgets/news_visual.dart';
import '../widgets/scene_art.dart';
import 'eczane_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final news = ContentScope.of(context).news;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _Hero(),
        Transform.translate(
          offset: const Offset(0, -34),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                DataStream<List<NewsItem>>(
                  source: news,
                  builder: (context, all) => all.isEmpty
                      ? const _NoNews()
                      : _FeaturedNews(all.first, onTap: () => onOpenTab(1)),
                ),
                const SizedBox(height: 14),
                _VefatBanner(onTap: () => onOpenTab(2)),
                const SizedBox(height: 18),
                const _ShortcutGrid(),
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
                            Text('Son haberler', style: AppTheme.display(24)),
                            GestureDetector(
                              onTap: () => onOpenTab(1),
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
                          _NewsRow(n, onTap: () => onOpenTab(1)),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 90),
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

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 200 + top,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.primary)),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 120,
            child: SceneArt(
              custom: [
                AppColors.primary,
                AppColors.lime,
                Color(0xFF2A8A73),
                Color(0xFF1B7A64),
                AppColors.bg,
              ],
            ),
          ),
          Positioned(
            top: top + 14,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text('T', style: AppTheme.display(22)),
                ),
                const SizedBox(width: 10),
                Text('Tavas', style: AppTheme.display(20, color: Colors.white)),
                const Spacer(),
                const RoundIconButton(
                  icon: Icons.notifications_none,
                  label: 'Bildirimler',
                  background: Color(0x29FFFFFF),
                  color: Colors.white,
                ),
              ],
            ),
          ),
          Positioned(
            top: top + 76,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lime,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Tavas'ta bugün",
                  style: AppTheme.display(34, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Öne çıkan (en yeni) haber.
class _FeaturedNews extends StatelessWidget {
  const _FeaturedNews(this.item, {required this.onTap});
  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 230,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: NewsVisual(item, radius: 30, palette: ScenePalette.dusk),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: const Color(0xEB092821),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TagChip(item.tagText, item.kind),
                    const SizedBox(height: 8),
                    Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.display(21, color: Colors.white),
                    ),
                    if (item.meta.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.meta,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB8CBC4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoNews extends StatelessWidget {
  const _NoNews();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppTheme.cardShadow,
      ),
      child: const Text(
        'Henüz haber yok.',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _VefatBanner extends StatelessWidget {
  const _VefatBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: AppColors.darkAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department_outlined,
                color: AppColors.ink,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vefat ilanları',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  StreamBuilder<List<VefatItem>>(
                    stream: ContentScope.of(context).vefat.stream,
                    initialData: ContentScope.of(context).vefat.latest,
                    builder: (context, snap) {
                      final data = snap.data;
                      final text = data == null
                          ? 'İlanları gör'
                          : switch (filterVefat(
                              data,
                              0,
                              DateTime.now(),
                            ).length) {
                              0 => 'Güncel ilan yok',
                              final n => '$n güncel ilan',
                            };
                      return Text(
                        text,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.darkMuted,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.darkSurface2,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.darkAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid();

  static const _tiles = [
    (Icons.local_pharmacy_outlined, 'Nöbetçi\nEczane', AppColors.limeSoft),
    (Icons.menu_book_outlined, 'Rehber', AppColors.sky),
    (Icons.event_outlined, 'Etkinlik', AppColors.sand),
    (Icons.storefront_outlined, 'Esnaf', AppColors.lavender),
    (Icons.report_gmailerrorred_outlined, 'Şikâyet', AppColors.claySoft),
    (Icons.chat_bubble_outline, 'Sohbet', AppColors.mint),
    (Icons.bolt_outlined, 'Kesintiler', AppColors.sand),
    (Icons.map_outlined, 'Harita', AppColors.sky),
  ];

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
        for (final (icon, label, bg) in _tiles)
          GestureDetector(
            onTap: () {
              if (label.startsWith('Nöbetçi')) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const EczaneScreen()),
                );
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${label.replaceAll('\n', ' ')} sonraki fazda eklenecek.',
                  ),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(icon, size: 26, color: AppColors.ink),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    label,
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
