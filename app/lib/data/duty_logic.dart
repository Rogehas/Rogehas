import 'models.dart';
import 'vefat_filter.dart' show turkishDate;

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Şu an geçerli nöbet gününün tarihi: nöbet 09:00'da değişir, yani sabah 09:00'dan önce hâlâ dünün nöbeti sürer.
DateTime currentDutyDay(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return now.hour < 9 ? today.subtract(const Duration(days: 1)) : today;
}

/// `currentDutyDay`dan [offset] gün sonrası (0 = şu anki nöbet, 1 = sıradaki).
/// Gün ekleme saat dilimi/yaz saati kaymasına takılmasın diye takvim günüyle yapılır.
DateTime dutyDayAt(DateTime now, int offset) {
  final d = currentDutyDay(now);
  return DateTime(d.year, d.month, d.day + offset);
}

String dutyDateKey(DateTime day) => _ymd(day);

/// "30 Eylül 09:00 – 1 Ekim 09:00"
String dutyWindowLabel(DateTime day) {
  final next = DateTime(day.year, day.month, day.day + 1);
  return '${turkishDate(day)} 09:00 – ${turkishDate(next)} 09:00';
}

/// O günün nöbetçi eczaneleri; kapalı/silinmiş eczaneler ve kaydı olmayan kimlikler atlanır.
/// Sıra, panelde yazıldığı sıradır. Gün hiç girilmediyse `null` döner ("girilmedi" ile "kimse yok" ayrımı).
List<Pharmacy>? pharmaciesOnDuty(
  List<DutyDay> duty,
  List<Pharmacy> pharmacies,
  String dateKey,
) {
  final day = duty.where((d) => d.date == dateKey).firstOrNull;
  if (day == null) return null;
  final byId = {for (final p in pharmacies) p.id: p};
  return [
    for (final id in day.pharmacyIds)
      if (byId[id] != null) byId[id]!,
  ];
}

/// Telefon arama adresi.
Uri telUri(String phone) => Uri(scheme: 'tel', path: phone);

/// Google Haritalar yol tarifi adresi: koordinat varsa tam konum, yoksa adres metni.
Uri directionsUri(Pharmacy p) {
  final destination = (p.lat != null && p.lng != null)
      ? '${p.lat},${p.lng}'
      : '${p.name} ${p.address} Tavas Denizli'.trim();
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': destination,
  });
}

/// "0258 614 00 00" biçiminde gösterim (11 haneli değilse olduğu gibi).
String formatPhone(String phone) {
  if (phone.length != 11) return phone;
  return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7, 9)} ${phone.substring(9)}';
}
