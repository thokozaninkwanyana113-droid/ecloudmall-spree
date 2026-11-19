'use client';

import { useActionState } from 'react';
import { applyCoupon, type ActionState } from '@/app/actions';

export function CouponForm() {
  const [state, action, pending] = useActionState<ActionState, FormData>(applyCoupon, {});
  return (
    <form action={action} className="rounded-3xl border-2 border-ink bg-white p-4">
      <label className="label" htmlFor="code">Promo code</label>
      <div className="flex gap-2">
        <input id="code" name="code" required placeholder="e.g. LEKKER10" className="field py-2 uppercase" />
        <button disabled={pending} className="btn btn-light px-4 py-2">Apply</button>
      </div>
      {state.error && <p className="mt-2 text-sm font-bold text-flame">{state.error}</p>}
      {state.ok && <p className="mt-2 text-sm font-bold text-veld">{state.message}</p>}
    </form>
  );
}
