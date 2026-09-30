'use client';
import Link from 'next/link';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Shell } from '@/components/Shell';
import {
  canApproveVefat,
  canArchiveVefat,
  canEditVefat,
  canPublishDirect,
} from '@/lib/permissions';
import { useSession } from '@/lib/session';
import { store } from '@/lib/store';
import { STATUS_LABEL, type Vefat, type VefatStatus } from '@/lib/types';
import { transition, type VefatAction } from '@/lib/vefat-rules';

const TABS: { key: VefatStatus | 'all'; label: string }[] = [
  { key: 'all', label: 'Tümü' },
  { key: 'pending', label: 'Onay bekleyen' },
  { key: 'draft', label: 'Taslak' },
  { key: 'published', label: 'Yayında' },
  { key: 'rejected', label: 'Reddedilen' },
  { key: 'archived', label: 'Arşiv' },
];

export default function VefatList() {
  const { user } = useSession();
  const [items, setItems] = useState<Vefat[]>([]);
  const [tab, setTab] = useState<VefatStatus | 'all'>('all');
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  const refresh = useCallback(() => setItems(store.vefat()), []);
  useEffect(refresh, [refresh]);

  const shown = useMemo(() => items.filter((v) => tab === 'all' || v.status === tab), [items, tab]);
  const owners = useMemo(() => new Map(store.users().map((u) => [u.id, u.name])), [items]);

  function run(v: Vefat, action: VefatAction) {
    if (!user) return;
    setError('');
    setInfo('');
    try {
      let note: string | undefined;
      if (action === 'reject') {
        note = window.prompt('Reddetme nedeni (editör bunu görecek):') ?? undefined;
        if (note === undefined) return;
      }
      const res = transition(v, action, user, note);
      store.upsertVefat(res.vefat, res.notice);
      if (res.notice) setInfo(`Yayınlandı. Bildirim kuyruğa alındı: “${res.notice.body}”`);
      refresh();
    } catch (e) {
      setError((e as Error).message);
    }
  }

  return (
    <Shell
      section="vefat"
      title="Vefat ilanları"
      actions={
        <Link className="btn dark" href="/vefat/new">
          + Yeni ilan
        </Link>
      }
    >
      {error && <div className="err" role="alert">{error}</div>}
      {info && <div className="note" role="status">{info}</div>}
      <div className="tabs" role="tablist">
        {TABS.map((t) => (
          <button key={t.key} role="tab" aria-selected={tab === t.key} className={`tab${tab === t.key ? ' on' : ''}`} onClick={() => setTab(t.key)}>
            {t.label}
          </button>
        ))}
      </div>
      <div className="card">
        {shown.length === 0 && <p className="muted">Bu listede ilan yok.</p>}
        {user && shown.map((v) => (
          <div className="row" key={v.id}>
            <div className="avatar">
              {v.photo ? <img src={v.photo} alt={`${v.name} fotoğrafı`} /> : v.name.slice(0, 1)}
            </div>
            <div className="grow">
              <strong style={{ fontSize: 17 }}>{v.name}</strong>{' '}
              <span className={`badge ${v.status}`}>{STATUS_LABEL[v.status]}</span>
              <div className="muted">
                {v.age} yaşında · {v.neighborhood} · Cenaze namazı {v.prayerDate} {v.prayerTime}, {v.mosque}
              </div>
              <div className="muted">Hazırlayan: {owners.get(v.createdBy) ?? '—'}</div>
              {v.status === 'rejected' && v.rejectionNote && (
                <div className="muted" style={{ color: 'var(--clay)', fontWeight: 700 }}>
                  Red nedeni: {v.rejectionNote}
                </div>
              )}
            </div>
            <div className="actions">
              {canEditVefat(user, v) && (
                <Link className="btn sm" href={`/vefat/${v.id}`}>Düzenle</Link>
              )}
              {canApproveVefat(user, v) && (
                <>
                  <button className="btn sm lime" onClick={() => run(v, 'approve')}>Onayla ve yayınla</button>
                  <button className="btn sm danger" onClick={() => run(v, 'reject')}>Reddet</button>
                </>
              )}
              {canPublishDirect(user, v) && (
                <button className="btn sm lime" onClick={() => run(v, 'publish')}>Doğrudan yayınla</button>
              )}
              {canArchiveVefat(user, v) && (
                <button className="btn sm" onClick={() => run(v, 'archive')}>Arşivle</button>
              )}
            </div>
          </div>
        ))}
      </div>
    </Shell>
  );
}
