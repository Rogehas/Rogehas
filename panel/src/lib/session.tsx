'use client';
import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react';
import { store } from './store';
import type { PanelUser } from './types';

const KEY = 'tavas.panel.session';

interface Ctx {
  user: PanelUser | null;
  ready: boolean;
  login: (userId: string) => void;
  logout: () => void;
}

const SessionCtx = createContext<Ctx>({ user: null, ready: false, login: () => {}, logout: () => {} });

/** Geçici oturum: demo kullanıcı seçimi. Firebase Auth (e-posta / Google) ile değişecek. */
export function SessionProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<PanelUser | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    try {
      const id = localStorage.getItem(KEY);
      const found = id ? store.users().find((u) => u.id === id && u.active) : null;
      setUser(found ?? null);
    } catch {
      setUser(null);
    }
    setReady(true);
  }, []);

  const login = useCallback((id: string) => {
    const u = store.users().find((x) => x.id === id && x.active) ?? null;
    if (u) localStorage.setItem(KEY, u.id);
    setUser(u);
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem(KEY);
    setUser(null);
  }, []);

  return <SessionCtx.Provider value={{ user, ready, login, logout }}>{children}</SessionCtx.Provider>;
}

export const useSession = () => useContext(SessionCtx);
