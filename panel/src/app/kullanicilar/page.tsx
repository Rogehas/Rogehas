'use client';
import { useCallback, useEffect, useState, type FormEvent } from 'react';
import { Shell } from '@/components/Shell';
import { useSession } from '@/lib/session';
import { store } from '@/lib/store';
import { ROLE_LABEL, type PanelUser, type Role } from '@/lib/types';

export default function Users() {
  const { user } = useSession();
  const [users, setUsers] = useState<PanelUser[]>([]);
  const [error, setError] = useState('');
  const [form, setForm] = useState({ name: '', email: '', role: 'editor' as Role });

  const refresh = useCallback(() => setUsers(store.users()), []);
  useEffect(refresh, [refresh]);

  function guard(fn: () => void) {
    setError('');
    try {
      fn();
      refresh();
    } catch (e) {
      setError((e as Error).message);
    }
  }

  function add(e: FormEvent) {
    e.preventDefault();
    guard(() => {
      if (!form.name.trim() || !form.email.includes('@')) throw new Error('Ad ve geçerli bir e-posta girin.');
      store.addUser({ name: form.name.trim(), email: form.email.trim(), role: form.role });
      setForm({ name: '', email: '', role: 'editor' });
    });
  }

  return (
    <Shell section="kullanici" title="Kullanıcılar">
      {error && <div className="err" role="alert">{error}</div>}
      <div className="card" style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 20, marginBottom: 16 }}>Yeni kullanıcı ekle</h2>
        <form onSubmit={add} className="fields" style={{ alignItems: 'end' }}>
          <div className="field"><label htmlFor="n">Ad soyad</label><input id="n" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></div>
          <div className="field"><label htmlFor="e">E-posta</label><input id="e" type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} /></div>
          <div className="field">
            <label htmlFor="r">Rol</label>
            <select id="r" value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value as Role })}>
              {(Object.keys(ROLE_LABEL) as Role[]).map((r) => <option key={r} value={r}>{ROLE_LABEL[r]}</option>)}
            </select>
          </div>
          <button className="btn dark" type="submit">Ekle</button>
        </form>
      </div>
      <div className="card">
        <table>
          <thead><tr><th>Ad</th><th>E-posta</th><th>Rol</th><th>Durum</th></tr></thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id}>
                <td><strong>{u.name}</strong>{u.id === user?.id && <span className="muted"> (sen)</span>}</td>
                <td>{u.email}</td>
                <td>
                  <select aria-label={`${u.name} rolü`} value={u.role} onChange={(e) => guard(() => store.updateUser(u.id, { role: e.target.value as Role }))}>
                    {(Object.keys(ROLE_LABEL) as Role[]).map((r) => <option key={r} value={r}>{ROLE_LABEL[r]}</option>)}
                  </select>
                </td>
                <td>
                  <button className={`btn sm ${u.active ? '' : 'lime'}`} onClick={() => guard(() => store.updateUser(u.id, { active: !u.active }))}>
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
