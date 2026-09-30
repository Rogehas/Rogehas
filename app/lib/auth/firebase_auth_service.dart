import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

/// Firebase Authentication (e-posta + şifre) ile üyelik.
class FirebaseAuthService extends AuthService {
  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance {
    _sub = _auth.userChanges().listen((_) => notifyListeners());
  }

  final FirebaseAuth _auth;
  late final StreamSubscription<User?> _sub;

  @override
  bool get available => true;

  @override
  AuthUser? get user {
    final u = _auth.currentUser;
    if (u == null) return null;
    final name = (u.displayName ?? '').trim();
    final email = u.email ?? '';
    return AuthUser(
      uid: u.uid,
      name: name.isNotEmpty ? name : email.split('@').first,
      email: email,
    );
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(turkishAuthError(e.code));
    } catch (_) {
      throw const AuthFailure(
        'Bir sorun oluştu. İnternetini kontrol edip tekrar dene.',
      );
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(() async {
        await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
      });

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) => _guard(() async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(name.trim());
    await cred.user?.reload();
    notifyListeners();
  });

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> deleteAccount({
    required String password,
    Future<void> Function(AuthUser user)? beforeDelete,
  }) => _guard(() async {
    final u = _auth.currentUser;
    final email = u?.email;
    final me = user;
    if (u == null || email == null || me == null) return;
    await u.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: email, password: password),
    );
    await beforeDelete?.call(me);
    await u.delete();
  });

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Firebase hata kodlarını sade Türkçeye çevirir.
String turkishAuthError(String code) => switch (code) {
  'invalid-email' => 'E-posta adresi geçersiz.',
  'user-not-found' ||
  'wrong-password' ||
  'invalid-credential' ||
  'invalid-login-credentials' => 'E-posta veya şifre yanlış.',
  'email-already-in-use' => 'Bu e-posta ile zaten bir hesap var. Giriş yap.',
  'weak-password' => 'Şifre çok zayıf. En az 6 karakter kullan.',
  'too-many-requests' =>
    'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.',
  'network-request-failed' => 'İnternet bağlantısı yok.',
  'user-disabled' => 'Bu hesap kapatılmış.',
  'operation-not-allowed' => 'E-posta ile giriş şu an açık değil.',
  _ => 'İşlem başarısız oldu. Tekrar dene.',
};
