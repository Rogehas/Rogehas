import 'models.dart';

/// Örnek veriler. Firebase bağlanınca yerini gerçek veri alacak.
class MockData {
  static const news = <NewsItem>[
    NewsItem(
      kind: NewsKind.haber,
      title: "Tavas'ta sonbahar etkinlik takvimi açıklandı",
      meta: 'Bugün · Editör',
      palette: ScenePalette.dusk,
    ),
    NewsItem(
      kind: NewsKind.kesinti,
      label: 'KESİNTİ · SU',
      title: 'Yarın 09:00–14:00 arası planlı su kesintisi',
      meta: 'Belediye · 3 saat önce',
      palette: ScenePalette.sand,
    ),
    NewsItem(
      kind: NewsKind.duyuru,
      title: 'Başvuru tarihleri uzatıldı',
      meta: 'Belediye · Dün',
      palette: ScenePalette.day,
    ),
    NewsItem(
      kind: NewsKind.duyuru,
      title: 'Belediye hizmet saatlerinde yeni düzenleme',
      meta: '2 saat önce · Belediye',
      palette: ScenePalette.sand,
    ),
  ];

  static const vefat = <VefatItem>[
    VefatItem(
      name: 'Ayşe Örnek',
      age: 78,
      neighborhood: 'Merkez Mah.',
      prayerTime: 'Bugün 13:30',
      mosque: 'Merkez Camii',
      burial: 'Tavas Mezarlığı',
      ago: '1 sa önce',
    ),
    VefatItem(
      name: 'Mehmet Örnek',
      age: 84,
      neighborhood: 'Yeni Mah.',
      prayerTime: 'Yarın 11:00',
      mosque: 'Yeni Mah. Camii',
      burial: 'Tavas Mezarlığı',
      ago: '3 sa önce',
    ),
  ];

  static const prayers = <PrayerTime>[
    PrayerTime('İmsak', '05:14'),
    PrayerTime('Öğle', '12:50'),
    PrayerTime('İkindi', '16:12'),
    PrayerTime('Akşam', '18:52', isNext: true),
    PrayerTime('Yatsı', '20:11'),
  ];
}
