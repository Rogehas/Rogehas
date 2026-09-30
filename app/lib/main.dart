import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/content_repository.dart';
import 'data/mock_data.dart';
import 'firebase_options.dart';
import 'notifications/firebase_notification_settings.dart';
import 'notifications/notification_settings.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

/// `--dart-define=USE_MOCK=true` ile örnek veriyle çalışır (tanıtım/deneme).
const _useMock = bool.fromEnvironment('USE_MOCK');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (repository, notifications) = await _bootstrap();
  runApp(TavasApp(repository: repository, notifications: notifications));
}

Future<(ContentRepository, NoticeSettings)> _bootstrap() async {
  if (_useMock) {
    return (MockContentRepository(), InMemoryNoticeSettings());
  }
  try {
    if (!DefaultFirebaseOptions.isConfigured) {
      throw StateError('Firebase yapılandırması eksik.');
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return (
      FirestoreContentRepository(),
      await FirebaseNoticeSettings.create(),
    );
  } catch (e) {
    // Sahte veri göstermek yerine ekranlarda "yüklenemedi" mesajı çıkar.
    return (UnavailableContentRepository(e), InMemoryNoticeSettings());
  }
}

class TavasApp extends StatefulWidget {
  const TavasApp({
    super.key,
    required this.repository,
    required this.notifications,
  });
  final ContentRepository repository;
  final NoticeSettings notifications;

  @override
  State<TavasApp> createState() => _TavasAppState();
}

class _TavasAppState extends State<TavasApp> {
  late final ContentHub _hub = ContentHub(widget.repository);

  @override
  void dispose() {
    _hub.dispose();
    widget.notifications.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentScope(
      hub: _hub,
      child: NotificationScope(
        settings: widget.notifications,
        child: MaterialApp(
          title: 'Tavas',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
