'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { CHAT_RETENTION_DAYS, cutoffDate, purgeOlderThan } = require('./retention');

/** Bellekte çalışan sahte Firestore: yalnızca createdAt'e göre süzme ve toplu silme. */
function fakeDb(times) {
  const docs = times.map((t, i) => ({ id: `m${i}`, createdAt: t }));
  return {
    docs,
    collection: () => ({
      where: (_f, _op, cutoff) => ({
        orderBy: () => ({
          limit: (n) => ({
            get: async () => ({
              docs: docs.filter((d) => d.createdAt < cutoff).slice(0, n).map((d) => ({ ref: d })),
            }),
          }),
        }),
      }),
    }),
    batch: () => {
      const refs = [];
      return {
        delete: (r) => refs.push(r),
        commit: async () => {
          for (const r of refs) docs.splice(docs.indexOf(r), 1);
        },
      };
    },
  };
}

test('saklama süresi 30 gündür', () => {
  assert.strictEqual(CHAT_RETENTION_DAYS, 30);
});

test('eşik tarih tam gün sayısı kadar geridedir', () => {
  const now = new Date('2026-10-31T12:00:00Z');
  assert.strictEqual(cutoffDate(now, 30).toISOString(), '2026-10-01T12:00:00.000Z');
});

test('yalnızca eşikten eski mesajlar silinir, yeniler kalır', async () => {
  const cutoff = new Date('2026-10-01T00:00:00Z');
  const db = fakeDb([
    new Date('2026-08-01T00:00:00Z'),
    new Date('2026-09-30T23:59:59Z'),
    new Date('2026-10-01T00:00:00Z'), // tam eşikte: kalır
    new Date('2026-10-20T00:00:00Z'),
  ]);
  const n = await purgeOlderThan(db, 'chat', cutoff);
  assert.strictEqual(n, 2);
  assert.strictEqual(db.docs.length, 2);
});

test('çok sayıda eski mesaj parça parça silinir', async () => {
  const cutoff = new Date('2026-10-01T00:00:00Z');
  const db = fakeDb(Array.from({ length: 1000 }, (_, i) => new Date(2026, 7, 1, 0, 0, i)));
  const n = await purgeOlderThan(db, 'chat', cutoff, 400);
  assert.strictEqual(n, 1000);
  assert.strictEqual(db.docs.length, 0);
});

test('silinecek mesaj yoksa sıfır döner', async () => {
  const db = fakeDb([new Date('2026-10-20T00:00:00Z')]);
  assert.strictEqual(await purgeOlderThan(db, 'chat', new Date('2026-10-01T00:00:00Z')), 0);
});
