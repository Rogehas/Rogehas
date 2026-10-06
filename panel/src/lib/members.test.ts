import { describe, expect, it } from 'vitest';
import { filterMembers } from './members';
import type { Member } from './types';

const m = (uid: string, name: string, email: string): Member => ({ uid, name, email, createdAt: '2026-09-01T10:00:00Z' });
const list = [m('1', 'Şükrü Çelik', 'sukru@x.com'), m('2', 'Ayşe Demir', 'ayse.demir@y.com'), m('3', 'IŞIK Yılmaz', 'isik@z.com')];

describe('filterMembers', () => {
  it('boş arama hepsini verir', () => {
    expect(filterMembers(list, '  ')).toHaveLength(3);
  });
  it('Türkçe harflerden bağımsız ada göre arar', () => {
    expect(filterMembers(list, 'sukru').map((x) => x.uid)).toEqual(['1']);
    expect(filterMembers(list, 'ŞÜKRÜ').map((x) => x.uid)).toEqual(['1']);
    expect(filterMembers(list, 'ışık').map((x) => x.uid)).toEqual(['3']);
  });
  it('e-postaya göre arar', () => {
    expect(filterMembers(list, 'y.com').map((x) => x.uid)).toEqual(['2']);
    expect(filterMembers(list, 'yok')).toEqual([]);
  });
});
