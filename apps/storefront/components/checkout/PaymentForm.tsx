'use client';

import { useActionState, useState } from 'react';
import type { PaymentMethod } from '@spree/sdk';
import { placeOrder, type ActionState } from '@/app/actions';

export function PaymentForm({ methods, total }: { methods: PaymentMethod[]; total: string }) {
  const [state, action, pending] = useActionState<ActionState, FormData>(placeOrder, {});
  const [selected, setSelected] = useState(methods[0]?.id ?? '');

  if (methods.length === 0) return <p className="font-bold text-flame">No payment methods are available right now.</p>;

  return (
    <form action={action} className="space-y-3">
      {methods.map((m) => (
        <label key={m.id} className={`flex cursor-pointer gap-4 rounded-2xl border-2 border-ink p-4 transition ${selected === m.id ? 'bg-lime shadow-[4px_4px_0_#0b0b0f]' : 'bg-white hover:bg-cream'}`}>
          <input type="radio" name="payment_method_id" value={m.id} checked={selected === m.id} onChange={() => setSelected(m.id)} className="mt-1 h-5 w-5 accent-ink" />
          <span>
            <span className="block font-bold">{m.name.includes('EFT') ? '🏦 ' : '💵 '}{m.name}</span>
            {m.description && <span className="block text-sm text-ink/70">{m.description}</span>}
          </span>
        </label>
      ))}
      {state.error && <p className="rounded-2xl border-2 border-ink bg-flame px-4 py-3 text-sm font-bold text-white" role="alert">{state.error}</p>}
      <button disabled={pending || !selected} className="btn btn-primary w-full text-lg">
        {pending ? 'Placing your order…' : `Place order · ${total}`}
      </button>
      <p className="text-center text-xs text-ink/60">By placing your order you agree to EcloudMall’s terms. Your details are protected under POPIA.</p>
    </form>
  );
}
