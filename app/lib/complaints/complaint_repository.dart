import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../auth/auth_service.dart';

const complaintCategories = <String>[
  'Yol ve kaldırım',
  'Temizlik ve çöp',
  'Su ve kanalizasyon',
  'Aydınlatma',
  'Park ve bahçe',
  'Ulaşım',
  'Öneri',
  'Diğer',
];

const minComplaintLength = 10;
const maxComplaintLength = 1000;

enum ComplaintStatus {
  newOne('Alındı'),
  progress('İnceleniyor'),
  resolved('Çözüldü'),
  closed('Kapatıldı');

  const ComplaintStatus(this.label);
  final String label;

  /// Firestore'da saklanan ad.
  String get key => switch (this) {
    ComplaintStatus.newOne => 'new',
    ComplaintStatus.progress => 'progress',
    ComplaintStatus.resolved => 'resolved',
    ComplaintStatus.closed => 'closed',
  };

  static ComplaintStatus parse(String? key) => ComplaintStatus.values
      .firstWhere((s) => s.key == key, orElse: () => ComplaintStatus.newOne);
}

class Complaint {
  const Complaint({
    required this.id,
    required this.category,
    required this.neighborhood,
    required this.text,
    required this.status,
    required this.reply,
    required this.at,
  });
  final String id;
  final String category;
  final String neighborhood;
  final String text;
  final ComplaintStatus status;

  /// Belediye/yönetici yanıtı; yoksa boş.
  final String reply;
  final DateTime? at;
}

/// Gönderilebilir ise null; değilse kullanıcıya gösterilecek neden.
String? validateComplaint({required String category, required String text}) {
  if (!complaintCategories.contains(category)) return 'Bir konu seç.';
  final t = text.trim();
  if (t.length < minComplaintLength) {
    return 'Biraz daha ayrıntı yaz (en az $minComplaintLength karakter).';
  }
  if (t.length > maxComplaintLength) {
    return 'En fazla $maxComplaintLength karakter yazabilirsin.';
  }
  return null;
}

class ComplaintFailure implements Exception {
  const ComplaintFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class ComplaintRepository {
  /// Üyenin kendi gönderdikleri, en yeni başta.
  Stream<List<Complaint>> watchMine(String uid);
  Future<void> submit(
    AuthUser user, {
    required String category,
    required String neighborhood,
    required String text,
  });
}

class FirestoreComplaintRepository implements ComplaintRepository {
  FirestoreComplaintRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  @override
  Stream<List<Complaint>> watchMine(String uid) {
    return _db
        .collection('complaints')
        .where('uid', isEqualTo: uid)
        .snapshots()
        .map((s) {
          final list = [
            for (final d in s.docs)
              Complaint(
                id: d.id,
                category: (d.data()['category'] as String?) ?? '',
                neighborhood: (d.data()['neighborhood'] as String?) ?? '',
                text: (d.data()['text'] as String?) ?? '',
                status: ComplaintStatus.parse(d.data()['status'] as String?),
                reply: (d.data()['reply'] as String?) ?? '',
                at: (d.data()['createdAt'] as Timestamp?)?.toDate(),
              ),
          ];
          // Sunucu saati henüz yazılmamış (yeni) kayıt en üstte kalır.
          list.sort(
            (a, b) =>
                (b.at ?? DateTime.now()).compareTo(a.at ?? DateTime.now()),
          );
          return list;
        });
  }

  @override
  Future<void> submit(
    AuthUser user, {
    required String category,
    required String neighborhood,
    required String text,
  }) async {
    try {
      await _db.collection('complaints').add({
        'uid': user.uid,
        'name': user.name,
        'email': user.email,
        'category': category,
        'neighborhood': neighborhood.trim(),
        'text': text.trim(),
        'status': ComplaintStatus.newOne.key,
        'reply': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException {
      throw const ComplaintFailure(
        'Gönderilemedi. İnternetini kontrol edip tekrar dene.',
      );
    }
  }
}

/// Denemeler ve testler için bellekte çalışan şikâyet kutusu.
class InMemoryComplaintRepository implements ComplaintRepository {
  final List<({String uid, Complaint complaint})> _all = [];
  final _changes = StreamController<void>.broadcast();
  int _n = 0;

  @override
  Stream<List<Complaint>> watchMine(String uid) async* {
    List<Complaint> mine() => [
      for (final e in _all.reversed)
        if (e.uid == uid) e.complaint,
    ];
    yield mine();
    await for (final _ in _changes.stream) {
      yield mine();
    }
  }

  @override
  Future<void> submit(
    AuthUser user, {
    required String category,
    required String neighborhood,
    required String text,
  }) async {
    _all.add((
      uid: user.uid,
      complaint: Complaint(
        id: 'c${++_n}',
        category: category,
        neighborhood: neighborhood.trim(),
        text: text.trim(),
        status: ComplaintStatus.newOne,
        reply: '',
        at: DateTime(2026, 10, 1, 9, 30),
      ),
    ));
    _changes.add(null);
  }

  /// Testlerde yönetici yanıtını taklit eder.
  void respond(String id, ComplaintStatus status, String reply) {
    for (var i = 0; i < _all.length; i++) {
      final c = _all[i].complaint;
      if (c.id == id) {
        _all[i] = (
          uid: _all[i].uid,
          complaint: Complaint(
            id: c.id,
            category: c.category,
            neighborhood: c.neighborhood,
            text: c.text,
            status: status,
            reply: reply,
            at: c.at,
          ),
        );
      }
    }
    _changes.add(null);
  }
}

class ComplaintScope extends InheritedWidget {
  const ComplaintScope({
    super.key,
    required this.repository,
    required super.child,
  });
  final ComplaintRepository repository;

  static ComplaintRepository of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<ComplaintScope>();
    assert(s != null, 'ComplaintScope bulunamadı');
    return s!.repository;
  }

  @override
  bool updateShouldNotify(ComplaintScope old) => repository != old.repository;
}
