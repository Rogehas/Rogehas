'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { buildMessage, handleNotice } = require('./notify');

const vefat = { topic: 'vefat', title: 'Vefat · Ayşe Örnek', body: 'Cenaze namazı bugün 13:30, Merkez Camii.', vefatId: 'v1' };

test('vefat bildirimi yüksek öncelikli ve vefat kanalına gider', () => {
  const m = buildMessage(vefat);
  assert.strictEqual(m.topic, 'vefat');
  assert.strictEqual(m.android.priority, 'high');
  assert.strictEqual(m.android.notification.channelId, 'vefat');
  assert.deepStrictEqual(m.notification, { title: vefat.title, body: vefat.body });
  assert.strictEqual(m.data.vefatId, 'v1');
});

test('haber ve kesinti genel kanala, normal öncelikle gider', () => {
  const m = buildMessage({ topic: 'kesinti', title: 'Kesinti · SU', body: 'Yarın', newsId: 'h1' });
  assert.strictEqual(m.android.priority, 'normal');
  assert.strictEqual(m.android.notification.channelId, 'genel');
  assert.strictEqual(m.data.newsId, 'h1');
});

test('geçersiz konu ve boş metin reddedilir', () => {
  assert.throws(() => buildMessage({ topic: 'hepsi', title: 'a', body: 'b' }));
  assert.throws(() => buildMessage({ topic: 'vefat', title: ' ', body: 'b' }));
  assert.throws(() => buildMessage(undefined));
});

test('kayıt gönderilir ve işaretlenir', async () => {
  const calls = [];
  const res = await handleNotice(vefat, {
    send: async (m) => { calls.push(m); return 'projects/x/messages/1'; },
    markSent: async (f) => calls.push(f),
  });
  assert.strictEqual(res.sent, true);
  assert.strictEqual(calls.length, 2);
  assert.ok(calls[1].sentAt);
  assert.strictEqual(calls[1].messageId, 'projects/x/messages/1');
});

test('zaten gönderilmiş kayıt ikinci kez gönderilmez', async () => {
  let sends = 0;
  const res = await handleNotice({ ...vefat, sentAt: '2026-09-30T10:00:00Z' }, {
    send: async () => { sends++; return 'x'; },
    markSent: async () => {},
  });
  assert.strictEqual(res.sent, false);
  assert.strictEqual(sends, 0);
});

test('gönderim hatası işaretlenmeden yukarı fırlatılır', async () => {
  let marked = false;
  await assert.rejects(handleNotice(vefat, {
    send: async () => { throw new Error('fcm down'); },
    markSent: async () => { marked = true; },
  }), /fcm down/);
  assert.strictEqual(marked, false);
});
