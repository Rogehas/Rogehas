'use strict';
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const logger = require('firebase-functions/logger');
const { handleNotice } = require('./notify');

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

