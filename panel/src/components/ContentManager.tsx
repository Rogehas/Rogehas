'use client';
import { useCallback, useEffect, useMemo, useState, type FormEvent, type ReactNode } from 'react';
import { Shell } from '@/components/Shell';
import { resizePhoto } from '@/lib/image';
import type { Section } from '@/lib/permissions';
import { useSession } from '@/lib/session';
import { store, type ContentCollection } from '@/lib/store';
import type { ContentBase } from '@/lib/types';

export interface FieldDef {
  key: string;
  label: string;
  type: 'text' | 'textarea' | 'select' | 'date' | 'time' | 'tel' | 'number' | 'decimal';
  options?: string[];
  placeholder?: string;
  hint?: string;
  /** Formda tüm satırı kaplar. */
  wide?: boolean;
}

export interface ContentConfig<T extends ContentBase> {
  section: Section;
  title: string;
  newLabel: string;
  collection: ContentCollection;
  fields: FieldDef[];
  /** Görsel seçme alanı gösterilsin mi (kayıtta `photo` alanı olmalı). */
  photo?: boolean;
  blank: (id: string) => T;
  validate: (item: T) => string[];
  /** Kaydetmeden önce değerleri düzenler (ör. telefonu rakamlara çevirir). */
  normalize?: (item: T) => T;
  sort: (a: T, b: T) => number;
  describe: (item: T) => { title: string; lines: string[] };
  emptyText: string;
  footnote?: ReactNode;
}

type Rec = Record<string, unknown>;

