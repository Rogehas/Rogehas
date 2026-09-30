import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase projesi `tavas-4f166` (Android uygulaması `com.tavas.tavas`).
/// Bu değerler gizli değildir (her uygulamanın içinde bulunur); veriyi güvenlik kuralları korur.
///
/// `appId` ve `apiKey` Android uygulamasının `google-services.json` dosyasından alınmıştır.
/// Değerler eksik olursa uygulama sahte veri göstermez, hata bildirir.
class DefaultFirebaseOptions {
  static const _placeholder = 'DOLDURULACAK';

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyAX6uiH5tgUF6jc1HDHVp-SY7mnAXzTU9I',
    appId: '1:227449958610:android:bb6fd1ef4f9a8ee133bd0b',
    messagingSenderId: '227449958610',
    projectId: 'tavas-4f166',
    storageBucket: 'tavas-4f166.firebasestorage.app',
  );

  static bool get isConfigured =>
      android.apiKey != _placeholder && android.appId != _placeholder;

  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('Bu platform henüz desteklenmiyor.');
  }
}
