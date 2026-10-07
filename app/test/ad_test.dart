import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tavas/ads/ad_controller.dart';
import 'package:tavas/ads/ad_models.dart';
import 'package:tavas/ads/ad_repository.dart';
import 'package:tavas/ads/ad_widgets.dart';
import 'package:tavas/data/hero_slides.dart';
import 'package:tavas/data/mock_data.dart';
import 'package:tavas/data/models.dart';
import 'package:tavas/main.dart';
import 'package:tavas/notifications/notification_settings.dart';

AdItem ad(
  String id, {
  Set<AdPlacement> placements = const {AdPlacement.home},
  AdAction action = AdAction.call,
  String value = '0258 614 00 00',
  DateTime? start,
  DateTime? end,
  bool active = true,
  int created = 0,
}) => AdItem(
  id: id,
  name: 'Esnaf $id',
  text: 'Metin $id',
  action: action,
  actionValue: value,
  placements: placements,
  start: start,
  end: end,
  active: active,
  createdAt: DateTime(2026, 10, 1, 10, created),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  final now = DateTime(2026, 10, 10, 15);

  group('eligibleAds / pickAd', () {
    test('genel anahtar kapalıysa hiçbir reklam çıkmaz', () {
      final s = AdsState(enabled: false, ads: [ad('a')]);
      expect(eligibleAds(s, AdPlacement.home, now), isEmpty);
    });

    test('kapalı, başka yerdeki ve bozuk adresli reklamlar dışarıda kalır', () {
      final s = AdsState(
        ads: [
          ad('acik'),
          ad('kapali', active: false),
          ad('baska', placements: {AdPlacement.nav}),
          ad('bozuk', value: '   '),
          ad('web', action: AdAction.web, value: 'x'),
        ],
      );
      expect(eligibleAds(s, AdPlacement.home, now).map((a) => a.id), [
        'acik',
        'web',
      ]);
    });

    test(
      'tarih aralığı: başlamamış ve süresi dolmuş çıkmaz, sınır günleri dahil',
      () {
        final s = AdsState(
          ads: [
            ad('gelecek', start: DateTime(2026, 10, 11)),
            ad('gecmis', end: DateTime(2026, 10, 9)),
            ad('bugunBaslar', start: DateTime(2026, 10, 10)),
            ad('bugunBiter', end: DateTime(2026, 10, 10)),
            ad('suresiz'),
          ],
        );
        expect(eligibleAds(s, AdPlacement.home, now).map((a) => a.id).toSet(), {
          'bugunBaslar',
          'bugunBiter',
          'suresiz',
        });
      },
    );

    test('bir yerde en fazla 3 reklam, eskiden yeniye sıralı', () {
      final s = AdsState(
        ads: [for (var i = 5; i >= 1; i--) ad('r$i', created: i)],
      );
      expect(eligibleAds(s, AdPlacement.home, now).map((a) => a.id), [
        'r1',
        'r2',
        'r3',
      ]);
    });

    test('her açılışta sıradaki reklam seçilir ve başa döner', () {
      final list = [ad('a'), ad('b', created: 1), ad('c', created: 2)];
      expect(
        [for (var i = 0; i < 7; i++) pickAd(list, i)!.id],
        [
          'a', 'b', 'c', 'a', 'b', 'c', 'a', //
        ],
      );
      expect(pickAd(const [], 3), isNull);
    });
  });

  group('adUri ve eşleme', () {
    test('eyleme göre adres üretir', () {
      expect(ad('a').uri.toString(), 'tel:02586140000');
      expect(
        ad('a', action: AdAction.web, value: 'tavasfirini.com').uri.toString(),
        'https://tavasfirini.com',
      );
      expect(
        ad(
          'a',
          action: AdAction.map,
          value: 'Cumhuriyet Cd. 3, Tavas',
        ).uri?.host,
        'www.google.com',
      );
      expect(ad('a', value: '').uri, isNull);
    });

    test('panel belgesini okur; bozuk belgeyi atar', () {
      final a = adFromMap('x', {
        'name': 'Fırın',
        'text': 'Simit',
        'action': 'call',
        'actionValue': '0258',
        'placements': ['home', 'nav', 'bilinmeyen'],
        'active': true,
        'startDate': '2026-10-01',
        'endDate': '',
        'photo': null,
        'createdAt': '2026-10-01T10:00:00.000Z',
      });
      expect(a, isNotNull);
      expect(a!.placements, {AdPlacement.home, AdPlacement.nav});
      expect(a.start, DateTime(2026, 10, 1));
      expect(a.end, isNull);
      expect(adFromMap('y', {'name': '', 'action': 'call'}), isNull);
      expect(adFromMap('z', {'name': 'A', 'action': 'sms'}), isNull);
    });
  });

  group('kayan haberler', () {
    final n = [
      for (var i = 0; i < 4; i++)
        NewsItem(
          id: 'n$i',
          kind: NewsKind.haber,
          title: 'Haber $i',
          meta: '',
          palette: ScenePalette.day,
          publishedAt: DateTime(2026, 10, 1, 10 - i),
        ),
    ];

    test(
      'reklam içerikten sonra 3. sıraya girer, içerik sayısını azaltmaz',
      () {
        final s = buildHeroSlides(n, const [], ad: ad('a'));
        expect(s.length, 5);
        expect(s[2].ad?.id, 'a');
        expect(s.where((x) => x.news != null).length, 4);
      },
    );

    test('az içerik varsa reklam sona girer; reklam yoksa değişiklik yok', () {
      expect(
        buildHeroSlides(n.take(1).toList(), const [], ad: ad('a'))[1].ad,
        isNotNull,
      );
      expect(buildHeroSlides(const [], const [], ad: ad('a')), isEmpty);
      expect(buildHeroSlides(n, const []).any((x) => x.ad != null), isFalse);
    });
  });

  group('reklam alanı (AdSlot)', () {
    Future<void> pumpSlot(
      WidgetTester tester,
      AdController c, {
      AdPlacement placement = AdPlacement.home,
      bool closable = false,
    }) => tester.pumpWidget(
      AdScope(
        controller: c,
        child: MaterialApp(
          home: Scaffold(
            body: AdSlot(placement: placement, closable: closable),
          ),
        ),
      ),
    );

    testWidgets('reklam yoksa hiçbir şey çizilmez', (tester) async {
      final repo = InMemoryAdRepository();
      await pumpSlot(tester, AdController(repo, clock: () => now));
      await tester.pump();
      expect(find.text('SPONSOR'), findsNothing);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets(
      'reklam görünür; gösterim bir kez, tıklama her dokunuşta sayılır',
      (tester) async {
        final repo = InMemoryAdRepository(AdsState(ads: [ad('a')]));
        Uri? opened;
        final c = AdController(
          repo,
          clock: () => now,
          opener: (u) async {
            opened = u;
            return true;
          },
        );
        await pumpSlot(tester, c);
        await tester.pump();
        expect(find.text('Esnaf a'), findsOneWidget);
        expect(find.text('SPONSOR'), findsOneWidget);
        expect(find.text('Ara ›'), findsOneWidget);
        expect(repo.recorded, [('a', false)]);

        // Yeniden çizim gösterimi tekrar saymaz.
        await pumpSlot(tester, c);
        await tester.pump();
        expect(repo.recorded.where((e) => !e.$2).length, 1);

        await tester.tap(find.text('Esnaf a'));
        await tester.pump();
        expect(opened.toString(), 'tel:02586140000');
        expect(repo.recorded.last, ('a', true));
      },
    );

    testWidgets('genel anahtar kapanınca reklam anında kalkar', (tester) async {
      final repo = InMemoryAdRepository(AdsState(ads: [ad('a')]));
      final c = AdController(repo, clock: () => now);
      await pumpSlot(tester, c);
      await tester.pump();
      expect(find.text('Esnaf a'), findsOneWidget);
      repo.setState(AdsState(enabled: false, ads: [ad('a')]));
      await tester.pump();
      await tester.pump();
      expect(find.text('Esnaf a'), findsNothing);
    });

    testWidgets('açılış sayısına göre farklı reklam çıkar', (tester) async {
      final repo = InMemoryAdRepository(
        AdsState(ads: [ad('a'), ad('b', created: 1)]),
      );
      await pumpSlot(tester, AdController(repo, launch: 0, clock: () => now));
      await tester.pump();
      expect(find.text('Esnaf a'), findsOneWidget);
      await pumpSlot(tester, AdController(repo, launch: 1, clock: () => now));
      await tester.pump();
      expect(find.text('Esnaf b'), findsOneWidget);
    });

    testWidgets('şerit kapatılınca o yerde bir daha çıkmaz', (tester) async {
      final repo = InMemoryAdRepository(
        AdsState(
          ads: [
            ad('a', placements: {AdPlacement.nav}),
          ],
        ),
      );
      final c = AdController(repo, clock: () => now);
      await pumpSlot(tester, c, placement: AdPlacement.nav, closable: true);
      await tester.pump();
      expect(find.text('Esnaf a'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(find.text('Esnaf a'), findsNothing);
    });
  });

  group('uygulama içinde', () {
    Future<void> pumpApp(WidgetTester tester, InMemoryAdRepository repo) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TavasApp(
          repository: MockContentRepository(),
          notifications: InMemoryNoticeSettings(),
          ads: repo,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'ana sayfa şeridi ve alt menü şeridi görünür; reklam yokken hiçbiri yok',
      (tester) async {
        final repo = InMemoryAdRepository(
          AdsState(
            ads: [
              ad('h', placements: {AdPlacement.home}),
              ad('n', placements: {AdPlacement.nav}),
            ],
          ),
        );
        await pumpApp(tester, repo);
        expect(find.text('Esnaf h'), findsOneWidget);
        expect(find.text('Esnaf n'), findsOneWidget);
        repo.setState(const AdsState());
        await tester.pumpAndSettle();
        expect(find.text('SPONSOR'), findsNothing);
      },
    );

    testWidgets('vefat sekmesinde reklam çıkmaz', (tester) async {
      final repo = InMemoryAdRepository(
        AdsState(
          ads: [
            ad('n', placements: {AdPlacement.nav}),
          ],
        ),
      );
      await pumpApp(tester, repo);
      expect(find.text('Esnaf n'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Vefat'));
      await tester.pumpAndSettle();
      expect(find.text('Esnaf n'), findsNothing);
    });
  });
}
