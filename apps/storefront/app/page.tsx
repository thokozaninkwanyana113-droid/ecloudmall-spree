import Link from 'next/link';
import { listProducts, getCategories } from '@/lib/catalog';
import { marketplace } from '@/lib/spree';
import { PROVINCES, IMPACT_FILTERS, CATEGORY_EMOJI, COMMISSION_RATE } from '@/lib/constants';
import { ProductCard } from '@/components/ProductCard';
import { SellerCard, SellerLogo } from '@/components/SellerCard';
import { ProductArt } from '@/components/ProductArt';
import { Marquee } from '@/components/Marquee';

export const dynamic = 'force-dynamic';

export default async function HomePage() {
  const [trending, deals, featured, allVendors, categories] = await Promise.all([
    listProducts({ limit: 8, sort: '-available_on' }),
    listProducts({ limit: 4, category: 'tech-and-load-shedding' }),
    marketplace.sellers.list({ featured: true, limit: 4 }),
    marketplace.sellers.list({ limit: 100 }),
    getCategories(),
  ]);

  const sellersByProvince = new Map<string, number>();
  for (const v of allVendors.data) {
    if (v.province) sellersByProvince.set(v.province, (sellersByProvince.get(v.province) ?? 0) + 1);
  }
  const spotlight = featured.data[0];
  const heroProducts = trending.data.slice(0, 3);

  return (
    <>
      {/* ------------------------------------------------ HERO */}
      <section className="grain relative overflow-hidden border-b-2 border-ink">
        <div className="mx-auto grid max-w-7xl items-center gap-12 px-4 py-14 md:py-20 lg:grid-cols-[1.15fr_1fr]">
          <div className="relative z-10 space-y-7">
            <p className="inline-flex items-center gap-2 rounded-full border-2 border-ink bg-white px-4 py-1.5 text-sm font-bold">
              <span className="h-2.5 w-2.5 animate-pulse rounded-full bg-veld" /> {allVendors.meta.count} local businesses · {trending.meta.count} products live
            </p>
            <h1 className="font-display text-5xl font-extrabold leading-[0.95] tracking-tight sm:text-6xl lg:text-7xl">
              Shop <span className="relative inline-block -rotate-2 rounded-2xl border-2 border-ink bg-sun px-3 shadow-[5px_5px_0_#0b0b0f]">local.</span>
              <br />
              Grow <span className="text-veld">Mzansi.</span>
            </h1>
            <p className="max-w-xl text-lg text-ink/75 md:text-xl">
              EcloudMall is where South Africa’s small businesses meet the whole country. Township makers, Black- and women-owned
              brands and family recipes from all <strong>9 provinces</strong> — delivered to your door.
            </p>
            <div className="flex flex-wrap gap-3">
              <Link href="/shop" className="btn btn-dark text-lg">Start shopping →</Link>
              <Link href="/sell" className="btn btn-primary text-lg">Sell on EcloudMall</Link>
            </div>
            <div className="flex flex-wrap gap-2 pt-2">
              {IMPACT_FILTERS.map((f) => (
                <Link key={f.key} href={`/shop?impact=${f.key}`} className="chip">
                  {f.emoji} {f.label}
                </Link>
              ))}
            </div>
          </div>
          <div className="relative mx-auto h-[420px] w-full max-w-md md:h-[480px]">
            {heroProducts.map((p, i) => (
              <Link
                key={p.id}
                href={`/products/${p.slug}`}
                className={`card-pop absolute block w-56 overflow-hidden rounded-3xl bg-white md:w-64 ${
                  ['left-0 top-6 [--r:-8deg]', 'right-0 top-0 [--r:6deg]', 'left-16 bottom-0 [--r:-2deg]'][i]
                } animate-float`}
                style={{ animationDelay: `${i * 0.8}s`, zIndex: 3 - i }}
              >
                <div className="aspect-square border-b-2 border-ink">
                  {p.thumbnail_url ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={p.thumbnail_url} alt={p.name} className="h-full w-full object-cover" />
                  ) : (
                    <ProductArt name={p.name} accent={p.seller?.brand_color} className="h-full w-full" />
                  )}
                </div>
                <div className="flex items-center justify-between gap-2 px-4 py-3">
                  <span className="truncate text-sm font-bold">{p.name}</span>
                  <span className="shrink-0 rounded-full bg-lime px-2 py-0.5 text-sm font-black">{p.price?.display_amount?.replace('.00', '')}</span>
                </div>
              </Link>
            ))}
            <span className="absolute -right-2 bottom-16 z-10 grid h-28 w-28 animate-wiggle place-items-center rounded-full border-2 border-ink bg-pink text-center font-display text-sm font-extrabold leading-tight">
              100%<br />Proudly<br />SA 🇿🇦
            </span>
          </div>
        </div>
      </section>

      {/* ------------------------------------------------ CATEGORIES */}
      <section className="mx-auto max-w-7xl px-4 pt-16">
        <SectionTitle eyebrow="Browse" title="What are you looking for?" />
        <div className="mt-8 grid grid-cols-2 gap-4 sm:grid-cols-4 lg:grid-cols-7">
          {categories.map((c, i) => (
            <Link
              key={c.id}
              href={`/shop?category=${c.slug}`}
              className={`card-pop flex flex-col items-center gap-3 rounded-3xl p-5 text-center ${
                ['bg-sun', 'bg-pink', 'bg-lime', 'bg-white', 'bg-[#8ecae6]', 'bg-[#ffd6a5]', 'bg-[#cdb4db]'][i % 7]
              }`}
            >
              <span className="text-4xl">{CATEGORY_EMOJI[c.name] ?? '🛍️'}</span>
              <span className="font-display text-sm font-extrabold leading-tight">{c.name}</span>
            </Link>
          ))}
        </div>
      </section>

      {/* ------------------------------------------------ TRENDING */}
      <section className="mx-auto max-w-7xl px-4 pt-20">
        <div className="flex items-end justify-between gap-4">
          <SectionTitle eyebrow="Fresh drops" title="Trending in Mzansi" />
          <Link href="/shop" className="hidden font-bold underline decoration-2 underline-offset-4 sm:block">See all →</Link>
        </div>
        <div className="mt-8 grid grid-cols-2 gap-4 md:gap-6 lg:grid-cols-4">
          {trending.data.map((p, i) => (
            <ProductCard key={p.id} product={p} priority={i < 4} />
          ))}
        </div>
      </section>

      {/* ------------------------------------------------ PROVINCES */}
      <section className="mt-24 border-y-2 border-ink bg-ink py-16 text-white">
        <div className="mx-auto max-w-7xl px-4">
          <SectionTitle eyebrow="Nine provinces, one marketplace" title="Shop by province" light />
          <div className="mt-10 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-9">
            {PROVINCES.map((p) => {
              const count = sellersByProvince.get(p.code) ?? 0;
              return (
                <Link
                  key={p.code}
                  href={`/shop?province=${p.code}`}
                  className="group relative flex aspect-[3/4] flex-col justify-between overflow-hidden rounded-3xl border-2 border-white/80 p-4 transition hover:-translate-y-1"
                  style={{ background: p.color }}
                >
                  <span className="font-display text-4xl font-extrabold text-ink/90">{p.code}</span>
                  <span>
                    <span className="block font-display text-base font-extrabold leading-tight text-ink">{p.name}</span>
                    <span className="block text-[11px] font-semibold text-ink/70">{p.nickname}</span>
                    <span className="mt-2 inline-block rounded-full bg-ink px-2 py-0.5 text-[10px] font-bold text-white">
                      {count} {count === 1 ? 'seller' : 'sellers'}
                    </span>
                  </span>
                </Link>
              );
            })}
          </div>
        </div>
      </section>

      {/* ------------------------------------------------ SPOTLIGHT */}
      {spotlight && (
        <section className="mx-auto max-w-7xl px-4 pt-20">
          <div className="card-pop grid overflow-hidden rounded-[2rem] bg-white md:grid-cols-2">
            <div className="ndebele-band min-h-64 border-b-2 border-ink md:border-b-0 md:border-r-2" style={{ ['--band' as string]: spotlight.brand_color ?? '#FFB612' }} />
            <div className="flex flex-col gap-5 p-8 md:p-12">
              <p className="text-sm font-black uppercase tracking-[0.2em] text-flame">Seller spotlight</p>
              <div className="flex items-center gap-4">
                <SellerLogo seller={spotlight} size={72} />
                <div>
                  <h3 className="font-display text-3xl font-extrabold leading-tight">{spotlight.name}</h3>
                  <p className="text-ink/60">📍 {spotlight.location}</p>
                </div>
              </div>
              {spotlight.story_headline && <p className="font-display text-2xl font-bold">“{spotlight.story_headline}”</p>}
              <p className="text-ink/75">{spotlight.story}</p>
              <Link href={`/sellers/${spotlight.slug}`} className="btn btn-dark self-start">Visit their shop →</Link>
            </div>
          </div>
        </section>
      )}

      {/* ------------------------------------------------ LOAD-SHEDDING */}
      {deals.data.length > 0 && (
        <section className="mx-auto max-w-7xl px-4 pt-20">
          <div className="rounded-[2rem] border-2 border-ink bg-[#1a1a2e] p-6 text-white shadow-[8px_8px_0_#ffb612] md:p-10">
            <div className="flex flex-wrap items-end justify-between gap-4">
              <div>
                <p className="text-sm font-black uppercase tracking-[0.2em] text-sun">Stage-proof your home</p>
                <h2 className="font-display text-4xl font-extrabold md:text-5xl">🔋 Load-shedding survival kit</h2>
              </div>
              <Link href="/shop?category=tech-and-load-shedding" className="btn btn-primary">Shop the kit</Link>
            </div>
            <div className="mt-8 grid grid-cols-2 gap-4 text-ink md:gap-6 lg:grid-cols-4">
              {deals.data.map((p) => (
                <ProductCard key={p.id} product={p} />
              ))}
            </div>
          </div>
        </section>
      )}

      {/* ------------------------------------------------ FEATURED SELLERS */}
      <section className="mx-auto max-w-7xl px-4 pt-20">
        <div className="flex items-end justify-between gap-4">
          <SectionTitle eyebrow="Local legends" title="Meet the makers" />
          <Link href="/sellers" className="hidden font-bold underline decoration-2 underline-offset-4 sm:block">All sellers →</Link>
        </div>
        <div className="mt-8 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {featured.data.map((v) => (
            <SellerCard key={v.id} seller={v} />
          ))}
        </div>
      </section>

      {/* ------------------------------------------------ SELL CTA */}
      <section className="mx-auto max-w-7xl px-4 pt-24">
        <div className="relative overflow-hidden rounded-[2rem] border-2 border-ink bg-veld p-8 text-white shadow-[8px_8px_0_#0b0b0f] md:p-14">
          <div className="absolute -right-16 -top-16 h-64 w-64 rounded-full border-2 border-ink bg-sun" />
          <div className="absolute -bottom-20 right-40 h-40 w-40 rotate-12 rounded-3xl border-2 border-ink bg-pink" />
          <div className="relative max-w-2xl space-y-5">
            <h2 className="font-display text-4xl font-extrabold leading-tight md:text-6xl">Got a hustle? Put it in front of the whole country.</h2>
            <p className="text-lg text-white/85">
              No listing fees. No monthly subscription. Just {COMMISSION_RATE}% when you make a sale, weekly payouts and a team that
              helps you with photos, pricing and delivery.
            </p>
            <div className="flex flex-wrap gap-3">
              <Link href="/sell" className="btn btn-primary text-lg">Apply in 5 minutes →</Link>
              <Link href="/sell#pricing" className="btn btn-light text-lg">How fees work</Link>
            </div>
          </div>
        </div>
      </section>

      <div className="mt-24">
        <Marquee
          className="bg-sun text-ink"
          items={['Ubuntu', 'Shop local', 'Buy Black', 'Support women in business', 'Kasi to the world', 'Lekker local', 'Sharp sharp']}
        />
      </div>
    </>
  );
}

function SectionTitle({ eyebrow, title, light = false }: { eyebrow: string; title: string; light?: boolean }) {
  return (
    <div>
      <p className={`text-sm font-black uppercase tracking-[0.2em] ${light ? 'text-sun' : 'text-flame'}`}>{eyebrow}</p>
      <h2 className="font-display text-4xl font-extrabold tracking-tight md:text-5xl">{title}</h2>
    </div>
  );
}
