import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../chat/chat_logic.dart' show messageTime;
import '../chat/chat_repository.dart';
import '../comments/comment_repository.dart';
import '../screens/auth_screen.dart';
import '../theme/app_theme.dart';

/// Haber altındaki yorumlar: herkes okur, üyeler yazar.
class CommentsSection extends StatefulWidget {
  const CommentsSection({super.key, required this.newsId, required this.open});
  final String newsId;
  final bool open;

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _input = TextEditingController();
  Stream<List<Comment>>? _stream;
  CommentRepository? _repo;
  bool _sending = false;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = CommentScope.of(context);
    if (_repo != repo) {
      _repo = repo;
      _stream = widget.open ? repo.watch(widget.newsId) : null;
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _toast(String t) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(t)));

  Future<void> _send(AuthUser user) async {
    final problem = validateComment(_input.text);
    if (problem != null) return _toast(problem);
    if (DateTime.now().difference(_lastSent) < commentCooldown) {
      return _toast('Çok hızlı yazıyorsun. Birkaç saniye bekle.');
    }
    setState(() => _sending = true);
    try {
      await _repo!.send(user, widget.newsId, _input.text);
      _lastSent = DateTime.now();
      _input.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } on CommentFailure catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _more(Comment c, AuthUser? me) async {
    final mine = me != null && c.uid == me.uid;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mine)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Yorumu sil'),
                onTap: () => Navigator.pop(context, 'delete'),
              )
            else ...[
              if (me != null)
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Şikâyet et'),
                  subtitle: const Text('Yöneticilere bildirilir'),
                  onTap: () => Navigator.pop(context, 'report'),
                ),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text('${c.name} adlı kişiyi engelle'),
                subtitle: const Text('Yorumlarını bu telefonda görmezsin'),
                onTap: () => Navigator.pop(context, 'block'),
              ),
            ],
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'delete':
        try {
          await _repo!.delete(c.id);
        } on CommentFailure catch (e) {
          if (mounted) _toast(e.message);
        }
      case 'report':
        try {
          await _repo!.report(me!, widget.newsId, c);
          if (mounted) _toast('Teşekkürler, yöneticilere bildirildi.');
        } on CommentFailure catch (e) {
          if (mounted) _toast(e.message);
        }
      case 'block':
        await ChatScope.of(context).blocks.block(c.uid, c.name);
        if (mounted) {
          _toast('${c.name} engellendi. Profil sekmesinden kaldırabilirsin.');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final me = auth.user;
    final blocks = ChatScope.of(context).blocks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Yorumlar', style: AppTheme.display(22)),
        const SizedBox(height: 10),
        if (!widget.open)
          const Text(
            'Bu haber için yorumlar kapalı.',
            style: TextStyle(color: AppColors.muted),
          )
        else ...[
          if (me == null)
            _SignInPrompt(available: auth.available)
          else
            _Composer(
              controller: _input,
              sending: _sending,
              onSend: () => _send(me),
              muted: ChatScope.of(context).repository.watchMuted(me.uid),
            ),
          const SizedBox(height: 12),
          StreamBuilder<List<Comment>>(
            stream: _stream,
            builder: (context, snap) {
              if (snap.hasError) {
                return const Text(
                  'Yorumlar yüklenemedi. İnternetini kontrol et.',
                  style: TextStyle(color: AppColors.muted),
                );
              }
              final all = snap.data;
              if (all == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListenableBuilder(
                listenable: blocks,
                builder: (context, _) {
                  final items = [
                    for (final c in all)
                      if (!blocks.isBlocked(c.uid)) c,
                  ];
                  if (items.isEmpty) {
                    return const Text(
                      'Henüz yorum yok. İlk yorumu sen yaz!',
                      style: TextStyle(color: AppColors.muted),
                    );
                  }
                  return Column(
                    children: [
                      for (final c in items)
                        _CommentTile(c, onMore: () => _more(c, me)),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.available});
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            available
                ? 'Yorum yazmak için giriş yapman gerekiyor.'
                : 'Üyelik şu an kullanılamıyor.',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (available) ...[
            const SizedBox(height: 10),
            FilledButton(
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
          ],
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.muted,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final Stream<bool> muted;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: muted,
      initialData: false,
      builder: (context, snap) {
        if (snap.data ?? false) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.claySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Hesabın yönetici tarafından susturuldu. Şu an yorum yazamazsın.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                maxLength: maxCommentLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Yorumunu yaz…',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: 'Yorumu gönder',
              child: GestureDetector(
                onTap: sending ? null : onSend,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile(this.c, {required this.onMore});
  final Comment c;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final time = messageTime(c.at);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (time.isNotEmpty)
                Text(
                  time,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              const Spacer(),
              SizedBox(
                width: 36,
                height: 28,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Yorum seçenekleri',
                  onPressed: onMore,
                  icon: const Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              c.text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
