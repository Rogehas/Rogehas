import { normalizeAnyPhone } from './content';
import { AD_PLACEMENTS, type Ad, type AdPlacement } from './types';

/** Bir yerde aynı anda en fazla kaç açık reklam bulunabilir. */
export const MAX_ADS_PER_PLACEMENT = 3;
export const MAX_AD_TEXT = 80;

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const KEYS = new Set<string>(AD_PLACEMENTS.map((p) => p.key));

/** Bugünün tarihi YYYY-MM-DD (yerel saat). */
export const todayKey = (d = new Date()) =>
  `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

export type AdStatus = 'live' | 'off' | 'scheduled' | 'expired';

/** Reklam şu an uygulamada gösterilir mi? (genel anahtar hariç) */
export function adStatus(ad: Pick<Ad, 'active' | 'startDate' | 'endDate'>, today = todayKey()): AdStatus {
  if (!ad.active) return 'off';
  if (ad.startDate && today < ad.startDate) return 'scheduled';
  if (ad.endDate && today > ad.endDate) return 'expired';
  return 'live';
}

export const AD_STATUS_LABEL: Record<AdStatus, string> = {
  live: 'Yayında',
  off: 'Kapalı',
  scheduled: 'Başlamadı',
  expired: 'Süresi doldu',
};

/** Telefonu rakamlara, web adresini https:// ile başlayan biçime çevirir. */
export function normalizeAd(ad: Ad): Ad {
  const v = ad.actionValue.trim();
  let value = v;
  if (ad.action === 'call') value = normalizeAnyPhone(v);
  if (ad.action === 'web' && v && !/^https?:\/\//i.test(v)) value = `https://${v}`;
  return { ...ad, name: ad.name.trim(), text: ad.text.trim(), actionValue: value };
}

export function validateAd(ad: Ad): string[] {
  const e: string[] = [];
  if (!ad.name.trim()) e.push('Esnaf / reklam veren adı gerekli.');
  if (!ad.text.trim()) e.push('Kısa metin gerekli.');
  if (ad.text.trim().length > MAX_AD_TEXT) e.push(`Metin en fazla ${MAX_AD_TEXT} karakter olabilir.`);
  const v = ad.actionValue.trim();
  if (ad.action === 'call') {
    const d = v.replace(/\D/g, '');
    if (!(d.length >= 7 && d.length <= 15)) e.push('Geçerli bir telefon numarası girin.');
  } else if (ad.action === 'map') {
    if (v.length < 5) e.push('Haritada açılacak adresi yazın.');
  } else {
    let ok = false;
    try {
      const u = new URL(/^https?:\/\//i.test(v) ? v : `https://${v}`);
      ok = u.hostname.includes('.');
    } catch {
      ok = false;
    }
    if (!ok) e.push('Geçerli bir web adresi girin.');
  }
  if (ad.placements.length === 0) e.push('En az bir yer seçin.');
  if (ad.placements.some((p) => !KEYS.has(p))) e.push('Geçersiz yer seçimi.');
  if (ad.startDate && !DATE_RE.test(ad.startDate)) e.push('Başlangıç tarihi geçersiz.');
  if (ad.endDate && !DATE_RE.test(ad.endDate)) e.push('Bitiş tarihi geçersiz.');
  if (ad.startDate && ad.endDate && ad.endDate < ad.startDate) e.push('Bitiş tarihi başlangıçtan önce olamaz.');
  return e;
}

/**
 * Bu reklam kaydedilirse, açık (kapalı değil, süresi dolmamış) reklam sayısı sınırı aşılacak yerler.
 * Boş dönerse sorun yok.
 */
export function placementOverflow(others: Ad[], ad: Ad, today = todayKey()): AdPlacement[] {
  if (!ad.active || adStatus(ad, today) === 'expired') return [];
  return ad.placements.filter((p) => {
    const count = others.filter(
      (o) => o.id !== ad.id && o.placements.includes(p) && o.active && adStatus(o, today) !== 'expired',
    ).length;
    return count + 1 > MAX_ADS_PER_PLACEMENT;
  });
}
