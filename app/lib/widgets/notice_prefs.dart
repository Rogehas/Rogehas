import 'package:flutter/material.dart';

import '../notifications/notification_settings.dart';
import '../theme/app_theme.dart';

/// Bildirim konularının açma/kapama listesi (Profil sekmesi ve zil penceresinde ortak).
class NoticePrefsList extends StatelessWidget {
  const NoticePrefsList({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = NotificationScope.of(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final t in NoticeTopics.all)
            _Row(
              label: NoticeTopics.labels[t]!,
              value: settings.isEnabled(t),
              onChanged: (v) async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await settings.setEnabled(t, v);
                if (!ok) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Bildirim izni kapalı. Telefonun Ayarlar > Uygulamalar > Tavas > Bildirimler bölümünden izin ver.',
                      ),
                    ),
                  );
                }
              },
            ),
          if (settings.problem != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Text(
                settings.problem!,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  color: AppColors.clay,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

/// Zil simgesi ve "Bildirimler" kısayolu bunu açar.
void showNoticePrefsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bg,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bildirimler', style: AppTheme.display(26)),
            const SizedBox(height: 4),
            const Text(
              'Hangi konularda telefonuna bildirim gelsin?',
              style: TextStyle(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            NotificationScope(
              settings: NotificationScope.of(context),
              child: const NoticePrefsList(),
            ),
          ],
        ),
      ),
    ),
  );
}
