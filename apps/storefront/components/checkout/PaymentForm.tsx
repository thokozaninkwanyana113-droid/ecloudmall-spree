'use client';

import { useActionState, useEffect, useRef, useState } from 'react';
import type { PaymentMethod } from '@spree/sdk';
import { placeOrder, type PaymentState } from '@/app/actions';

const BADGES: Record<string, { icon: string; tags: string[] }> = {
  Payfast: { icon: '💳', tags: ['Card', 'Instant EFT', 'SnapScan', 'Zapper'] },
  Ozow: { icon: '⚡', tags: ['Instant EFT', 'All major SA banks'] },
  Yoco: { icon: '📱', tags: ['Card', 'Apple Pay', 'Google Pay'] },
};

function providerOf(m: PaymentMethod) {
  return m.type.split('::').pop() ?? '';
}

export function PaymentForm({ methods, total }: { methods: PaymentMethod[]; total: string }) {
  const [state, action, pending] = useActionState<PaymentState, FormData>(placeOrder, {});
  const sorted = [...methods].sort((a, b) => Number(b.session_required) - Number(a.session_required));
  const [selected, setSelected] = useState(sorted[0]?.id ?? '');
  const redirectForm = useRef<HTMLFormElement>(null);
  const current = sorted.find((m) => m.id === selected);

  // Hand the shopper over to the provider's secure page
  useEffect(() => {
    if (!state.redirect) return;
    if (state.redirect.method === 'GET') window.location.assign(state.redirect.url);
    else redirectForm.current?.submit();
  }, [state.redirect]);

  if (methods.length === 0) return <p className="font-bold text-flame">No payment methods are available right now.</p>;

  const online = sorted.filter((m) => m.session_required);
  const offline = sorted.filter((m) => !m.session_required);

  return (
    <>
      <form action={action} className="space-y-3">
        {online.length > 0 && <p className="label">Pay now — secure online payment</p>}
        {online.map((m) => (
          <MethodOption key={m.id} m={m} selected={selected} onSelect={setSelected} />
        ))}
        {offline.length > 0 && <p className="label pt-2">Or pay later</p>}
        {offline.map((m) => (
          <MethodOption key={m.id} m={m} selected={selected} onSelect={setSelected} />
        ))}
        {state.error && <p className="rounded-2xl border-2 border-ink bg-flame px-4 py-3 text-sm font-bold text-white" role="alert">{state.error}</p>}
        <button disabled={pending || !selected || Boolean(state.redirect)} className="btn btn-primary w-full text-lg">
          {state.redirect
            ? `Taking you to ${providerOf(current!)}…`
            : pending
              ? 'One moment…'
              : current?.session_required
                ? `Pay ${total} securely →`
                : `Place order · ${total}`}
        </button>
        <p className="text-center text-xs text-ink/60">
          {current?.session_required ? '🔒 You’ll complete payment on the provider’s secure page. We never see your card or banking details. ' : ''}
          Your details are protected under POPIA.
        </p>
      </form>
      {state.redirect && state.redirect.method === 'POST' && (
        <form ref={redirectForm} method="POST" action={state.redirect.url} className="hidden">
          {Object.entries(state.redirect.fields).map(([k, v]) => (
            <input key={k} type="hidden" name={k} value={v} />
          ))}
        </form>
      )}
    </>
  );
}

function MethodOption({ m, selected, onSelect }: { m: PaymentMethod; selected: string; onSelect: (id: string) => void }) {
  const badge = BADGES[providerOf(m)];
  return (
    <label className={`flex cursor-pointer gap-4 rounded-2xl border-2 border-ink p-4 transition ${selected === m.id ? 'bg-lime shadow-[4px_4px_0_#0b0b0f]' : 'bg-white hover:bg-cream'}`}>
      <input type="radio" name="payment_method_id" value={m.id} checked={selected === m.id} onChange={() => onSelect(m.id)} className="mt-1 h-5 w-5 accent-ink" />
      <span className="flex-1">
        <span className="block font-bold">{badge?.icon ?? (m.name.includes('EFT') ? '🏦' : '💵')} {m.name}</span>
        {m.description && <span className="block text-sm text-ink/70">{m.description}</span>}
        {badge && (
          <span className="mt-2 flex flex-wrap gap-1">
            {badge.tags.map((t) => (
              <span key={t} className="rounded-full border border-ink bg-white px-2 py-0.5 text-[11px] font-bold">{t}</span>
            ))}
          </span>
        )}
      </span>
    </label>
  );
}
