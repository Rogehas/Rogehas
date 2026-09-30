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

- [x] Flutter uygulaması: giriş (misafir), Ana Sayfa, Haberler (filtreli), Vefat (koyu tema, fotoğraf) — **gerçek Firestore verisiyle**
- [x] Editör paneli (web) — **https://tavas-4f166.web.app**: roller, davet, vefat onay akışı, haber yönetimi
- [x] Firebase: Auth (Google + e-posta), Firestore, güvenlik kuralları (emülatörde 16 testle doğrulandı; gerçek projede yayınlandı)
- [x] Android APK GitHub Actions ile derleniyor (`.github/workflows/android-apk.yml`), telefonda denendi
- [x] Blaze planı, Storage kuralları ve Cloud Functions yayında
- [x] Vefat/haber push bildirimi (FCM): panelden yayınla → sunucu gönderir → telefona düşer (gerçek cihazda doğrulandı)
- [ ] Panelden fotoğraf yükleme (Storage) gerçek projede henüz denenmedi
- [ ] Temizlik: deneme ilanları/bildirim kayıtları (Firestore `vefat`, `notices`), API anahtarı kısıtlaması
- [x] Ana sayfa yeniden tasarlandı (Öneri A: öne çıkan haber + vefat + kısayollar + son haberler). Namaz vakitleri ve sahte hava durumu **kaldırıldı**; ileride gerçek kaynakla (Diyanet/hava API) geri eklenebilir
- [x] Nöbetçi eczane: panelden elle giriş (eczane kaydı + tarih aralığıyla nöbet takvimi), uygulamada Bugün/Yarın, Ara ve Yol tarifi. Nöbet günü 09:00'da değişir
- [ ] Faz 2 (kalan): rehber, keşfet/harita, etkinlikler
- [ ] Faz 3: Google girişi + sohbet, şikâyet/öneri, esnaf, favoriler
- [ ] Play Store: ikon, imza anahtarı, gizlilik politikası/KVKK, hesap silme, kapalı test

Çalıştırma: `cd app && flutter pub get && flutter run` — testler: `flutter test`

## Vefat ilanlarında fotoğraf

- Editör ilanda ölen kişinin fotoğrafını yükler; kullanıcılar kartta görür, dokununca tam ekran büyütür (yakınlaştırılabilir).
- Fotoğraf yoksa ya da yüklenemezse baş harfler gösterilir.
- Depolama: Firebase Storage. Yüklerken yeniden boyutlandırılıp sıkıştırılacak (hızlı yükleme, düşük maliyet).
- Fotoğraf yüklemeden önce "Aile onayı alındı" işaretlenmeli (editör panelinde zorunlu).
- Fotoğraf sadece yetkili editör/yönetici tarafından eklenir ve değiştirilir; kullanıcılar yükleyemez.
- Arşive alınan ilanlarda fotoğraf gösterimi yönetici kararıyla kapatılabilir.

## Android yayın adımları

1. Firebase projesi ve `google-services.json` (repoya konmaz)
2. Uygulama adı, ikon, açılış ekranı
3. İmzalama anahtarı (keystore) oluşturma ve güvenli saklama
4. Google Play Console hesabı (tek seferlik 25 dolar) ve mağaza kaydı
5. Gizlilik politikası ve KVKK metni (web adresi gerekir), veri güvenliği formu
6. Kapalı test (Google zorunlu kılabilir: en az 12 test kullanıcısı, 14 gün) → yayın

## Editör paneli (`panel/`, Next.js)

