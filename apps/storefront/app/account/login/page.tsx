import Link from 'next/link';
import type { Metadata } from 'next';
import { LoginForm } from '@/components/AuthForms';

export const metadata: Metadata = { title: 'Log in' };

export default async function LoginPage({ searchParams }: { searchParams: Promise<{ redirect_to?: string }> }) {
  const { redirect_to } = await searchParams;
  return (
    <div className="mx-auto max-w-md px-4 py-16">
      <h1 className="font-display text-5xl font-extrabold tracking-tight">Welcome back</h1>
      <p className="mt-2 text-ink/70">Log in to track orders and check out faster.</p>
      <div className="mt-8"><LoginForm redirectTo={redirect_to?.startsWith('/') ? redirect_to : '/account'} /></div>
      <p className="mt-6 text-center">New here? <Link href="/account/register" className="font-bold underline">Create an account</Link></p>
    </div>
  );
}
