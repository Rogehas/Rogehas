/** YouTube linkinden video kimliğini çıkarır; geçerli bir link değilse null. */
export function youtubeId(url: string | null | undefined): string | null {
  const raw = (url ?? '').trim();
  if (!raw) return null;
  let u: URL;
  try {
    u = new URL(/^https?:\/\//i.test(raw) ? raw : `https://${raw}`);
  } catch {
    return null;
  }
  const host = u.hostname.toLowerCase().replace(/^www\.|^m\./, '');
  const ok = (id: string | null | undefined) => (id && /^[A-Za-z0-9_-]{11}$/.test(id) ? id : null);
  if (host === 'youtu.be') return ok(u.pathname.split('/')[1]);
  if (host === 'youtube.com' || host === 'youtube-nocookie.com') {
    if (u.pathname === '/watch') return ok(u.searchParams.get('v'));
    const m = u.pathname.match(/^\/(?:embed|shorts|live|v)\/([^/?#]+)/);
    return m ? ok(m[1]) : null;
  }
  return null;
}

/** Kapak resmi (YouTube verir). */
export const youtubeThumb = (id: string) => `https://img.youtube.com/vi/${id}/hqdefault.jpg`;
