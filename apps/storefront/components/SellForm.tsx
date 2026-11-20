'use client';

import { useActionState } from 'react';
import Link from 'next/link';
import { applyToSell, type ActionState } from '@/app/actions';
import { PROVINCES, CATEGORY_ORDER } from '@/lib/constants';

const BUSINESS_TYPES = [
  ['sole_proprietor', 'Sole Proprietor'],
  ['pty_ltd', 'Private Company (Pty) Ltd'],
  ['cooperative', 'Co-operative'],
  ['partnership', 'Partnership'],
  ['npc', 'Non-Profit Company (NPC)'],
  ['informal', 'Informal / not yet registered'],
];

export function SellForm() {
  const [state, action, pending] = useActionState<ActionState, FormData>(applyToSell, {});
  const err = (k: string) => state.fieldErrors?.[k]?.[0];

  if (state.ok) {
    return (
      <div className="card-pop rounded-3xl bg-lime p-10 text-center">
        <p className="text-6xl">🚀</p>
        <h3 className="mt-4 font-display text-3xl font-extrabold">Application received!</h3>
        <p className="mx-auto mt-2 max-w-lg text-lg">{state.message}</p>
        <Link href="/sellers" className="btn btn-dark mt-6">See who’s already selling</Link>
      </div>
    );
  }

  return (
    <form action={action} className="card-pop space-y-8 rounded-3xl bg-white p-6 md:p-10">
      <Fieldset title="1. Your business">
        <Input label="Business / brand name" name="name" required span error={err('name')} />
        <Input label="One-line pitch" name="tagline" placeholder="e.g. Hand-poured soy candles with fynbos scents" maxLength={160} span error={err('tagline')} />
        <div className="sm:col-span-2">
          <label className="label" htmlFor="description">What do you sell?</label>
          <textarea id="description" name="description" rows={3} className="field" placeholder="Tell customers what makes your products special." />
        </div>
        <Select label="Main category" name="primary_category" options={CATEGORY_ORDER.map((c) => [c, c])} required />
        <Select label="Business type" name="business_type" options={BUSINESS_TYPES} required error={err('business_type')} />
        <Input label="CIPC registration no. (optional)" name="registration_number" placeholder="2021/123456/07" />
        <Input label="VAT number (optional)" name="vat_number" />
        <Select label="B-BBEE level (optional)" name="bbbee_level" options={Array.from({ length: 8 }, (_, i) => [String(i + 1), `Level ${i + 1}`])} error={err('bbbee_level')} />
        <Input label="Year started" name="founded_year" type="number" min={1950} max={new Date().getFullYear()} error={err('founded_year')} />
      </Fieldset>

      <Fieldset title="2. Ownership & impact" hint="Helps customers who want to shop with impact find you. Tick all that apply.">
        <div className="grid gap-2 sm:col-span-2 sm:grid-cols-2">
          {[
            ['black_owned', '✊🏿 Black-owned (51%+)'],
            ['women_owned', '👩🏾‍💼 Women-owned (51%+)'],
            ['youth_owned', '⚡ Youth-owned (under 35)'],
            ['disability_owned', '♿ Owned by people with disabilities'],
            ['township_business', '🏘️ Township or rural business'],
            ['offers_collection', '📍 Customers can collect from me'],
          ].map(([name, label]) => (
            <label key={name} className="flex cursor-pointer items-center gap-3 rounded-2xl border-2 border-ink px-4 py-3 font-semibold has-[:checked]:bg-lime">
              <input type="checkbox" name={name} className="h-5 w-5 accent-ink" /> {label}
            </label>
          ))}
        </div>
      </Fieldset>

      <Fieldset title="3. Where are you?">
        <Select label="Province" name="province" options={PROVINCES.map((p) => [p.code, p.name])} required error={err('province')} />
        <Input label="City / town" name="city" required />
        <Input label="Township / suburb (optional)" name="township" span />
      </Fieldset>

      <Fieldset title="4. Contact">
        <Input label="Your name" name="contact_name" required />
        <Input label="Email" name="email" type="email" required error={err('email')} />
        <Input label="Mobile" name="phone" type="tel" required placeholder="082 123 4567" />
        <Input label="WhatsApp (if different)" name="whatsapp" type="tel" />
        <Input label="Instagram handle (optional)" name="instagram" placeholder="@yourbrand" />
        <Input label="Website (optional)" name="website" placeholder="www.yourbrand.co.za" />
      </Fieldset>

      <Fieldset title="5. Referral (optional)" hint="Signed up at a partner counter (e.g. Paxi or Pargo)? Enter the code you were given to get a reduced commission for your first months.">
        <Input label="Partner referral code" name="referral_code" placeholder="e.g. PAXI" error={err('referral_code')} />
      </Fieldset>

      <label className="flex items-start gap-3 text-sm">
        <input type="checkbox" name="consent" className="mt-1 h-5 w-5 accent-ink" required />
        <span>I agree to the EcloudMall seller terms and consent to EcloudMall processing my information under POPIA to assess my application.</span>
      </label>

      {state.error && <p className="rounded-2xl border-2 border-ink bg-flame px-4 py-3 font-bold text-white" role="alert">{state.error}</p>}
      <button disabled={pending} className="btn btn-primary w-full text-lg">{pending ? 'Sending…' : 'Submit application 🚀'}</button>
    </form>
  );
}

function Fieldset({ title, hint, children }: { title: string; hint?: string; children: React.ReactNode }) {
  return (
    <fieldset className="space-y-4">
      <legend className="font-display text-2xl font-extrabold">{title}</legend>
      {hint && <p className="-mt-2 text-sm text-ink/60">{hint}</p>}
      <div className="grid gap-4 sm:grid-cols-2">{children}</div>
    </fieldset>
  );
}

function Input({ label, name, span, error, ...props }: React.InputHTMLAttributes<HTMLInputElement> & { label: string; name: string; span?: boolean; error?: string }) {
  return (
    <div className={span ? 'sm:col-span-2' : ''}>
      <label className="label" htmlFor={name}>{label}</label>
      <input id={name} name={name} className="field" {...props} />
      {error && <p className="mt-1 text-sm font-bold text-flame">{error}</p>}
    </div>
  );
}

function Select({ label, name, options, required, error }: { label: string; name: string; options: string[][]; required?: boolean; error?: string }) {
  return (
    <div>
      <label className="label" htmlFor={name}>{label}</label>
      <select id={name} name={name} required={required} defaultValue="" className="field">
        <option value="">Select…</option>
        {options.map(([v, l]) => (
          <option key={v} value={v}>{l}</option>
        ))}
      </select>
      {error && <p className="mt-1 text-sm font-bold text-flame">{error}</p>}
    </div>
  );
}
