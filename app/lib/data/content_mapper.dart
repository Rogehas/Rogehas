import 'models.dart';

/// Firestore belgelerini (panelin yazdığı alanlar) uygulama modellerine çevirir.
class ContentMapper {
  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  static String ago(DateTime? t, DateTime now) {
    if (t == null) return '';
    final d = now.difference(t);
    if (d.inMinutes < 1) return 'Az önce';
    if (d.inMinutes < 60) return '${d.inMinutes} dk önce';
    if (d.inHours < 24) return '${d.inHours} sa önce';
    return '${d.inDays} gün önce';
  }

  static String? _photo(Object? v) => v is String && v.isNotEmpty ? v : null;

  static NewsKind kindOf(Object? v) => switch (v) {
    'duyuru' => NewsKind.duyuru,
    'kesinti' => NewsKind.kesinti,
    _ => NewsKind.haber,
  };

  /// Yayınlanma zamanı; sıralama için.
  static DateTime publishedAt(Map<String, dynamic> m) =>
      _date(m['publishedAt']) ??
      _date(m['updatedAt']) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  static NewsItem news(Map<String, dynamic> m, {DateTime? now}) {
    final kind = kindOf(m['kind']);
    final sub = (m['subLabel'] as String? ?? '').trim();
    final source = (m['source'] as String? ?? '').trim();
    final t = ago(publishedAt(m), now ?? DateTime.now());
    return NewsItem(
      kind: kind,
      label: kind == NewsKind.kesinti && sub.isNotEmpty
          ? 'KESİNTİ · ${sub.toUpperCase()}'
          : null,
      title: (m['title'] as String? ?? '').trim(),
      body: (m['body'] as String? ?? '').trim(),
      meta: [if (source.isNotEmpty) source, if (t.isNotEmpty) t].join(' · '),
      palette: kind == NewsKind.haber ? ScenePalette.day : ScenePalette.sand,
      photoUrl: _photo(m['photo']),
    );
  }

  static String prayerLabel(DateTime? day, String time, DateTime now) {
    if (day == null) return time;
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(
      day.year,
      day.month,
      day.day,
    ).difference(today).inDays;
    final label = switch (diff) {
      0 => 'Bugün',
      1 => 'Yarın',
      _ =>
        '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}',
    };
    return '$label $time'.trim();
  }

  static VefatItem vefat(Map<String, dynamic> m, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final day = _date(m['prayerDate']);
    final burial = (m['burialPlace'] as String? ?? '').trim();
    return VefatItem(
      name: (m['name'] as String? ?? '').trim(),
      age: (m['age'] as num?)?.toInt() ?? 0,
      neighborhood: (m['neighborhood'] as String? ?? '').trim(),
      prayerTime: prayerLabel(
        day,
        (m['prayerTime'] as String? ?? '').trim(),
        n,
      ),
      mosque: (m['mosque'] as String? ?? '').trim(),
      burial: burial,
      ago: ago(publishedAt(m), n),
      photoUrl: _photo(m['photo']),
      prayerAt: day,
    );
  }
}
