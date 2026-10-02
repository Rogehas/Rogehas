import 'models.dart';

/// Ana sayfadaki kayan haberlerde başlığın fotoğraf üzerindeki görünümü.
enum HeroStyle {
  /// Beyaz büyük yazı, altta.
  whiteBottom,

  /// Sarı, büyük harfli yazı, ortada.
  yellowMiddle,

  /// Üstte sarı şerit, siyah yazı.
  yellowBandTop,

  /// Altta siyah yuvarlak şerit, beyaz yazı.
  blackBand,

  /// Altta tam genişlikte kırmızı şerit (kesinti haberleri).
  redBand,
}

const _rotation = [
  HeroStyle.whiteBottom,
  HeroStyle.yellowMiddle,
  HeroStyle.yellowBandTop,
  HeroStyle.blackBand,
];

/// Slaytın sırasına ve türüne göre stil seçer. Kesinti hep kırmızı şerittir;
/// diğerlerinde komşu iki slayt asla aynı stili almaz.
HeroStyle heroStyleFor(int index, NewsKind kind) => kind == NewsKind.kesinti
    ? HeroStyle.redBand
    : _rotation[index % _rotation.length];

/// Türkçe büyük harf (i → İ, ı → I).
String trUpper(String s) =>
    s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
