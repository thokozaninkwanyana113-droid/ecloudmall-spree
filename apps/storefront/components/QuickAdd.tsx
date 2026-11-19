'use client';

import { useActionState } from 'react';
import { addToCart, type ActionState } from '@/app/actions';

export function QuickAdd({ variantId, name }: { variantId: string; name: string }) {
  const [state, action, pending] = useActionState<ActionState, FormData>(addToCart, {});
  return (
    <form action={action}>
      <input type="hidden" name="variant_id" value={variantId} />
      <input type="hidden" name="quantity" value="1" />
      <button
        type="submit"
        disabled={pending}
        aria-label={`Add ${name} to cart`}
        className={`grid h-11 w-11 place-items-center rounded-full border-2 border-ink text-lg font-black transition active:scale-90 ${
          state.ok ? 'bg-veld text-white' : 'bg-sun hover:bg-lime'
        } ${pending ? 'animate-pulse' : ''}`}
      >
        {state.ok ? '✓' : '+'}
      </button>
    </form>
  );
}
