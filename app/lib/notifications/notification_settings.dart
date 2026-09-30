import 'dart:async';

import 'package:flutter/widgets.dart';

/// Uygulama açıkken gelen bildirim (telefon bildirim çubuğunda görünmez, uygulama içinde gösterilir).
class NoticeMessage {
  const NoticeMessage({
    required this.topic,
    required this.title,
    required this.body,
  });
  final String topic;
  final String title;
  final String body;
}

/// Bildirim konuları ve varsayılanları. Konu adları sunucu kodundaki (functions/notify.js) ile aynıdır.
class NoticeTopics {
  static const vefat = 'vefat';
  static const haber = 'haber';
  static const duyuru = 'duyuru';
  static const kesinti = 'kesinti';

  static const all = [vefat, haber, duyuru, kesinti];

  /// İlk açılışta izin verilirse açılacak konular. Haber bildirimi yalnızca editör
  /// "bildirim gönder" dediğinde gittiği için hepsi açık başlar; kullanıcı kapatabilir.
  static const defaultOn = [vefat, haber, duyuru, kesinti];

  static const labels = {
    vefat: 'Vefat ilanları',
    haber: 'Haberler',
    duyuru: 'Duyurular',
    kesinti: 'Kesintiler (su, elektrik)',
  };
}

/// Tercih şeması: 1 = yalnızca vefat anahtarı vardı (haber hiç seçilemiyordu, hep kapalıydı),
/// 2 = dört konu da ayarlanabilir ve haber varsayılan açık.
const noticePrefsSchema = 2;

/// Eski kurulumları yeni şemaya taşır: haber konusu hiç seçilemediği için "kapalı" olması
/// bir tercih değildi. Bildirim izni verilmiş kullanıcılarda (başka bir konu açık) haber de açılır.
Map<String, bool> migrateTopicPrefs(Map<String, bool> stored, int schema) {
  if (schema >= noticePrefsSchema) return stored;
  final permissionLikelyGranted = stored.values.any((v) => v);
  return {...stored, if (permissionLikelyGranted) NoticeTopics.haber: true};
}

/// Bildirim tercihleri. Gerçek sürüm Firebase Cloud Messaging konularına abone olur.
abstract class NoticeSettings extends ChangeNotifier {
  bool isEnabled(String topic);

  /// Bildirimlerin neden çalışmadığını açıklayan kısa mesaj (yoksa `null`).
  String? get problem => null;

  /// Konuyu açar/kapatır. Açarken bildirim izni reddedilirse `false` döner ve konu açılmaz.
  Future<bool> setEnabled(String topic, bool enabled);

  /// İlk açılışta izin ister ve varsayılan konulara abone olur; sonraki açılışlarda abonelikleri tazeler.
  Future<void> start();

  /// Uygulama açıkken gelen bildirimler.
  Stream<NoticeMessage> get foreground;

  /// Kullanıcı telefondaki bildirime dokunup uygulamayı açtığında (arka plandan ya da kapalıyken).
  Stream<NoticeMessage> get opened;
}

/// Firebase'siz çalışma (testler, tanıtım sürümü): tercihler bellekte tutulur, bildirim gelmez.
class InMemoryNoticeSettings extends NoticeSettings {
  InMemoryNoticeSettings({this.grantPermission = true, this.initialProblem});

  final String? initialProblem;

  @override
  String? get problem => initialProblem;

  /// `false` ise izin reddedilmiş gibi davranır (test için).
  final bool grantPermission;

  final Set<String> _on = {...NoticeTopics.defaultOn};
  final _controller = StreamController<NoticeMessage>.broadcast();
  final _openedController = StreamController<NoticeMessage>.broadcast();

  @override
  bool isEnabled(String topic) => _on.contains(topic);

  @override
  Future<bool> setEnabled(String topic, bool enabled) async {
    if (enabled && !grantPermission) return false;
    enabled ? _on.add(topic) : _on.remove(topic);
    notifyListeners();
    return true;
  }

  @override
  Future<void> start() async {}

  @override
  Stream<NoticeMessage> get foreground => _controller.stream;

  @override
  Stream<NoticeMessage> get opened => _openedController.stream;

  /// Testlerde "uygulama açıkken bildirim geldi" durumunu taklit eder.
  void simulateForeground(NoticeMessage m) => _controller.add(m);

  /// Testlerde "bildirime dokunuldu" durumunu taklit eder.
  void simulateOpened(NoticeMessage m) => _openedController.add(m);

  @override
  void dispose() {
    _controller.close();
    _openedController.close();
    super.dispose();
  }
}

class NotificationScope extends InheritedWidget {
  const NotificationScope({
    super.key,
    required this.settings,
    required super.child,
  });
  final NoticeSettings settings;

  static NoticeSettings of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<NotificationScope>();
    assert(scope != null, 'NotificationScope bulunamadı');
    return scope!.settings;
  }

  @override
  bool updateShouldNotify(NotificationScope old) => settings != old.settings;
}
