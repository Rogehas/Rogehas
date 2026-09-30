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

  /// İlk açılışta izin verilirse açılacak konular (haber çok sık olabilir, kapalı başlar).
  static const defaultOn = [vefat, duyuru, kesinti];
}

/// Bildirim tercihleri. Gerçek sürüm Firebase Cloud Messaging konularına abone olur.
abstract class NoticeSettings extends ChangeNotifier {
  bool isEnabled(String topic);

  /// Konuyu açar/kapatır. Açarken bildirim izni reddedilirse `false` döner ve konu açılmaz.
  Future<bool> setEnabled(String topic, bool enabled);

  /// İlk açılışta izin ister ve varsayılan konulara abone olur; sonraki açılışlarda abonelikleri tazeler.
  Future<void> start();

  /// Uygulama açıkken gelen bildirimler.
  Stream<NoticeMessage> get foreground;
}

/// Firebase'siz çalışma (testler, tanıtım sürümü): tercihler bellekte tutulur, bildirim gelmez.
class InMemoryNoticeSettings extends NoticeSettings {
  InMemoryNoticeSettings({this.grantPermission = true});

  /// `false` ise izin reddedilmiş gibi davranır (test için).
  final bool grantPermission;

  final Set<String> _on = {...NoticeTopics.defaultOn};
  final _controller = StreamController<NoticeMessage>.broadcast();

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

  /// Testlerde "uygulama açıkken bildirim geldi" durumunu taklit eder.
  void simulateForeground(NoticeMessage m) => _controller.add(m);

  @override
  void dispose() {
    _controller.close();
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
