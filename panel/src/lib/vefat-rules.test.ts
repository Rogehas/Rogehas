import { describe, expect, it } from 'vitest';
import { canAccess, canEditVefat } from './permissions';
import type { PanelUser, Vefat } from './types';
import { applyEdit, transition, validateVefat } from './vefat-rules';

const admin: PanelUser = { id: 'a1', name: 'Y', email: 'y@x', role: 'admin', active: true };
const ed1: PanelUser = { id: 'e1', name: 'E1', email: 'e1@x', role: 'editor', active: true };
const ed2: PanelUser = { id: 'e2', name: 'E2', email: 'e2@x', role: 'editor', active: true };
const mod: PanelUser = { id: 'm1', name: 'M', email: 'm@x', role: 'moderator', active: true };

const draft = (over: Partial<Vefat> = {}): Vefat => ({
  id: 'v1',
  name: 'Ayşe Örnek',
  age: 78,
  neighborhood: 'Merkez',
  prayerDate: '2026-09-30',
  prayerTime: '13:30',
  mosque: 'Merkez Camii',
  burialPlace: 'Tavas Mezarlığı',
  condolenceAddress: '',
  photo: null,
  familyConsent: true,
  status: 'draft',
  createdBy: 'e1',
  createdAt: '2026-09-30T08:00:00Z',
  updatedAt: '2026-09-30T08:00:00Z',
  ...over,
});

describe('yetkiler', () => {
  it('moderatör vefat bölümüne giremez, yönetici kullanıcı yönetimine girer', () => {
    expect(canAccess('moderator', 'vefat')).toBe(false);
    expect(canAccess('editor', 'kullanici')).toBe(false);
    expect(canAccess('admin', 'kullanici')).toBe(true);
  });

  it('editör başkasının taslağını düzenleyemez', () => {
    expect(canEditVefat(ed1, draft())).toBe(true);
    expect(canEditVefat(ed2, draft())).toBe(false);
    expect(canEditVefat(admin, draft())).toBe(true);
  });

  it('editör onay bekleyen ilanı düzenleyemez', () => {
    expect(canEditVefat(ed1, draft({ status: 'pending' }))).toBe(false);
  });

  it('düzenleme kaydı durumu ve sahibi değiştirmez', () => {
    const saved = applyEdit(ed1, draft(), draft({ name: 'Yeni', status: 'published', createdBy: 'x' }));
    expect(saved.name).toBe('Yeni');
    expect(saved.status).toBe('draft');
    expect(saved.createdBy).toBe('e1');
  });
});

describe('yayın akışı', () => {
  it('editör onaya gönderir ama yayınlayamaz', () => {
    const pending = transition(draft(), 'submit', ed1).vefat;
    expect(pending.status).toBe('pending');
    expect(() => transition(pending, 'approve', ed1)).toThrow();
    expect(() => transition(draft(), 'publish', ed1)).toThrow();
  });

  it('yönetici onaylayınca yayınlanır ve bildirim üretilir', () => {
    const pending = draft({ status: 'pending' });
    const { vefat, notice } = transition(pending, 'approve', admin);
    expect(vefat.status).toBe('published');
    expect(vefat.publishedBy).toBe('a1');
    expect(notice?.title).toBe('Vefat · Ayşe Örnek');
    expect(notice?.body).toContain('13:30');
  });

  it('aile onayı olmadan onaya gönderilemez ve yayınlanamaz', () => {
    const v = draft({ familyConsent: false });
    expect(validateVefat(v)).toContain('Aile onayı alınmadan yayınlanamaz.');
    expect(() => transition(v, 'submit', ed1)).toThrow();
    expect(() => transition(v, 'publish', admin)).toThrow();
  });

  it('reddetme için neden gerekir ve editör düzeltip tekrar gönderebilir', () => {
    const pending = draft({ status: 'pending' });
    expect(() => transition(pending, 'reject', admin)).toThrow();
    const rejected = transition(pending, 'reject', admin, 'Saat hatalı').vefat;
    expect(rejected.rejectionNote).toBe('Saat hatalı');
    expect(canEditVefat(ed1, rejected)).toBe(true);
    expect(transition(rejected, 'submit', ed1).vefat.status).toBe('pending');
  });

  it('yalnızca yönetici arşivler', () => {
    const pub = draft({ status: 'published' });
    expect(() => transition(pub, 'archive', ed1)).toThrow();
    expect(transition(pub, 'archive', admin).vefat.status).toBe('archived');
  });
});
