import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'business_screen.dart';
import 'events_screen.dart';
import 'guide_screen.dart';

/// Keşfet sekmesi: etkinlik, rehber ve yerel esnaf girişleri.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          Text('Keşfet', style: AppTheme.display(36)),
          const SizedBox(height: 4),
          const Text(
            "Tavas'ta neler olup bittiğine göz at.",
            style: TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          _ExploreCard(
            icon: Icons.event_outlined,
            title: 'Etkinlikler',
            subtitle: 'Festival, pazar ve yerel etkinlikler',
            background: AppColors.lime,
            onTap: () => _open(context, const EventsScreen()),
          ),
          const SizedBox(height: 12),
          _ExploreCard(
            icon: Icons.storefront_outlined,
            title: 'Yerel Esnaf',
            subtitle: 'Restoran, konaklama ve hizmetler',
            background: AppColors.sky,
            onTap: () => _open(context, const BusinessScreen()),
          ),
          const SizedBox(height: 12),
          _ExploreCard(
            icon: Icons.menu_book_outlined,
            title: 'Rehber',
            subtitle: 'Acil numaralar, kurumlar ve telefonlar',
            background: AppColors.sand,
            onTap: () => _open(context, const GuideScreen()),
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.background,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 28, color: AppColors.ink),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTheme.display(23)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: Color(0xFF3B463F),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}
