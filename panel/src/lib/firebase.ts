import { getApps, initializeApp } from 'firebase/app';
import { connectAuthEmulator, getAuth } from 'firebase/auth';
import { connectFirestoreEmulator, initializeFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

/**
 * Web yapılandırması gizli değildir (her web uygulamasında herkese açıktır);
 * veriyi koruyan şey firestore.rules / storage.rules dosyalarıdır.
 */
const firebaseConfig = {
  apiKey: 'AIzaSyCbl-8MpYy2HV9tBL96umydm3JPbxr_8gc',
  authDomain: 'tavas-4f166.firebaseapp.com',
  projectId: 'tavas-4f166',
  storageBucket: 'tavas-4f166.firebasestorage.app',
  messagingSenderId: '227449958610',
  appId: '1:227449958610:web:b6719760a46a379733bd0b',
};

const existing = getApps()[0];
const app = existing ?? initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = initializeFirestore(app, { ignoreUndefinedProperties: true });
export const storage = getStorage(app);

// Yerel deneme: NEXT_PUBLIC_USE_EMULATOR=true ile gerçek projeye dokunmadan emülatöre bağlanır.
if (!existing && process.env.NEXT_PUBLIC_USE_EMULATOR === 'true') {
  connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
  connectFirestoreEmulator(db, '127.0.0.1', 8080);
}

/** Storage (Blaze planı gerektirir) açılana kadar fotoğraflar belgenin içinde saklanır. */
export const USE_STORAGE = process.env.NEXT_PUBLIC_USE_STORAGE === 'true';
