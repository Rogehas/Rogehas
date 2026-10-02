'use strict';

/** Sohbet mesajlarının saklanma süresi (gün). */
const CHAT_RETENTION_DAYS = 30;

/** `now` anından `days` gün öncesi. */
function cutoffDate(now, days) {
  return new Date(now.getTime() - days * 24 * 60 * 60 * 1000);
}

/**
 * `createdAt` değeri `cutoff`tan eski belgeleri parça parça siler; silinen sayıyı döner.
 * `db` yalnızca şu arayüzü bekler (Firestore Admin ile uyumlu, testte sahtesi kullanılır):
 *   db.collection(name).where('createdAt', '<', cutoff).orderBy('createdAt').limit(n).get() -> { docs: [{ ref }] }
 *   db.batch() -> { delete(ref), commit() }
 */
async function purgeOlderThan(db, collection, cutoff, batchSize = 400, maxBatches = 50) {
  let deleted = 0;
  for (let i = 0; i < maxBatches; i += 1) {
    const snap = await db.collection(collection).where('createdAt', '<', cutoff).orderBy('createdAt').limit(batchSize).get();
    if (snap.docs.length === 0) break;
    const batch = db.batch();
    for (const d of snap.docs) batch.delete(d.ref);
    await batch.commit();
    deleted += snap.docs.length;
    if (snap.docs.length < batchSize) break;
  }
  return deleted;
}

module.exports = { CHAT_RETENTION_DAYS, cutoffDate, purgeOlderThan };
