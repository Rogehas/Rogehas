'use client';
import { useCallback, useEffect, useState } from 'react';
import { Shell } from '@/components/Shell';
import { useSession } from '@/lib/session';
import { store } from '@/lib/store';
import { COMPLAINT_STATUS_LABEL, type ComplaintItem, type ComplaintStatus } from '@/lib/types';

const when = (iso: string) => (iso ? new Date(iso).toLocaleString('tr-TR', { dateStyle: 'short', timeStyle: 'short' }) : '');
const FILTERS: ('all' | ComplaintStatus)[] = ['all', 'new', 'progress', 'resolved', 'closed'];

export default function Complaints() {
  const { user } = useSession();
  const [items, setItems] = useState<ComplaintItem[]>([]);
  const [filter, setFilter] = useState<'all' | ComplaintStatus>('new');
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  const refresh = useCallback(async () => {
    try {
      setItems(await store.complaints());
    } catch {
      setError('Şikâyetler yüklenemedi.');
    }
  }, []);
  useEffect(() => {
    if (user) void refresh();
  }, [user, refresh]);

  async function answer(c: ComplaintItem, status: ComplaintStatus) {
    setError('');
    setInfo('');
    try {
      await store.answerComplaint(c.id, status, (drafts[c.id] ?? c.reply).trim(), user!.id);
      await refresh();
      setInfo(`“${c.category}” kaydı “${COMPLAINT_STATUS_LABEL[status]}” olarak işaretlendi. Yanıt kullanıcının uygulamasında görünür.`);
    } catch (e) {
      setError((e as Error).message);
    }
  }

  const shown = items.filter((c) => filter === 'all' || c.status === filter);
  const count = (s: ComplaintStatus) => items.filter((c) => c.status === s).length;

  return (
    <Shell section="sikayet" title="Şikâyet ve öneriler">
      {error && <div className="err" role="alert">{error}</div>}
      {info && <div className="note" role="status">{info}</div>}
      <div className="tabs" role="tablist">
        {FILTERS.map((f) => (
          <button key={f} role="tab" aria-selected={filter === f} className={`tab${filter === f ? ' on' : ''}`} onClick={() => setFilter(f)}>
            {f === 'all' ? 'Tümü' : `${COMPLAINT_STATUS_LABEL[f]} (${count(f)})`}
          </button>
        ))}
      </div>
      <div className="card">
        {shown.length === 0 && <p className="muted">Bu listede kayıt yok.</p>}
        {shown.map((c) => (
          <div className="row" key={c.id} style={{ alignItems: 'flex-start' }}>
            <div className="grow">
              <strong>{c.category}</strong>{' '}
              <span className="badge">{COMPLAINT_STATUS_LABEL[c.status]}</span>
              <div className="muted">
                {c.name} · {c.email}{c.neighborhood ? ` · ${c.neighborhood}` : ''} · {when(c.createdAt)}
              </div>
              <p style={{ margin: '8px 0' }}>{c.text}</p>
              <div className="field">
                <label htmlFor={`r-${c.id}`}>Yanıt (kullanıcı uygulamada görür)</label>
                <textarea id={`r-${c.id}`} value={drafts[c.id] ?? c.reply} onChange={(e) => setDrafts({ ...drafts, [c.id]: e.target.value })} />
              </div>
              <div className="actions" style={{ marginTop: 8 }}>
                <button className="btn sm" onClick={() => void answer(c, 'progress')}>İnceleniyor</button>
                <button className="btn sm lime" onClick={() => void answer(c, 'resolved')}>Çözüldü</button>
                <button className="btn sm" onClick={() => void answer(c, 'closed')}>Kapat</button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </Shell>
  );
}
