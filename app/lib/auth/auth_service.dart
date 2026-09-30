import 'dart:async';

import 'package:flutter/widgets.dart';

/// Giriş yapmış üye.
class AuthUser {
  const AuthUser({required this.uid, required this.name, required this.email});
  final String uid;
  final String name;
  final String email;
}

/// Kullanıcıya gösterilebilir Türkçe hata.
class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Form alanlarının ön doğrulaması (sunucuya gitmeden). Sorun yoksa null.
String? validateSignUp({
  required String name,
  required String email,
  required String password,
}) {
  if (name.trim().length < 2) return 'Adını yaz (en az 2 harf).';
  if (name.trim().length > 30) return 'Ad en fazla 30 karakter olabilir.';
  return validateSignIn(email: email, password: password, minPassword: 6);
}

String? validateSignIn({
  required String email,
  required String password,
  int minPassword = 1,
}) {
  final e = email.trim();
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
    return 'Geçerli bir e-posta adresi yaz.';
  }
  if (password.length < minPassword) {
    return minPassword > 1
        ? 'Şifre en az $minPassword karakter olmalı.'
        : 'Şifreni yaz.';
  }
  return null;
}

/// Üyelik işlemleri. Sohbet gibi giriş gerektiren bölümler bunu kullanır.
abstract class AuthService extends ChangeNotifier {
  /// Firebase kurulu değilse false: üyelik ekranı "şu an kullanılamıyor" der.
  bool get available;
  AuthUser? get user;
  Future<void> signIn({required String email, required String password});
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);

  /// Şifreyle kimliği doğrular, [beforeDelete] işini (ör. mesajları silmek) yapar, sonra hesabı siler.
  Future<void> deleteAccount({
    required String password,
    Future<void> Function(AuthUser user)? beforeDelete,
  });
}

/// Denemeler ve testler için bellekte çalışan üyelik.
class InMemoryAuthService extends AuthService {
  InMemoryAuthService({this.available = true});

  @override
  final bool available;
  final Map<String, ({String uid, String name, String password})> _accounts =
      {};
  AuthUser? _user;
  int _n = 0;

  /// Son gönderilen şifre sıfırlama e-postası (test için).
  String? lastResetEmail;
  final List<String> deleted = [];

  @override
  AuthUser? get user => _user;

  @override
  Future<void> signIn({required String email, required String password}) async {
    final a = _accounts[email.trim().toLowerCase()];
    if (a == null || a.password != password) {
      throw const AuthFailure('E-posta veya şifre yanlış.');
    }
    _user = AuthUser(
      uid: a.uid,
      name: a.name,
      email: email.trim().toLowerCase(),
    );
    notifyListeners();
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthFailure('Bu e-posta ile zaten bir hesap var. Giriş yap.');
    }
    final uid = 'u${++_n}';
    _accounts[key] = (uid: uid, name: name.trim(), password: password);
    _user = AuthUser(uid: uid, name: name.trim(), email: key);
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    lastResetEmail = email.trim();
  }

  @override
  Future<void> deleteAccount({
    required String password,
    Future<void> Function(AuthUser user)? beforeDelete,
  }) async {
    final u = _user;
    if (u == null) return;
    final a = _accounts[u.email];
    if (a == null || a.password != password) {
      throw const AuthFailure('Şifre yanlış.');
    }
    await beforeDelete?.call(u);
    _accounts.remove(u.email);
    deleted.add(u.uid);
    _user = null;
    notifyListeners();
  }
}

/// Üyelik durumunu ağaca taşır; durum değişince bağımlı ekranlar yenilenir.
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({
    super.key,
    required AuthService service,
    required super.child,
  }) : super(notifier: service);

  static AuthService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope bulunamadı');
    return scope!.notifier!;
  }
}