export function ContentManager<T extends ContentBase>({ config }: { config: ContentConfig<T> }) {
  const { user } = useSession();
  const [items, setItems] = useState<T[]>([]);
  const [editing, setEditing] = useState<T | null>(null);
  const [isNew, setIsNew] = useState(false);
  const [error, setError] = useState('');
  const [info, setInfo] = useState('');

  const refresh = useCallback(async () => {
    try {
      setItems(await store.listContent<T>(config.collection));
    } catch {
      setError('Kayıtlar yüklenemedi.');
    }
  }, [config.collection]);
  useEffect(() => {
    void refresh();
  }, [refresh]);

  const sorted = useMemo(() => [...items].sort(config.sort), [items, config.sort]);

  async function persist(item: T) {
    if (!user) return;
    const toSave = { ...(config.normalize ? config.normalize(item) : item), updatedAt: new Date().toISOString(), updatedBy: user.id };
    await store.upsertContent(config.collection, toSave as T & { id: string; photo?: string | null });
  }

  async function save(e: FormEvent) {
    e.preventDefault();
    if (!editing) return;
    setError('');
    setInfo('');
    const errs = config.validate(editing);
    if (errs.length) return setError(errs.join(' '));
    try {
      await persist(editing);
      setEditing(null);
      await refresh();
      setInfo('Kaydedildi.');
    } catch {
      setError('Kaydedilemedi. İnternet bağlantını ve yetkini kontrol et.');
    }
  }

  async function toggle(item: T) {
    setError('');
    setInfo('');
    try {
      await persist({ ...item, published: !item.published });
      await refresh();
      setInfo(item.published ? 'Uygulamadan gizlendi.' : 'Uygulamada yayında.');
    } catch {
      setError('Değiştirilemedi.');
    }
  }

  function set(key: string, value: unknown) {
    setEditing((p) => (p ? ({ ...p, [key]: value } as T) : p));
  }

  async function pickPhoto(file?: File) {
    if (!file) return;
    try {
      set('photo', await resizePhoto(file));
    } catch (e) {
      setError((e as Error).message);
    }
  }

  function input(f: FieldDef, rec: Rec) {
    const v = rec[f.key];
    const id = `f_${f.key}`;
    if (f.type === 'textarea')
      return <textarea id={id} placeholder={f.placeholder} value={(v as string) ?? ''} onChange={(e) => set(f.key, e.target.value)} />;
    if (f.type === 'select')
      return (
        <select id={id} value={(v as string) ?? ''} onChange={(e) => set(f.key, e.target.value)}>
          <option value="">Seçin…</option>
          {f.options?.map((o) => <option key={o} value={o}>{o}</option>)}
        </select>
      );
    if (f.type === 'number' || f.type === 'decimal')
      return (
        <input
          id={id}
          inputMode="decimal"
          placeholder={f.placeholder}
          value={typeof v === 'number' && Number.isFinite(v) ? v : ''}
          onChange={(e) => {
            const t = e.target.value.trim().replace(',', '.');
            // `number`: zorunlu sayı (boşsa NaN, doğrulama yakalar); `decimal`: isteğe bağlı (boşsa null)
            set(f.key, t === '' ? (f.type === 'decimal' ? null : Number.NaN) : Number(t));
          }}
        />
      );
    const htmlType = f.type === 'date' ? 'date' : f.type === 'time' ? 'time' : f.type === 'tel' ? 'tel' : 'text';
    return <input id={id} type={htmlType} inputMode={f.type === 'tel' ? 'tel' : undefined} placeholder={f.placeholder} value={(v as string) ?? ''} onChange={(e) => set(f.key, e.target.value)} />;
  }

  return (
    <Shell section={config.section} title={config.title}>
      {error && <div className="err" role="alert">{error}</div>}
      {info && <div className="note" role="status">{info}</div>}

      {editing ? (
        <form className="card" onSubmit={save} style={{ marginBottom: 20 }}>
          <h2 style={{ fontSize: 20, marginBottom: 16 }}>{isNew ? config.newLabel : 'Düzenle'}</h2>
          {config.photo && (
            <div style={{ display: 'flex', gap: 20, flexWrap: 'wrap', marginBottom: 20 }}>
              <div>
                <div className="photo">
                  {(editing as unknown as { photo: string | null }).photo ? (
                    <img src={(editing as unknown as { photo: string }).photo} alt="Seçilen görsel" />
                  ) : (
                    <span>Görsel yok<br />(isteğe bağlı)</span>
                  )}
                </div>
                <div className="actions" style={{ marginTop: 10 }}>
                  <label className="btn sm">
                    Görsel seç
                    <input type="file" accept="image/*" hidden onChange={(e) => pickPhoto(e.target.files?.[0])} />
                  </label>
                  {(editing as unknown as { photo: string | null }).photo && (
                    <button type="button" className="btn sm danger" onClick={() => set('photo', null)}>Kaldır</button>
                  )}
                </div>
              </div>
            </div>
          )}
          <div className="fields" style={{ marginBottom: 16 }}>
            {config.fields.map((f) => (
              <div className="field" key={f.key} style={f.wide ? { gridColumn: '1 / -1' } : undefined}>
                <label htmlFor={`f_${f.key}`}>{f.label}</label>
                {input(f, editing as unknown as Rec)}
                {f.hint && <span className="muted">{f.hint}</span>}
              </div>
            ))}
          </div>
          <div className="actions">
            <button className="btn dark" type="submit">Kaydet</button>
            <button className="btn" type="button" onClick={() => { setEditing(null); setError(''); }}>Vazgeç</button>
          </div>
        </form>
      ) : (
        <div className="actions" style={{ marginBottom: 16 }}>
          <button
            className="btn dark"
            onClick={() => {
              setEditing(config.blank(`${config.collection}_${Date.now()}`));
              setIsNew(true);
              setError('');
              setInfo('');
            }}
          >
            + {config.newLabel}
          </button>
        </div>
      )}

      <div className="card">
        {sorted.length === 0 && <p className="muted">{config.emptyText}</p>}
        {sorted.map((item) => {
          const d = config.describe(item);
          const photo = (item as unknown as { photo?: string | null }).photo;
          return (
            <div className="row" key={item.id}>
              {config.photo && <div className="avatar">{photo ? <img src={photo} alt="" /> : d.title.slice(0, 1)}</div>}
              <div className="grow">
                <strong style={{ fontSize: 17 }}>{d.title}</strong>{' '}
                <span className={`badge ${item.published ? 'published' : 'archived'}`}>{item.published ? 'Yayında' : 'Gizli'}</span>
                {d.lines.filter(Boolean).map((l, i) => <div className="muted" key={i}>{l}</div>)}
              </div>
              <div className="actions">
                <button className="btn sm" onClick={() => { setEditing(item); setIsNew(false); setError(''); setInfo(''); window.scrollTo({ top: 0, behavior: 'smooth' }); }}>Düzenle</button>
                <button className="btn sm" onClick={() => void toggle(item)}>{item.published ? 'Gizle' : 'Yayınla'}</button>
              </div>
            </div>
          );
        })}
        {config.footnote && <p className="muted">{config.footnote}</p>}
      </div>
    </Shell>
  );
}
