'use client';
import { useParams, useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { Shell } from '@/components/Shell';
import { resizePhoto } from '@/lib/image';
import { applyNewsEdit, transitionNews, validateNews } from '@/lib/news-rules';
import { canEditNews } from '@/lib/permissions';
import { useSession } from '@/lib/session';
import { store } from '@/lib/store';
import { KIND_LABEL, type News, type NewsKind } from '@/lib/types';

function blank(userId: string, userName: string): News {
  const t = new Date().toISOString();
  return {
    id: `h_${Date.now()}`, kind: 'haber', subLabel: '', title: '', body: '', source: '', photo: null,
    sendPush: false, status: 'draft', createdBy: userId, createdByName: userName, createdAt: t, updatedAt: t,
  };
}

export default function NewsEdit() {
  const { id } = useParams<{ id: string }>();
  const { user } = useSession();
  const router = useRouter();
  const isNew = id === 'new';
  const [n, setN] = useState<News | null>(null);
  const [error, setError] = useState('');
  const [missing, setMissing] = useState(false);

  useEffect(() => {
    if (!user) return;
    if (isNew) return setN(blank(user.id, user.name));
    store
      .newsById(id)
      .then((f) => (f ? setN(f) : setMissing(true)))
      .catch(() => setError('Haber yüklenemedi.'));
  }, [id, isNew, user]);

  const set = <K extends keyof News>(k: K, v: News[K]) => setN((p) => (p ? { ...p, [k]: v } : p));

  async function persist(): Promise<News | null> {
    if (!user || !n) return null;
    setError('');
    try {
      const existing = isNew ? null : await store.newsById(n.id);
      const toSave = existing ? applyNewsEdit(user, existing, n) : n;
      await store.upsertNews(toSave);
      return toSave;
    } catch (e) {
      setError((e as Error).message);
      return null;
    }
  }

  async function publish() {
    if (!user) return;
    const saved = await persist();
    if (!saved) return;
    try {
      const r = transitionNews(saved, 'publish', user);
      await store.upsertNews(r.news, r.notice);
      router.push('/haberler');
    } catch (e) {
      setError((e as Error).message);
    }
  }

  async function pickPhoto(file?: File) {
    if (!file) return;
    try {
      set('photo', await resizePhoto(file));
    } catch (e) {
      setError((e as Error).message);
    }
  }

  const editable = !!user && !!n && (isNew || canEditNews(user, n));
  const problems = n ? validateNews(n) : [];
  const alreadyPublished = n?.status === 'published';

  return (
    <Shell section="haber" title={isNew ? 'Yeni haber' : 'Haberi düzenle'}>
      {missing && <div className="err">Haber bulunamadı.</div>}
      {n && !editable && <div className="err">Bu haberi düzenleme yetkin yok.</div>}
      {n && editable && (
        <div className="card">
          {error && <div className="err" role="alert">{error}</div>}
          <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap' }}>
            <div>
              <div className="photo">{n.photo ? <img src={n.photo} alt="Seçilen görsel" /> : <span>Görsel yok<br />(isteğe bağlı)</span>}</div>
              <div className="actions" style={{ marginTop: 10 }}>
                <label className="btn sm">
                  {n.photo ? 'Değiştir' : 'Görsel seç'}
                  <input type="file" accept="image/*" hidden onChange={(e) => pickPhoto(e.target.files?.[0])} />
                </label>
                {n.photo && <button className="btn sm danger" onClick={() => set('photo', null)}>Kaldır</button>}
              </div>
            </div>
            <div className="fields" style={{ flex: 1, minWidth: 280, alignContent: 'start' }}>
              <div className="field">
                <label htmlFor="kind">Tür</label>
                <select id="kind" value={n.kind} onChange={(e) => set('kind', e.target.value as NewsKind)}>
                  {(Object.keys(KIND_LABEL) as NewsKind[]).map((k) => <option key={k} value={k}>{KIND_LABEL[k]}</option>)}
                </select>
              </div>
              {n.kind === 'kesinti' && (
                <div className="field"><label htmlFor="sub">Kesinti türü</label><input id="sub" placeholder="SU, ELEKTRİK…" value={n.subLabel} onChange={(e) => set('subLabel', e.target.value)} /></div>
              )}
              <div className="field"><label htmlFor="src">Kaynak</label><input id="src" placeholder="Belediye, Editör…" value={n.source} onChange={(e) => set('source', e.target.value)} /></div>
              <div className="field" style={{ gridColumn: '1 / -1' }}><label htmlFor="title">Başlık</label><input id="title" value={n.title} onChange={(e) => set('title', e.target.value)} /></div>
              <div className="field" style={{ gridColumn: '1 / -1' }}><label htmlFor="body">Metin</label><textarea id="body" style={{ height: 180 }} value={n.body} onChange={(e) => set('body', e.target.value)} /></div>
            </div>
          </div>

          {!alreadyPublished && (
            <label className="check" style={{ margin: '20px 0' }}>
              <input type="checkbox" checked={n.sendPush} onChange={(e) => set('sendPush', e.target.checked)} />
              <span>Yayınlanınca telefonlara bildirim gönder</span>
            </label>
          )}
          {n.sendPush && !alreadyPublished && (
            <div className="note"><strong>Bildirim önizlemesi:</strong> {n.kind === 'kesinti' ? `Kesinti · ${n.subLabel || '…'}` : KIND_LABEL[n.kind]} — {n.title || '…'}</div>
          )}
          {problems.length > 0 && <p className="muted" role="status">Yayınlamak için eksikler: {problems.join(' ')}</p>}
          <div className="actions" style={{ marginTop: 12 }}>
            <button className="btn" onClick={async () => { if (await persist()) router.push('/haberler'); }}>{alreadyPublished ? 'Değişiklikleri kaydet' : 'Taslağı kaydet'}</button>
            {!alreadyPublished && <button className="btn dark" disabled={problems.length > 0} onClick={() => void publish()}>Yayınla</button>}
          </div>
        </div>
      )}
    </Shell>
  );
}
