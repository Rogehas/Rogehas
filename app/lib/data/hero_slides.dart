import 'models.dart';

/// Ana sayfadaki kayan bölümde en fazla kaç slayt gösterilir.
const heroSlideLimit = 15;

/// Kayan bölümün bir slaytı: ya bir haber ya bir vefat ilanı.
class HeroSlide {
  const HeroSlide.news(NewsItem this.news) : vefat = null;
  const HeroSlide.vefat(VefatItem this.vefat) : news = null;

  final NewsItem? news;
  final VefatItem? vefat;

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
  return all.take(limit).toList();
}
