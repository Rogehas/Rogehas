import 'content_repository.dart';
import 'models.dart';

/// Örnek veriler: yalnızca testler ve `--dart-define=USE_MOCK=true` ile tanıtım için.
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

  static List<VefatItem> vefat() {
    final today = DateTime.now();
    return [
      VefatItem(
        name: 'Ayşe Örnek',
        age: 78,
        neighborhood: 'Merkez Mah.',
        prayerTime: 'Bugün 13:30',
        mosque: 'Merkez Camii',
        burial: 'Tavas Mezarlığı',
        ago: '1 sa önce',
        prayerAt: today,
      ),
      VefatItem(
        name: 'Mehmet Örnek',
        age: 84,
        neighborhood: 'Yeni Mah.',
        prayerTime: 'Yarın 11:00',
        mosque: 'Yeni Mah. Camii',
        burial: 'Tavas Mezarlığı',
        ago: '3 sa önce',
        prayerAt: today.add(const Duration(days: 1)),
      ),
    ];
  }
}

class MockContentRepository implements ContentRepository {
  @override
  Stream<List<NewsItem>> watchNews() => Stream.value(MockData.news);

  @override
  Stream<List<VefatItem>> watchVefat() => Stream.value(MockData.vefat());
}
