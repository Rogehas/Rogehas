import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth/auth_service.dart';
import 'auth/firebase_auth_service.dart';
import 'chat/chat_repository.dart';
import 'data/content_repository.dart';
import 'data/mock_data.dart';
import 'firebase_options.dart';
import 'notifications/firebase_notification_settings.dart';
import 'notifications/notification_settings.dart';
import 'screens/shell.dart';
import 'theme/app_theme.dart';

/// `--dart-define=USE_MOCK=true` ile örnek veriyle çalışır (tanıtım/deneme).
const _useMock = bool.fromEnvironment('USE_MOCK');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final s = await _bootstrap();
  runApp(
    TavasApp(
      repository: s.repository,
      notifications: s.notifications,
      auth: s.auth,
      chat: s.chat,
      blocks: s.blocks,
    ),
  );
}

typedef _Services = ({
  ContentRepository repository,
  NoticeSettings notifications,
  AuthService auth,
  ChatRepository chat,
  BlockList blocks,
});

Future<_Services> _bootstrap() async {
  final blocks = await BlockList.load();
  if (_useMock) {
    return (
      repository: MockContentRepository(),
      notifications: InMemoryNoticeSettings(),
      auth: InMemoryAuthService(),
      chat: InMemoryChatRepository(),
      blocks: blocks,
    );
  }
  try {
    if (!DefaultFirebaseOptions.isConfigured) {
      throw StateError('Firebase yapılandırması eksik.');
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return (
      repository: FirestoreContentRepository(),
      notifications: await FirebaseNoticeSettings.create(),
      auth: FirebaseAuthService(),
      chat: FirestoreChatRepository(),
      blocks: blocks,
    );
  } catch (e) {
    // Sahte veri göstermek yerine ekranlarda "yüklenemedi" mesajı çıkar.
    return (
      repository: UnavailableContentRepository(e),
      notifications: InMemoryNoticeSettings(),
      auth: InMemoryAuthService(available: false),
      chat: InMemoryChatRepository(),
      blocks: blocks,
    );
  }
}

class TavasApp extends StatefulWidget {
  const TavasApp({
    super.key,
    required this.repository,
    required this.notifications,
    this.auth,
    this.chat,
    this.blocks,
  });
  final ContentRepository repository;
  final NoticeSettings notifications;

  /// Verilmezse bellekte çalışan örnekler kullanılır (testler, tanıtım).
  final AuthService? auth;
  final ChatRepository? chat;
  final BlockList? blocks;

  @override
  State<TavasApp> createState() => _TavasAppState();
}

class _TavasAppState extends State<TavasApp> {
  late final ContentHub _hub = ContentHub(widget.repository);
  late final AuthService _auth = widget.auth ?? InMemoryAuthService();
  late final ChatRepository _chat = widget.chat ?? InMemoryChatRepository();
  late final BlockList _blocks = widget.blocks ?? BlockList.memory();

  @override
  void dispose() {
    _hub.dispose();
    widget.notifications.dispose();
    if (widget.auth == null) _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentScope(
      hub: _hub,
      child: NotificationScope(
        settings: widget.notifications,
        child: AuthScope(
          service: _auth,
          child: ChatScope(
            repository: _chat,
            blocks: _blocks,
            child: MaterialApp(
              title: 'Tavas',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              // Uygulama doğrudan ana sayfada açılır; giriş yalnızca sohbet için gerekir.
              home: const Shell(),
            ),
          ),
        ),
      ),
    );
  }
}
