'use client';
import { ContentManager, type ContentConfig } from '@/components/ContentManager';
import { normalizeAnyPhone, validateBusiness } from '@/lib/content';
import { BUSINESS_CATEGORIES, type Business } from '@/lib/types';

const config: ContentConfig<Business> = {
  section: 'esnaf',
  title: 'Yerel esnaf',
  newLabel: 'Yeni işletme',
  collection: 'businesses',
  photo: true,
  fields: [
    { key: 'name', label: 'İşletme adı', type: 'text', wide: true },
    { key: 'category', label: 'Kategori', type: 'select', options: BUSINESS_CATEGORIES },
    { key: 'phone', label: 'Telefon (isteğe bağlı)', type: 'tel', placeholder: '0258 614 00 00' },
    { key: 'address', label: 'Adres', type: 'text', wide: true },
    { key: 'hours', label: 'Çalışma saatleri (isteğe bağlı)', type: 'text', placeholder: 'Her gün 08:00 – 22:00' },
    { key: 'description', label: 'Açıklama', type: 'textarea', wide: true },
    { key: 'lat', label: 'Enlem (isteğe bağlı)', type: 'decimal', placeholder: '37.5715' },
    { key: 'lng', label: 'Boylam (isteğe bağlı)', type: 'decimal', placeholder: '29.0700', hint: 'Koordinat girilirse “Yol tarifi” tam konuma gider; girilmezse adrese göre aranır.' },
  ],
  blank: (id) => ({
    id, name: '', category: '', description: '', phone: '', address: '', hours: '',
    lat: null, lng: null, photo: null, published: true, updatedAt: '', updatedBy: '',
  }),
  validate: validateBusiness,
  normalize: (b) => ({ ...b, phone: b.phone.trim() ? normalizeAnyPhone(b.phone) : '' }),
  sort: (a, b) => BUSINESS_CATEGORIES.indexOf(a.category) - BUSINESS_CATEGORIES.indexOf(b.category) || a.name.localeCompare(b.name, 'tr'),
  describe: (b) => ({ title: b.name, lines: [`${b.category}${b.phone ? ` · ${b.phone}` : ''}`, b.address, b.hours] }),
  emptyText: 'Henüz işletme eklenmedi.',
  footnote: 'İşletme bilgileri doğrulanmış olmalı. Kapanan ya da bilgisi geçersiz olan işletmeyi “Gizle” ile uygulamadan kaldır.',
};

export default function BusinessPage() {
  return <ContentManager config={config} />;
}
