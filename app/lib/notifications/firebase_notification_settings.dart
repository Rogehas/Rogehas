import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_settings.dart';

/// Tercihleri telefonda saklar, açık konulara FCM üzerinden abone olur.
class FirebaseNoticeSettings extends NoticeSettings {
  FirebaseNoticeSettings(this._prefs, [FirebaseMessaging? messaging])
    : _fm = messaging ?? FirebaseMessaging.instance;

  static const _initKey = 'notif_initialized';
  static String _key(String topic) => 'notif_$topic';

  final SharedPreferences _prefs;
  final FirebaseMessaging _fm;
  final _controller = StreamController<NoticeMessage>.broadcast();
  StreamSubscription<RemoteMessage>? _sub;
  String? _problem;

  @override
  String? get problem => _problem;

  void _setProblem(String? p) {
    if (_problem == p) return;
    _problem = p;
    notifyListeners();
  }

  static String _short(Object e) {
    final s = e.toString().replaceAll('\n', ' ');
    return s.length > 140 ? '${s.substring(0, 140)}…' : s;
  }

  static Future<FirebaseNoticeSettings> create() async =>
      FirebaseNoticeSettings(await SharedPreferences.getInstance());

  @override
  bool isEnabled(String topic) => _prefs.getBool(_key(topic)) ?? false;

  Future<bool> _requestPermission() async {
    final s = await _fm.requestPermission();
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<bool> setEnabled(String topic, bool enabled) async {
    try {
      if (enabled) {
        if (!await _requestPermission()) return false;
        await _fm.subscribeToTopic(topic);
      } else {
        await _fm.unsubscribeFromTopic(topic);
      }
      await _prefs.setBool(_key(topic), enabled);
      _setProblem(null);
      notifyListeners();
      return true;
    } catch (e) {
      _setProblem('Bildirim ayarı kaydedilemedi: ${_short(e)}');
      return false;
    }
  }

  @override
  Future<void> start() async {
    _sub ??= FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n == null) return;
      _controller.add(
        NoticeMessage(
          topic: m.data['topic'] as String? ?? '',
          title: n.title ?? '',
          body: n.body ?? '',
        ),
      );
    });

    try {
      if (!(_prefs.getBool(_initKey) ?? false)) {
        // İlk açılış: izin iste, verilirse varsayılan konulara abone ol.
        final granted = await _requestPermission();
        for (final t in NoticeTopics.all) {
          final on = granted && NoticeTopics.defaultOn.contains(t);
          if (on) await _fm.subscribeToTopic(t);
          await _prefs.setBool(_key(t), on);
        }
        await _prefs.setBool(_initKey, true);
        if (!granted) _setProblem('Bildirim izni verilmedi.');
      } else {
        // Sonraki açılışlar: abonelikleri tazele (telefon değişikliği/yeniden kurulum sonrası sağlamlık).
        for (final t in NoticeTopics.all) {
          if (isEnabled(t)) await _fm.subscribeToTopic(t);
        }
      }
      notifyListeners();
    } catch (e) {
      // Ağ yoksa tercihler olduğu gibi kalır; bir sonraki açılışta tekrar denenir.
      _setProblem('Bildirim kaydı yapılamadı: ${_short(e)}');
    }
  }

  @override
  Stream<NoticeMessage> get foreground => _controller.stream;

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
    super.dispose();
  }
}
