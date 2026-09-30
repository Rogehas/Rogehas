export type Role = 'admin' | 'editor' | 'moderator';

export interface PanelUser {
  id: string;
  name: string;
  email: string;
  role: Role;
  active: boolean;
}

export interface Invite {
  email: string;
  name: string;
  role: Role;
}

export type VefatStatus = 'draft' | 'pending' | 'published' | 'rejected' | 'archived';

export interface Vefat {
  id: string;
  name: string;
  age: number | null;
  neighborhood: string;
  prayerDate: string; // yyyy-mm-dd
  prayerTime: string; // HH:MM
  mosque: string;
  burialPlace: string;
  condolenceAddress: string;
  /** Küçültülmüş fotoğraf (şimdilik data URL, Firebase Storage'a taşınacak). */
  photo: string | null;
  familyConsent: boolean;
  status: VefatStatus;
  createdBy: string;
  createdByName: string;
  createdAt: string;
  updatedAt: string;
  publishedAt?: string;
  publishedBy?: string;
  rejectionNote?: string;
}

export type NewsKind = 'haber' | 'duyuru' | 'kesinti';
export type NewsStatus = 'draft' | 'published' | 'archived';

export interface News {
  id: string;
  kind: NewsKind;
  /** Kesinti için alt etiket, ör. "SU" ya da "ELEKTRİK". */
  subLabel: string;
  title: string;
  body: string;
  source: string;
  photo: string | null;
  sendPush: boolean;
  status: NewsStatus;
  createdBy: string;
  createdByName: string;
  createdAt: string;
  updatedAt: string;
  publishedAt?: string;
  publishedBy?: string;
}

/** Yayınlanınca telefonlara gidecek bildirim kaydı. */
/** Telefonların abone olduğu konu: vefat / haber / duyuru / kesinti. */
export type NoticeTopic = 'vefat' | 'haber' | 'duyuru' | 'kesinti';

export interface PushNotice {
  id: string;
  topic: NoticeTopic;
  vefatId?: string;
  newsId?: string;
  title: string;
  body: string;
  createdAt: string;
}

export const ROLE_LABEL: Record<Role, string> = {
  admin: 'Yönetici',
  editor: 'Editör',
  moderator: 'Moderatör',
};

export const STATUS_LABEL: Record<VefatStatus, string> = {
  draft: 'Taslak',
  pending: 'Onay bekliyor',
  published: 'Yayında',
  rejected: 'Reddedildi',
  archived: 'Arşiv',
};

export const KIND_LABEL: Record<NewsKind, string> = { haber: 'Haber', duyuru: 'Duyuru', kesinti: 'Kesinti' };
export const NEWS_STATUS_LABEL: Record<NewsStatus, string> = { draft: 'Taslak', published: 'Yayında', archived: 'Arşiv' };
