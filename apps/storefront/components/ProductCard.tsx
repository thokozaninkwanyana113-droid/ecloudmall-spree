import Link from 'next/link';
import type { MarketProduct } from '@/lib/spree';
import { rand, percentOff } from '@/lib/format';
import { ProductArt } from './ProductArt';
import { QuickAdd } from './QuickAdd';

export function ProductCard({ product, priority = false }: { product: MarketProduct; priority?: boolean }) {
  const off = percentOff(product.price?.amount, product.price?.compare_at_amount);
  const seller = product.seller;
  return (
    <article className="group card-pop relative flex flex-col overflow-hidden rounded-3xl bg-white">
      <Link href={`/products/${product.slug}`} className="relative block aspect-square overflow-hidden border-b-2 border-ink">
        {product.thumbnail_url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={product.thumbnail_url}
            alt={product.name}
            loading={priority ? 'eager' : 'lazy'}
            className="h-full w-full object-cover transition duration-500 group-hover:scale-105"
          />
        ) : (
          <ProductArt
            name={product.name}
            accent={seller?.brand_color}
            label={seller?.city ?? undefined}
            className="h-full w-full transition duration-500 group-hover:scale-105"
          />
        )}
        {off && (
          <span className="absolute left-3 top-3 rotate-[-6deg] rounded-full border-2 border-ink bg-flame px-3 py-1 text-xs font-black text-white">
            -{off}%
          </span>
        )}
        {!product.in_stock && (
          <span className="absolute inset-x-0 bottom-0 bg-ink/80 py-2 text-center text-xs font-bold uppercase tracking-widest text-white">
            Sold out
          </span>
        )}
      </Link>
      <div className="flex flex-1 flex-col gap-2 p-4">
        {seller && (
          <Link
            href={`/sellers/${seller.slug}`}
            className="flex items-center gap-1.5 text-xs font-semibold text-ink/60 hover:text-ink"
          >
            <span className="inline-block h-2.5 w-2.5 rounded-full border border-ink" style={{ background: seller.brand_color ?? '#FFB612' }} />
            {seller.name}
            {seller.verified && <span className="text-veld" title="Verified seller">✓</span>}
            <span className="ml-auto rounded-md bg-cream px-1.5 py-0.5 text-[10px] font-bold">{seller.province}</span>
          </Link>
        )}
        <Link href={`/products/${product.slug}`} className="font-display text-lg font-bold leading-tight hover:underline">
          {product.name}
        </Link>
        <div className="mt-auto flex items-end justify-between gap-2 pt-2">
          <div>
            <span className="font-display text-xl font-extrabold">{rand(product.price?.amount)}</span>
            {product.price?.compare_at_amount && off && (
              <span className="ml-2 text-sm text-ink/50 line-through">{rand(product.price.compare_at_amount)}</span>
            )}
          </div>
          {product.purchasable && product.in_stock && product.variant_count === 0 && (
            <QuickAdd variantId={product.default_variant_id} name={product.name} />
          )}
        </div>
      </div>
    </article>
  );
}
