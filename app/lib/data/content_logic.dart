import 'models.dart';

const _monthAbbr = [
  'OCA',
  'ŞUB',
  'MAR',
  'NİS',
  'MAY',
  'HAZ',
  'TEM',
  'AĞU',
  'EYL',
  'EKİ',
  'KAS',
  'ARA',
];
const _monthNames = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Bugün ve sonrası süren etkinlikler, en yakın tarih önce (aynı gün içinde saate göre).
List<EventItem> upcomingEvents(List<EventItem> all, DateTime now) {
  final today = _day(now);
  final list = all.where((e) => !_day(e.lastDay).isBefore(today)).toList()
    ..sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : a.time.compareTo(b.time);
    });
  return list;
}

/// Tarih rozeti: gün ("04") ve ay kısaltması ("EKİ").
({String day, String month}) eventBadge(EventItem e) => (
  day: e.date.day.toString().padLeft(2, '0'),
  month: _monthAbbr[e.date.month - 1],
);

/// "Bugün", "Yarın", "Devam ediyor", "4 Ekim" ya da "4–6 Ekim".
String eventWhenLabel(EventItem e, DateTime now) {
  final today = _day(now);
  final start = _day(e.date);
  final end = _day(e.lastDay);
  if (!start.isAfter(today) && !end.isBefore(today)) {
    return start == today || start == end ? 'Bugün' : 'Devam ediyor';
  }
  if (start.difference(today).inDays == 1) return 'Yarın';
  final m = _monthNames[e.date.month - 1];
  if (end == start) return '${e.date.day} $m';
  final em = _monthNames[e.lastDay.month - 1];
  return e.lastDay.month == e.date.month
      ? '${e.date.day}–${e.lastDay.day} $m'
      : '${e.date.day} $m – ${e.lastDay.day} $em';
}

/// Rehber: kategori sırası sabit (Acil önce), kategori içinde "sıra", sonra ada göre.
List<MapEntry<String, List<GuideEntry>>> groupGuide(List<GuideEntry> all) {
  const order = [
    'Acil',
    'Sağlık',
    'Belediye',
    'Kamu kurumu',
    'Ulaşım',
    'Diğer',
  ];
  final by = <String, List<GuideEntry>>{};
  for (final g in all) {
    by.putIfAbsent(g.category.isEmpty ? 'Diğer' : g.category, () => []).add(g);
  }
  int rank(String c) {
    final i = order.indexOf(c);
    return i < 0 ? order.length : i;
  }

  final keys = by.keys.toList()
    ..sort(
      (a, b) =>
          rank(a) != rank(b) ? rank(a).compareTo(rank(b)) : a.compareTo(b),
    );
  return [
    for (final k in keys)
      MapEntry(
        k,
        by[k]!..sort((a, b) {
          final c = a.order.compareTo(b.order);
          return c != 0 ? c : a.name.compareTo(b.name);
        }),
      ),
  ];
}

/// Esnaf listesi: kategori filtresi (`null` = tümü), ada göre.
List<Business> filterBusinesses(List<Business> all, String? category) {
  return all.where((b) => category == null || b.category == category).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
}

/// Mevcut kategoriler, sabit sırayla (listede olmayanlar gösterilmez).
List<String> businessCategories(List<Business> all) {
  const order = [
    'Restoran',
    'Kafe',
    'Konaklama',
    'Market',
    'Hizmet',
    'Sağlık',
    'Diğer',
  ];
  final present = all.map((b) => b.category).toSet();
  return [
    ...order.where(present.contains),
    ...present.where((c) => !order.contains(c) && c.isNotEmpty),
  ];
}

/// Türkçe harfleri ve büyük/küçük harf farkını yok sayan arama biçimi:
/// "SÖNMEZ", "sönmez" ve "sonmez" aynı sayılır.
String foldTr(String input) {
  const map = {
    'İ': 'i',
    'I': 'i',
    'ı': 'i',
    'Ş': 's',
    'ş': 's',
    'Ğ': 'g',
    'ğ': 'g',
    'Ü': 'u',
    'ü': 'u',
    'Ö': 'o',
    'ö': 'o',
    'Ç': 'c',
    'ç': 'c',
  };
  final b = StringBuffer();
  for (final r in input.runes) {
    final ch = String.fromCharCode(r);
    b.write(map[ch] ?? ch.toLowerCase());
  }
  return b.toString().trim();
}

/// Başlıkta ya da metinde geçen haberler; boş arama hepsini döndürür.
List<NewsItem> searchNews(List<NewsItem> all, String query) {
  final q = foldTr(query);
  if (q.isEmpty) return all;
  return all
      .where((n) => foldTr('${n.title} ${n.body} ${n.tagText}').contains(q))
      .toList();
}

/// Vefat ilanının WhatsApp vb. ile paylaşılacak metni.
String vefatShareText(VefatItem v) {
  final prayer = [
    if (v.prayerTime.isNotEmpty) v.prayerTime,
    if (v.mosque.isNotEmpty) v.mosque,
  ].join(', ');
  final lines = <String>[
    'Vefat: ${v.name}${v.age > 0 ? ' (${v.age})' : ''}',
    if (v.neighborhood.isNotEmpty) 'Mahalle: ${v.neighborhood}',
    if (prayer.isNotEmpty) 'Cenaze namazı: $prayer',
    if (v.burial.isNotEmpty) 'Defin yeri: ${v.burial}',
    if (v.condolenceAddress.isNotEmpty) 'Taziye yeri: ${v.condolenceAddress}',
    '',
    'Allah rahmet eylesin.',
    '— Tavas uygulaması',
  ];
  return lines.join('\n');
}
