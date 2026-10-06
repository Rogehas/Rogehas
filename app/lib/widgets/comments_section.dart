import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../chat/chat_logic.dart' show messageTime, visibleTo;
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
  final _replyInput = TextEditingController();
  final _replyKey = GlobalKey();
  Comment? _replyTo;
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
    _replyInput.dispose();
    super.dispose();
  }

  void _toast(String t) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(t)));

  /// [reply] verilirse yorum o yoruma yanıttır ve yanıt kutusundan okunur.
  Future<void> _send(AuthUser user, {Comment? reply}) async {
    final field = reply == null ? _input : _replyInput;
    final problem = validateComment(field.text);
    if (problem != null) return _toast(problem);
    if (DateTime.now().difference(_lastSent) < commentCooldown) {
      return _toast('Çok hızlı yazıyorsun. Birkaç saniye bekle.');
    }
    setState(() => _sending = true);
    try {
      await _repo!.send(user, widget.newsId, field.text, replyTo: reply);
      _lastSent = DateTime.now();
      field.clear();
      if (mounted) setState(() => _replyTo = null);
      if (mounted) FocusScope.of(context).unfocus();
    } on CommentFailure catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// "Yanıtla": üye değilse giriş ekranı, üyeyse yorumun hemen altında yanıt kutusu açılır.
  void _startReply(Comment c, AuthUser? me) {
    if (me == null) {
      Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => const AuthScreen(mode: AuthMode.signIn),
        ),
      );
      return;
    }
    if (_replyTo?.id != c.id) _replyInput.clear();
    setState(() => _replyTo = c);
    // Yanıt kutusu ekranın dışında kalmasın (liste uzunluğu oturduktan sonra kaydırılır).
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      final box = _replyKey.currentContext;
      if (!mounted || box == null || !box.mounted) return;
      Scrollable.ensureVisible(
        box,
        duration: const Duration(milliseconds: 200),
        alignment: 0.3,
      );
    });
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

  /// Yanıtlanan yorumun hemen altında açılan yazma kutusu.
  Widget _replyBox(AuthUser me) {
    final to = _replyTo!;
    return Padding(
      key: const Key('replyBox'),
      padding: const EdgeInsets.only(left: 22, bottom: 10),
      child: _Composer(
        key: _replyKey,
        controller: _replyInput,
        hint: '${to.name} adlı kişiye yanıt yaz…',
        sending: _sending,
        autofocus: true,
        onCancel: () => setState(() => _replyTo = null),
        onSend: () => _send(me, reply: to),
      ),
    );
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
              hint: 'Yorumunu yaz…',
              sending: _sending,
              onSend: () => _send(me),
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
                      if (!blocks.isBlocked(c.uid) &&
                          visibleTo(me?.uid, shadow: c.shadow, uid: c.uid))
                        c,
                  ];
                  if (items.isEmpty) {
                    return const Text(
                      'Henüz yorum yok. İlk yorumu sen yaz!',
                      style: TextStyle(color: AppColors.muted),
                    );
                  }
                  return Column(
                    children: [
                      for (final t in groupComments(items)) ...[
                        _CommentTile(
                          t.root,
                          onMore: () => _more(t.root, me),
                          onReply: () => _startReply(t.root, me),
                        ),
                        if (me != null && _replyTo?.id == t.root.id)
                          _replyBox(me),
                        for (final r in t.replies) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 22),
                            child: _CommentTile(
                              r,
                              onMore: () => _more(r, me),
                              onReply: () => _startReply(r, me),
                            ),
                          ),
                          if (me != null && _replyTo?.id == r.id) _replyBox(me),
                        ],
                      ],
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
    super.key,
    required this.controller,
    required this.hint,
    required this.sending,
    required this.onSend,
    this.onCancel,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String hint;
  final bool sending;
  final VoidCallback onSend;

  /// Verilirse (yanıt kutusu) üstte "Vazgeç" düğmesi çıkar.
  final VoidCallback? onCancel;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            minLines: 1,
            maxLines: 4,
            maxLength: maxCommentLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: hint,
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
    if (onCancel == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Yanıt yazıyorsun',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentText,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'Yanıtı iptal et',
                child: GestureDetector(
                  onTap: onCancel,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 18, color: AppColors.muted),
                  ),
                ),
              ),
            ],
          ),
        ),
        row,
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile(this.c, {required this.onMore, required this.onReply});
  final Comment c;
  final VoidCallback onMore;
  final VoidCallback onReply;

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
          if (c.isReply && c.replyToName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '↪ ${c.replyToName}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              c.text,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onReply,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(top: 6, right: 12, bottom: 2),
                child: Text(
                  'Yanıtla',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
