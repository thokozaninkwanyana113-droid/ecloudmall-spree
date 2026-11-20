'use client';

import { useActionState } from 'react';
import Link from 'next/link';
import { saveAddress, type ActionState } from '@/app/actions';

type Defaults = Record<'email' | 'first_name' | 'last_name' | 'phone' | 'address1' | 'address2' | 'city' | 'postal_code' | 'state_abbr', string>;

export function AddressForm({ states, defaults, loggedIn }: { states: { abbr: string; name: string }[]; defaults: Defaults; loggedIn: boolean }) {
  const [state, action, pending] = useActionState<ActionState, FormData>(saveAddress, {});
  const err = (k: string) => state.fieldErrors?.[k]?.[0] ?? state.fieldErrors?.[`shipping_address.${k}`]?.[0] ?? state.fieldErrors?.[`ship_address.${k}`]?.[0];

  return (
    <form action={action} className="grid gap-4 sm:grid-cols-2">
      {!loggedIn && (
        <p className="text-sm sm:col-span-2">
          Have an account? <Link href="/account/login?redirect_to=/checkout" className="font-bold underline">Log in</Link> for faster checkout.
        </p>
      )}
      <Field label="Email" name="email" type="email" autoComplete="email" defaultValue={defaults.email} required span error={err('email')} />
      <Field label="First name" name="first_name" autoComplete="given-name" defaultValue={defaults.first_name} required error={err('firstname') ?? err('first_name')} />
      <Field label="Last name" name="last_name" autoComplete="family-name" defaultValue={defaults.last_name} required error={err('lastname') ?? err('last_name')} />
      <Field label="Mobile number" name="phone" type="tel" autoComplete="tel" placeholder="082 123 4567" defaultValue={defaults.phone} required span error={err('phone')} />
      <Field label="Street address" name="address1" autoComplete="address-line1" placeholder="12 Vilakazi Street" defaultValue={defaults.address1} required span error={err('address1')} />
      <Field label="Complex / building / suburb (optional)" name="address2" autoComplete="address-line2" defaultValue={defaults.address2} span />
      <Field label="City / town" name="city" autoComplete="address-level2" defaultValue={defaults.city} required error={err('city')} />
      <Field label="Postal code" name="postal_code" autoComplete="postal-code" inputMode="numeric" pattern="[0-9]{4}" title="4-digit postal code" defaultValue={defaults.postal_code} required error={err('zipcode') ?? err('postal_code')} />
      <div className="sm:col-span-2">
        <label className="label" htmlFor="state_abbr">Province</label>
        <select id="state_abbr" name="state_abbr" defaultValue={defaults.state_abbr} required className="field">
          <option value="">Select your province</option>
          {states.map((s) => (
            <option key={s.abbr} value={s.abbr}>{s.name.replace(' (South Africa)', '')}</option>
          ))}
        </select>
      </div>
      <div className="sm:col-span-2">
        <label className="label" htmlFor="customer_note">Delivery notes (optional)</label>
        <textarea id="customer_note" name="customer_note" rows={2} placeholder="Gate code, landmarks, best time to deliver…" className="field" />
      </div>
      {state.error && <p className="rounded-2xl border-2 border-ink bg-flame px-4 py-3 text-sm font-bold text-white sm:col-span-2" role="alert">{state.error}</p>}
      <button disabled={pending} className="btn btn-dark sm:col-span-2">{pending ? 'Saving…' : 'Continue to delivery →'}</button>
    </form>
  );
}

function Field({ label, name, span, error, ...props }: React.InputHTMLAttributes<HTMLInputElement> & { label: string; name: string; span?: boolean; error?: string }) {
  return (
    <div className={span ? 'sm:col-span-2' : ''}>
      <label className="label" htmlFor={name}>{label}</label>
      <input id={name} name={name} className="field" aria-invalid={Boolean(error)} {...props} />
      {error && <p className="mt-1 text-sm font-bold text-flame">{error}</p>}
    </div>
  );
}
