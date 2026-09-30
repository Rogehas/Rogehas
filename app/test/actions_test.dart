import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tavas/data/content_logic.dart';
import 'package:tavas/data/content_repository.dart';
import 'package:tavas/data/mock_data.dart';
import 'package:tavas/data/models.dart';
import 'package:tavas/main.dart';
import 'package:tavas/notifications/notification_settings.dart';
import 'package:tavas/screens/home_screen.dart';
import 'package:tavas/screens/vefat_screen.dart';
import 'package:tavas/widgets/common.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<InMemoryNoticeSettings> pumpApp(
    WidgetTester tester, {
    InMemoryNoticeSettings? settings,
  }) async {
    bigScreen(tester);
    final s = settings ?? InMemoryNoticeSettings();
    await tester.pumpWidget(
      TavasApp(repository: MockContentRepository(), notifications: s),
    );
    await tester.tap(find.text('Başla'));
    await tester.pumpAndSettle();
    return s;
  }

  /// Sayfayı tek başına, sahte açıcı/paylaşıcıyla kurar.
  Future<void> pumpPage(
    WidgetTester tester,
    Widget page, {
    InMemoryNoticeSettings? settings,
  }) async {
    bigScreen(tester);
    final hub = ContentHub(MockContentRepository());
    addTearDown(hub.dispose);
    await tester.pumpWidget(
      ContentScope(
        hub: hub,
        child: NotificationScope(
          settings: settings ?? InMemoryNoticeSettings(),
          child: MaterialApp(home: Scaffold(body: page)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('giriş ekranı', () {
    testWidgets('çalışmayan Google/Apple düğmeleri yok', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(
        TavasApp(
          repository: MockContentRepository(),
          notifications: InMemoryNoticeSettings(),
        ),
      );
      expect(find.textContaining('Google'), findsNothing);
      expect(find.textContaining('Apple'), findsNothing);
      expect(find.text('Başla'), findsOneWidget);
    });
  });

  group('haber detayı ve arama', () {
    testWidgets('habere dokununca metin açılır', (tester) async {
      await pumpApp(tester);
      await tester.tap(
        find.text("Tavas'ta sonbahar etkinlik takvimi açıklandı"),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Sonbahar boyunca çeşitli etkinlikler'),
        findsOneWidget,
      );
      expect(find.text('Paylaş'), findsOneWidget);
    });

    testWidgets('metni olmayan haberde açıklama yazar', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.bySemanticsLabel('Haberler'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Başvuru tarihleri uzatıldı'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ek açıklama girilmemiş'), findsOneWidget);
    });

    testWidgets('haber sekmesinde arama başlıkta ve metinde çalışır', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.bySemanticsLabel('Haberler'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(RoundIconButton, Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'SU KESINTISI',
      ); // büyük harf ve "İ" yerine "I"
      await tester.pumpAndSettle();
      expect(
        find.text('Yarın 09:00–14:00 arası planlı su kesintisi'),
        findsOneWidget,
      );
      expect(find.text('Başvuru tarihleri uzatıldı'), findsNothing);

      await tester.enterText(find.byType(TextField), 'var olmayan kelime');
      await tester.pumpAndSettle();
      expect(find.text('Aramanla eşleşen haber yok.'), findsOneWidget);

      await tester.tap(find.widgetWithIcon(RoundIconButton, Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Başvuru tarihleri uzatıldı'), findsOneWidget);
    });

    test('Türkçe harf farkı aramayı bozmaz', () {
      expect(foldTr('ÇAĞRI Şölen İğne ıslak'), 'cagri solen igne islak');
      const items = [
        NewsItem(
          kind: NewsKind.haber,
          title: 'Şenlik Başlıyor',
          meta: '',
          palette: ScenePalette.day,
          body: 'Çarşıda konser var',
        ),
      ];
      expect(searchNews(items, 'senlik'), hasLength(1));
      expect(searchNews(items, 'CARSIDA'), hasLength(1));
      expect(searchNews(items, 'yok'), isEmpty);
      expect(searchNews(items, '  '), hasLength(1));
    });
  });

  group('vefat düğmeleri', () {
    testWidgets('Yol tarifi taziye adresini açar, Paylaş metni gönderir', (
      tester,
    ) async {
      final opened = <Uri>[];
      final shared = <String>[];
      await pumpPage(
        tester,
        VefatScreen(
          opener: (u) async {
            opened.add(u);
            return true;
          },
          share: (t) async => shared.add(t),
        ),
      );

      // Yalnızca taziye adresi olan ilanda Yol tarifi düğmesi var.
      expect(find.text('Yol tarifi'), findsOneWidget);
      expect(find.text('Taziye yeri'), findsOneWidget);
      await tester.tap(find.text('Yol tarifi'));
      await tester.pump();
      expect(
        opened.single.queryParameters['destination'],
        'Merkez Mah. Atatürk Cd. No:4 Tavas Denizli',
      );

      await tester.tap(find.text('Paylaş').first);
      await tester.pump();
      expect(shared.single, contains('Vefat: Ayşe Örnek (78)'));
      expect(
        shared.single,
        contains('Taziye yeri: Merkez Mah. Atatürk Cd. No:4'),
      );
      expect(shared.single, contains('Tavas uygulaması'));
    });

    testWidgets('taziye adresi yoksa Yol tarifi düğmesi gösterilmez', (
      tester,
    ) async {
      await pumpPage(tester, const VefatScreen());
      // İki ilan var, yalnızca biri taziye adresli; iki Paylaş, bir Yol tarifi.
      expect(find.text('Paylaş'), findsNWidgets(2));
      expect(find.text('Yol tarifi'), findsOneWidget);
    });

    test('paylaşım metni boş alanları atlar', () {
      const v = VefatItem(
        name: 'A B',
        age: 0,
        neighborhood: '',
        prayerTime: '',
        mosque: '',
        burial: '',
        ago: '',
      );
      final t = vefatShareText(v);
      expect(t, contains('Vefat: A B'));
      expect(t, isNot(contains('(0)')));
      expect(t, isNot(contains('Cenaze namazı')));
      expect(t, isNot(contains('Taziye')));
    });
  });

  group('ana sayfa kısayolları', () {
    testWidgets('Kesintiler ve Duyurular haberleri süzerek açar', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.ensureVisible(find.text('Kesintiler'));
      await tester.tap(find.text('Kesintiler'));
      await tester.pumpAndSettle();
      expect(find.text('KESİNTİ · SU'), findsOneWidget);
      expect(find.text('Başvuru tarihleri uzatıldı'), findsNothing);

      await tester.tap(find.bySemanticsLabel('Ana Sayfa'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Duyurular'));
      await tester.tap(find.text('Duyurular'));
      await tester.pumpAndSettle();
      expect(find.text('Başvuru tarihleri uzatıldı'), findsOneWidget);
      expect(find.text('KESİNTİ · SU'), findsNothing);
    });

    testWidgets('Harita Tavas konumunu açar', (tester) async {
      final opened = <Uri>[];
      await pumpPage(
        tester,
        Scaffold(
          body: HomeScreen(
            onOpenTab: (_) {},
            onOpenNews: (_) {},
            opener: (u) async {
              opened.add(u);
              return true;
            },
          ),
        ),
      );
      await tester.ensureVisible(find.text('Harita'));
      await tester.tap(find.text('Harita'));
      await tester.pump();
      expect(opened.single, tavasMapUri);
      expect(tavasMapUri.queryParameters['query'], 'Tavas, Denizli');
    });

    testWidgets('Bildirimler kısayolu ve zil aynı tercih penceresini açar', (
      tester,
    ) async {
      final s = await pumpApp(tester);
      await tester.ensureVisible(find.text('Bildirimler'));
      await tester.tap(find.text('Bildirimler'));
      await tester.pumpAndSettle();
      for (final label in NoticeTopics.labels.values) {
        expect(find.text(label), findsWidgets, reason: label);
      }
      // Haber konusu artık seçilebilir ve varsayılan açık.
      expect(s.isEnabled(NoticeTopics.haber), isTrue);
      await tester.tap(find.byType(Switch).at(1)); // Haberler
      await tester.pumpAndSettle();
      expect(s.isEnabled(NoticeTopics.haber), isFalse);

      await tester.tapAt(const Offset(10, 10)); // pencereyi kapat
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithIcon(RoundIconButton, Icons.notifications_none),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Hangi konularda telefonuna bildirim gelsin?'),
        findsOneWidget,
      );
    });
  });

  group('profil sekmesi', () {
    testWidgets('boş değil: misafir kartı ve dört bildirim anahtarı', (
      tester,
    ) async {
      await pumpApp(tester);
      await tester.tap(find.bySemanticsLabel('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Misafir'), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(4));
      expect(find.textContaining('sonraki fazda'), findsNothing);
    });

    testWidgets('izin yoksa açılmaz ve neden yazar', (tester) async {
      await pumpApp(
        tester,
        settings: InMemoryNoticeSettings(grantPermission: false),
      );
      await tester.tap(find.bySemanticsLabel('Profil'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first); // vefat: kapat
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first); // tekrar aç: izin yok
      await tester.pumpAndSettle();
      expect(find.textContaining('Bildirim izni kapalı'), findsOneWidget);
    });
  });

  group('bildirime dokunma', () {
    testWidgets('vefat bildirimi Vefat sekmesini açar', (tester) async {
      final s = await pumpApp(tester);
      s.simulateOpened(
        const NoticeMessage(topic: 'vefat', title: 'Vefat · X', body: ''),
      );
      await tester.pumpAndSettle();
      expect(find.text('Vefat bildirimleri açık'), findsOneWidget);
    });

    testWidgets('kesinti bildirimi haberleri kesintiye süzerek açar', (
      tester,
    ) async {
      final s = await pumpApp(tester);
      s.simulateOpened(
        const NoticeMessage(topic: 'kesinti', title: 'Kesinti · SU', body: ''),
      );
      await tester.pumpAndSettle();
      expect(find.text('KESİNTİ · SU'), findsOneWidget);
      expect(find.text('Başvuru tarihleri uzatıldı'), findsNothing);
    });
  });

  group('bildirim tercihleri', () {
    test('haber artık varsayılan açık; eski kurulum haberi alır', () {
      expect(NoticeTopics.defaultOn, contains(NoticeTopics.haber));
      // Eski şema: haber hiç seçilemediği için kapalıydı.
      final old = {
        'vefat': true,
        'haber': false,
        'duyuru': true,
        'kesinti': true,
      };
      expect(migrateTopicPrefs(old, 1)['haber'], isTrue);
      expect(migrateTopicPrefs(old, 1)['vefat'], isTrue);
    });

    test('izin hiç verilmemişse (hepsi kapalı) haber de açılmaz', () {
      final denied = {for (final t in NoticeTopics.all) t: false};
      expect(migrateTopicPrefs(denied, 1)['haber'], isFalse);
    });

    test('yeni şemada tercihlere dokunulmaz (kullanıcı haberi kapattıysa kapalı kalır)', () {
      final choice = {
        'vefat': true,
        'haber': false,
        'duyuru': true,
        'kesinti': true,
      };
      expect(migrateTopicPrefs(choice, noticePrefsSchema)['haber'], isFalse);
    });
  });
}
