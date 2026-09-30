'use client';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { canAccess } from '@/lib/permissions';
import { useSession } from '@/lib/session';

export default function Home() {
  const { user, ready } = useSession();
  const router = useRouter();
  useEffect(() => {
    if (!ready) return;
    if (!user) router.replace('/login');
    else router.replace(canAccess(user.role, 'vefat') ? '/vefat' : '/moderasyon');
  }, [ready, user, router]);
  return null;
}
