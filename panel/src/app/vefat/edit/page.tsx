'use client';
import { useRouter, useSearchParams } from 'next/navigation';
import { Suspense, useEffect, useState } from 'react';
import { Shell } from '@/components/Shell';
import { canEditVefat } from '@/lib/permissions';
import { resizePhoto } from '@/lib/image';
import { useSession } from '@/lib/session';
import { store } from '@/lib/store';
import { STATUS_LABEL, type Vefat } from '@/lib/types';
import { applyEdit, transition, validateVefat } from '@/lib/vefat-rules';

function blank(userId: string, userName: string): Vefat {
  const t = new Date().toISOString();
  return {
    id: `v_${Date.now()}`,
    name: '',
    age: null,
    neighborhood: '',
    prayerDate: t.slice(0, 10),
    prayerTime: '',
    mosque: '',
    burialPlace: 'Tavas Mezarlığı',
    condolenceAddress: '',
    photo: null,
    familyConsent: false,
    status: 'draft',
    createdBy: userId,
    createdByName: userName,
    createdAt: t,
    updatedAt: t,
  };
}

function VefatEditInner() {
  const id = useSearchParams().get('id') ?? 'new';
  const { user } = useSession();
  const router = useRouter();
  const isNew = id === 'new';
  const [v, setV] = useState<Vefat | null>(null);
  const [error, setError] = useState('');
  const [missing, setMissing] = useState(false);

  useEffect(() => {
    if (!user) return;
    if (isNew) return setV(blank(user.id, user.name));
    store
      .vefatById(id)
      .then((found) => (found ? setV(found) : setMissing(true)))
      .catch(() => setError('İlan yüklenemedi.'));
  }, [id, isNew, user]);

  const set = <K extends keyof Vefat>(k: K, val: Vefat[K]) => setV((p) => (p ? { ...p, [k]: val } : p));

  async function persist(): Promise<Vefat | null> {
    if (!user || !v) return null;
    setError('');
    try {
      const existing = isNew ? null : await store.vefatById(v.id);
      const toSave = existing ? applyEdit(user, existing, v) : v;
      await store.upsertVefat(toSave);
      return toSave;
    } catch (e) {
      setError((e as Error).message);
      return null;
    }
  }

  const saveDraft = async () => {
    if (await persist()) router.push('/vefat');
  };

  async function submit() {
    if (!user) return;
    const saved = await persist();
    if (!saved) return;
    try {
      await store.upsertVefat(transition(saved, 'submit', user).vefat);
      router.push('/vefat');
    } catch (e) {
      setError((e as Error).message);
    }
  }

  async function pickPhoto(file?: File) {
    if (!file) return;
    try {
      set('photo', await resizePhoto(file));
    } catch (e) {
      setError((e as Error).message);
    }
  }

  const editable = !!user && !!v && (isNew || canEditVefat(user, v));
  const problems = v ? validateVefat(v) : [];

  return (
    <Shell section="vefat" title={isNew ? 'Yeni vefat ilanı' : 'İlanı düzenle'}>
      {missing && <div className="err">İlan bulunamadı.</div>}
      {v && !editable && <div className="err">Bu ilanı düzenleme yetkin yok ({STATUS_LABEL[v.status]}).</div>}
      {v && editable && (
        <div className="card">
          {v.status === 'rejected' && v.rejectionNote && (
            <div className="err">Yönetici notu: {v.rejectionNote}</div>
          )}
          {error && <div className="err" role="alert">{error}</div>}

          <h2 style={{ fontSize: 20, marginBottom: 16 }}>Kişi bilgileri</h2>
          <div style={{ display: 'flex', gap: 24, flexWrap: 'wrap', marginBottom: 24 }}>
            <div>
              <div className="photo">
                {v.photo ? <img src={v.photo} alt="Seçilen fotoğraf" /> : <span>Fotoğraf yok<br />(isteğe bağlı)</span>}
              </div>
              <div className="actions" style={{ marginTop: 10 }}>
                <label className="btn sm">
                  {v.photo ? 'Değiştir' : 'Fotoğraf seç'}
                  <input type="file" accept="image/*" hidden onChange={(e) => pickPhoto(e.target.files?.[0])} />
                </label>
                {v.photo && <button className="btn sm danger" onClick={() => set('photo', null)}>Kaldır</button>}
              </div>
            </div>
            <div className="fields" style={{ flex: 1, minWidth: 260, alignContent: 'start' }}>
              <div className="field"><label htmlFor="name">Ad soyad</label><input id="name" value={v.name} onChange={(e) => set('name', e.target.value)} /></div>
              <div className="field"><label htmlFor="age">Yaş</label><input id="age" type="number" min={0} max={130} value={v.age ?? ''} onChange={(e) => set('age', e.target.value === '' ? null : Number(e.target.value))} /></div>
              <div className="field"><label htmlFor="mah">Bilgiler</label><input id="mah" value={v.neighborhood} onChange={(e) => set('neighborhood', e.target.value)} /></div>
            </div>
          </div>

          <h2 style={{ fontSize: 20, marginBottom: 16 }}>Cenaze bilgileri</h2>
          <div className="fields" style={{ marginBottom: 24 }}>
            <div className="field"><label htmlFor="pd">Cenaze namazı tarihi</label><input id="pd" type="date" value={v.prayerDate} onChange={(e) => set('prayerDate', e.target.value)} /></div>
            <div className="field"><label htmlFor="pt">Saat</label><input id="pt" type="time" value={v.prayerTime} onChange={(e) => set('prayerTime', e.target.value)} /></div>
            <div className="field"><label htmlFor="mosque">Cami</label><input id="mosque" value={v.mosque} onChange={(e) => set('mosque', e.target.value)} /></div>
            <div className="field"><label htmlFor="bp">Defin yeri</label><input id="bp" value={v.burialPlace} onChange={(e) => set('burialPlace', e.target.value)} /></div>
            <div className="field" style={{ gridColumn: '1 / -1' }}><label htmlFor="ca">Taziye adresi (uygulamada “Yol tarifi” buraya gider; isteğe bağlı)</label><textarea id="ca" value={v.condolenceAddress} onChange={(e) => set('condolenceAddress', e.target.value)} /></div>
          </div>

          <label className="check" style={{ marginBottom: 20 }}>
            <input type="checkbox" checked={v.familyConsent} onChange={(e) => set('familyConsent', e.target.checked)} />
            <span>Aile onayı alındı (fotoğraf ve bilgilerin yayınlanması için zorunlu)</span>
          </label>

          <div className="note">
            <strong>Bildirim önizlemesi:</strong> Vefat · {v.name || '…'} — Cenaze namazı {v.prayerTime || '…'}, {v.mosque || '…'}.
            <br />
            <span className="muted">Editör olarak ilanı onaya gönderirsin; yönetici onaylayınca yayınlanır ve bildirim gider.</span>
          </div>
          {problems.length > 0 && (
            <p className="muted" role="status">Onaya göndermek için eksikler: {problems.join(' ')}</p>
          )}

          <div className="actions">
            <button className="btn" onClick={() => void saveDraft()}>Taslağı kaydet</button>
            <button className="btn dark" onClick={() => void submit()} disabled={problems.length > 0}>Onaya gönder</button>
          </div>
        </div>
      )}
    </Shell>
  );
}

/** Statik yayın (Firebase Hosting) için adres parametresi okunurken Suspense gerekir. */
export default function VefatEdit() {
  return (
    <Suspense fallback={null}>
      <VefatEditInner />
    </Suspense>
  );
}
