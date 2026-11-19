import Link from 'next/link';
import { notFound } from 'next/navigation';
import type { Metadata } from 'next';
import { spree } from '@/lib/spree';
import { orderToken, getAuthToken } from '@/lib/session';
import { rand } from '@/lib/format';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'Order confirmation' };

export default async function OrderPage({ params, searchParams }: { params: Promise<{ id: string }>; searchParams: Promise<{ placed?: string }> }) {
  const { id } = await params;
  const { placed } = await searchParams;
  const [token, auth] = await Promise.all([orderToken(id), getAuthToken()]);
  let order;
  try {
    order = await spree.orders.get(id, undefined, { ...(token ? { spreeToken: token } : {}), ...(auth ? { token: auth } : {}) });
  } catch {
    notFound();
  }
  const eft = order.payments.some((p) => p.payment_method?.type?.endsWith('Check') && p.payment_method?.name?.includes('EFT'));
  const paidOnline = order.payments.find((p) => p.payment_method?.session_required && p.status === 'completed');
  const pickup = (order.fulfillments[0] as unknown as { pickup_point?: { name: string; address: { street?: string; city?: string }; opening_hours?: string } | null })?.pickup_point;

  return (
    <div className="mx-auto max-w-3xl px-4 py-14">
      {placed && (
        <div className="mb-10 text-center">
          <p className="text-7xl">🎉</p>
          <h1 className="mt-4 font-display text-5xl font-extrabold tracking-tight">Ngiyabonga! Order placed.</h1>
          <p className="mt-3 text-lg text-ink/70">We’ve emailed your confirmation to <strong>{order.email}</strong>. You just backed {new Set(order.items.map((i) => i.slug)).size > 1 ? 'some amazing' : 'an amazing'} local business{order.items.length > 1 ? 'es' : ''}.</p>
        </div>
      )}
      <div className="card-pop space-y-6 rounded-3xl bg-white p-6 md:p-8">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <p className="text-xs font-black uppercase tracking-[0.2em] text-ink/50">Order</p>
            <p className="font-display text-3xl font-extrabold">#{order.number}</p>
          </div>
          <span className="chip bg-sun">{order.payment_status === 'paid' ? `✓ Paid${paidOnline ? ` via ${paidOnline.payment_method.name.split(' — ')[0]}` : ''}` : eft ? '⏳ Awaiting EFT' : '💵 Pay on delivery'}</span>
        </div>
        {eft && order.payment_status !== 'paid' && (
          <div className="rounded-2xl border-2 border-ink bg-cream p-4 text-sm">
            <p className="font-bold">Complete your EFT payment</p>
            <p className="mt-1">Use reference <strong className="font-mono">{order.number}</strong> and pay <strong>{rand(order.total, { cents: true })}</strong> into the EcloudMall trust account. Your order is dispatched as soon as payment reflects.</p>
          </div>
        )}
        <ul className="divide-y-2 divide-dashed divide-ink/20">
          {order.items.map((i) => (
            <li key={i.id} className="flex justify-between py-3">
              <span><Link href={`/products/${i.slug}`} className="font-semibold hover:underline">{i.name}</Link> <span className="text-ink/50">× {i.quantity}</span></span>
              <span className="font-bold">{rand(i.total)}</span>
            </li>
          ))}
        </ul>
        <div className="space-y-1 border-t-2 border-ink pt-4 text-sm">
          <div className="flex justify-between"><span>Subtotal</span><span>{rand(order.item_total)}</span></div>
          <div className="flex justify-between"><span>Delivery</span><span>{Number(order.delivery_total) === 0 ? 'FREE' : rand(order.delivery_total)}</span></div>
          {Number(order.discount_total) !== 0 && <div className="flex justify-between text-veld"><span>Discounts</span><span>{rand(order.discount_total)}</span></div>}
          <div className="flex justify-between font-display text-2xl font-extrabold"><span>Total</span><span>{rand(order.total)}</span></div>
          <p className="text-xs text-ink/60">Includes {rand(order.included_tax_total)} VAT</p>
        </div>
        {order.shipping_address && (
          <div className="text-sm">
            <p className="font-bold">Delivering to</p>
            <p>{order.shipping_address.first_name} {order.shipping_address.last_name}, {order.shipping_address.address1}, {order.shipping_address.city} {order.shipping_address.postal_code}</p>
            {order.fulfillments[0]?.delivery_method && <p className="text-ink/60">via {order.fulfillments[0].delivery_method.name}</p>}
            {pickup && (
              <p className="mt-2 rounded-xl border-2 border-ink bg-cream p-3">
                📍 <strong>Collect at {pickup.name}</strong><br />
                {[pickup.address.street, pickup.address.city].filter(Boolean).join(', ')}{pickup.opening_hours ? ` · ${pickup.opening_hours}` : ''}<br />
                <span className="text-xs text-ink/60">We’ll SMS you a collection code when your parcel arrives.</span>
              </p>
            )}
          </div>
        )}
      </div>
      <div className="mt-8 flex justify-center gap-3">
        <Link href="/shop" className="btn btn-dark">Keep shopping</Link>
        <Link href="/sellers" className="btn btn-light">Meet more makers</Link>
      </div>
    </div>
  );
}
