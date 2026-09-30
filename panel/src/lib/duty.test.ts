import { describe, expect, it } from 'vitest';
import { addDays, dateRange, MAX_SPAN_DAYS, normalizePhone, todayString, validatePharmacy, weekdayName } from './duty';

describe('nöbet tarihleri', () => {
  it('aralık iki ucu da içerir ve ay/yıl sınırını geçer', () => {
    expect(dateRange('2026-09-29', '2026-10-02')).toEqual(['2026-09-29', '2026-09-30', '2026-10-01', '2026-10-02']);
    expect(dateRange('2026-12-31', '2027-01-01')).toEqual(['2026-12-31', '2027-01-01']);
    expect(dateRange('2026-09-30', '2026-09-30')).toEqual(['2026-09-30']);
  });
  it('artık yıl şubat ayını doğru sayar', () => {
    expect(dateRange('2028-02-28', '2028-03-01')).toEqual(['2028-02-28', '2028-02-29', '2028-03-01']);
  });
  it('geçersiz, ters ve çok geniş aralık reddedilir', () => {
    expect(() => dateRange('2026-02-31', '2026-03-05')).toThrow();
    expect(() => dateRange('abc', '2026-03-05')).toThrow();
    expect(() => dateRange('2026-10-02', '2026-10-01')).toThrow(/önce/);
    expect(() => dateRange('2026-01-01', '2026-12-31')).toThrow(new RegExp(String(MAX_SPAN_DAYS)));
  });
  it('gün ekleme, gün adı ve yerel bugün', () => {
    expect(addDays('2026-09-30', 1)).toBe('2026-10-01');
    expect(addDays('2026-03-01', -1)).toBe('2026-02-28');
    expect(weekdayName('2026-09-30')).toBe('Çarşamba');
    expect(todayString(new Date(2026, 8, 5, 23, 30))).toBe('2026-09-05');
  });
});

describe('telefon ve eczane doğrulama', () => {
  it('telefon biçimleri 0 ile başlayan 11 haneye çevrilir', () => {
    expect(normalizePhone('0258 614 00 00')).toBe('02586140000');
    expect(normalizePhone('+90 (258) 614-00-00')).toBe('02586140000');
    expect(normalizePhone('2586140000')).toBe('02586140000');
    expect(normalizePhone('12345')).toBe('');
    expect(normalizePhone('')).toBe('');
  });
  const ok = { name: 'Örnek Eczanesi', address: 'Merkez Mah.', phone: '0258 614 00 00', lat: null, lng: null };
  it('geçerli eczane hata vermez; eksikler ve yarım koordinat yakalanır', () => {
    expect(validatePharmacy(ok)).toEqual([]);
    expect(validatePharmacy({ ...ok, name: ' ', phone: 'x' }).length).toBe(2);
    expect(validatePharmacy({ ...ok, lat: 37.5, lng: null })).toContain('Enlem ve boylam birlikte girilmeli (ya da ikisi de boş).');
    expect(validatePharmacy({ ...ok, lat: 95, lng: 29 }).length).toBe(1);
  });
});
