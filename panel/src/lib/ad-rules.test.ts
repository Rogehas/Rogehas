import { describe, expect, it } from 'vitest';
import { adStatus, MAX_ADS_PER_PLACEMENT, normalizeAd, placementOverflow, validateAd } from './ad-rules';
import type { Ad } from './types';

const ad = (over: Partial<Ad> = {}): Ad => ({
  id: 'a1', name: 'Tavas Fırını', text: 'Sıcak simit', photo: null, action: 'call', actionValue: '0258 614 00 00',
  placements: ['home'], startDate: '', endDate: '', active: true, createdAt: '', updatedAt: '', updatedBy: '', ...over,
});

describe('validateAd', () => {
  it('geçerli reklamda hata yok', () => {
    expect(validateAd(ad())).toEqual([]);
    expect(validateAd(ad({ action: 'map', actionValue: 'Cumhuriyet Cd. No:3, Tavas' }))).toEqual([]);
    expect(validateAd(ad({ action: 'web', actionValue: 'tavasfirini.com' }))).toEqual([]);
  });
  it('eksik alanları yakalar', () => {
    expect(validateAd(ad({ name: ' ' }))).toContain('Esnaf / reklam veren adı gerekli.');
    expect(validateAd(ad({ text: '' }))).toContain('Kısa metin gerekli.');
    expect(validateAd(ad({ text: 'a'.repeat(81) })).join()).toContain('en fazla 80');
    expect(validateAd(ad({ placements: [] }))).toContain('En az bir yer seçin.');
    expect(validateAd(ad({ actionValue: '12' }))).toContain('Geçerli bir telefon numarası girin.');
    expect(validateAd(ad({ action: 'web', actionValue: 'merhaba' }))).toContain('Geçerli bir web adresi girin.');
    expect(validateAd(ad({ action: 'map', actionValue: 'abc' }))).toContain('Haritada açılacak adresi yazın.');
  });
  it('tarih sırasını denetler', () => {
    expect(validateAd(ad({ startDate: '2026-10-10', endDate: '2026-10-01' }))).toContain('Bitiş tarihi başlangıçtan önce olamaz.');
    expect(validateAd(ad({ startDate: 'x' }))).toContain('Başlangıç tarihi geçersiz.');
  });
});

describe('normalizeAd', () => {
  it('telefonu rakamlara, web adresini https biçimine çevirir', () => {
    expect(normalizeAd(ad()).actionValue).toBe('02586140000');
    expect(normalizeAd(ad({ action: 'web', actionValue: ' tavasfirini.com ' })).actionValue).toBe('https://tavasfirini.com');
    expect(normalizeAd(ad({ action: 'web', actionValue: 'http://x.com' })).actionValue).toBe('http://x.com');
  });
});

describe('adStatus', () => {
  it('kapalı, başlamadı, yayında, süresi doldu', () => {
    const t = '2026-10-10';
    expect(adStatus(ad({ active: false }), t)).toBe('off');
    expect(adStatus(ad({ startDate: '2026-10-11' }), t)).toBe('scheduled');
    expect(adStatus(ad({ startDate: '2026-10-10', endDate: '2026-10-10' }), t)).toBe('live');
    expect(adStatus(ad({ endDate: '2026-10-09' }), t)).toBe('expired');
    expect(adStatus(ad(), t)).toBe('live');
  });
});

describe('placementOverflow', () => {
  const t = '2026-10-10';
  const many = (n: number, over: Partial<Ad> = {}) => Array.from({ length: n }, (_, i) => ad({ id: `o${i}`, ...over }));
  it('sınır dolunca yeni açık reklam reddedilir', () => {
    expect(placementOverflow(many(MAX_ADS_PER_PLACEMENT - 1), ad({ id: 'yeni' }), t)).toEqual([]);
    expect(placementOverflow(many(MAX_ADS_PER_PLACEMENT), ad({ id: 'yeni' }), t)).toEqual(['home']);
  });
  it('kapalı, süresi dolmuş veya başka yerdeki reklamlar sayılmaz; kendisi sayılmaz', () => {
    const others = [...many(2), ad({ id: 'k', active: false }), ad({ id: 'e', endDate: '2026-01-01' }), ad({ id: 'b', placements: ['nav'] })];
    expect(placementOverflow(others, ad({ id: 'yeni' }), t)).toEqual([]);
    expect(placementOverflow(many(3), ad({ id: 'o0' }), t)).toEqual([]);
  });
  it('kapalı reklamı kaydetmek sınırı aşmaz', () => {
    expect(placementOverflow(many(3), ad({ id: 'yeni', active: false }), t)).toEqual([]);
  });
});
