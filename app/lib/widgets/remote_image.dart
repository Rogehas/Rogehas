import 'dart:typed_data';

import 'package:flutter/material.dart';

/// https adresini ya da `data:` adresini (panel, Storage açılana kadar fotoğrafı böyle saklar) gösterir.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  final String url;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget error(BuildContext c, Object e, StackTrace? s) => fallback;
    if (url.startsWith('data:')) {
      try {
        final Uint8List bytes = UriData.parse(url).contentAsBytes();
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: error,
          gaplessPlayback: true,
        );
      } catch (_) {
        return fallback;
      }
    }
    return Image.network(
      url,
      fit: fit,
      errorBuilder: error,
      loadingBuilder: (c, child, p) => p == null ? child : fallback,
    );
  }
}
