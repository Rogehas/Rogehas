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
    final Widget base = url == null
        ? art
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: SizedBox.expand(
              child: RemoteImage(url: url, fallback: art),
            ),
          );
    if (item.videoId == null) return base;
    // Videolu haber: ortada oynat simgesi.
    return Stack(
      fit: StackFit.expand,
      children: [
        base,
        const Center(child: PlayBadge()),
      ],
    );
  }
}

/// Videolu haberlerin kapağındaki oynat simgesi.
class PlayBadge extends StatelessWidget {
  const PlayBadge({super.key, this.size = 46});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Color(0xB3000000),
      shape: BoxShape.circle,
    ),
    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: size * .7),
  );
}
