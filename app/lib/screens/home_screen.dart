import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/scene_art.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenTab});
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const _Hero(),
        Transform.translate(
          offset: const Offset(0, -46),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const _PrayerCard(),
                const SizedBox(height: 14),
                _VefatBanner(onTap: () => onOpenTab(2)),
                const SizedBox(height: 18),
                const _ShortcutGrid(),
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
              ],
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -46),
          child: SizedBox(
            height: 236,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
              children: [
                for (final n in [MockData.news[3], MockData.news[0]])
                  _NewsCard(n),
              ],
            ),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 262 + top,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.primary)),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 150,
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
                const Text(
                  'İyi akşamlar',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lime,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Tavas'ta bugün",
                  style: AppTheme.display(36, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            top: top + 162,
            left: 20,
            child: const Row(
              children: [
                _HeroChip(
                  Icons.wb_sunny_outlined,
                  '24° Güneşli',
                  Color(0xFFF4C95D),
                ),
                SizedBox(width: 8),
                _HeroChip(Icons.place_outlined, 'Denizli', Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip(this.icon, this.text, this.iconColor);
  final IconData icon;
  final String text;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: const Color(0xB8083228),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _PrayerCard extends StatelessWidget {
  const _PrayerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SIRADAKİ VAKİT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Akşam · 18:52', style: AppTheme.display(30)),
                  ],
                ),
              ),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.schedule, size: 16),
                    SizedBox(width: 6),
                    Text(
                      '2 sa 10 dk',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: const LinearProgressIndicator(
              value: .62,
              minHeight: 6,
              backgroundColor: AppColors.line,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final p in MockData.prayers)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: p.isNext ? AppColors.ink : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.isNext ? Colors.white : AppColors.muted,
                          ),
                        ),
                        Text(
                          p.time,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: p.isNext ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vefat ilanları',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  Text(
                    'Bugün 2 yeni ilan',
                    style: TextStyle(fontSize: 13, color: AppColors.darkMuted),
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
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${label.replaceAll('\n', ' ')} sonraki fazda eklenecek.',
                ),
              ),
            ),
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

class _NewsCard extends StatelessWidget {
  const _NewsCard(this.item);
  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppTheme.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 116, child: SceneArt(palette: item.palette)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TagChip(item.tagText, item.kind),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.meta,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
