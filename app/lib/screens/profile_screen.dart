import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../chat/chat_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/notice_prefs.dart';
import 'auth_screen.dart';

/// Profil sekmesi: üyelik, bildirim tercihleri ve uygulama bilgisi.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(28),
      boxShadow: AppTheme.cardShadow,
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          Text('Profil', style: AppTheme.display(36)),
          const SizedBox(height: 16),
          _card(child: const _AccountSection()),
          const SizedBox(height: 16),
          const _BlockedSection(),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bildirimler', style: AppTheme.display(22)),
                const SizedBox(height: 4),
                const Text(
                  'Hangi konularda telefonuna bildirim gelsin?',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                const NoticePrefsList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tavas',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  "Tavas'a ait haber, duyuru, vefat ilanı, nöbetçi eczane, etkinlik, rehber, yerel esnaf bilgileri ve genel sohbet.",
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection();

  Future<void> _deleteAccount(BuildContext context) async {
    final auth = AuthScope.of(context);
    final chat = ChatScope.of(context).repository;
    final messenger = ScaffoldMessenger.of(context);
    final user = auth.user;
    if (user == null) return;
    final password = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteDialog(),
    );
    if (password == null) return;
    try {
      // Kimlik doğrulanınca önce mesajlar silinir (giriş açıkken), sonra hesap.
      await auth.deleteAccount(
        password: password,
        beforeDelete: (u) => chat.deleteAllOf(u.uid),
      );
      messenger.showSnackBar(const SnackBar(content: Text('Hesabın silindi.')));
    } on AuthFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.user;
    final Widget actions;
    if (user == null) {
      actions = Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<bool>(
                  builder: (_) => const AuthScreen(mode: AuthMode.signIn),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Giriş yap / Üye ol'),
            ),
          ),
        ],
      );
    } else {
      actions = Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: auth.signOut,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                shape: const StadiumBorder(),
              ),
              child: const Text('Çıkış yap'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextButton(
              onPressed: () => _deleteAccount(context),
              style: TextButton.styleFrom(foregroundColor: AppColors.clay),
              child: const Text('Hesabımı sil'),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: AppColors.limeSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Misafir',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? 'Haber, vefat ilanı ve eczane için giriş gerekmez. Sohbete katılmak için üye ol.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        actions,
      ],
    );
  }
}

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog();

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hesabını sil?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Hesabın ve sohbetteki mesajların kalıcı olarak silinir. Onaylamak için şifreni yaz.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Şifre'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _password.text),
          style: TextButton.styleFrom(foregroundColor: AppColors.clay),
          child: const Text('Hesabımı sil'),
        ),
      ],
    );
  }
}

/// Engellenen kişiler (varsa): listeden kaldırılabilir.
class _BlockedSection extends StatelessWidget {
  const _BlockedSection();

  @override
  Widget build(BuildContext context) {
    final blocks = ChatScope.of(context).blocks;
    return ListenableBuilder(
      listenable: blocks,
      builder: (context, _) {
        if (blocks.all.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Engellenenler', style: AppTheme.display(22)),
                const SizedBox(height: 8),
                for (final e in blocks.all.entries)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () => blocks.unblock(e.key),
                        child: const Text('Engeli kaldır'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
