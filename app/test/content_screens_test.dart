import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tavas/data/content_logic.dart';
import 'package:tavas/data/content_mapper.dart';
import 'package:tavas/data/content_repository.dart';
import 'package:tavas/data/links.dart';
import 'package:tavas/data/mock_data.dart';
import 'package:tavas/data/models.dart';
import 'package:tavas/screens/business_screen.dart';
import 'package:tavas/screens/events_screen.dart';
import 'package:tavas/screens/guide_screen.dart';

EventItem ev(String id, DateTime d, {DateTime? end, String time = ''}) =>
    EventItem(
      id: id,
      title: id,
      date: d,
      endDate: end,
      time: time,
      place: 'Yer',
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  final now = DateTime(2026, 9, 30, 15);

  group('etkinlik mantığı', () {
    test('geçmiş elenir, çok günlü devam eden kalır, tarih ve saate göre sıralanır', () {
      final list = upcomingEvents([
        ev('gecmis', DateTime(2026, 9, 29)),
        ev('bugun-gec', DateTime(2026, 9, 30), time: '20:00'),
        ev('bugun-erken', DateTime(2026, 9, 30), time: '09:00'),
        ev('suruyor', DateTime(2026, 9, 28), end: DateTime(2026, 10, 2)),
        ev('ileri', DateTime(2026, 10, 10)),
      ], now);
      expect(list.map((e) => e.title), [
        'suruyor',
        'bugun-erken',
        'bugun-gec',
        'ileri',
      ]);
    });

    test('rozet ve zaman etiketleri', () {
      final e = ev('x', DateTime(2026, 10, 4));
      expect(eventBadge(e).day, '04');
      expect(eventBadge(e).month, 'EKİ');
      expect(eventWhenLabel(ev('a', DateTime(2026, 9, 30)), now), 'Bugün');
      expect(eventWhenLabel(ev('a', DateTime(2026, 10, 1)), now), 'Yarın');
      expect(eventWhenLabel(e, now), '4 Ekim');
      expect(
        eventWhenLabel(
          ev('a', DateTime(2026, 10, 4), end: DateTime(2026, 10, 6)),
          now,
        ),
        '4–6 Ekim',
      );
      expect(
        eventWhenLabel(
          ev('a', DateTime(2026, 10, 30), end: DateTime(2026, 11, 2)),
          now,
        ),
        '30 Ekim – 2 Kasım',
      );
      expect(
        eventWhenLabel(
          ev('a', DateTime(2026, 9, 28), end: DateTime(2026, 10, 2)),
          now,
        ),
        'Devam ediyor',
      );
    });
  });

  group('rehber ve esnaf mantığı', () {
    test('rehber: Acil önce, kategori içinde sıraya göre', () {
      final g = groupGuide(const [
        GuideEntry(
          id: '1',
          name: 'B',
          category: 'Belediye',
          phone: '1',
          order: 2,
        ),
        GuideEntry(
          id: '2',
          name: 'A',
          category: 'Belediye',
          phone: '1',
          order: 1,
        ),
        GuideEntry(id: '3', name: 'Y', category: 'Acil', phone: '112'),
        GuideEntry(id: '4', name: 'Z', category: '', phone: '1'),
      ]);
      expect(g.map((e) => e.key), ['Acil', 'Belediye', 'Diğer']);
      expect(g[1].value.map((e) => e.name), ['A', 'B']);
    });

    test('esnaf: kategori listesi ve süzme', () {
      const all = [
        Business(id: '1', name: 'B', category: 'Kafe'),
        Business(id: '2', name: 'A', category: 'Restoran'),
        Business(id: '3', name: 'C', category: 'Restoran'),
      ];
      expect(businessCategories(all), ['Restoran', 'Kafe']);
      expect(filterBusinesses(all, null).map((b) => b.name), ['A', 'B', 'C']);
      expect(filterBusinesses(all, 'Restoran').map((b) => b.name), ['A', 'C']);
    });

    test('telefon gösterimi ve harita bağlantısı', () {
      expect(prettyPhone('02586140000'), '0258 614 00 00');
      expect(prettyPhone('4441444'), '444 1 444');
      expect(prettyPhone('112'), '112');
      expect(
        mapsLink(
          lat: 37.5,
          lng: 29.1,
          query: 'x',
        ).queryParameters['destination'],
        '37.5,29.1',
      );
      expect(
        mapsLink(query: ' Lokanta Tavas ').queryParameters['destination'],
        'Lokanta Tavas',
      );
    });
  });

  group('eşleme', () {
    test('etkinlik: gizli, adsız ve geçersiz tarihli kayıtlar atlanır', () {
      const ok = {'title': ' Pazar ', 'date': '2026-10-04', 'place': ' Alan '};
      final e = ContentMapper.event('e1', ok)!;
      expect(e.title, 'Pazar');
      expect(e.place, 'Alan');
      expect(ContentMapper.event('e', {...ok, 'published': false}), isNull);
      expect(ContentMapper.event('e', {...ok, 'title': ' '}), isNull);
      expect(ContentMapper.event('e', {...ok, 'date': '2026-02-31'}), isNull);
      expect(ContentMapper.event('e', {...ok, 'date': 'yarın'}), isNull);
    });

    test('etkinlik: bitiş başlangıçtan önceyse yok sayılır', () {
      final e = ContentMapper.event('e', {
        'title': 'X',
        'date': '2026-10-04',
        'endDate': '2026-10-01',
      })!;
      expect(e.endDate, isNull);
    });

    test('rehber: telefonsuz kayıt atlanır, telefon rakama çevrilir', () {
      expect(ContentMapper.guide('g', {'name': 'A', 'phone': ''}), isNull);
      final g = ContentMapper.guide('g', {
        'name': 'Belediye',
        'phone': '0258 614-00-00',
        'order': 3,
      })!;
      expect(g.phone, '02586140000');
      expect(g.order, 3);
    });

    test('esnaf: telefon isteğe bağlı, koordinat okunur', () {
      final b = ContentMapper.business('b', {
        'name': 'Lokanta',
        'category': 'Restoran',
        'lat': 37,
        'lng': 29.5,
      })!;
      expect(b.phone, '');
      expect(b.lat, 37.0);
      expect(
        ContentMapper.business('b', {'name': 'X', 'published': false}),
        isNull,
      );
    });
  });

  group('ekranlar', () {
    Future<List<Uri>> pump(
      WidgetTester tester,
      Widget Function(UrlOpenerFn open) home, {
      ContentRepository? repo,
    }) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final opened = <Uri>[];
      final hub = ContentHub(repo ?? MockContentRepository());
      addTearDown(hub.dispose);
      await tester.pumpWidget(
        ContentScope(
          hub: hub,
          child: MaterialApp(
            home: home((u) async {
              opened.add(u);
              return true;
            }),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets('etkinlikler listelenir ve dokununca ayrıntı açılır', (
      tester,
    ) async {
      await pump(tester, (_) => const EventsScreen());
      expect(find.text('Yerel Ürünler Pazarı'), findsOneWidget);
      expect(find.text('Sonbahar Şenliği'), findsOneWidget);
      await tester.tap(find.text('Yerel Ürünler Pazarı'));
      await tester.pumpAndSettle();
      expect(find.text('Üreticiler ürünlerini tanıtıyor.'), findsOneWidget);
    });

    testWidgets('etkinlik yoksa boş durum mesajı çıkar', (tester) async {
      await pump(tester, (_) => const EventsScreen(), repo: _Empty());
      expect(
        find.textContaining('planlanmış bir etkinlik yok'),
        findsOneWidget,
      );
    });

    testWidgets('rehber gruplu gösterilir; ara düğmesi telefonu açar', (
      tester,
    ) async {
      final opened = await pump(tester, (o) => GuideScreen(opener: o));
      expect(find.text('Acil'), findsOneWidget);
      expect(find.text('Belediye'), findsOneWidget);
      expect(find.text('0258 614 00 00'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Acil Yardım ara'));
      await tester.pump();
      expect(opened.last.toString(), 'tel:112');
    });

    testWidgets('esnaf: kategori süzme, ara ve yol tarifi', (tester) async {
      final opened = await pump(tester, (o) => BusinessScreen(opener: o));
      expect(find.text('Lezzet Lokantası'), findsOneWidget);
      expect(find.text('Çarşı Kafe'), findsOneWidget);

      await tester.tap(find.text('Kafe').first);
      await tester.pumpAndSettle();
      expect(find.text('Lezzet Lokantası'), findsNothing);
      expect(find.text('Çarşı Kafe'), findsOneWidget);

      await tester.tap(find.text('Tümü'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ara').first);
      await tester.pump();
      expect(opened.last.toString(), startsWith('tel:'));
      await tester.tap(find.text('Yol tarifi').first);
      await tester.pump();
      expect(opened.last.host, 'www.google.com');
    });

    testWidgets('telefonsuz işletmede Ara düğmesi yok', (tester) async {
      await pump(tester, (_) => const BusinessScreen(), repo: _OnlyNoPhone());
      expect(find.text('Ara'), findsNothing);
      expect(find.text('Yol tarifi'), findsOneWidget);
    });

    testWidgets('veri yüklenemezse hata mesajı, sahte kayıt yok', (
      tester,
    ) async {
      await pump(
        tester,
        (_) => const BusinessScreen(),
        repo: UnavailableContentRepository(StateError('yok')),
      );
      expect(find.textContaining('İçerik yüklenemedi'), findsOneWidget);
      expect(find.text('Lezzet Lokantası'), findsNothing);
    });
  });
}

typedef UrlOpenerFn = Future<bool> Function(Uri uri);

class _Empty extends MockContentRepository {
  @override
  Stream<List<EventItem>> watchEvents() => Stream.value(const <EventItem>[]);
}

class _OnlyNoPhone extends MockContentRepository {
  @override
  Stream<List<Business>> watchBusinesses() => Stream.value(const [
    Business(id: 'x', name: 'Telefonsuz', category: 'Hizmet', address: 'Çarşı'),
  ]);
}
