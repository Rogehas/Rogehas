'use client';
import { useRouter } from 'next/navigation';
import { useEffect, useState, type FormEvent } from 'react';
import { useSession } from '@/lib/session';

function friendly(e: unknown): string {
  const code = (e as { code?: string }).code ?? '';
  if (code.includes('invalid-credential') || code.includes('wrong-password') || code.includes('user-not-found'))
    return 'E-posta ya da şifre hatalı.';
  if (code.includes('popup-closed')) return 'Giriş penceresi kapatıldı.';
  if (code.includes('too-many-requests')) return 'Çok fazla deneme. Biraz bekleyip tekrar dene.';
  if (code.includes('network')) return 'Bağlantı hatası. İnternetini kontrol et.';
  return 'Giriş yapılamadı.';
}

export default function Login() {
  const { user, ready, status, authEmail, loginGoogle, loginEmail, logout } = useSession();
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (ready && user) router.replace('/');
  }, [ready, user, router]);

  async function attempt(fn: () => Promise<void>) {
    setError('');
    setBusy(true);
    try {
      await fn();
    } catch (e) {
      setError(friendly(e));
    } finally {
      setBusy(false);
    }
  }

  const submit = (e: FormEvent) => {
    e.preventDefault();
    void attempt(() => loginEmail(email, password));
  };

  return (
    <div className="login">
      <div className="brand" style={{ color: 'var(--ink)' }}>
        <div className="logo">T</div>
        <h1>Tavas Panel</h1>
      </div>
      <div className="card">
        <h2 style={{ fontSize: 22, marginBottom: 16 }}>Giriş yap</h2>
        {status === 'noaccess' && (
          <div className="err" role="alert">
            <strong>{authEmail}</strong> hesabı panele yetkili değil. Yöneticiden seni e-posta adresinle davet etmesini iste,
            sonra tekrar giriş yap.
            <div style={{ marginTop: 10 }}>
              <button className="btn sm" onClick={() => void logout()}>Başka hesapla dene</button>
            </div>
          </div>
        )}
        {error && <div className="err" role="alert">{error}</div>}
        <button className="btn dark" style={{ width: '100%', height: 52 }} disabled={busy} onClick={() => void attempt(loginGoogle)}>
          Google ile giriş yap
        </button>
        <p className="muted" style={{ textAlign: 'center', margin: '16px 0' }}>ya da e-posta ile</p>
        <form onSubmit={submit} className="fields" style={{ gridTemplateColumns: '1fr' }}>
          <div className="field"><label htmlFor="em">E-posta</label><input id="em" type="email" autoComplete="username" value={email} onChange={(e) => setEmail(e.target.value)} required /></div>
          <div className="field"><label htmlFor="pw">Şifre</label><input id="pw" type="password" autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} required /></div>
          <button className="btn lime" type="submit" disabled={busy} style={{ height: 48 }}>Giriş yap</button>
        </form>
      </div>
    </div>
  );
}
