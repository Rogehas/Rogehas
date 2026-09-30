import { describe, expect, it } from 'vitest';
import { applyNewsEdit, transitionNews, validateNews } from './news-rules';
import { canAccess } from './permissions';
import type { News, PanelUser } from './types';

const admin: PanelUser = { id: 'a', name: 'A', email: 'a@x', role: 'admin', active: true };
const editor: PanelUser = { id: 'e', name: 'E', email: 'e@x', role: 'editor', active: true };
const editor2: PanelUser = { id: 'e2', name: 'E2', email: 'e2@x', role: 'editor', active: true };
const mod: PanelUser = { id: 'm', name: 'M', email: 'm@x', role: 'moderator', active: true };

const news = (over: Partial<News> = {}): News => ({
  id: 'n1', kind: 'kesinti', subLabel: 'SU', title: 'Yarın su kesintisi', body: '09:00–14:00',
  source: 'Belediye', photo: null, sendPush: true, status: 'draft', createdBy: 'e',
  createdAt: '2026-09-30T08:00:00Z', updatedAt: '2026-09-30T08:00:00Z', ...over,
});

describe('haber yönetimi', () => {
  it('moderatör haber bölümüne giremez', () => {
    expect(canAccess('moderator', 'haber')).toBe(false);
    expect(() => transitionNews(news(), 'publish', mod)).toThrow();
  });

  it('editör onay olmadan yayınlar ve bildirim üretir', () => {
    const r = transitionNews(news(), 'publish', editor);
    expect(r.news.status).toBe('published');
    expect(r.notice?.title).toBe('Kesinti · SU');
    expect(r.notice?.body).toBe('Yarın su kesintisi');
  });

  it('bildirim kapalıysa bildirim üretilmez', () => {
    expect(transitionNews(news({ sendPush: false }), 'publish', editor).notice).toBeUndefined();
  });

  it('başka editör de düzenleyebilir, durum ve sahibi değişmez', () => {
    const saved = applyNewsEdit(editor2, news(), news({ title: 'Yeni', status: 'archived', createdBy: 'x' }));
    expect(saved.title).toBe('Yeni');
    expect(saved.status).toBe('draft');
    expect(saved.createdBy).toBe('e');
  });

  it('kesintide tür zorunlu, başlık ve metin boş olamaz', () => {
    expect(validateNews(news({ subLabel: '' }))).toContain('Kesinti türü (ör. SU) gerekli.');
    expect(validateNews(news({ title: ' ', body: '' })).length).toBe(2);
    expect(() => transitionNews(news({ title: '' }), 'publish', editor)).toThrow();
  });

  it('yalnızca yönetici arşivler; arşivlenen düzenlenemez', () => {
    const pub = news({ status: 'published' });
    expect(() => transitionNews(pub, 'archive', editor)).toThrow();
    const arch = transitionNews(pub, 'archive', admin).news;
    expect(arch.status).toBe('archived');
    expect(() => applyNewsEdit(admin, arch, arch)).toThrow();
  });
});
