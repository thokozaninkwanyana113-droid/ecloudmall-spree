'use client';

import { useActionState, useState } from 'react';
import Link from 'next/link';
import { addToCart, type ActionState } from '@/app/actions';

type VariantOption = { id: string; label: string; price: string; available: boolean };

export function AddToCart({ defaultVariantId, variants }: { defaultVariantId: string; variants?: VariantOption[] }) {
  const [state, action, pending] = useActionState<ActionState, FormData>(addToCart, {});
  const [qty, setQty] = useState(1);
  const [variantId, setVariantId] = useState(variants?.find((v) => v.available)?.id ?? defaultVariantId);

  return (
    <form action={action} className="space-y-4">
      {variants && variants.length > 0 && (
        <fieldset>
          <legend className="label">Choose an option</legend>
          <div className="flex flex-wrap gap-2">
            {variants.map((v) => (
              <button
                type="button"
                key={v.id}
                disabled={!v.available}
                onClick={() => setVariantId(v.id)}
                className={`chip ${variantId === v.id ? 'chip-active' : ''} disabled:line-through disabled:opacity-40`}
              >
                {v.label}
              </button>
            ))}
          </div>
        </fieldset>
      )}
      <input type="hidden" name="variant_id" value={variantId} />
      <div className="flex flex-wrap items-center gap-3">
        <div className="flex items-center rounded-full border-2 border-ink bg-white">
          <button type="button" aria-label="Decrease quantity" className="h-12 w-12 text-xl font-black" onClick={() => setQty((q) => Math.max(1, q - 1))}>−</button>
          <input name="quantity" value={qty} readOnly aria-label="Quantity" className="w-10 bg-transparent text-center font-bold outline-none" />
          <button type="button" aria-label="Increase quantity" className="h-12 w-12 text-xl font-black" onClick={() => setQty((q) => Math.min(20, q + 1))}>+</button>
        </div>
        <button type="submit" disabled={pending} className="btn btn-primary flex-1 text-lg">
          {pending ? 'Adding…' : 'Add to cart'}
        </button>
        <button type="submit" name="buy_now" value="1" disabled={pending} className="btn btn-dark flex-1 text-lg">
          Buy now
        </button>
      </div>
      {state.ok && (
        <p className="flex items-center justify-between rounded-2xl border-2 border-ink bg-lime px-4 py-3 font-bold" role="status">
          ✓ {state.message}
          <Link href="/cart" className="underline">View cart →</Link>
        </p>
      )}
      {state.error && <p className="rounded-2xl border-2 border-ink bg-flame px-4 py-3 font-bold text-white" role="alert">{state.error}</p>}
    </form>
  );
}
