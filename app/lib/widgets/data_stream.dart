import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../theme/app_theme.dart';

/// Paylaşılan bir akışı yükleniyor / hata / veri durumlarıyla gösterir.
class DataStream<T> extends StatelessWidget {
  const DataStream({
    super.key,
    required this.source,
    required this.builder,
    this.dark = false,
  });

  final Shared<T> source;
  final Widget Function(BuildContext context, T data) builder;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final muted = dark ? AppColors.darkMuted : AppColors.muted;
    return StreamBuilder<T>(
      stream: source.stream,
      initialData: source.latest,
      builder: (context, snap) {
        if (snap.hasData) return builder(context, snap.data as T);
        if (snap.hasError || source.error != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            child: Center(
              child: Text(
                'İçerik yüklenemedi. İnternet bağlantını kontrol edip uygulamayı yeniden aç.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, height: 1.5),
              ),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(
              color: dark ? AppColors.darkAccent : AppColors.primary,
            ),
          ),
        );
      },
    );
  }
}