Roller: **Yönetici**, **Editör** (birden fazla), **Moderatör**.
- Editör: kendi ilanını taslak yapar, düzenler, onaya gönderir. Yayınlayamaz.
- Yönetici: onaylar/reddeder (neden zorunlu), doğrudan yayınlar, arşivler, kullanıcı ekler, rol atar, hesap kapatır. Son yönetici kapatılamaz.
- Moderatör: yalnızca şikâyet ve sohbet moderasyonu.
- Vefat ilanı: zorunlu alanlar + "Aile onayı alındı" olmadan onaya gönderilemez/yayınlanamaz. Fotoğraf 800 px'e küçültülür.
- Yayınlanınca bildirim kaydı üretilir (şimdilik yerel; Firebase Cloud Messaging'e bağlanacak).
- Şimdilik veri tarayıcıda (localStorage) ve giriş demo: Firebase Auth/Firestore bağlanınca `panel/src/lib/store.ts` ve `session.tsx` değişecek.
- Çalıştırma: `cd panel && npm install && npm run dev`; testler: `npm test`

### Haber yönetimi (panel)
- Tür: Haber / Duyuru / Kesinti (kesintide alt tür zorunlu, ör. SU). Uygulamadaki Haberler ekranıyla aynı üç tür.
- Editörler onay beklemeden yayınlar ve yayınlanmış haberi düzenler; arşivleme yalnızca yöneticide.
- "Telefonlara bildirim gönder" seçeneği (özellikle kesinti/duyuru için); bildirim önizlemesi form üzerinde.

## Firebase (proje: `tavas-4f166`)

Panel artık gerçek Firebase'e bağlı (Auth: Google + e-posta/şifre, Firestore). Güvenlik kuralları `panel/firestore.rules` ve `panel/storage.rules`.
- Roller Firestore `users/{uid}` belgesinde. İlk yönetici elle oluşturulur; diğerleri yönetici panelinden **davet** edilir (`invites/{e-posta}`), davetli kişi doğrulanmış e-postasıyla ilk girişte otomatik yetkilenir.
- Kurallar sunucuda da uygular: editör yayınlayamaz, aile onayı olmadan yayın olmaz, misafir yalnızca `status == published` okur, moderatör vefat/haber görmez.
- Testler: `npm test` (iş kuralları), `npm run test:rules` (kurallar, Firestore emülatörü gerekir; Java lazım).
- Fotoğraflar Blaze planına geçilene kadar belge içinde saklanır (`NEXT_PUBLIC_USE_STORAGE=true` ile Storage'a geçer).
- Uygulamada okuma sorguları mutlaka `where status == 'published'` içermeli.

Kalan: kuralları yayınlama, ilk yönetici profili, Blaze + Storage, push bildirimi (Cloud Functions + FCM), mobil uygulamayı Firebase'e bağlama.

## Panelin yayınlanması (Firebase Hosting, ücretsiz plan)

- Panel statik dosya olarak derlenir (`output: 'export'`, `panel/out`) ve Firebase Hosting'e yüklenir: `https://tavas-4f166.web.app`
- Düzenleme sayfaları adres parametresiyle çalışır: `/vefat/edit?id=…`, `/haberler/edit?id=…` (yeni kayıt için `id` yok).
- Yayınlama: `cd panel && npm install && npm run deploy` (önce bir kez `npx firebase login`).
- Giriş için `tavas-4f166.web.app` alan adı Firebase Authentication'da varsayılan olarak yetkilidir.

## Bildirimler (FCM) ve fotoğraf depolama

- Panel bir ilan/haber yayınlayınca `notices` kaydı yazar (`topic`: vefat / haber / duyuru / kesinti). `panel/functions/` içindeki `sendNotice` (Cloud Functions, 2. nesil) kayıt oluşunca o konuya abone telefonlara FCM mesajı gönderir; kaydı `sentAt` ile işaretler (tekrar gönderilmez). Hata olursa `error`/`failedAt` yazılır, yeniden denenmez (eski vefat bildirimi geç gitmesin).
- Uygulama ilk açılışta bildirim izni ister; varsayılan abonelikler: vefat, duyuru, kesinti (haber kapalı). Vefat ekranındaki anahtar `vefat` konusuna abone olur/çıkar; izin reddedilmişse uyarır.
- Android kanalları: `vefat` (yüksek önem), `genel` (`MainActivity.kt`; adlar `functions/notify.js` ile aynı olmalı).
- Fotoğraflar artık Firebase Storage'a yüklenir (`vefat/{id}/photo-<zaman>.jpg`, `news/...`); herkes okur, yalnızca aktif yönetici/editör yazar, 2 MB ve `image/*` sınırı.
- Yayınlama: `cd panel && npm run deploy:backend` (fonksiyon + Firestore/Storage kuralları) ve `npm run deploy` (panel).
- Doğrulama durumu: fonksiyonun tetiklenmesi ve mesaj üretimi emülatör/birim testlerinde doğrulandı; gerçek FCM gönderimi, Storage kuralları ve telefonda bildirim görünmesi gerçek projede denenecek (emülatör bu servisleri burada doğrulayamadı).

## Nöbetçi eczane

- Veri kaynağı: **panelden elle giriş** (güvenilir ve izinli; eczacı odası sitelerinden otomatik çekmek yanlış/eskimiş veri riski ve kullanım şartı sorunu taşır). Yanlış nöbetçi eczane bilgisi halk için zararlı olduğundan bilinçli tercih.
- Firestore: `pharmacies/{id}` (ad, mahalle, adres, telefon, isteğe bağlı enlem/boylam, aktif) ve `duty/{yyyy-mm-dd}` (`pharmacyIds`). Herkes okur; yalnızca aktif yönetici/editör yazar; silme yok (eczane "kapatılır").
- Nöbet, günün 09:00'undan ertesi gün 09:00'una kadar sürer; uygulama saat 09:00'dan önce dünün nöbetini gösterir.
- Girilmemiş gün: uygulama "nöbet bilgisi henüz girilmedi" der (yanlış eczane göstermek yerine).
- Yayınlama: kurallar için `npm run deploy:backend`, panel için `npm run deploy`.

- Panel önbelleği: Firebase Hosting varsayılan olarak sayfaları ~1 saat önbelleğe alır; editörler yeni sürümü geç görmesin diye `firebase.json`'da `Cache-Control: no-cache` (her seferinde yeniden doğrulama) ayarlı.
- `panel/out/` (derleme çıktısı) repoda tutulmaz (`.gitignore`); her yayında `npm run deploy` yeniden derler. Bir ara yanlışlıkla commit edilmişti, takipten çıkarıldı.
