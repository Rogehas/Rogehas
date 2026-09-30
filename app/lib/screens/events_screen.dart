import 'package:flutter/material.dart';

import '../data/content_logic.dart';
import '../data/content_repository.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/data_stream.dart';
import '../widgets/remote_image.dart';
import '../widgets/sub_page.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hub = ContentScope.of(context);
    return SubPage(
      title: 'Etkinlikler',
      children: [
        DataStream<List<EventItem>>(
          source: hub.events,
          builder: (context, all) {
            final now = DateTime.now();
            final list = upcomingEvents(all, now);
            if (list.isEmpty) {
              return const SoftNotice(
                Icons.event_outlined,
                'Yakında planlanmış bir etkinlik yok.',
              );
            }
            return Column(
              children: [
                for (final e in list) ...[
                  _EventCard(e, now: now),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard(this.e, {required this.now});
  final EventItem e;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final badge = eventBadge(e);
    final when = eventWhenLabel(e, now);
    final meta = [
      when,
      if (e.time.isNotEmpty) e.time,
      if (e.place.isNotEmpty) e.place,
    ].join(' · ');
    return GestureDetector(
      onTap: () => _showDetail(context, e, meta),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 66,
              decoration: BoxDecoration(
                color: AppColors.lime,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    badge.month,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(badge.day, style: AppTheme.display(26)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

void _showDetail(BuildContext context, EventItem e, String meta) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (e.photoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: RemoteImage(
                    url: e.photoUrl!,
                    fallback: const ColoredBox(color: AppColors.sand),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(e.title, style: AppTheme.display(26)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.schedule, size: 18, color: AppColors.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meta,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            if (e.description.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                e.description,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
