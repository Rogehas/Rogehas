'use client';
import { ContentManager, type ContentConfig } from '@/components/ContentManager';
import { normalizeAnyPhone, validateGuide } from '@/lib/content';
import { GUIDE_CATEGORIES, type GuideEntry } from '@/lib/types';

const config: ContentConfig<GuideEntry> = {
  section: 'rehber',
  title: 'Rehber',
  newLabel: 'Yeni kayıt',
  collection: 'guide',
  fields: [
    { key: 'name', label: 'Ad', type: 'text', placeholder: 'Acil Yardım, Belediye Santral…', wide: true },
    { key: 'category', label: 'Kategori', type: 'select', options: GUIDE_CATEGORIES },
    { key: 'phone', label: 'Telefon', type: 'tel', placeholder: '112 ya da 0258 614 00 00' },
    { key: 'address', label: 'Adres (isteğe bağlı)', type: 'text', wide: true },
    { key: 'note', label: 'Not (çalışma saatleri, dolmuş saatleri vb.)', type: 'textarea', wide: true },
    { key: 'order', label: 'Sıra', type: 'number', hint: 'Küçük sayı önce çıkar (1, 2, 3…). Kategori içinde sıralar.' },
  ],
  blank: (id) => ({
    id, name: '', category: '', phone: '', address: '', note: '', order: 10,
    published: true, updatedAt: '', updatedBy: '',
  }),
  validate: validateGuide,
  normalize: (g) => ({ ...g, phone: normalizeAnyPhone(g.phone) }),
  sort: (a, b) => GUIDE_CATEGORIES.indexOf(a.category) - GUIDE_CATEGORIES.indexOf(b.category) || a.order - b.order || a.name.localeCompare(b.name, 'tr'),
  describe: (g) => ({ title: g.name, lines: [`${g.category} · ${g.phone}`, g.address, g.note] }),
  emptyText: 'Henüz rehber kaydı eklenmedi. Acil numaralarla (112, 155, 110) başlayabilirsin.',
  footnote: 'Uygulamada kategoriye göre gruplanır, kategori içinde “Sıra”ya göre dizilir. Gizlenen kayıt uygulamada görünmez.',
};

export default function GuidePage() {
  return <ContentManager config={config} />;
}
