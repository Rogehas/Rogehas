'use client';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { useSession } from '@/lib/session';
import { store } from '@/lib/store';
import { ROLE_LABEL, type PanelUser } from '@/lib/types';

export default function Login() {
  const { login, user, ready } = useSession();
  const router = useRouter();
  const [users, setUsers] = useState<PanelUser[]>([]);

  useEffect(() => setUsers(store.users().filter((u) => u.active)), []);
  useEffect(() => {
    if (ready && user) router.replace('/');
  }, [ready, user, router]);

  return (
    <div className="login">
      <div className="brand" style={{ color: 'var(--ink)' }}>
        <div className="logo">T</div>
        <h1>Tavas Panel</h1>
      </div>
      <div className="card">
        <h2 style={{ fontSize: 22 }}>Giriş yap</h2>
        <p className="note" style={{ marginTop: 12 }}>
          Demo sürüm: gerçek giriş (e-posta / Google) Firebase bağlanınca gelecek. Şimdilik bir kullanıcı seçerek rolleri deneyebilirsin.
        </p>
        <div className="users">
          {users.map((u) => (
            <button
              key={u.id}
              className="user"
              onClick={() => {
                login(u.id);
                router.replace('/');
              }}
            >
              <span className="avatar" style={{ width: 44, height: 44, borderRadius: 22, fontSize: 16 }}>
                {u.name[0]}
              </span>
              <span>
                <strong>{u.name}</strong>
                <br />
                <span className="muted">{ROLE_LABEL[u.role]} · {u.email}</span>
              </span>
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}
