import type { Pharmacy } from './types';

/** Bir seferde en fazla bu kadar gün için nöbet yazılır (yanlışlıkla çok geniş aralık girilmesin). */
export const MAX_SPAN_DAYS = 62;

const DATE_RE = /^(\d{4})-(\d{2})-(\d{2})$/;

function parse(d: string): Date | null {
  const m = DATE_RE.exec(d);
  if (!m) return null;
  const [y, mo, da] = [Number(m[1]), Number(m[2]), Number(m[3])];
  const t = new Date(Date.UTC(y, mo - 1, da));
  // 31 Şubat gibi geçersiz tarihleri ele
  return t.getUTCFullYear() === y && t.getUTCMonth() === mo - 1 && t.getUTCDate() === da ? t : null;
}

const fmt = (t: Date) => t.toISOString().slice(0, 10);

/** Yerel saate göre bugünün tarihi (yyyy-mm-dd). */
export function todayString(now = new Date()): string {
  const p = (n: number) => String(n).padStart(2, '0');
  return `${now.getFullYear()}-${p(now.getMonth() + 1)}-${p(now.getDate())}`;
}

/** İki tarih dahil olmak üzere aradaki tüm günler. */
export function dateRange(start: string, end: string): string[] {
  const s = parse(start);
  const e = parse(end);
  if (!s || !e) throw new Error('Geçerli bir başlangıç ve bitiş tarihi girin.');
  if (e < s) throw new Error('Bitiş tarihi başlangıçtan önce olamaz.');
  const days = Math.round((e.getTime() - s.getTime()) / 86_400_000) + 1;
  if (days > MAX_SPAN_DAYS) throw new Error(`En fazla ${MAX_SPAN_DAYS} günlük aralık girilebilir.`);
  return Array.from({ length: days }, (_, i) => fmt(new Date(s.getTime() + i * 86_400_000)));
}

export function addDays(date: string, n: number): string {
  const t = parse(date);
  if (!t) throw new Error('Geçersiz tarih.');
  return fmt(new Date(t.getTime() + n * 86_400_000));
}

const WEEKDAYS = ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'];
export function weekdayName(date: string): string {
  const t = parse(date);
  return t ? WEEKDAYS[t.getUTCDay()] : '';
}

/** Telefonu rakamlara çevirir: "+90 258 614 00 00" → "02586140000". Geçersizse boş döner. */
export function normalizePhone(input: string): string {
  let d = input.replace(/\D/g, '');
  if (d.startsWith('90') && d.length === 12) d = '0' + d.slice(2);
  else if (d.length === 10) d = '0' + d;
  return /^0\d{10}$/.test(d) ? d : '';
}

export function validatePharmacy(p: Pick<Pharmacy, 'name' | 'address' | 'phone' | 'lat' | 'lng'>): string[] {
  const e: string[] = [];
  if (!p.name.trim()) e.push('Eczane adı gerekli.');
  if (!p.address.trim()) e.push('Adres gerekli.');
  if (!normalizePhone(p.phone)) e.push('Geçerli bir telefon girin (ör. 0258 614 00 00).');
  if ((p.lat === null) !== (p.lng === null)) e.push('Enlem ve boylam birlikte girilmeli (ya da ikisi de boş).');
  if (p.lat !== null && (p.lat < -90 || p.lat > 90)) e.push('Enlem -90 ile 90 arasında olmalı.');
  if (p.lng !== null && (p.lng < -180 || p.lng > 180)) e.push('Boylam -180 ile 180 arasında olmalı.');
  return e;
}
