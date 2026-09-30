import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/scene_art.dart';
import 'shell.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _guest(BuildContext context) =>
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => const Shell()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          const Positioned.fill(
            bottom: 300,
            child: SceneArt(
              custom: [
                AppColors.primary,
                AppColors.lime,
                Color(0xFF1C7A64),
                Color(0xFF136650),
                Color(0xFF0C5343),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text('T', style: AppTheme.display(24)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Tavas',
                    style: AppTheme.display(22, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tavas cebinde.',
                        style: AppTheme.display(36),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Haberler, nöbetçi eczane, vefat ilanları ve ilçenin tüm bilgisi tek yerde.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _AuthButton(
                      label: 'Başla',
                      background: AppColors.lime,
                      foreground: AppColors.ink,
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: AppColors.ink,
                      ),
                      onTap: () => _guest(context),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Haber, vefat ilanı, nöbetçi eczane, etkinlik ve rehber için giriş yapmana gerek yok.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.trailing,
  });
  final String label;
  final Color background, foreground;
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 4), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
