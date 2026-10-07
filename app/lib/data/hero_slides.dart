import '../ads/ad_models.dart';
import 'models.dart';

/// Ana sayfadaki kayan bölümde en fazla kaç slayt gösterilir.
const heroSlideLimit = 15;

/// Kayan bölümün bir slaytı: ya bir haber ya bir vefat ilanı.
class HeroSlide {
  const HeroSlide.news(NewsItem this.news) : vefat = null, ad = null;
  const HeroSlide.vefat(VefatItem this.vefat) : news = null, ad = null;
  const HeroSlide.ad(AdItem this.ad) : news = null, vefat = null;

  final NewsItem? news;
  final VefatItem? vefat;

  /// Sponsor reklam slaytı.
  final AdItem? ad;

  DateTime get at =>
      news?.publishedAt ??
      vefat?.publishedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

/// Yayındaki haber ve vefat ilanlarını yayınlanma zamanına göre (yeni üstte) birleştirir;
/// en fazla [heroSlideLimit] slayt döner. Zamanı eşit olanlarda haber, vefattan önce gelir.
List<HeroSlide> buildHeroSlides(
  List<NewsItem> news,
  List<VefatItem> vefat, {
  int limit = heroSlideLimit,
  AdItem? ad,
}) {
  final all = <HeroSlide>[
    for (final n in news) HeroSlide.news(n),
    for (final v in vefat) HeroSlide.vefat(v),
  ];
  final order = {for (var i = 0; i < all.length; i++) all[i]: i};
  all.sort((a, b) {
    final c = b.at.compareTo(a.at);
    return c != 0 ? c : order[a]!.compareTo(order[b]!);
  });
  final slides = all.take(limit).toList();
  // Reklam, içerik slaytlarının arasına (en fazla 3. sıraya) girer; içerik sayısını azaltmaz.
  if (ad != null && slides.isNotEmpty) {
    slides.insert(slides.length < 2 ? slides.length : 2, HeroSlide.ad(ad));
  }
  return slides;
}
