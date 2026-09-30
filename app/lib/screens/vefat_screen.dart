import 'package:flutter/material.dart';

import '../data/content_logic.dart';
import '../data/content_repository.dart';
import '../data/links.dart';
import '../notifications/notification_settings.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../data/vefat_filter.dart';
import '../widgets/data_stream.dart';
import '../widgets/person_photo.dart';
import '../widgets/share.dart';
import '../widgets/url_opener.dart';

class VefatScreen extends StatefulWidget {
  const VefatScreen({
    super.key,
    this.opener = defaultOpen,
    this.share = defaultShare,
  });
  final UrlOpener opener;
  final ShareFn share;

  @override
  State<VefatScreen> createState() => _VefatScreenState();
}

class _VefatScreenState extends State<VefatScreen> {
  int _tab = 0;

  Future<void> _toggleNotify(bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await NotificationScope.of(context)
        .setEnabled(NoticeTopics.vefat, on);
    if (!ok && mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Bildirim izni kapalı. Telefonun Ayarlar > Uygulamalar > Tavas > Bildirimler bölümünden izin ver.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Vefat\nİlanları',
                  style: AppTheme.display(34, color: AppColors.darkText),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  turkishDate(now),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.darkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListenableBuilder(
            listenable: NotificationScope.of(context),
            builder: (context, _) => _NotifyCard(
              value: NotificationScope.of(context)
                  .isEnabled(NoticeTopics.vefat),
              problem: NotificationScope.of(context).problem,
              onChanged: _toggleNotify,
            ),
          ),
          const SizedBox(height: 12),
          _Segments(index: _tab, onChanged: (i) => setState(() => _tab = i)),
          const SizedBox(height: 12),
          DataStream<List<VefatItem>>(
            dark: true,
            source: ContentScope.of(context).vefat,
            builder: (context, all) {
              final items = filterVefat(all, _tab, now);
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      'Bu dönemde ilan yok.',
                      style: TextStyle(color: AppColors.darkMuted),
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final v in items) ...[
                    _VefatCard(
                      v,
                      onDirections: () => openOrWarn(
                        context,
                        widget.opener,
                        mapsLink(query: '${v.condolenceAddress} Tavas Denizli'),
                      ),
                      onShare: () => widget.share(vefatShareText(v)),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NotifyCard extends StatelessWidget {
  const _NotifyCard({
    required this.value,
    required this.onChanged,
    this.problem,
  });
  final bool value;
  final String? problem;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.darkLine),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_none,
            size: 20,
            color: AppColors.darkAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value
                      ? 'Vefat bildirimleri açık'
                      : 'Vefat bildirimleri kapalı',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                if (problem != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      problem!,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: Color(0xFFFFB4A1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.darkBg,
            activeTrackColor: AppColors.darkAccent,
            inactiveTrackColor: AppColors.darkSurface2,
          ),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Bugün', 'Bu hafta', 'Arşiv'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index
                        ? AppColors.darkAccent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: i == index
                          ? AppColors.darkBg
                          : AppColors.darkMuted,
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

class _VefatCard extends StatelessWidget {
  const _VefatCard(this.v, {required this.onDirections, required this.onShare});
  final VefatItem v;
  final VoidCallback onDirections;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.darkLine),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PersonPhoto(
                photoUrl: v.photoUrl,
                initials: v.initials,
                name: v.name,
                width: 92,
                height: 116,
                enlargeOnTap: true,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.ago,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.darkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      v.name,
                      style: AppTheme.display(23, color: AppColors.darkText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${v.age} yaşında',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkAccent,
                      ),
                    ),
                    Text(
                      v.neighborhood,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.darkMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  Icons.schedule,
                  'Cenaze namazı',
                  v.prayerTime,
                  v.mosque,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  Icons.place_outlined,
                  'Defin yeri',
                  v.burial,
                  'Tavas',
                ),
              ),
            ],
          ),
          if (v.condolenceAddress.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoTile(
              Icons.home_outlined,
              'Taziye yeri',
              v.condolenceAddress,
              '',
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              // Yol tarifi taziye adresine gider; adres girilmemişse düğme gösterilmez.
              if (v.condolenceAddress.isNotEmpty) ...[
                Expanded(
                  child: _Action(
                    label: 'Yol tarifi',
                    icon: Icons.near_me_outlined,
                    filled: true,
                    onTap: onDirections,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _Action(
                  label: 'Paylaş',
                  icon: Icons.share_outlined,
                  filled: v.condolenceAddress.isEmpty,
                  onTap: onShare,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.icon, this.title, this.value, this.sub);
  final IconData icon;
  final String title, value, sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.darkAccent),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: AppColors.darkMuted),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText,
            ),
          ),
          if (sub.isNotEmpty)
            Text(
              sub,
              style: const TextStyle(fontSize: 12, color: AppColors.darkMuted),
            ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.darkBg : AppColors.darkText;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: filled ? AppColors.darkAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: filled
              ? null
              : Border.all(color: AppColors.darkLine, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
