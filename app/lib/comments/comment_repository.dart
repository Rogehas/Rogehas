import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../auth/auth_service.dart';
import '../chat/chat_logic.dart';

const maxCommentLength = 300;
const commentCooldown = Duration(seconds: 3);

class Comment {
  const Comment({
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
  final DateTime? at;
}

/// Gönderilebilir yorum ise null; değilse kullanıcıya gösterilecek neden.
String? validateComment(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return 'Boş yorum gönderilemez.';
  if (t.length > maxCommentLength) {
    return 'Yorum en fazla $maxCommentLength karakter olabilir.';
  }
  if (containsBlockedWord(t)) {
    return 'Yorumunda uygunsuz bir ifade var. Lütfen saygılı bir dil kullan.';
  }
  return null;
}

class CommentFailure implements Exception {
  const CommentFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class CommentRepository {
  /// Haberin gizlenmemiş yorumları, en yeni başta.
  Stream<List<Comment>> watch(String newsId);
  Future<void> send(AuthUser user, String newsId, String text);
  Future<void> delete(String id);
  Future<void> report(AuthUser reporter, String newsId, Comment c);
}

class FirestoreCommentRepository implements CommentRepository {
  FirestoreCommentRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  @override
  Stream<List<Comment>> watch(String newsId) {
    // Gizli yorumlar kurallar gereği yalnızca moderatöre açıktır; filtre sorguda da olmalı.
    return _db
        .collection('comments')
        .where('newsId', isEqualTo: newsId)
        .where('hidden', isEqualTo: false)
        .snapshots()
        .map((s) {
          final list = [
            for (final d in s.docs)
              Comment(
                id: d.id,
                uid: (d.data()['uid'] as String?) ?? '',
                name: (d.data()['name'] as String?) ?? 'Üye',
                text: (d.data()['text'] as String?) ?? '',
                at: (d.data()['createdAt'] as Timestamp?)?.toDate(),
              ),
          ];
          final now = DateTime.now();
          list.sort((a, b) => (b.at ?? now).compareTo(a.at ?? now));
          return list;
        });
  }

  @override
  Future<void> send(AuthUser user, String newsId, String text) async {
    try {
      await _db.collection('comments').add({
        'newsId': newsId,
        'uid': user.uid,
        'name': user.name,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'hidden': false,
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const CommentFailure(
          'Yorum gönderilemedi. Yorumlar kapatılmış ya da hesabın susturulmuş olabilir.',
        );
      }
      throw const CommentFailure(
        'Yorum gönderilemedi. İnternetini kontrol et.',
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _db.collection('comments').doc(id).delete();
    } on FirebaseException {
      throw const CommentFailure('Yorum silinemedi.');
    }
  }

  @override
  Future<void> report(AuthUser reporter, String newsId, Comment c) async {
    try {
      await _db.collection('chatReports').doc('${reporter.uid}_${c.id}').set({
        'messageId': c.id,
        'messageUid': c.uid,
        'messageName': c.name,
        'text': c.text,
        'reporterUid': reporter.uid,
        'reason': 'uygunsuz',
        'handled': false,
        'source': 'comment',
        'newsId': newsId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const CommentFailure('Bu yorumu zaten bildirdin.');
      }
      throw const CommentFailure('Bildirilemedi. İnternetini kontrol et.');
    }
  }
}

/// Denemeler ve testler için bellekte çalışan yorumlar.
class InMemoryCommentRepository implements CommentRepository {
  final List<(String newsId, Comment c)> _all = [];
  final List<(String reporter, String commentId)> reports = [];
  final _changes = StreamController<void>.broadcast();
  int _n = 0;

  void seed(String newsId, String uid, String name, String text) {
    _all.add((
      newsId,
      Comment(
        id: 'k${++_n}',
        uid: uid,
        name: name,
        text: text,
        at: DateTime(2026, 10, 2, 10, 15),
      ),
    ));
    _changes.add(null);
  }

  @override
  Stream<List<Comment>> watch(String newsId) async* {
    List<Comment> now() => [
      for (final e in _all.reversed)
        if (e.$1 == newsId) e.$2,
    ];
    yield now();
    await for (final _ in _changes.stream) {
      yield now();
    }
  }

  @override
  Future<void> send(AuthUser user, String newsId, String text) async {
    seed(newsId, user.uid, user.name, text.trim());
  }

  @override
  Future<void> delete(String id) async {
    _all.removeWhere((e) => e.$2.id == id);
    _changes.add(null);
  }

  @override
  Future<void> report(AuthUser reporter, String newsId, Comment c) async {
    if (reports.any((r) => r.$1 == reporter.uid && r.$2 == c.id)) {
      throw const CommentFailure('Bu yorumu zaten bildirdin.');
    }
    reports.add((reporter.uid, c.id));
  }
}

class CommentScope extends InheritedWidget {
  const CommentScope({
    super.key,
    required this.repository,
    required super.child,
  });
  final CommentRepository repository;

  static CommentRepository of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<CommentScope>();
    assert(s != null, 'CommentScope bulunamadı');
    return s!.repository;
  }

  @override
  bool updateShouldNotify(CommentScope old) => repository != old.repository;
}
