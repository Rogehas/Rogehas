enum NewsKind { haber, duyuru, kesinti }

enum ScenePalette { day, sand, dusk }

class NewsItem {
  const NewsItem({
    required this.kind,
    required this.title,
    required this.meta,
    required this.palette,
    this.label,
  });

  final NewsKind kind;
  final String title;
  final String meta;
  final ScenePalette palette;

  /// Etiket metni; verilmezse türden üretilir.
  final String? label;

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
  });

  final String name;
  final int age;
  final String neighborhood;
  final String prayerTime;
  final String mosque;
  final String burial;
  final String ago;

  String get initials {
    final parts = name.split(' ');
    return parts.length > 1 ? '${parts.first[0]}${parts.last[0]}' : name[0];
  }
}

class PrayerTime {
  const PrayerTime(this.name, this.time, {this.isNext = false});
  final String name;
  final String time;
  final bool isNext;
}
