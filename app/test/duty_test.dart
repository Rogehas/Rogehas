import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tavas/data/content_mapper.dart';
import 'package:tavas/data/content_repository.dart';
import 'package:tavas/data/duty_logic.dart';
import 'package:tavas/data/mock_data.dart';
import 'package:tavas/data/models.dart';
import 'package:tavas/screens/eczane_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('nöbet günü', () {
    test('sabah 09:00\'dan önce hâlâ dünün nöbeti sürer', () {
      expect(
        dutyDateKey(currentDutyDay(DateTime(2026, 10, 1, 8, 59))),
        '2026-09-30',
      );
      expect(
        dutyDateKey(currentDutyDay(DateTime(2026, 10, 1, 9, 0))),
        '2026-10-01',
      );
      expect(
        dutyDateKey(currentDutyDay(DateTime(2026, 10, 1, 23, 30))),
        '2026-10-01',
      );
    });

    test(
      'ay ve yıl başında doğru güne gider, sıradaki nöbet ertesi gündür',
      () {
        expect(
          dutyDateKey(currentDutyDay(DateTime(2027, 1, 1, 3))),
          '2026-12-31',
        );
        expect(
          dutyDateKey(dutyDayAt(DateTime(2026, 12, 31, 12), 1)),
          '2027-01-01',
        );
        expect(
          dutyDateKey(dutyDayAt(DateTime(2028, 2, 28, 12), 1)),
          '2028-02-29',
        );
      },
    );

    test('nöbet penceresi etiketi', () {
      expect(
        dutyWindowLabel(DateTime(2026, 9, 30)),
        '30 Eylül 09:00 – 1 Ekim 09:00',
      );
    });
  });

  group('eczane seçimi', () {
    const a = Pharmacy(
      id: 'a',
      name: 'A',
      neighborhood: '',
      address: '',
      phone: '',
    );
    const b = Pharmacy(
      id: 'b',
      name: 'B',
      neighborhood: '',
      address: '',
      phone: '',
    );

    test('yazılan sıra korunur, bilinmeyen kimlik atlanır', () {
      final duty = [
        const DutyDay(date: '2026-09-30', pharmacyIds: ['b', 'yok', 'a']),
      ];
      final r = pharmaciesOnDuty(duty, [a, b], '2026-09-30')!;
      expect(r.map((p) => p.id), ['b', 'a']);
    });

    test('girilmemiş gün null, girilmiş ama boş gün boş liste döner', () {
      final duty = [const DutyDay(date: '2026-09-30', pharmacyIds: [])];
      expect(pharmaciesOnDuty(duty, [a], '2026-10-01'), isNull);
      expect(pharmaciesOnDuty(duty, [a], '2026-09-30'), isEmpty);
    });
  });

  group('eşleme', () {
    test(
      'kapalı eczane ve adsız kayıt gösterilmez, telefon rakama çevrilir',
      () {
        expect(
          ContentMapper.pharmacy('x', {'name': 'A', 'active': false}),
          isNull,
        );
        expect(
          ContentMapper.pharmacy('x', {'name': ' ', 'active': true}),
          isNull,
        );
        final p = ContentMapper.pharmacy('x', {
          'name': ' Örnek ',
          'phone': '0258 614-00-00',
          'lat': 37,
          'lng': 29.5,
          'active': true,
        })!;
        expect(p.name, 'Örnek');
        expect(p.phone, '02586140000');
        expect(p.lat, 37.0);
      },
    );

    test('bozuk nöbet kaydı atlanır', () {
      expect(ContentMapper.duty({'date': 'bugün'}), isNull);
      expect(ContentMapper.duty({'pharmacyIds': []}), isNull);
      final d = ContentMapper.duty({
        'date': '2026-09-30',
        'pharmacyIds': ['a', 5, 'b'],
      })!;
      expect(d.pharmacyIds, ['a', 'b']);
    });
  });

  group('adresler', () {
    test('telefon ve yol tarifi bağlantıları', () {
      expect(telUri('02586140000').toString(), 'tel:02586140000');
      const withCoords = Pharmacy(
        id: 'a',
        name: 'A',
        neighborhood: '',
        address: 'x',
        phone: '',
        lat: 37.57,
        lng: 29.07,
      );
      final u = directionsUri(withCoords);
      expect(u.host, 'www.google.com');
      expect(u.queryParameters['destination'], '37.57,29.07');
      const noCoords = Pharmacy(
        id: 'b',
        name: 'Örnek Eczanesi',
        neighborhood: '',
        address: 'Cumhuriyet Cd. No:1',
        phone: '',
      );
      expect(
        directionsUri(noCoords).queryParameters['destination'],
        'Örnek Eczanesi Cumhuriyet Cd. No:1 Tavas Denizli',
      );
    });

    test('telefon gösterimi', () {
      expect(formatPhone('02586140000'), '0258 614 00 00');
      expect(formatPhone('123'), '123');
    });
  });

  group('eczane ekranı', () {
    Future<List<Uri>> pumpScreen(
      WidgetTester tester, {
      ContentRepository? repo,
      bool openOk = true,
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
            home: EczaneScreen(
              opener: (u) async {
                opened.add(u);
                return openOk;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets('bugünün nöbetçileri listelenir; Ara ve Yol tarifi açılır', (
      tester,
    ) async {
      final opened = await pumpScreen(tester);
      expect(find.text('Örnek Eczanesi'), findsOneWidget);
      expect(find.text('Yeni Eczanesi'), findsOneWidget);
      expect(find.text('0258 614 00 00'), findsOneWidget);

      await tester.tap(find.text('Ara').first);
      await tester.pump();
      expect(opened.last.toString(), 'tel:02586140000');

      await tester.tap(find.text('Yol tarifi').last);
      await tester.pump();
      expect(opened.last.queryParameters['destination'], '37.57,29.07');
    });

    testWidgets('yarın girilmemişse açıklama gösterir', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Yarın'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('nöbet bilgisi henüz girilmedi'),
        findsOneWidget,
      );
      expect(find.text('Örnek Eczanesi'), findsNothing);
    });

    testWidgets('bağlantı açılamazsa uyarı çıkar', (tester) async {
      await pumpScreen(tester, openOk: false);
      await tester.tap(find.text('Ara').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('Açılamadı'), findsOneWidget);
    });

    testWidgets('veri yüklenemezse hata mesajı, sahte eczane yok', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repo: UnavailableContentRepository(StateError('yok')),
      );
      expect(find.textContaining('İçerik yüklenemedi'), findsWidgets);
      expect(find.text('Örnek Eczanesi'), findsNothing);
    });
  });
}
