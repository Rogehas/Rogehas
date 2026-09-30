enum NewsKind { haber, duyuru, kesinti }

enum ScenePalette { day, sand, dusk }

class NewsItem {
  const NewsItem({
    required this.kind,
    required this.title,
    required this.meta,
    required this.palette,
    this.label,
    this.body = '',
    this.photoUrl,
  });

  final NewsKind kind;
  final String title;
  final String meta;
  final ScenePalette palette;

  /// Etiket metni; verilmezse türden üretilir.
  final String? label;
  final String body;

  /// Görsel adresi (https ya da data:). Yoksa çizim gösterilir.
  final String? photoUrl;

  String get tagText =>
      label ??
      switch (kind) {
        NewsKind.haber => 'HABER',
        NewsKind.duyuru => 'DUYURU',
        NewsKind.kesinti => 'KESİNTİ',
      };
}

class VefatItem {
  const VefatItem({
    required this.name,
    required this.age,
    required this.neighborhood,
    required this.prayerTime,
    required this.mosque,
    required this.burial,
    required this.ago,
    this.photoUrl,
    this.prayerAt,
  });

  final String name;
  final int age;
  final String neighborhood;
  final String prayerTime;
  final String mosque;
  final String burial;
  final String ago;

  /// Ölen kişinin fotoğrafı (https ya da data:). Yoksa baş harfler gösterilir.
  final String? photoUrl;

  /// Cenaze namazı günü; sekmelere ayırmak için.
  final DateTime? prayerAt;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return parts.length > 1
        ? '${parts.first[0]}${parts.last[0]}'
        : parts.first[0];
  }
}

class Pharmacy {
  const Pharmacy({
    required this.id,
    required this.name,
    required this.neighborhood,
    required this.address,
    required this.phone,
    this.lat,
    this.lng,
  });

  final String id;
  final String name;
  final String neighborhood;
  final String address;

  /// Yalnızca rakamlar (ör. 02586140000).
  final String phone;
  final double? lat;
  final double? lng;
}

/// Bir günün nöbetçi eczane kimlikleri. Nöbet o günün 09:00'undan ertesi gün 09:00'una kadardır.
class DutyDay {
  const DutyDay({required this.date, required this.pharmacyIds});
  final String date; // yyyy-mm-dd
  final List<String> pharmacyIds;
}
