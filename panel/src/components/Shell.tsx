'use client';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect, type ReactNode } from 'react';
import { canAccess, type Section } from '@/lib/permissions';
import { useSession } from '@/lib/session';
import { ROLE_LABEL } from '@/lib/types';

/** Menü simgeleri (24x24, çizgi stili). */
const ICONS: Record<Section, ReactNode> = {
  vefat: <path d="M7 21V11a5 5 0 0 1 10 0v10M4 21h16M10 12h4M10 15h4" />,
  haber: <path d="M5 4h11a2 2 0 0 1 2 2v14H7a2 2 0 0 1-2-2V4zM18 9h2v9a2 2 0 0 1-2 2M8 8h6M8 12h6M8 16h4" />,
  duyuru: <path d="M3 11v3a1 1 0 0 0 1 1h2l5 4V6L6 10H4a1 1 0 0 0-1 1zM15 9a4 4 0 0 1 0 6M18 6.5a8 8 0 0 1 0 11" />,
  etkinlik: <path d="M5 5h14a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1zM4 10h16M8 3v4M16 3v4" />,
  eczane: <path d="M10 3h4v7h7v4h-7v7h-4v-7H3v-4h7V3z" />,
  esnaf: <path d="M4 9l1.5-5h13L20 9M4 9h16M4 9v11h16V9M9 20v-6h6v6" />,
  rehber: <path d="M6 3h11a2 2 0 0 1 2 2v16H8a2 2 0 0 1-2-2V3zM6 3v16M10 8h6M10 12h6" />,
  sikayet: <path d="M21 12a8 8 0 0 1-11.5 7.2L4 20l1-4.5A8 8 0 1 1 21 12zM12 8v4M12 15.5v.01" />,
  chat: <path d="M4 5h16a1 1 0 0 1 1 1v10a1 1 0 0 1-1 1H9l-5 4V6a1 1 0 0 1 1-1zM8 10h8M8 13h5" />,
  reklam: <path d="M3 11v3a1 1 0 0 0 1 1h2l5 4V6L6 10H4a1 1 0 0 0-1 1zM15 9a4 4 0 0 1 0 6M18 6.5a8 8 0 0 1 0 11" />,
  uye: <path d="M9 11a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7zM2 20a7 7 0 0 1 14 0M16 4.5a3.5 3.5 0 0 1 0 6.5M18 14a7 7 0 0 1 4 6" />,
  kullanici: <path d="M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6l8-3zM9 12l2 2 4-4" />,
};

function NavIcon({ section }: { section: Section }) {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" style={{ flexShrink: 0 }}>
      {ICONS[section]}
    </svg>
  );
}

const ITEMS: { label: string; section: Section; href?: string }[] = [
  { label: 'Vefat ilanları', section: 'vefat', href: '/vefat' },
  { label: 'Haberler', section: 'haber', href: '/haberler' },
  { label: 'Etkinlikler', section: 'etkinlik', href: '/etkinlikler' },
  { label: 'Nöbetçi eczane', section: 'eczane', href: '/eczane' },
  { label: 'Rehber', section: 'rehber', href: '/rehber' },
  { label: 'Yerel esnaf', section: 'esnaf', href: '/esnaf' },
  { label: 'Şikâyet / öneri', section: 'sikayet', href: '/sikayetler' },
  { label: 'Sohbet moderasyonu', section: 'chat', href: '/moderasyon' },
  { label: 'Reklamlar', section: 'reklam', href: '/reklamlar' },
  { label: 'Üyeler', section: 'uye', href: '/uyeler' },
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
          <div className="logo"><img src="/logo.png" alt="" width={44} height={44} /></div>
          <div>
            <strong>Tavas Panel</strong>
            <div style={{ fontSize: 12, opacity: 0.75 }}>Yönetim paneli</div>
          </div>
        </div>
        <nav className="nav" aria-label="Bölümler">
          {ITEMS.filter((i) => canAccess(user.role, i.section)).map((i) =>
            i.href ? (
              <Link key={i.label} href={i.href} className={path.startsWith(i.href) ? 'on' : ''}>
                <NavIcon section={i.section} />
                {i.label}
              </Link>
            ) : (
              <span key={i.label} title="Sonraki fazda eklenecek"><NavIcon section={i.section} />{i.label}</span>
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
