import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'content_mapper.dart';
import 'models.dart';

/// Uygulamanın içerik kaynağı. Gerçek sürüm Firestore'dur; testlerde sahte sürüm kullanılır.
abstract class ContentRepository {
  Stream<List<NewsItem>> watchNews();
  Stream<List<VefatItem>> watchVefat();
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
}

/// Firebase başlatılamazsa: sahte veri göstermek yerine hata bildirir.
class UnavailableContentRepository implements ContentRepository {
  UnavailableContentRepository(this.error);
  final Object error;

  @override
  Stream<List<NewsItem>> watchNews() => Stream.error(error);

  @override
  Stream<List<VefatItem>> watchVefat() => Stream.error(error);
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
      vefat = Shared(repo.watchVefat());

  final Shared<List<NewsItem>> news;
  final Shared<List<VefatItem>> vefat;

  void dispose() {
    news.dispose();
    vefat.dispose();
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
