import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import '../auth/auth_service.dart';

/// Panelin "Üyeler" sayfası için üye kaydı: ad, e-posta, kayıt tarihi.
abstract class MemberRegistry {
  /// Kayıt yoksa oluşturur, ad değişmişse günceller. Hata verirse sessizce geçer.
  Future<void> ensure(AuthUser user);
}

class FirestoreMemberRegistry implements MemberRegistry {
  FirestoreMemberRegistry({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  @override
  Future<void> ensure(AuthUser user) async {
    try {
      final ref = _db.collection('members').doc(user.uid);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'name': user.name,
          'email': user.email,
          'createdAt': Timestamp.fromDate(user.createdAt ?? DateTime.now()),
        });
      } else if (snap.data()?['name'] != user.name) {
        await ref.update({'name': user.name});
      }
    } on FirebaseException {
      // Kayıt yazılamadıysa bir sonraki açılışta yeniden denenir.
    }
  }
}

/// Denemeler ve testler için bellekte çalışan kayıt.
class InMemoryMemberRegistry implements MemberRegistry {
  final Map<String, AuthUser> members = {};

  @override
  Future<void> ensure(AuthUser user) async => members[user.uid] = user;
}

/// Giriş yapan üyeyi kayda geçirir (uygulama açılışında ve girişte).
class MemberSync extends StatefulWidget {
  const MemberSync({
    super.key,
    required this.registry,
    required this.auth,
    required this.child,
  });
  final MemberRegistry registry;
  final AuthService auth;
  final Widget child;

  @override
  State<MemberSync> createState() => _MemberSyncState();
}

class _MemberSyncState extends State<MemberSync> {
  String? _last;

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_sync);
    _sync();
  }

  @override
  void dispose() {
    widget.auth.removeListener(_sync);
    super.dispose();
  }

  void _sync() {
    final u = widget.auth.user;
    final key = u == null ? null : '${u.uid}|${u.name}';
    if (key == null || key == _last) return;
    _last = key;
    widget.registry.ensure(u!);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
