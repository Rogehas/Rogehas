import 'content_repository.dart';
import 'duty_logic.dart';
import 'models.dart';

/// Örnek veriler: yalnızca testler ve `--dart-define=USE_MOCK=true` ile tanıtım için.
class MockData {
  static const news = <NewsItem>[
    NewsItem(
      kind: NewsKind.haber,
      title: "Tavas'ta sonbahar etkinlik takvimi açıklandı",
      meta: 'Bugün · Editör',
      body:
          'Sonbahar boyunca çeşitli etkinlikler düzenlenecek. Ayrıntılar yakında duyurulacak.',
      palette: ScenePalette.dusk,
    ),
    NewsItem(
      kind: NewsKind.kesinti,
      label: 'KESİNTİ · SU',
      title: 'Yarın 09:00–14:00 arası planlı su kesintisi',
      meta: 'Belediye · 3 saat önce',
      body: 'Bazı mahallelerde su verilemeyecek.',
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

  static const pharmacies = <Pharmacy>[
    Pharmacy(
      id: 'p1',
      name: 'Örnek Eczanesi',
      neighborhood: 'Merkez',
      address: 'Cumhuriyet Cd. No:1',
      phone: '02586140000',
    ),
    Pharmacy(
      id: 'p2',
      name: 'Yeni Eczanesi',
      neighborhood: 'Yeni Mah.',
      address: 'Atatürk Blv. No:5',
      phone: '02586141122',
      lat: 37.57,
      lng: 29.07,
    ),
  ];

  static List<EventItem> events() {
    final t = DateTime.now();
    final today = DateTime(t.year, t.month, t.day);
    return [
      EventItem(
        id: 'e1',
        title: 'Yerel Ürünler Pazarı',
        date: today.add(const Duration(days: 3)),
        time: '10:00',
        place: 'Pazar alanı',
        description: 'Üreticiler ürünlerini tanıtıyor.',
      ),
      EventItem(
        id: 'e2',
        title: 'Sonbahar Şenliği',
        date: today.add(const Duration(days: 10)),
        endDate: today.add(const Duration(days: 12)),
        place: 'Belediye meydanı',
      ),
    ];
  }

  static const guide = <GuideEntry>[
    GuideEntry(
      id: 'g1',
      name: 'Acil Yardım',
      category: 'Acil',
      phone: '112',
      order: 1,
    ),
    GuideEntry(
      id: 'g2',
      name: 'Belediye Santral',
      category: 'Belediye',
      phone: '02586140000',
      note: 'Hafta içi 08:00 – 17:00',
    ),
  ];

  static const businesses = <Business>[
    Business(
      id: 'b1',
      name: 'Lezzet Lokantası',
      category: 'Restoran',
      phone: '02586140001',
      address: 'Cumhuriyet Cd. No:3',
      hours: 'Her gün 08:00 – 22:00',
      description: 'Ev yemekleri.',
    ),
    Business(id: 'b2', name: 'Çarşı Kafe', category: 'Kafe', address: 'Çarşı'),
  ];

  /// Bugünün nöbeti p1 + p2, yarın boş (girilmemiş).
  static List<DutyDay> duty() => [
    DutyDay(
      date: dutyDateKey(currentDutyDay(DateTime.now())),
      pharmacyIds: const ['p1', 'p2'],
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
        condolenceAddress: 'Merkez Mah. Atatürk Cd. No:4',
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

  @override
  Stream<List<Pharmacy>> watchPharmacies() => Stream.value(MockData.pharmacies);

  @override
  Stream<List<DutyDay>> watchDuty() => Stream.value(MockData.duty());

  @override
  Stream<List<EventItem>> watchEvents() => Stream.value(MockData.events());

  @override
  Stream<List<GuideEntry>> watchGuide() => Stream.value(MockData.guide);

  @override
  Stream<List<Business>> watchBusinesses() => Stream.value(MockData.businesses);
}
