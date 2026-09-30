import '../data/content_logic.dart';

const maxMessageLength = 500;
const sendCooldown = Duration(seconds: 2);

/// Uygunsuz ifadeler (tam kelime eşleşmesi; Türkçe harf farkından etkilenmez).
const _blockedWords = {
  'orospu',
  'pic',
  'siktir',
  'amk',
  'aq',
  'yarrak',
  'ibne',
  'pezevenk',
  'surtuk',
  'gavat',
  'serefsiz',
  'amina',
  'sikerim',
};

bool containsBlockedWord(String text) {
  final words = foldTr(text).split(RegExp(r'[^a-z0-9]+'));
  return words.any(_blockedWords.contains);
}

/// Gönderilebilir mesaj ise null; değilse kullanıcıya gösterilecek neden.
String? validateMessage(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return 'Boş mesaj gönderilemez.';
  if (t.length > maxMessageLength) {
    return 'Mesaj en fazla $maxMessageLength karakter olabilir.';
  }
  if (containsBlockedWord(t)) {
    return 'Mesajında uygunsuz bir ifade var. Lütfen saygılı bir dil kullan.';
  }
  return null;
}

/// Mesaj saati "14:05"; saat yoksa (sunucu henüz yazmadıysa) boş.
String messageTime(DateTime? at) {
  if (at == null) return '';
  final l = at.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}
