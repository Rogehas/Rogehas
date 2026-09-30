import { describe, expect, it } from 'vitest';
import { normalizeAnyPhone, validateBusiness, validateEvent, validateGuide } from './content';

describe('esnek telefon', () => {
  it('acil, 444 ve normal numaraları kabul eder, bozukları reddeder', () => {
    expect(normalizeAnyPhone('112')).toBe('112');
    expect(normalizeAnyPhone('444 1 444')).toBe('4441444');
    expect(normalizeAnyPhone('+90 258 614 00 00')).toBe('02586140000');
    expect(normalizeAnyPhone('12')).toBe('');
    expect(normalizeAnyPhone('12345')).toBe('');
    expect(normalizeAnyPhone('')).toBe('');
  });
});

describe('etkinlik', () => {
  const ok = { title: 'Pazar', date: '2026-10-04', endDate: '', time: '10:00', place: 'Pazar alanı' };
  it('geçerli etkinlik hata vermez; saat ve bitiş isteğe bağlı', () => {
    expect(validateEvent(ok)).toEqual([]);
    expect(validateEvent({ ...ok, time: '', endDate: '2026-10-06' })).toEqual([]);
  });
  it('eksik alan, ters tarih ve bozuk saat yakalanır', () => {
    expect(validateEvent({ ...ok, title: ' ', place: '' }).length).toBe(2);
    expect(validateEvent({ ...ok, endDate: '2026-10-03' })).toContain('Bitiş tarihi başlangıçtan önce olamaz.');
    expect(validateEvent({ ...ok, time: '25:00' })).toContain('Saat SS:DD biçiminde olmalı (ör. 18:30).');
    expect(validateEvent({ ...ok, date: '' })).toContain('Başlangıç tarihi gerekli.');
  });
});

describe('rehber ve esnaf', () => {
  it('rehber: ad, kategori, telefon ve sıra zorunlu', () => {
    expect(validateGuide({ name: 'Acil', category: 'Acil', phone: '112', order: 1 })).toEqual([]);
    expect(validateGuide({ name: '', category: '', phone: 'x', order: NaN }).length).toBe(4);
  });
  it('esnaf: telefon isteğe bağlı ama girilirse geçerli olmalı; koordinat birlikte', () => {
    const ok = { name: 'Lokanta', category: 'Restoran', phone: '', lat: null, lng: null };
    expect(validateBusiness(ok)).toEqual([]);
    expect(validateBusiness({ ...ok, phone: '12345' })).toContain('Telefon geçersiz (ör. 0258 614 00 00).');
    expect(validateBusiness({ ...ok, lat: 37.5, lng: null }).length).toBe(1);
    expect(validateBusiness({ ...ok, lat: 99, lng: 29 }).length).toBe(1);
  });
});
