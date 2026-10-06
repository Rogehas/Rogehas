import type { Member } from './types';

const fold = (s: string) =>
  s
    .toLocaleLowerCase('tr-TR')
    .replaceAll('ı', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c');

/** Ad veya e-postada arar (Türkçe harf ve büyük/küçük harf farkı gözetmez). Boş arama hepsini döndürür. */
export function filterMembers(list: Member[], q: string): Member[] {
  const t = fold(q.trim());
  if (!t) return list;
  return list.filter((m) => fold(m.name).includes(t) || fold(m.email).includes(t));
}
