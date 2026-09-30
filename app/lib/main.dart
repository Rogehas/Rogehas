import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/content_repository.dart';
import 'data/mock_data.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

/// `--dart-define=USE_MOCK=true` ile örnek veriyle çalışır (tanıtım/deneme).
const _useMock = bool.fromEnvironment('USE_MOCK');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TavasApp(repository: await _createRepository()));
}

Future<ContentRepository> _createRepository() async {
  if (_useMock) return MockContentRepository();
  try {
    if (!DefaultFirebaseOptions.isConfigured) {
      throw StateError('Firebase yapılandırması eksik.');
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return FirestoreContentRepository();
  } catch (e) {
    // Sahte veri göstermek yerine ekranlarda "yüklenemedi" mesajı çıkar.
    return UnavailableContentRepository(e);
  }
}

class TavasApp extends StatefulWidget {
  const TavasApp({super.key, required this.repository});
  final ContentRepository repository;

  @override
  State<TavasApp> createState() => _TavasAppState();
}

class _TavasAppState extends State<TavasApp> {
  late final ContentHub _hub = ContentHub(widget.repository);

  @override
  void dispose() {
    _hub.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentScope(
      hub: _hub,
      child: MaterialApp(
        title: 'Tavas',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    );
  }
}
