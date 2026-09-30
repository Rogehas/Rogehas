'use client';
import { useCallback, useEffect, useState, type FormEvent } from 'react';
import { Shell } from '@/components/Shell';
import { useSession } from '@/lib/session';
import { store } from '@/lib/store';
import { ROLE_LABEL, type Invite, type PanelUser, type Role } from '@/lib/types';

const ROLES = Object.keys(ROLE_LABEL) as Role[];

export default function Users() {
  const { user } = useSession();
  const [users, setUsers] = useState<PanelUser[]>([]);
  const [invites, setInvites] = useState<Invite[]>([]);
  const [error, setError] = useState('');
  const [form, setForm] = useState({ name: '', email: '', role: 'editor' as Role });

  const refresh = useCallback(async () => {
    try {
      const [u, i] = await Promise.all([store.users(), store.invites()]);
      setUsers(u);
      const known = new Set(u.map((x) => x.email.toLowerCase()));
      setInvites(i.filter((x) => !known.has(x.email.toLowerCase())));
    } catch {
      setError('Kullanıcılar yüklenemedi.');
    }
  }, []);
  useEffect(() => {
    void refresh();
  }, [refresh]);

  async function guard(fn: () => Promise<void>) {
    setError('');
    try {
      await fn();
      await refresh();
    } catch (e) {
      setError((e as Error).message);
    }
  }

  function invite(e: FormEvent) {
    e.preventDefault();
    void guard(async () => {
      if (!form.name.trim() || !form.email.includes('@')) throw new Error('Ad ve geçerli bir e-posta girin.');
      await store.addInvite({ name: form.name, email: form.email, role: form.role });
      setForm({ name: '', email: '', role: 'editor' });
    });
  }

  return (
    <Shell section="kullanici" title="Kullanıcılar">
      {error && <div className="err" role="alert">{error}</div>}
      <div className="card" style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 20, marginBottom: 8 }}>Kişi davet et</h2>
        <p className="muted" style={{ marginTop: 0 }}>
          Kişi bu e-posta adresiyle (Google hesabı olması en kolayı) panele ilk girişinde otomatik olarak yetkilenir.
        </p>
        <form onSubmit={invite} className="fields" style={{ alignItems: 'end' }}>
          <div className="field"><label htmlFor="n">Ad soyad</label><input id="n" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></div>
          <div className="field"><label htmlFor="e">E-posta</label><input id="e" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} /></div>
          <div className="field">
            <label htmlFor="r">Rol</label>
            <select id="r" value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value as Role })}>
              {ROLES.map((r) => <option key={r} value={r}>{ROLE_LABEL[r]}</option>)}
            </select>
          </div>
          <button className="btn dark" type="submit">Davet et</button>
        </form>
      </div>

      {invites.length > 0 && (
        <div className="card" style={{ marginBottom: 20 }}>
          <h2 style={{ fontSize: 20, marginBottom: 8 }}>Bekleyen davetler</h2>
          <table>
            <tbody>
              {invites.map((i) => (
                <tr key={i.email}>
                  <td><strong>{i.name}</strong></td>
                  <td>{i.email}</td>
                  <td>{ROLE_LABEL[i.role]}</td>
                  <td><button className="btn sm danger" onClick={() => void guard(() => store.removeInvite(i.email))}>Daveti sil</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="card">
        <table>
          <thead><tr><th>Ad</th><th>E-posta</th><th>Rol</th><th>Durum</th></tr></thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id}>
                <td><strong>{u.name}</strong>{u.id === user?.id && <span className="muted"> (sen)</span>}</td>
                <td>{u.email}</td>
                <td>
                  <select aria-label={`${u.name} rolü`} value={u.role} onChange={(e) => void guard(() => store.updateUser(u.id, { role: e.target.value as Role }))}>
                    {ROLES.map((r) => <option key={r} value={r}>{ROLE_LABEL[r]}</option>)}
                  </select>
                </td>
                <td>
                  <button className={`btn sm ${u.active ? '' : 'lime'}`} onClick={() => void guard(() => store.updateUser(u.id, { active: !u.active }))}>
                    {u.active ? 'Aktif · Kapat' : 'Kapalı · Aç'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        <p className="muted">Kapatılan kullanıcı panele giremez. Son yönetici kapatılamaz.</p>
      </div>
    </Shell>
  );
}
