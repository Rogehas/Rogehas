'use client';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, type ReactNode } from 'react';
import { canAccess, type Section } from '@/lib/permissions';
import { useSession } from '@/lib/session';
import { ROLE_LABEL } from '@/lib/types';

const ITEMS: { label: string; section: Section; href?: string }[] = [
  { label: 'Vefat ilanları', section: 'vefat', href: '/vefat' },
  { label: 'Haberler', section: 'haber', href: '/haberler' },
  { label: 'Etkinlikler', section: 'etkinlik', href: '/etkinlikler' },
  { label: 'Nöbetçi eczane', section: 'eczane', href: '/eczane' },
  { label: 'Rehber', section: 'rehber', href: '/rehber' },
  { label: 'Yerel esnaf', section: 'esnaf', href: '/esnaf' },
  { label: 'Şikâyetler', section: 'sikayet' },
  { label: 'Sohbet moderasyonu', section: 'chat' },
  { label: 'Kullanıcılar', section: 'kullanici', href: '/kullanicilar' },
];

export function Shell({ section, title, children, actions }: {
  section: Section;
  title: string;
  children: ReactNode;
  actions?: ReactNode;
}) {
  const { user, ready, logout } = useSession();
  const router = useRouter();
  const path = usePathname();

  useEffect(() => {
    if (ready && !user) router.replace('/login');
  }, [ready, user, router]);

  if (!ready || !user) return null;

  return (
    <div className="layout">
      <aside className="side">
        <div className="brand">
          <div className="logo">T</div>
          <div>
            <strong>Tavas Panel</strong>
            <div style={{ fontSize: 12, opacity: 0.75 }}>Yönetim paneli</div>
          </div>
        </div>
        <nav className="nav" aria-label="Bölümler">
          {ITEMS.filter((i) => canAccess(user.role, i.section)).map((i) =>
            i.href ? (
              <Link key={i.label} href={i.href} className={path.startsWith(i.href) ? 'on' : ''}>
                {i.label}
              </Link>
            ) : (
              <span key={i.label} title="Sonraki fazda eklenecek">{i.label}</span>
            ),
          )}
        </nav>
        <div className="me">
          <div>
            <strong>{user.name}</strong>
            <br />
            <small>Rol: {ROLE_LABEL[user.role]}</small>
          </div>
          <button onClick={() => void logout()}>Çıkış yap</button>
        </div>
      </aside>
      <main className="main">
        {canAccess(user.role, section) ? (
          <>
            <div className="head">
              <h1>{title}</h1>
              {actions}
            </div>
            {children}
          </>
        ) : (
          <div className="card">
            <h1>Erişim yok</h1>
            <p className="muted">{ROLE_LABEL[user.role]} rolü bu bölümü görüntüleyemez.</p>
          </div>
        )}
      </main>
    </div>
  );
}
