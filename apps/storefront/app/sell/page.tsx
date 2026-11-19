import type { Metadata } from 'next';
import { COMMISSION_RATE } from '@/lib/constants';
import { SellForm } from '@/components/SellForm';

export const metadata: Metadata = {
  title: 'Sell on EcloudMall',
  description: 'Reach customers in all 9 provinces. No listing fees, no monthly subscription — just a small commission when you sell.',
};

const STEPS = [
  { emoji: '📝', title: 'Apply in 5 minutes', body: 'Tell us about your business. CIPC registration helps but informal businesses are welcome too.' },
  { emoji: '🤝', title: 'Get approved in 48h', body: 'A real person reviews every application and helps you set up your shop.' },
  { emoji: '📸', title: 'List your products', body: 'Upload photos from your phone. We help with pricing, descriptions and SEO.' },
  { emoji: '💸', title: 'Sell & get paid weekly', body: 'We handle payments and courier collection. Payouts land in your bank every Friday.' },
];

export default function SellPage() {
  return (
    <>
      <section className="grain border-b-2 border-ink">
        <div className="mx-auto grid max-w-7xl gap-12 px-4 py-16 lg:grid-cols-2 lg:items-center">
          <div className="space-y-6">
            <p className="inline-block rounded-full border-2 border-ink bg-lime px-4 py-1 text-sm font-black uppercase tracking-wider">For SMMEs, by SMMEs</p>
            <h1 className="font-display text-5xl font-extrabold leading-[0.95] tracking-tight md:text-7xl">
              Your hustle, <span className="text-veld">nationwide.</span>
            </h1>
            <p className="max-w-xl text-xl text-ink/75">
              Sell to customers in all 9 provinces without building a website, chasing payments or negotiating with couriers. You make it — we help you move it.
            </p>
            <div className="flex flex-wrap gap-3">
              <a href="#apply" className="btn btn-dark text-lg">Apply now →</a>
              <a href="#pricing" className="btn btn-light text-lg">See fees</a>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            {[
              ['0', 'Listing fees', 'bg-sun'],
              [`${COMMISSION_RATE}%`, 'Only when you sell', 'bg-pink'],
              ['48h', 'Application review', 'bg-lime'],
              ['Weekly', 'Payouts every Friday', 'bg-white'],
            ].map(([big, small, bg]) => (
              <div key={small} className={`card-pop rounded-3xl p-6 ${bg}`}>
                <p className="font-display text-5xl font-extrabold">{big}</p>
                <p className="mt-1 font-bold">{small}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-4 py-16">
        <h2 className="font-display text-4xl font-extrabold md:text-5xl">How it works</h2>
        <div className="mt-8 grid gap-6 md:grid-cols-4">
          {STEPS.map((s, i) => (
            <div key={s.title} className="card-pop rounded-3xl bg-white p-6">
              <p className="text-4xl">{s.emoji}</p>
              <p className="mt-4 text-xs font-black uppercase tracking-wider text-flame">Step {i + 1}</p>
              <h3 className="font-display text-xl font-extrabold">{s.title}</h3>
              <p className="mt-2 text-sm text-ink/70">{s.body}</p>
            </div>
          ))}
        </div>
      </section>

      <section id="pricing" className="border-y-2 border-ink bg-ink py-16 text-white">
        <div className="mx-auto grid max-w-7xl gap-10 px-4 md:grid-cols-2">
          <div>
            <p className="text-sm font-black uppercase tracking-[0.2em] text-sun">Simple, fair pricing</p>
            <h2 className="mt-2 font-display text-4xl font-extrabold md:text-5xl">You only pay when you get paid.</h2>
            <p className="mt-4 text-lg text-white/75">
              One flat {COMMISSION_RATE}% commission on each sale (excl. delivery). It covers payment processing, fraud protection, marketing and seller support.
            </p>
          </div>
          <div className="rounded-3xl border-2 border-white bg-white p-6 text-ink">
            <p className="font-display text-xl font-extrabold">Example: you sell a R500 item</p>
            <dl className="mt-4 space-y-2">
              <div className="flex justify-between"><dt>Customer pays</dt><dd className="font-bold">R500.00</dd></div>
              <div className="flex justify-between text-flame"><dt>EcloudMall commission ({COMMISSION_RATE}%)</dt><dd className="font-bold">−R{(500 * COMMISSION_RATE / 100).toFixed(2)}</dd></div>
              <div className="flex justify-between border-t-2 border-dashed border-ink pt-2 font-display text-2xl font-extrabold"><dt>You receive</dt><dd className="text-veld">R{(500 - 500 * COMMISSION_RATE / 100).toFixed(2)}</dd></div>
            </dl>
            <p className="mt-4 text-xs text-ink/60">No setup, listing or monthly fees. VAT-registered sellers receive a monthly tax invoice for commission.</p>
          </div>
        </div>
      </section>

      <section id="apply" className="mx-auto max-w-4xl scroll-mt-32 px-4 py-16">
        <h2 className="font-display text-4xl font-extrabold md:text-5xl">Apply to sell</h2>
        <p className="mt-2 text-lg text-ink/70">Takes about 5 minutes. We’ll get back to you within 2 working days.</p>
        <div className="mt-8">
          <SellForm />
        </div>
      </section>
    </>
  );
}
