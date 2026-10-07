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
  /** İsteğe bağlı YouTube video linki; uygulamada haberin içinde oynatılır. */
  youtubeUrl?: string;
  sendPush: boolean;
  /** Üyeler yorum yazabilir mi? Eski kayıtlarda yoksa açık sayılır. */
  commentsOpen?: boolean;
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

/** Sohbet mesajı (uygulamadaki genel sohbet). `createdAt` ISO biçiminde, yoksa boş. */
export interface ChatMsg {
  id: string;
  uid: string;
  name: string;
  text: string;
  hidden: boolean;
  /** Susturulmuş üyenin gölge mesajı: yalnızca yazanın kendisi görür. */
  shadow?: boolean;
  createdAt: string;
}

export interface ChatReport {
  id: string;
  messageId: string;
  messageUid: string;
  messageName: string;
  text: string;
  reason: string;
  handled: boolean;
  /** 'comment': haber yorumu şikâyeti; yoksa sohbet mesajı. */
  source?: 'comment';
  createdAt: string;
}

export interface Member {
  uid: string;
  name: string;
  email: string;
  /** Hesabın açıldığı an (ISO). */
  createdAt: string;
}

export interface Mute {
  uid: string;
  name: string;
}

export type ComplaintStatus = 'new' | 'progress' | 'resolved' | 'closed';
export const COMPLAINT_STATUS_LABEL: Record<ComplaintStatus, string> = {
  new: 'Yeni',
  progress: 'İnceleniyor',
  resolved: 'Çözüldü',
  closed: 'Kapatıldı',
};

/** Uygulamadan gelen şikâyet/öneri. */
export interface ComplaintItem {
  id: string;
  uid: string;
  name: string;
  email: string;
  category: string;
  neighborhood: string;
  text: string;
  status: ComplaintStatus;
  reply: string;
  createdAt: string;
}

/** Haber altındaki yorum. */
export interface CommentItem {
  id: string;
  newsId: string;
  uid: string;
  name: string;
  text: string;
  hidden: boolean;
  shadow?: boolean;
  /** Yanıtsa ana yorumun kimliği. */
  parentId?: string;
  /** Yanıtın kime verildiği. */
  replyToName?: string;
  createdAt: string;
}

// ---- sponsor reklamlar ----
/** Reklamın uygulamada görünebileceği yerler. Anahtarlar uygulamadaki `AdPlacement` ile aynıdır. */
export const AD_PLACEMENTS = [
  { key: 'hero', label: 'Kayan haberlerin içinde (ana sayfa)' },
  { key: 'home', label: 'Ana sayfa şeridi (kısayolların altı)' },
  { key: 'nav', label: 'Alt menü üstü ince şerit' },
  { key: 'newsDetail', label: 'Haber içinde (yorumların üstü)' },
  { key: 'newsList', label: 'Haber listesi arası' },
  { key: 'esnaf', label: 'Esnaf sayfasında “öne çıkan”' },
  { key: 'info', label: 'Eczane ve etkinlik sayfası altı' },
] as const;
export type AdPlacement = (typeof AD_PLACEMENTS)[number]['key'];
export const AD_PLACEMENT_LABEL = Object.fromEntries(AD_PLACEMENTS.map((p) => [p.key, p.label])) as Record<AdPlacement, string>;

export type AdAction = 'call' | 'map' | 'web';
export const AD_ACTION_LABEL: Record<AdAction, string> = {
  call: 'Ara (telefon)',
  map: 'Haritada aç (adres)',
  web: 'Web sitesine git',
};

export interface Ad {
  id: string;
  /** Esnaf / reklam veren adı. */
  name: string;
  /** Kısa metin (en fazla 80 karakter). */
  text: string;
  photo: string | null;
  action: AdAction;
  /** Telefon, adres ya da web adresi (eyleme göre). */
  actionValue: string;
  placements: AdPlacement[];
  /** YYYY-MM-DD; boşsa hemen başlar. */
  startDate: string;
  /** YYYY-MM-DD; boşsa süresiz. */
  endDate: string;
  active: boolean;
  createdAt: string;
  updatedAt: string;
  updatedBy: string;
}

/** Bir reklamın bir aydaki gösterim ve tıklama sayısı. */
export interface AdStat {
  adId: string;
  /** YYYY-MM */
  month: string;
  impressions: number;
  clicks: number;
}
