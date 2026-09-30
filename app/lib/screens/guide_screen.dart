import 'package:flutter/material.dart';

import '../data/content_logic.dart';
import '../data/content_repository.dart';
import '../data/links.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/data_stream.dart';
import '../widgets/sub_page.dart';
import '../widgets/url_opener.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key, this.opener = defaultOpen});
  final UrlOpener opener;

  @override
  Widget build(BuildContext context) {
    final hub = ContentScope.of(context);
    return SubPage(
      title: 'Rehber',
      children: [
        DataStream<List<GuideEntry>>(
          source: hub.guide,
          builder: (context, all) {
            final groups = groupGuide(all);
            if (groups.isEmpty) {
              return const SoftNotice(
                Icons.menu_book_outlined,
                'Rehber henüz boş.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final g in groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 0, 10),
                    child: Text(g.key, style: AppTheme.display(20)),
                  ),
                  for (final entry in g.value) ...[
                    _GuideRow(
                      entry,
                      onCall: () =>
                          openOrWarn(context, opener, telLink(entry.phone)),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow(this.g, {required this.onCall});
  final GuideEntry g;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    final emergency = g.category == 'Acil';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  g.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  prettyPhone(g.phone),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                if (g.address.isNotEmpty)
                  Text(
                    g.address,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.3,
                    ),
                  ),
                if (g.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      g.note,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: '${g.name} ara',
            child: GestureDetector(
              onTap: onCall,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: emergency ? AppColors.clay : AppColors.lime,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.call_outlined,
                  size: 22,
                  color: emergency ? Colors.white : AppColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
