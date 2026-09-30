'use client';
import { ContentManager, type ContentConfig } from '@/components/ContentManager';
import { validateEvent } from '@/lib/content';
import { todayString } from '@/lib/duty';
import type { EventItem } from '@/lib/types';

const config: ContentConfig<EventItem> = {
  section: 'etkinlik',
  title: 'Etkinlikler',
  newLabel: 'Yeni etkinlik',
  collection: 'events',
  photo: true,
  fields: [
    { key: 'title', label: 'Etkinlik adı', type: 'text', wide: true },
    { key: 'date', label: 'Başlangıç tarihi', type: 'date' },
    { key: 'endDate', label: 'Bitiş tarihi (çok günlüyse)', type: 'date' },
    { key: 'time', label: 'Saat (isteğe bağlı)', type: 'time' },
    { key: 'place', label: 'Yer', type: 'text' },
    { key: 'description', label: 'Açıklama', type: 'textarea', wide: true },
  ],
  blank: (id) => ({
    id, title: '', description: '', date: todayString(), endDate: '', time: '', place: '',
    photo: null, published: true, updatedAt: '', updatedBy: '',
  }),
  validate: validateEvent,
  // Yeni tarihler önce; geçmiş etkinlikler listenin sonunda
  sort: (a, b) => {
    const today = todayString();
    const pa = (a.endDate || a.date) < today;
    const pb = (b.endDate || b.date) < today;
    if (pa !== pb) return pa ? 1 : -1;
    return pa ? b.date.localeCompare(a.date) : a.date.localeCompare(b.date);
  },
  describe: (e) => ({
    title: e.title,
    lines: [
      `${e.date}${e.endDate && e.endDate !== e.date ? ` – ${e.endDate}` : ''}${e.time ? ` · ${e.time}` : ''} · ${e.place}`,
      (e.endDate || e.date) < todayString() ? 'Geçmiş etkinlik (uygulamada listelenmez)' : '',
    ],
  }),
  emptyText: 'Henüz etkinlik eklenmedi.',
  footnote: 'Uygulamada yalnızca bugün ve sonrası için olan, “Yayında” durumundaki etkinlikler görünür. Geçmiş etkinlikler otomatik gizlenir.',
};

export default function EventsPage() {
  return <ContentManager config={config} />;
}
