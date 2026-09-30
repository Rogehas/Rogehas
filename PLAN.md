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
