import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tavas/data/content_mapper.dart';
import 'package:tavas/data/models.dart';
import 'package:tavas/data/youtube.dart';
import 'package:tavas/screens/news_detail_screen.dart';
import 'package:tavas/widgets/news_video.dart';
import 'package:tavas/widgets/news_visual.dart';

const id = 'dQw4w9WgXcQ';

void main() {
  group('youtubeVideoId', () {
    test('yaygın link biçimlerini tanır', () {
      for (final u in [
        'https://www.youtube.com/watch?v=$id',
        'https://youtube.com/watch?v=$id&t=30s',
        'https://m.youtube.com/watch?feature=share&v=$id',
        'https://youtu.be/$id?si=abc',
        'https://www.youtube.com/embed/$id',
        'https://www.youtube.com/shorts/$id',
        'https://www.youtube.com/live/$id?feature=share',
        'youtu.be/$id',
        '  https://youtu.be/$id  ',
      ]) {
        expect(youtubeVideoId(u), id, reason: u);
      }
    });

    test('geçersiz veya başka siteye ait linkleri reddeder', () {
      for (final u in [
        '',
        '   ',
        'merhaba',
        'https://vimeo.com/123456789',
        'https://youtube.com/watch?v=kisa',
        'https://evil.com/watch?v=$id',
        'https://youtube.com.evil.com/watch?v=$id',
        'https://youtube.com/',
      ]) {
        expect(youtubeVideoId(u), isNull, reason: u);
      }
      expect(youtubeVideoId(null), isNull);
      expect(youtubeVideoId(42), isNull);
    });
  });

  group('haber eşlemesi', () {
    test('videolu haberde kapak resmi YouTube kapağı olur', () {
      final n = ContentMapper.news({
        'title': 'Canlı yayın',
        'kind': 'haber',
        'youtubeUrl': 'https://youtu.be/$id',
      });
      expect(n.videoId, id);
      expect(n.photoUrl, youtubeThumbnail(id));
    });

    test('görsel seçilmişse onu korur, videoyu da tutar', () {
      final n = ContentMapper.news({
        'title': 'Haber',
        'kind': 'haber',
        'photo': 'data:image/jpeg;base64,AAAA',
        'youtubeUrl': 'https://youtu.be/$id',
      });
      expect(n.photoUrl, startsWith('data:image'));
      expect(n.videoId, id);
    });

    test('video yoksa ya da link bozuksa video alanı boştur', () {
      expect(
        ContentMapper.news({'title': 'a', 'kind': 'haber'}).videoId,
        isNull,
      );
      expect(
        ContentMapper.news({
          'title': 'a',
          'kind': 'haber',
          'youtubeUrl': 'bozuk',
        }).videoId,
        isNull,
      );
    });
  });

  group('haber ayrıntısı', () {
    const video = NewsItem(
      kind: NewsKind.haber,
      title: 'Canlı yayın',
      meta: '',
      palette: ScenePalette.day,
      videoId: id,
    );

    setUp(() => videoPlayerBuilder = (c, v) => Text('OYNATICI:$v'));
    tearDown(() => videoPlayerBuilder = (c, v) => const SizedBox());

    testWidgets('kapakta oynat simgesi var; dokununca video açılır', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: NewsDetailScreen(video)),
      );
      expect(find.byType(PlayBadge), findsOneWidget);
      expect(find.textContaining('OYNATICI'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Videoyu oynat'));
      await tester.pumpAndSettle();
      expect(find.text('OYNATICI:$id'), findsOneWidget);
    });

    testWidgets("YouTube'da aç düğmesi doğru adresi açar", (tester) async {
      Uri? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: NewsDetailScreen(
            video,
            opener: (u) async {
              opened = u;
              return true;
            },
          ),
        ),
      );
      await tester.tap(find.text("YouTube'da aç"));
      await tester.pump();
      expect(opened.toString(), 'https://www.youtube.com/watch?v=$id');
    });

    testWidgets('videosuz haberde oynat simgesi ve YouTube düğmesi yoktur', (
      tester,
    ) async {
      const plain = NewsItem(
        kind: NewsKind.haber,
        title: 'Düz haber',
        meta: '',
        palette: ScenePalette.day,
      );
      await tester.pumpWidget(
        const MaterialApp(home: NewsDetailScreen(plain)),
      );
      expect(find.byType(PlayBadge), findsNothing);
      expect(find.text("YouTube'da aç"), findsNothing);
    });
  });
}
