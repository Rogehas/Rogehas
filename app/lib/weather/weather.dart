import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// Anlık hava durumu.
class Weather {
  const Weather({required this.tempC, required this.code, required this.isDay});
  final int tempC;

  /// WMO hava durumu kodu (Open-Meteo).
  final int code;
  final bool isDay;

  String get label => weatherLabel(code);
  IconData get icon => weatherIcon(code, isDay);
}

String weatherLabel(int code) => switch (code) {
  0 => 'Açık',
  1 => 'Az bulutlu',
  2 => 'Parçalı bulutlu',
  3 => 'Bulutlu',
  45 || 48 => 'Sisli',
  51 || 53 || 55 || 56 || 57 => 'Çisenti',
  61 || 63 || 65 || 66 || 67 => 'Yağmurlu',
  71 || 73 || 75 || 77 || 85 || 86 => 'Karlı',
  80 || 81 || 82 => 'Sağanak',
  95 || 96 || 99 => 'Gök gürültülü',
  _ => 'Hava durumu',
};

IconData weatherIcon(int code, bool isDay) => switch (code) {
  0 || 1 => isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
  2 => Icons.wb_cloudy_rounded,
  3 => Icons.cloud_rounded,
  45 || 48 => Icons.foggy,
  51 || 53 || 55 || 56 || 57 || 61 || 63 || 65 || 66 || 67 => Icons.grain,
  80 || 81 || 82 => Icons.water_drop_rounded,
  71 || 73 || 75 || 77 || 85 || 86 => Icons.ac_unit_rounded,
  95 || 96 || 99 => Icons.thunderstorm_rounded,
  _ => Icons.cloud_rounded,
};

/// Open-Meteo yanıtından hava durumu çıkarır; beklenmeyen biçimde null döner.
Weather? parseWeather(Object? json) {
  if (json is! Map) return null;
  final cur = json['current'];
  if (cur is! Map) return null;
  final t = cur['temperature_2m'];
  final c = cur['weather_code'];
  if (t is! num || c is! num) return null;
  return Weather(
    tempC: t.round(),
    code: c.toInt(),
    isDay: (cur['is_day'] as num?) != 0,
  );
}

abstract class WeatherSource {
  /// Güncel hava; alınamazsa null (sahte değer gösterilmez).
  Future<Weather?> fetch();
}

/// Tavas (Denizli) için Open-Meteo'dan anahtarsız, ücretsiz hava verisi.
class OpenMeteoWeatherSource implements WeatherSource {
  static final _uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
    'latitude': '37.5736',
    'longitude': '29.0722',
    'current': 'temperature_2m,weather_code,is_day',
    'timezone': 'Europe/Istanbul',
  });

  @override
  Future<Weather?> fetch() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(_uri).timeout(const Duration(seconds: 8));
      final res = await req.close().timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final body = await res
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 8));
      return parseWeather(jsonDecode(body));
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

/// Hava durumu gösterilmesin istendiğinde (testler) kullanılır.
class NoWeatherSource implements WeatherSource {
  @override
  Future<Weather?> fetch() async => null;
}

/// Sabit değer döndüren kaynak (tanıtım ve testler).
class FixedWeatherSource implements WeatherSource {
  FixedWeatherSource(this.weather);
  final Weather? weather;
  @override
  Future<Weather?> fetch() async => weather;
}

/// Hava durumunu çeker ve güncel tutar:
/// - açılışta bir kez, sonra [refreshEvery] aralıkla (Open-Meteo verisi ~15 dakikada bir değişir),
/// - uygulama arka plandan dönünce (son denemeden [resumeAfter] geçtiyse),
/// - başarısız denemede son değer korunur, ama [staleAfter]'dan eskiyse gösterilmez (eski veri yanıltmasın).
class WeatherController extends ChangeNotifier with WidgetsBindingObserver {
  WeatherController(
    this._source, {
    DateTime Function()? now,
    this.refreshEvery = const Duration(minutes: 15),
    this.staleAfter = const Duration(hours: 2),
    this.resumeAfter = const Duration(minutes: 5),
  }) : _now = now ?? DateTime.now;

  final WeatherSource _source;
  final DateTime Function() _now;
  final Duration refreshEvery;
  final Duration staleAfter;
  final Duration resumeAfter;

  Weather? _value;
  DateTime? _fetchedAt;
  DateTime? _lastAttempt;
  Timer? _timer;
  bool _disposed = false;

  /// Güncel hava; hiç alınamadıysa ya da son başarılı veri çok eskiyse null.
  Weather? get value {
    final w = _value;
    final t = _fetchedAt;
    if (w == null || t == null) return null;
    return _now().difference(t) > staleAfter ? null : w;
  }

  void start() {
    if (_timer != null) return;
    WidgetsBinding.instance.addObserver(this);
    unawaited(refresh());
    _timer = Timer.periodic(refreshEvery, (_) => refresh());
  }

  Future<void> refresh() async {
    _lastAttempt = _now();
    final w = await _source.fetch();
    if (_disposed) return;
    if (w != null) {
      _value = w;
      _fetchedAt = _now();
    }
    notifyListeners(); // eski veri gizlenecekse de ekran yenilenir
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final last = _lastAttempt;
    if (last == null || _now().difference(last) >= resumeAfter) {
      unawaited(refresh());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class WeatherScope extends InheritedNotifier<WeatherController> {
  const WeatherScope({
    super.key,
    required WeatherController controller,
    required super.child,
  }) : super(notifier: controller);

  static Weather? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<WeatherScope>()
      ?.notifier
      ?.value;
}
