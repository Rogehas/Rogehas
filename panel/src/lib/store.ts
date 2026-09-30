'use client';
import type { PanelUser, PushNotice, Vefat } from './types';

/**
 * Geçici veri katmanı: tarayıcı localStorage'ında saklar.
 * Firebase (Firestore) bağlanınca bu dosyanın içi değişecek, arayüz aynı kalacak.
 */
interface DB {
  users: PanelUser[];
  vefat: Vefat[];
  notices: PushNotice[];
}

const KEY = 'tavas.panel.v1';

const seedUsers: PanelUser[] = [
  { id: 'u_admin', name: 'Yönetici Örnek', email: 'yonetici@example.com', role: 'admin', active: true },
  { id: 'u_ed1', name: 'Editör Örnek', email: 'editor1@example.com', role: 'editor', active: true },
  { id: 'u_ed2', name: 'İkinci Editör', email: 'editor2@example.com', role: 'editor', active: true },
  { id: 'u_mod', name: 'Moderatör Örnek', email: 'moderator@example.com', role: 'moderator', active: true },
];

function seed(): DB {
  const t = new Date().toISOString();
  return {
    users: seedUsers,
    notices: [],
    vefat: [
      {
        id: 'v_seed1',
        name: 'Ayşe Örnek',
        age: 78,
        neighborhood: 'Merkez Mah.',
        prayerDate: t.slice(0, 10),
        prayerTime: '13:30',
        mosque: 'Merkez Camii',
        burialPlace: 'Tavas Mezarlığı',
        condolenceAddress: '',
        photo: null,
        familyConsent: true,
        status: 'pending',
        createdBy: 'u_ed1',
        createdAt: t,
        updatedAt: t,
      },
    ],
  };
}

function load(): DB {
  try {
    const raw = localStorage.getItem(KEY);
    if (raw) return JSON.parse(raw) as DB;
  } catch {
    /* bozuk veri: sıfırdan başla */
  }
  return seed();
}

function save(db: DB) {
  try {
    localStorage.setItem(KEY, JSON.stringify(db));
  } catch {
    throw new Error('Kayıt yapılamadı (tarayıcı depolaması dolu olabilir; fotoğraf çok büyük mü?).');
  }
}

export const store = {
  users: () => load().users,
  vefat: () => load().vefat.sort((a, b) => b.updatedAt.localeCompare(a.updatedAt)),
  vefatById: (id: string) => load().vefat.find((v) => v.id === id) ?? null,
  notices: () => load().notices,

  upsertVefat(v: Vefat, notice?: PushNotice) {
    const db = load();
    const i = db.vefat.findIndex((x) => x.id === v.id);
    if (i >= 0) db.vefat[i] = v;
    else db.vefat.push(v);
    if (notice) db.notices.push(notice);
    save(db);
  },

  addUser(u: Omit<PanelUser, 'id' | 'active'>) {
    const db = load();
    if (db.users.some((x) => x.email.toLowerCase() === u.email.toLowerCase()))
      throw new Error('Bu e-posta ile zaten bir kullanıcı var.');
    db.users.push({ ...u, id: `u_${Date.now()}`, active: true });
    save(db);
  },

  updateUser(id: string, patch: Partial<Pick<PanelUser, 'role' | 'active'>>) {
    const db = load();
    const admins = db.users.filter((u) => u.role === 'admin' && u.active);
    const target = db.users.find((u) => u.id === id);
    if (!target) return;
    const next = { ...target, ...patch };
    const losesAdmin = target.role === 'admin' && target.active && !(next.role === 'admin' && next.active);
    if (losesAdmin && admins.length <= 1) throw new Error('Son yöneticinin rolü değiştirilemez ya da kapatılamaz.');
    db.users = db.users.map((u) => (u.id === id ? next : u));
    save(db);
  },
};
