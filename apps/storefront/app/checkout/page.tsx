import Link from 'next/link';
import { redirect } from 'next/navigation';
import type { Metadata } from 'next';
import { spree } from '@/lib/spree';
import { getCart, getCustomer } from '@/lib/session';
import { rand } from '@/lib/format';
import { AddressForm } from '@/components/checkout/AddressForm';
import { DeliveryOptions } from '@/components/checkout/DeliveryOptions';
import { PaymentForm } from '@/components/checkout/PaymentForm';
import { ProductArt } from '@/components/ProductArt';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'Checkout' };

export default async function CheckoutPage({ searchParams }: { searchParams: Promise<{ edit?: string }> }) {
  const [cart, customer, { edit }] = await Promise.all([getCart(), getCustomer(), searchParams]);
  if (!cart || cart.items.length === 0) redirect('/cart');

  const za = await spree.countries.get('ZA', { expand: ['states'] });
  const states = (za as unknown as { states?: { abbr: string; name: string }[] }).states ?? [];
  const address = cart.shipping_address ?? customer?.default_shipping_address ?? null;
  const hasAddress = Boolean(cart.shipping_address && cart.email) && edit !== 'address';
  const rateSelected = cart.fulfillments.length > 0 && cart.fulfillments.every((f) => f.delivery_rates.some((r) => r.selected));

  return (
    <div className="mx-auto max-w-7xl px-4 py-10">
      <h1 className="font-display text-5xl font-extrabold tracking-tight">Checkout</h1>
      <ol className="mt-4 flex flex-wrap gap-2 text-sm font-bold">
        {['Details', 'Delivery', 'Payment'].map((s, i) => {
          const done = [hasAddress, hasAddress && rateSelected, false][i];
          const active = [!hasAddress, hasAddress && !rateSelected, hasAddress && rateSelected][i];
          return (
            <li key={s} className={`chip ${active ? 'chip-active' : done ? 'bg-lime' : ''}`}>
              {done ? '✓' : i + 1}. {s}
            </li>
          );
        })}
      </ol>

      <div className="mt-8 grid gap-8 lg:grid-cols-[1fr_400px]">
        <div className="space-y-6">
          <Step n={1} title="Your details & delivery address">
            {hasAddress ? (
              <div className="flex flex-wrap items-start justify-between gap-4">
                <div className="text-sm leading-relaxed">
                  <p className="font-bold">{cart.shipping_address!.first_name} {cart.shipping_address!.last_name}</p>
                  <p>{cart.email} · {cart.shipping_address!.phone}</p>
                  <p>{cart.shipping_address!.address1}{cart.shipping_address!.address2 ? `, ${cart.shipping_address!.address2}` : ''}</p>
                  <p>{cart.shipping_address!.city}, {cart.shipping_address!.state_name ?? cart.shipping_address!.state_abbr} {cart.shipping_address!.postal_code}</p>
                </div>
                <Link href="/checkout?edit=address" className="chip">Edit</Link>
              </div>
            ) : (
              <AddressForm
                states={states}
                defaults={{
                  email: cart.email ?? customer?.email ?? '',
                  first_name: address?.first_name ?? customer?.first_name ?? '',
                  last_name: address?.last_name ?? customer?.last_name ?? '',
                  phone: address?.phone ?? customer?.phone ?? '',
                  address1: address?.address1 ?? '',
                  address2: address?.address2 ?? '',
                  city: address?.city ?? '',
                  postal_code: address?.postal_code ?? '',
                  state_abbr: address?.state_abbr ?? '',
                }}
                loggedIn={Boolean(customer)}
              />
            )}
          </Step>

          <Step n={2} title="Delivery" disabled={!hasAddress}>
            {hasAddress && <DeliveryOptions fulfillments={cart.fulfillments} />}
          </Step>

          <Step n={3} title="Payment" disabled={!hasAddress || !rateSelected}>
            {hasAddress && rateSelected && (
              <PaymentForm methods={cart.payment_methods.filter((m) => !m.session_required)} total={rand(cart.total, { cents: true })} />
            )}
          </Step>
        </div>

        <aside className="h-fit lg:sticky lg:top-36">
          <div className="card-pop space-y-4 rounded-3xl bg-white p-6">
            <h2 className="font-display text-2xl font-extrabold">Order summary</h2>
            <ul className="space-y-3">
              {cart.items.map((i) => (
                <li key={i.id} className="flex items-center gap-3">
                  <span className="relative h-14 w-14 shrink-0 overflow-hidden rounded-xl border-2 border-ink">
                    {i.thumbnail_url ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={i.thumbnail_url} alt="" className="h-full w-full object-cover" />
                    ) : (
                      <ProductArt name={i.name} className="h-full w-full" />
                    )}
                  </span>
                  <span className="flex-1 text-sm font-semibold leading-tight">{i.name} <span className="text-ink/50">× {i.quantity}</span></span>
                  <span className="text-sm font-bold">{rand(i.total)}</span>
                </li>
              ))}
            </ul>
            <div className="space-y-2 border-t-2 border-dashed border-ink pt-4 text-sm">
              <div className="flex justify-between"><span>Subtotal</span><span className="font-bold">{rand(cart.item_total)}</span></div>
              {Number(cart.discount_total) !== 0 && <div className="flex justify-between text-veld"><span>Discounts</span><span className="font-bold">{rand(cart.discount_total)}</span></div>}
              <div className="flex justify-between"><span>Delivery</span><span className="font-bold">{rateSelected ? (Number(cart.delivery_total) === 0 ? 'FREE' : rand(cart.delivery_total)) : '—'}</span></div>
              <div className="flex justify-between font-display text-2xl font-extrabold"><span>Total</span><span>{rand(cart.total)}</span></div>
              <p className="text-xs text-ink/60">Includes {rand(cart.included_tax_total)} VAT (15%)</p>
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
}

function Step({ n, title, disabled, children }: { n: number; title: string; disabled?: boolean; children: React.ReactNode }) {
  return (
    <section className={`rounded-3xl border-2 border-ink bg-white p-6 ${disabled ? 'opacity-50' : 'shadow-[5px_5px_0_#0b0b0f]'}`}>
      <h2 className="mb-5 flex items-center gap-3 font-display text-2xl font-extrabold">
        <span className="grid h-9 w-9 place-items-center rounded-full border-2 border-ink bg-sun text-base">{n}</span>
        {title}
      </h2>
      {children}
    </section>
  );
}
