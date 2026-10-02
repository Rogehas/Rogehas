import 'dart:ui' show Offset, Size;

import 'package:flutter/material.dart' show Icons, Switch;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tavas/data/content_repository.dart';
import 'package:tavas/data/mock_data.dart';
import 'package:tavas/data/models.dart';
import 'package:tavas/main.dart';
import 'package:tavas/notifications/notification_settings.dart';
import 'package:tavas/screens/home_screen.dart' show greeting;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('misafir girişi ana sayfayı açar, sekmeler çalışır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      TavasApp(
        repository: MockContentRepository(),
        notifications: InMemoryNoticeSettings(),
      ),
    );
    await tester.pumpAndSettle();
    // Giriş ekranı yok: uygulama doğrudan ana sayfada açılır.
    expect(find.textContaining(', Tavas'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Vefat'));
    await tester.pumpAndSettle();
    expect(find.text('Ayşe Örnek'), findsOneWidget);
    // Bildirim anahtarı artık Vefat sayfasında değil, zilde ve Profil'de.
    expect(find.byType(Switch), findsNothing);

    await tester.tap(find.bySemanticsLabel('Haberler'));
    await tester.pumpAndSettle();
    expect(find.text('Başvuru tarihleri uzatıldı'), findsOneWidget);
    await tester.drag(find.text('Tümü'), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kesinti'));
    await tester.pumpAndSettle();
    expect(find.text('Başvuru tarihleri uzatıldı'), findsNothing);
    expect(find.text('KESİNTİ · SU'), findsOneWidget);
  });

  testWidgets('içerik yüklenemezse sahte veri değil hata mesajı gösterilir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      TavasApp(
        repository: UnavailableContentRepository(StateError('yok')),
        notifications: InMemoryNoticeSettings(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Vefat'));
    await tester.pumpAndSettle();
    expect(find.textContaining('İçerik yüklenemedi'), findsOneWidget);
    expect(find.text('Ayşe Örnek'), findsNothing);
  });

  testWidgets('uygulama açıkken gelen vefat bildirimi ekranda görünür', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final settings = InMemoryNoticeSettings();
    await tester.pumpWidget(
      TavasApp(repository: MockContentRepository(), notifications: settings),
    );
    await tester.pumpAndSettle();

    settings.simulateForeground(
      const NoticeMessage(
        topic: 'vefat',
        title: 'Vefat · Deneme',
        body: 'Cenaze namazı bugün 13:30.',
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Vefat · Deneme'), findsOneWidget);
    expect(find.text('Gör'), findsOneWidget);
  });

  testWidgets('bildirim kurulamadıysa neden Profil sekmesinde yazar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      TavasApp(
        repository: MockContentRepository(),
        notifications: InMemoryNoticeSettings(
          initialProblem: 'Bildirim izni verilmedi.',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Bildirim izni verilmedi.'), findsOneWidget);
  });

  testWidgets(
    'ana sayfada öne çıkan haber var; namaz vakti ve sahte hava yok',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        TavasApp(
          repository: MockContentRepository(),
          notifications: InMemoryNoticeSettings(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text("Tavas'ta sonbahar etkinlik takvimi açıklandı"),
        findsOneWidget,
      );
      expect(find.text('SIRADAKİ VAKİT'), findsNothing);
      expect(find.textContaining('24°'), findsNothing);
    },
  );

  testWidgets('haber yoksa ana sayfada boş durum mesajı çıkar', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      TavasApp(
        repository: _NoNewsRepository(),
        notifications: InMemoryNoticeSettings(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Henüz haber yok.'), findsOneWidget);
  });

  test('selamlama günün saatine göre değişir', () {
    expect(greeting(DateTime(2026, 9, 30, 3)), 'İyi geceler');
    expect(greeting(DateTime(2026, 9, 30, 9)), 'Günaydın');
    expect(greeting(DateTime(2026, 9, 30, 14)), 'İyi günler');
    expect(greeting(DateTime(2026, 9, 30, 20)), 'İyi akşamlar');
  });

  testWidgets('ana sayfadaki Nöbetçi Eczane kısayolu eczane ekranını açar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      TavasApp(
        repository: MockContentRepository(),
        notifications: InMemoryNoticeSettings(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Nöbetçi\nEczane'));
    await tester.tap(find.text('Nöbetçi\nEczane'));
    await tester.pumpAndSettle();
    expect(find.text('Nöbetçi Eczane'), findsOneWidget);
    expect(find.text('Örnek Eczanesi'), findsOneWidget);
  });

  testWidgets(
    'ana sayfa kısayolları etkinlik, rehber ve esnaf ekranlarını açar',
    (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        TavasApp(
          repository: MockContentRepository(),
          notifications: InMemoryNoticeSettings(),
        ),
      );
      await tester.pumpAndSettle();

      for (final (tile, content) in [
        ('Etkinlik', 'Yerel Ürünler Pazarı'),
        ('Rehber', 'Belediye Santral'),
        ('Esnaf', 'Lezzet Lokantası'),
      ]) {
        await tester.ensureVisible(find.text(tile));
        await tester.tap(find.text(tile));
        await tester.pumpAndSettle();
        expect(find.text(content), findsOneWidget, reason: tile);
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
      }
    },
  );
}

class _NoNewsRepository extends MockContentRepository {
  @override
  Stream<List<NewsItem>> watchNews() => Stream.value(const <NewsItem>[]);

  @override
  Stream<List<VefatItem>> watchVefat() => Stream.value(const <VefatItem>[]);
}
