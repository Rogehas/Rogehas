import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import '../data/duty_logic.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/data_stream.dart';
import '../widgets/url_opener.dart';

class EczaneScreen extends StatefulWidget {
  const EczaneScreen({super.key, this.opener = defaultOpen});
  final UrlOpener opener;

  @override
  State<EczaneScreen> createState() => _EczaneScreenState();
}

class _EczaneScreenState extends State<EczaneScreen> {
  int _tab = 0; // 0 = şu anki nöbet, 1 = sıradaki

  Future<void> _open(Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await widget.opener(uri);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Açılamadı. Uygulama bulunamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hub = ContentScope.of(context);
    final now = DateTime.now();
    final day = dutyDayAt(now, _tab);
    final key = dutyDateKey(day);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                RoundIconButton(
                  icon: Icons.arrow_back,
                  label: 'Geri',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Nöbetçi Eczane', style: AppTheme.display(26)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Segments(index: _tab, onChanged: (i) => setState(() => _tab = i)),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    dutyWindowLabel(day),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            DataStream<List<Pharmacy>>(
              source: hub.pharmacies,
              builder: (context, pharmacies) => DataStream<List<DutyDay>>(
                source: hub.duty,
                builder: (context, duty) {
                  final list = pharmaciesOnDuty(duty, pharmacies, key);
                  if (list == null || list.isEmpty) {
                    return const _NotEntered();
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        _PharmacyCard(
                          list[i],
                          highlighted: i == 0,
                          onCall: list[i].phone.isEmpty
                              ? null
                              : () => _open(telUri(list[i].phone)),
                          onDirections: () => _open(directionsUri(list[i])),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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
    const labels = ['Bugün', 'Yarın'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: AppTheme.cardShadow,
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
                    color: i == index ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: i == index ? Colors.white : AppColors.muted,
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

class _NotEntered extends StatelessWidget {
  const _NotEntered();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
      ),
      child: const Column(
        children: [
          Icon(Icons.local_pharmacy_outlined, size: 32, color: AppColors.muted),
          SizedBox(height: 10),
          Text(
            'Bu gün için nöbet bilgisi henüz girilmedi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard(
    this.p, {
    required this.highlighted,
    required this.onCall,
    required this.onDirections,
  });

  final Pharmacy p;
  final bool highlighted;
  final VoidCallback? onCall;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final fg = highlighted ? Colors.white : AppColors.ink;
    final sub = highlighted ? const Color(0xFFB8D6CC) : AppColors.muted;
    final place = [
      if (p.neighborhood.isNotEmpty) p.neighborhood,
      if (p.address.isNotEmpty) p.address,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: highlighted ? null : AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: highlighted ? AppColors.lime : AppColors.limeSoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.local_pharmacy_outlined,
                  size: 26,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: AppTheme.display(21, color: fg)),
                    if (place.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        place,
                        style: TextStyle(fontSize: 13, color: sub, height: 1.3),
                      ),
                    ],
                    if (p.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        formatPhone(p.phone),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: sub,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Ara',
                  icon: Icons.call_outlined,
                  filled: true,
                  highlighted: highlighted,
                  onTap: onCall,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  label: 'Yol tarifi',
                  icon: Icons.near_me_outlined,
                  filled: false,
                  highlighted: highlighted,
                  onTap: onDirections,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.highlighted,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final bg = filled
        ? (highlighted ? AppColors.lime : AppColors.ink)
        : Colors.transparent;
    final fg = filled
        ? (highlighted ? AppColors.ink : Colors.white)
        : (highlighted ? Colors.white : AppColors.ink);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: enabled ? 1 : .4,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(25),
              border: filled
                  ? null
                  : Border.all(
                      color: highlighted
                          ? const Color(0x59FFFFFF)
                          : AppColors.line,
                      width: 1.5,
                    ),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
