import 'package:flutter/material.dart';

import '../data/content_logic.dart';
import '../data/content_repository.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/data_stream.dart';
import '../widgets/news_visual.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  /// [filter] dışarıdan da değiştirilebilir (ana sayfadaki "Kesintiler" / "Duyurular" kısayolları).
  NewsScreen({super.key, ValueNotifier<NewsKind?>? filter})
    : filter = filter ?? ValueNotifier<NewsKind?>(null);

  final ValueNotifier<NewsKind?> filter;

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  bool _searching = false;
  String _query = '';
  final _search = TextEditingController();

  static const _filters = <(String, NewsKind?)>[
    ('Tümü', null),
    ('Haber', NewsKind.haber),
    ('Duyuru', NewsKind.duyuru),
    ('Kesinti', NewsKind.kesinti),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _query = '';
        _search.clear();
      }
    });
  }

  void _open(NewsItem n) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => NewsDetailScreen(n)));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          Row(
            children: [
              Expanded(child: Text('Haberler', style: AppTheme.display(36))),
              RoundIconButton(
                icon: _searching ? Icons.close : Icons.search,
                label: _searching ? 'Aramayı kapat' : 'Ara',
                onTap: _toggleSearch,
              ),
            ],
          ),
          if (_searching) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Haberlerde ara…',
                filled: true,
                fillColor: AppColors.surface,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          ValueListenableBuilder<NewsKind?>(
            valueListenable: widget.filter,
            builder: (context, filter, _) => SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (label, kind) in _filters) ...[
                    FilterChipPill(
                      label,
                      selected: filter == kind,
                      onTap: () => widget.filter.value = kind,
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<NewsKind?>(
            valueListenable: widget.filter,
            builder: (context, filter, _) => DataStream<List<NewsItem>>(
              source: ContentScope.of(context).news,
              builder: (context, all) {
                final byKind = all
                    .where((n) => filter == null || n.kind == filter)
                    .toList();
                final items = searchNews(byKind, _query);
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text(
                        _query.trim().isNotEmpty
                            ? 'Aramanla eşleşen haber yok.'
                            : 'Bu kategoride haber yok.',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    _Featured(items.first, onTap: () => _open(items.first)),
                    for (final n in items.skip(1)) ...[
                      const SizedBox(height: 14),
                      _Row(n, onTap: () => _open(n)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Featured extends StatelessWidget {
  const _Featured(this.item, {required this.onTap});
  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 250,
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
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.item, {required this.onTap});
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.meta,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
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
