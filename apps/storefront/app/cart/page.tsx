import Link from 'next/link';
import type { Metadata } from 'next';
import { getCart } from '@/lib/session';
import { rand } from '@/lib/format';
import { FREE_DELIVERY_THRESHOLD } from '@/lib/constants';
import { updateItem, removeItem } from '@/app/actions';
import { ProductArt } from '@/components/ProductArt';
import { CouponForm } from '@/components/CouponForm';

export const dynamic = 'force-dynamic';
export const metadata: Metadata = { title: 'Your cart' };

export default async function CartPage() {
  const cart = await getCart();
  const items = cart?.items ?? [];

  if (!cart || items.length === 0) {
    return (
      <div className="mx-auto max-w-2xl px-4 py-24 text-center">
        <p className="text-7xl">🛍️</p>
        <h1 className="mt-6 font-display text-5xl font-extrabold">Your cart is empty</h1>
        <p className="mt-3 text-lg text-ink/70">Thousands of local makers are waiting to meet you.</p>
        <Link href="/shop" className="btn btn-primary mt-8 text-lg">Start shopping →</Link>
      </div>
    );
  }

  const itemTotal = Number(cart.item_total);
  const toFree = Math.max(0, FREE_DELIVERY_THRESHOLD - itemTotal);
  const progress = Math.min(100, (itemTotal / FREE_DELIVERY_THRESHOLD) * 100);

  return (
    <div className="mx-auto max-w-7xl px-4 py-10">
      <h1 className="font-display text-5xl font-extrabold tracking-tight">Your cart <span className="text-ink/40">({cart.total_quantity})</span></h1>
      <div className="mt-8 grid gap-8 lg:grid-cols-[1fr_380px]">
        <div className="space-y-4">
          <div className="rounded-3xl border-2 border-ink bg-white p-5">
            <p className="font-bold">{toFree > 0 ? <>You’re <span className="text-veld">{rand(toFree)}</span> away from free courier delivery 🚚</> : <>🎉 You’ve unlocked free courier delivery!</>}</p>
            <div className="mt-3 h-4 overflow-hidden rounded-full border-2 border-ink bg-cream">
              <div className="h-full bg-veld transition-all" style={{ width: `${progress}%` }} />
            </div>
          </div>
          {items.map((item) => (
            <div key={item.id} className="card-pop flex gap-4 rounded-3xl bg-white p-4">
              <Link href={`/products/${item.slug}`} className="h-28 w-28 shrink-0 overflow-hidden rounded-2xl border-2 border-ink">
                {item.thumbnail_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={item.thumbnail_url} alt="" className="h-full w-full object-cover" />
                ) : (
                  <ProductArt name={item.name} className="h-full w-full" />
                )}
              </Link>
              <div className="flex flex-1 flex-col gap-2">
                <div className="flex justify-between gap-3">
                  <div>
                    <Link href={`/products/${item.slug}`} className="font-display text-lg font-bold hover:underline">{item.name}</Link>
                    {item.options_text && <p className="text-sm text-ink/60">{item.options_text}</p>}
                  </div>
                  <p className="font-display text-lg font-extrabold">{rand(item.total)}</p>
                </div>
                <div className="mt-auto flex items-center gap-3">
                  <form action={updateItem} className="flex items-center rounded-full border-2 border-ink">
                    <input type="hidden" name="item_id" value={item.id} />
                    <button name="quantity" value={item.quantity - 1} className="h-9 w-9 font-black" aria-label="Decrease">−</button>
                    <span className="w-8 text-center font-bold">{item.quantity}</span>
                    <button name="quantity" value={item.quantity + 1} className="h-9 w-9 font-black" aria-label="Increase">+</button>
                  </form>
                  <span className="text-sm text-ink/60">{rand(item.price)} each</span>
                  <form action={removeItem} className="ml-auto">
                    <input type="hidden" name="item_id" value={item.id} />
                    <button className="text-sm font-bold text-flame underline">Remove</button>
                  </form>
                </div>
              </div>
            </div>
          ))}
        </div>
        <aside className="h-fit space-y-4 lg:sticky lg:top-36">
          <div className="card-pop space-y-3 rounded-3xl bg-white p-6">
            <h2 className="font-display text-2xl font-extrabold">Summary</h2>
            <Row label="Subtotal" value={rand(cart.item_total)} />
            {Number(cart.discount_total) !== 0 && <Row label="Discounts" value={rand(cart.discount_total)} accent />}
            <Row label="Delivery" value="Calculated at checkout" muted />
            <div className="border-t-2 border-dashed border-ink pt-3">
              <Row label="Total" value={rand(cart.total)} big />
              <p className="text-xs text-ink/60">Includes {rand(cart.included_tax_total)} VAT</p>
            </div>
            <Link href="/checkout" className="btn btn-dark w-full text-lg">Checkout securely →</Link>
            <p className="text-center text-xs text-ink/60">🔒 Instant EFT · Pay on delivery</p>
          </div>
          <CouponForm />
        </aside>
      </div>
    </div>
  );
}

function Row({ label, value, big, muted, accent }: { label: string; value: string; big?: boolean; muted?: boolean; accent?: boolean }) {
  return (
    <div className={`flex justify-between ${big ? 'font-display text-2xl font-extrabold' : ''}`}>
      <span className={muted ? 'text-ink/60' : ''}>{label}</span>
      <span className={`${muted ? 'text-sm text-ink/60' : 'font-bold'} ${accent ? 'text-veld' : ''}`}>{value}</span>
    </div>
  );
}
