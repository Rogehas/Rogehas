import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'ad_models.dart';

/// Reklamların sunucu tarafı. Hata olursa reklam gösterilmez (sessizce).
abstract class AdRepository {
  Stream<AdsState> watch();

  /// Gösterim ya da tıklama sayacını 1 artırır. Hata verirse yutulur.
  Future<void> record(String adId, {required bool click});
}

DateTime? _day(Object? v) {
  if (v is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return null;
  return DateTime.tryParse(v);
}

AdItem? adFromMap(String id, Map<String, dynamic> m) {
  final action = switch (m['action']) {
    'call' => AdAction.call,
    'map' => AdAction.map,
    'web' => AdAction.web,
    _ => null,
  };
  final name = (m['name'] as String? ?? '').trim();
  if (action == null || name.isEmpty) return null;
  final placements = <AdPlacement>{
    for (final p in (m['placements'] as List? ?? const []))
      for (final v in AdPlacement.values)
        if (v.name == p) v,
  };
  final photo = m['photo'];
  return AdItem(
    id: id,
    name: name,
    text: (m['text'] as String? ?? '').trim(),
    action: action,
    actionValue: (m['actionValue'] as String? ?? '').trim(),
    placements: placements,
    photoUrl: photo is String && photo.isNotEmpty ? photo : null,
    start: _day(m['startDate']),
    end: _day(m['endDate']),
    active: m['active'] as bool? ?? false,
    createdAt: DateTime.tryParse(m['createdAt'] as String? ?? ''),
  );
}

String monthKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

class FirestoreAdRepository implements AdRepository {
  FirestoreAdRepository({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  @override
  Stream<AdsState> watch() {
    final controller = StreamController<AdsState>();
    var enabled = true;
    var ads = <AdItem>[];
    void emit() => controller.add(AdsState(enabled: enabled, ads: ads));
    final subs = <StreamSubscription<Object?>>[];
    subs.add(
      _db.collection('settings').doc('ads').snapshots().listen((s) {
        enabled = !s.exists || s.data()?['enabled'] != false;
        emit();
      }, onError: (_) {}),
    );
    subs.add(
      _db
          .collection('ads')
          .snapshots()
          .listen(
            (s) {
              ads = [for (final d in s.docs) ?adFromMap(d.id, d.data())];
              emit();
            },
            onError: (_) {
              ads = [];
              emit();
            },
          ),
    );
    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
    return controller.stream;
  }

  @override
  Future<void> record(String adId, {required bool click}) async {
    final month = monthKey(DateTime.now());
    try {
      await _db.collection('adStats').doc('${adId}_$month').set({
        'adId': adId,
        'month': month,
        click ? 'clicks' : 'impressions': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (_) {
      // Sayaç yazılamadıysa kullanıcı etkilenmesin.
    }
  }
}

/// Testler ve reklamsız çalışma için bellekte reklam kaynağı.
class InMemoryAdRepository implements AdRepository {
  InMemoryAdRepository([AdsState initial = const AdsState()])
    : _state = initial;
  AdsState _state;
  final _c = StreamController<AdsState>.broadcast();

  /// Kaydedilen sayaç olayları: (reklam kimliği, tıklama mı).
  final List<(String, bool)> recorded = [];

  void setState(AdsState s) {
    _state = s;
    _c.add(s);
  }

  @override
  Stream<AdsState> watch() async* {
    yield _state;
    yield* _c.stream;
  }

  @override
  Future<void> record(String adId, {required bool click}) async =>
      recorded.add((adId, click));
}
