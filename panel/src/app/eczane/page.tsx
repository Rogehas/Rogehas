'use client';
import { useCallback, useEffect, useMemo, useState, type FormEvent } from 'react';
import { Shell } from '@/components/Shell';
import { addDays, dateRange, normalizePhone, todayString, validatePharmacy, weekdayName } from '@/lib/duty';
import { useSession } from '@/lib/session';
import { store } from '@/lib/store';
import type { DutyDay, Pharmacy } from '@/lib/types';

const UPCOMING_DAYS = 14;

function blank(): Pharmacy {
  return { id: `ph_${Date.now()}`, name: '', neighborhood: '', address: '', phone: '', lat: null, lng: null, active: true, updatedAt: '' };
}

export default function PharmacyPage() {
  const { user } = useSession();
  const [tab, setTab] = useState<'duty' | 'list'>('duty');
  const [pharmacies, setPharmacies] = useState<Pharmacy[]>([]);
  const [duty, setDuty] = useState<DutyDay[]>([]);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  const today = todayString();
  const [start, setStart] = useState(today);
  const [end, setEnd] = useState(today);
  const [selected, setSelected] = useState<string[]>([]);
  const [editing, setEditing] = useState<Pharmacy | null>(null);

  const refresh = useCallback(async () => {
    try {
      const [p, d] = await Promise.all([store.pharmacies(), store.dutyFrom(todayString())]);
      setPharmacies(p);
      setDuty(d);
    } catch {
      setError('Veriler yüklenemedi.');
    }
  }, []);
  useEffect(() => {
    void refresh();
  }, [refresh]);

  const active = useMemo(() => pharmacies.filter((p) => p.active), [pharmacies]);
  const byId = useMemo(() => new Map(pharmacies.map((p) => [p.id, p])), [pharmacies]);
  const dutyByDate = useMemo(() => new Map(duty.map((d) => [d.date, d])), [duty]);
  const upcoming = useMemo(() => Array.from({ length: UPCOMING_DAYS }, (_, i) => addDays(today, i)), [today]);

  function flash(msg: string) {
    setInfo(msg);
    setError('');
  }

  async function saveDuty(e: FormEvent) {
    e.preventDefault();
    if (!user) return;
    setError('');
    setInfo('');
    try {
      const dates = dateRange(start, end);
      if (selected.length === 0 && !window.confirm('Hiç eczane seçilmedi. Bu günlerin nöbeti boşaltılsın mı?')) return;
      await store.setDuty(dates, selected, user.id);
      await refresh();
      flash(`${dates.length} gün için nöbet kaydedildi.`);
    } catch (err) {
      setError((err as Error).message);
    }
  }

  function pickDay(date: string) {
    setStart(date);
    setEnd(date);
    setSelected(dutyByDate.get(date)?.pharmacyIds ?? []);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  async function savePharmacy(e: FormEvent) {
    e.preventDefault();
    if (!editing) return;
    setError('');
    setInfo('');
    const errs = validatePharmacy(editing);
    if (errs.length) return setError(errs.join(' '));
    try {
      await store.upsertPharmacy({ ...editing, phone: normalizePhone(editing.phone), updatedAt: new Date().toISOString() });
      setEditing(null);
      await refresh();
      flash('Eczane kaydedildi.');
    } catch {
      setError('Eczane kaydedilemedi.');
    }
  }

  const num = (v: string) => (v.trim() === '' ? null : Number(v.replace(',', '.')));

  return (
    <Shell section="eczane" title="Nöbetçi eczane">
      {error && <div className="err" role="alert">{error}</div>}
      {info && <div className="note" role="status">{info}</div>}
      <div className="tabs" role="tablist">
        <button role="tab" aria-selected={tab === 'duty'} className={`tab${tab === 'duty' ? ' on' : ''}`} onClick={() => setTab('duty')}>Nöbet takvimi</button>
        <button role="tab" aria-selected={tab === 'list'} className={`tab${tab === 'list' ? ' on' : ''}`} onClick={() => setTab('list')}>Eczaneler</button>
      </div>

      {tab === 'duty' && (
        <>
          <div className="card" style={{ marginBottom: 20 }}>
            <h2 style={{ fontSize: 20, marginBottom: 8 }}>Nöbet yaz</h2>
            <p className="muted" style={{ marginTop: 0 }}>
              Nöbet, seçilen günün 09:00&apos;ından ertesi gün 09:00&apos;una kadar sürer. Aynı eczaneleri birden çok güne yazmak için tarih aralığı seç.
            </p>
            {active.length === 0 ? (
              <p className="muted">Önce “Eczaneler” sekmesinden eczane ekle.</p>
            ) : (
              <form onSubmit={saveDuty}>
                <div className="fields" style={{ marginBottom: 16 }}>
                  <div className="field"><label htmlFor="s">Başlangıç</label><input id="s" type="date" value={start} onChange={(e) => { setStart(e.target.value); if (e.target.value > end) setEnd(e.target.value); }} /></div>
                  <div className="field"><label htmlFor="e">Bitiş</label><input id="e" type="date" value={end} min={start} onChange={(e) => setEnd(e.target.value)} /></div>
                </div>
                <fieldset style={{ border: 0, padding: 0, margin: '0 0 16px' }}>
                  <legend style={{ fontSize: 13, fontWeight: 800, marginBottom: 8 }}>O gün nöbetçi olan eczaneler</legend>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                    {active.map((p) => (
                      <label className="check" key={p.id}>
                        <input
                          type="checkbox"
                          checked={selected.includes(p.id)}
                          onChange={(e) => setSelected((s) => (e.target.checked ? [...s, p.id] : s.filter((x) => x !== p.id)))}
                        />
                        <span>{p.name} <span className="muted">· {p.neighborhood || p.address}</span></span>
                      </label>
                    ))}
                  </div>
                </fieldset>
                <button className="btn dark" type="submit">Nöbeti kaydet</button>
              </form>
            )}
          </div>

          <div className="card">
            <h2 style={{ fontSize: 20, marginBottom: 8 }}>Önümüzdeki {UPCOMING_DAYS} gün</h2>
            <table>
              <thead><tr><th>Tarih</th><th>Nöbetçi eczaneler</th><th /></tr></thead>
              <tbody>
                {upcoming.map((date) => {
                  const d = dutyByDate.get(date);
                  const names = (d?.pharmacyIds ?? []).map((id) => byId.get(id)?.name ?? '(silinmiş eczane)');
                  return (
                    <tr key={date}>
                      <td><strong>{date}</strong> <span className="muted">{weekdayName(date)}</span></td>
                      <td>{names.length ? names.join(', ') : <span style={{ color: 'var(--clay)', fontWeight: 700 }}>Girilmemiş</span>}</td>
                      <td><button className="btn sm" onClick={() => pickDay(date)}>Düzenle</button></td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
            <p className="muted">Girilmemiş günlerde uygulama “Bu gün için nöbet bilgisi girilmedi” gösterir.</p>
          </div>
        </>
      )}

      {tab === 'list' && (
        <>
          {editing ? (
            <form className="card" onSubmit={savePharmacy} style={{ marginBottom: 20 }}>
              <h2 style={{ fontSize: 20, marginBottom: 16 }}>{editing.updatedAt ? 'Eczaneyi düzenle' : 'Yeni eczane'}</h2>
              <div className="fields" style={{ marginBottom: 16 }}>
                <div className="field"><label htmlFor="n">Eczane adı</label><input id="n" value={editing.name} onChange={(e) => setEditing({ ...editing, name: e.target.value })} /></div>
                <div className="field"><label htmlFor="m">Mahalle</label><input id="m" value={editing.neighborhood} onChange={(e) => setEditing({ ...editing, neighborhood: e.target.value })} /></div>
                <div className="field"><label htmlFor="t">Telefon</label><input id="t" inputMode="tel" placeholder="0258 614 00 00" value={editing.phone} onChange={(e) => setEditing({ ...editing, phone: e.target.value })} /></div>
                <div className="field" style={{ gridColumn: '1 / -1' }}><label htmlFor="a">Adres</label><input id="a" value={editing.address} onChange={(e) => setEditing({ ...editing, address: e.target.value })} /></div>
                <div className="field"><label htmlFor="la">Enlem (isteğe bağlı)</label><input id="la" inputMode="decimal" placeholder="37.5715" value={editing.lat ?? ''} onChange={(e) => setEditing({ ...editing, lat: num(e.target.value) })} /></div>
                <div className="field"><label htmlFor="lo">Boylam (isteğe bağlı)</label><input id="lo" inputMode="decimal" placeholder="29.0700" value={editing.lng ?? ''} onChange={(e) => setEditing({ ...editing, lng: num(e.target.value) })} /></div>
              </div>
              <p className="muted">Enlem/boylam girilirse “Yol tarifi” tam konuma gider; girilmezse adrese göre aranır. Google Haritalar&apos;da eczaneye sağ tıklayıp koordinatı kopyalayabilirsin.</p>
              <div className="actions">
                <button className="btn dark" type="submit">Kaydet</button>
                <button className="btn" type="button" onClick={() => { setEditing(null); setError(''); }}>Vazgeç</button>
              </div>
            </form>
          ) : (
            <div className="actions" style={{ marginBottom: 16 }}>
              <button className="btn dark" onClick={() => setEditing(blank())}>+ Yeni eczane</button>
            </div>
          )}
          <div className="card">
            {pharmacies.length === 0 && <p className="muted">Henüz eczane eklenmedi.</p>}
            {pharmacies.map((p) => (
              <div className="row" key={p.id}>
                <div className="grow">
                  <strong style={{ fontSize: 17 }}>{p.name}</strong>{' '}
                  <span className={`badge ${p.active ? 'published' : 'archived'}`}>{p.active ? 'Aktif' : 'Kapalı'}</span>
                  <div className="muted">{p.neighborhood ? `${p.neighborhood} · ` : ''}{p.address}</div>
                  <div className="muted">{p.phone}{p.lat !== null ? ` · ${p.lat}, ${p.lng}` : ''}</div>
                </div>
                <div className="actions">
                  <button className="btn sm" onClick={() => { setEditing(p); setError(''); }}>Düzenle</button>
                  <button className="btn sm" onClick={async () => { await store.upsertPharmacy({ ...p, active: !p.active, updatedAt: new Date().toISOString() }); await refresh(); }}>
                    {p.active ? 'Kapat' : 'Aç'}
                  </button>
                </div>
              </div>
            ))}
            <p className="muted">Kapatılan eczane yeni nöbet yazarken listede çıkmaz. Geçmiş nöbetler etkilenmez.</p>
          </div>
        </>
      )}
    </Shell>
  );
}
