import 'package:share_plus/share_plus.dart';

/// Metni WhatsApp vb. ile paylaşır. Testlerde sahte bir sürümle değiştirilir.
typedef ShareFn = Future<void> Function(String text);

Future<void> defaultShare(String text) async {
  await SharePlus.instance.share(ShareParams(text: text));
}
