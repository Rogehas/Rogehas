'use client';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Shell } from '@/components/Shell';
import { filterMembers } from '@/lib/members';
import { useSession } from '@/lib/session';
import { store } from '@/lib/store';
import type { Member } from '@/lib/types';

const day = (iso: string) => (iso ? new Date(iso).toLocaleDateString('tr-TR', { dateStyle: 'medium' }) : '—');

export default function Members() {
  const { user } = useSession();
  const [members, setMembers] = useState<Member[]>([]);
  const [muted, setMuted] = useState<Set<string>>(new Set());
  const [q, setQ] = useState('');
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');
  const [loaded, setLoaded] = useState(false);

  const refresh = useCallback(async () => {
    try {
      const [m, mu] = await Promise.all([store.members(), store.mutes()]);
      setMembers(m);
      setMuted(new Set(mu.map((x) => x.uid)));
      setLoaded(true);
    } catch {
      setError('Üyeler yüklenemedi.');
    }
  }, []);
  useEffect(() => {
    if (user) void refresh();
  }, [user, refresh]);

  async function act(run: () => Promise<void>, done: string) {
    setError('');
    setInfo('');
    try {
      await run();
      await refresh();
      setInfo(done);
    } catch (e) {
      setError((e as Error).message);
    }
  }

  const shown = useMemo(() => filterMembers(members, q), [members, q]);

  return (
    <Shell section="uye" title="Üyeler">
      {error && <div className="err" role="alert">{error}</div>}
      {info && <div className="note" role="status">{info}</div>}

      <div className="card" style={{ marginBottom: 20 }}>
        <p style={{ marginTop: 0 }}>
          <strong>Toplam üye: {members.length}</strong>
          {muted.size > 0 && <span className="muted"> · susturulan: {muted.size}</span>}
        </p>
        <p className="muted">
          Üyeler uygulamaya ilk girişlerinde bu listeye eklenir; bu özellikten önce kayıt olanlar uygulamayı açıp giriş yapınca görünür.
          Susturulan üye sohbette ve yorumlarda yazmaya devam eder, yazdıklarını kendisi görür ama başkaları görmez; susturulduğunu anlamaz.
        </p>
        <div className="field">
          <label htmlFor="q">Ara (ad veya e-posta)</label>
          <input id="q" value={q} onChange={(e) => setQ(e.target.value)} placeholder="Örn. ayşe" />
        </div>
      </div>

      <div className="card">
        {!loaded && !error && <p className="muted">Yükleniyor…</p>}
        {loaded && members.length === 0 && <p className="muted">Henüz kayıtlı üye yok.</p>}
        {loaded && members.length > 0 && shown.length === 0 && <p className="muted">Aramaya uyan üye yok.</p>}
        {shown.map((m) => {
          const isMuted = muted.has(m.uid);
          return (
            <div className="row" key={m.uid}>
              <div className="grow">
                <strong>{m.name}</strong>{isMuted && <span className="muted"> · susturulmuş</span>}
                <div className="muted">{m.email} · Kayıt: {day(m.createdAt)}</div>
              </div>
              <div className="actions">
                {isMuted ? (
                  <button className="btn sm lime" onClick={() => void act(() => store.unmute(m.uid), `${m.name} için susturma kaldırıldı.`)}>
                    Susturmayı kaldır
                  </button>
                ) : (
                  <button className="btn sm" onClick={() => void act(() => store.mute(m.uid, m.name, user!.id), `${m.name} susturuldu.`)}>
                    Sustur
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </Shell>
  );
}
