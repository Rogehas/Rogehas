import 'models.dart';

/// Ana sayfadaki kayan haberlerde başlığın fotoğraf üzerindeki görünümü.
/// İki ana biçim var: şeritsiz gölgeli yazı ve siyah yuvarlak şerit; çeşitlilik yazı renginden gelir; yazı her zaman fotoğrafın altındadır.
enum HeroStyle {
  /// Beyaz yazı, altta.
  whiteBottom,

  /// Siyah yuvarlak şerit, beyaz yazı, altta.
  bandWhite,

  /// Sarı yazı, altta.
  yellowBottom,

  /// Siyah yuvarlak şerit, sarı yazı, altta.
  bandYellow,

  /// Açık mavi yazı, altta.
  cyanBottom,

  /// Siyah yuvarlak şerit, kırmızı-turuncu yazı, altta (kesinti uyarısı).
  bandAlert,
}

const _rotation = [
  HeroStyle.whiteBottom,
  HeroStyle.bandWhite,
  HeroStyle.yellowBottom,
  HeroStyle.bandYellow,
  HeroStyle.cyanBottom,
];

/// Slaytın sırasına ve türüne göre stil seçer. Kesinti hep uyarı rengindedir;
/// diğerlerinde komşu iki slayt asla aynı stili almaz.
HeroStyle heroStyleFor(int index, NewsKind kind) => kind == NewsKind.kesinti
    ? HeroStyle.bandAlert
    : _rotation[index % _rotation.length];

/// Türkçe büyük harf (i → İ, ı → I).
String trUpper(String s) =>
    s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
