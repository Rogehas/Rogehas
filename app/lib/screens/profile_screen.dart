import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/notice_prefs.dart';

/// Profil sekmesi: bildirim tercihleri ve uygulama bilgisi.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(28),
      boxShadow: AppTheme.cardShadow,
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          Text('Profil', style: AppTheme.display(36)),
          const SizedBox(height: 16),
          _card(
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.limeSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, color: AppColors.ink),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Misafir',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Uygulamayı giriş yapmadan kullanıyorsun. Haber, vefat ilanı ve eczane için giriş gerekmez.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bildirimler', style: AppTheme.display(22)),
                const SizedBox(height: 4),
                const Text(
                  'Hangi konularda telefonuna bildirim gelsin?',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                const NoticePrefsList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tavas',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  "Tavas'a ait haber, duyuru, vefat ilanı, nöbetçi eczane, etkinlik, rehber ve yerel esnaf bilgileri.",
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
