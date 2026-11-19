import Link from 'next/link';
import { notFound } from 'next/navigation';
import type { Metadata } from 'next';
import { marketplace, ApiError } from '@/lib/spree';
import { listProducts } from '@/lib/catalog';
import { ProductCard } from '@/components/ProductCard';
import { SellerLogo } from '@/components/SellerCard';
import { Badges } from '@/components/Badges';

export const dynamic = 'force-dynamic';

type Params = Promise<{ slug: string }>;

async function getSeller(slug: string) {
  try {
    return await marketplace.sellers.get(slug);
  } catch (e) {
    if (e instanceof ApiError && e.status === 404) return null;
    throw e;
  }
}

export async function generateMetadata({ params }: { params: Params }): Promise<Metadata> {
  const seller = await getSeller((await params).slug);
  return seller ? { title: `${seller.name} — ${seller.tagline ?? 'Shop on EcloudMall'}`, description: seller.description ?? undefined } : {};
}

export default async function SellerPage({ params, searchParams }: { params: Params; searchParams: Promise<{ sort?: string }> }) {
  const seller = await getSeller((await params).slug);
  if (!seller) notFound();
  const { sort } = await searchParams;
  const products = await listProducts({ seller: seller.slug, limit: 48, sort });
  const color = seller.brand_color ?? '#FFB612';
  const socials = [
    seller.instagram && { label: 'Instagram', href: `https://instagram.com/${seller.instagram.replace('@', '')}` },
    seller.tiktok && { label: 'TikTok', href: `https://tiktok.com/@${seller.tiktok.replace('@', '')}` },
    seller.facebook && { label: 'Facebook', href: seller.facebook.startsWith('http') ? seller.facebook : `https://facebook.com/${seller.facebook}` },
    seller.website && { label: 'Website', href: seller.website.startsWith('http') ? seller.website : `https://${seller.website}` },
  ].filter(Boolean) as { label: string; href: string }[];

  return (
    <div>
      <section className="border-b-2 border-ink" style={{ background: color }}>
        {seller.banner_url ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={seller.banner_url} alt="" className="h-56 w-full border-b-2 border-ink object-cover md:h-72" />
        ) : (
          <div className="ndebele-band h-40 border-b-2 border-ink md:h-56" style={{ ['--band' as string]: color }} />
        )}
        <div className="mx-auto max-w-7xl px-4 pb-10">
          <div className="-mt-12 flex flex-col gap-4 sm:flex-row sm:items-end sm:gap-6">
            <SellerLogo seller={seller} size={112} />
            <div className="w-full flex-1 rounded-3xl border-2 border-ink bg-white p-5 shadow-[5px_5px_0_#0b0b0f]">
              <div className="flex flex-wrap items-center gap-3">
                <h1 className="font-display text-3xl font-extrabold tracking-tight sm:text-4xl md:text-5xl">{seller.name}</h1>
                {seller.verified && <span className="rounded-full border-2 border-ink bg-veld px-3 py-1 text-xs font-black text-white">✓ VERIFIED</span>}
              </div>
              {seller.tagline && <p className="mt-1 text-lg text-ink/75">{seller.tagline}</p>}
              <p className="mt-2 text-sm font-semibold text-ink/60">
                📍 {seller.location}
                {seller.founded_year && ` · Est. ${seller.founded_year}`}
                {seller.team_size && ` · Team of ${seller.team_size}`}
                {` · Ships in ${seller.dispatch_days ?? 2} days`}
              </p>
            </div>
          </div>
        </div>
      </section>

      <div className="mx-auto grid max-w-7xl gap-10 px-4 py-12 lg:grid-cols-[320px_1fr]">
        <aside className="space-y-6">
          {(seller.story || seller.description) && (
            <div className="card-pop rounded-3xl bg-white p-6">
              <p className="text-xs font-black uppercase tracking-[0.2em] text-flame">Our story</p>
              {seller.story_headline && <h2 className="mt-2 font-display text-2xl font-extrabold leading-tight">{seller.story_headline}</h2>}
              <p className="mt-3 text-ink/75">{seller.story ?? seller.description}</p>
              {seller.story && seller.description && <p className="mt-3 text-sm text-ink/60">{seller.description}</p>}
            </div>
          )}
          <div className="card-pop space-y-4 rounded-3xl bg-white p-6">
            <p className="text-xs font-black uppercase tracking-[0.2em] text-ink/50">Business profile</p>
            <Badges badges={seller.badges} size="md" />
            <dl className="grid grid-cols-2 gap-2 text-sm">
              {seller.business_type_name && (<><dt className="text-ink/60">Entity</dt><dd className="font-semibold">{seller.business_type_name}</dd></>)}
              {seller.primary_category && (<><dt className="text-ink/60">Category</dt><dd className="font-semibold">{seller.primary_category}</dd></>)}
              <dt className="text-ink/60">Delivery</dt>
              <dd className="font-semibold">{seller.ships_nationwide ? 'Nationwide' : 'Local only'}{seller.offers_collection ? ' + collection' : ''}</dd>
            </dl>
            {socials.length > 0 && (
              <div className="flex flex-wrap gap-2">
                {socials.map((s) => (
                  <a key={s.label} href={s.href} target="_blank" rel="noopener noreferrer" className="chip">{s.label} ↗</a>
                ))}
              </div>
            )}
          </div>
        </aside>
        <section>
          <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
            <h2 className="font-display text-3xl font-extrabold">Shop {seller.name} <span className="text-ink/40">({products.meta.count})</span></h2>
            <div className="flex gap-2">
              {[
                ['', 'Featured'],
                ['price', 'Lowest price'],
                ['-price', 'Highest price'],
              ].map(([v, l]) => (
                <Link key={v} href={v ? `?sort=${v}` : '?'} className={`chip ${(sort ?? '') === v ? 'chip-active' : ''}`}>{l}</Link>
              ))}
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4 md:gap-6 xl:grid-cols-3">
            {products.data.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}
