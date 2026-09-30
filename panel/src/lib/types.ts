export type Role = 'admin' | 'editor' | 'moderator';

export interface PanelUser {
  id: string;
  name: string;
  email: string;
  role: Role;
  active: boolean;
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
  createdAt: string;
  updatedAt: string;
  publishedAt?: string;
  publishedBy?: string;
  rejectionNote?: string;
}

/** Yayınlanınca telefonlara gidecek bildirim kaydı. */
export interface PushNotice {
  id: string;
  vefatId: string;
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
