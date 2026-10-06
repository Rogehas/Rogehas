import type { News, PanelUser, Role, Vefat } from './types';

export type Section =
  | 'vefat'
  | 'haber'
  | 'duyuru'
  | 'etkinlik'
  | 'eczane'
  | 'esnaf'
  | 'rehber'
  | 'sikayet'
  | 'chat'
  | 'uye'
  | 'kullanici';

const SECTIONS: Record<Role, Section[]> = {
  admin: ['vefat', 'haber', 'duyuru', 'etkinlik', 'eczane', 'esnaf', 'rehber', 'sikayet', 'chat', 'uye', 'kullanici'],
  editor: ['vefat', 'haber', 'duyuru', 'etkinlik', 'eczane', 'esnaf', 'rehber'],
  moderator: ['sikayet', 'chat', 'uye'],
};

export const canAccess = (role: Role, section: Section) => SECTIONS[role].includes(section);

const isAdmin = (u: PanelUser) => u.role === 'admin';

/** Editör yalnızca kendi taslağını/reddedilen ilanını düzenler; yönetici arşiv dışında hepsini. */
export function canEditVefat(u: PanelUser, v: Vefat): boolean {
  if (!canAccess(u.role, 'vefat') || v.status === 'archived') return false;
  if (isAdmin(u)) return true;
  return v.createdBy === u.id && (v.status === 'draft' || v.status === 'rejected');
}

export const canSubmitVefat = (u: PanelUser, v: Vefat) =>
  canEditVefat(u, v) && (v.status === 'draft' || v.status === 'rejected');

/** Onaylama, reddetme, doğrudan yayın ve arşivleme yalnızca yöneticidedir. */
export const canApproveVefat = (u: PanelUser, v: Vefat) => isAdmin(u) && v.status === 'pending';
export const canPublishDirect = (u: PanelUser, v: Vefat) =>
  isAdmin(u) && (v.status === 'draft' || v.status === 'rejected');
export const canArchiveVefat = (u: PanelUser, v: Vefat) => isAdmin(u) && v.status === 'published';
export const canManageUsers = (u: PanelUser) => isAdmin(u);

/** Haberde onay akışı yok: editörler düzenler ve yayınlar; arşivleme yöneticide. */
const newsRole = (u: PanelUser) => canAccess(u.role, 'haber');
export const canEditNews = (u: PanelUser, n: News) => newsRole(u) && n.status !== 'archived';
export const canPublishNews = (u: PanelUser, n: News) => newsRole(u) && n.status === 'draft';
export const canArchiveNews = (u: PanelUser, n: News) => isAdmin(u) && n.status === 'published';
