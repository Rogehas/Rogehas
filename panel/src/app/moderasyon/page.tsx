'use client';
import { useCallback, useEffect, useState } from 'react';
import { Shell } from '@/components/Shell';
import { store } from '@/lib/store';
import { useSession } from '@/lib/session';
import type { ChatMsg, ChatReport, Mute } from '@/lib/types';

const when = (iso: string) => (iso ? new Date(iso).toLocaleString('tr-TR', { dateStyle: 'short', timeStyle: 'short' }) : '');

export default function Moderation() {
  const { user } = useSession();
  const [messages, setMessages] = useState<ChatMsg[]>([]);
  const [reports, setReports] = useState<ChatReport[]>([]);
  const [mutes, setMutes] = useState<Mute[]>([]);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  const refresh = useCallback(async () => {
    try {
      const [m, r, mu] = await Promise.all([store.chatMessages(), store.chatReports(), store.mutes()]);
      setMessages(m);
      setReports(r);
      setMutes(mu);
    } catch {
      setError('Sohbet verileri yüklenemedi.');
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

  const isMuted = (uid: string) => mutes.some((m) => m.uid === uid);
  const mute = (uid: string, name: string) =>
    act(() => store.mute(uid, name, user!.id), `${name} susturuldu; artık mesaj yazamaz.`);
  const open = reports.filter((r) => !r.handled);

  return (
    <Shell section="chat" title="Sohbet moderasyonu">
      {error && <div className="err" role="alert">{error}</div>}
      {info && <div className="note" role="status">{info}</div>}

      <div className="card" style={{ marginBottom: 20 }}>
        <h3 style={{ marginTop: 0 }}>Şikâyet edilen mesajlar ({open.length})</h3>
        {open.length === 0 && <p className="muted">Bekleyen şikâyet yok.</p>}
        {open.map((r) => (
          <div className="row" key={r.id}>
            <div className="grow">
              <strong>{r.messageName}</strong> <span className="muted">· {when(r.createdAt)}</span>
              <div>{r.text}</div>
            </div>
            <div className="actions">
              <button className="btn sm danger" onClick={() => void act(async () => {
                await store.setChatHidden(r.messageId, true);
                await store.markReportHandled(r.id);
              }, 'Mesaj gizlendi.')}>Mesajı gizle</button>
              {!isMuted(r.messageUid) && (
                <button className="btn sm" onClick={() => void mute(r.messageUid, r.messageName)}>Kişiyi sustur</button>
              )}
              <button className="btn sm" onClick={() => void act(() => store.markReportHandled(r.id), 'Şikâyet kapatıldı.')}>İşlem yok, kapat</button>
            </div>
          </div>
        ))}
      </div>

      <div className="card" style={{ marginBottom: 20 }}>
        <h3 style={{ marginTop: 0 }}>Susturulanlar ({mutes.length})</h3>
        {mutes.length === 0 && <p className="muted">Susturulan kimse yok.</p>}
        {mutes.map((m) => (
          <div className="row" key={m.uid}>
            <div className="grow"><strong>{m.name}</strong></div>
            <div className="actions">
              <button className="btn sm lime" onClick={() => void act(() => store.unmute(m.uid), `${m.name} için susturma kaldırıldı.`)}>Susturmayı kaldır</button>
            </div>
          </div>
        ))}
      </div>

      <div className="card">
        <h3 style={{ marginTop: 0 }}>Son mesajlar</h3>
        <p className="muted" style={{ marginTop: 0 }}>Gizlenen mesaj uygulamada görünmez; istersen geri açabilirsin.</p>
        {messages.length === 0 && <p className="muted">Henüz mesaj yok.</p>}
        {messages.map((m) => (
          <div className="row" key={m.id} style={m.hidden ? { opacity: 0.55 } : undefined}>
            <div className="grow">
              <strong>{m.name}</strong> <span className="muted">· {when(m.createdAt)}{m.hidden ? ' · gizli' : ''}</span>
              <div>{m.text}</div>
            </div>
            <div className="actions">
              <button className="btn sm" onClick={() => void act(() => store.setChatHidden(m.id, !m.hidden), m.hidden ? 'Mesaj geri açıldı.' : 'Mesaj gizlendi.')}>
                {m.hidden ? 'Geri aç' : 'Gizle'}
              </button>
              {!isMuted(m.uid) && <button className="btn sm" onClick={() => void mute(m.uid, m.name)}>Sustur</button>}
            </div>
          </div>
        ))}
      </div>
    </Shell>
  );
}
