import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Vefat ilanlarındaki kişi fotoğrafı. Fotoğraf yoksa ya da yüklenemezse
/// baş harfleri gösterir. [enlargeOnTap] ile dokununca tam ekran açılır.
class PersonPhoto extends StatelessWidget {
  const PersonPhoto({
    super.key,
    required this.photoUrl,
    required this.initials,
    required this.name,
    this.width = 92,
    this.height = 116,
    this.enlargeOnTap = false,
  });

  final String? photoUrl;
  final String initials;
  final String name;
  final double width;
  final double height;
  final bool enlargeOnTap;

  Widget _placeholder() => Container(
    color: AppColors.darkLine,
    alignment: Alignment.center,
    child: Text(
      initials,
      style: AppTheme.display(width / 3, color: AppColors.darkAccent),
    ),
  );

  Widget _image({BoxFit fit = BoxFit.cover}) {
    final url = photoUrl;
    if (url == null || url.isEmpty) return _placeholder();
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
      errorBuilder: (context, error, stack) => _placeholder(),
    );
  }

  void _open(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xE6000000),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(child: _image(fit: BoxFit.contain)),
            ),
            Positioned(
              top: 48,
              right: 16,
              child: Semantics(
                button: true,
                label: 'Kapat',
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final box = Semantics(
      label: '$name fotoğrafı',
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(width: width, height: height, child: _image()),
      ),
    );
    if (!enlargeOnTap || !hasPhoto) return box;
    return GestureDetector(onTap: () => _open(context), child: box);
  }
}
