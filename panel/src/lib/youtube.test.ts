import { describe, expect, it } from 'vitest';
import { youtubeId } from './youtube';

const ID = 'dQw4w9WgXcQ';
describe('youtubeId', () => {
  it('yaygın link biçimlerini tanır', () => {
    for (const u of [
      `https://www.youtube.com/watch?v=${ID}`,
      `https://youtube.com/watch?v=${ID}&t=30s`,
      `https://m.youtube.com/watch?feature=share&v=${ID}`,
      `https://youtu.be/${ID}?si=abc`,
      `https://www.youtube.com/embed/${ID}`,
      `https://www.youtube.com/shorts/${ID}`,
      `https://www.youtube.com/live/${ID}?feature=share`,
      `youtu.be/${ID}`,
      `  https://youtu.be/${ID}  `,
    ]) {
      expect(youtubeId(u), u).toBe(ID);
    }
  });
  it('geçersiz veya başka siteye ait linkleri reddeder', () => {
    for (const u of ['', '   ', 'merhaba', 'https://vimeo.com/123456789', 'https://youtube.com/watch?v=kisa', 'https://evil.com/watch?v=' + ID, 'https://youtube.com.evil.com/watch?v=' + ID, 'https://youtube.com/']) {
      expect(youtubeId(u), u).toBeNull();
    }
    expect(youtubeId(null)).toBeNull();
    expect(youtubeId(undefined)).toBeNull();
  });
});
