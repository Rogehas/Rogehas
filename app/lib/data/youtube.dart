/// YouTube linkinden video kimliğini çıkarır; geçerli bir YouTube linki değilse null.
String? youtubeVideoId(Object? url) {
  if (url is! String) return null;
  var raw = url.trim();
  if (raw.isEmpty) return null;
  if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(raw)) {
    raw = 'https://$raw';
  }
  final u = Uri.tryParse(raw);
  if (u == null || u.host.isEmpty) return null;
  final host = u.host.toLowerCase().replaceFirst(RegExp(r'^(www\.|m\.)'), '');
  String? ok(String? id) =>
      id != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id) ? id : null;
  final seg = u.pathSegments;
  if (host == 'youtu.be') return ok(seg.isEmpty ? null : seg.first);
  if (host == 'youtube.com' || host == 'youtube-nocookie.com') {
    if (u.path == '/watch') return ok(u.queryParameters['v']);
    if (seg.length >= 2 &&
        const {'embed', 'shorts', 'live', 'v'}.contains(seg.first)) {
      return ok(seg[1]);
    }
  }
  return null;
}

/// YouTube'un verdiği kapak resmi.
String youtubeThumbnail(String videoId) =>
    'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

/// Videoyu tarayıcıda/YouTube uygulamasında açan adres.
String youtubeWatchUrl(String videoId) =>
    'https://www.youtube.com/watch?v=$videoId';
