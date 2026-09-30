import { normalizePhone } from './duty';
import type { Business, EventItem, GuideEntry } from './types';

/**
 * Esnek telefon doğrulama: acil/kısa numaralar (112, 155), 444'lü çağrı merkezleri ve 0'lı 11 haneli numaralar.
 * Geçersizse boş döner.
 */
export function normalizeAnyPhone(input: string): string {
  const digits = input.replace(/\D/g, '');
  if (/^\d{3}$/.test(digits)) return digits; // 112, 155, 110 ...
  if (/^444\d{4}$/.test(digits)) return digits; // 444 1 444
  return normalizePhone(input);
}

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d$/;

export function validateEvent(e: Pick<EventItem, 'title' | 'date' | 'endDate' | 'time' | 'place'>): string[] {
  const errs: string[] = [];
  if (!e.title.trim()) errs.push('Etkinlik adı gerekli.');
  if (!DATE_RE.test(e.date)) errs.push('Başlangıç tarihi gerekli.');
  if (e.endDate && !DATE_RE.test(e.endDate)) errs.push('Bitiş tarihi geçersiz.');
  if (DATE_RE.test(e.date) && DATE_RE.test(e.endDate) && e.endDate < e.date)
    errs.push('Bitiş tarihi başlangıçtan önce olamaz.');
  if (e.time && !TIME_RE.test(e.time)) errs.push('Saat SS:DD biçiminde olmalı (ör. 18:30).');
  if (!e.place.trim()) errs.push('Yer gerekli.');
  return errs;
}

export function validateGuide(g: Pick<GuideEntry, 'name' | 'category' | 'phone' | 'order'>): string[] {
  const errs: string[] = [];
  if (!g.name.trim()) errs.push('Ad gerekli.');
  if (!g.category) errs.push('Kategori seçin.');
  if (!normalizeAnyPhone(g.phone)) errs.push('Geçerli bir telefon girin (ör. 0258 614 00 00 ya da 112).');
  if (!Number.isFinite(g.order)) errs.push('Sıra bir sayı olmalı.');
  return errs;
}

export function validateBusiness(b: Pick<Business, 'name' | 'category' | 'phone' | 'lat' | 'lng'>): string[] {
  const errs: string[] = [];
  if (!b.name.trim()) errs.push('İşletme adı gerekli.');
  if (!b.category) errs.push('Kategori seçin.');
  if (b.phone.trim() && !normalizeAnyPhone(b.phone)) errs.push('Telefon geçersiz (ör. 0258 614 00 00).');
  if ((b.lat === null) !== (b.lng === null)) errs.push('Enlem ve boylam birlikte girilmeli (ya da ikisi de boş).');
  if (b.lat !== null && (b.lat < -90 || b.lat > 90)) errs.push('Enlem -90 ile 90 arasında olmalı.');
  if (b.lng !== null && (b.lng < -180 || b.lng > 180)) errs.push('Boylam -180 ile 180 arasında olmalı.');
  return errs;
}
