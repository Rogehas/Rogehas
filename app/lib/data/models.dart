enum NewsKind { haber, duyuru, kesinti }

enum ScenePalette { day, sand, dusk }

class NewsItem {
  const NewsItem({
    required this.kind,
    required this.title,
    required this.meta,
    required this.palette,
    this.id = '',
    this.label,
    this.body = '',
    this.photoUrl,
    this.commentsOpen = true,
  });

  /// Haber belge kimliği; yorumlar buna bağlanır. Örnek verilerde boş olabilir.
  final String id;

  /// Üyeler yorum yazabilir mi? Yayınlayan kapatabilir; belgede yoksa açık sayılır.
  final bool commentsOpen;

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
    this.condolenceAddress = '',
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

  /// Taziye yerinin adresi (boş olabilir). "Yol tarifi" bunu kullanır.
  final String condolenceAddress;

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

class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.date,
    required this.place,
    this.endDate,
    this.time = '',
    this.description = '',
    this.photoUrl,
  });

  final String id;
  final String title;
  final DateTime date;

  /// Çok günlü etkinliğin son günü (tek günlükse `null`).
  final DateTime? endDate;

  /// SS:DD ya da boş.
  final String time;
  final String place;
  final String description;
  final String? photoUrl;

  DateTime get lastDay => endDate ?? date;
}

class GuideEntry {
  const GuideEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.phone,
    this.address = '',
    this.note = '',
    this.order = 0,
  });

  final String id;
  final String name;
  final String category;
  final String phone;
  final String address;
  final String note;
  final int order;
}

class Business {
  const Business({
    required this.id,
    required this.name,
    required this.category,
    this.description = '',
    this.phone = '',
    this.address = '',
    this.hours = '',
    this.lat,
    this.lng,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String category;
  final String description;
  final String phone;
  final String address;
  final String hours;
  final double? lat;
  final double? lng;
  final String? photoUrl;
}
