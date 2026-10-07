import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/comments_section.dart';
import '../widgets/common.dart';
import '../widgets/news_video.dart';
import '../widgets/share.dart';
import '../widgets/sub_page.dart';

/// Haberin tam metni.
class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen(this.item, {super.key, this.share = defaultShare});
  final NewsItem item;
  final ShareFn share;

  @override
  Widget build(BuildContext context) {
    final hasBody = item.body.isNotEmpty;
    return SubPage(
      title: item.kind == NewsKind.haber
          ? 'Haber'
          : item.kind == NewsKind.duyuru
          ? 'Duyuru'
          : 'Kesinti',
      children: [
        NewsMedia(item),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: TagChip(item.tagText, item.kind),
        ),
        const SizedBox(height: 10),
        Text(item.title, style: AppTheme.display(28)),
        if (item.meta.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            item.meta,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ],
        const SizedBox(height: 18),
        if (hasBody)
          SelectableText(
            item.body,
            style: const TextStyle(fontSize: 16, height: 1.6),
          )
        else
          const Text(
            'Bu haber için ek açıklama girilmemiş.',
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => share(
            [
              item.title,
              if (hasBody) '',
              if (hasBody) item.body,
              '',
              '— Tavas uygulaması',
            ].join('\n'),
          ),
          child: Semantics(
            button: true,
            label: 'Haberi paylaş',
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share_outlined, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Paylaş',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Kimliği olmayan (örnek) haberlerde yorum bölümü gösterilmez.
        if (item.id.isNotEmpty) ...[
          const SizedBox(height: 28),
          CommentsSection(newsId: item.id, open: item.commentsOpen),
        ],
      ],
    );
  }
}
