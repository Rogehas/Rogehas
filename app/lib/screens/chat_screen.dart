import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../chat/chat_logic.dart';
import '../chat/chat_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/sub_page.dart';
import 'auth_screen.dart';

/// Sohbet sekmesi: üye değilse giriş/üyelik, üyeyse genel sohbet odası.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.user;
    return SafeArea(
      bottom: false,
      child: user == null
          ? const _SignedOut()
          : _ChatRoom(key: ValueKey(user.uid), user: user),
    );
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  void _open(BuildContext context, AuthMode mode) => Navigator.of(context)
      .push(MaterialPageRoute<bool>(builder: (_) => AuthScreen(mode: mode)));

  @override
  Widget build(BuildContext context) {
    final available = AuthScope.of(context).available;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        Text('Sohbet', style: AppTheme.display(36)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.limeSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              Text('Tavaslılarla sohbet et', style: AppTheme.display(24)),
              const SizedBox(height: 6),
              const Text(
                'Genel sohbete katılmak için üye olman gerekiyor. Üyelik ücretsiz ve sadece e-posta ile yapılır.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 18),
              if (!available)
                const Text(
                  'Üyelik şu an kullanılamıyor. Biraz sonra tekrar dene.',
                  style: TextStyle(
                    color: AppColors.clay,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: () => _open(context, AuthMode.signUp),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Üye ol'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => _open(context, AuthMode.signIn),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      shape: const StadiumBorder(),
                      side: const BorderSide(color: AppColors.line, width: 1.5),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Giriş yap'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatRoom extends StatefulWidget {
  const _ChatRoom({super.key, required this.user});
  final AuthUser user;

  @override
  State<_ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<_ChatRoom> {
  final _input = TextEditingController();
  Stream<List<ChatMessage>>? _messages;
  Stream<bool>? _muted;
  ChatRepository? _repo;
  bool _sending = false;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repo = ChatScope.of(context).repository;
    if (_repo != repo) {
      _repo = repo;
      _messages = repo.watchMessages();
      _muted = repo.watchMuted(widget.user.uid);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _send() async {
    final text = _input.text;
    final problem = validateMessage(text);
    if (problem != null) {
      _toast(problem);
      return;
    }
    if (DateTime.now().difference(_lastSent) < sendCooldown) {
      _toast('Çok hızlı yazıyorsun. Birkaç saniye bekle.');
      return;
    }
    setState(() => _sending = true);
    try {
      await _repo!.send(widget.user, text);
      _lastSent = DateTime.now();
      _input.clear();
    } on ChatFailure catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _more(ChatMessage m) async {
    final mine = m.uid == widget.user.uid;
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
                title: const Text('Mesajı sil'),
                onTap: () => Navigator.pop(context, 'delete'),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Şikâyet et'),
                subtitle: const Text('Yöneticilere bildirilir'),
                onTap: () => Navigator.pop(context, 'report'),
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: Text('${m.name} adlı kişiyi engelle'),
                subtitle: const Text('Mesajlarını bu telefonda görmezsin'),
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
          await _repo!.deleteMessage(m.id);
        } on ChatFailure catch (e) {
          if (mounted) _toast(e.message);
        }
      case 'report':
        try {
          await _repo!.report(widget.user, m, 'uygunsuz');
          if (mounted) _toast('Teşekkürler, yöneticilere bildirildi.');
        } on ChatFailure catch (e) {
          if (mounted) _toast(e.message);
        }
      case 'block':
        await ChatScope.of(context).blocks.block(m.uid, m.name);
        if (mounted) {
          _toast('${m.name} engellendi. Profil sekmesinden kaldırabilirsin.');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocks = ChatScope.of(context).blocks;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Row(
            children: [
              Expanded(child: Text('Sohbet', style: AppTheme.display(36))),
              Text(
                widget.user.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Saygılı ol. Uygunsuz mesajlar silinir, kurala uymayanlar susturulur.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: _messages,
            builder: (context, snap) {
              if (snap.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: SoftNotice(
                    Icons.cloud_off_outlined,
                    'Sohbet yüklenemedi. İnternetini kontrol edip tekrar dene.',
                  ),
                );
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListenableBuilder(
                listenable: blocks,
                builder: (context, _) {
                  final items = [
                    for (final m in snap.data!)
                      if (!blocks.isBlocked(m.uid)) m,
                  ];
                  if (items.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Henüz mesaj yok. İlk mesajı sen yaz!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: items.length,
                    itemBuilder: (context, i) => _Bubble(
                      items[i],
                      mine: items[i].uid == widget.user.uid,
                      onMore: () => _more(items[i]),
                    ),
                  );
                },
              );
            },
          ),
        ),
        StreamBuilder<bool>(
          stream: _muted,
          initialData: false,
          builder: (context, snap) {
            final muted = snap.data ?? false;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, keyboard ? 8 : 100),
              child: muted
                  ? Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.claySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Hesabın yönetici tarafından susturuldu. Şu an mesaj yazamazsın.',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            minLines: 1,
                            maxLines: 4,
                            maxLength: maxMessageLength,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Mesajını yaz…',
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
                          label: 'Mesajı gönder',
                          child: GestureDetector(
                            onTap: _sending ? null : _send,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.m, {required this.mine, required this.onMore});
  final ChatMessage m;
  final bool mine;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final time = messageTime(m.at);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        decoration: BoxDecoration(
          color: mine ? AppColors.lime : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    mine ? 'Sen' : m.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                SizedBox(
                  width: 34,
                  height: 26,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'Mesaj seçenekleri',
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
              child: SelectableText(
                m.text,
                style: const TextStyle(fontSize: 15, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
