'use client';

import { useActionState } from 'react';
import { login, register, type ActionState } from '@/app/actions';

export function LoginForm({ redirectTo }: { redirectTo: string }) {
  const [state, action, pending] = useActionState<ActionState, FormData>(login, {});
  return (
    <form action={action} className="card-pop space-y-4 rounded-3xl bg-white p-6">
      <input type="hidden" name="redirect_to" value={redirectTo} />
      <div><label className="label" htmlFor="email">Email</label><input id="email" name="email" type="email" autoComplete="email" required className="field" /></div>
      <div><label className="label" htmlFor="password">Password</label><input id="password" name="password" type="password" autoComplete="current-password" required className="field" /></div>
      {state.error && <p className="rounded-2xl border-2 border-ink bg-flame px-4 py-3 text-sm font-bold text-white" role="alert">{state.error}</p>}
      <button disabled={pending} className="btn btn-dark w-full">{pending ? 'Logging in…' : 'Log in'}</button>
    </form>
  );
}

export function RegisterForm() {
  const [state, action, pending] = useActionState<ActionState, FormData>(register, {});
  const err = (k: string) => state.fieldErrors?.[k]?.[0];
  return (
    <form action={action} className="card-pop space-y-4 rounded-3xl bg-white p-6">
      <div className="grid grid-cols-2 gap-3">
        <div><label className="label" htmlFor="first_name">First name</label><input id="first_name" name="first_name" autoComplete="given-name" required className="field" /></div>
        <div><label className="label" htmlFor="last_name">Last name</label><input id="last_name" name="last_name" autoComplete="family-name" required className="field" /></div>
      </div>
      <div><label className="label" htmlFor="email">Email</label><input id="email" name="email" type="email" autoComplete="email" required className="field" />{err('email') && <p className="mt-1 text-sm font-bold text-flame">Email {err('email')}</p>}</div>
      <div><label className="label" htmlFor="phone">Mobile (optional)</label><input id="phone" name="phone" type="tel" autoComplete="tel" className="field" /></div>
      <div><label className="label" htmlFor="password">Password</label><input id="password" name="password" type="password" autoComplete="new-password" minLength={6} required className="field" />{err('password') && <p className="mt-1 text-sm font-bold text-flame">Password {err('password')}</p>}</div>
      <label className="flex items-center gap-3 text-sm"><input type="checkbox" name="marketing" className="h-5 w-5 accent-ink" /> Send me new drops & deals from local makers</label>
      {state.error && <p className="rounded-2xl border-2 border-ink bg-flame px-4 py-3 text-sm font-bold text-white" role="alert">{state.error}</p>}
      <button disabled={pending} className="btn btn-primary w-full">{pending ? 'Creating account…' : 'Create account'}</button>
    </form>
  );
}
