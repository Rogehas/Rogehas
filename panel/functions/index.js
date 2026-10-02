'use strict';
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const logger = require('firebase-functions/logger');
const { handleNotice } = require('./notify');
const { CHAT_RETENTION_DAYS, cutoffDate, purgeOlderThan } = require('./retention');

initializeApp();

// Bölge Firestore veritabanının konumuyla uyumlu olmalı (ilk yüklemede hata mesajı doğru bölgeyi söyler).
const REGION = process.env.FUNCTIONS_REGION || 'europe-west1';

/** Panel bir `notices` kaydı oluşturunca ilgili konuya abone telefonlara bildirim gönderir. */
exports.sendNotice = onDocumentCreated(
  { document: 'notices/{id}', region: REGION, retry: false },
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    try {
      const res = await handleNotice(snap.data(), {
        send: (message) => getMessaging().send(message),
        markSent: (fields) => snap.ref.update(fields),
      });
      logger.info('Bildirim işlendi', { id: event.params.id, ...res });
    } catch (e) {
      logger.error('Bildirim gönderilemedi', { id: event.params.id, error: String(e) });
      await snap.ref.update({ error: String(e), failedAt: new Date().toISOString() });
    }
  },
);


/** Her gece 04:00'te (Türkiye saati) 30 günden eski genel sohbet mesajlarını siler. */
exports.cleanupChat = onSchedule(
  { schedule: 'every day 04:00', timeZone: 'Europe/Istanbul', region: REGION, retryCount: 1 },
  async () => {
    const cutoff = cutoffDate(new Date(), CHAT_RETENTION_DAYS);
    const deleted = await purgeOlderThan(getFirestore(), 'chat', cutoff);
    logger.info('Eski sohbet mesajları silindi', { deleted, cutoff: cutoff.toISOString() });
  },
);
