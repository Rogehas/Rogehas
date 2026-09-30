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

class PrayerTime {
  const PrayerTime(this.name, this.time, {this.isNext = false});
  final String name;
  final String time;
  final bool isNext;
}
