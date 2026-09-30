import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'content_mapper.dart';
import 'duty_logic.dart';
import 'models.dart';

/// Uygulamanın içerik kaynağı. Gerçek sürüm Firestore'dur; testlerde sahte sürüm kullanılır.
abstract class ContentRepository {
  Stream<List<NewsItem>> watchNews();
  Stream<List<VefatItem>> watchVefat();
  Stream<List<Pharmacy>> watchPharmacies();
  Stream<List<DutyDay>> watchDuty();
  Stream<List<EventItem>> watchEvents();
  Stream<List<GuideEntry>> watchGuide();
  Stream<List<Business>> watchBusinesses();
}

/// Yalnızca `status == published` belgeleri okur (güvenlik kuralları misafire yalnızca bunu açar).
class FirestoreContentRepository implements ContentRepository {
  FirestoreContentRepository([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  Stream<List<T>> _published<T>(
    String collection,
    T Function(Map<String, dynamic>) map,
  ) {
    return _db
        .collection(collection)
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snap) {
          final docs = snap.docs.map((d) => d.data()).toList()
            ..sort(
              (a, b) =>
                  ContentMapper.publishedAt(b)
                      .compareTo(ContentMapper.publishedAt(a)),
            );
          return docs.map(map).toList();
        });
  }

  @override
  Stream<List<NewsItem>> watchNews() => _published('news', ContentMapper.news);

  @override
  Stream<List<VefatItem>> watchVefat() =>
      _published('vefat', ContentMapper.vefat);

  @override
  Stream<List<Pharmacy>> watchPharmacies() {
    return _db.collection('pharmacies').snapshots().map((snap) {
      final list = [
        for (final d in snap.docs) ?ContentMapper.pharmacy(d.id, d.data()),
      ]..sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  /// `published == true` olanlar (güvenlik kuralları misafire yalnızca bunu açar).
  Stream<List<T>> _visible<T>(
    String collection,
    T? Function(String id, Map<String, dynamic> data) map,
  ) {
    return _db
        .collection(collection)
        .where('published', isEqualTo: true)
        .snapshots()
        .map((snap) => [for (final d in snap.docs) ?map(d.id, d.data())]);
  }

  @override
  Stream<List<EventItem>> watchEvents() =>
      _visible('events', ContentMapper.event);

  @override
  Stream<List<GuideEntry>> watchGuide() =>
      _visible('guide', ContentMapper.guide);

  @override
  Stream<List<Business>> watchBusinesses() =>
      _visible('businesses', ContentMapper.business);

  /// Dünden itibaren nöbet günleri (09:00'dan önce hâlâ dünün nöbeti sürer).
  @override
  Stream<List<DutyDay>> watchDuty() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - 1);
    final key = dutyDateKey(from);
    return _db
        .collection('duty')
        .where('date', isGreaterThanOrEqualTo: key)
        .snapshots()
        .map(
          (snap) => [for (final d in snap.docs) ?ContentMapper.duty(d.data())],
        );
  }
}

/// Firebase başlatılamazsa: sahte veri göstermek yerine hata bildirir.
class UnavailableContentRepository implements ContentRepository {
  UnavailableContentRepository(this.error);
  final Object error;

  @override
  Stream<List<NewsItem>> watchNews() => Stream.error(error);

  @override
  Stream<List<VefatItem>> watchVefat() => Stream.error(error);

  @override
  Stream<List<Pharmacy>> watchPharmacies() => Stream.error(error);

  @override
  Stream<List<DutyDay>> watchDuty() => Stream.error(error);

  @override
  Stream<List<EventItem>> watchEvents() => Stream.error(error);

  @override
  Stream<List<GuideEntry>> watchGuide() => Stream.error(error);

  @override
  Stream<List<Business>> watchBusinesses() => Stream.error(error);
}

/// Bir akışa tek kez abone olur, son değeri/hatayı saklar ve ekranlara paylaştırır
/// (her ekran yeniden çizilişinde Firestore'a yeniden abone olunmasın diye).
class Shared<T> {
  Shared(Stream<T> source) {
    _sub = source.listen(
      (v) {
        latest = v;
        error = null;
        _c.add(v);
      },
      onError: (Object e) {
        error = e;
        _c.addError(e);
      },
    );
  }

  late final StreamSubscription<T> _sub;
  final _c = StreamController<T>.broadcast();
  T? latest;
  Object? error;

  Stream<T> get stream => _c.stream;

  void dispose() {
    _sub.cancel();
    _c.close();
  }
}

class ContentHub {
  ContentHub(ContentRepository repo)
    : news = Shared(repo.watchNews()),
      vefat = Shared(repo.watchVefat()),
      pharmacies = Shared(repo.watchPharmacies()),
      duty = Shared(repo.watchDuty()),
      events = Shared(repo.watchEvents()),
      guide = Shared(repo.watchGuide()),
      businesses = Shared(repo.watchBusinesses());

  final Shared<List<NewsItem>> news;
  final Shared<List<VefatItem>> vefat;
  final Shared<List<Pharmacy>> pharmacies;
  final Shared<List<DutyDay>> duty;
  final Shared<List<EventItem>> events;
  final Shared<List<GuideEntry>> guide;
  final Shared<List<Business>> businesses;

  void dispose() {
    news.dispose();
    vefat.dispose();
    pharmacies.dispose();
    duty.dispose();
    events.dispose();
    guide.dispose();
    businesses.dispose();
  }
}

/// Widget ağacına içerik merkezini taşır.
class ContentScope extends InheritedWidget {
  const ContentScope({super.key, required this.hub, required super.child});
  final ContentHub hub;

  static ContentHub of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ContentScope>();
    assert(scope != null, 'ContentScope bulunamadı');
    return scope!.hub;
  }

  @override
  bool updateShouldNotify(ContentScope old) => hub != old.hub;
}
