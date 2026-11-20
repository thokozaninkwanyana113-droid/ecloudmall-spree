import Link from 'next/link';
import { notFound } from 'next/navigation';
import type { Metadata } from 'next';
import { SpreeError } from '@spree/sdk';
import { spree, type MarketProduct } from '@/lib/spree';
import { listProducts } from '@/lib/catalog';
import { rand, percentOff, businessDaysFromNow } from '@/lib/format';
import { FREE_DELIVERY_THRESHOLD } from '@/lib/constants';
import { ProductArt } from '@/components/ProductArt';
import { ProductCard } from '@/components/ProductCard';
import { SellerLogo } from '@/components/SellerCard';
import { Badges } from '@/components/Badges';
import { AddToCart } from '@/components/AddToCart';

export const dynamic = 'force-dynamic';

type Params = Promise<{ slug: string }>;

async function getProduct(slug: string) {
  try {
    return (await spree.products.get(slug, { expand: ['media', 'variants', 'option_types', 'categories'] })) as MarketProduct;
  } catch (e) {
    if (e instanceof SpreeError && e.status === 404) return null;
    throw e;
  }
}

export async function generateMetadata({ params }: { params: Params }): Promise<Metadata> {
  const product = await getProduct((await params).slug);
  if (!product) return {};
  return {
    title: product.name,
    description: product.description ?? undefined,
  };
}

export default async function ProductPage({ params }: { params: Params }) {
  const product = await getProduct((await params).slug);
  if (!product) notFound();

  const seller = product.seller;
  const more = seller ? (await listProducts({ seller: seller.slug, limit: 5 })).data.filter((p) => p.id !== product.id).slice(0, 4) : [];
  const off = percentOff(product.price?.amount, product.price?.compare_at_amount);
  const images = (product.media ?? []).filter((m) => m.original_url || m.large_url);
  const price = Number(product.price?.amount ?? 0);
  const variants = (product.variants ?? []).map((v) => ({
    id: v.id,
    label: v.options_text || v.sku || 'Default',
    price: v.price?.display_amount ?? '',
    available: v.purchasable && v.in_stock,
  }));
  const dispatchDays = seller?.dispatch_days ?? 2;

  return (
    <div className="mx-auto max-w-7xl px-4 py-10">
      <nav className="mb-6 flex flex-wrap gap-2 text-sm font-semibold text-ink/60">
        <Link href="/shop" className="hover:underline">Shop</Link>
        {product.categories?.filter((c) => c.depth > 0).slice(-1).map((c) => (
          <span key={c.id}>/ <Link className="hover:underline" href={`/shop?category=${c.permalink.split('/').pop()}`}>{c.name}</Link></span>
        ))}
        <span>/ {product.name}</span>
      </nav>

      <div className="grid gap-10 lg:grid-cols-2">
        <div className="space-y-4">
          <div className="card-pop relative aspect-square overflow-hidden rounded-[2rem] bg-white">
            {images[0] ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={images[0].large_url ?? images[0].original_url ?? ''} alt={images[0].alt ?? product.name} className="h-full w-full object-cover" />
            ) : (
              <ProductArt name={product.name} accent={seller?.brand_color} label={seller?.name} className="h-full w-full" />
            )}
            {off && (
              <span className="absolute left-5 top-5 rotate-[-8deg] rounded-full border-2 border-ink bg-flame px-4 py-2 font-display text-lg font-black text-white">
                Save {off}%
              </span>
            )}
          </div>
          {images.length > 1 && (
            <div className="grid grid-cols-4 gap-3">
              {images.slice(1, 5).map((m) => (
                // eslint-disable-next-line @next/next/no-img-element
                <img key={m.id} src={m.small_url ?? m.original_url ?? ''} alt={m.alt ?? ''} className="aspect-square rounded-2xl border-2 border-ink object-cover" />
              ))}
            </div>
          )}
        </div>

        <div className="space-y-6">
          {seller && (
            <Link href={`/sellers/${seller.slug}`} className="inline-flex items-center gap-3 rounded-full border-2 border-ink bg-white py-1.5 pl-1.5 pr-4 font-bold hover:bg-lime">
              <SellerLogo seller={seller} size={36} />
              <span>
                {seller.name} {seller.verified && <span className="text-veld">✓</span>}
                <span className="block text-xs font-semibold text-ink/60">📍 {seller.location}</span>
              </span>
            </Link>
          )}
          <h1 className="font-display text-4xl font-extrabold leading-tight tracking-tight md:text-5xl">{product.name}</h1>
          <div className="flex items-baseline gap-3">
            <span className="font-display text-4xl font-extrabold">{rand(product.price?.amount)}</span>
            {off && <span className="text-xl text-ink/50 line-through">{rand(product.price?.compare_at_amount)}</span>}
            <span className="text-sm text-ink/60">incl. VAT</span>
          </div>

          {product.purchasable && (product.in_stock || product.backorderable) ? (
            <AddToCart defaultVariantId={product.default_variant_id} variants={variants.length > 0 ? variants : undefined} />
          ) : (
            <p className="rounded-2xl border-2 border-ink bg-cream p-4 font-bold">😢 Sold out — the maker is restocking. Check back soon.</p>
          )}

          <ul className="grid gap-3 sm:grid-cols-2">
            <li className="rounded-2xl border-2 border-ink bg-white p-4">
              <p className="text-xs font-black uppercase tracking-wider text-ink/50">Delivery</p>
              <p className="font-bold">🚚 Arrives by {businessDaysFromNow(dispatchDays + 3)}</p>
              <p className="text-sm text-ink/60">{price >= FREE_DELIVERY_THRESHOLD ? 'Free courier delivery' : `Free over ${rand(FREE_DELIVERY_THRESHOLD)} · or Paxi/Pargo from R59`}</p>
            </li>
            <li className="rounded-2xl border-2 border-ink bg-white p-4">
              <p className="text-xs font-black uppercase tracking-wider text-ink/50">Payment</p>
              <p className="font-bold">💳 Instant EFT or pay on delivery</p>
              <p className="text-sm text-ink/60">Secure checkout · 30-day returns</p>
            </li>
          </ul>

          {product.description_html && (
            <div className="prose max-w-none rounded-2xl border-2 border-ink bg-white p-5 text-ink/80" dangerouslySetInnerHTML={{ __html: product.description_html }} />
          )}

          {seller && seller.badges.length > 0 && (
            <div className="space-y-2">
              <p className="text-xs font-black uppercase tracking-wider text-ink/50">Your purchase supports</p>
              <Badges badges={seller.badges} size="md" />
            </div>
          )}
        </div>
      </div>

      {more.length > 0 && seller && (
        <section className="mt-20">
          <div className="flex items-end justify-between">
            <h2 className="font-display text-3xl font-extrabold">More from {seller.name}</h2>
            <Link href={`/sellers/${seller.slug}`} className="font-bold underline">Visit shop →</Link>
          </div>
          <div className="mt-6 grid grid-cols-2 gap-4 md:gap-6 lg:grid-cols-4">
            {more.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
