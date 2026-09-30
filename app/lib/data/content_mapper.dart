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

  static Pharmacy? pharmacy(String id, Map<String, dynamic> m) {
    if (m['active'] == false) return null; // kapatılan eczane gösterilmez
    final name = (m['name'] as String? ?? '').trim();
    if (name.isEmpty) return null;
    return Pharmacy(
      id: id,
      name: name,
      neighborhood: (m['neighborhood'] as String? ?? '').trim(),
      address: (m['address'] as String? ?? '').trim(),
      phone: (m['phone'] as String? ?? '').replaceAll(RegExp(r'\D'), ''),
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
    );
  }

  static String _s(Object? v) => (v as String? ?? '').trim();

  static String _phone(Object? v) => _s(v).replaceAll(RegExp(r'\D'), '');

  static DateTime? _ymd(Object? v) {
    if (v is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
      return null;
    }
    final p = v.split('-').map(int.parse).toList();
    final d = DateTime(p[0], p[1], p[2]);
    // 31 Şubat gibi geçersiz tarihler DateTime'da kayar; bunları eşleştirme.
    return d.month == p[1] && d.day == p[2] ? d : null;
  }

  static EventItem? event(String id, Map<String, dynamic> m) {
    final title = _s(m['title']);
    final date = _ymd(m['date']);
    if (m['published'] == false || title.isEmpty || date == null) return null;
    final end = _ymd(m['endDate']);
    return EventItem(
      id: id,
      title: title,
      date: date,
      endDate: end != null && !end.isBefore(date) ? end : null,
      time: _s(m['time']),
      place: _s(m['place']),
      description: _s(m['description']),
      photoUrl: _photo(m['photo']),
    );
  }

  static GuideEntry? guide(String id, Map<String, dynamic> m) {
    final name = _s(m['name']);
    final phone = _phone(m['phone']);
    if (m['published'] == false || name.isEmpty || phone.isEmpty) return null;
    return GuideEntry(
      id: id,
      name: name,
      category: _s(m['category']),
      phone: phone,
      address: _s(m['address']),
      note: _s(m['note']),
      order: (m['order'] as num?)?.toInt() ?? 0,
    );
  }

  static Business? business(String id, Map<String, dynamic> m) {
    final name = _s(m['name']);
    if (m['published'] == false || name.isEmpty) return null;
    return Business(
      id: id,
      name: name,
      category: _s(m['category']),
      description: _s(m['description']),
      phone: _phone(m['phone']),
      address: _s(m['address']),
      hours: _s(m['hours']),
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      photoUrl: _photo(m['photo']),
    );
  }

  static DutyDay? duty(Map<String, dynamic> m) {
    final date = m['date'];
    if (date is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      return null;
    }
    final ids = m['pharmacyIds'];
    return DutyDay(
      date: date,
      pharmacyIds: ids is List ? ids.whereType<String>().toList() : const [],
    );
  }

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
      condolenceAddress: (m['condolenceAddress'] as String? ?? '').trim(),
    );
  }
}
