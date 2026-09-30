'use client';
import Link from 'next/link';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Shell } from '@/components/Shell';
import { canArchiveNews, canEditNews, canPublishNews } from '@/lib/permissions';
import { useSession } from '@/lib/session';
import { store } from '@/lib/store';
import { KIND_LABEL, NEWS_STATUS_LABEL, type News, type NewsKind } from '@/lib/types';
import { transitionNews, type NewsAction } from '@/lib/news-rules';

export default function NewsList() {
  const { user } = useSession();
  const [items, setItems] = useState<News[]>([]);
  const [kind, setKind] = useState<NewsKind | 'all'>('all');
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  const refresh = useCallback(async () => {
    try {
      setItems(await store.news());
    } catch {
      setError('Haberler yüklenemedi.');
    }
  }, []);
  useEffect(() => {
    void refresh();
    try {
      const flash = sessionStorage.getItem('haberFlash');
      if (flash) {
        sessionStorage.removeItem('haberFlash');
        setInfo(flash);
      }
    } catch {
      /* sessionStorage kapalı */
    }
  }, [refresh]);
  const shown = useMemo(() => items.filter((n) => kind === 'all' || n.kind === kind), [items, kind]);

  async function run(n: News, action: NewsAction) {
    if (!user) return;
    setError('');
    setInfo('');
    try {
      const r = transitionNews(n, action, user);
      await store.upsertNews(r.news, r.notice);
      if (r.notice) setInfo(`Yayınlandı. Bildirim kuyruğa alındı: “${r.notice.title} — ${r.notice.body}”`);
      await refresh();
    } catch (e) {
      setError((e as Error).message);
    }
  }

  return (
    <Shell section="haber" title="Haberler" actions={<Link className="btn dark" href="/haberler/edit">+ Yeni haber</Link>}>
      {error && <div className="err" role="alert">{error}</div>}
      {info && <div className="note" role="status">{info}</div>}
      <div className="tabs" role="tablist">
        {(['all', 'haber', 'duyuru', 'kesinti'] as const).map((k) => (
          <button key={k} role="tab" aria-selected={kind === k} className={`tab${kind === k ? ' on' : ''}`} onClick={() => setKind(k)}>
            {k === 'all' ? 'Tümü' : KIND_LABEL[k]}
          </button>
        ))}
      </div>
      <div className="card">
        {shown.length === 0 && <p className="muted">Bu listede haber yok.</p>}
        {user && shown.map((n) => (
          <div className="row" key={n.id}>
            <div className="avatar">{n.photo ? <img src={n.photo} alt="" /> : KIND_LABEL[n.kind][0]}</div>
            <div className="grow">
              <strong style={{ fontSize: 17 }}>{n.title}</strong>{' '}
              <span className={`badge ${n.status}`}>{NEWS_STATUS_LABEL[n.status]}</span>
              <div className="muted">
                {KIND_LABEL[n.kind]}{n.kind === 'kesinti' && n.subLabel ? ` · ${n.subLabel}` : ''} · {n.source || 'Kaynak yok'}
              </div>
            </div>
            <div className="actions">
              {canEditNews(user, n) && <Link className="btn sm" href={`/haberler/edit?id=${n.id}`}>Düzenle</Link>}
              {canPublishNews(user, n) && <button className="btn sm lime" onClick={() => run(n, 'publish')}>Yayınla</button>}
              {canArchiveNews(user, n) && <button className="btn sm" onClick={() => run(n, 'archive')}>Arşivle</button>}
            </div>
          </div>
        ))}
      </div>
    </Shell>
  );
}
