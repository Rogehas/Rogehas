import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../data/models.dart';
import '../data/youtube.dart';
import '../theme/app_theme.dart';
import 'news_visual.dart';
import 'url_opener.dart';

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
/// haberin içinde oynar; "YouTube'da aç" düğmesi her zaman yanında durur.
class NewsMedia extends StatefulWidget {
  const NewsMedia(this.item, {super.key, this.opener = defaultOpen});
  final NewsItem item;
  final UrlOpener opener;

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
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => openOrWarn(
              context,
              widget.opener,
              Uri.parse(youtubeWatchUrl(id)),
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text("YouTube'da aç"),
            style: TextButton.styleFrom(foregroundColor: AppColors.accentText),
          ),
        ),
      ],
    );
  }
}
