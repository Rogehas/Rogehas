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
export interface Pharmacy {
  id: string;
  name: string;
  neighborhood: string;
  address: string;
  /** Yalnızca rakamlar, 0 ile başlayan 11 hane (ör. 02586140000). */
  phone: string;
  lat: number | null;
  lng: number | null;
  active: boolean;
  updatedAt: string;
}

/** Bir günün nöbetçi eczaneleri. Nöbet o günün 09:00'undan ertesi gün 09:00'una kadardır. */
export interface DutyDay {
  date: string; // yyyy-mm-dd (belge kimliği de bu)
  pharmacyIds: string[];
  updatedAt: string;
  updatedBy: string;
}

/** Panelden girilen, uygulamada listelenen içeriklerin ortak alanları. */
export interface ContentBase {
  id: string;
  /** Kapalıysa uygulamada görünmez (silme yok, "gizle" var). */
  published: boolean;
  updatedAt: string;
  updatedBy: string;
}

export interface EventItem extends ContentBase {
  title: string;
  description: string;
  date: string; // yyyy-mm-dd (başlangıç)
  endDate: string; // yyyy-mm-dd, boşsa tek gün
  time: string; // HH:MM, boş olabilir
  place: string;
  photo: string | null;
}

export interface GuideEntry extends ContentBase {
  name: string;
  category: string;
  phone: string;
  address: string;
  note: string;
  order: number;
}

export interface Business extends ContentBase {
  name: string;
  category: string;
  description: string;
  phone: string;
  address: string;
  hours: string;
  lat: number | null;
  lng: number | null;
  photo: string | null;
}

export const GUIDE_CATEGORIES = ['Acil', 'Sağlık', 'Belediye', 'Kamu kurumu', 'Ulaşım', 'Diğer'];
export const BUSINESS_CATEGORIES = ['Restoran', 'Kafe', 'Konaklama', 'Market', 'Hizmet', 'Sağlık', 'Diğer'];

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
