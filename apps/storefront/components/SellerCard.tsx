import Link from 'next/link';
import type { Seller } from '@/lib/spree';
import { initials } from '@/lib/format';
import { Badges } from './Badges';

export function SellerLogo({ seller, size = 56 }: { seller: Pick<Seller, 'name' | 'logo_url' | 'brand_color'>; size?: number }) {
  if (seller.logo_url) {
    // eslint-disable-next-line @next/next/no-img-element
    return <img src={seller.logo_url} alt="" width={size} height={size} className="rounded-2xl border-2 border-ink object-cover" />;
  }
  return (
    <span
      className="grid shrink-0 place-items-center rounded-2xl border-2 border-ink font-display font-black text-white"
      style={{ width: size, height: size, background: seller.brand_color ?? '#0B0B0F', fontSize: size * 0.38 }}
    >
      {initials(seller.name)}
    </span>
  );
}

export function SellerCard({ seller }: { seller: Seller }) {
  return (
    <Link
      href={`/sellers/${seller.slug}`}
      className="card-pop group flex h-full flex-col overflow-hidden rounded-3xl bg-white"
    >
      <div
        className="ndebele-band h-20 border-b-2 border-ink"
        style={{ ['--band' as string]: seller.brand_color ?? '#FFB612' }}
      />
      <div className="-mt-8 flex flex-1 flex-col gap-3 p-5">
        <SellerLogo seller={seller} size={64} />
        <div>
          <h3 className="font-display text-xl font-extrabold leading-tight group-hover:underline">{seller.name}</h3>
          <p className="text-sm text-ink/60">📍 {seller.location}</p>
        </div>
        {seller.tagline && <p className="text-sm leading-snug">{seller.tagline}</p>}
        <div className="mt-auto flex flex-col gap-3 pt-2">
          <Badges badges={seller.badges.filter((b) => !b.startsWith('bbbee'))} max={3} />
          <p className="text-xs font-bold uppercase tracking-wider text-ink/50">
            {seller.products_count} products {seller.founded_year ? `· since ${seller.founded_year}` : ''}
          </p>
        </div>
      </div>
    </Link>
  );
}
