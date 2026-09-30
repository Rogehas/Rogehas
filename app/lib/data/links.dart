/// Telefon ve harita bağlantıları (tüm ekranlarda ortak).
Uri telLink(String phone) => Uri(scheme: 'tel', path: phone);

/// Google Haritalar yol tarifi: koordinat varsa tam konum, yoksa [query] metni.
Uri mapsLink({double? lat, double? lng, required String query}) {
  final destination = (lat != null && lng != null) ? '$lat,$lng' : query.trim();
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': destination,
  });
}

/// "0258 614 00 00" biçiminde gösterim; kısa numaralar (112, 444 1 444) ve bilinmeyen biçimler olduğu gibi.
String prettyPhone(String phone) {
  if (phone.length == 11) {
    return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7, 9)} ${phone.substring(9)}';
  }
  if (phone.length == 7 && phone.startsWith('444')) {
    return '${phone.substring(0, 3)} ${phone.substring(3, 4)} ${phone.substring(4)}';
  }
  return phone;
}
