import 'package:flutter_test/flutter_test.dart';
import 'package:tavas/data/content_mapper.dart';
import 'package:tavas/data/mock_data.dart';
import 'package:tavas/data/models.dart';
import 'package:tavas/data/vefat_filter.dart';

void main() {
  final now = DateTime(2026, 9, 30, 15, 0);

  group('haber eşleme', () {
    test('kesinti etiketi alt türle birlikte büyük harfle yazılır', () {
      final n = ContentMapper.news({
        'kind': 'kesinti',
        'subLabel': 'su',
        'title': '  Yarın su kesintisi ',
        'source': 'Belediye',
        'publishedAt': '2026-09-30T12:00:00.000',
        'photo': null,
      }, now: now);
      expect(n.kind, NewsKind.kesinti);
      expect(n.tagText, 'KESİNTİ · SU');
      expect(n.title, 'Yarın su kesintisi');
      expect(n.meta, 'Belediye · 3 sa önce');
      expect(n.photoUrl, isNull);
    });

    test('bilinmeyen tür habere düşer, boş kaynak atlanır', () {
      final n = ContentMapper.news({
        'kind': 'x',
        'title': 'T',
        'source': '',
        'publishedAt': '2026-09-30T14:59:30.000',
        'photo': 'data:image/jpeg;base64,AAAA',
      }, now: now);
      expect(n.kind, NewsKind.haber);
      expect(n.meta, 'Az önce');
      expect(n.photoUrl, startsWith('data:image'));
    });
  });

  group('vefat eşleme', () {
    Map<String, dynamic> doc(String day) => {
      'name': 'Ayşe Örnek',
      'age': 78,
      'neighborhood': 'Merkez',
      'prayerDate': day,
      'prayerTime': '13:30',
      'mosque': 'Merkez Camii',
      'burialPlace': 'Tavas Mezarlığı',
      'publishedAt': '2026-09-30T14:00:00.000',
      'photo': 'https://example.com/a.jpg',
    };

    test('cenaze günü bugün / yarın / tarih olarak yazılır', () {
      expect(
        ContentMapper.vefat(doc('2026-09-30'), now: now).prayerTime,
        'Bugün 13:30',
      );
      expect(
        ContentMapper.vefat(doc('2026-10-01'), now: now).prayerTime,
        'Yarın 13:30',
      );
      expect(
        ContentMapper.vefat(doc('2026-10-05'), now: now).prayerTime,
        '05.10 13:30',
      );
    });

    test('fotoğraf ve baş harfler', () {
      final v = ContentMapper.vefat(doc('2026-09-30'), now: now);
      expect(v.photoUrl, 'https://example.com/a.jpg');
      expect(v.initials, 'AÖ');
      expect(v.ago, '1 sa önce');
    });

    test('eksik alanlar çökertmez', () {
      final v = ContentMapper.vefat({'name': ' '}, now: now);
      expect(v.age, 0);
      expect(v.initials, '?');
    });
  });

  group('vefat sekmeleri', () {
    VefatItem at(DateTime? d) => VefatItem(
      name: 'A B',
      age: 1,
      neighborhood: '',
      prayerTime: '',
      mosque: '',
      burial: '',
      ago: '',
      prayerAt: d,
    );

    test('bugün ve gelecek Bugün, 1-7 gün önce Bu hafta, daha eski Arşiv', () {
      final items = [
        at(DateTime(2026, 9, 30)),
        at(DateTime(2026, 10, 1)),
        at(DateTime(2026, 9, 25)),
        at(DateTime(2026, 9, 1)),
        at(null),
      ];
      expect(filterVefat(items, 0, now).length, 3);
      expect(filterVefat(items, 1, now).length, 1);
      expect(filterVefat(items, 2, now).length, 1);
    });

    test('mock veri Bugün sekmesinde görünür', () {
      expect(filterVefat(MockData.vefat(), 0, DateTime.now()).length, 2);
    });
  });

  test('Türkçe tarih', () => expect(turkishDate(now), '30 Eylül'));
}
