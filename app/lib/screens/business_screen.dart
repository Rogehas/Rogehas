import 'package:flutter/material.dart';

import '../ads/ad_models.dart';
import '../ads/ad_widgets.dart';

import '../data/content_logic.dart';
import '../data/content_repository.dart';
import '../data/links.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/data_stream.dart';
import '../widgets/remote_image.dart';
import '../widgets/sub_page.dart';
import '../widgets/url_opener.dart';

IconData _categoryIcon(String c) => switch (c) {
  'Restoran' => Icons.restaurant_outlined,
  'Kafe' => Icons.local_cafe_outlined,
  'Konaklama' => Icons.hotel_outlined,
  'Market' => Icons.shopping_basket_outlined,
  'Hizmet' => Icons.handyman_outlined,
  'Sağlık' => Icons.medical_services_outlined,
  _ => Icons.storefront_outlined,
};

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({super.key, this.opener = defaultOpen});
  final UrlOpener opener;

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  String? _category; // null = tümü

  @override
  Widget build(BuildContext context) {
    final hub = ContentScope.of(context);
    return SubPage(
      title: 'Yerel Esnaf',
      children: [
        DataStream<List<Business>>(
          source: hub.businesses,
          builder: (context, all) {
            final cats = businessCategories(all);
            // Seçili kategori artık yoksa (işletme gizlendi) tümüne dön.
            final selected = cats.contains(_category) ? _category : null;
            final list = filterBusinesses(all, selected);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdSlot(
                  placement: AdPlacement.esnaf,
                  style: AdStyle.featured,
                  padding: EdgeInsets.only(bottom: 14),
                ),
                if (cats.length > 1)
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        FilterChipPill(
                          'Tümü',
                          selected: selected == null,
                          onTap: () => setState(() => _category = null),
                        ),
                        for (final c in cats) ...[
                          const SizedBox(width: 8),
                          FilterChipPill(
                            c,
                            selected: selected == c,
                            onTap: () => setState(() => _category = c),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (cats.length > 1) const SizedBox(height: 14),
                if (list.isEmpty)
                  const SoftNotice(
                    Icons.storefront_outlined,
                    'Henüz işletme eklenmedi.',
                  )
                else
                  for (final b in list) ...[
                    _BusinessCard(
                      b,
                      onCall: b.phone.isEmpty
                          ? null
                          : () => openOrWarn(
                              context,
                              widget.opener,
                              telLink(b.phone),
                            ),
                      onDirections: () => openOrWarn(
                        context,
                        widget.opener,
                        mapsLink(
                          lat: b.lat,
                          lng: b.lng,
                          query: '${b.name} ${b.address} Tavas Denizli',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BusinessCard extends StatelessWidget {
  const _BusinessCard(
    this.b, {
    required this.onCall,
    required this.onDirections,
  });
  final Business b;
  final VoidCallback? onCall;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.limeSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        _categoryIcon(b.category),
        size: 28,
        color: AppColors.accentText,
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (b.photoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: RemoteImage(url: b.photoUrl!, fallback: icon),
                  ),
                )
              else
                icon,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      b.category,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentText,
                      ),
                    ),
                    if (b.address.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          b.address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                            height: 1.3,
                          ),
                        ),
                      ),
                    if (b.hours.isNotEmpty)
                      Text(
                        b.hours,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.3,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (b.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              b.description,
              style: const TextStyle(fontSize: 14, height: 1.45),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              if (onCall != null) ...[
                Expanded(
                  child: _Action(
                    label: 'Ara',
                    icon: Icons.call_outlined,
                    filled: true,
                    onTap: onCall!,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: _Action(
                  label: 'Yol tarifi',
                  icon: Icons.near_me_outlined,
                  filled: onCall == null,
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
    final fg = filled ? Colors.white : AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(23),
          border: filled ? null : Border.all(color: AppColors.line, width: 1.5),
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
