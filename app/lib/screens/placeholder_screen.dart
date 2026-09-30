import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Sonraki fazlarda yapılacak ekranlar için geçici sayfa.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(title, style: AppTheme.display(36)),
            const Spacer(),
            const Center(
              child: Text(
                'Bu bölüm sonraki fazda eklenecek.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
