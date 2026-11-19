import Link from 'next/link';
import type { Metadata } from 'next';
import { RegisterForm } from '@/components/AuthForms';

export const metadata: Metadata = { title: 'Create an account' };

export default function RegisterPage() {
  return (
    <div className="mx-auto max-w-md px-4 py-16">
      <h1 className="font-display text-5xl font-extrabold tracking-tight">Join EcloudMall</h1>
      <p className="mt-2 text-ink/70">Save your details, track orders and get first dibs on new local drops.</p>
      <div className="mt-8"><RegisterForm /></div>
      <p className="mt-6 text-center">Already have an account? <Link href="/account/login" className="font-bold underline">Log in</Link></p>
    </div>
  );
}
