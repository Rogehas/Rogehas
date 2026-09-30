import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase projesi `tavas-4f166` (Android uygulaması `com.tavas.tavas`).
/// Bu değerler gizli değildir (her uygulamanın içinde bulunur); veriyi güvenlik kuralları korur.
///
/// `appId` ve `apiKey` Firebase konsolundaki Android uygulamasının `google-services.json`
/// dosyasından alınır. Doldurulmadıysa uygulama sahte veri göstermez, hata bildirir.
class DefaultFirebaseOptions {
  static const _placeholder = 'DOLDURULACAK';

  static const android = FirebaseOptions(
    apiKey: _placeholder,
    appId: _placeholder,
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
