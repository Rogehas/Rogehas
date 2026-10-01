import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../complaints/complaint_repository.dart';
import '../data/vefat_filter.dart' show turkishDate;
import '../theme/app_theme.dart';
import '../widgets/sub_page.dart';
import 'auth_screen.dart';

/// Şikâyet ve öneri: üyeler gönderir, durumunu ve yanıtı görür.
class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _neighborhood = TextEditingController();
  final _text = TextEditingController();
  String? _category;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _neighborhood.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthUser user) async {
    final repo = ComplaintScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final problem = validateComplaint(
      category: _category ?? '',
      text: _text.text,
    );
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repo.submit(
        user,
        category: _category!,
        neighborhood: _neighborhood.text,
        text: _text.text,
      );
      _text.clear();
      _neighborhood.clear();
      setState(() => _category = null);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Teşekkürler, mesajın alındı. Durumunu aşağıdan takip edebilirsin.',
          ),
        ),
      );
    } on ComplaintFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    final user = auth.user;
    return SubPage(
      title: 'Şikâyet / Öneri',
      children: [
        if (user == null)
          _SignInCard(available: auth.available)
        else ...[
          const Text(
            'Tavas ile ilgili şikâyet veya önerini yaz. Mesajın yetkililere iletilir; yanıtı ve durumu burada görünür.',
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: _decoration('Konu'),
            items: [
              for (final c in complaintCategories)
                DropdownMenuItem(value: c, child: Text(c)),
            ],
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _neighborhood,
            textCapitalization: TextCapitalization.words,
            decoration: _decoration('Mahalle / yer (isteğe bağlı)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 8,
            maxLength: maxComplaintLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration('Mesajın'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.clay,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _busy ? null : () => _submit(user),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Gönder'),
            ),
          ),
          const SizedBox(height: 24),
          Text('Gönderdiklerim', style: AppTheme.display(22)),
          const SizedBox(height: 10),
          _Mine(uid: user.uid),
        ],
      ],
    );
  }
}

class _SignInCard extends StatelessWidget {
  const _SignInCard({required this.available});
  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Önce üye ol', style: AppTheme.display(22)),
          const SizedBox(height: 6),
          Text(
            available
                ? 'Şikâyet ve önerini gönderebilmek için giriş yapman gerekiyor. Böylece yanıtı sana ulaştırabiliriz.'
                : 'Üyelik şu an kullanılamıyor. Biraz sonra tekrar dene.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
          if (available) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<bool>(
                    builder: (_) => const AuthScreen(mode: AuthMode.signUp),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Üye ol / Giriş yap'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Mine extends StatelessWidget {
  const _Mine({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Complaint>>(
      stream: ComplaintScope.of(context).watchMine(uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return const SoftNotice(
            Icons.cloud_off_outlined,
            'Gönderdiklerin yüklenemedi. İnternetini kontrol et.',
          );
        }
        final items = snap.data;
        if (items == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) {
          return const Text(
            'Henüz bir şey göndermedin.',
            style: TextStyle(color: AppColors.muted),
          );
        }
        return Column(children: [for (final c in items) _MineCard(c)]);
      },
    );
  }
}

class _MineCard extends StatelessWidget {
  const _MineCard(this.c);
  final Complaint c;

  Color get _color => switch (c.status) {
    ComplaintStatus.newOne => AppColors.muted,
    ComplaintStatus.progress => const Color(0xFFFBBF24),
    ComplaintStatus.resolved => const Color(0xFF34D399),
    ComplaintStatus.closed => AppColors.muted,
  };

  @override
  Widget build(BuildContext context) {
    final place = c.neighborhood.isEmpty ? '' : ' · ${c.neighborhood}';
    final date = c.at == null ? '' : ' · ${turkishDate(c.at!)}';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${c.category}$place$date',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  c.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(c.text, style: const TextStyle(fontSize: 15, height: 1.4)),
          if (c.reply.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.limeSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Yanıt',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    c.reply,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
