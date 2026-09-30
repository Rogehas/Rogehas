import 'models.dart';

/// Vefat sekmeleri: 0 = Bugün (bugün ve ilerisi), 1 = Bu hafta (son 7 gün), 2 = Arşiv (daha eski).
/// Cenaze günü bilinmeyen ilanlar "Bugün"de gösterilir.
List<VefatItem> filterVefat(List<VefatItem> all, int tab, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  int tabOf(VefatItem v) {
    final d = v.prayerAt;
    if (d == null) return 0;
    final days = today.difference(DateTime(d.year, d.month, d.day)).inDays;
    if (days <= 0) return 0;
    return days <= 7 ? 1 : 2;
  }

  return all.where((v) => tabOf(v) == tab).toList();
}

const _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String turkishDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';
