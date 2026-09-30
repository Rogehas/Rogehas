import { canArchiveNews, canEditNews, canPublishNews } from './permissions';
import type { News, PanelUser, PushNotice } from './types';

export function validateNews(n: News): string[] {
  const e: string[] = [];
  if (!n.title.trim()) e.push('Başlık gerekli.');
  if (!n.body.trim()) e.push('Metin gerekli.');
  if (n.kind === 'kesinti' && !n.subLabel.trim()) e.push('Kesinti türü (ör. SU) gerekli.');
  return e;
}

const now = () => new Date().toISOString();

export function newsNotice(n: News): PushNotice {
  const prefix = n.kind === 'kesinti' ? `Kesinti · ${n.subLabel.trim()}` : n.kind === 'duyuru' ? 'Duyuru' : 'Haber';
  return {
    id: `n_${n.id}_${Date.now()}`,
    topic: n.kind,
    newsId: n.id,
    title: prefix,
    body: n.title.trim(),
    createdAt: now(),
  };
}

export type NewsAction = 'publish' | 'archive';

export function transitionNews(n: News, action: NewsAction, actor: PanelUser): { news: News; notice?: PushNotice } {
  if (action === 'publish') {
    if (!canPublishNews(actor, n)) throw new Error('Bu haberi yayınlama yetkin yok.');
    const errs = validateNews(n);
    if (errs.length) throw new Error(errs.join(' '));
    const news: News = { ...n, status: 'published', publishedAt: now(), publishedBy: actor.id, updatedAt: now() };
    return { news, notice: n.sendPush ? newsNotice(news) : undefined };
  }
  if (!canArchiveNews(actor, n)) throw new Error('Arşivleme yetkisi yalnızca yöneticidedir.');
  return { news: { ...n, status: 'archived', updatedAt: now() } };
}

export function applyNewsEdit(actor: PanelUser, existing: News, next: News): News {
  if (!canEditNews(actor, existing)) throw new Error('Bu haberi düzenleme yetkin yok.');
  return {
    ...next,
    id: existing.id,
    status: existing.status,
    createdBy: existing.createdBy,
    createdByName: existing.createdByName,
    createdAt: existing.createdAt,
    publishedAt: existing.publishedAt,
    publishedBy: existing.publishedBy,
    updatedAt: now(),
  };
}
