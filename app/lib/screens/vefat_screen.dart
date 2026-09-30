import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';

class VefatScreen extends StatefulWidget {
  const VefatScreen({super.key});

  @override
  State<VefatScreen> createState() => _VefatScreenState();
}

class _VefatScreenState extends State<VefatScreen> {
  bool _notify = true;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
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
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '30 Eylül · 2 ilan',
                  style: TextStyle(fontSize: 13, color: AppColors.darkMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _NotifyCard(
            value: _notify,
            onChanged: (v) => setState(() => _notify = v),
          ),
          const SizedBox(height: 12),
          _Segments(index: _tab, onChanged: (i) => setState(() => _tab = i)),
          const SizedBox(height: 12),
          if (_tab != 0)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: Text(
                  'Bu dönemde ilan yok.',
                  style: TextStyle(color: AppColors.darkMuted),
                ),
              ),
            )
          else
            for (final v in MockData.vefat) ...[
              _VefatCard(v),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _NotifyCard extends StatelessWidget {
  const _NotifyCard({required this.value, required this.onChanged});
  final bool value;
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
            child: Text(
              value ? 'Vefat bildirimleri açık' : 'Vefat bildirimleri kapalı',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.darkText,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.ink,
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
                      color: i == index ? AppColors.ink : AppColors.darkMuted,
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
  const _VefatCard(this.v);
  final VefatItem v;

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
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.darkLine,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  v.initials,
                  style: AppTheme.display(22, color: AppColors.darkAccent),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.name,
                      style: AppTheme.display(23, color: AppColors.darkText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${v.age} yaşında · ${v.neighborhood}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.darkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                v.ago,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.darkMuted,
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Action(
                  label: 'Yol tarifi',
                  icon: Icons.near_me_outlined,
                  filled: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Action(
                  label: 'Paylaş',
                  icon: Icons.share_outlined,
                  filled: false,
                  onTap: () {},
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
    final fg = filled ? AppColors.ink : AppColors.darkText;
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
