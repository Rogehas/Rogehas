'use client';
import {
  collection,
  query,
  where,
  deleteDoc,
  doc,
  limit,
  orderBy,
  serverTimestamp,
  Timestamp,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';
import { getDownloadURL, ref, uploadString } from 'firebase/storage';
import { db, storage, USE_STORAGE } from './firebase';
import type { ChatMsg, ChatReport, CommentItem, ComplaintItem, ComplaintStatus, DutyDay, Invite, Member, Mute, News, PanelUser, Pharmacy, PushNotice, Role, Vefat } from './types';

/** Fotoğraf Storage açıksa yüklenip adresi saklanır; değilse veri adresi belgede kalır. */
export type ContentCollection = 'events' | 'guide' | 'businesses';

async function resolvePhoto(kind: 'vefat' | 'news' | 'events' | 'businesses', id: string, photo: string | null) {
  if (!photo || !photo.startsWith('data:') || !USE_STORAGE) return photo;
  const r = ref(storage, `${kind}/${id}/photo-${Date.now()}.jpg`);
  await uploadString(r, photo, 'data_url');
  return getDownloadURL(r);
}

const byUpdated = <T extends { updatedAt: string }>(a: T, b: T) => b.updatedAt.localeCompare(a.updatedAt);

export const store = {
  // ---- etkinlik, rehber, esnaf (ortak yapı) ----
  async listContent<T extends { id: string }>(collectionName: ContentCollection): Promise<T[]> {
    const s = await getDocs(collection(db, collectionName));
    return s.docs.map((d) => d.data() as T);
  },

  /** Kaydeder; `photo` alanı varsa ve yeni seçildiyse Storage'a yükler. */
  async upsertContent<T extends { id: string; photo?: string | null }>(collectionName: ContentCollection, item: T) {
    let saved = item;
    if ('photo' in item && (collectionName === 'events' || collectionName === 'businesses')) {
      saved = { ...item, photo: await resolvePhoto(collectionName, item.id, item.photo ?? null) };
    }
    await setDoc(doc(db, collectionName, item.id), saved);
  },

  // ---- eczaneler ve nöbet takvimi ----
  async pharmacies(): Promise<Pharmacy[]> {
    const s = await getDocs(collection(db, 'pharmacies'));
    return s.docs.map((d) => d.data() as Pharmacy).sort((a, b) => a.name.localeCompare(b.name, 'tr'));
  },

  async upsertPharmacy(p: Pharmacy) {
    await setDoc(doc(db, 'pharmacies', p.id), p);
  },

  /** `from` tarihinden (dahil) sonraki nöbet günleri. */
  async dutyFrom(from: string): Promise<DutyDay[]> {
    const s = await getDocs(query(collection(db, 'duty'), where('date', '>=', from)));
    return s.docs.map((d) => d.data() as DutyDay).sort((a, b) => a.date.localeCompare(b.date));
  },

  /** Verilen günlerin hepsine aynı eczaneleri yazar (boş liste = o gün girilmemiş sayılır). */
  async setDuty(dates: string[], pharmacyIds: string[], updatedBy: string) {
    const batch = writeBatch(db);
    const updatedAt = new Date().toISOString();
    for (const date of dates) batch.set(doc(db, 'duty', date), { date, pharmacyIds, updatedAt, updatedBy });
    await batch.commit();
  },

  // ---- kullanıcılar ve davetler (yalnızca yönetici) ----
  async users(): Promise<PanelUser[]> {
    const s = await getDocs(collection(db, 'users'));
    return s.docs.map((d) => ({ id: d.id, ...(d.data() as Omit<PanelUser, 'id'>) }));
  },

  async invites(): Promise<Invite[]> {
    const s = await getDocs(collection(db, 'invites'));
    return s.docs.map((d) => ({ email: d.id, ...(d.data() as Omit<Invite, 'email'>) }));
  },

  async addInvite(i: Invite) {
    const email = i.email.trim().toLowerCase();
    const users = await this.users();
    if (users.some((u) => u.email.toLowerCase() === email)) throw new Error('Bu e-posta ile zaten bir kullanıcı var.');
    await setDoc(doc(db, 'invites', email), { name: i.name.trim(), role: i.role });
  },

  async removeInvite(email: string) {
    await deleteDoc(doc(db, 'invites', email.toLowerCase()));
  },

  async updateUser(id: string, patch: Partial<Pick<PanelUser, 'role' | 'active'>>) {
    const users = await this.users();
    const target = users.find((u) => u.id === id);
    if (!target) return;
    const next = { ...target, ...patch };
    const losesAdmin = target.role === 'admin' && target.active && !(next.role === 'admin' && next.active);
    const admins = users.filter((u) => u.role === 'admin' && u.active);
    if (losesAdmin && admins.length <= 1) throw new Error('Son yöneticinin rolü değiştirilemez ya da kapatılamaz.');
    await updateDoc(doc(db, 'users', id), patch);
  },

  // ---- vefat ----
  async vefat(): Promise<Vefat[]> {
    const s = await getDocs(collection(db, 'vefat'));
    return s.docs.map((d) => d.data() as Vefat).sort(byUpdated);
  },

  async vefatById(id: string): Promise<Vefat | null> {
    const s = await getDoc(doc(db, 'vefat', id));
    return s.exists() ? (s.data() as Vefat) : null;
  },

  async upsertVefat(v: Vefat, notice?: PushNotice) {
    const photo = await resolvePhoto('vefat', v.id, v.photo);
    const batch = writeBatch(db);
    batch.set(doc(db, 'vefat', v.id), { ...v, photo });
    if (notice) batch.set(doc(db, 'notices', notice.id), notice);
    await batch.commit();
  },

  // ---- haberler ----
  async news(): Promise<News[]> {
    const s = await getDocs(collection(db, 'news'));
    return s.docs.map((d) => d.data() as News).sort(byUpdated);
  },

  async newsById(id: string): Promise<News | null> {
    const s = await getDoc(doc(db, 'news', id));
    return s.exists() ? (s.data() as News) : null;
  },

  async upsertNews(n: News, notice?: PushNotice) {
    const photo = await resolvePhoto('news', n.id, n.photo);
    const batch = writeBatch(db);
    batch.set(doc(db, 'news', n.id), { ...n, photo });
    if (notice) batch.set(doc(db, 'notices', notice.id), notice);
    await batch.commit();
  },

  // ---- sohbet moderasyonu (moderatör ve yönetici) ----
  async chatMessages(): Promise<ChatMsg[]> {
    const s = await getDocs(query(collection(db, 'chat'), orderBy('createdAt', 'desc'), limit(100)));
    return s.docs.map((d) => {
      const x = d.data();
      return {
        id: d.id,
        uid: String(x.uid ?? ''),
        name: String(x.name ?? ''),
        text: String(x.text ?? ''),
        hidden: x.hidden === true,
        shadow: x.shadow === true,
        createdAt: x.createdAt instanceof Timestamp ? x.createdAt.toDate().toISOString() : '',
      };
    });
  },

  /** Mesajı herkese gizler (silmez); geri açılabilir. */
  async setChatHidden(id: string, hidden: boolean) {
    await updateDoc(doc(db, 'chat', id), { hidden });
  },

  async chatReports(): Promise<ChatReport[]> {
    const s = await getDocs(query(collection(db, 'chatReports'), orderBy('createdAt', 'desc'), limit(100)));
    return s.docs.map((d) => {
      const x = d.data();
      return {
        id: d.id,
        messageId: String(x.messageId ?? ''),
        messageUid: String(x.messageUid ?? ''),
        messageName: String(x.messageName ?? ''),
        text: String(x.text ?? ''),
        reason: String(x.reason ?? ''),
        handled: x.handled === true,
        source: x.source === 'comment' ? 'comment' : undefined,
        createdAt: x.createdAt instanceof Timestamp ? x.createdAt.toDate().toISOString() : '',
      };
    });
  },

  async comments(): Promise<CommentItem[]> {
    const s = await getDocs(query(collection(db, 'comments'), orderBy('createdAt', 'desc'), limit(100)));
    return s.docs.map((d) => {
      const x = d.data();
      return {
        id: d.id,
        newsId: String(x.newsId ?? ''),
        uid: String(x.uid ?? ''),
        name: String(x.name ?? ''),
        text: String(x.text ?? ''),
        hidden: x.hidden === true,
        shadow: x.shadow === true,
        parentId: typeof x.parentId === 'string' ? x.parentId : undefined,
        replyToName: typeof x.replyToName === 'string' ? x.replyToName : undefined,
        createdAt: x.createdAt instanceof Timestamp ? x.createdAt.toDate().toISOString() : '',
      };
    });
  },

  async setCommentHidden(id: string, hidden: boolean) {
    await updateDoc(doc(db, 'comments', id), { hidden });
  },

  async markReportHandled(id: string) {
    await updateDoc(doc(db, 'chatReports', id), { handled: true });
  },

  async members(): Promise<Member[]> {
    const s = await getDocs(query(collection(db, 'members'), orderBy('createdAt', 'desc'), limit(2000)));
    return s.docs.map((d) => {
      const x = d.data();
      return {
        uid: d.id,
        name: String(x.name ?? ''),
        email: String(x.email ?? ''),
        createdAt: x.createdAt instanceof Timestamp ? x.createdAt.toDate().toISOString() : '',
      };
    });
  },

  async mutes(): Promise<Mute[]> {
    const s = await getDocs(collection(db, 'mutes'));
    return s.docs.map((d) => ({ uid: d.id, name: String(d.data().name ?? '') }));
  },

  async mute(uid: string, name: string, by: string) {
    await setDoc(doc(db, 'mutes', uid), { name, by, at: serverTimestamp() });
  },

  async unmute(uid: string) {
    await deleteDoc(doc(db, 'mutes', uid));
  },

  // ---- şikâyet / öneri (moderatör ve yönetici) ----
  async complaints(): Promise<ComplaintItem[]> {
    const s = await getDocs(query(collection(db, 'complaints'), orderBy('createdAt', 'desc'), limit(200)));
    return s.docs.map((d) => {
      const x = d.data();
      return {
        id: d.id,
        uid: String(x.uid ?? ''),
        name: String(x.name ?? ''),
        email: String(x.email ?? ''),
        category: String(x.category ?? ''),
        neighborhood: String(x.neighborhood ?? ''),
        text: String(x.text ?? ''),
        status: (['new', 'progress', 'resolved', 'closed'].includes(x.status) ? x.status : 'new') as ComplaintStatus,
        reply: String(x.reply ?? ''),
        createdAt: x.createdAt instanceof Timestamp ? x.createdAt.toDate().toISOString() : '',
      };
    });
  },

  async answerComplaint(id: string, status: ComplaintStatus, reply: string, by: string) {
    await updateDoc(doc(db, 'complaints', id), { status, reply, updatedAt: serverTimestamp(), handledBy: by });
  },
};

export type { Role };
