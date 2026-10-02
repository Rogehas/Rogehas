import 'package:flutter_test/flutter_test.dart';
import 'package:tavas/data/hero_style.dart';
import 'package:tavas/data/models.dart';

void main() {
  test('kesinti haberi hep uyarı rengindeki şeridi alır', () {
    for (var i = 0; i < 6; i++) {
      expect(heroStyleFor(i, NewsKind.kesinti), HeroStyle.bandAlert);
    }
  });

  test(
    'haber ve duyuruda komşu slaytlar farklı stil alır, ilki beyaz büyüktür',
    () {
      expect(heroStyleFor(0, NewsKind.haber), HeroStyle.whiteBottom);
      for (var i = 0; i < 12; i++) {
        expect(
          heroStyleFor(i, NewsKind.haber) ==
              heroStyleFor(i + 1, NewsKind.duyuru),
          isFalse,
          reason: '$i. ve ${i + 1}. slayt',
        );
        expect(heroStyleFor(i, NewsKind.haber), isNot(HeroStyle.bandAlert));
      }
    },
  );

  test('Türkçe büyük harf', () {
    expect(trUpper('iğne ıslak'), 'İĞNE ISLAK');
    expect(trUpper("Tavas'ta yatırım"), "TAVAS'TA YATIRIM");
  });
}
