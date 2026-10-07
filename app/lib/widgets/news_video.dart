import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../data/models.dart';
import 'news_visual.dart';

/// Videoyu çizen bileşen. Testlerde sahte bir sürümle değiştirilir.
typedef VideoPlayerBuilder = Widget Function(BuildContext context, String id);

Widget _iframePlayer(BuildContext context, String id) => _IframePlayer(id);

VideoPlayerBuilder videoPlayerBuilder = _iframePlayer;

class _IframePlayer extends StatefulWidget {
  const _IframePlayer(this.id);
  final String id;

  @override
  State<_IframePlayer> createState() => _IframePlayerState();
}

class _IframePlayerState extends State<_IframePlayer> {
  late final YoutubePlayerController _c = YoutubePlayerController.fromVideoId(
    videoId: widget.id,
    autoPlay: true,
    params: const YoutubePlayerParams(
      showFullscreenButton: true,
      strictRelatedVideos: true,
    ),
  );

  @override
  void dispose() {
    _c.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      YoutubePlayer(controller: _c, aspectRatio: 16 / 9);
}

/// Haber ayrıntısının üstündeki görsel. Videolu haberde kapağa dokununca video
/// haberin içinde oynar.
class NewsMedia extends StatefulWidget {
  const NewsMedia(this.item, {super.key});
  final NewsItem item;

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final id = widget.item.videoId;
    if (id == null) {
      return SizedBox(height: 210, child: NewsVisual(widget.item, radius: 28));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _playing
                ? videoPlayerBuilder(context, id)
                : Semantics(
                    button: true,
                    label: 'Videoyu oynat',
                    child: GestureDetector(
                      onTap: () => setState(() => _playing = true),
                      child: NewsVisual(widget.item),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
