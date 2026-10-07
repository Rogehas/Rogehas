import 'dart:async';

import 'package:flutter/widgets.dart';

import '../widgets/url_opener.dart';
import 'ad_models.dart';
import 'ad_repository.dart';

/// Reklam durumunu tutar: hangi yerde hangi reklam görünür, gösterim/tıklama sayaçları.
class AdController extends ChangeNotifier {
  AdController(
    this._repo, {
    this.launch = 0,
    this.opener = defaultOpen,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _sub = _repo.watch().listen((s) {
      _state = s;
      notifyListeners();
    }, onError: (_) {});
  }

  final AdRepository _repo;
  final DateTime Function() _clock;

  /// Uygulamanın kaçıncı açılışı; reklamlar bununla sırayla döner.
  final int launch;
  final UrlOpener opener;
  late final StreamSubscription<AdsState> _sub;
  AdsState _state = const AdsState();
  final _counted = <String>{};
  final _closed = <AdPlacement>{};

  /// [placement] için şu an gösterilecek reklam; yoksa null (hiçbir şey çizilmez).
  AdItem? adFor(AdPlacement placement) {
    if (_closed.contains(placement)) return null;
    return pickAd(eligibleAds(_state, placement, _clock()), launch);
  }

  /// Aynı reklam aynı yerde bir uygulama oturumunda yalnızca bir kez sayılır.
  void trackImpression(AdItem ad, AdPlacement placement) {
    if (_counted.add('${ad.id}|${placement.name}')) {
      unawaited(_repo.record(ad.id, click: false));
    }
  }

  void trackClick(AdItem ad) => unawaited(_repo.record(ad.id, click: true));

  /// Kullanıcı şeridi kapattı: bu oturumda o yerde bir daha gösterilmez.
  void close(AdPlacement placement) {
    _closed.add(placement);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
