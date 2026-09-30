'use strict';

/** Panelin yazdığı bildirim kaydını FCM mesajına çevirir. Konu, uygulamadaki abonelik adıdır. */
const TOPICS = ['vefat', 'haber', 'duyuru', 'kesinti'];

/** Kanal adları uygulamadaki MainActivity ile aynı olmalı (vefat: yüksek öncelikli). */
const CHANNEL = { vefat: 'vefat', haber: 'genel', duyuru: 'genel', kesinti: 'genel' };

function buildMessage(notice) {
  const topic = notice && notice.topic;
  if (!TOPICS.includes(topic)) throw new Error(`Geçersiz bildirim konusu: ${topic}`);
  const title = String(notice.title || '').trim();
  const body = String(notice.body || '').trim();
  if (!title || !body) throw new Error('Bildirimin başlığı ve metni gerekli.');

  return {
    topic,
    notification: { title, body },
    data: {
      topic,
      ...(notice.vefatId ? { vefatId: String(notice.vefatId) } : {}),
      ...(notice.newsId ? { newsId: String(notice.newsId) } : {}),
    },
    android: {
      priority: topic === 'vefat' ? 'high' : 'normal',
      notification: { channelId: CHANNEL[topic] },
    },
  };
}

/**
 * Bildirimi gönderir ve kaydı işaretler. Aynı kayıt iki kez işlenirse (yeniden deneme) ikinci kez göndermez.
 * `send` ve `markSent` dışarıdan verilir; böylece Firebase olmadan test edilir.
 */
async function handleNotice(notice, { send, markSent }) {
  if (!notice) return { sent: false, reason: 'boş kayıt' };
  if (notice.sentAt) return { sent: false, reason: 'zaten gönderilmiş' };
  const messageId = await send(buildMessage(notice));
  await markSent({ sentAt: new Date().toISOString(), messageId });
  return { sent: true, messageId };
}

module.exports = { buildMessage, handleNotice, TOPICS };
