import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Adresi/telefonu açar. Testlerde sahte bir sürümle değiştirilir.
typedef UrlOpener = Future<bool> Function(Uri uri);

Future<bool> defaultOpen(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Açar; açılamazsa kısa bir uyarı gösterir.
Future<void> openOrWarn(BuildContext context, UrlOpener opener, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  var ok = false;
  try {
    ok = await opener(uri);
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Açılamadı. Uygulama bulunamadı.')),
    );
  }
}
