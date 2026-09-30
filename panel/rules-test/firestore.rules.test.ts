import { assertFails, assertSucceeds, initializeTestEnvironment, type RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';

let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'tavas-rules-test',
    firestore: { rules: readFileSync('firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
  });
});
afterAll(() => env.cleanup());

const profile = (role: string, active = true) => ({ name: role, email: `${role}@example.com`, role, active });
const vefat = (over = {}) => ({
  name: 'Ayşe Örnek', photo: null, familyConsent: true, status: 'draft', createdBy: 'ed1', ...over,
});
const news = (over = {}) => ({ title: 'Başlık', kind: 'haber', photo: null, status: 'draft', createdBy: 'ed1', ...over });

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/adm'), profile('admin'));
    await setDoc(doc(db, 'users/ed1'), profile('editor'));
    await setDoc(doc(db, 'users/ed2'), profile('editor'));
    await setDoc(doc(db, 'users/mod'), profile('moderator'));
    await setDoc(doc(db, 'users/off'), profile('editor', false));
    await setDoc(doc(db, 'vefat/pub'), vefat({ status: 'published' }));
    await setDoc(doc(db, 'vefat/drf'), vefat());
    await setDoc(doc(db, 'vefat/pen'), vefat({ status: 'pending' }));
    await setDoc(doc(db, 'news/pub'), news({ status: 'published' }));
    await setDoc(doc(db, 'news/drf'), news());
    await setDoc(doc(db, 'invites/yeni@example.com'), { role: 'editor', name: 'Yeni' });
  });
});

const as = (uid: string | null, claims: Record<string, unknown> = {}) =>
  (uid ? env.authenticatedContext(uid, claims) : env.unauthenticatedContext()).firestore();

describe('vefat okuma', () => {
  it('misafir yalnızca yayınlanmış ilanı okur', async () => {
    await assertSucceeds(getDoc(doc(as(null), 'vefat/pub')));
    await assertFails(getDoc(doc(as(null), 'vefat/drf')));
  });
  it('editör taslakları da okur; moderatör okumaz', async () => {
    await assertSucceeds(getDoc(doc(as('ed2'), 'vefat/drf')));
    await assertFails(getDoc(doc(as('mod'), 'vefat/drf')));
  });
  it('kapatılmış editör taslakları okuyamaz', async () => {
    await assertFails(getDoc(doc(as('off'), 'vefat/drf')));
  });
});

describe('vefat yazma', () => {
  it('editör kendi adına taslak oluşturur, yayınlanmış oluşturamaz', async () => {
    await assertSucceeds(setDoc(doc(as('ed1'), 'vefat/n1'), vefat()));
    await assertFails(setDoc(doc(as('ed1'), 'vefat/n2'), vefat({ status: 'published' })));
    await assertFails(setDoc(doc(as('ed1'), 'vefat/n3'), vefat({ createdBy: 'ed2' })));
  });
  it('editör kendi taslağını onaya gönderir ama yayınlayamaz', async () => {
    await assertSucceeds(updateDoc(doc(as('ed1'), 'vefat/drf'), { status: 'pending' }));
    await assertFails(updateDoc(doc(as('ed1'), 'vefat/drf'), { status: 'published' }));
  });
  it('editör başkasının ilanını ve onay bekleyeni düzenleyemez', async () => {
    await assertFails(updateDoc(doc(as('ed2'), 'vefat/drf'), { name: 'X' }));
    await assertFails(updateDoc(doc(as('ed1'), 'vefat/pen'), { name: 'X' }));
  });
  it('aile onayı olmadan onaya gönderilemez, yayınlanamaz', async () => {
    await assertFails(updateDoc(doc(as('ed1'), 'vefat/drf'), { status: 'pending', familyConsent: false }));
    await assertFails(updateDoc(doc(as('adm'), 'vefat/pen'), { status: 'published', familyConsent: false }));
  });
  it('yönetici onaylar ve arşivler; arşivlenen değişmez', async () => {
    await assertSucceeds(updateDoc(doc(as('adm'), 'vefat/pen'), { status: 'published' }));
    await assertSucceeds(updateDoc(doc(as('adm'), 'vefat/pub'), { status: 'archived' }));
    await assertFails(updateDoc(doc(as('adm'), 'vefat/pub'), { name: 'Y' })); // arşivlendi
  });
  it('moderatör ve misafir yazamaz', async () => {
    await assertFails(setDoc(doc(as('mod'), 'vefat/m'), vefat({ createdBy: 'mod' })));
    await assertFails(setDoc(doc(as(null), 'vefat/g'), vefat()));
  });
});

describe('haberler', () => {
  it('editör onaysız yayınlar, arşivleyemez', async () => {
    await assertSucceeds(updateDoc(doc(as('ed2'), 'news/drf'), { status: 'published' }));
    await assertFails(updateDoc(doc(as('ed1'), 'news/pub'), { status: 'archived' }));
  });
  it('yönetici arşivler; misafir yalnızca yayınlanmış haberi görür', async () => {
    await assertSucceeds(getDoc(doc(as(null), 'news/pub')));
    await assertFails(getDoc(doc(as(null), 'news/drf')));
    await assertSucceeds(updateDoc(doc(as('adm'), 'news/pub'), { status: 'archived' }));
    await assertFails(getDoc(doc(as(null), 'news/pub'))); // arşivlenen haber herkese kapanır
  });
});

describe('kullanıcılar ve davetler', () => {
  it('yönetici rol atar; editör atayamaz', async () => {
    await assertSucceeds(updateDoc(doc(as('adm'), 'users/ed2'), { role: 'admin' }));
    await assertFails(updateDoc(doc(as('ed1'), 'users/ed1'), { role: 'admin' }));
  });
  it('kullanıcı kendi profilini okur, başkasınınkini okuyamaz', async () => {
    await assertSucceeds(getDoc(doc(as('ed1'), 'users/ed1')));
    await assertFails(getDoc(doc(as('ed1'), 'users/ed2')));
  });
  it('davetli kişi doğrulanmış e-postasıyla davetteki rolle kaydolur', async () => {
    const ok = as('newuid', { email: 'yeni@example.com', email_verified: true });
    await assertSucceeds(setDoc(doc(ok, 'users/newuid'), { name: 'Yeni', email: 'yeni@example.com', role: 'editor', active: true }));
  });
  it('rol yükseltme, doğrulanmamış e-posta ve davetsiz kayıt reddedilir', async () => {
    const verified = as('u1', { email: 'yeni@example.com', email_verified: true });
    await assertFails(setDoc(doc(verified, 'users/u1'), { name: 'Y', email: 'yeni@example.com', role: 'admin', active: true }));
    const unverified = as('u2', { email: 'yeni@example.com', email_verified: false });
    await assertFails(setDoc(doc(unverified, 'users/u2'), { name: 'Y', email: 'yeni@example.com', role: 'editor', active: true }));
    const stranger = as('u3', { email: 'yabanci@example.com', email_verified: true });
    await assertFails(setDoc(doc(stranger, 'users/u3'), { name: 'Y', email: 'yabanci@example.com', role: 'editor', active: true }));
  });
  it('yalnızca yönetici davet oluşturur', async () => {
    await assertSucceeds(setDoc(doc(as('adm'), 'invites/a@example.com'), { role: 'editor', name: 'A' }));
    await assertFails(setDoc(doc(as('ed1'), 'invites/b@example.com'), { role: 'admin', name: 'B' }));
  });
});
