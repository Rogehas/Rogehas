'use client';
import {
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut,
} from 'firebase/auth';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react';
import { auth, db } from './firebase';
import type { PanelUser, Role } from './types';

/** 'out': giriş yok · 'ok': yetkili · 'noaccess': giriş yaptı ama panelde yetkisi yok/davetli değil */
type Status = 'out' | 'ok' | 'noaccess';

interface Ctx {
  user: PanelUser | null;
  ready: boolean;
  status: Status;
  authEmail: string | null;
  loginGoogle: () => Promise<void>;
  loginEmail: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const SessionCtx = createContext<Ctx>({
  user: null,
  ready: false,
  status: 'out',
  authEmail: null,
  loginGoogle: async () => {},
  loginEmail: async () => {},
  logout: async () => {},
});

export function SessionProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<PanelUser | null>(null);
  const [status, setStatus] = useState<Status>('out');
  const [authEmail, setAuthEmail] = useState<string | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(
    () =>
      onAuthStateChanged(auth, async (fb) => {
        if (!fb) {
          setUser(null);
          setStatus('out');
          setAuthEmail(null);
          return setReady(true);
        }
        setAuthEmail(fb.email);
        try {
          const profileRef = doc(db, 'users', fb.uid);
          let snap = await getDoc(profileRef);
          if (!snap.exists() && fb.email && fb.emailVerified) {
            // Davet edilmişse ilk girişte profili oluştur.
            const inv = await getDoc(doc(db, 'invites', fb.email.toLowerCase()));
            if (inv.exists()) {
              const d = inv.data() as { name?: string; role: Role };
              await setDoc(profileRef, {
                name: d.name || fb.displayName || fb.email,
                email: fb.email.toLowerCase(),
                role: d.role,
                active: true,
              });
              snap = await getDoc(profileRef);
            }
          }
          const data = snap.exists() ? (snap.data() as Omit<PanelUser, 'id'>) : null;
          if (data && data.active) {
            setUser({ id: fb.uid, ...data });
            setStatus('ok');
          } else {
            setUser(null);
            setStatus('noaccess');
          }
        } catch {
          setUser(null);
          setStatus('noaccess');
        }
        setReady(true);
      }),
    [],
  );

  const loginGoogle = useCallback(async () => {
    await signInWithPopup(auth, new GoogleAuthProvider());
  }, []);
  const loginEmail = useCallback(async (email: string, password: string) => {
    await signInWithEmailAndPassword(auth, email.trim(), password);
  }, []);
  const logout = useCallback(() => signOut(auth), []);

  return (
    <SessionCtx.Provider value={{ user, ready, status, authEmail, loginGoogle, loginEmail, logout }}>
      {children}
    </SessionCtx.Provider>
  );
}

export const useSession = () => useContext(SessionCtx);
