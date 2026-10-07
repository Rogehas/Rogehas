'use client';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Shell } from '@/components/Shell';
import { AD_STATUS_LABEL, adStatus, MAX_AD_TEXT, MAX_ADS_PER_PLACEMENT, normalizeAd, placementOverflow, todayKey, validateAd } from '@/lib/ad-rules';
import { resizePhoto } from '@/lib/image';
import { useSession } from '@/lib/session';
import { store } from '@/lib/store';
import { AD_ACTION_LABEL, AD_PLACEMENT_LABEL, AD_PLACEMENTS, type Ad, type AdAction, type AdPlacement, type AdStat } from '@/lib/types';

const blank = (): Ad => ({
  id: `ad_${Date.now()}`, name: '', text: '', photo: null, action: 'call', actionValue: '', placements: [],
  startDate: '', endDate: '', active: true, createdAt: '', updatedAt: '', updatedBy: '',
});

const dateTr = (d: string) => (d ? new Date(`${d}T00:00:00`).toLocaleDateString('tr-TR') : '');
const monthKey = (d = new Date()) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;

export default function Ads() {
  const { user } = useSession();
  const [ads, setAds] = useState<Ad[]>([]);
  const [stats, setStats] = useState<AdStat[]>([]);
  const [enabled, setEnabled] = useState(true);
  const [editing, setEditing] = useState<Ad | null>(null);
  const [loaded, setLoaded] = useState(false);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  const refresh = useCallback(async () => {
    try {
      const [a, s, e] = await Promise.all([store.ads(), store.adStats(), store.adsEnabled()]);
      setAds(a);
      setStats(s);
      setEnabled(e);
      setLoaded(true);
    } catch {
      setError('Reklamlar yüklenemedi.');
    }
  }, []);
  useEffect(() => {
    if (user) void refresh();
  }, [user, refresh]);

  async function act(run: () => Promise<void>, done: string) {
    setError('');
    setInfo('');
    try {
      await run();
      await refresh();
      setInfo(done);
    } catch (e) {
      setError((e as Error).message);
    }
  }

  const thisMonth = monthKey();
  const totals = useMemo(() => {
    const m = new Map<string, { month: AdStat; all: AdStat }>();
    for (const s of stats) {
      const cur = m.get(s.adId) ?? { month: { adId: s.adId, month: thisMonth, impressions: 0, clicks: 0 }, all: { adId: s.adId, month: '', impressions: 0, clicks: 0 } };
      cur.all.impressions += s.impressions;
      cur.all.clicks += s.clicks;
      if (s.month === thisMonth) {
        cur.month.impressions += s.impressions;
        cur.month.clicks += s.clicks;
      }
      m.set(s.adId, cur);
    }
    return m;
  }, [stats, thisMonth]);

  function save() {
    if (!editing || !user) return;
    const ad = normalizeAd(editing);
    const errs = validateAd(ad);
    if (errs.length) return setError(errs.join(' '));
    const overflow = placementOverflow(ads, ad);
    if (overflow.length) {
      return setError(
        `Şu yerlerde zaten ${MAX_ADS_PER_PLACEMENT} açık reklam var: ${overflow.map((p) => AD_PLACEMENT_LABEL[p]).join(', ')}. Birini kapatın ya da bu reklamın yerlerini değiştirin.`,
      );
    }
    const now = new Date().toISOString();
    const next: Ad = { ...ad, createdAt: ad.createdAt || now, updatedAt: now, updatedBy: user.id };
    void act(async () => {
      await store.upsertAd(next);
      setEditing(null);
    }, 'Reklam kaydedildi.');
  }

  const set = <K extends keyof Ad>(k: K, v: Ad[K]) => setEditing((e) => (e ? { ...e, [k]: v } : e));
  const togglePlacement = (p: AdPlacement) =>
    setEditing((e) => (e ? { ...e, placements: e.placements.includes(p) ? e.placements.filter((x) => x !== p) : [...e.placements, p] } : e));

  async function pickPhoto(file?: File) {
    if (!file) return;
    try {
      set('photo', await resizePhoto(file));
    } catch (e) {
      setError((e as Error).message);
    }
  }

  return (
    <Shell
      section="reklam"
      title="Sponsor reklamlar"
      actions={!editing && <button className="btn lime" onClick={() => { setError(''); setInfo(''); setEditing(blank()); }}>Yeni reklam</button>}
    >
      {error && <div className="err" role="alert">{error}</div>}
      {info && <div className="note" role="status">{info}</div>}

      <div className="card" style={{ marginBottom: 20 }}>
        <label className="check" style={{ margin: 0 }}>
          <input
            type="checkbox"
            checked={enabled}
            onChange={(e) => void act(() => store.setAdsEnabled(e.target.checked, user!.id), e.target.checked ? 'Reklamlar açıldı.' : 'Tüm reklamlar kapatıldı; uygulamada hiçbir yerde görünmez.')}
          />
          <span><strong>Reklamları göster</strong> — kapatırsan tek tıkla tüm reklamlar uygulamadan kalkar (reklamlar silinmez).</span>
        </label>
        <p className="muted" style={{ marginBottom: 0 }}>
          Aynı yerde birden fazla açık reklam varsa uygulama her açılışta sırayla birini gösterir. Bir yerde en fazla {MAX_ADS_PER_PLACEMENT} açık reklam olabilir.
          Gösterim, uygulama oturumu başına bir kez sayılır; tıklama her dokunuşta sayılır.
        </p>
      </div>

      {editing && (
        <div className="card" style={{ marginBottom: 20 }}>
          <h2 style={{ fontSize: 20, marginBottom: 14 }}>{ads.some((a) => a.id === editing.id) ? 'Reklamı düzenle' : 'Yeni reklam'}</h2>
          <div className="fields">
            <div className="field"><label htmlFor="adn">Esnaf / reklam veren</label><input id="adn" value={editing.name} onChange={(e) => set('name', e.target.value)} /></div>
            <div className="field">
              <label htmlFor="adt">Kısa metin ({editing.text.trim().length}/{MAX_AD_TEXT})</label>
              <input id="adt" value={editing.text} onChange={(e) => set('text', e.target.value)} placeholder="Sıcak simit ve poğaça, her sabah 06:00'dan itibaren" />
            </div>
            <div className="field">
              <label htmlFor="ada">Dokununca ne olsun</label>
              <select id="ada" value={editing.action} onChange={(e) => set('action', e.target.value as AdAction)}>
                {(Object.keys(AD_ACTION_LABEL) as AdAction[]).map((a) => <option key={a} value={a}>{AD_ACTION_LABEL[a]}</option>)}
              </select>
            </div>
            <div className="field">
              <label htmlFor="adv">{editing.action === 'call' ? 'Telefon' : editing.action === 'map' ? 'Adres' : 'Web adresi'}</label>
              <input id="adv" value={editing.actionValue} onChange={(e) => set('actionValue', e.target.value)} placeholder={editing.action === 'call' ? '0258 614 00 00' : editing.action === 'map' ? 'Cumhuriyet Cd. No:3, Tavas' : 'tavasfirini.com'} />
            </div>
            <div className="field"><label htmlFor="ads">Başlangıç (boşsa hemen)</label><input id="ads" type="date" value={editing.startDate} onChange={(e) => set('startDate', e.target.value)} /></div>
            <div className="field"><label htmlFor="ade">Bitiş (boşsa süresiz)</label><input id="ade" type="date" value={editing.endDate} onChange={(e) => set('endDate', e.target.value)} /></div>
          </div>

          <h3 style={{ margin: '20px 0 8px' }}>Nerelerde görünsün?</h3>
          <div style={{ display: 'grid', gap: 6 }}>
            {AD_PLACEMENTS.map((p) => (
              <label className="check" key={p.key} style={{ margin: 0 }}>
                <input type="checkbox" checked={editing.placements.includes(p.key)} onChange={() => togglePlacement(p.key)} />
                <span>{p.label}</span>
              </label>
            ))}
          </div>

          <h3 style={{ margin: '20px 0 8px' }}>Görsel (isteğe bağlı)</h3>
          <div className="photo-row" style={{ display: 'flex', gap: 14, alignItems: 'center' }}>
            <div className="photo">{editing.photo ? <img src={editing.photo} alt="Reklam görseli" /> : <span>Görsel yok<br />(işletme harfi görünür)</span>}</div>
            <div className="actions">
              <label className="btn sm">
                {editing.photo ? 'Değiştir' : 'Görsel seç'}
                <input type="file" accept="image/*" hidden onChange={(e) => void pickPhoto(e.target.files?.[0])} />
              </label>
              {editing.photo && <button className="btn sm danger" onClick={() => set('photo', null)}>Kaldır</button>}
            </div>
          </div>
          <p className="muted">Kare ya da yatay bir logo/afiş uygundur; şeritlerde küçük, kartlarda geniş görünür ve gerekirse kırpılır.</p>

          <label className="check" style={{ margin: '14px 0' }}>
            <input type="checkbox" checked={editing.active} onChange={(e) => set('active', e.target.checked)} />
            <span>Reklam açık (kapalıysa kaydedilir ama uygulamada görünmez)</span>
          </label>
          <div className="actions">
            <button className="btn lime" onClick={save}>Kaydet</button>
            <button className="btn" onClick={() => { setEditing(null); setError(''); }}>Vazgeç</button>
          </div>
        </div>
      )}

      <div className="card">
        {!loaded && !error && <p className="muted">Yükleniyor…</p>}
        {loaded && ads.length === 0 && <p className="muted">Henüz reklam yok. Reklam eklemezsen uygulamada hiçbir yerde reklam alanı görünmez.</p>}
        {ads.map((a) => {
          const st = adStatus(a, todayKey());
          const t = totals.get(a.id);
          const ctr = t && t.month.impressions > 0 ? ((t.month.clicks / t.month.impressions) * 100).toFixed(1) : '0';
          return (
            <div className="row" key={a.id} style={st === 'live' ? undefined : { opacity: 0.65 }}>
              <div className="grow">
                <strong>{a.name}</strong> <span className="muted">· {AD_STATUS_LABEL[st]}{a.startDate ? ` · ${dateTr(a.startDate)}` : ''}{a.endDate ? ` → ${dateTr(a.endDate)}` : a.startDate ? ' → süresiz' : ''}</span>
                <div>{a.text}</div>
                <div className="muted">{a.placements.map((p) => AD_PLACEMENT_LABEL[p]).join(' · ')}</div>
                <div className="muted">
                  Bu ay: <strong>{t?.month.impressions ?? 0}</strong> gösterim, <strong>{t?.month.clicks ?? 0}</strong> tıklama (%{ctr})
                  {' · '}Toplam: {t?.all.impressions ?? 0} gösterim, {t?.all.clicks ?? 0} tıklama
                </div>
              </div>
              <div className="actions">
                <button className="btn sm" onClick={() => { setError(''); setInfo(''); setEditing({ ...a }); window.scrollTo({ top: 0, behavior: 'smooth' }); }}>Düzenle</button>
                <button
                  className="btn sm"
                  onClick={() => {
                    const next = { ...a, active: !a.active, updatedAt: new Date().toISOString(), updatedBy: user!.id };
                    const over = placementOverflow(ads, next);
                    if (over.length) return setError(`Şu yerlerde zaten ${MAX_ADS_PER_PLACEMENT} açık reklam var: ${over.map((p) => AD_PLACEMENT_LABEL[p]).join(', ')}.`);
                    void act(() => store.upsertAd(next), next.active ? 'Reklam açıldı.' : 'Reklam kapatıldı.');
                  }}
                >
                  {a.active ? 'Kapat' : 'Aç'}
                </button>
                <button className="btn sm danger" onClick={() => { if (confirm(`“${a.name}” reklamı silinsin mi? Bu işlem geri alınamaz.`)) void act(() => store.deleteAd(a.id), 'Reklam silindi.'); }}>Sil</button>
              </div>
            </div>
          );
        })}
      </div>
    </Shell>
  );
}
