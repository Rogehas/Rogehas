import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/scene_art.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  NewsKind? _filter; // null = tümü

  static const _filters = <(String, NewsKind?)>[
    ('Tümü', null),
    ('Haber', NewsKind.haber),
    ('Duyuru', NewsKind.duyuru),
    ('Kesinti', NewsKind.kesinti),
  ];

  @override
  Widget build(BuildContext context) {
    final items = MockData.news
        .where((n) => _filter == null || n.kind == _filter)
        .toList();
    final featured = items.isNotEmpty ? items.first : null;
    final rest = items.skip(1).toList();

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          Row(
            children: [
              Expanded(child: Text('Haberler', style: AppTheme.display(36))),
              const RoundIconButton(icon: Icons.search, label: 'Ara'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (label, kind) in _filters) ...[
                  FilterChipPill(
                    label,
                    selected: _filter == kind,
                    onTap: () => setState(() => _filter = kind),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (featured == null)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: Text(
                  'Bu kategoride haber yok.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else ...[
            _Featured(featured),
            for (final n in rest) ...[const SizedBox(height: 14), _Row(n)],
          ],
        ],
      ),
    );
  }
}

class _Featured extends StatelessWidget {
  const _Featured(this.item);
  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
          Positioned.fill(
            child: SceneArt(palette: ScenePalette.dusk, radius: 30),
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
                    style: AppTheme.display(21, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.meta,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB8CBC4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.item);
  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            child: SceneArt(palette: item.palette, radius: 18),
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
                  style: const TextStyle(
                    fontSize: 15,
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
