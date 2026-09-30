import {
  canApproveVefat,
  canArchiveVefat,
  canEditVefat,
  canPublishDirect,
  canSubmitVefat,
} from './permissions';
import type { PanelUser, PushNotice, Vefat } from './types';

/** Onaya göndermeden / yayınlamadan önce zorunlu alanlar. */
export function validateVefat(v: Vefat): string[] {
  const errors: string[] = [];
  if (!v.name.trim()) errors.push('Ad soyad gerekli.');
  if (v.age === null || v.age < 0 || v.age > 130) errors.push('Geçerli bir yaş girin.');
  if (!v.neighborhood.trim()) errors.push('Mahalle gerekli.');
  if (!v.prayerDate || !v.prayerTime) errors.push('Cenaze namazı tarihi ve saati gerekli.');
  if (!v.mosque.trim()) errors.push('Cami gerekli.');
  if (!v.burialPlace.trim()) errors.push('Defin yeri gerekli.');
  if (!v.familyConsent) errors.push('Aile onayı alınmadan yayınlanamaz.');
  return errors;
}

export type VefatAction = 'submit' | 'approve' | 'reject' | 'publish' | 'archive';

export interface TransitionResult {
  vefat: Vefat;
  notice?: PushNotice;
}

const now = () => new Date().toISOString();

export function buildNotice(v: Vefat): PushNotice {
  const [y, m, d] = v.prayerDate.split('-').map(Number);
  const date = new Date(y, m - 1, d);
  const today = new Date();
  const isToday = date.toDateString() === today.toDateString();
  const when = isToday ? 'bugün' : `${d.toString().padStart(2, '0')}.${m.toString().padStart(2, '0')}`;
  return {
    id: `n_${v.id}_${Date.now()}`,
    vefatId: v.id,
    title: `Vefat · ${v.name}`,
    body: `Cenaze namazı ${when} ${v.prayerTime}, ${v.mosque}.`,
    createdAt: now(),
  };
}

/** Durum geçişi: yetki ve zorunlu alan kontrolünü uygular, hata fırlatır. */
export function transition(
  v: Vefat,
  action: VefatAction,
  actor: PanelUser,
  note?: string,
): TransitionResult {
  const fail = (msg: string): never => {
    throw new Error(msg);
  };
  const base = { ...v, updatedAt: now() };

  switch (action) {
    case 'submit': {
      if (!canSubmitVefat(actor, v)) fail('Bu ilanı onaya gönderme yetkin yok.');
      const errs = validateVefat(v);
      if (errs.length) fail(errs.join(' '));
      return { vefat: { ...base, status: 'pending', rejectionNote: undefined } };
    }
    case 'approve':
    case 'publish': {
      const allowed = action === 'approve' ? canApproveVefat(actor, v) : canPublishDirect(actor, v);
      if (!allowed) fail('Yayınlama yetkisi yalnızca yöneticidedir.');
      const errs = validateVefat(v);
      if (errs.length) fail(errs.join(' '));
      const published: Vefat = {
        ...base,
        status: 'published',
        publishedAt: now(),
        publishedBy: actor.id,
        rejectionNote: undefined,
      };
      return { vefat: published, notice: buildNotice(published) };
    }
    case 'reject': {
      if (!canApproveVefat(actor, v)) fail('Reddetme yetkisi yalnızca yöneticidedir.');
      if (!note?.trim()) fail('Reddetme nedeni yazılmalı.');
      return { vefat: { ...base, status: 'rejected', rejectionNote: note!.trim() } };
    }
    case 'archive': {
      if (!canArchiveVefat(actor, v)) fail('Arşivleme yetkisi yalnızca yöneticidedir.');
      return { vefat: { ...base, status: 'archived' } };
    }
  }
}

/** Düzenleme kaydı: yetki kontrolüyle birlikte. */
export function applyEdit(actor: PanelUser, existing: Vefat, next: Vefat): Vefat {
  if (!canEditVefat(actor, existing)) throw new Error('Bu ilanı düzenleme yetkin yok.');
  return {
    ...next,
    id: existing.id,
    status: existing.status,
    createdBy: existing.createdBy,
    createdByName: existing.createdByName,
    createdAt: existing.createdAt,
    updatedAt: now(),
  };
}
