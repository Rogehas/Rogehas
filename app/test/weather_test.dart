import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tavas/data/mock_data.dart';
import 'package:tavas/main.dart';
import 'package:tavas/notifications/notification_settings.dart';
import 'package:tavas/weather/weather.dart';

class _Seq implements WeatherSource {
  _Seq(this.results);
  final List<Weather?> results;
  int calls = 0;
  @override
  Future<Weather?> fetch() async =>
      results[calls++ < results.length ? calls - 1 : results.length - 1];
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('hava durumu güncelliği', () {
    const w1 = Weather(tempC: 13, code: 3, isDay: true);
    const w2 = Weather(tempC: 8, code: 61, isDay: false);

    testWidgets(
      'açılışta çeker; arka plandan dönünce 5 dakika geçtiyse tazeler',
      (tester) async {
        var now = DateTime(2026, 10, 3, 10);
        final src = _Seq([w1, w2]);
        final c = WeatherController(src, now: () => now)..start();
        await tester.pump();
        expect(c.value?.tempC, 13);
        expect(src.calls, 1);

        // Hemen dönünce (3 dk) yeniden çekmez.
        now = now.add(const Duration(minutes: 3));
        c.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await tester.pump();
        expect(src.calls, 1);

        // 6 dk sonra dönünce çeker ve yeni değeri gösterir.
        now = now.add(const Duration(minutes: 3));
        c.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await tester.pump();
        expect(src.calls, 2);
        expect(c.value?.tempC, 8);
        c.dispose();
      },
    );

    testWidgets('arka plana giderken tazelenmez', (tester) async {
      final src = _Seq([w1]);
      final c = WeatherController(src)..start();
      await tester.pump();
      c.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump();
      expect(src.calls, 1);
      c.dispose();
    });

    testWidgets(
      'tazeleme başarısız olursa son değer 2 saate kadar korunur, sonra gizlenir',
      (tester) async {
        var now = DateTime(2026, 10, 3, 10);
        final src = _Seq([w1, null]);
        final c = WeatherController(src, now: () => now)..start();
        await tester.pump();
        expect(c.value?.tempC, 13);

        now = now.add(const Duration(minutes: 90));
        await c.refresh(); // başarısız
        expect(c.value?.tempC, 13); // 90 dk: hâlâ gösterilir

        now = now.add(const Duration(minutes: 40)); // toplam 130 dk
        await c.refresh(); // yine başarısız
        expect(c.value, isNull); // eski veri gizlenir
        c.dispose();
      },
    );
  });

  group('hava durumu verisi', () {
    test('Open-Meteo yanıtı okunur', () {
      final w = parseWeather({
        'current': {'temperature_2m': 17.6, 'weather_code': 61, 'is_day': 0},
      });
      expect(w!.tempC, 18);
      expect(w.code, 61);
      expect(w.isDay, isFalse);
      expect(w.label, 'Yağmurlu');
    });

    test('bozuk ya da eksik yanıt null döner, sahte değer üretilmez', () {
      expect(parseWeather(null), isNull);
      expect(parseWeather('x'), isNull);
      expect(parseWeather({'current': {}}), isNull);
      expect(
        parseWeather({
          'current': {'temperature_2m': 'a', 'weather_code': 1},
        }),
        isNull,
      );
    });

    test('kodlar Türkçe açıklanır', () {
      expect(weatherLabel(0), 'Açık');
      expect(weatherLabel(3), 'Bulutlu');
      expect(weatherLabel(95), 'Gök gürültülü');
      expect(weatherLabel(999), isNotEmpty);
    });
  });

  group('ana sayfada hava durumu', () {
    Future<void> pumpApp(WidgetTester tester, WeatherSource source) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TavasApp(
          repository: MockContentRepository(),
          notifications: InMemoryNoticeSettings(),
          weather: source,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('alınan hava üst çubukta görünür', (tester) async {
      await pumpApp(
        tester,
        FixedWeatherSource(const Weather(tempC: 18, code: 2, isDay: true)),
      );
      expect(find.text('18°'), findsOneWidget);
      expect(find.text('Parçalı bulutlu'), findsOneWidget);
    });

    testWidgets('hava alınamazsa hiçbir şey gösterilmez', (tester) async {
      await pumpApp(tester, NoWeatherSource());
      expect(find.textContaining('°'), findsNothing);
      expect(find.textContaining(', Tavas'), findsOneWidget);
    });
  });
}
