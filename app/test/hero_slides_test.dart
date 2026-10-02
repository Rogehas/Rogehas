import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tavas/data/content_repository.dart';
import 'package:tavas/data/hero_slides.dart';
import 'package:tavas/data/mock_data.dart';
import 'package:tavas/data/models.dart';
import 'package:tavas/main.dart';
import 'package:tavas/notifications/notification_settings.dart';
import 'package:tavas/widgets/common.dart';

NewsItem _news(String title, DateTime? at) => NewsItem(
  kind: NewsKind.haber,
  title: title,
  meta: '',
  palette: ScenePalette.day,
  publishedAt: at,
);

VefatItem _vefat(String name, DateTime? at) => VefatItem(
  name: name,
  age: 70,
  neighborhood: '',
  prayerTime: '',
  mosque: '',
  burial: '',
  ago: '',
  publishedAt: at,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('kayan slayt listesi', () {
    test(
      'haber ve vefat yayınlanma zamanına göre karışık, yeni üstte sıralanır',
      () {
        final slides = buildHeroSlides(
          [
            _news('eski haber', DateTime(2026, 10, 1)),
            _news('yeni haber', DateTime(2026, 10, 3)),
          ],
          [_vefat('Ayşe Örnek', DateTime(2026, 10, 2))],
        );
        expect(
          [for (final s in slides) s.news?.title ?? 'vefat:${s.vefat!.name}'],
          ['yeni haber', 'vefat:Ayşe Örnek', 'eski haber'],
        );
      },
    );

    test('en fazla 15 slayt gelir; en eskiler dışarıda kalır', () {
      final news = [
        for (var i = 0; i < 12; i++) _news('h$i', DateTime(2026, 9, 1 + i)),
      ];
      final vefat = [
        for (var i = 0; i < 8; i++) _vefat('v$i', DateTime(2026, 9, 20 + i)),
      ];
      final slides = buildHeroSlides(news, vefat);
      expect(slides, hasLength(heroSlideLimit));
      expect(heroSlideLimit, 15);
      // En eski haber (h0) listede olmamalı.
      expect(slides.any((s) => s.news?.title == 'h0'), isFalse);
    });

    test('zamanı olmayanlarda haber vefattan önce gelir', () {
      final slides = buildHeroSlides([_news('h', null)], [_vefat('v', null)]);
      expect(slides.first.news, isNotNull);
      expect(slides.last.vefat, isNotNull);
    });

    test('hiç içerik yoksa liste boştur', () {
      expect(buildHeroSlides(const [], const []), isEmpty);
    });
  });

  group('ana sayfada kayan vefat', () {
    Future<void> pumpApp(WidgetTester tester, ContentRepository repo) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TavasApp(repository: repo, notifications: InMemoryNoticeSettings()),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'vefat slaytı "Vefat: Ad Soyad" yazar; dokununca Vefat sekmesi açılır',
      (tester) async {
        await pumpApp(tester, _OnlyVefat());
        expect(find.text('Vefat: Ayşe Örnek'), findsOneWidget);
        expect(find.text('VEFAT'), findsOneWidget);
        await tester.tap(find.text('Vefat: Ayşe Örnek'));
        await tester.pumpAndSettle();
        expect(find.text('Vefat bildirimleri açık'), findsOneWidget);
      },
    );

    testWidgets('haber ve vefat birlikte kayar', (tester) async {
      await pumpApp(tester, MockContentRepository());
      expect(
        find.text("Tavas'ta sonbahar etkinlik takvimi açıklandı"),
        findsOneWidget,
      );
      // Örnek veride 4 haber + 2 vefat: oklarla vefat slaytına ulaşılır.
      for (var i = 0; i < 4; i++) {
        await tester.tap(
          find.widgetWithIcon(RoundIconButton, Icons.chevron_right),
        );
        await tester.pumpAndSettle();
      }
      expect(find.textContaining('Vefat: '), findsOneWidget);
    });

    testWidgets('haber de vefat da yoksa boş durum yazar', (tester) async {
      await pumpApp(tester, _Nothing());
      expect(find.text('Henüz haber yok.'), findsOneWidget);
    });
  });
}

class _OnlyVefat extends MockContentRepository {
  @override
  Stream<List<NewsItem>> watchNews() => Stream.value(const <NewsItem>[]);
  @override
  Stream<List<VefatItem>> watchVefat() =>
      Stream.value([MockData.vefat().first]);
}

class _Nothing extends MockContentRepository {
  @override
  Stream<List<NewsItem>> watchNews() => Stream.value(const <NewsItem>[]);
  @override
  Stream<List<VefatItem>> watchVefat() => Stream.value(const <VefatItem>[]);
}
