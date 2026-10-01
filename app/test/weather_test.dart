import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tavas/data/mock_data.dart';
import 'package:tavas/main.dart';
import 'package:tavas/notifications/notification_settings.dart';
import 'package:tavas/weather/weather.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

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
