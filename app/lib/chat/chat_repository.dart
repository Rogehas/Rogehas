import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_service.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.uid,
    required this.name,
    required this.text,
    required this.at,
  });
  final String id;
  final String uid;
  final String name;
  final String text;

  /// Sunucu saati; yeni gönderilen mesajda birkaç an boş olabilir.
  final DateTime? at;
}

/// Sohbetin sunucu tarafı. Uygulama yalnızca bu arayüze bağlıdır.
abstract class ChatRepository {
  /// Gizlenmemiş son mesajlar, en yeni başta.
  Stream<List<ChatMessage>> watchMessages();
  Future<void> send(AuthUser user, String text);
  Future<void> deleteMessage(String id);

  /// Bir mesajı yöneticilere bildirir. Aynı kişi aynı mesajı bir kez bildirebilir.
  Future<void> report(AuthUser reporter, ChatMessage m, String reason);

  /// Hesap silinirken kişinin tüm mesajlarını kaldırır.
  Future<void> deleteAllOf(String uid);

  /// Yönetici bu kişiyi susturduysa true olur.
  Stream<bool> watchMuted(String uid);
}

class ChatFailure implements Exception {
  const ChatFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  @override
  Stream<List<ChatMessage>> watchMessages() {
    return _db
        .collection('chat')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (s) => [
            for (final d in s.docs)
              if ((d.data()['hidden'] as bool? ?? false) == false)
                ChatMessage(
                  id: d.id,
                  uid: (d.data()['uid'] as String?) ?? '',
                  name: (d.data()['name'] as String?) ?? 'Üye',
                  text: (d.data()['text'] as String?) ?? '',
                  at: (d.data()['createdAt'] as Timestamp?)?.toDate(),
                ),
          ],
        );
  }

  @override
  Future<void> send(AuthUser user, String text) async {
    try {
      await _db.collection('chat').add({
        'uid': user.uid,
        'name': user.name,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'hidden': false,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const ChatFailure(
          'Mesaj gönderilemedi. Hesabın susturulmuş olabilir.',
        );
      }
      throw const ChatFailure('Mesaj gönderilemedi. İnternetini kontrol et.');
    }
  }

  @override
  Future<void> deleteMessage(String id) async {
    try {
      await _db.collection('chat').doc(id).delete();
    } on FirebaseException {
      throw const ChatFailure('Mesaj silinemedi.');
    }
  }

  @override
  Future<void> report(AuthUser reporter, ChatMessage m, String reason) async {
    try {
      await _db.collection('chatReports').doc('${reporter.uid}_${m.id}').set({
        'messageId': m.id,
        'messageUid': m.uid,
        'messageName': m.name,
        'text': m.text,
        'reporterUid': reporter.uid,
        'reason': reason,
        'handled': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const ChatFailure('Bu mesajı zaten bildirdin.');
      }
      throw const ChatFailure('Bildirilemedi. İnternetini kontrol et.');
    }
  }

  @override
  Future<void> deleteAllOf(String uid) async {
    final s = await _db.collection('chat').where('uid', isEqualTo: uid).get();
    for (var i = 0; i < s.docs.length; i += 400) {
      final batch = _db.batch();
      for (final d in s.docs.skip(i).take(400)) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  @override
  Stream<bool> watchMuted(String uid) => _db
      .collection('mutes')
      .doc(uid)
      .snapshots()
      .map((s) => s.exists)
      .handleError((_) {});
}

/// Denemeler ve testler için bellekte çalışan sohbet.
class InMemoryChatRepository implements ChatRepository {
  final List<ChatMessage> _all = [];
  final List<({String reporter, String messageId, String reason})> reports = [];
  final Set<String> muted = {};
  final _messages = StreamController<List<ChatMessage>>.broadcast();
  final _mutes = StreamController<void>.broadcast();
  int _n = 0;

  void _emit() => _messages.add(_snapshot());
  List<ChatMessage> _snapshot() => List.unmodifiable(_all.reversed);

  /// Testlerde başkasının mesajını eklemek için.
  void seed(String uid, String name, String text) {
    _all.add(
      ChatMessage(
        id: 'm${++_n}',
        uid: uid,
        name: name,
        text: text,
        at: DateTime(2026, 9, 30, 14, 5),
      ),
    );
    _emit();
  }

  @override
  Stream<List<ChatMessage>> watchMessages() async* {
    yield _snapshot();
    yield* _messages.stream;
  }

  @override
  Future<void> send(AuthUser user, String text) async {
    if (muted.contains(user.uid)) {
      throw const ChatFailure(
        'Mesaj gönderilemedi. Hesabın susturulmuş olabilir.',
      );
    }
    _all.add(
      ChatMessage(
        id: 'm${++_n}',
        uid: user.uid,
        name: user.name,
        text: text.trim(),
        at: DateTime(2026, 9, 30, 14, 6),
      ),
    );
    _emit();
  }

  @override
  Future<void> deleteMessage(String id) async {
    _all.removeWhere((m) => m.id == id);
    _emit();
  }

  @override
  Future<void> report(AuthUser reporter, ChatMessage m, String reason) async {
    if (reports.any((r) => r.reporter == reporter.uid && r.messageId == m.id)) {
      throw const ChatFailure('Bu mesajı zaten bildirdin.');
    }
    reports.add((reporter: reporter.uid, messageId: m.id, reason: reason));
  }

  @override
  Future<void> deleteAllOf(String uid) async {
    _all.removeWhere((m) => m.uid == uid);
    _emit();
  }

  @override
  Stream<bool> watchMuted(String uid) async* {
    yield muted.contains(uid);
    await for (final _ in _mutes.stream) {
      yield muted.contains(uid);
    }
  }

  void setMuted(String uid, bool on) {
    on ? muted.add(uid) : muted.remove(uid);
    _mutes.add(null);
  }
}

/// Bu cihazda engellenen kişiler: mesajları bu telefonda gizlenir.
class BlockList extends ChangeNotifier {
  BlockList._(this._prefs, Map<String, String> initial)
    : _blocked = {...initial};

  static const _key = 'chat_blocked';
  final SharedPreferences? _prefs;
  final Map<String, String> _blocked; // uid -> görünen ad

  static Future<BlockList> load() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, String>{};
    for (final e in prefs.getStringList(_key) ?? const <String>[]) {
      final i = e.indexOf('|');
      if (i > 0) map[e.substring(0, i)] = e.substring(i + 1);
    }
    return BlockList._(prefs, map);
  }

  /// Kalıcı depolama olmadan (testlerde) bellekte çalışır.
  BlockList.memory() : _prefs = null, _blocked = {};

  bool isBlocked(String uid) => _blocked.containsKey(uid);
  Map<String, String> get all => Map.unmodifiable(_blocked);

  Future<void> _save() async => _prefs?.setStringList(_key, [
    for (final e in _blocked.entries) '${e.key}|${e.value}',
  ]);

  Future<void> block(String uid, String name) async {
    _blocked[uid] = name;
    notifyListeners();
    await _save();
  }

  Future<void> unblock(String uid) async {
    _blocked.remove(uid);
    notifyListeners();
    await _save();
  }
}

/// Sohbet bağımlılıklarını ağaca taşır.
class ChatScope extends InheritedWidget {
  const ChatScope({
    super.key,
    required this.repository,
    required this.blocks,
    required super.child,
  });
  final ChatRepository repository;
  final BlockList blocks;

  static ChatScope of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<ChatScope>();
    assert(s != null, 'ChatScope bulunamadı');
    return s!;
  }

  @override
  bool updateShouldNotify(ChatScope old) =>
      repository != old.repository || blocks != old.blocks;
}
