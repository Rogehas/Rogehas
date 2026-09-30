# Tavas Mobil Uygulaması – Proje Planı

## Karar verilenler

- **Platform:** iOS + Android (Flutter)
- **Backend:** Firebase (Auth, Firestore, Cloud Messaging, Storage)
- **Editör paneli:** Web (Next.js), rol bazlı yetki (admin / editör / moderatör)
- **Giriş:** Misafir modu + Google + Apple girişi
  - Misafir: haber, vefat, eczane, duyuru, rehber, harita, hava, namaz vakitleri
  - Giriş şart: chat, şikâyet/öneri, favori
  - Profil: ad, isteğe bağlı fotoğraf, mahalle. Uygulama içinden hesap silme.
- **Genel chat ilk sürümde:** giriş zorunlu, küfür filtresi, mesaj şikâyeti, kullanıcı engelleme, panelden mesaj silme / susturma
- **Hava durumu ve namaz vakitleri** ana sayfada
- **Tasarım:** Material 3, modern ve sade, açık/koyu tema

## Özellikler

| Bölüm | Not |
|---|---|
| Ana sayfa | Hava, namaz vakitleri, son haberler, kısa yol kartları |
| Haberler | Haber / Duyuru / Kesinti filtreleri tek sekmede |
| Vefat ilanları | Sadece editör girer, yayın öncesi onay; anlık push; arşivleme |
| Keşfet | Gezilecek yerler, etkinlikler, harita |
| Nöbetçi eczane | Veri kaynağı araştırılacak |
| Rehber | Önemli telefonlar, kurumlar, ulaşım saatleri |
| Yerel esnaf | Küçük başlangıç listesi, sonra başvuru ile büyür |
| Şikâyet / öneri | Fotoğraflı ve konumlu, giriş gerekli |
| Genel chat | Giriş gerekli, moderasyonlu |
| Bildirimler | Kategori bazlı (vefat, duyuru, kesinti, etkinlik) açma/kapama |

## Menü

Alt menü: **Ana Sayfa · Haberler · Vefat · Keşfet · Profil/Daha Fazla**
Chat, eczane, rehber, şikâyet: ana sayfadaki kısa yol kartlarından.

## Geliştirme fazları

1. **Faz 1 – Çekirdek:** proje kurulumu, giriş (misafir/Google/Apple), ana sayfa (hava + namaz), haberler, vefat + push, editör paneli
2. **Faz 2 – İçerik:** nöbetçi eczane, rehber, keşfet/harita, etkinlikler
3. **Faz 3 – Etkileşim:** genel chat + moderasyon, şikâyet/öneri, yerel esnaf, favoriler, paylaş

## Açık konular

- Uygulama adı ve yayıncı (belediye / bağımsız) → mağaza hesabı, KVKK metni
- Editör sayısı ve vefat ilanı doğrulama süreci
- Nöbetçi eczane, haber, hava ve namaz vakti veri kaynakları
- Yerel haber sitelerinden içerik alınacaksa izin

## Mağaza ve yasal gereklilikler

- KVKK aydınlatma metni, gizlilik politikası, kullanım koşulları
- Kullanıcı içeriği için: şikâyet, engelleme, moderasyon (mağaza zorunluluğu)
- Hesap silme uygulama içinden yapılabilmeli
- Apple ile giriş (Google girişi olduğu için zorunlu)

## Onaylanan tasarım (ekran taslakları)

Taslaklar: https://claude.ai/artifact/4MBRqJrUnsyqChgYQkbch8 (9 ekran: Giriş, Ana Sayfa, Haberler, Vefat, Keşfet, Eczane, Sohbet, Şikâyet, Editör Paneli)

**Tasarım dili**
- Başlık yazı tipi: Bricolage Grotesque (600–800); metin: Manrope
- Renkler: zümrüt `#0B4D3E`, limon vurgu `#D4F26A`, krem zemin `#F4F1EA`, mürekkep `#10201B`, uyarı/kesinti `#D9532B`
- Pastel kart renkleri: nane `#D9EBDD`, gökyüzü `#DCEAF2`, kum `#EFE4CB`, lavanta `#E6E0F3`
- Vefat ekranı koyu tema: zemin `#131A21`, kart `#1D2731`, vurgu `#C9D6E2`
- Yuvarlak köşeli kartlar (22–30 px), yumuşak gölge, yüzen koyu alt menü (hap biçimli)
- Alt menü: Ana Sayfa · Haberler · Vefat · Keşfet · Profil

**Notlar**
- Taslaklardaki tüm içerik örnektir (isimler, haberler, vakitler).
- Görseller geçici çizimlerdir; gerçek Tavas fotoğrafları eklenecek.

## İlerleme

- [x] Flutter iskeleti (`app/`): tema, yüzen alt menü, örnek veri
- [x] Giriş ekranı (misafir modu çalışıyor; Google/Apple Firebase bağlanınca)
- [x] Ana Sayfa, Haberler (filtreli), Vefat (koyu tema, bildirim anahtarı)
- [ ] Firebase kurulumu (Auth, Firestore, Cloud Messaging)
- [ ] Vefat push bildirimi
- [ ] Editör paneli (web)
- [ ] Faz 2 ve Faz 3 ekranları

Çalıştırma: `cd app && flutter pub get && flutter run` — testler: `flutter test`
