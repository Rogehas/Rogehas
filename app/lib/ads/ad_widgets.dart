import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/remote_image.dart';
import '../widgets/url_opener.dart';
import 'ad_controller.dart';
import 'ad_models.dart';

/// Reklam denetleyicisini ağaca taşır; reklamlar değişince bağımlı yerler yenilenir.
class AdScope extends InheritedNotifier<AdController> {
  const AdScope({
    super.key,
    required AdController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Kapsam yoksa (ör. bazı testlerde) null: hiçbir yerde reklam çıkmaz.
  static AdController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdScope>()?.notifier;
}

enum AdStyle { strip, card, featured }

/// Bir yerleşim yeri: gösterilecek reklam varsa çizer, yoksa hiçbir şey (boşluk bile) bırakmaz.
class AdSlot extends StatelessWidget {
  const AdSlot({
    super.key,
    required this.placement,
    this.style = AdStyle.strip,
    this.padding = EdgeInsets.zero,
    this.closable = false,
  });

  final AdPlacement placement;
  final AdStyle style;

  /// Yalnızca reklam görünürken uygulanır.
  final EdgeInsets padding;

  /// Şeritte kapat (✕) düğmesi.
  final bool closable;

  @override
  Widget build(BuildContext context) {
    final c = AdScope.maybeOf(context);
    final ad = c?.adFor(placement);
    if (c == null || ad == null) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: AdImpression(
        key: ValueKey('${ad.id}|${placement.name}'),
        ad: ad,
        placement: placement,
        controller: c,
        child: switch (style) {
          AdStyle.strip => _AdStrip(
            ad,
            onTap: () => openAd(context, c, ad),
            onClose: closable ? () => c.close(placement) : null,
          ),
          AdStyle.card => _AdCard(ad, onTap: () => openAd(context, c, ad)),
          AdStyle.featured => _AdCard(
            ad,
            onTap: () => openAd(context, c, ad),
            featured: true,
          ),
        },
      ),
    );
  }
}

/// Reklama dokunuldu: tıklamayı sayar, adresi açar.
Future<void> openAd(BuildContext context, AdController c, AdItem ad) async {
  final uri = ad.uri;
  if (uri == null) return;
  c.trackClick(ad);
  await openOrWarn(context, c.opener, uri);
}

/// Görünür olunca gösterimi (oturum başına bir kez) sayar.
class AdImpression extends StatefulWidget {
  const AdImpression({
    super.key,
    required this.ad,
    required this.placement,
    required this.controller,
    required this.child,
  });
  final AdItem ad;
  final AdPlacement placement;
  final AdController controller;
  final Widget child;

  @override
  State<AdImpression> createState() => _AdImpressionState();
}

class _AdImpressionState extends State<AdImpression> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.controller.trackImpression(widget.ad, widget.placement);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AdThumb extends StatelessWidget {
  const _AdThumb(this.ad, {required this.size});
  final AdItem ad;
  final double size;
  static const radius = 14.0;

  @override
  Widget build(BuildContext context) {
    final letter = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        ad.name.characters.first.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * .42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    final url = ad.photoUrl;
    if (url == null) return letter;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: RemoteImage(url: url, fallback: letter),
      ),
    );
  }
}

class _Sponsor extends StatelessWidget {
  const _Sponsor();

  @override
  Widget build(BuildContext context) => const Text(
    'SPONSOR',
    style: TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w800,
      letterSpacing: .6,
      color: AppColors.muted,
    ),
  );
}

class _AdStrip extends StatelessWidget {
  const _AdStrip(this.ad, {required this.onTap, this.onClose});
  final AdItem ad;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Reklam: ${ad.name}. ${ad.text}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              _AdThumb(ad, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (ad.text.isNotEmpty)
                        Text(
                          ad.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.3,
                            color: AppColors.muted,
                          ),
                        ),
                      const SizedBox(height: 3),
                      Text(
                        ad.actionLabel,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const _Sponsor(),
                  if (onClose != null)
                    Semantics(
                      button: true,
                      label: 'Reklamı kapat',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onClose,
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(10, 8, 0, 4),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  const _AdCard(this.ad, {required this.onTap, this.featured = false});
  final AdItem ad;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final url = ad.photoUrl;
    final fallback = Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        ad.name.characters.first.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 44,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return Semantics(
      button: true,
      label: 'Reklam: ${ad.name}. ${ad.text}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: featured ? AppColors.primary : AppColors.line,
              width: featured ? 1.5 : 1,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 8,
                      child: url == null
                          ? fallback
                          : RemoteImage(url: url, fallback: fallback),
                    ),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: featured
                              ? AppColors.primary
                              : const Color(0xB3000000),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          featured ? 'ÖNE ÇIKAN · SPONSOR' : 'SPONSOR',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (ad.text.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          ad.text,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.35,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        ad.actionLabel,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentText,
                        ),
                      ),
                    ],
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

/// Ana sayfadaki kayan bölümün reklam slaytı: tam alan görsel, altta metin.
class AdHeroSlide extends StatelessWidget {
  const AdHeroSlide(this.ad, {super.key});
  final AdItem ad;

  @override
  Widget build(BuildContext context) {
    final c = AdScope.maybeOf(context);
    if (c == null) return const SizedBox.shrink();
    final url = ad.photoUrl;
    final base = Container(
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        ad.name.characters.first.toUpperCase(),
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 120,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return AdImpression(
      key: ValueKey('${ad.id}|hero'),
      ad: ad,
      placement: AdPlacement.hero,
      controller: c,
      child: Semantics(
        button: true,
        label: 'Reklam: ${ad.name}. ${ad.text}',
        child: GestureDetector(
          onTap: () => openAd(context, c, ad),
          child: ExcludeSemantics(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (url == null)
                  base
                else
                  RemoteImage(url: url, fallback: base),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xD9000000)],
                      stops: [.35, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xB3000000),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'SPONSOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 34,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ad.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.display(26)
                            .copyWith(color: Colors.white),
                      ),
                      if (ad.text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          ad.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        ad.actionLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
