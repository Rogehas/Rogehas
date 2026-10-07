/// Reklamın uygulamada görünebileceği yerler. Panelde seçilen yer anahtarları [name] ile aynıdır.
enum AdPlacement { hero, home, nav, newsDetail, newsList, esnaf, info }

enum AdAction { call, map, web }

/// Bir yerde dönen en fazla reklam sayısı (panel de bunu zorlar).
const maxAdsPerPlacement = 3;

class AdItem {
  const AdItem({
    required this.id,
    required this.name,
    required this.text,
    required this.action,
    required this.actionValue,
    required this.placements,
    this.photoUrl,
    this.start,
    this.end,
    this.active = true,
    this.createdAt,
  });

  final String id;
  final String name;
  final String text;
  final AdAction action;

  /// Telefon, adres ya da web adresi.
  final String actionValue;
  final Set<AdPlacement> placements;
  final String? photoUrl;

  /// Yayın günleri (dahil); boşsa sınırsız.
  final DateTime? start;
  final DateTime? end;
  final bool active;
  final DateTime? createdAt;

  /// Reklam kartlarındaki eylem yazısı.
  String get actionLabel => switch (action) {
    AdAction.call => 'Ara ›',
    AdAction.map => 'Haritada aç ›',
    AdAction.web => 'Siteye git ›',
  };

  /// Dokununca açılacak adres; değer bozuksa null.
  Uri? get uri {
    final v = actionValue.trim();
    if (v.isEmpty) return null;
    switch (action) {
      case AdAction.call:
        final digits = v.replaceAll(RegExp(r'[^0-9+]'), '');
        return digits.isEmpty ? null : Uri(scheme: 'tel', path: digits);
      case AdAction.map:
        return Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': v,
        });
      case AdAction.web:
        final u = Uri.tryParse(
          RegExp(r'^https?://', caseSensitive: false).hasMatch(v)
              ? v
              : 'https://$v',
        );
        return u == null || u.host.isEmpty ? null : u;
    }
  }
}

/// Reklam kaynağının anlık durumu: genel anahtar ve tüm reklamlar.
class AdsState {
  const AdsState({this.enabled = true, this.ads = const []});
  final bool enabled;
  final List<AdItem> ads;
}

bool _sameDayOrAfter(DateTime a, DateTime b) => !DateTime(
  a.year,
  a.month,
  a.day,
).isBefore(DateTime(b.year, b.month, b.day));

/// [placement] için şu an gösterilebilecek reklamlar (en fazla [maxAdsPerPlacement], en eskiden yeniye).
/// Genel anahtar kapalıysa, reklam kapalıysa, tarihi dışındaysa ya da dokunma adresi bozuksa dışarıda kalır.
List<AdItem> eligibleAds(AdsState state, AdPlacement placement, DateTime now) {
  if (!state.enabled) return const [];
  final list = [
    for (final a in state.ads)
      if (a.active &&
          a.placements.contains(placement) &&
          a.uri != null &&
          (a.start == null || _sameDayOrAfter(now, a.start!)) &&
          (a.end == null || _sameDayOrAfter(a.end!, now)))
        a,
  ];
  list.sort((a, b) {
    final c = (a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
      b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
    return c != 0 ? c : a.id.compareTo(b.id);
  });
  return list.take(maxAdsPerPlacement).toList();
}

/// Uygulama her açıldığında sıradaki reklamı seçer: [launch] sayısı kadar döner.
AdItem? pickAd(List<AdItem> eligible, int launch) =>
    eligible.isEmpty ? null : eligible[launch.abs() % eligible.length];
