import 'package:flutter/material.dart';

import '../data/models.dart';
import 'remote_image.dart';
import 'scene_art.dart';

/// Haberin görseli; yoksa manzara çizimi.
class NewsVisual extends StatelessWidget {
  const NewsVisual(this.item, {super.key, this.radius = 0, this.palette});
  final NewsItem item;
  final double radius;
  final ScenePalette? palette;

  @override
  Widget build(BuildContext context) {
    final art = SceneArt(palette: palette ?? item.palette, radius: radius);
    final url = item.photoUrl;
    if (url == null) return art;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.expand(
        child: RemoteImage(url: url, fallback: art),
      ),
    );
  }
}
